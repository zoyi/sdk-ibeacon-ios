//
//  Manager.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

func dlog<T>(@autoclosure object:  () -> T) {
  guard Manager.debugMode else { return }
  print("[ZBeaconKit]: \(object())\n", terminator: "")
}

//public protocol ZBeaconManagerDelegate {
//  
//}

enum IBeaconRegionEvent: String {
  case Enter = "enter"
  case Exit = "leave"
}

public final class Manager: NSObject, MonitoringServiceDelegate {

  public static var debugMode = false

  public static let packageId = NSBundle.mainBundle().bundleIdentifier;
  public static var customerId: String? = nil

  static let apiEndpoint = "https://api.walkinsights.com/api/v1/brands"
  static let dataEndpoint = "https://dropwizard.walkinsights.com/api/v1/ibeacon_signals"
  static let defaultOutUUIDString = "345C237F-65DC-4928-8595-1E955561F695"

  static let model = UIDevice.currentDevice().modelName
  static let systemInfo = UIDevice.currentDevice().systemInfo

  private var authHeader: [String: String]
  private let brandId: Int

  var monitoringServices = [GeneralMonitoringService]()

  public init(email: String, authToken token: String, brandId: Int) {
    self.authHeader = [
      "X-User-Email" : email,
      "X-User-Token" : token
    ]
    self.brandId = brandId
    super.init()
    // http://www.touch-code-magazine.com/cllocationmanager-and-thread-safety/
    // Location manager must be created on main thread
    dispatch_async(dispatch_get_main_queue(), { [unowned self] _ in
      let outRegion = self.getMonitoringRegion(withUUID: NSUUID(UUIDString: Manager.defaultOutUUIDString)!, identifier: "ZBEACON-OUT")
      self.monitoringServices.append(GeneralMonitoringService(region: outRegion, delegate: self)) // OUT
    })

  }

  public func start() {
    if Manager.customerId == nil {
      dlog("you should set customer id")
    }
    startMonitoring()
    startBrandOutRegion(withBrandId: brandId)
  }

  public func stop() {
    stopMonitoring()
  }

  private func startMonitoring() {
    dlog("Totoal \(monitoringServices.count) monitoring services")
    monitoringServices.forEach({$0.startMonitoring()})
  }

  private func stopMonitoring() {
    dlog("Totoal \(monitoringServices.count) monitoring services stop")
    monitoringServices.forEach({$0.stopMonitoring()})
  }

  private func restartMonitoring() {
    self.stopMonitoring()

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))),
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [unowned self] _ in
        self.startMonitoring()
    }
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
            self.monitoringServices.append(GeneralMonitoringService(region: brandOutRegion, delegate: self))
          }
          self.restartMonitoring()
        })
        dlog("brand out self: \(self), uuid: \(brandOutUUIDString), monitoringService count: \(self.monitoringServices.map{$0})")
      })
    } catch {
      self.restartMonitoring()
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
      "ts": NSDate().millisecondsIntervalSince1970,
    ]

    do {
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

  // MARK: - Monitoring Service delegate
  func didEnterBeaconRegion(service: GeneralMonitoringService, beacon: CLBeacon?, forReigon region: CLRegion) {
    guard let region = region as? CLBeaconRegion else { return }
    guard beacon == nil || beacon!.proximityUUID.UUIDString == region.proximityUUID.UUIDString else { return }
    let major: NSNumber? = beacon?.major ?? region.major
    let minor: NSNumber? = beacon?.minor ?? region.minor
    dlog("About to send server for ENTER service: \(service), with beacon: \(beacon), for reigon: \(region), on \(NSDate().millisecondsIntervalSince1970)")
    sendEvent(.Enter, uuid: region.proximityUUID.UUIDString, major: major, minor: minor, rssi: beacon?.rssi)
  }

  func didExitBeaconRegion(service: GeneralMonitoringService, beacon: CLBeacon?, forReigon region: CLRegion) {
    guard let region = region as? CLBeaconRegion else { return }
    guard beacon == nil || beacon!.proximityUUID.UUIDString == region.proximityUUID.UUIDString else { return }
    let major: NSNumber? = beacon?.major ?? region.major
    let minor: NSNumber? = beacon?.minor ?? region.minor
    dlog("About to send server for EXIT service: \(service), with beacon: \(beacon), for reigon: \(region), on \(NSDate().millisecondsIntervalSince1970)")
    sendEvent(.Exit, uuid: region.proximityUUID.UUIDString, major: major, minor: minor, rssi: beacon?.rssi)
  }
}
