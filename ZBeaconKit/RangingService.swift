//
//  RangingService.swift
//  ZBeaconKit
//
//  Created by sean on 08/16/17.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol RangingServiceDelegate: class {
  func didRangeBeacon(_ beacon: CLBeacon, forRegion region: CLBeaconRegion)
  func didFailRangeBeacon(forRegion region: CLBeaconRegion)
}

/**
 * CLLocationManagerDelegate method didRangeBeacons will not get called when
 * delegate method was implemented other than UIViewController.
 */
final class RangingService: UIViewController, CLLocationManagerDelegate {
  let locationManager = CLLocationManager()
  // MARK: - Properties

  var region: CLBeaconRegion? {
    willSet(newRegion) {
      if !self.locationManager.rangedRegions.isEmpty && region?.isEqual(newRegion) == false {
        self.stopRanging()
      }
    }
    didSet {
      self.startRanging()
    }
  }
  weak var delegate: RangingServiceDelegate?

  // MARK: - Initialize
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  convenience init() {
    self.init(nibName: nil, bundle: nil)
  }

  deinit {
    self.stopRanging()
  }

  // MARK: - Ranging methods

  func startRanging() {
    guard let region = self.region else {
      dlog("Cancel to start ranging because region is nil")
      return
    }

    self.locationManager.delegate = self
    self.locationManager.startRangingBeacons(in: region)
    dlog("Start ranging for region: \(region)")
  }

  func stopRanging() {
    guard let region = self.region else {
      dlog("Cancel to stop ranging because region is nil")
      return
    }
    self.locationManager.stopRangingBeacons(in: region)
    dlog("Stop ranging for region: \(region)")
  }

  // MARK: - Location Manager Delegate methods
  
  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    dlog("Location state: \(state.rawValue) for region: \(region)")
  }
  
  func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion) {
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

  func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailFor region: CLBeaconRegion,
    withError error: Error) {
    dlog("did fail range beacon for region: \(region), with error: \(error)")
    self.delegate?.didFailRangeBeacon(forRegion: region)
  }
}
