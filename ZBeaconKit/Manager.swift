//
//  Manager.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import AdSupport

func dlog<T>( _ object:  @autoclosure () -> T, color: UIColor = UIColor.black) {
  guard Manager.debugMode else { return }
  let message = "[ZBeaconKit] \(Date()): \(object())\n\n"
  print(message, terminator: "")
  debugDelegate?.debug(with: message)
}

enum IBeaconRegionEvent: String {
  case Enter = "enter"
  case Exit = "leave"
}

@objc public enum Target: Int {
  case Production
  case Development
}

/** debugging purpose **/
public protocol DebugDelegate: class {
  func debug(with message: String)
  func debug(with message: String, color: UIColor)
  func receive(with event: ZBeaconEvent)
}

public enum ZBeaconEvent {
  case error(data: [String: Any], event: String)
  case sent(data: [String: Any], event: String)
  case enter(region: CLBeaconRegion)
  case exit(region: CLBeaconRegion)
  case state(region: CLBeaconRegion, state: CLRegionState)
}

public var debugDelegate: DebugDelegate? = nil

@objc
public final class Manager: NSObject, MonitoringManagerDelegate {

  // MARK: - Properties

  @objc public static var debugMode = false
  @objc public static let packageId = Bundle.main.bundleIdentifier;
  @objc public static var uuids = [String]()
  @objc public static var customerId: String? = nil
  @objc public static var advId: String? = nil

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
      return "http://dropwizard-dev.walkinsights.com/api/v1/ibeacon_signals"
    }
  }

  static let model = UIDevice.current.modelName
  static let systemInfo = UIDevice.current.systemInfo
  static let currentPackageVersion = "1.0.0"

  fileprivate var monitoringManagers = [MonitoringManager]()
  fileprivate var authHeader: [String: String]
  fileprivate let target: Target
  fileprivate var retryCount = 0
  fileprivate let retryTimeInterval = 60.0
  fileprivate let maxRetryCount = 5

  // MARK: - Initialize
  @objc
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
  
  @objc
  public func start() {
    self.stop()

    if Manager.customerId == nil {
      dlog("[ERR] you should set customer id")
    }

    self.retryCount = 0

    self.fetchPackageVersion()
  }

  @objc
  public func restart() {
    self.start()
  }

  @objc
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
    dlog("[INFO] All start monitoring \(self.monitoringManagers.count)")
    debugDelegate?.debug(with: "Start monitoring for\n\t\(Manager.uuids.joined(separator: "\n\t"))\n\n", color: UIColor.black)
  }

  func fetchPackageVersion() {
    do {
      dlog("[INFO] Try to fetch package version")

      let opt = try HTTP.GET(
        self.packageVersionEndpoint,
        parameters: nil,
        headers: nil,
        requestSerializer: HTTPParameterSerializer())

      opt.start({ [weak self] response in
        if response.error != nil {
          dlog("[ERR] Did fetch package version with ERROR: \(response.error!)")
          self?.startRetryTimer()
        } else {

          if let json = try? JSONSerialization.jsonObject(with: response.data, options: []),
            let result = json as? [String: AnyObject],
            let ibeaconPlugins = result["ibeacon_plugins"],
            let newestVersion = ibeaconPlugins["newest_version"] as? String,
            let minimumVersion = ibeaconPlugins["minimum_version"] as? String {
            dlog("[INFO] Did fetch package version with response: \(result)")

            // get current version
            let cv = Manager.currentPackageVersion
            if cv.compare(minimumVersion, options: .numeric) == .orderedSame ||
               cv.compare(minimumVersion, options: .numeric) == .orderedDescending {
              // current version is newer than or equal to minimum version
              if cv.compare(newestVersion, options: .numeric) == .orderedAscending {
                // current version is older than newest version
                dlog("[INFO] Warning: Newest version \(newestVersion) is available")
              }
              self?.fetchUUIDs()
            } else {
              dlog("[ERR] Current version is not compatible. Need to upgrade to newest version: \(newestVersion)")
            }
          }
        }
      })
    } catch {
      dlog("[ERR] Error on request to fetch package version")
      self.startRetryTimer()
    }
  }

  @objc func fetchUUIDs() {
    do {
      dlog("[INFO] Try to fetch uuids")

      let opt = try HTTP.GET(
        self.uuidEndpoint,
        parameters: nil,
        headers: self.authHeader,
        requestSerializer: HTTPParameterSerializer())

      opt.start({ [weak self] response in
        if response.error != nil {
          dlog("[ERR] Did fetch uuids with ERROR: \(response.error!)")
          self?.startRetryTimer()
        } else {

          if let json = try? JSONSerialization.jsonObject(with: response.data, options: []),
             let result = json as? [String: AnyObject],
             let ibeacons = result["square_ibeacons"] as? [AnyObject] {
            dlog("[INFO] Did fetch uuids with response: \(ibeacons)")

            self?.retryCount = 0

            Manager.uuids = [String]()
            ibeacons.enumerated().forEach({
              if let uuid = ibeacons[$0.offset]["uuid"] as? String,
                 let name = ibeacons[$0.offset]["name"] as? String {
                PrefStore.saveArea(uuid: uuid, name: name)
                Manager.uuids.append(uuid)
              }
            })

            DispatchQueue.main.async(execute: { [weak self] in
              self?.startMonitoring()
            })
          }
        }
      })
    } catch {
      dlog("[ERR] Error on request to fetch uuids: \(error)")
      self.startRetryTimer()
    }
  }

  fileprivate func startRetryTimer() {
    if self.retryCount < self.maxRetryCount {
      dlog("[INFO] Set timer to retry fetch")
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
    minor: Int) {
    guard let customerId = Manager.customerId else {
      dlog("[ERR] Did not send event because no customer id")
      return
    }
    var params: [String: Any] = [
      "package_id": Manager.packageId ?? "",
      "customer_id" : customerId,
      "event": type.rawValue,

      "ibeacon_uuid": uuid,
      "major": major,
      "minor": minor,
      "area": PrefStore.getArea(uuid: uuid) ?? "",

      "os": "ios",
      "device": Manager.model,
      "ts": "\(Date().microsecondsIntervalSince1970)",

      "sdk_version": Manager.currentPackageVersion
    ]
    
    if let advId = Manager.advId, advId != "" {
      params["ad_id"] = advId
    }

    do {
      dlog("[REQ] Try to send event with params: \(params)\n")
      let opt = try HTTP.POST(self.dataEndpoint,
                              parameters: params,
                              requestSerializer: JSONParameterSerializer())
      opt.start({ response in
        if response.error != nil {
          dlog("[ERR] Did send event with ERROR: \(response.error!)")
          debugDelegate?.receive(with: .error(data: params, event: type.rawValue))
          if response.statusCode == 426 {
            dlog("[ERR] UnsupportedSDKVersionError: stop monitoring")
            debugDelegate?.receive(with: .error(data: params, event: type.rawValue))
            self.stop()
          }
        } else {
          debugDelegate?.receive(with: .sent(data: params, event: type.rawValue))
          dlog("[RES] Did send event to zoyi server response: \(response.data)\n")
        }

      })
    } catch {
      dlog("[ERR] Error on create a new event request: \(error)")
      debugDelegate?.receive(with: .error(data: params, event: type.rawValue))
    }
  }
}
