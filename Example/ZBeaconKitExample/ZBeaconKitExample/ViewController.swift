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
  var logText = ""
  var retryCount = 0
  
  @IBOutlet weak var logView: UITextView!
  
  override func viewDidLoad() {
    debugDelegate = self
    self.manager.delegate = self
    self.logView.isEditable = false
    self.logView.isSelectable = false
  }
  
  @IBAction func exportTapped(_ sender: Any) {
    if MFMailComposeViewController.canSendMail() {
      let composeVC = MFMailComposeViewController()
      composeVC.mailComposeDelegate = self
      composeVC.setToRecipients(["eng@zoyi.co"])
      composeVC.setSubject("ZBeaconKit log")
      composeVC.setMessageBody(self.logText, isHTML: false)
      self.present(composeVC, animated: true, completion: nil)
    }
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
  }
  
  func debug(with message: String, color: UIColor) {
    DispatchQueue.main.async { [weak self] in
      let attributedText = NSMutableAttributedString(attributedString: (self?.logView.attributedText)!)
      let newText = NSMutableAttributedString(string: message)
      newText.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: NSRange(location: 0, length: message.count))
      attributedText.append(newText)
      self?.logView.attributedText = attributedText
    }
  }
  
  func debug(with message: String) {
    self.logText += message
  }
  
  func receive(with event: ZBeaconEvent) {
    switch event {
    case .enter(let region):
      DispatchQueue.main.async { [weak self] in
        if UIApplication.shared.applicationState == .background {
          let body = region.proximityUUID.uuidString
          self?.sendNotification(with: "Enter to region", body: body)
        }
        self?.debug(with: "Enter to region:\n\t\(region.proximityUUID)\n", color: UIColor.black)
      }
    case .exit(let region):
      DispatchQueue.main.async { [weak self] in
        if UIApplication.shared.applicationState == .background {
          let body = region.proximityUUID.uuidString
          self?.sendNotification(with: "Exit from region", body: body)
        }
        self?.debug(with: "Exit from region:\n\t\(region.proximityUUID)\n", color: UIColor.black)
      }
    case .state(let region, let state):
      DispatchQueue.main.async { [weak self] in
        let area = state == .inside ? "inside" : state == .outside ? "outside" : "unknown"
        self?.debug(with: "Received state: \(area)\n\t\(region.proximityUUID)\n\n", color: UIColor.black)
        self?.manager.startRangingBeacons(in: region)
      }
    case .sent(let data, let event):
      DispatchQueue.main.async { [weak self] in
        if UIApplication.shared.applicationState == .background {
          self?.sendNotification(with: "Data has sent", body: "Data has sent to server for **\(event)** event\n\tfor \(data["ibeacon_uuid"]!)\n\n")
        }
        
        self?.debug(with: "Data has sent to server for **\(event)** event\n\tfor \(data["ibeacon_uuid"]!)\n\n", color: UIColor.blue)
      }
    case .error(let data, let event):
      DispatchQueue.main.async { [weak self] in
        if UIApplication.shared.applicationState == .background {
          self?.sendNotification(with: "Error sending data", body: "[Error] data sent **\(event)** event\n\tfor \(data["ibeacon_uuid"]!)\n\n")
        }
        
        self?.debug(with: "[Error] data sent **\(event)** event\n\tfor \(data["ibeacon_uuid"]!)\n\n", color: UIColor.blue)
      }
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    for beacon in beacons {
      if beacon.proximityUUID == region.proximityUUID {
        self.debug(with: "Found valid beacon from ranging\n\t\(region.proximityUUID)\n", color: UIColor.black)
        self.debug(with: "============= Ranging checking ============\n", color: UIColor.black)
        self.debug(with: "\(beacon)\n", color: UIColor.black)
        self.manager.stopRangingBeacons(in: region)
        self.retryCount = 0
        self.debug(with: "============== Checking end ==============\n\n", color: UIColor.black)
        break
      }
    }
   
    if self.retryCount == 10 {
      self.debug(with: "Stop ranging to validate for region:\n\t\(region.proximityUUID).\nReached max retry\n", color: UIColor.black)
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

