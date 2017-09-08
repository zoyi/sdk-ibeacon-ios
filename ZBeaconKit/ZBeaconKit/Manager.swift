//
//  Manager.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import AdSupport

func dlog<T>( _ object:  @autoclosure () -> T) {
  guard Manager.debugMode else { return }
  print("[ZBeaconKit]: \(object())\n\n", terminator: "")
}

enum IBeaconRegionEvent: String {
  case Enter = "enter"
  case Exit = "leave"
}

@objc public enum Target: Int {
  case Production
  case Development
}

public final class Manager: NSObject, MonitoringManagerDelegate {

  // MARK: - Properties

  public static var debugMode = false

  public static let packageId = Bundle.main.bundleIdentifier;

  public static var uuids = [String]()

  public static var customerId: String? = nil
  public static var advId: String? = nil

  var packageVersionEndpoint: String {
    switch self.target {
    case .Production:
      return "https://api.walkinsights.com/api/v1/plugins/ios"
    case .Development:
      return "http://dev-square.zoyi.co/api/v1/plugins/ios"
    }
  }

  var uuidEndpoint: String {
    switch self.target {
    case .Production:
      return "https://api.walkinsights.com/api/v1/square_ibeacons"
    case .Development:
      return "http://dev-square.zoyi.co/api/v1/square_ibeacons"
    }
  }

  var dataEndpoint: String {
    switch self.target {
    case .Production:
      return "https://dropwizard.walkinsights.com/api/v1/ibeacon_signals"
    case .Development:
      return "https://dropwizard-dev.walkinsights.com/api/v1/ibeacon_signals"
    }
  }

  static let model = UIDevice.current.modelName
  static let systemInfo = UIDevice.current.systemInfo
  static let sdkVersion = 2
  static let currentPackageVersion = "1.0.0"

  fileprivate var monitoringManagers = [MonitoringManager]()
  fileprivate var authHeader: [String: String]
  fileprivate let target: Target
  fileprivate var retryCount = 0
  fileprivate let retryTimeInterval = 60.0
  fileprivate let maxRetryCount = 5

  // MARK: - Initialize

  public init(email: String, authToken token: String, target: Target = .Production) {
    self.authHeader = [
      "X-User-Email" : email,
      "X-User-Token" : token
    ]
    self.target = target

    super.init()

    if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
      Manager.advId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
  }

  // MARK: - Public methods

  public func start() {
    self.stop()

    if Manager.customerId == nil {
      dlog("you should set customer id")
    }

    self.retryCount = 0

    self.fetchPackageVersion()
  }

  public func restart() {
    self.start()
  }

  public func stop() {
    self.monitoringManagers.forEach { $0.stopMonitoring() }
    self.monitoringManagers = [MonitoringManager]()
  }

  // MARK: - MonitoringManagerDelegate methods

  func didEnterBeaconRegion(uuid: String, major: Int, minor: Int, forReigon region: CLRegion) {
    self.sendEvent(.Enter, uuid: uuid, major: major, minor: minor)
  }

  func didExitBeaconRegion(uuid: String, major: Int, minor: Int, forReigon region: CLRegion) {
    self.sendEvent(.Exit, uuid: uuid, major: major, minor: minor)
  }

  // MARK: - Private help methods

  private func startMonitoring() {
    Manager.uuids.forEach { (uuid) in
      let region = CLBeaconRegion(proximityUUID: UUID(uuidString: uuid)!, identifier: "ZBEACON-" + uuid)
      region.notifyEntryStateOnDisplay = true

      let manager = MonitoringManager(region: region, delegate: self)
      manager.startMonitoring()
      self.monitoringManagers.append(manager)
    }
    dlog("All start monitoring \(self.monitoringManagers.count)")
  }

