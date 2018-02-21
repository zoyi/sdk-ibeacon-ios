//
//  UIDevice.swift
//  ZBeaconKit
//
//  Created by Di Wu on 1/8/16.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation

extension UIDevice {
  var modelName: String {
    switch UIDevice.current.systemVersion.compare("8.0.0", options: NSString.CompareOptions.numeric) {
    case .orderedSame, .orderedDescending: // iOS >= 8.0
      var systemInfo = utsname()
      uname(&systemInfo)
      let machineMirror = Mirror(reflecting: systemInfo.machine)
      return machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
      }
    case .orderedAscending: return self.model // iOS < 8.0
    }
  }

  var systemInfo: String {
    return self.systemName + " " + self.systemVersion
  }
}
