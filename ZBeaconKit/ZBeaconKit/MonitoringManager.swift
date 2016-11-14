//
//  MonitoringManager.swift
//  ZBeaconKit
//
//  Created by 이수완 on 2016. 10. 31..
//  Copyright © 2016년 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol MonitoringManagerDelegate: class {
  func didEnterBeaconRegion(beacon: CLBeacon?, forReigon region: CLRegion)
  func didExitBeaconRegion(beacon: CLBeacon?, forReigon region: CLRegion, rssiOnEnter rssi: Int?)
}

class MonitoringManager: RangingServiceDelegate, MonitoringServiceDelegate {

  var beaconRegion: CLBeaconRegion!
  var specificBeaconRegion: CLBeaconRegion?
  var rssiOnEnter: Int?
  let rangingService = RangingService()
  let monitoringService = MonitoringService()
  weak var delegate: MonitoringManagerDelegate?

  // MARK: - Constructors

  init(region: CLBeaconRegion, delegate: MonitoringManagerDelegate? = nil) {
    precondition(region.major == nil)
    precondition(region.minor == nil)
    self.beaconRegion = region
    self.delegate = delegate
    self.rangingService.delegate = self
    self.monitoringService.delegate = self
  }

  // MARK: - Monitoring Manager methods

  func startMonitoring() {
    self.startGeneralMonitoring()
  }

  func stopMonitoring() {
    self.stopGeneralMonitoring()
    self.stopSpecificMonitoring()
    self.stopRanging()
  }

  // MARK: - General Monitoring methods

  private func startGeneralMonitoring() {
    dlog("Start general monitoring")
    self.monitoringService.startMonitoring(withRegion: self.beaconRegion)
  }

  private func stopGeneralMonitoring() {
    dlog("Stop general monitoring")
    self.monitoringService.locationManager.stopMonitoringForRegion(self.beaconRegion)
  }

  // MARK: - Specific Monitoring methods

  private func startSpecificMonitoring(withBeacon beacon: CLBeacon) {
    guard beacon.proximityUUID.UUIDString == beaconRegion.proximityUUID.UUIDString else { return }
    dlog("Start specific monitoring")
    let specificRegion = CLBeaconRegion(proximityUUID: beacon.proximityUUID,
                                        major: CLBeaconMajorValue(beacon.major.integerValue),
                                        minor: CLBeaconMinorValue(beacon.minor.integerValue),
                                        identifier: beaconRegion.identifier + "-SPECIFIC")
    self.specificBeaconRegion = specificRegion
    let specificRegionWithoutMinor = CLBeaconRegion(proximityUUID: beacon.proximityUUID,
                                        major: CLBeaconMajorValue(beacon.major.integerValue),
                                        identifier: beaconRegion.identifier + "-SPECIFIC")
    specificRegionWithoutMinor.notifyEntryStateOnDisplay = true
    self.monitoringService.startMonitoring(withRegion: specificRegionWithoutMinor)
  }

  private func stopSpecificMonitoring() {
    guard let region = self.specificBeaconRegion else { return }
    dlog("Stop specific monitoring")
    self.monitoringService.locationManager.stopMonitoringForRegion(region)
  }

  // MARK: - Ranging methods

  private func startRanging() {
    self.rangingService.region = CLBeaconRegion(proximityUUID: beaconRegion.proximityUUID, identifier: beaconRegion.identifier)
  }

  private func stopRanging() {
    self.rangingService.stopRanging()
  }

  // MARK: - Monitoring Service delegate methods

  func didEnterRegion(region: CLBeaconRegion) {
    if region.isSpecific() {
      dlog("did enter specific region")
    } else {
      dlog("did enter general region")
      self.stopGeneralMonitoring()
      self.startRanging()
    }
  }

  func didExitRegion(region: CLBeaconRegion) {
    if region.isSpecific() {
      dlog("did exit specific region")
      self.stopSpecificMonitoring()
      if let region = self.specificBeaconRegion {
        self.delegate?.didExitBeaconRegion(nil, forReigon: region, rssiOnEnter: self.rssiOnEnter)
      }
      self.startGeneralMonitoring()
    } else {
      dlog("did exit general region")
    }
  }

  // MARK: - Ranging Service delegate methods

  func didRangeBeacon(beacon: CLBeacon, forRegion region: CLBeaconRegion) {
    self.stopRanging()
    self.rssiOnEnter = beacon.rssi
    self.delegate?.didEnterBeaconRegion(beacon, forReigon: region)
    self.startSpecificMonitoring(withBeacon: beacon)
  }
}
