//
//  MonitoringService.swift
//  ZBeaconKit
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

final class MonitoringService: LocationService {

  var beaconRegion: CLBeaconRegion!

  weak var generalMonitoringService: GeneralMonitoringService?

  // MARK: - Constructors
  init(region: CLBeaconRegion, generalMonitoringService: GeneralMonitoringService? = nil) {
    super.init()
    self.beaconRegion = region
    self.generalMonitoringService = generalMonitoringService
  }

  deinit {
    stopMonitoring()
  }

  // MARK: - Help methods

  func isResponsibleFor(region: CLRegion, manager: CLLocationManager) -> Bool {
    return region.isEqual(beaconRegion)
           && manager.delegate != nil
           && manager.isEqual(locationManager)
           && manager.monitoredRegions.contains(region)
  }

  // MARK: - Monitoring methods
  
  func startMonitoring() {
    dlog("Prepare to start monitoring...")

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
    dlog("About to stop specific monitoring for region: \(beaconRegion), manager: \(locationManager)")
    inactiveLocationManager()
    locationManager.stopMonitoringForRegion(beaconRegion)
  }

  func turnOnMonitoring() {
    locationManager.startMonitoringForRegion(beaconRegion)
  }


  // MARK: - Location Manager Delegate methods

  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    guard manager.isEqual(locationManager) else { return}
    switch status {
    case .AuthorizedAlways:
      self.turnOnMonitoring()
    case .AuthorizedWhenInUse, .Denied, .Restricted:
      dlog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
    default: break
    }
  }

  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard region.isSpecific() && region.isEqual(beaconRegion) && manager.isEqual(locationManager) else { return }
    dlog("did enter specific region: \(region)")
    generalMonitoringService?.didEnterSpecificRegion(region)
  }

  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    dlog("did exit specific region: \(region)")
    generalMonitoringService?.didExitSpecificRegion(region)
  }

  func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    dlog("did start monitoring specific region: \(region), manager: \(manager)")
  }

}
