//
//  common.swift
//  Skull
//
//  Created by Michael Nisi on 22/06/16.
//  Copyright © 2016 Michael Nisi. All rights reserved.
//

import Foundation
import XCTest

/// Read a SQLite file into a string and return it.
///
/// - Parameter bundle: The resource bundle containing the file.
/// - Parameter name : The name of the file without extension.
///
/// - Returns: The SQL string.
///
/// - Throws: `SkullError.NoPath` if the file cannot be located.
func sqlFromBundle(bundle: NSBundle, withName name: String) throws -> String? {
  guard let path = bundle.pathForResource(name, ofType: "sql") else {
    throw SkullError.NoPath
  }
  return try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
}

/// The NSURL for the specified URL string relative to the Document directory.
/// 
/// - Parameter URLString: The URL string to initialize the NSURL object with
/// relative to the Document directory.
func documentURL(URLString: String) -> NSURL? {
  let paths = NSSearchPathForDirectoriesInDomains(
    .DocumentDirectory, .UserDomainMask, true
  )
  guard let path: String = paths[0] else {
    return nil
  }
  return NSURL(string: URLString, relativeToURL: NSURL(fileURLWithPath: path))
}

func rm(filename: String) throws {
  let url = documentURL(filename)!
  try NSFileManager.defaultManager().removeItemAtURL(url)
}

/// A test case to extend providing things most Skull tests have in common,
/// namely: setting up, populating, and tearing down a test database.
class SkullTestCase: XCTestCase {
  
  var db: Skull!
  var filename: String?
  
  func load(name: String) throws -> String? {
    let bundle = NSBundle(forClass: self.dynamicType)
    return try sqlFromBundle(bundle, withName: name)
  }
  
  override func setUp() {
    super.setUp()
    db = try! Skull()
    guard let name = filename else {
      return
    }
    let sql = try! load(name)
    try! db.exec(sql!) { error, found in
      guard error == nil else {
        XCTFail("should not error: \(error)")
        return -1
      }
      return 0
    }
  }
  
  override func tearDown() {
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
}
