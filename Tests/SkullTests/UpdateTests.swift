//
//  UpdateTests.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Skull

// TODO: Make UpdateTests less dumb

class UpdateTests: XCTestCase {

  var db: Skull!

  override func setUp() {
    super.setUp()
    
    db = try! Skull()

    let sql = [
      "CREATE TABLE t1(t TEXT, nu NUMERIC, i INTEGER, r REAL, no BLOB)",
      "INSERT INTO t1 VALUES('500.0', '500.0', '500.0', '500.0', '500.0')",
      "SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1",

      "DELETE FROM t1",
      "INSERT INTO t1 VALUES(500.0, 500.0, 500.0, 500.0, 500.0)",
      "SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1",

      "DELETE FROM t1",
      "INSERT INTO t1 VALUES(500, 500, 500, 500, 500)",
      "SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1",

      "DELETE FROM t1",
      "INSERT INTO t1 VALUES(x'0500', x'0500', x'0500', x'0500', x'0500')",
      "SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1",

      "DELETE FROM t1",
      "INSERT INTO t1 VALUES(NULL,NULL,NULL,NULL,NULL)",
      "SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1",
    ].joined(separator: ";\n")

    try! db.exec(sql)

    var count = 0
    try! db.query("SELECT * FROM t1;") { error, row in
      XCTAssertNil(error)
      XCTAssertNotNil(row)
      count += 1
      return 0
    }
    XCTAssertEqual(count, 1)
  }

  override func tearDown() {
    do {
      try db.close()
    } catch SkullError.notOpen {
    } catch {
      XCTFail("should not throw unexpected error")
    }
    defer {
      super.tearDown()
    }
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
      
      if count == 1 {
        XCTAssertEqual(r["t"] as? String, "500.0")
        XCTAssertEqual(r["nu"] as? Int, 500)
        XCTAssertEqual(r["i"] as? Int, 500)
        XCTAssertEqual(r["r"] as? Double, 500.0)
        XCTAssertEqual(r["no"] as? String, "500.0")
      }
      
      count += 1
      
      return 0
    }
    XCTAssertEqual(count, 3)
  }

  func testUpdateFail() {
    try! db.update("DELETE FROM t1;")
    do {
      try db.update("INSERT INTO t1 VALUES (?,?,?,?,?")
    } catch SkullError.sqliteError(let code, let msg) {
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
    try! db.flush()
    XCTAssert(db.cache.isEmpty, "should purge statements")
  }
}
