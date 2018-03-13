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
  var rangingQueue = [CLBeaconRegion]()
  var isRanging = false
  
  // MARK: - Properties

  var region: CLBeaconRegion? {
    willSet(newRegion) {
      if !self.locationManager.rangedRegions.isEmpty && region?.isEqual(newRegion) == false {
        self.stopRanging()
      }
      if let region = newRegion {
        self.rangingQueue.append(region)
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
    if #available(iOS 9.0, *){
      self.locationManager.allowsBackgroundLocationUpdates = true
    }
  }

  deinit {
    self.stopRanging()
  }

  // MARK: - Ranging methods

  func startRanging() {
    guard !self.isRanging else {
      dlog("[INFO] Ranging is happening .. will execute after finish current one")
      return
    }
    
    guard let region = self.rangingQueue.first else {
      dlog("[INFO] Cancel to start ranging because region is nil")
      return
    }

    self.isRanging = true
    self.locationManager.delegate = self
    self.locationManager.startRangingBeacons(in: region)
    dlog("[INFO] Start ranging for region: \(region)")
  }

  func stopRanging() {
    guard let region = self.rangingQueue.first else {
      dlog("[INFO] Cancel to stop ranging because region is nil")
      return
    }
    
    self.isRanging = false
    self.rangingQueue.remove(at: 0)
    self.locationManager.stopRangingBeacons(in: region)
    
    dlog("[INFO] Stop ranging for region: \(region)")
    
    //consume ranging queue
    if let range = self.rangingQueue.first, self.rangingQueue.count != 0 {
      dlog("[INFO] Consuming ranging queue for \(range)")
      self.startRanging()
    }
  }

  // MARK: - Location Manager Delegate methods
  
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

    if let rBeacon = rangedBeacon {
      dlog("[INFO] did range beacon: \(rBeacon), for region: \(region)")
      self.delegate?.didRangeBeacon(rBeacon, forRegion: region)
    } else {
      dlog("[INFO] did fail range beacon for region: \(region)")
      self.delegate?.didFailRangeBeacon(forRegion: region)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailFor region: CLBeaconRegion,
    withError error: Error) {
    dlog("[INFO] did fail range beacon for region: \(region), with error: \(error)")
    self.isRanging = false
    self.delegate?.didFailRangeBeacon(forRegion: region)
  }
}
