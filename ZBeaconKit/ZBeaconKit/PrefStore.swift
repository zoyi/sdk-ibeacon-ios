//
//  PrefStore.swift
//  ZBeaconKit
//
//  Created by 이수완 on 2017. 8. 16..
//  Copyright © 2017년 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

class PrefStore {
  static let PREFIX = "ZBeaconKit_Beacon_"

  static func getKey(uuid: String) -> String {
    return "\(PREFIX)\(uuid)"
  }

  static func save(uuid: String, major: Int, minor: Int) {
    let key = getKey(uuid: uuid)
    UserDefaults.standard.set("\(major):\(minor)", forKey: key)
  }

  static func get(uuid: String) -> [Int] {
    let key = getKey(uuid: uuid)
    let value = UserDefaults.standard.string(forKey: key)
    guard value != nil else { return [] }
    let values = value!.components(separatedBy: ":")
    guard values.count == 2 else { return [] }
    let major = Int(values[0])
    let minor = Int(values[1])
    guard major != nil && minor != nil else { return [] }
    return [major!, minor!]
  }

  static func clear(uuid: String) {
    let key = getKey(uuid: uuid)
    UserDefaults.standard.removeObject(forKey: key)
  }
}
