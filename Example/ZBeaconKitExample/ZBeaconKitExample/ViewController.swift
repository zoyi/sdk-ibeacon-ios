//
//  ViewController.swift
//  ZBeaconKitExample
//
//  Created by R3alFr3e on 2/21/18.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
  let manager = CLLocationManager()
  
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

