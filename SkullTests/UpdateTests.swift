//
//  UpdateTests.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest

class UpdateTests: SkullTestCase {

  override func setUp() {
    filename = "some"
    super.setUp()
    
    var count = 0
    try! db.query("SELECT * FROM t1;") { error, row in
      XCTAssertNil(error)
      XCTAssertNotNil(row)
      count += 1
      return 0
    }
    XCTAssertEqual(count, 1)
  }
  
  func testUpdate() {
    let sql = "INSERT INTO t1 VALUES (?,?,?,?,?);"
    try! db.update(sql, 500.0, 500.0, 500.0, 500.0, "500.0")
    try! db.update(sql, "500.0", 500, 500, 500.0, "500.0")
    var count = 0
    try! db.query("SELECT * FROM t1;") { error, row in
      XCTAssertNil(error)

      guard let r = row else {
        XCTFail("should have row")
        return -1
      }
      
      XCTAssertEqual(r["t"] as? String, "500.0")
      XCTAssertEqual(r["nu"] as? Int, 500)
      XCTAssertEqual(r["i"] as? Int, 500)
      XCTAssertEqual(r["r"] as? Double, 500.0)
      XCTAssertEqual(r["no"] as? String, "500.0")
      
      count += 1
  
      return 0
    }
    XCTAssertEqual(count, 3)
  }

  func testUpdateFail() {
    try! db.update("DELETE FROM t1;")
    do {
      try db.update("INSERT INTO t1 VALUES (?,?,?,?,?")
    } catch SkullError.SQLiteError(let code, let msg) {
      XCTAssertEqual(code, 1)
      XCTAssertEqual(msg, "near \"?\": syntax error")
    } catch {
      XCTFail("should not throw unexpected error")
    }
    try! db.update("INSERT INTO t1 VALUES (?,?,?,?,?);")
    var count = 0
    try! db.query("SELECT * FROM t1;") { er, optrow in
      XCTAssertNil(er)
      if let row = optrow {
        count += 1
        for column in ["t", "nu", "i", "r", "no"] {
          XCTAssertNil(row[column])
        }
      } else {
        XCTFail("should have row")
      }
      return 0
    }
    XCTAssertEqual(count, 1, "should be one empty row, because we don't validate")
  }

  func testTransaction() {
    try! db.update("BEGIN IMMEDIATE;")
    try! db.update("CREATE TABLE shows(id INTEGER PRIMARY KEY, title TEXT);")
    let shows = ["Fargo", "Game Of Thrones", "The Walking Dead"]
    for show: String in shows {
      try! db.update("INSERT INTO shows(id, title) VALUES (?,?);", nil, show)
    }
    try! db.update("COMMIT;")
    func selectShows() {
      var count = 0
      try! db.query("SELECT * FROM shows;") { er, row in
        XCTAssertNil(er)
        XCTAssertNotNil(row)
        count += 1
        return 0
      }
      XCTAssertEqual(count, 3)
    }
    selectShows()
    XCTAssertEqual(db.cache.count, 6, "should cache statements")
    selectShows()
    try! db.close()
    XCTAssert(db.cache.isEmpty, "should purge statements")
  }
}
