//
//  CLRegion.swift
//  ZBeaconKit
//
//  Created by Di Wu on 1/7/16.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

extension CLRegion {
  func isSpecific() -> Bool {
    guard let region = self as? CLBeaconRegion else { return false }
    return region.major != nil
  }
}
