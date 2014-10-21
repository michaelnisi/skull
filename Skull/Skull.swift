//
//  Skull.swift
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation
import sqlite3
import skull_helpers

let domain = "com.michaelnisi.skull"

struct SkullColumn<T>: Printable {
  let name: String
  let value: T

  var description: String {
    return "SkullColumn: \(name), \(value)"
  }
}

public class SkullRow: Printable {
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

func ok (code: CInt, ctx: COpaquePointer) -> NSError? {
  if code == SQLITE_OK {
    return nil
  } else {
    var msg: String
    let cs = sqlite3_errmsg(ctx)
    if let s = String.fromCString(cs) { // handles NULL
      msg = s
    } else {
      msg = "unknown error"
    }
    return NSError(
      domain: domain
    , code: Int(code)
    , userInfo: ["message": msg]
    )
  }
}

public class Skull: Printable {
  var ctx: COpaquePointer = nil
  var urls = [NSURL]()
  var cache = [String:COpaquePointer]()

  public var description: String {
    return "Skull: \(urls)"
  }

  public func open () -> NSError? {
    return open(url: nil)
  }
  public func open (url opturl: NSURL?) -> NSError? {
    if let url = opturl {
      if let filename = url.path {
        urls.append(url)
        return open(filename)
      } else {
        return NSError(
          domain: domain
        , code: 1
        , userInfo: ["message": "invalid URL"]
        )
      }
    } else {
      return open(":memory:")
    }
  }
  func open (filename: String) -> NSError? {
    let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
    return ok(sqlite3_open_v2(filename, &ctx, flags, nil), ctx)
  }

  public func flush () -> NSError? {
    for (sql, pStmt) in cache {
      if cache.removeValueForKey(sql) == nil { // highly unlikely
        return NSError(
          domain: domain
        , code: 0
        , userInfo: ["message": "key not present"]
        )
      }
      if let er = ok(sqlite3_finalize(pStmt), ctx) {
        return er
      }
    }
    return nil
  }

  public func close () -> NSError? {
    if let er = flush() {
      return er
    }
    return ok(sqlite3_close(ctx), ctx)
  }

  public func exec
  (sql: String, cb ocb: ((NSError?, [String:String]) -> Int)? = nil)
  -> NSError? {
    typealias CArr = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>
    typealias Callback = (CInt, CArr, CArr) -> CInt
    var f: Callback? = nil
    if let cb = ocb {
      f = { cols, texts, names in
        var er: NSError?
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
          er = NSError(
            domain: domain
          , code: 0 // just a warning
          , userInfo: ["message": "got NULL from CString"]
          )
        }
        return CInt(cb(er, dict))
      }
    }
    return ok(skull_exec(ctx, sql, f), ctx)
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
  func textColumn (pStmt: COpaquePointer, index: CInt, name: String)
  -> SkullColumn<AnyObject>? {
    let ptr: UnsafePointer<UInt8> = sqlite3_column_text(pStmt, index)
    var cs = UnsafePointer<CChar>(ptr)
    if let s = String.fromCString(cs) {
      return SkullColumn(name: name, value: s)
    }
    return nil
  }
  func intColumn (pStmt: COpaquePointer, index: CInt, name: String)
  -> SkullColumn<AnyObject>? {
    let value = Int(sqlite3_column_int(pStmt, index))
    return SkullColumn(name: name, value: value)
  }
  func doubleColumn (pStmt: COpaquePointer, index: CInt, name: String)
  -> SkullColumn<AnyObject>? {
    let value: Double = sqlite3_column_double(pStmt, index)
    return SkullColumn(name: name, value: value)
  }

  func run
  (pStmt: COpaquePointer, cb optcb: ((NSError?, SkullRow?) -> Int)? = nil)
  -> NSError? {
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
          cb(ok(code, ctx), nil)
        }
        break
      }
    }
    return ok(sqlite3_reset(pStmt), ctx)
  }

  public func query (sql: String, cb: (NSError?, SkullRow?) -> Int)
  -> NSError? {
    var pStmt: COpaquePointer = nil
    if let cachedPStmt = cache[sql] {
      pStmt = cachedPStmt
    } else {
      if let er = ok(skull_prepare(ctx, sql, &pStmt), ctx) {
        return er
      } else {
        cache[sql] = pStmt
      }
    }
    return run(pStmt, cb)
  }

  public func update (sql: String, _ params: Any?...) -> NSError? {
    var pStmt: COpaquePointer = nil
    if let cachedPStmt = cache[sql] {
      pStmt = cachedPStmt // has bindings
      if let er = ok(sqlite3_clear_bindings(pStmt), ctx) {
        return er
      }
    } else {
      if let er = ok(skull_prepare(ctx, sql, &pStmt), ctx) {
        return er
      } else {
        cache[sql] = pStmt
      }
    }
    func fin (er: NSError) -> NSError? {
      if let fer = ok(sqlite3_finalize(pStmt), ctx) {
        return fer
      }
      return er
    }
    var i: CInt = 0
    for (index, param) in enumerate(params) {
      i = CInt(index + 1)
      if param == nil {
        if let er = ok(sqlite3_bind_null(pStmt, i), ctx) {
          return fin(er)
        }
      } else if let value = param as? Int {
        let c = CInt(value)
        if let er = ok(sqlite3_bind_int(pStmt, i, c), ctx) {
          return fin(er)
        }
      } else if let value = param as? Float {
        let c = CDouble(value)
        if let er = ok(sqlite3_bind_double(pStmt, i, c), ctx) {
          return fin(er)
        }
      } else if let value = param as? Double {
        let c = CDouble(value)
        if let er = ok(sqlite3_bind_double(pStmt, i, c), ctx) {
          return fin(er)
        }
      } else if let value = param as? String {
        let c = value
        let len = CInt(countElements(value))
        if let er = ok(skull_bind_text(pStmt, i, c, len), ctx) {
          return fin(er)
        }
      } else {
        return fin(NSError(
          domain: domain
        , code: 1
        , userInfo: ["message": "unsupported type \(param)"]
        ))
      }
    }
    return run(pStmt, nil)
  }
}
