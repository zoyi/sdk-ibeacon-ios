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

  // MARK: - Beacon

  static func getKey(uuid: String) -> String {
    return "ZBeaconKit_Beacon_\(uuid.lowercased())"
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


  // MARK: - Area

  static func getAreaKey(uuid: String) -> String {
    return "ZBeaconKit_Area_\(uuid.lowercased())"
  }

  static func saveArea(uuid: String, name: String) {
    UserDefaults.standard.set(name, forKey: getAreaKey(uuid: uuid))
  }

  static func getArea(uuid: String) -> String? {
    return UserDefaults.standard.string(forKey: getAreaKey(uuid: uuid))
  }
}
