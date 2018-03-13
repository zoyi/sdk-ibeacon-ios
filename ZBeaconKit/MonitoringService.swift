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
  func didChangeState(_ region: CLBeaconRegion, state: CLRegionState)
}

final class MonitoringService: UIViewController, CLLocationManagerDelegate {
  let locationManager = CLLocationManager()
  var isMonitoring = false
  var beaconRegion: CLBeaconRegion?
  weak var delegate: MonitoringServiceDelegate?

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
    
    self.activeLocationManager()
    self.prepareMonitoring()
  }
  
  func activeLocationManager() {
    self.locationManager.delegate = self
  }
  
  func inactiveLocationManager() {
    self.locationManager.delegate = nil
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
    dlog("[INFO] Stop monitoring for region: \(region)")
    self.locationManager.stopMonitoring(for: region)
    self.beaconRegion = nil
    self.isMonitoring = false
  }

  fileprivate func turnOnMonitoring() {
    guard let region = self.beaconRegion else { return }
    dlog("[INFO] Start monitoring for region: \(region)")
    self.locationManager.startMonitoring(for: region)
    self.isMonitoring = true
  }

  fileprivate func prepareMonitoring() {
    dlog("[INFO] Prepare to start monitoring...")

    guard CLLocationManager.locationServicesEnabled() else {
      dlog("[ERR] Couldn't turn on monitoring: Location services are not enabled.")
      return
    }

    guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) else {
      dlog("[ERR] Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.")
      return
    }

    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways:
      break
    case .authorizedWhenInUse, .denied, .restricted:
      dlog("[ERR] Couldn't turn on monitoring: Required Location Access (Always) missing.")
    case .notDetermined:
      dlog("[INFO] About to request location authorization.")
      self.locationManager.requestAlwaysAuthorization()
    }
  }

  // MARK: - Location Manager Delegate methods

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    guard manager.isEqual(locationManager) else { return }
    switch status {
    case .authorizedAlways:
      if self.beaconRegion != nil && !self.isMonitoring {
        self.turnOnMonitoring()
      }
    case .authorizedWhenInUse, .denied, .restricted:
      dlog("[ERR] Couldn't turn on monitoring: Required Location Access (Always) missing.")
    default: break
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    if let beaconRegion = region as? CLBeaconRegion {
      dlog("[INFO] Detect state \(state.rawValue) for region (\(beaconRegion)")
      self.delegate?.didChangeState(beaconRegion, state: state)
      debugDelegate?.receive(with: .state(region: beaconRegion, state: state))
    }
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    if let beaconRegion = region as? CLBeaconRegion {
      dlog("[INFO] Did enter monitoring for region: \(beaconRegion)")
      self.delegate?.didEnterRegion(beaconRegion)
      debugDelegate?.receive(with: .enter(region: beaconRegion))

    }
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard isResponsibleFor(region, manager: manager) else { return }
    if let beaconRegion = region as? CLBeaconRegion {
      dlog("[INFO] Did exit monitoring for region: \(beaconRegion)")
      self.delegate?.didExitRegion(beaconRegion)
      debugDelegate?.receive(with: .exit(region: beaconRegion))
    }
  }
}
