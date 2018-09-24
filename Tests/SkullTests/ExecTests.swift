//
//  ExecTests.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016-2017 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Skull

enum SQLiteTypeAffinity: String {
  case NULL = "null"
  case INTEGER = "integer"
  case REAL = "real"
  case TEXT = "text"
  case BLOB = "blob"
}

class ExecTests: XCTestCase {
  var db: Skull!

  override func setUp() {
    super.setUp()
    db = try! Skull()
  }

  func load() throws -> String? {
    return """
      CREATE TABLE t1(t TEXT, nu NUMERIC, i INTEGER, r REAL, no BLOB);
      INSERT INTO t1 VALUES('500.0', '500.0', '500.0', '500.0', '500.0');
      SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1;

      DELETE FROM t1;
      INSERT INTO t1 VALUES(500.0, 500.0, 500.0, 500.0, 500.0);
      SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1;

      DELETE FROM t1;
      INSERT INTO t1 VALUES(500, 500, 500, 500, 500);
      SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1;

      DELETE FROM t1;
      INSERT INTO t1 VALUES(x'0500', x'0500', x'0500', x'0500', x'0500');
      SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1;

      DELETE FROM t1;
      INSERT INTO t1 VALUES(NULL,NULL,NULL,NULL,NULL);
      SELECT typeof(t), typeof(nu), typeof(i), typeof(r), typeof(no) FROM t1;
    """
  }

  func testVersion() {
    var found: String? = nil
    try! db.exec("SELECT sqlite_version();") { er, row in
      found = row["sqlite_version()"]
      return 0
    }
//    print(found)
    XCTAssertNotNil(found)
  }

  func testThrowing() {
    try! db.exec("")

    XCTAssertThrowsError(try db.exec("SELECT wtf();"))
    XCTAssertThrowsError(try db.exec("Oh Hi"))
  }

  func testExec() {
    typealias Row = [String:String]
    func row(_ t: [SQLiteTypeAffinity]) -> Row {
      let names = ["t", "nu", "i", "r", "no"]
      var row = [String:String]()
      for (i, type) in t.enumerated() {
        let name = names[i]
        row["typeof(\(name))"] = type.rawValue
      }
      return row
    }
    typealias Rows = [Row]
    func rows () -> Rows {
      let types = [
        [.TEXT, .INTEGER, .INTEGER, .REAL, .TEXT],
        [.TEXT, .INTEGER, .INTEGER, .REAL, .REAL],
        [.TEXT, .INTEGER, .INTEGER, .REAL, .INTEGER],
        [.BLOB, .BLOB, .BLOB, .BLOB, .BLOB],
        [.NULL, .NULL, .NULL, .NULL, SQLiteTypeAffinity.NULL]
      ]
      return types.map { type in
        row(type)
      }
    }
    let sql = try! load()
    var count = 0
    let r = rows()
    try! db.exec(sql!) { er, found in
      if er != nil {
        XCTFail("should not error")
      }
      let wanted = r[count]
      count += 1
      XCTAssertEqual(found, wanted)
      return 0
    }
    try! db.exec("SELECT * FROM t1;")
    XCTAssertEqual(count, r.count)
  }

  func testPragmas() {
    let pragmas = [
      "application_id",
      "auto_vacuum",
      "automatic_index",
      "busy_timeout",
      "cache_size",
      "cache_spill",
      "cell_size_check",
      "checkpoint_fullfsync",
      "collation_list",
      "compile_options",
      "data_version",
      "database_list",
      "defer_foreign_keys",
      "encoding",
      "foreign_key_check",
      "foreign_keys",
      "freelist_count",
      "fullfsync",
      "integrity_check",
      "journal_mode",
      "journal_size_limit",
      "legacy_file_format",
      "locking_mode",
      "max_page_count",
      "mmap_size",
      "page_count",
      "page_size",
      "query_only",
      "quick_check",
      "read_uncommitted",
      "recursive_triggers",
      "reverse_unordered_selects",
      "schema_version",
      "secure_delete",
      "shrink_memory",
      "soft_heap_limit",
      "stats",
      "synchronous",
      "temp_store",
      "threads",
      "user_version",
      "wal_autocheckpoint",
      "wal_checkpoint",
      "writable_schema",
    ]

    typealias Pragma = [String : String]

    let found = pragmas.reduce([String : [Pragma]]()) { acc, p in
      var pragmas = [Pragma]()
      let sql = "PRAGMA \(p);"
      try! db.exec(sql) { er, pragma in
        if er != nil {
          XCTFail("should not error")
        }
        pragmas.append(pragma)
        return 0
      }
      var d = acc
      d[p] = pragmas
      return d
    }

    for p in pragmas {
      XCTAssert(found.keys.contains(p))
    }
  }

  func testFalsePragma() {
    try! db.exec("PRAGMA wtf;") { er, pragma in
      XCTFail()
      return 0
    }
  }

  func testExecAbort() {
    let sql = try! load()
    var count = 0
    var thrown = false
    do {
      try db.exec(sql!) { er, found in
        if er != nil {
          XCTFail("should not error")
        }
        count += 1
        return 1
      }
    } catch SkullError.sqliteError(let code, let msg) {
      XCTAssertEqual(code, 4)
      XCTAssert(msg == "callback requested query abort" || msg == "query aborted")
      XCTAssertEqual(count, 1)
      thrown = true
    } catch {
      XCTFail("should throw expected error")
    }
    XCTAssert(thrown, "should throw")
  }
}
