//
//  skull_helpers.h
//  Skull
//
//  Created by Michael Nisi on 12.10.14.
//  Copyright (c) 2014-2015 Michael Nisi. All rights reserved.
//

#ifndef __Skull__helpers__
#define __Skull__helpers__

#include <stdio.h>
#include <sqlite3.h>

int skull_exec
(sqlite3 *db, const char *sql, int(^cb)(int, char**, char**));

int skull_bind_text
(sqlite3_stmt *pStmt, int index, const char *zName, int length);

#endif /* defined(__Skull__helpers__) */