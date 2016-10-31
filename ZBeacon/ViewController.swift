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

  @IBOutlet weak var logTextView: UITextView!

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    NSNotificationCenter.defaultCenter()
      .addObserver(self, selector: #selector(ViewController.sendDebug(_:)), name: "ZBeaconSendDebugNotification", object: nil)

    Manager.debugMode = true
    Manager.customerId = self.generateSampleCustomerId()
    manager.start()
  }

  private func generateSampleCustomerId() -> String {
    let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString
    let deviceIdWithSalt = deviceId! + "YOUR_SALT"
    return deviceIdWithSalt.hmac(.SHA512, key: "YOUR_KEY_FOR_HMAC")
  }

  func sendDebug(sender: AnyObject) {
    dispatch_async(dispatch_get_main_queue()) { [unowned self] in
      if let text = sender.object as? String {
        if let logs = self.logTextView.text {
          let logItems = logs.componentsSeparatedByString("\n\n")
          if logItems.count > 1000 {
            self.logTextView.text = text
          } else {
            self.logTextView.text = self.logTextView.text?.stringByAppendingString(text + "\n\n")
          }
        } else {
          self.logTextView.text = text
        }

      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

