//
//  ViewController.swift
//  ZBeacon
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import UIKit
import ZBeaconKit

class ViewController: UIViewController {

  let manager = Manager(email: "app@zoyi.co", authToken: "17bFLC5F3ddQNwSHKxSk", brandId: 69)

  override func viewDidLoad() {
    super.viewDidLoad()
    Manager.debugMode = true
    Manager.customerId = self.generateSampleCustomerId()
  }

  private func generateSampleCustomerId() -> String {
    let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString
    let deviceIdWithSalt = deviceId! + "YOUR_SALT"
    return deviceIdWithSalt.hmac(.SHA512, key: "YOUR_KEY_FOR_HMAC")
  }

  @IBAction func buttonTapped(sender: AnyObject) {
    print("start button tapped")
    manager.start()
  }

  @IBAction func stopTapped(sender: AnyObject) {
    print("stop button tapped")
    manager.stop()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

