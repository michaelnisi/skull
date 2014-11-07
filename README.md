
# Skull - Swift SQLite

Skull is a minimal [SQLite3](https://www.sqlite.org/) API for [Swift](https://developer.apple.com/swift/). Trying to stay out of the way, it is not threadsafe and leaves access serialization to the user. A `Skull` instance caches prepared statements.

[![Build Status](https://secure.travis-ci.org/michaelnisi/skull.svg)](http://travis-ci.org/michaelnisi/skull)

## types

```swift
SkullRow()
```
A database `row` with subscript access to column values. Supported types are `String`, `Int`, and `Double`. For example:

```swift
XCTAssertEqual(row["t"] as String, "500.0")
XCTAssertEqual(row["nu"] as Int, 500)
XCTAssertEqual(row["i"] as Int, 500)
XCTAssertEqual(row["r"] as Double, 500.0)
XCTAssertEqual(row["no"] as String, "500.0")
```

```swift
Skull()
```
Initializes a Skull instance. For example:

```swift
let db = Skull()
```

## exports

### Opening a database connection

```swift
db.open() -> NSError?
```
Opens a connection to an in-memory database.

```swift
db.openURL(url: NSURL?) -> NSError?
```
- url The location of the database file to open.

Opens a connection to a database in the file located at the provided `NSURL`. If the file does not exist, it is created. Passing `nil` means `db.open()`.

### Accessing the database

```swift
db.exec(sql: String, cb: ((NSError?, [String:String]) -> Int)?)) -> NSError?
```
- `sql` The SQL statement to execute.
- `cb` An optional callback to handle results.

Executes SQL statement and applies the callback for each result. The callback is optional. If a callback is provided, it can abort execution by returning something else than `0`.

```swift
db.query(sql: String, cb: (NSError?, SkullRow?) -> Int) -> NSError?
```
- `sql` The SQL statement to apply.
- `cb` The callback to handle results.

Queries the database with the SQL statement and apply the callback for each resulting row.

```swift
db.update(sql: String, params: Any?...) -> NSError?
```
- `sql` The SQL statement to apply.
- `params` The parameters to bind to the statement.

Updates the database by binding the parameters to an SQL statement, for example:
```swift
let sql = "INSERT INTO t1 VALUES (?,?,?,?,?)"
XCTAssertNil(db!.update(sql, 500.0, 500.0, 500.0, 500.0, "500.0"))
```

### Managing the database connection

```swift
db.flush() -> NSError?
```
Removes and finalizes all cached prepared statements.

```swift
db.close() -> NSError?
```
Flushes cache and closes database connection.

## Install

Add the `Skull.xcodeproj` to your workspace and add `Skull.framework` to a target of the project you want to use it in.

## License

MIT
