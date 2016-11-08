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

func dlog<T>(@autoclosure object:  () -> T) {
  guard Manager.debugMode else { return }
  print("[ZBeaconKit]: \(object())\n\n", terminator: "")
}

enum IBeaconRegionEvent: String {
  case Enter = "enter"
  case Exit = "leave"
}

public final class Manager: NSObject, MonitoringManagerDelegate {

  public static var debugMode = false

  public static let packageId = NSBundle.mainBundle().bundleIdentifier;
  public static var customerId: String? = nil

  static let apiEndpoint = "https://api.walkinsights.com/api/v1/brands"
  static let dataEndpoint = "https://dropwizard.walkinsights.com/api/v1/ibeacon_signals"

  static let model = UIDevice.currentDevice().modelName
  static let systemInfo = UIDevice.currentDevice().systemInfo
  static let sdkVersion = 1

  private var authHeader: [String: String]
  private let brandId: Int

  var monitoringManager: MonitoringManager? = nil

  public init(email: String, authToken token: String, brandId: Int) {
    self.authHeader = [
      "X-User-Email" : email,
      "X-User-Token" : token
    ]
    self.brandId = brandId
    super.init()
  }

  public func start() {
    if Manager.customerId == nil {
      dlog("you should set customer id")
    }
    self.startBrandOutRegion(withBrandId: brandId)
  }

  public func stop() {
    self.monitoringManager?.stopMonitoring()
  }

  private func getMonitoringRegion(withUUID uuid: NSUUID, identifier: String) -> CLBeaconRegion {
    let region = CLBeaconRegion(proximityUUID: uuid, identifier: identifier)
    region.notifyEntryStateOnDisplay = true
    return region
  }

  private func startBrandOutRegion(withBrandId brandId: Int) {
    var brandOutUUIDString: String? = nil
    do {
      let opt = try HTTP.GET(Manager.apiEndpoint + "/\(brandId)",
                             parameters: nil,
                             headers: authHeader,
                             requestSerializer: HTTPParameterSerializer())
      opt.start({ [unowned self] response in
        if response.error != nil {
          dlog("Did fetch brand out region with ERROR: \(response.error)")
        } else {
          if let json = try? NSJSONSerialization.JSONObjectWithData(response.data, options: []),
             let result = json as? [String: AnyObject],
             let brand = result["brand"] as? [String: AnyObject]
          {
            brandOutUUIDString = (brand["ibeacon_out_uuid"] as? String) ?? brandOutUUIDString
            dlog("Did fetch brand info : \(brand)")
          }
        }
        dispatch_async(dispatch_get_main_queue(), { [unowned self] _ in
          if let brandOutUUIDString = brandOutUUIDString {
            let brandOutRegion = self.getMonitoringRegion(withUUID: NSUUID(UUIDString: brandOutUUIDString)!, identifier: "ZBEACON-" + brandOutUUIDString)
            self.monitoringManager = MonitoringManager(region: brandOutRegion, delegate: self)
            self.monitoringManager?.startMonitoring()
          }
        })
        dlog("brand out self: \(self), uuid: \(brandOutUUIDString)")
      })
    } catch {
      dlog("Error on create fetch brand out region: \(error)")
    }
  }

  private func sendEvent(
    type: IBeaconRegionEvent,
    uuid: String,
    major: NSNumber?,
    minor: NSNumber?,
    rssi: Int?)
  {
    guard let customerId = Manager.customerId else {
      dlog("Did not send event because no customer id")
      return
    }
    guard major != nil else { return }
    let params: [String: AnyObject] = [
      "package_id": Manager.packageId ?? "",
      "customer_id" : customerId,
      "event": type.rawValue,

      "ibeacon_uuid": uuid,
      "major": major?.integerValue ?? NSNull(),
      "minor": minor?.integerValue ?? NSNull(),
      "rssi" : rssi ?? NSNull(),

      "os": "ios",
      "device": Manager.model,
      "ts": "\(NSDate().microsecondsIntervalSince1970)",

      "sdk_version": Manager.sdkVersion
    ]

    do {
      dlog("Try to send event with params: \(params)")
      let opt = try HTTP.POST(Manager.dataEndpoint,
                              parameters: params,
                              headers: self.authHeader,
                              requestSerializer: JSONParameterSerializer())
      opt.start({ response in
        if response.error != nil {
          dlog("Did send event with ERROR: \(response.error)")
        } else {
          dlog("Did send event to zoyi server response: \(response.data)")
        }

      })
    } catch {
      dlog("Error on create a new event request: \(error)")
    }
  }

  // MARK: - Monitoring Manager delegate

  func didEnterBeaconRegion(beacon: CLBeacon?, forReigon region: CLRegion) {
    guard let region = region as? CLBeaconRegion else { return }
    guard beacon == nil || beacon!.proximityUUID.UUIDString == region.proximityUUID.UUIDString else { return }
    let major: NSNumber? = beacon?.major ?? region.major
    let minor: NSNumber? = beacon?.minor ?? region.minor
    dlog("About to send server for ENTER with beacon: \(beacon), for reigon: \(region), on \(NSDate().microsecondsIntervalSince1970)")
    sendEvent(.Enter, uuid: region.proximityUUID.UUIDString, major: major, minor: minor, rssi: beacon?.rssi)
  }

  func didExitBeaconRegion(beacon: CLBeacon?, forReigon region: CLRegion) {
    guard let region = region as? CLBeaconRegion else { return }
    guard beacon == nil || beacon!.proximityUUID.UUIDString == region.proximityUUID.UUIDString else { return }
    let major: NSNumber? = beacon?.major ?? region.major
    let minor: NSNumber? = beacon?.minor ?? region.minor
    dlog("About to send server for EXIT with beacon: \(beacon), for reigon: \(region), on \(NSDate().microsecondsIntervalSince1970)")
    sendEvent(.Exit, uuid: region.proximityUUID.UUIDString, major: major, minor: minor, rssi: beacon?.rssi)
  }
}