  func fetchPackageVersion() {
    do {
      dlog("Try to fetch package version")

      let opt = try HTTP.GET(self.packageVersionEndpoint,
                             parameters: nil,
                             headers: nil,
                             requestSerializer: HTTPParameterSerializer())

      opt.start({ [weak self] response in
        if response.error != nil {
          dlog("Did fetch package version with ERROR: \(response.error!)")
          self?.startRetryTimer()
        } else {

          if let json = try? JSONSerialization.jsonObject(with: response.data, options: []),
            let result = json as? [String: AnyObject],
            let ibeaconPlugins = result["ibeacon_plugins"],
            let newestVersion = ibeaconPlugins["newest_version"] as? String,
            let minimumVersion = ibeaconPlugins["minimum_version"] as? String {
            dlog("Did fetch package version with response: \(result)")

            // get current version
            let cv = Manager.currentPackageVersion
            if cv.compare(minimumVersion, options: .numeric) == .orderedSame ||
               cv.compare(minimumVersion, options: .numeric) == .orderedDescending {
              // current version is newer than or equal to minimum version
              if cv.compare(newestVersion, options: .numeric) == .orderedAscending {
                // current version is older than newest version
                dlog("Warning: Newest version \(newestVersion) is available")
              }
              self?.fetchUUIDs()
            } else {
              dlog("Error: Current version is not compatible. Need to upgrade to newest version: \(newestVersion)")
            }
          }
        }
      })
    } catch {
      dlog("Error on request to fetch package version")
      self.startRetryTimer()
    }
  }

  func fetchUUIDs() {
    do {
      dlog("Try to fetch uuids")

      let opt = try HTTP.GET(self.uuidEndpoint,
                             parameters: nil,
                             headers: self.authHeader,
                             requestSerializer: HTTPParameterSerializer())

      opt.start({ [weak self] response in
        if response.error != nil {
          dlog("Did fetch uuids with ERROR: \(response.error!)")
          self?.startRetryTimer()
        } else {

          if let json = try? JSONSerialization.jsonObject(with: response.data, options: []),
             let result = json as? [String: AnyObject],
             let ibeacons = result["square_ibeacons"] as? [AnyObject] {
            dlog("Did fetch uuids with response: \(ibeacons)")

            self?.retryCount = 0

            Manager.uuids = [String]()
            ibeacons.enumerated().forEach({
              if let uuid = ibeacons[$0.offset]["uuid"] as? String,
                 let name = ibeacons[$0.offset]["name"] as? String {
                PrefStore.saveArea(uuid: uuid, name: name)
                Manager.uuids.append(uuid)
              }
            })

            DispatchQueue.main.async(execute: { [weak self] _ in
              self?.startMonitoring()
            })
          }
        }
      })
    } catch {
      dlog("Error on request to fetch uuids: \(error)")
      self.startRetryTimer()
    }
  }

  fileprivate func startRetryTimer() {
    if self.retryCount < self.maxRetryCount {
      dlog("Set timer to retry fetch")
      self.retryCount = self.retryCount + 1

      DispatchQueue.main.async {
        if #available(iOS 10.0, *) {
          Timer.scheduledTimer(
            withTimeInterval: self.retryTimeInterval,
            repeats: false,
            block: { (_) in
              self.fetchUUIDs()
          })
        } else {
          Timer.scheduledTimer(
            timeInterval: self.retryTimeInterval,
            target: self,
            selector: #selector(self.fetchUUIDs),
            userInfo: nil,
            repeats: false)
        }
      }
    }
  }

  fileprivate func sendEvent(
    _ type: IBeaconRegionEvent,
    uuid: String,
    major: Int,
    minor: Int)
  {
    guard let customerId = Manager.customerId else {
      dlog("Did not send event because no customer id")
      return
    }
    let params: [String: Any] = [
      "package_id": Manager.packageId ?? "",
      "customer_id" : customerId,
      "ad_id": Manager.advId ?? "",
      "event": type.rawValue,

      "ibeacon_uuid": uuid,
      "major": major,
      "minor": minor,
      "area": PrefStore.getArea(uuid: uuid) ?? "",

      "os": "ios",
      "device": Manager.model,
      "ts": "\(Date().microsecondsIntervalSince1970)",

      "sdk_version": Manager.sdkVersion
    ]

    do {
      dlog("Try to send event with params: \(params)")
      let opt = try HTTP.POST(self.dataEndpoint,
                              parameters: params,
                              requestSerializer: JSONParameterSerializer())
      opt.start({ response in
        if response.error != nil {
          dlog("Did send event with ERROR: \(response.error!)")
        } else {
          dlog("Did send event to zoyi server response: \(response.data)")
        }

      })
    } catch {
      dlog("Error on create a new event request: \(error)")
    }
  }
}
