//
//  Skull.swift
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014-2016 Michael Nisi. All rights reserved.
//

import Foundation
import CSqlite3

// MARK: API

/// `SkullError` enumerates explicit errors.
public enum SkullError: Error {
  case alreadyOpen(String)
  case failedToFinalize(Array<Error>)
  case invalidURL
  case notOpen
  case sqliteError(Int, String)
  case unsupportedType
  case sqliteMessage(String)
}

extension SkullError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .alreadyOpen(let filename):
      return "Skull: \(filename) already open"
    case .sqliteError(let code, let msg):
      return "Skull: \(code): \(msg)"
    case .sqliteMessage(let msg):
      return "Skull: \(msg)"
    case .invalidURL:
      return "Skull: invalid URL"
    case .notOpen:
      return "Skull: not open"
    case .unsupportedType:
      return "Skull: unsupported type"
    case .failedToFinalize(let errors):
      return "Skull: failed to finalize: \(errors)"
    }
  }
}

/// A row within a SQLite table.
public typealias SkullRow = Dictionary<String, Any>

/// Defines a minimal SQL database API.
public protocol SQLDatabase {
  var url: URL? { get }

  func flush() throws

  func exec(
    _ sql: String,
    cb: @escaping (SkullError?, [String : String]) -> Int
  ) throws

  func query(_ sql: String, cb: (SkullError?, SkullRow?) -> Int) throws
  func update(_ sql: String, _ params: Any?...) throws
}

// MARK: - Internals

/// A column within a row.
struct SkullColumn<T>: CustomStringConvertible {
  let name: String
  let value: T

  var description: String {
    return "SkullColumn: \(name), \(value)"
  }
}

/// Evaluates SQLite result code and eventually throws
/// `SkullError.sqliteError(Int, String)` if `code` is anything but `SQLITE_OK`.
///
/// - parameter code: The SQLite result code.
/// - parameter ctx: The SQlite database connection handle.
///
/// - throws: Throws `SkullError.sqliteError(Int, String)` if code is non-zero.
private func ok(_ code: CInt, _ ctx: OpaquePointer) throws {
  if code != SQLITE_OK {
    func msg () -> String {
      let cs = sqlite3_errmsg(ctx)
      guard let msg = String(validatingUTF8: cs!) else {
        return "unkown error"
      }
      return msg
    }
    throw SkullError.sqliteError(Int(code), msg())
  }
}

/// A database connection.
final public class Skull: SQLDatabase {

  // SQLite db handle.
  private var ctx: OpaquePointer? = nil

  fileprivate var filename: String? {
    guard ctx != nil else {
      return nil
    }
    let ptr: UnsafePointer<CChar> = sqlite3_db_filename(ctx, "main")
    return String(cString: ptr)
  }

  /// The URL of the database file or `nil` if this is an in-memory database.
  public var url: URL? {
    if let f = filename {
      guard f != "" else {
        return nil
      }
      return URL(string: f)
    }
    return nil
  }

  private func checkIfOpen() throws {
    if let f = filename {
      throw SkullError.alreadyOpen(f)
    }
  }

  private func open(_ filename: String) throws {
    let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
    try ok(sqlite3_open_v2(filename, &ctx, flags, nil), ctx!)
  }

  /// Open a SQLite database file at `url` or, if no URL is specified, open a
  /// private temporary in-memory database.
  ///
  /// - parameter url: The URL of a SQLite database file.
  ///
  /// - throws: Possibly throws `SkullError`.
  private func open(_ url: URL? = nil) throws {
    guard let url = url else {
      return try open(":memory:")
    }
    guard url.scheme == "file" else {
      throw SkullError.invalidURL
    }
    try checkIfOpen()
    try open(url.path)
  }

  // Cache for prepared statements.
  var cache = [String : OpaquePointer]()

  /// Creates and returns a Skull object.
  ///
  /// - parameter url: The URL of a SQLite database file.
  ///
  /// - throws: Possibly throws `SkullError`.
  public init(_ url: URL? = nil) throws {
    try open(url)
  }

