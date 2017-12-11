//
//  ErrorTests.swift
//  Skull
//
//  Created by Michael Nisi on 11.12.17.
//

import XCTest
@testable import Skull

class ErrorTests: XCTestCase {

  func testDescription() {
    XCTAssertEqual(
      SkullError.alreadyOpen("/some/where").description,
      "Skull: /some/where already open"
    )
    XCTAssertEqual(
      SkullError.failedToFinalize([]).description,
      "Skull: failed to finalize: []"
    )
    XCTAssertEqual(
      SkullError.invalidURL.description,
      "Skull: invalid URL"
    )
    XCTAssertEqual(
      SkullError.notOpen.description,
      "Skull: not open"
    )
    XCTAssertEqual(
      SkullError.sqliteError(9, "not good").description,
      "Skull: 9: not good"
    )
    XCTAssertEqual(
      SkullError.sqliteMessage("not good").description,
      "Skull: not good"
    )
    XCTAssertEqual(
      SkullError.unsupportedType.description,
      "Skull: unsupported type"
    )
  }
}
