//
//  ZBeaconKitTests.swift
//  ZBeaconKitTests
//
//  Created by Di Wu on 12/21/15.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import XCTest
@testable import ZBeaconKit

class ZBeaconKitTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock {
      // Put the code you want to measure the time of here.
    }
  }

  func testNSNumberExtension() {
    print(NSNumber(short: 61463).hexValue)
    XCTAssertEqual(NSNumber(short: 61463).hexValue, "F017", "NSNumber extension hexValue test failed.")
  }

}
