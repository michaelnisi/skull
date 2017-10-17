//
//  Skull.swift
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014-2017 Michael Nisi. All rights reserved.
//

import Foundation
import CSqlite3

/// `SkullError` enumerates explicit errors.
public enum SkullError: Error {
  case alreadyOpen(String)
  case failedToFinalize(Array<Error>)
  case invalidURL
  case notOpen
  case sqliteError(Int, String)
  case sqliteMessage(String)
  case unsupportedType
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

  func exec(_ sql: String,
    cb: @escaping (SkullError?, [String : String]) -> Int) throws

  func query(_ sql: String, cb: (SkullError?, SkullRow?) -> Int) throws
  func update(_ sql: String, _ params: Any?...) throws
}

/// A column within a row.
struct SkullColumn<T>: CustomStringConvertible {
  let name: String
  let value: T

  var description: String {
    return "SkullColumn: \(name), \(value)"
  }
}

/// Evaluates SQLite result code and potentially throws
/// `SkullError.sqliteError(Int, String)` if `code` is anything but `SQLITE_OK`.
///
/// - Parameters:
///   - code: The SQLite result code.
///   - ctx: The SQLite database connection handle.
///
/// - Throws: May throw`SkullError.sqliteError(Int, String)` if code is
/// non-zero.
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
    guard let f = filename, f != "" else {
      return nil
    }
    return URL(string: f)
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
  /// - Parameter url: The URL of a SQLite database file.
  ///
  /// - Throws: Possibly throws `SkullError`.
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
  /// - Parameter url: The URL of a SQLite database file.
  ///
  /// - Throws: Possibly throws `SkullError`.
  public init(_ url: URL? = nil) throws {
    try open(url)
  }

  /// Execute a string of `sql` incrementally applying the optional callback.
  ///
  /// If `cb` isn`t provided, the callback is a NOP: ostensible observations
  /// suggest that using Optionals instead would not be faster.
  ///
  /// - Parameters:
  ///   - sql: Zero or more UTF-8 encoded, semicolon-separated SQL
  /// statements.
  ///   - cb: A callback to handle results or abort by returning non-zero.
  ///
  /// - Throws: Possibly throws `SkullError.sqliteError(Int, String)` or
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

    // Redundant. I have yet to see this code run.
    let msg = String(cString: er)
    sqlite3_free(error)
    throw SkullError.sqliteMessage(msg)
  }

  private func column(
    _ pStmt: OpaquePointer, _ i: Int) -> SkullColumn<AnyObject>? {
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
    let value = Int64(sqlite3_column_int64(pStmt, index))
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

  /// Steps through `pStmt` applying the callback with resulting
  /// errors and rows with each step.
  ///
  /// - Parameters:
  ///   - pStmt: The prepared statement to execute.
  ///   - cb: The callback to handle resulting errors and rows.
  ///
  /// - Throws: May throw `SkullError.sqliteError(Int, String)`.
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

  /// Resets all host parameters of a prepared `statement` to `NULL`.
  public func clearBindings(of statement: OpaquePointer) throws {
    try ok(sqlite3_clear_bindings(statement), ctx!)
  }

  /// Returns a prepared statement compiled from `sql`.
  private func prepare(_ sql: String) throws -> OpaquePointer {
    if let cached = cache[sql] {
      try clearBindings(of: cached)
      return cached
    }
    var pStmt: OpaquePointer? = nil
    try ok(sqlite3_prepare_v2(ctx, sql, -1, &pStmt, nil), ctx!)
    cache[sql] = pStmt
    return pStmt!
  }

  /// Queries the database with the specified *selective* `sql` statement.
  ///
  /// - Parameters:
  ///   - sql: The SQL statement to query the database with.
  ///   - cb: The callback to handle resulting errors and rows.
  ///
  /// - Throws: Might throw `SkullError.sqliteError(Int, String)`.
  public func query(
    _ sql: String,
    cb: (SkullError?, SkullRow?) -> Int
  ) throws {
    let pStmt = try prepare(sql)
    try run(pStmt, cb: cb)
  }

  private let SQLITE_TRANSIENT
    = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

  /// Binds `parameter` at `index` to prepared `statement`.
  private func bind(
    statement: OpaquePointer, at index: CInt, to parameter: Any?) throws {
    switch parameter {
    case nil:
      try ok(sqlite3_bind_null(statement, index), ctx!)
    case let v as Int:
      try ok(sqlite3_bind_int(statement, index, CInt(v)), ctx!)
    case let v as Float:
      try ok(sqlite3_bind_double(statement, index, CDouble(v)), ctx!)
    case let v as Double:
      try ok(sqlite3_bind_double(statement, index, CDouble(v)), ctx!)
    case let v as String:
      let len = CInt(v.characters.count)
      try ok(sqlite3_bind_text(statement, index, v, len, SQLITE_TRANSIENT), ctx!)
    default:
      throw SkullError.unsupportedType
    }
  }

  /// Updates the database with the provided `sql` statement and `params'.
  ///
  /// - Parameters:
  ///   - sql: The SQL statement to apply with the `params`.
  ///   - params: Zero or more parameters to bind.
  ///
  /// - Throws: Might throw `SkullError.sqliteError(Int, String)` or
  /// `SkullError.unsupportedType`.
  public func update(_ sql: String, _ params: Any?...) throws {
    let pStmt = try prepare(sql)

    for (index, param) in params.enumerated() {
      try bind(statement: pStmt, at: CInt(index + 1), to: param)
    }

    try run(pStmt)
  }

  /// Resets prepared `statement` back to its initial state.
  private func finalize(statement: OpaquePointer) throws {
    try ok(sqlite3_finalize(statement), ctx!)
  }

  /// Flushes the cache, releasing all prepared statements.
  ///
  /// - Throws: Throws `SkullError` if any cached prepared statement indicated
  /// an error in its most recent appliance.
  public func flush() throws {
    let pStmts = cache.values
    let errors: [Error] = pStmts.flatMap {
      do { try finalize(statement: $0)} catch { return error }
      return nil
    }
    guard errors.isEmpty else {
      throw SkullError.failedToFinalize(errors)
    }
    cache.removeAll()
  }

  /// Close the database connection finalizing and flushing prepared statements.
  ///
  /// - Throws: Might throw `SkullError`.
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
