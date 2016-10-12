//
//  AppDelegate.swift
//  ZBeacon
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2015 ZOYI. All rights reserved.
//

import UIKit
import ZBeaconKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  let manager = Manager(email: "app@zoyi.co", authToken: "17bFLC5F3ddQNwSHKxSk", brandId: 1)

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    Manager.debugMode = true
    Manager.customerId = self.generateSampleCustomerId()
    manager.start()
    print(Manager.customerId)
    print(Manager.packageId)
    return true
  }

  private func generateSampleCustomerId() -> String {
    let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString
    let deviceIdWithSalt = deviceId! + "YOUR_SALT"
    return deviceIdWithSalt.hmac(.SHA512, key: "YOUR_KEY_FOR_HMAC")
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    manager.stop()
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

