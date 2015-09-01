import XCTest

class ConnectionTests: XCTestCase {
  var db: Skull!
  let filename: String = "affinity.db"

  override func setUp () {
    super.setUp()
    do {
      try rm(filename)
    } catch {
      XCTAssert(true, "nothing to remove")
    }
  }

  override func tearDown () {
    do {
      try db.close()
      try rm(filename)
    } catch {
      XCTAssert(true, "nothing to close or remove")
    }
    defer {
      super.tearDown()
    }
  }

  func testOpenURL () {
    guard let url = documents(filename) else {
      return XCTAssert(false, "should be valid URL")
    }
    db = Skull()
    let desc = "Skull: closed"
    XCTAssertEqual(String(db), desc)
    try! db.open(url)
    XCTAssertNotEqual(String(db), desc)
    var thrown = false
    do {
      try db.open(url)
    } catch {
      thrown = true
    }
    XCTAssert(thrown, "should throw")
  }
  
  func testOpenInMemory () {
    db = Skull()
    XCTAssertEqual(String(db), "Skull: closed")
    try! db.open()
    var thrown = false
    do {
      try db.open()
    } catch {
      thrown = true
    }
    XCTAssert(thrown, "should throw")
  }

  func testClose () {
    guard let url = documents(filename) else {
      return XCTAssert(false, "should be valid URL")
    }
    db = Skull()
    var thrown = false
    do {
      try db.close()
    } catch SkullError.NotOpen {
      thrown = true
    } catch {
      XCTFail("should not throw unexpected error")
    }
    XCTAssert(thrown, "should throw")
    try! db.open(url)
    try! db.close()
  }
}
