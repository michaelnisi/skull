//
//  ConnectionTests.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest

class ConnectionTests: XCTestCase {

  func testInitWithURL() {
    let url = documentURL("test.db")!
    let db = try! Skull(url)
    XCTAssertEqual(String(db), "Skull: \(url.path!)")
  }
  
  func testInitWithInvalidURL() {
    let url = NSURL(string: "test.db")!
    var threw = false
    do {
      let _ = try Skull(url)
    } catch SkullError.InvalidURL {
      threw = true
    } catch {
      XCTFail("should not throw unexpected error")
    }
    XCTAssert(threw)
  }
  
  func testInitWithoutURL() {
    let db = try! Skull()
    XCTAssertNil(db.url)
  }
}
