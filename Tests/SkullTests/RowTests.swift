//
//  RowTests.swift
//  Skull
//
//  Created by Michael Nisi on 26/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Skull

class RowTests: XCTestCase {

  func _testPerf() {
    let db = try! Skull()
    let sql = "CREATE TABLE show (title TEXT);"
    try! db.exec(sql) { error, row in
      XCTAssertNil(error)
      XCTAssertNil(row)
      return 0
    }
    for _ in 0..<10000 {
      try! db.exec("INSERT INTO show VALUES(\(arc4random()));")
    }

    // In this test we are interested in row creation and value access times,
    // specifically in comparing boxed and plain `Dictionary` as row. The test
    // showed that Dictionary is 67% faster than a custom struct, therefor
    // `SkullRow` is a `typealias` for `Dictionary<String, AnyObject>`.

    self.measure {
      try! db.query("SELECT * FROM show;") { error, row in
        XCTAssertNil(error)
        XCTAssertNotNil(row!["title"])
        return 0
      }
    }
  }
}
