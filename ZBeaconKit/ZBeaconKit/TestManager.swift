//
//  TestManager.swift
//  ZBeaconKit
//
//  Created by 이수완 on 2017. 8. 9..
//  Copyright © 2017년 ZOYI. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

func dlogForTest<T>( _ object:  @autoclosure () -> T) {
  NotificationCenter.default.post(name: TestManager.PRINT_LOG, object: nil, userInfo: [
    "log": "\(object())"
  ])
}

func getUUIDList() -> [String] {
  return [
    "45e08fa2-6b6b-4cae-80e0-c203563a8e41",
    "0a2372d5-e4c4-45ec-a032-0a45b903b5b1",
    "7bf7cc52-4f65-4f48-a5d3-6f46af270cfb",
    "B86F30D9-B585-4A89-A053-3399C754F4C4"
  ]
}

func getUUIDName(_ uuid: String) -> String {
  switch uuid {
  case "45e08fa2-6b6b-4cae-80e0-c203563a8e41": return "+4"
  case "0a2372d5-e4c4-45ec-a032-0a45b903b5b1": return "-12"
  case "7bf7cc52-4f65-4f48-a5d3-6f46af270cfb": return "-30"
  case "B86F30D9-B585-4A89-A053-3399C754F4C4": return "ZOYI"
  default: return "Unknown"
  }
}

public final class TestManager: NSObject, MonitoringServiceDelegate {

  public static let PRINT_LOG = Notification.Name("PRINT_LOG")
  var monitoringServices = [MonitoringService]()

  public func startTest() {
    getUUIDList().forEach { (uuid) in
      let region = CLBeaconRegion(proximityUUID: UUID(uuidString: uuid)!, identifier: "ZBEACON-" + uuid)
      region.notifyEntryStateOnDisplay = true

      let service = MonitoringService()
      service.startMonitoring(withRegion: region)
      service.delegate = self

      dlogForTest("[\(getUUIDName(uuid))] Start monitoring")

      self.monitoringServices.append(service)
    }
  }

  func didEnterRegion(_ region: CLBeaconRegion) {
    dlogForTest("[\(getUUIDName(region.proximityUUID.uuidString))] Enter")
  }

  func didExitRegion(_ region: CLBeaconRegion) {
    dlogForTest("[\(getUUIDName(region.proximityUUID.uuidString))] Exit")
  }
}
