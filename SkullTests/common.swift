//
//  common.swift
//  Skull
//
//  Created by Michael Nisi on 14.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

import Foundation

func sqlFrom (bundle: NSBundle, name: String) -> (NSError?, String?) {
  var er: NSError?
  if let path = bundle.pathForResource(name, ofType: "sql") {
    if let sql = String(
      contentsOfFile: path
    , encoding: NSUTF8StringEncoding
    , error: &er
    ) {
      return (er, sql)
    }
  } else {
    er = NSError(
      domain: SkullErrorDomain
    , code: 1
    , userInfo: ["message": "no path"]
    )
  }
  return (er, nil)
}

func documents (string: String) -> NSURL? {
  if let paths = NSSearchPathForDirectoriesInDomains(
    .DocumentDirectory
  , .UserDomainMask
  , true
  ) {
    if let path = paths[0] as? String {
      return NSURL(
        string: string
      , relativeToURL: NSURL(fileURLWithPath: path)
      )
    }
  }
  return nil
}

func rm (filename: String) -> NSError? {
  var er: NSError? = nil
  let url = documents(filename)
  let fm = NSFileManager.defaultManager()
  fm.removeItemAtURL(url!, error: &er)
  return er
}
