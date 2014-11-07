//
//  ExecTests.swift
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import UIKit
import XCTest

enum SQLiteTypeAffinity: String {
  case NULL = "null"
  case INTEGER = "integer"
  case REAL = "real"
  case TEXT = "text"
  case BLOB = "blob"
}

class ExecTests: XCTestCase {
  var db: Skull?

  override func setUp () {
    super.setUp()
    db = Skull() // in-memory
    XCTAssertNil(db!.open())
  }

  override func tearDown () {
    XCTAssertNil(db!.close())
    super.tearDown()
  }

  func load () -> String {
    let (er, sql) = sqlFrom(NSBundle(forClass: self.dynamicType), "affinity")
    XCTAssertNil(er)
    XCTAssertNotNil(sql)
    return sql!
  }

  func testExec () {
    typealias Row = [String:String]
    func row (t: [SQLiteTypeAffinity]) -> Row {
      let names = ["t", "nu", "i", "r", "no"]
      var row = [String:String]()
      for (i, type: SQLiteTypeAffinity) in enumerate(t) {
        row["typeof(\(names[i]))"] = type.rawValue
      }
      return row
    }
    typealias Rows = [Row]
    func rows () -> Rows {
      let types = [
        [.TEXT, .INTEGER, .INTEGER, .REAL, .TEXT]
      , [.TEXT, .INTEGER, .INTEGER, .REAL, .REAL]
      , [.TEXT, .INTEGER, .INTEGER, .REAL, .INTEGER]
      , [.BLOB, .BLOB, .BLOB, .BLOB, .BLOB]
      , [.NULL, .NULL, .NULL, .NULL, SQLiteTypeAffinity.NULL]
      ]
      var rows = Rows()
      for type in types {
        rows.append(row(type))
      }
      return rows
    }
    let sql = load()
    var count = 0
    let r = rows()
    XCTAssertNil(db!.exec(sql) { er, found in
      let wanted = r[count++]
      XCTAssertEqual(found, wanted)
      XCTAssertNil(er)
      return 0
    })
    XCTAssertNil(db!.exec("SELECT * FROM t1"), "should be ok without callback")
    XCTAssertEqual(count, r.count)
  }

  func testExecAbort () {
    let sql = load()
    var count = 0
    let er = db!.exec(sql) { er, found in
      XCTAssertNil(er)
      count++
      return 1
    }
    if let found = er {
      let wanted = NSError(
        domain: "com.michaelnisi.skull"
      , code: 4
      , userInfo: ["message": "callback requested query abort"]
      )
      XCTAssertEqual(found, wanted)
      XCTAssertEqual(count, 1)
    } else {
      XCTFail("should error")
    }
  }
}
