import Foundation
import Skull

let skull: DispatchQueue = DispatchQueue(label: "ink.codes.skull")
let db = skull.sync {
  return try! Skull()
}

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
    print(name)

    return 0
  }
}
