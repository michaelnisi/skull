// common - common functions used by tests

import Foundation

func sqlFromBundle (bundle: NSBundle, withName name: String) throws -> String? {
  guard let path = bundle.pathForResource(name, ofType: "sql") else {
    throw SkullError.NoPath
  }
  return try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
}

func documents (string: String) -> NSURL? {
  let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
  guard let path: String = paths[0] else {
    return nil
  }
  return NSURL(string: string, relativeToURL: NSURL(fileURLWithPath: path))
}

func rm (filename: String) throws {
  let url = documents(filename)
  let fm = NSFileManager.defaultManager()
  try fm.removeItemAtURL(url!)
}
