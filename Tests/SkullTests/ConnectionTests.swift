//
//  ConnectionTests.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Skull

class ConnectionTests: XCTestCase {

  func testInitWithURL() {
    let paths = NSSearchPathForDirectoriesInDomains(
      .documentDirectory, .userDomainMask, true
    )
    let path: String = paths[0]
    let url = URL(string: "test.db", relativeTo: URL(fileURLWithPath: path))!
    let db = try! Skull(url)
    XCTAssertEqual(db.description, "Skull: \(url.path)")
  }

  func testInitWithInvalidURL() {
    let url = URL(string: "test.db")!
    var threw = false
    do {
      let _ = try Skull(url)
    } catch SkullError.invalidURL {
      threw = true
    } catch {
      XCTFail("should not throw unexpected error")
    }
    XCTAssert(threw)
  }

  func testInitWithoutURL() {
    let db = try! Skull()
    XCTAssertNil(db.url)
    XCTAssertEqual(db.description, "Skull: in-memory")
  }
}
