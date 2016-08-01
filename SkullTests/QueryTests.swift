//
//  QueryTests.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest

class QueryTests: SkullTestCase {

  override func setUp() {
    filename = "some"
    super.setUp()
  }
  
  func testQuery() {
    let sql = "SELECT * FROM t1;"
    var count = 0
    try! db!.query(sql) { er, row in
      if er != nil {
        XCTFail("should not error")
      }
      if let r = row {
        XCTAssertEqual(r["t"] as? String, "500.0")
        XCTAssertEqual(r["nu"] as? Int, 500)
        XCTAssertEqual(r["i"] as? Int, 500)
        XCTAssertEqual(r["r"] as? Double, 500.0)
        XCTAssertEqual(r["no"] as? String, "500.0")
        
        XCTAssertEqual(r.count, 5)
        
        // You can map rows to unsorted lists of column names.
        let wanted = ["t", "nu", "i", "r", "no"]
        let found = r.map { $0.0 }
        for name in wanted {
          XCTAssert(found.contains(name))
        }
      } else {
        XCTFail("should have row")
      }
      count += 1
      return 0
    }
    XCTAssertEqual(count, 1)
  }
}
