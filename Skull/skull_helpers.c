//
//  skull_helpers.c
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014 Michael Nisi. All rights reserved.
//

#include "skull_helpers.h"

static int exec_cb
(void *a_param, int argc, char **argv, char **column) {
  int (^closure)(int, char**, char**) = a_param;
  return closure(argc, argv, column);
}

int skull_exec
(sqlite3 *db, const char *sql, int(^cb)(int, char**, char**)) {
  return sqlite3_exec(db, sql, cb ? exec_cb : NULL, cb, NULL);
}

int skull_prepare
(sqlite3 *db, const char *sql, sqlite3_stmt **handle) {
  return sqlite3_prepare_v2(db, sql, -1, handle, NULL);
}

int skull_bind_text
(sqlite3_stmt *pStmt, int index, const char *zName, int length) {
  return sqlite3_bind_text(pStmt, index, zName, length, SQLITE_TRANSIENT);
}
