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

  let manager = Manager(email: "YOUR_EMAIL", authToken: "YOUR_AUTH_TOKEN", brandId: 1, target: .Production)

  override func viewDidLoad() {
    super.viewDidLoad()
    Manager.debugMode = true
    Manager.customerId = self.generateSampleCustomerId()
  }

  func generateSampleCustomerId() -> String {
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    let deviceIdWithSalt = deviceId! + "YOUR_SALT"
    return deviceIdWithSalt.hmac(.sha512, key: "YOUR_KEY_FOR_HMAC")
  }

  @IBAction func buttonTapped(_ sender: AnyObject) {
    print("start button tapped")
    manager.start()
  }

  @IBAction func stopTapped(_ sender: AnyObject) {
    print("stop button tapped")
    manager.stop()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

