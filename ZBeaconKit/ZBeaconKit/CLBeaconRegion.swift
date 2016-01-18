//
//  CLBeaconRegion.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

extension CLBeaconRegion {
  func isEqualTo(region: CLBeaconRegion) -> Bool {
    return region.proximityUUID.UUIDString == self.proximityUUID.UUIDString
  }

  override func isSpecific() -> Bool {
    return self.major != nil
  }
}