//
//  NSDate.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/31/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation

extension NSDate {
  var millisecondsIntervalSince1970: Double {
    return self.timeIntervalSince1970 * 1000;
  }
}