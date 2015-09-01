//
//  Skull.swift
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014-2015 Michael Nisi. All rights reserved.
//

import Foundation
import sqlite3
import skull_helpers

struct SkullColumn<T>: CustomStringConvertible {
  let name: String
  let value: T

  var description: String {
    return "SkullColumn: \(name), \(value)"
  }
}

public class SkullRow: CustomStringConvertible {
  private var cols = [String:SkullColumn<AnyObject>]()

  public subscript (key: String) -> AnyObject? {
    return cols[key]?.value
  }

  func append (col: SkullColumn<AnyObject>) -> Void {
    cols[col.name] = col
  }

  public var description: String {
    return "SkullRow: \(cols)"
  }
}

let ERROR_DESCRIPTIONS = [
  "Already open",
  "failed to finalize",
  "invalid url",
  "null from C string",
  "no path",
  "not open",
  "sqlite error",
  "unsupported type"
]

// TODO: Review these error types
public enum SkullError: ErrorType, CustomStringConvertible {
  case AlreadyOpen(String)
  case FailedToFinalize(Array<ErrorType>)
  case InvalidURL
  case NULLFromCString
  case NoPath
  case NotOpen
  case SQLiteError(Int, String)
  case UnsupportedType

  public var description: String {
    switch self {
    case .SQLiteError(let code, let msg):
      return "SQLiteError code: \(code) message: \(msg)"
    default:
      return ERROR_DESCRIPTIONS[self._code]
    }
  }
}

func ok (code: CInt, _ ctx: COpaquePointer) throws {
  if code != SQLITE_OK {
    func msg () -> String {
      let cs = sqlite3_errmsg(ctx)
      guard let msg = String.fromCString(cs) else {
        return "unkown error"
      }
      return msg
    }
    throw SkullError.SQLiteError(Int(code), msg())
  }
}

public class Skull: CustomStringConvertible {
  var ctx: COpaquePointer
  var cache: [String:COpaquePointer]

  public init () {
    ctx = nil
    cache = [String:COpaquePointer]()
  }

  private var filename: String? {
    guard ctx != nil else {
      return nil
    }
    let ptr: UnsafePointer<CChar> = sqlite3_db_filename(ctx, "main")
    return String.fromCString(ptr)
  }

  public var description: String {
    let str = filename ?? "closed"
    return "Skull: \(str)"
  }
  
  func checkIfOpen () throws {
    if let f = self.filename {
      throw SkullError.AlreadyOpen(f)
    }
  }

  public func open () throws {
    try checkIfOpen()
    try open(":memory:")
  }

  public func open (url: NSURL) throws {
    try checkIfOpen()
    guard let filename = url.path else {
      throw SkullError.InvalidURL
    }
    try open(filename)
  }

  func open (filename: String) throws {
    let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
    try ok(sqlite3_open_v2(filename, &ctx, flags, nil), ctx)
  }

  public func flush () throws {
    var errors = [ErrorType]()
    for (_, pStmt) in cache {
      do {
        try ok(sqlite3_finalize(pStmt), ctx)
      } catch let er {
        errors.append(er)
      }
    }
    if errors.count > 0 {
      throw SkullError.FailedToFinalize(errors)
    }
    cache.removeAll()
  }

  public func close () throws {
    try flush()
    if ctx == nil {
      throw SkullError.NotOpen
    }
    try ok(sqlite3_close(ctx), ctx)
    ctx = nil
  }

  public func exec (sql: String, cb ocb: ((SkullError?, [String:String]) -> Int)? = nil) throws {
    typealias CArr = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>
    typealias Callback = (CInt, CArr, CArr) -> CInt
    var f: Callback? = nil
    if let cb = ocb {
      f = { cols, texts, names in
        var er: SkullError?
        var errors = 0
        var dict = [String:String]()
        let count = Int(cols)
        for i in 0..<count {
          if let k = String.fromCString(names[i]) {
            if let v = String.fromCString(texts[i]) {
              dict[k] = v
            } else {
              errors++
            }
          } else {
            errors++
          }
        }
        if errors > 0 {
          er = SkullError.NULLFromCString
        }
        return CInt(cb(er, dict))
      }
    }
    try ok(skull_exec(ctx, sql, f), ctx)
  }

