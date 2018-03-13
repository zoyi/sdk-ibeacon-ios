//
//  ViewController.swift
//  ZBeaconKitExample
//
//  Created by R3alFr3e on 2/21/18.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import UIKit
import CoreLocation
import ZBeaconKit
import UserNotifications
import MessageUI

class ViewController: UIViewController, DebugDelegate, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate {
  let manager = CLLocationManager()
  var retryCount = 0
  @IBOutlet weak var logView: UITextView!
  
  override func viewDidLoad() {
    debugDelegate = self
    self.manager.delegate = self
  }
  
  @IBAction func exportTapped(_ sender: Any) {
    let composeVC = MFMailComposeViewController()
    composeVC.mailComposeDelegate = self
    composeVC.setToRecipients(["eng@zoyi.co"])
    composeVC.setSubject("ZBeaconKit log")
    composeVC.setMessageBody(self.logView.text, isHTML: false)
    self.present(composeVC, animated: true, completion: nil)
  }
  
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func buttonTapped(_ sender: AnyObject) {
    print("start button tapped")
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    appDelegate?.manager.start()
  }
  
  @IBAction func stopTapped(_ sender: AnyObject) {
    print("stop button tapped")
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    appDelegate?.manager.stop()
  }
  
  @IBAction func clearLogs(_ sender: Any) {
    logView.text = ""
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func debug(with message: String) {
    DispatchQueue.main.async { [weak self] in
      self?.logView.text.append(message)
    }
  }
  
  func sent(with data: [String: Any]){
    DispatchQueue.main.async { [weak self] in
      if UIApplication.shared.applicationState == .background {
        let body = data.map({ (key, value)  in
          return "\(key):\(value) "
        }).joined()
        self?.sendNotification(with: "Data sent", body: body)
      }
    }
  }
  
  func enter(to region: CLRegion) {
    DispatchQueue.main.async {
      if UIApplication.shared.applicationState == .background {
        let beacon = region as? CLBeaconRegion
        let body = beacon?.proximityUUID.uuidString ?? ""
        self.sendNotification(with: "Enter to region", body: body)
      }
    }
  }
  
  func exit(from region: CLRegion) {
    DispatchQueue.main.async { [weak self] in
      if UIApplication.shared.applicationState == .background {
        let beacon = region as? CLBeaconRegion
        let body = beacon?.proximityUUID.uuidString ?? ""
        self?.sendNotification(with: "Exit from region", body: body)
      }
    }
  }
  
  func state(region: CLBeaconRegion, state: CLRegionState) {
    self.manager.startRangingBeacons(in: region)
  }
  
  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    self.logView.text.append("Start Ranging to validate for region \(region)\n")
    self.logView.text.append("============= Ranging checking ============\n")
    for beacon in beacons {
      if beacon.proximityUUID == region.proximityUUID {
        self.logView.text.append("\(beacon)\n")
        self.manager.stopRangingBeacons(in: region)
        self.retryCount = 0
        break
      }
    }
    self.logView.text.append("============== Checking end ==============\n\n")
    if self.retryCount == 10 {
      self.manager.stopRangingBeacons(in: region)
    }
  }
  
  private func sendNotification(with title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default()
    let notification = UNNotificationRequest(identifier: "zbeacon-sdk", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(notification, withCompletionHandler: nil)
  }
}

