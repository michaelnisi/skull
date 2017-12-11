//
//  ColumnTests.swift
//  Skull
//
//  Created by Michael Nisi on 11.12.17.
//

import XCTest
@testable import Skull

class ColumnTests: XCTestCase {
  
  func testDescription() {
    let col = SkullColumn(name: "id", value: 123)
    XCTAssertEqual(col.description, "SkullColumn: { id, 123 }")
  }
  
}
