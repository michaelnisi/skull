[![Build Status](https://secure.travis-ci.org/michaelnisi/skull.svg)](http://travis-ci.org/michaelnisi/skull)

# Skull - Swift SQLite

> Everything should be made as simple as possible, but no simpler.<br>—*Albert Einstein*

The Skull Swift package offers a bare bones (400 LOC) interface for [SQLite](https://www.sqlite.org/). Emphasising simplicity, its synchronous API implements a minimal set of functions for interacting with SQLite.

## Example

```swift
import Foundation
import Skull

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

// Synchronously, just so we don‘t exit before the callbacks are run.
skull.sync {
  let sql = "select name from planets where au=1;"
  try! db.query(sql) { er, row in
    assert(er == nil)
    let name = row?["name"] as! String
    assert(name == "Earth")
    print(name)
    return 0
  }
}
```

On macOS, building and running this example is easy.

```
cd example
swift build
swift run
```

Skull is deliberately thin, its tiny API leaves access serialization to users. Leveraging a dedicated serial queue, as shown in the example above, intuitively ensures serialized access.

## Types

```swift
enum SkullError: Error
```

`SkullError` enumerates explicit errors.

- `alreadyOpen(String)`
- `failedToFinalize(Array<Error>)`
- `invalidURL`
- `notOpen`
- `sqliteError(Int, String)`
- `sqliteMessage(String)`
- `unsupportedType`

```swift
typealias SkullRow = Dictionary<String, Any>
```

`SkullRow` models a `row` within a SQLite table. Being a `Dictionary`, it offers subscript access to column values, which can be of three essential types:

- `String`
- `Int`
- `Double`

For example:

```swift
row["a"] as String == "500.0"
row["b"] as Int == 500
row["c"] as Double == 500.0
```

```swift
class Skull: SQLDatabase
```

`Skull`, the main object of this module, represents a SQLite database connection. It adopts the `SQLDatabase` protocol, which defines its interface:

```swift
protocol SQLDatabase {
  var url: URL? { get }

  func flush() throws
  func exec(_ sql: String, cb: @escaping (SkullError?, [String : String]) -> Int) throws
  func query(_ sql: String, cb: (SkullError?, SkullRow?) -> Int) throws
  func update(_ sql: String, _ params: Any?...) throws
}
```

## Exports

### Opening a Database Connection

To open a database connection you initialize a new `Skull` object.

```swift
init(_ url: URL? = nil) throws
```

- `url` The location of the database file to open.

Opens the database located at file `url`. If the file does not exist, it is created. Skipping `url` or passing `nil` opens an in-memory database.

### Accessing the Database

A `Skull` object, representing a database connection, offers following methods for accessing the database.

```swift
func exec(sql: String, cb: ((SkullError?, [String:String]) -> Int)?)) throws
```

- `sql` Zero or more UTF-8 encoded, semicolon-separated SQL statements.
- `cb` A callback to handle results or abort by returning non-zero.

Executes SQL statements and applies the callback for each result, limited to strings in this case. The callback is optional, if provided, it can abort execution by returning non-zero. The callback doesn't just handle results, it can also monitor execution and, if need be, abort the operation; it is applied zero or more times.

```swift
func query(sql: String, cb: (SkullError?, SkullRow?) -> Int) throws
```

- `sql` The SQL statement to query the database with.
- `cb` The callback to handle resuting errors and rows.

Queries the database with the specified *selective* SQL statement and applies the callback for each resulting row or occuring error.

```swift
func update(sql: String, params: Any?...) throws
```

- `sql` The SQL statement to apply.
- `params` The parameters to bind to the statement.

Updates the database by binding the specified parameters to an SQLite statement, for example:

```swift
let sql = "insert into planets values (?, ?, ?);"
try! db.update(sql, 0, 0.4, "Mercury")
```

This method may throw `SkullError.sqliteError(Int, String)` or `SkullError.unsupportedType`.

### Managing the Database

```swift
func flush() throws
```

Removes and finalizes all cached prepared statements.

```swift
var url: URL? { get }
```

The location of the database file.

### Closing the Database

Close the database by simply dismissing the `Skull` object.

## Build and Install

Before building this software, we need to generate [module maps](http://clang.llvm.org/docs/Modules.html#module-maps) for the SQLite system library:

```
make module
```

### Xcode

The [Xcode](https://developer.apple.com/xcode/) project in this repo provides targets for all [Apple platforms](https://developer.apple.com/discover/).

You can conveniently run the tests with [Make](https://www.gnu.org/software/make/):

```
$ make [check | check_macOS | check_iOS | check_watchOS | check_tvOS]
```

And build the framework:

```
$ make [macOS | iOS | watchOS | tvOS]
```

Of course, you can also test and build using `xcodebuild` directly or from within Xcode.

I recommend [Xcode Workspaces](https://developer.apple.com/library/content/featuredarticles/XcodeConcepts/Concept-Workspace.html) for composing your programs.

### Swift Package Manager

Experimentally, you can use the [Package Manager](https://swift.org/package-manager/).

```
swift build
````

I like the agility of the command-line for testing.

```
swift test
```

## License

[MIT](https://raw.github.com/michaelnisi/skull/master/LICENSE)
