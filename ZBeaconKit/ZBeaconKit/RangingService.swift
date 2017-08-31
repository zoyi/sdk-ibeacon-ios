//
//  RangingService.swift
//  ZBeaconKit
//
//  Created by sean on 08/16/17.
//  Copyright © 2017 ZOYI. All rights reserved.
//
import Foundation
import CoreLocation

protocol RangingServiceDelegate: class {
  func didRangeBeacon(_ beacon: CLBeacon, forRegion region: CLBeaconRegion)
  func didFailRangeBeacon(forRegion region: CLBeaconRegion)
}

final class RangingService: LocationService {

  // MARK: - Properties

  var region: CLBeaconRegion? {
    willSet(newRegion) {
      if region != nil {
        // no action
      } else if !locationManager.rangedRegions.isEmpty && !region!.isEqual(newRegion) {
        stopRanging()
      }
    }
    didSet {
      self.startRanging()
    }
  }
  weak var delegate: RangingServiceDelegate?

  // MARK: - Initialize

  override init() {
    super.init()
  }

  convenience init(region: CLBeaconRegion) {
    self.init()
    self.region = region
  }

  deinit {
    self.stopRanging()
  }

  // MARK: - Ranging methods

  func startRanging() {
    guard self.region != nil else {
      dlog("Cancel to start ranging because region is nil")
      return
    }
    self.activeLocationManager()
    self.locationManager.startRangingBeacons(in: self.region!)
    dlog("Start ranging for region: \(self.region!)")
  }

  func stopRanging() {
    guard self.region != nil else {
      dlog("Cancel to stop ranging because region is nil")
      return
    }
    self.locationManager.stopRangingBeacons(in: self.region!)
    self.inactiveLocationManager()
    dlog("Stop ranging for region: \(self.region!)")
  }

  // MARK: - Location Manager Delegate methods

  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
    guard manager.isEqual(self.locationManager) else { return }

    var rangedBeacon: CLBeacon? = nil
    for beacon in beacons {
      if beacon.proximityUUID.uuidString == region.proximityUUID.uuidString {
        if rangedBeacon == nil {
          rangedBeacon = beacon
        } else if rangedBeacon!.rssi < beacon.rssi {
          rangedBeacon = beacon
        }
      }
    }

    if rangedBeacon != nil {
      dlog("did range beacon: \(rangedBeacon!), for region: \(region)")
      self.delegate?.didRangeBeacon(rangedBeacon!, forRegion: region)
    } else {
      dlog("did fail range beacon for region: \(region)")
      self.delegate?.didFailRangeBeacon(forRegion: region)
    }
  }

  func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
    dlog("did fail range beacon for region: \(region), with error: \(error)")
    self.delegate?.didFailRangeBeacon(forRegion: region)
  }
}
