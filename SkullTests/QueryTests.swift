import XCTest

class QueryTests: XCTestCase {
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
    try! db.exec(sql!) { er, _ in
      if er != nil {
        XCTFail("should not error")
      }
      return 0
    }
  }

  override func tearDown () {
    try! db.close()
    defer {
      super.tearDown()
    }
  }

  func testQuery () {
    let sql = "SELECT * FROM t1"
    var count = 0
    try! db!.query(sql) { er, optrow in
      if er != nil {
        XCTFail("should not error")
      }
      if let row = optrow {
        XCTAssertEqual(row["t"] as? String, "500.0")
        XCTAssertEqual(row["nu"] as? Int, 500)
        XCTAssertEqual(row["i"] as? Int, 500)
        XCTAssertEqual(row["r"] as? Double, 500.0)
        XCTAssertEqual(row["no"] as? String, "500.0")
      } else {
        XCTFail("should have row")
      }
      count++
      return 0
    }
    XCTAssertEqual(count, 1)
  }
}
