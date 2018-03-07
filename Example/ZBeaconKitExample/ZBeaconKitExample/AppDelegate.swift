//
//  AppDelegate.swift
//  ZBeaconKitExample
//
//  Created by R3alFr3e on 2/21/18.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import UIKit
import ZBeaconKit

protocol DebugDelegate: class {
  func debug(with message: String)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  var inputPipe: Pipe!
  var outputPipe: Pipe!
  weak var delegate: DebugDelegate?
  
  let manager = Manager(email: "app@zoyi.co", authToken: "17bFLC5F3ddQNwSHKxSk", target: .Development)
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // if not simulator, open console pipe
    #if !((arch(i386) || arch(x86_64)) && os(iOS))
      openConsolePipe()
    #endif
    
    // Initialize ZBeacon Manager
    Manager.debugMode = true
    Manager.customerId = self.generateSampleCustomerId()
    
    if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil {
      self.manager.restart()
    }
    
    // Override point for customization after application launch.
    return true
  }
  
  func generateSampleCustomerId() -> String {
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    let deviceIdWithSalt = deviceId! + "YOUR_SALT"
    return deviceIdWithSalt.hmac(.sha512, key: "YOUR_KEY_FOR_HMAC")
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  @objc func handlePipeNotification(notification: Notification) {
    //note you have to continuously call this when you get a message
    //see this from documentation:
    //Note that this method does not cause a continuous stream of notifications to be sent. If you wish to keep getting notified, you’ll also need to call readInBackgroundAndNotify() in your observer method.
    inputPipe?.fileHandleForReading.readInBackgroundAndNotify()
    
    if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
      let str = String(data: data, encoding: String.Encoding.ascii) {
      
      //write the data back into the output pipe. the output pipe's write file descriptor points to STDOUT. this allows the logs to show up on the xcode console
      
      //outputPipe?.fileHandleForWriting.write(data)
      self.delegate?.debug(with: str)
      // `str` here is the log/contents of the print statement
      //if you would like to route your print statements to the UI: make
      //sure to subscribe to this notification in your VC and update the UITextView.
      //Or if you wanted to send your print statements to the server, then
      //you could do this in your notification handler in the app delegate.
    }
  }
  
  func openConsolePipe() {
    //open a new Pipe to consume the messages on STDOUT and STDERR
    inputPipe = Pipe()
    
    //open another Pipe to output messages back to STDOUT
    outputPipe = Pipe()
    
    guard let inputPipe = inputPipe, let outputPipe = outputPipe else {
      return
    }
    
    let pipeReadHandle = inputPipe.fileHandleForReading
    
    //from documentation
    //dup2() makes newfd (new file descriptor) be the copy of oldfd (old file descriptor), closing newfd first if necessary.
    
    //here we are copying the STDOUT file descriptor into our output pipe's file descriptor
    //this is so we can write the strings back to STDOUT, so it can show up on the xcode console
    dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)
    
    //In this case, the newFileDescriptor is the pipe's file descriptor and the old file descriptor is STDOUT_FILENO and STDERR_FILENO
    
    dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
    
    //listen in to the readHandle notification
    NotificationCenter.default.addObserver(self, selector: #selector(self.handlePipeNotification), name: FileHandle.readCompletionNotification, object: pipeReadHandle)
    
    //state that you want to be notified of any data coming across the pipe
    pipeReadHandle.readInBackgroundAndNotify()
  }
}

