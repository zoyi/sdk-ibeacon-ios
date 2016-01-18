//
//  CLBeacon.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

extension CLBeacon {
  func isSameUUIDWith(beacon: CLBeacon) -> Bool {
    return self.proximityUUID.UUIDString == beacon.proximityUUID.UUIDString
  }

  func isSameUUIDNMajorWith(beacon: CLBeacon) -> Bool {
    return isSameUUIDWith(beacon) && self.major.intValue == beacon.major.intValue
  }

}