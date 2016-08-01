//
//  RowTests.swift
//  Skull
//
//  Created by Michael Nisi on 26/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest

class RowTests: XCTestCase {
  
  func testPerf() {
    let db = try! Skull()
    let sql = "CREATE TABLE show (title TEXT);"
    try! db.exec(sql) { error, row in
      XCTAssertNil(error)
      XCTAssertNil(row)
      return 0
    }
    for _ in 0..<10000 {
      try! db.exec("INSERT INTO show VALUES(\(random()));") { error, row in
        XCTAssertNil(error)
        XCTAssertNil(row)
        return 0
      }
    }
    
    // In this test we are interested in row creation and value access times,
    // specifically in comparing boxed and plain Dictionary as row. The test
    // showed that Dictionary is 67% better than a custom struct, therefor,
    // compromising API to enhance performance, rows are Dictionary now.
    
    self.measureBlock {
      try! db.query("SELECT * FROM show;") { error, row in
        XCTAssertNil(error)
        XCTAssertNotNil(row!["title"])
        return 0
      }
    }
  }
}
