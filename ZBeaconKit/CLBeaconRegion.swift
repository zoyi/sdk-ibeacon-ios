//
//  CLBeaconRegion.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

extension CLBeaconRegion {
  func isEqualTo(_ region: CLBeaconRegion) -> Bool {
    return region.proximityUUID.uuidString == self.proximityUUID.uuidString
  }
}
