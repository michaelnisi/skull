# Skull - Swift SQLite

**Skull** is a frugal interface for using [SQLite](https://www.sqlite.org/) from Swift. To keep it simple, **Skull** is not thread-safe and leaves access serialization to the user. **Skull** objects cache prepared statements.

[![Build Status](https://secure.travis-ci.org/michaelnisi/skull.svg)](http://travis-ci.org/michaelnisi/skull)

## Types

### SkullError

`SkullError` enumerates explicit error types of the Skull module.

- `AlreadyOpen(String)`
- `FailedToFinalize(Array<ErrorType>)`
- `InvalidURL`
- `NULLFromCString`
- `NoPath`
- `NotOpen`
- `SQLiteError(Int, String)`
- `UnsupportedType`

### SkullRow

`SkullRow` models a database `row` with subscript access to column values. Supported types are `String`, `Int`, and `Double`. For example:

```swift
row["a"] as String == "500.0"
row["b"] as Int == 500
row["c"] as Double == 500.0
```

### Skull

`Skull`, the main object of this module, represents a SQLite database connection.

## Exports

### Opening a database connection

To open a database connection you initialize a new `Skull` object.

```swift
init(_ url: NSURL? = nil) throws
```

- url The location of the database file to open

Opens the database located at file `url`. If the file does not exist, it is created. Skipping `url` or passing `nil` opens an in-memory database.

### Accessing the database

A `Skull` object, representing a database connection, offers following methods for accessing the database.

```swift
func exec(sql: String, cb: ((SkullError?, [String:String]) -> Int)?)) throws
```

- `sql` The SQLite statement to execute.
- `cb` An optional callback to handle results.

Executes SQLite statement and applies the callback for each result. The callback is optional. If a callback is provided, it can abort execution returning something other than `0`.

```swift
func query(sql: String, cb: (SkullError?, SkullRow?) -> Int) throws
```

- `sql` The SQLite statement to apply.
- `cb` The callback to handle results.

Queries the database with the SQLite statement and apply the callback for each resulting row.

```swift
func update(sql: String, params: Any?...) throws
```

- `sql` The SQLite statement to apply.
- `params` The parameters to bind to the statement.

Updates the database by binding the parameters to an SQLite statement, for example:

```swift
let sql = "INSERT INTO t1 VALUES (?,?,?,?,?)"
let error = db.update(sql, 500.0, 500.0, 500.0, 500.0, "500.0")
```

### Managing the database connection

```swift
func flush() throws
```

Removes and finalizes all cached prepared statements.

*The database connection is closed when the `Skull` object is deinitialized.*

## Install

*For now, I only support a Cocoa Touch framework target.*

Generate module map files for multiple platforms (iOS and iOS Simulator):

```bash
$ ./configure
```

Run the tests with:

```bash
$ make test
```

If test succeeds you can add `Skull.xcodeproj` to your workspace to link with `Skull.framework` in your targets.

## License

MIT