  func column (pStmt: COpaquePointer, _ i: Int) -> SkullColumn<AnyObject>? {
    let index = CInt(i)
    let type = sqlite3_column_type(pStmt, index)
    let cname = sqlite3_column_name(pStmt, index)
    if let name = String.fromCString(cname) {
      switch type {
      case SQLITE_TEXT:
        return textColumn(pStmt, index: index, name: name)
      case SQLITE_INTEGER:
        return intColumn(pStmt, index: index, name: name)
      case SQLITE_FLOAT:
        return doubleColumn(pStmt, index: index, name: name)
      case SQLITE_NULL:
        return nil
      case SQLITE_BLOB:
        return nil
      default:
        return nil
      }
    }
    return nil
  }

  func textColumn (pStmt: COpaquePointer, index: CInt, name: String) -> SkullColumn<AnyObject>? {
    let ptr: UnsafePointer<UInt8> = sqlite3_column_text(pStmt, index)
    let cs = UnsafePointer<CChar>(ptr)
    if let s = String.fromCString(cs) {
      return SkullColumn(name: name, value: s)
    }
    return nil
  }

  func intColumn (pStmt: COpaquePointer, index: CInt, name: String) -> SkullColumn<AnyObject>? {
    let value = Int(sqlite3_column_int(pStmt, index))
    return SkullColumn(name: name, value: value)
  }

  func doubleColumn (pStmt: COpaquePointer, index: CInt, name: String) -> SkullColumn<AnyObject>? {
    let value: Double = sqlite3_column_double(pStmt, index)
    return SkullColumn(name: name, value: value)
  }

  func run (pStmt: COpaquePointer, cb optcb: ((SkullError?, SkullRow?) -> Int)? = nil) throws {
    var code: CInt
    while true {
      code = sqlite3_step(pStmt) // cling together, swing together
      if code == SQLITE_ROW {
        let count = Int(sqlite3_column_count(pStmt))
        let row = SkullRow()
        for i in 0..<count {
          if let col = column(pStmt, i) {
            row.append(col)
          }
        }
        if let cb = optcb {
          cb(nil, row)
        }
      } else if code == SQLITE_DONE {
        break
      } else {
        if let cb = optcb  {
          do {
            try ok(code, ctx)
          } catch let er as SkullError {
            cb(er, nil)
          }
          cb(nil, nil)
        }
        break
      }
    }
    try ok(sqlite3_reset(pStmt), ctx)
  }

  public func query (sql: String, cb: (SkullError?, SkullRow?) -> Int) throws {
    var pStmt: COpaquePointer = nil
    if let cachedPStmt = cache[sql] {
      pStmt = cachedPStmt
    } else {
      try ok(sqlite3_prepare_v2(ctx, sql, -1, &pStmt, nil), ctx)
      cache[sql] = pStmt
    }
    try run(pStmt, cb: cb)
  }

  public func update (sql: String, _ params: Any?...) throws {
    var pStmt: COpaquePointer = nil
    if let cachedPStmt = cache[sql] {
      pStmt = cachedPStmt // has bindings
      try ok(sqlite3_clear_bindings(pStmt), ctx)
    } else {
      try ok(sqlite3_prepare_v2(ctx, sql, -1, &pStmt, nil), ctx)
      cache[sql] = pStmt
    }
    var i: CInt = 0
    for (index, param) in params.enumerate() {
      i = CInt(index + 1)
      if param == nil {
        try ok(sqlite3_bind_null(pStmt, i), ctx)
      } else if let value = param as? Int {
        let c = CInt(value)
        try ok(sqlite3_bind_int(pStmt, i, c), ctx)
      } else if let value = param as? Float {
        let c = CDouble(value)
        try ok(sqlite3_bind_double(pStmt, i, c), ctx)
      } else if let value = param as? Double {
        let c = CDouble(value)
        try ok(sqlite3_bind_double(pStmt, i, c), ctx)
      } else if let value = param as? String {
        let len = CInt(value.characters.count)
        try ok(skull_bind_text(pStmt, i, value, len), ctx)
      } else {
        throw SkullError.UnsupportedType
      }
    }
    try run(pStmt, cb: nil)
  }
}
