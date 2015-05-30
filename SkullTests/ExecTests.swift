//
//  ExecTests.swift
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import XCTest

enum SQLiteTypeAffinity: String {
  case NULL = "null"
  case INTEGER = "integer"
  case REAL = "real"
  case TEXT = "text"
  case BLOB = "blob"
}

class ExecTests: XCTestCase {
  var db: Skull!

  override func setUp () {
    super.setUp()
    db = Skull() // in-memory
    XCTAssertNil(db.open())
  }

  override func tearDown () {
    XCTAssertNil(db.close())
    super.tearDown()
  }

  func load () -> String {
    let (er, sql) = sqlFrom(NSBundle(forClass: self.dynamicType), "affinity")
    XCTAssertNil(er)
    XCTAssertNotNil(sql)
    return sql!
  }

  /*
  func testVersion () {
    XCTAssertNil(db.exec("select sqlite_version()") { er, row in
      XCTAssertNil(er)
      if let found = row["sqlite_version()"] {
        XCTAssertEqual(found, "3.8.5", "should be recommended version")
      } else {
        XCTFail("Should find version")
      }
      return 0
    })
  }
  */
  
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
      return types.map { type in
        row(type)
      }
    }
    let sql = load()
    var count = 0
    let r = rows()
    let er = db.exec(sql) { er, found in
      let wanted = r[count++]
      XCTAssertEqual(found, wanted)
      XCTAssertNil(er)
      return 0
    }
    XCTAssertNil(er)
    XCTAssertNil(db.exec("SELECT * FROM t1"), "should be ok without callback")
    XCTAssertEqual(count, r.count)
  }

  func testPragmas () {
    let pragmas = [
      "application_id"
    , "auto_vacuum"
    , "automatic_index"
    , "busy_timeout"
    , "cache_size"
    , "cache_spill"
    , "case_sensitive_like"
    , "checkpoint_fullfsync"
    , "collation_list"
    , "compile_options"
    , "data_version"
    , "database_list"
    , "defer_foreign_keys"
    , "encoding"
    , "foreign_key_check"
    , "foreign_key_list"
    , "foreign_keys"
    , "freelist_count"
    , "fullfsync"
    , "ignore_check_constraints"
    , "incremental_vacuum"
    , "index_info"
    , "index_list"
    , "integrity_check"
    , "journal_mode"
    , "journal_size_limit"
    , "legacy_file_format"
    , "locking_mode"
    , "max_page_count"
    , "mmap_size"
    , "page_count"
    , "page_size"
    , "parser_trace"
    , "query_only"
    , "quick_check"
    , "read_uncommitted"
    , "recursive_triggers"
    , "reverse_unordered_selects"
    , "schema_version"
    , "secure_delete"
    , "shrink_memory"
    , "soft_heap_limit"
    , "synchronous"
    , "table_info"
    , "temp_store"
    , "threads"
    , "user_version"
    , "vdbe_addoptrace²"
    , "vdbe_debug"
    , "vdbe_listing"
    , "vdbe_trace"
    , "wal_autocheckpoint"
    , "wal_checkpoint"
    , "writable_schema"
    ]
    let sql = "".join(pragmas.map {
      "PRAGMA \($0);";
    })
    XCTAssertNil(db.exec(sql) { er, found in
      XCTAssertNil(er)
      // println(found)
      return 0
    })
  }

  func testExecAbort () {
    let sql = load()
    var count = 0
    let er = db.exec(sql) { er, found in
      XCTAssertNil(er)
      count++
      return 1
    }
    if let found = er {
      let wanted = NSError(
        domain: SkullErrorDomain
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