  /// Execute a string of `sql` incrementally applying the optional callback.
  ///
  /// If `cb` isn`t provided, the callback is a NOP: ostensible observations
  /// suggest that using Optionals instead would not be faster.
  ///
  /// - parameter sql: Zero or more UTF-8 encoded, semicolon-separated SQL
  /// statements.
  /// - parameter cb: A callback to handle results or abort by returning non-zero.
  ///
  /// - throws: Possibly throws `SkullError.sqliteError(Int, String)` or
  /// `SkullError.sqliteError(String)`.
  public func exec(
    _ sql: String,
    cb: @escaping ((SkullError?, [String : String]) -> Int) = {_, _ in return 0 }
  ) throws {

    // Using a local context to pass our callback to C.
    typealias Callback = (SkullError?, [String : String]) -> Int
    class BoxedCallback {
      let cb: Callback
      init(_ cb: @escaping Callback) {
        self.cb = cb
      }
    }

    let f: (@convention(c) (
      UnsafeMutableRawPointer?,
      Int32,
      UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?,
      UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32
    ) = { param, cols, texts, names in
      let count = Int(cols)
      var dict = [String : String]()

      if let names = names, let texts = texts {
        for i in 0..<count {
          guard let name = names[i], let text = texts[i] else { continue }
          let k = String(cString: name)
          let v = String(cString: text)
          dict[k] = v
        }
      }

      let ctx = Unmanaged<BoxedCallback>.fromOpaque(param!).takeUnretainedValue()
      let cb = ctx.cb

      return CInt(cb(nil, dict))
    }

    let boxed = BoxedCallback(cb)
    let boxedRef = Unmanaged.passUnretained(boxed)
    let param = UnsafeMutableRawPointer(boxedRef.toOpaque())

    var error: UnsafeMutablePointer<Int8>? = nil

    try ok(sqlite3_exec(ctx, sql, f, param, &error), ctx!)

    guard let er = error else {
      return
    }
    // I've never seen this code being entered, yet.
    let msg = String(cString: er)
    sqlite3_free(error)
    print("🔥")
    throw SkullError.sqliteMessage(msg)
  }

  private func column(_ pStmt: OpaquePointer, _ i: Int) -> SkullColumn<AnyObject>? {
    let index = CInt(i)
    let type = sqlite3_column_type(pStmt, index)
    let cname = sqlite3_column_name(pStmt, index)
    if let name = String(validatingUTF8: cname!) {
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

  private func textColumn(
    _ pStmt: OpaquePointer,
    index: CInt,
    name: String
  ) -> SkullColumn<AnyObject>? {
    let ptr: UnsafePointer<UInt8> = sqlite3_column_text(pStmt, index)
    let str = String(cString: ptr)
    return SkullColumn(name: name, value: str as AnyObject)
  }

  private func intColumn(
    _ pStmt: OpaquePointer,
    index: CInt,
    name: String
  ) -> SkullColumn<AnyObject>? {
    let value = Int(sqlite3_column_int(pStmt, index))
    return SkullColumn(name: name, value: value as AnyObject)
  }

  private func doubleColumn(
    _ pStmt: OpaquePointer,
    index: CInt,
    name: String
  ) -> SkullColumn<AnyObject>? {
    let value: Double = sqlite3_column_double(pStmt, index)
    return SkullColumn(name: name, value: value as AnyObject)
  }

  /// Steps through `preparedStatement` applying the callback with resulting
  /// errors and rows with each step.
  ///
  /// - parameter pStmt: The prepared statement to execute.
  /// - parameter cb: The callback to handle resulting errors and rows.
  ///
  /// - throws: May throw `SkullError.sqliteError(Int, String)`.
  private func run(
    _ pStmt: OpaquePointer,
    cb: ((SkullError?, SkullRow?) -> Int) = {_, _ in return 0 }
  ) throws {
    var code: CInt
    while true {
      code = sqlite3_step(pStmt) // cling together, swing together
      if code == SQLITE_ROW {
        let count = Int(sqlite3_column_count(pStmt))
        var row = SkullRow()
        for i in 0..<count {
          if let col = column(pStmt, i) {
            row[col.name] = col.value
          }
        }
        let _ = cb(nil, row)
      } else if code == SQLITE_DONE {
        break
      } else {
        do {
          try ok(code, ctx!)
        } catch let er as SkullError {
          let _ = cb(er, nil)
        }
        let _ = cb(nil, nil)
        break
      }
    }
    try ok(sqlite3_reset(pStmt), ctx!)
  }

  private func prepare(_ sql: String) throws -> OpaquePointer {
    var pStmt: OpaquePointer? = nil
    if let cached = cache[sql] {
      try ok(sqlite3_clear_bindings(pStmt), ctx!)
      return cached
    } else {
      try ok(sqlite3_prepare_v2(ctx, sql, -1, &pStmt, nil), ctx!)
      cache[sql] = pStmt
      return pStmt!
    }
  }

  /// Queries the database with the specified *selective* `sql` statement.
  ///
  /// - parameter sql: The SQL statement to query the database with.
  /// - parameter cb: The callback to handle resulting errors and rows.
  ///
  /// - throws: May throw `SkullError.sqliteError(Int, String)`.
  public func query(
    _ sql: String,
    cb: (SkullError?, SkullRow?) -> Int
  ) throws {
    let pStmt = try prepare(sql)
    try run(pStmt, cb: cb)
  }

  private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

  /// Updates the database with the provided `sql` statement and `params'.
  ///
  /// - parameter sql: The SQL statement to apply with the `params`.
  /// - parameter params: Zero or more parameters to bind.
  ///
  /// - throws: May throw `SkullError.sqliteError(Int, String)` or
  /// `SkullError.unsupportedType`.
  public func update(
    _ sql: String,
    _ params: Any?...
  ) throws {
    let pStmt = try prepare(sql)

    var i: CInt = 0
    for (index, param) in params.enumerated() {
      i = CInt(index + 1)
      if param == nil {
        try ok(sqlite3_bind_null(pStmt, i), ctx!)
      } else if let value = param as? Int {
        let c = CInt(value)
        try ok(sqlite3_bind_int(pStmt, i, c), ctx!)
      } else if let value = param as? Float {
        let c = CDouble(value)
        try ok(sqlite3_bind_double(pStmt, i, c), ctx!)
      } else if let value = param as? Double {
        let c = CDouble(value)
        try ok(sqlite3_bind_double(pStmt, i, c), ctx!)
      } else if let value = param as? String {
        let len = CInt(value.characters.count)
        try ok(sqlite3_bind_text(pStmt, i, value, len, SQLITE_TRANSIENT), ctx!)
      } else {
        throw SkullError.unsupportedType
      }
    }
    try run(pStmt)
  }

  /// Finalize all prepared statements—SQL statements compiled to binary—and
  /// remove them from the cache.
  ///
  /// - throws: Possibly throws `SkullError`.
  public func flush() throws {
    var errors = [Error]()
    for pStmt in cache.values {
      do {
        try ok(sqlite3_finalize(pStmt), ctx!)
      } catch let er {
        errors.append(er)
      }
    }
    guard errors.isEmpty else {
      throw SkullError.failedToFinalize(errors)
    }
    cache.removeAll()
  }

  /// Close the database connection finalizing and flushing prepared statements.
  ///
  /// - throws: Might throw `SkullError`.
  public func close() throws {
    try flush()
    guard ctx != nil else { throw SkullError.notOpen }
    try ok(sqlite3_close(ctx), ctx!)
    ctx = nil
  }
}

extension Skull: CustomStringConvertible {
  public var description: String {
    let str = filename ?? "closed"
    return "Skull: \(str)"
  }
}
