//
//  UpdateTests.swift
//  Skull
//
//  Created by Michael Nisi on 19.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import XCTest

class UpdateTests: XCTestCase {
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

  func testUpdate () {
    let sql = "INSERT INTO t1 VALUES (?,?,?,?,?)"
    XCTAssertNil(db!.update(sql, 500.0, 500.0, 500.0, 500.0, "500.0"))
    XCTAssertNil(db!.update(sql, "500.0", 500, 500, 500.0, "500.0"))
    var count = 0
    let er = db!.query("SELECT * FROM t1") { er, optrow in
      XCTAssertNil(er)
      count++
      if let row = optrow {
        XCTAssertEqual(row["t"] as String, "500.0")
        XCTAssertEqual(row["nu"] as Int, 500)
        XCTAssertEqual(row["i"] as Int, 500)
        XCTAssertEqual(row["r"] as Double, 500.0)
        XCTAssertEqual(row["no"] as String, "500.0")
      } else {
        XCTFail("should have row")
      }
      return 0
    }
    XCTAssertEqual(count, 3)
  }

  func testUpdateFail () {
    XCTAssertNil(db!.update("DELETE FROM t1"))
    XCTAssertNotNil(db!.update("INSERT INTO t1 VALUES (?,?,?,?,?"))
    XCTAssertNil(db!.update("INSERT INTO t1 VALUES (?,?,?,?,?)"))
    var count = 0
    let er = db!.query("SELECT * FROM t1") { er, optrow in
      XCTAssertNil(er)
      if let row = optrow {
        count++
        for column: String in ["t", "nu", "i", "r", "no"] {
          XCTAssertNil(row[column])
        }
      } else {
        XCTFail("should have row")
      }
      return 0
    }
    XCTAssertEqual(count, 1) // one empty row because we don't validate
  }

  func testTransaction () {
    let db = Skull()
    XCTAssertNil(db.open())
    XCTAssertNil(db.update("BEGIN IMMEDIATE;"))
    XCTAssertNil(db.update(
     "CREATE TABLE shows(id INTEGER PRIMARY KEY, title TEXT);"
    ))
    for show: String in ["Fargo", "Game Of Thrones", "The Walking Dead"] {
      XCTAssertNil(db.update(
        "INSERT INTO shows(id, title) VALUES(?, ?);", nil, show
      ))
    }
    XCTAssertNil(db.update("COMMIT;"))
    var count = 0
    XCTAssertNil(db.query("SELECT * FROM shows") { er, row in
      XCTAssertNil(er)
      XCTAssertNotNil(row)
      count++
      return 0
    })
    XCTAssertEqual(count, 3)

    XCTAssertEqual(db.cache.count, 5, "should cache statements")
    XCTAssertNil(db.query("SELECT * FROM shows") { er, row in
      XCTAssertNil(er)
      XCTAssertNotNil(row)
      return 0
    })
    XCTAssertNil(db.close(), "should finalize statements")
    XCTAssert(db.cache.isEmpty, "should purge statements")
  }
}
