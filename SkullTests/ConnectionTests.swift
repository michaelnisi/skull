//
//  ConnectionTests.swift
//  Skull
//
//  Created by Michael Nisi on 16.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import XCTest

class ConnectionTests: XCTestCase {
  var db: Skull?
  let filename: String = "affinity.db"

  override func setUp () {
    super.setUp()
    rm(filename) // you never know
  }

  override func tearDown () {
    db!.close()
    XCTAssertNil(rm(filename))
    super.tearDown()
  }

  func testOpen() {
    if let url = documents(filename) {
      db = Skull()
      XCTAssertNil(db!.open(url: url))
      XCTAssertNil(db!.open(url: url))
    } else {
      XCTFail("invalid db URL")
    }
    XCTAssertNil(db!.open())
    XCTAssertNil(db!.open())
  }

  func testClose () {
    if let url = documents(filename) {
      db = Skull()
      XCTAssertNil(db!.open(url: url))
      XCTAssertNil(db!.close())
      if let found = db!.close() {
        let wanted = NSError(
          domain: SkullErrorDomain
        , code: 0
        , userInfo: ["message": "not open"]
        )
        XCTAssertEqual(found, wanted)
      } else {
        XCTFail("should error")
      }
    } else {
      XCTFail("invalid db URL")
    }
  }
}
