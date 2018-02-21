//
//  MonitoringService.swift
//  ZBeaconKit
//
//  Created by 이수완 on 2016. 10. 31..
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol MonitoringServiceDelegate: class {
  func didEnterRegion(_ region: CLBeaconRegion)
  func didExitRegion(_ region: CLBeaconRegion)
}

final class MonitoringService: LocationService {

  var beaconRegion: CLBeaconRegion?
  weak var delegate: MonitoringServiceDelegate?

  override init() {
    super.init()
    self.activeLocationManager()
    self.prepareMonitoring()
  }

  // MARK: - Help methods

  func isResponsibleFor(_ region: CLRegion, manager: CLLocationManager) -> Bool {
    return region.isEqual(beaconRegion)
      && manager.isEqual(locationManager)
      && manager.monitoredRegions.contains(region)
  }

  // MARK: - Monitoring methods

  func startMonitoring(withRegion region: CLBeaconRegion) {
    self.beaconRegion = region
    self.turnOnMonitoring()
  }

  func stopMonitoring() {
    guard let region = self.beaconRegion else { return }
    dlog("Stop monitoring for region: \(region)")
    self.locationManager.stopMonitoring(for: region)
    self.beaconRegion = nil
  }

  fileprivate func turnOnMonitoring() {
    guard let region = self.beaconRegion else { return }
    dlog("Start monitoring for region: \(region)")
    self.locationManager.startMonitoring(for: region)
  }

  fileprivate func prepareMonitoring() {
    dlog("Prepare to start monitoring...")

    guard CLLocationManager.locationServicesEnabled() else {
      dlog("Couldn't turn on monitoring: Location services are not enabled.")
      return
    }

    guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else {
      dlog("Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.")
      return
    }

    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways:
      break
    case .authorizedWhenInUse, .denied, .restricted:
      dlog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
    case .notDetermined:
      dlog("About to request location authorization.")
      self.locationManager.requestAlwaysAuthorization()
    }
  }

  // MARK: - Location Manager Delegate methods

  func locationManager(_ manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    guard manager.isEqual(locationManager) else { return }
    switch status {
    case .authorizedAlways:
      self.turnOnMonitoring()
    case .authorizedWhenInUse, .denied, .restricted:
      dlog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
    default: break
    }
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    if beaconRegion != nil {
      dlog("Did enter monitoring for region: \(region)")
      self.delegate?.didEnterRegion(beaconRegion!)
    }
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    if beaconRegion != nil {
      dlog("Did exit monitoring for region: \(region)")
      self.delegate?.didExitRegion(beaconRegion!)
    }
  }
}
