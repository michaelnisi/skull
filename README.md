# Skull - Swift SQLite

**Skull** is a bare-bones-interface for using [SQLite](https://www.sqlite.org/) from Swift. To keep it simple, **Skull** is not thread-safe and leaves access serialization to the user. **Skull** objects cache prepared statements.

[![Build Status](https://secure.travis-ci.org/michaelnisi/skull.svg)](http://travis-ci.org/michaelnisi/skull)

## Types

```swift
SkullError
```
The possible errors:

- `AlreadyOpen(String)`
- `FailedToFinalize(Array<ErrorType>)`
- `InvalidURL`
- `NULLFromCString`
- `NoPath`
- `NotOpen`
- `SQLiteError(Int, String)`
- `UnsupportedType`

```swift
SkullRow
```
A database `row` with subscript access to column values. Supported types are `String`, `Int`, and `Double`. For example:

```swift
row["a"] as String == "500.0"
row["b"] as Int == 500
row["c"] as Double == 500.0
```

## Exports

### Opening a database connection

```swift
Skull() throws
```
Opens an in-memory database.

```swift
Skull(url: NSURL) throws
```
- url The location of the database file to open

Opens the database located at file `url`. If the file does not exist, it is created. Passing `nil` means `Skull()`.

### Accessing the database

```swift
Void db.exec(sql: String, cb: ((SkullError?, [String:String]) -> Int)?)) throws
```

- `sql` The SQL statement to execute.
- `cb` An optional callback to handle results.

Executes SQL statement and applies the callback for each result. The callback is optional. If a callback is provided, it can abort execution by not returning `0`.

```swift
Void db.query(sql: String, cb: (SkullError?, SkullRow?) -> Int) throws
```

- `sql` The SQL statement to apply.
- `cb` The callback to handle results.

Queries the database with the SQL statement and apply the callback for each resulting row.

```swift
Void db.update(sql: String, params: Any?...) throws
```

- `sql` The SQL statement to apply.
- `params` The parameters to bind to the statement.

Updates the database by binding the parameters to an SQL statement, for example:

```swift
let sql = "INSERT INTO t1 VALUES (?,?,?,?,?)"
let error = db!.update(sql, 500.0, 500.0, 500.0, 500.0, "500.0")
```

### Managing the database connection

```swift
Void db.flush() throws
```
Removes and finalizes all cached prepared statements.

```swift
Void db.close() throws
```
Flushes cache and closes database connection.

## Install

*For now I only support a Cocoa Touch framework target.*

Generate module map files for multiple platforms—iphoneos and iphonesimulator for now:

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
