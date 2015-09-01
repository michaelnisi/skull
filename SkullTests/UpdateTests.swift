import XCTest

class UpdateTests: XCTestCase {
  var db: Skull!
  
  func load () throws -> String? {
    let bundle = NSBundle(forClass: self.dynamicType)
    return try sqlFromBundle(bundle, withName: "some")
  }

  override func setUp () {
    super.setUp()
    db = Skull()
    try! db.open()
    let sql = try! load()
    try! db.exec(sql!) { er, found in
      if er != nil {
        XCTFail("should not error")
      }
      return 0
    }
  }

  override func tearDown () {
    do {
      try db.close()
    } catch SkullError.NotOpen {
    } catch {
      XCTFail("should not throw unexpected error")
    }
    defer {
      super.tearDown()
    }
  }

  func testUpdate () {
    let sql = "INSERT INTO t1 VALUES (?,?,?,?,?)"
    try! db.update(sql, 500.0, 500.0, 500.0, 500.0, "500.0")
    try! db.update(sql, "500.0", 500, 500, 500.0, "500.0")
    var count = 0
    try! db.query("SELECT * FROM t1") { er, optrow in
      if er != nil {
        XCTFail("should not error")
      }
      count++
      if let row = optrow {
        XCTAssertEqual(row["t"] as? String, "500.0")
        XCTAssertEqual(row["nu"] as? Int, 500)
        XCTAssertEqual(row["i"] as? Int, 500)
        XCTAssertEqual(row["r"] as? Double, 500.0)
        XCTAssertEqual(row["no"] as? String, "500.0")
      } else {
        XCTFail("should have row")
      }
      return 0
    }
    XCTAssertEqual(count, 3)
  }

  func testUpdateFail () {
    try! db.update("DELETE FROM t1")
    do {
      try db.update("INSERT INTO t1 VALUES (?,?,?,?,?")
    } catch SkullError.SQLiteError(let code, let msg) {
      XCTAssertEqual(code, 1)
      XCTAssertEqual(msg, "near \"?\": syntax error")
    } catch {
      XCTFail("should not throw unexpected error")
    }
    try! db.update("INSERT INTO t1 VALUES (?,?,?,?,?)")
    var count = 0
    try! db.query("SELECT * FROM t1") { er, optrow in
      if er != nil {
        XCTFail("should not error")
      }
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
    XCTAssertEqual(count, 1, "should be one empty row, because we don't validate")
  }

  func testTransaction () {
    try! db.update("BEGIN IMMEDIATE;")
    try! db.update("CREATE TABLE shows(id INTEGER PRIMARY KEY, title TEXT);")
    let shows = ["Fargo", "Game Of Thrones", "The Walking Dead"]
    for show: String in shows {
      try! db.update("INSERT INTO shows(id, title) VALUES(?, ?);", nil, show)
    }
    try! db.update("COMMIT;")
    func selectShows () {
      var count = 0
      try! db.query("SELECT * FROM shows") { er, row in
        if er != nil {
          XCTFail("should not error")
        }
        XCTAssertNotNil(row)
        count++
        return 0
      }
      XCTAssertEqual(count, 3)
    }
    selectShows()
    XCTAssertEqual(db.cache.count, 5, "should cache statements")
    selectShows()
    try! db.close()
    XCTAssert(db.cache.isEmpty, "should purge statements")
  }
}
