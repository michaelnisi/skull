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
    db = Skull()
    try! db.open()
  }
  
  override func tearDown () {
    try! db.close()
    defer {
      super.tearDown()
    }
  }
  
  func load () throws -> String? {
    let bundle = NSBundle(forClass: self.dynamicType)
    return try sqlFromBundle(bundle, withName: "affinity")
  }
  
  func testVersion () {
    try! db.exec("select sqlite_version()") { er, row in
      if er != nil {
        XCTFail("should not error")
      }
      if let found = row["sqlite_version()"] {
        print("** SQLite Version \(found)")
        // XCTAssertEqual(found, "3.8.10.2", "should be expected version")
      } else {
        XCTFail("Should find version")
      }
      return 0
    }
  }
  
  func testExec () {
    typealias Row = [String:String]
    func row (t: [SQLiteTypeAffinity]) -> Row {
      let names = ["t", "nu", "i", "r", "no"]
      var row = [String:String]()
      for (i, type) in t.enumerate() {
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
      let wanted = r[count++]
      XCTAssertEqual(found, wanted)
      return 0
    }
    try! db.exec("SELECT * FROM t1")
    XCTAssertEqual(count, r.count)
  }
  
  func testPragmas () {
    let pragmas = [
      "application_id",
      "auto_vacuum",
      "automatic_index",
      "busy_timeout",
      "cache_size",
      "cache_spill",
      "case_sensitive_like",
      "checkpoint_fullfsync",
      "collation_list",
      "compile_options",
      "data_version",
      "database_list",
      "defer_foreign_keys",
      "encoding",
      "foreign_key_check",
      "foreign_key_list",
      "foreign_keys",
      "freelist_count",
      "fullfsync",
      "ignore_check_constraints",
      "incremental_vacuum",
      "index_info",
      "index_list",
      "integrity_check",
      "journal_mode",
      "journal_size_limit",
      "legacy_file_format",
      "locking_mode",
      "max_page_count",
      "mmap_size",
      "page_count",
      "page_size",
      "parser_trace",
      "query_only",
      "quick_check",
      "read_uncommitted",
      "recursive_triggers",
      "reverse_unordered_selects",
      "schema_version",
      "secure_delete",
      "shrink_memory",
      "soft_heap_limit",
      "synchronous",
      "table_info",
      "temp_store",
      "threads",
      "user_version",
      "vdbe_addoptrace",
      "vdbe_debug",
      "vdbe_listing",
      "vdbe_trace",
      "wal_autocheckpoint",
      "wal_checkpoint",
      "writable_schema"
    ]
    let sql = pragmas.map { "PRAGMA \($0);" }.joinWithSeparator("")
    try! db.exec(sql) { er, found in
      if er != nil {
        XCTFail("should not error")
      }
      return 0
    }
  }
  
  func testExecAbort () {
    let sql = try! load()
    var count = 0
    var thrown = false
    do {
      try db.exec(sql!) { er, found in
        if er != nil {
          XCTFail("should not error")
        }
        count++
        return 1
      }
    } catch SkullError.SQLiteError(let code, let msg) {
      XCTAssertEqual(code, 4)
      XCTAssertEqual(msg, "callback requested query abort")
      XCTAssertEqual(count, 1)
      thrown = true
    } catch {
      XCTFail("should throw expected error")
    }
    XCTAssert(thrown, "should throw")
  }
}
