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

  @IBOutlet weak var textView: UITextView!

  let manager = Manager(email: "app@zoyi.co", authToken: "17bFLC5F3ddQNwSHKxSk", brandId: 69, target: .Production)
  let testManager = TestManager()

  override func viewDidLoad() {
    super.viewDidLoad()
    Manager.debugMode = true
    Manager.customerId = self.generateSampleCustomerId()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(receivedLog(withNotification:)),
                                           name: TestManager.PRINT_LOG, object: nil)
  }

  func receivedLog(withNotification notification: NSNotification) {
    DispatchQueue.main.async {
      if let log = notification.userInfo?["log"] as? String {
        if let text = self.textView.text {
          self.textView.text = "\(text)\n\(log)"
        } else {
          self.textView.text = log
        }
      }
    }
  }

  func generateSampleCustomerId() -> String {
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    let deviceIdWithSalt = deviceId! + "YOUR_SALT"
    return deviceIdWithSalt.hmac(.sha512, key: "YOUR_KEY_FOR_HMAC")
  }

  @IBAction func buttonTapped(_ sender: AnyObject) {
    print("start button tapped")
    testManager.startTest()
//    manager.start()
  }

  @IBAction func stopTapped(_ sender: AnyObject) {
    print("stop button tapped")
//    testManager.stopTest()
//    manager.stop()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

