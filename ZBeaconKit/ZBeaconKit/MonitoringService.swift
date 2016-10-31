//
//  MonitoringService.swift
//  ZBeaconKit
//
//  Created by 이수완 on 2016. 10. 31..
//  Copyright © 2016년 ZOYI. All rights reserved.
//

import Foundation
import CoreLocation

protocol MonitoringServiceDelegate: class {
  func didEnterRegion(region: CLBeaconRegion)
  func didExitRegion(region: CLBeaconRegion)
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

  func isResponsibleFor(region: CLRegion, manager: CLLocationManager) -> Bool {
    return region.isEqual(beaconRegion)
      && manager.isEqual(locationManager)
      && manager.monitoredRegions.contains(region)
  }

  // MARK: - Monitoring methods

  func startMonitoring(withRegion region: CLBeaconRegion) {
    self.beaconRegion = region
    self.turnOnMonitoring()
  }

  private func prepareMonitoring() {
    dlog("Prepare to start monitoring...")

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
      break
    case .AuthorizedWhenInUse, .Denied, .Restricted:
      dlog("Couldn't turn on monitoring: Required Location Access (Always) missing.")
    case .NotDetermined:
      dlog("About to request location authorization.")
      self.locationManager.requestAlwaysAuthorization()
    }
  }

  private func turnOnMonitoring() {
    guard let region = beaconRegion else { return }
    dlog("Start monitoring: \(beaconRegion)")
    self.locationManager.startMonitoringForRegion(region)
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
    guard region.isEqual(beaconRegion) && manager.isEqual(locationManager) else { return }
    if beaconRegion != nil {
      self.delegate?.didEnterRegion(beaconRegion!)
    }
  }

  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    if beaconRegion != nil {
      self.delegate?.didExitRegion(beaconRegion!)
    }
  }
}
