//
//  RangingService.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

@objc protocol RangingServiceDelegate: class {
  optional func didStartRanging(forReigon region: CLBeaconRegion)
  optional func didStopRanging(forReigon region: CLBeaconRegion)
  optional func didFailToStartRanging(forReigon region: CLBeaconRegion)
  func didRangeBeacon(beacon: CLBeacon, forRegion region: CLBeaconRegion)
}

final class RangingService: LocationService {
  var region: CLBeaconRegion! {
    willSet(newRegion) {
      if !locationManager.rangedRegions.isEmpty
         && !region.isEqual(newRegion)
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
      delegate?.didFailToStartRanging?(forReigon: region)
      return
    }

    guard CLLocationManager.isRangingAvailable() else {
      dlog("Turn on ranging: ranging is not available")
      delegate?.didFailToStartRanging?(forReigon: region)
      return
    }

    guard locationManager.rangedRegions.isEmpty else {
      dlog("Turn on ranging: ranging is already on")
      delegate?.didFailToStartRanging?(forReigon: region)
      return
    }

    switch CLLocationManager.authorizationStatus() {
    case .AuthorizedAlways, .AuthorizedWhenInUse:
      turnOnRanging()
    case .Denied, .Restricted:
      dlog("Could not turn on ranging: require location access missing")
    case .NotDetermined:
      if #available(iOS 8.0, *) {
          locationManager.requestWhenInUseAuthorization()
      } else {
          // Fallback on earlier versions
      }
    }
  }

  func turnOnRanging() {
    locationManager.startRangingBeaconsInRegion(region)
    delegate?.didStartRanging?(forReigon: region)
    dlog("About to start ranging: \(region)")
  }

  func stopRanging() {
    locationManager.stopRangingBeaconsInRegion(region)
    inactiveLocationManager()
    delegate?.didStopRanging?(forReigon: region)
    dlog("Turn off ranging for regin: \(region)")
  }

  // MARK: - Location Manager Delegate methods
  func locationManager(
    manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    inRegion region: CLBeaconRegion)
  {
    guard manager.isEqual(locationManager) else { return}
    for beacon in beacons {
      if beacon.rssi < 0 && beacon.proximityUUID.UUIDString == region.proximityUUID.UUIDString {
        delegate?.didRangeBeacon(beacon, forRegion: region)
        return
      }
    }
  }

  func locationManager(
    manager: CLLocationManager,
    rangingBeaconsDidFailForRegion region: CLBeaconRegion,
    withError error: NSError)
  {
    dlog("ranging region: \(region), with error: \(error)")
    manager.stopRangingBeaconsInRegion(region)
  }
}