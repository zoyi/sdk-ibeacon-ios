//
//  LocationService.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

class LocationService: NSObject,  CLLocationManagerDelegate {
  let locationManager = CLLocationManager()

  func activeLocationManager() {
    self.locationManager.delegate = self
  }

  func inactiveLocationManager() {
    self.locationManager.delegate = nil
  }
}
