CREATE TABLE t1(
  t  TEXT,     -- text affinity by rule 2
  nu NUMERIC,  -- numeric affinity by rule 5
  i  INTEGER,  -- integer affinity by rule 1
  r  REAL,     -- real affinity by rule 4
  no BLOB      -- no affinity by rule 3
);

-- Values stored as TEXT, INTEGER, INTEGER, REAL, TEXT.
INSERT INTO t1 VALUES('500.0', '500.0', '500.0', '500.0', '500.0');
