//
//  GeneralMonitoringService.swift
//  ZBeaconKit
//
//  Created by Di Wu on 1/6/16.
//  Copyright © 2016 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol MonitoringServiceDelegate: class {
  func didEnterBeaconRegion(service: GeneralMonitoringService, beacon: CLBeacon?, forReigon region: CLRegion)
  func didExitBeaconRegion(service: GeneralMonitoringService, beacon: CLBeacon?, forReigon region: CLRegion)
}

final class GeneralMonitoringService: LocationService, RangingServiceDelegate {

  let rangingService = RangingService()

  var beaconRegion: CLBeaconRegion!

  var specificMonitoringService: MonitoringService?

  weak var delegate: MonitoringServiceDelegate?

  // MARK: - Constructors

  init(region: CLBeaconRegion, delegate: MonitoringServiceDelegate? = nil) {
    super.init()
    precondition(region.major == nil)
    precondition(region.minor == nil)
    self.beaconRegion = region
    self.delegate = delegate
    self.rangingService.delegate = self
  }
  
  // MARK: - Monitoring methods

  func isResponsibleFor(region: CLRegion, manager: CLLocationManager) -> Bool {
    return region.isEqual(beaconRegion)
           && manager.isEqual(locationManager)
           && manager.monitoredRegions.contains(region)
  }

  func startMonitoring() {
    dlog("Prepare to start monitoring... ")

    activeLocationManager()

    guard CLLocationManager.locationServicesEnabled() else {
      dlog("Couldn't turn on monitoring: Location services are not enabled.")
      return
    }

    guard CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) else {
      dlog("Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.")
      return
    }

    switch CLLocationManager.authorizationStatus() {
    case .AuthorizedAlways:
      self.turnOnMonitoring()
    case .AuthorizedWhenInUse, .Denied, .Restricted:
      dlog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
    case .NotDetermined:
      dlog("About to request location authorization.")
      locationManager.requestAlwaysAuthorization()
    }
  }

  func stopMonitoring() {
    dlog("Prepare to stop monitoring...")
    locationManager.stopMonitoringForRegion(beaconRegion)
    inactiveLocationManager()
  }

  func turnOnMonitoring() {
    dlog("Start monitoring: \(beaconRegion)")
    locationManager.startMonitoringForRegion(beaconRegion)
  }

  func startRanging() {
    rangingService.region = CLBeaconRegion(proximityUUID: beaconRegion.proximityUUID,
                                           identifier: beaconRegion.identifier)
  }

  // MARK: - Specific Monitoring methods
  func startSpecificMonitoring(withBeacon beacon: CLBeacon) {
    guard beacon.proximityUUID.UUIDString == beaconRegion.proximityUUID.UUIDString else { return }
    dlog("About to start specific monitoring for beacon: \(beacon)")
    let specificRegion = CLBeaconRegion(proximityUUID: beacon.proximityUUID,
      major: CLBeaconMajorValue(beacon.major.integerValue),
      identifier: beaconRegion.identifier + "-SPECIFIC")
    specificRegion.notifyEntryStateOnDisplay = true
    specificMonitoringService = MonitoringService(region: specificRegion, generalMonitoringService: self)
    specificMonitoringService?.startMonitoring()
  }

  func stopSpecificMonitoring() {
    dlog("About to stop specific monitoring for beacon: \(specificMonitoringService?.beaconRegion)")
    specificMonitoringService?.stopMonitoring()
    specificMonitoringService = nil
  }


  func didEnterSpecificRegion(region: CLRegion) {
    dlog("Did ENTER specific region")
  }

  func didExitSpecificRegion(region: CLRegion) {
    guard region.isSpecific() else { return }
    stopSpecificMonitoring()
    self.delegate?.didExitBeaconRegion(self, beacon: nil, forReigon: region)
    startRanging()
  }

  // MARK: - Location Manager Delegate methods

  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    guard manager.isEqual(locationManager) else { return }
    switch status {
    case .AuthorizedAlways:
      self.turnOnMonitoring()
    case .AuthorizedWhenInUse, .Denied, .Restricted:
      dlog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
    default: break
    }
  }

  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard !region.isSpecific() && region.isEqual(beaconRegion) && manager.isEqual(locationManager) else { return }
    dlog("did enter region: \(region)")
    startRanging()
  }

  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    dlog("did exit region: \(region)")
    stopSpecificMonitoring()
  }

  func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    dlog("manager :\(manager), did start monitoring region: \(region)")
  }

  func locationManager(
    manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    forRegion region: CLRegion)
  {
    guard isResponsibleFor(region, manager: manager) else { return }

    var stateString: String
    switch state {
    case .Inside:
      stateString = "Inside"
      startRanging()
    case .Outside:
      stateString = "Outside"
    case .Unknown:
      stateString = "Unknown"
    }
    dlog("locationManager did change state to \(stateString), for region: \(region)")
  }


  // MARK: - Ranging Service delegate methods

  func didRangeBeacon(beacon: CLBeacon, forRegion region: CLBeaconRegion) {
    dlog("did range beacon: \(beacon), for region: \(region)")
    rangingService.stopRanging()
    delegate?.didEnterBeaconRegion(self, beacon: beacon, forReigon: region)
    startSpecificMonitoring(withBeacon: beacon)
  }
}
