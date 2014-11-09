//
//  QueryTests.swift
//  Skull
//
//  Created by Michael Nisi on 16.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import XCTest

class QueryTests: XCTestCase {
  var db: Skull?

  func load () -> String {
    let (er, sql) = sqlFrom(NSBundle(forClass: self.dynamicType), "some")
    XCTAssertNil(er)
    XCTAssertNotNil(sql)
    return sql!
  }

  override func setUp () {
    super.setUp()
    db = Skull()
    XCTAssertNil(db!.open()) // in-memory
    let sql = load()
    let er = db!.exec(sql) { er, found in
      XCTAssertNil(er)
      return 0
    }
    XCTAssertNil(er)
  }

  override func tearDown () {
    XCTAssertNil(db!.close())
    super.tearDown()
  }

  func testQuery () {
    let sql = "SELECT * FROM t1"
    var count = 0
    let er = db!.query(sql) { er, optrow in
      XCTAssertNil(er)
      if let row = optrow {
        XCTAssertEqual(row["t"] as String, "500.0")
        XCTAssertEqual(row["nu"] as Int, 500)
        XCTAssertEqual(row["i"] as Int, 500)
        XCTAssertEqual(row["r"] as Double, 500.0)
        XCTAssertEqual(row["no"] as String, "500.0")
      } else {
        XCTFail("should have row")
      }
      count++
      return 0
    }
    XCTAssertNil(er)
    XCTAssertEqual(count, 1)
  }
}
