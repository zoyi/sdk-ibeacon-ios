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

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

