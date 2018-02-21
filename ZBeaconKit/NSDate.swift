//
//  NSDate.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/31/15.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation

extension Date {
  var microsecondsIntervalSince1970: UInt64 {
    return UInt64(self.timeIntervalSince1970 * 1000 * 1000);
  }
}
