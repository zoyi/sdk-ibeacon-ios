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

  public static let uuids = [
    "45e08fa2-6b6b-4cae-80e0-c203563a8e41",
    "7bf7cc52-4f65-4f48-a5d3-6f46af270cfb"
  ]

  public static var customerId: String? = nil
  public static var advId: String? = nil

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

  fileprivate var monitoringManagers = [MonitoringManager]()
  fileprivate let target: Target

  // MARK: - Initialize

  public init(target: Target = .Production) {
    self.target = target
    super.init()

    if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
      Manager.advId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
  }

  // MARK: - Public methods

  public func start() {
    if Manager.customerId == nil {
      dlog("you should set customer id")
    }

    Manager.uuids.forEach { (uuid) in
      let region = CLBeaconRegion(proximityUUID: UUID(uuidString: uuid)!, identifier: "ZBEACON-" + uuid)
      region.notifyEntryStateOnDisplay = true

      let manager = MonitoringManager(region: region, delegate: self)
      manager.startMonitoring()
      self.monitoringManagers.append(manager)
    }
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
