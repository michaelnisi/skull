//
//  SerialTests.swift
//  Skull
//
//  Created by Michael Nisi on 02/10/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Skull

class SerialTests: XCTestCase {
  
  func testExample() {
    let skull: DispatchQueue = DispatchQueue(label: "ink.codes.skull")
    let db = try! Skull()
    
    skull.async {
      let sql = "create table planets (id integer primary key, au double, name text);"
      try! db.exec(sql)
    }
    skull.async {
      let sql = "insert into planets values (?, ?, ?);"
      try! db.update(sql, 0, 0.4, "Mercury")
      try! db.update(sql, 1, 0.7, "Venus")
      try! db.update(sql, 2, 1, "Earth")
      try! db.update(sql, 3, 1.5, "Mars")
    }
    skull.sync {
      let sql = "select name from planets where au=1;"
      try! db.query(sql) { er, row in
        assert(er == nil)
        let name = row?["name"] as! String
        assert(name == "Earth")
        return 0
      }
    }
  }
}
