//
//  RangingService.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol RangingServiceDelegate: class {
  func didRangeBeacon(_ beacon: CLBeacon, forRegion region: CLBeaconRegion)
}

final class RangingService: LocationService {
  var region: CLBeaconRegion? {
    willSet(newRegion) {
      if (region != nil) {

      } else if !locationManager.rangedRegions.isEmpty
         && !region!.isEqual(newRegion)
      { stopRanging() }
    }
    didSet {
      self.startRanging()
    }
  }
  weak var delegate: RangingServiceDelegate?

  override init() {
    super.init()
  }

  convenience init(region: CLBeaconRegion) {
    self.init()
    self.region = region
  }

  deinit {
    stopRanging()
  }
  // MARK: - Ranging methods
  func startRanging() {
    activeLocationManager()

    dlog("Prepare to start ranging")

    guard CLLocationManager.locationServicesEnabled() else {
      dlog("Location Service is disabled")
      return
    }

    guard CLLocationManager.isRangingAvailable() else {
      dlog("Turn on ranging: ranging is not available")
      return
    }

    guard locationManager.rangedRegions.isEmpty else {
      dlog("Turn on ranging: ranging is already on")
      return
    }

    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways, .authorizedWhenInUse:
      turnOnRanging()
    case .denied, .restricted:
      dlog("Could not turn on ranging: require location access missing")
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    }
  }

  func turnOnRanging() {
    guard region != nil else {
      dlog("Cancel to start ranging because region is nil")
      return
    }
    locationManager.startRangingBeacons(in: region!)
    dlog("About to start ranging: \(region!)")
  }

  func stopRanging() {
    guard region != nil else {
      dlog("Cancel to stop ranging because region is nil")
      return
    }
    locationManager.stopRangingBeacons(in: region!)
    inactiveLocationManager()
    dlog("Turn off ranging for regin: \(region!)")
  }

  // MARK: - Location Manager Delegate methods
  func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    inRegion region: CLBeaconRegion)
  {
    guard manager.isEqual(locationManager) else { return}
    for beacon in beacons {
      if beacon.rssi < 0 && beacon.proximityUUID.uuidString == region.proximityUUID.uuidString {
        dlog("did range beacon: \(beacon), for region: \(region)")
        delegate?.didRangeBeacon(beacon, forRegion: region)
        return
      }
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailForRegion region: CLBeaconRegion,
    withError error: NSError)
  {
    dlog("ranging region: \(region), with error: \(error)")
    manager.stopRangingBeacons(in: region)
  }
}
