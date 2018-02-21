//
//  CLBeacon.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

extension CLBeacon {
  func isSameUUIDWith(_ beacon: CLBeacon) -> Bool {
    return self.proximityUUID.uuidString == beacon.proximityUUID.uuidString
  }

  func isSameUUIDNMajorWith(_ beacon: CLBeacon) -> Bool {
    return isSameUUIDWith(beacon) && self.major.int32Value == beacon.major.int32Value
  }

}
