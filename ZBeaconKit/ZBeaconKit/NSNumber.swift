//
//  NSNumber.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/31/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation

extension NSNumber {
  var hexValue: String {
    return String(format: "%2X", self.intValue)
  }
}
