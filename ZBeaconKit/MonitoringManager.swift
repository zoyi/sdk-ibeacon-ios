//
//  MonitoringManager.swift
//  ZBeaconKit
//
//  Created by 이수완 on 2016. 10. 31..
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol MonitoringManagerDelegate: class {
  func didEnterBeaconRegion(uuid: String, major: Int, minor: Int, forReigon region: CLRegion)
  func didExitBeaconRegion(uuid: String, major: Int, minor: Int, forReigon region: CLRegion)
}

class MonitoringManager: RangingServiceDelegate, MonitoringServiceDelegate {

  // MARK: - Properties

  var beaconRegion: CLBeaconRegion!
  var monitoringService = MonitoringService()
  let rangingService = RangingService()

  weak var delegate: MonitoringManagerDelegate?

  // MARK: - Constructors

  init(region: CLBeaconRegion, delegate: MonitoringManagerDelegate? = nil) {
    precondition(region.major == nil)
    precondition(region.minor == nil)

    self.beaconRegion = region
    self.delegate = delegate
    self.monitoringService.delegate = self
    self.rangingService.delegate = self
  }

  // MARK: - MonitoringManager methods

  func startMonitoring() {
    self.monitoringService.startMonitoring(withRegion: self.beaconRegion)
  }

  func stopMonitoring() {
    self.monitoringService.stopMonitoring()
    self.rangingService.stopRanging()
  }

  // MARK: - Ranging methods

  fileprivate func startRanging() {
    self.rangingService.region = CLBeaconRegion(
      proximityUUID: self.beaconRegion.proximityUUID,
      identifier: self.beaconRegion.identifier)
  }

  fileprivate func stopRanging() {
    self.rangingService.stopRanging()
  }

  // MARK: - MonitoringServiceDelegate methods

  func didChangeState(_ region: CLBeaconRegion, state: CLRegionState) {
    if state == .inside {
      self.didEnterRegion(region)
    } else if state == .outside {
      self.didExitRegion(region)
    }
  }
  
  func didEnterRegion(_ region: CLBeaconRegion) {
    self.startRanging()
  }

  func didExitRegion(_ region: CLBeaconRegion) {
    let uuid = region.proximityUUID.uuidString
    let values = PrefStore.get(uuid: uuid)
    guard values.count == 2 else { return }

    PrefStore.clear(uuid: uuid)
    
    let (major, minor) = (values[0], values[1])
    self.delegate?.didExitBeaconRegion(uuid: uuid, major: major, minor: minor, forReigon: region)
  }

  // MARK: - Ranging Service delegate methods

  func didRangeBeacon(_ beacon: CLBeacon, forRegion region: CLBeaconRegion) {
    self.stopRanging()
    let uuid = beacon.proximityUUID.uuidString
    let major = beacon.major.intValue
    let minor = beacon.minor.intValue
    PrefStore.save(uuid: uuid, major: major, minor: minor)
    self.delegate?.didEnterBeaconRegion(uuid: uuid, major: major, minor: minor, forReigon: region)
  }

  func didFailRangeBeacon(forRegion region: CLBeaconRegion) {
    self.stopRanging()
  }
}
