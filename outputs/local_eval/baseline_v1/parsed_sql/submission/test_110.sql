-- ===== Commit 110 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int);
CREATE TABLE t2 (b int);
INSERT INTO t1 VALUES (1), (2);
INSERT INTO t2 VALUES (1), (3);

-- Execution: semijoin with qual that may involve PHVs (e.g., via a subquery)
SELECT * FROM t1 WHERE EXISTS (SELECT 1 FROM t2 WHERE t1.a = t2.b AND t2.b > 0);

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int);
CREATE TABLE t2 (b int);
INSERT INTO t1 VALUES (1), (2);
INSERT INTO t2 VALUES (1), (2);

-- Execution: semijoin with no additional qual on the RHS
SELECT * FROM t1 WHERE EXISTS (SELECT 1 FROM t2 WHERE t1.a = t2.b);

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int);
CREATE TABLE t2 (b int);
INSERT INTO t1 VALUES (1);
INSERT INTO t2 VALUES (1);

-- Execution: Use a RIGHT JOIN to ensure it gets transformed by reduce_outer_joins, so the JOIN_RIGHT case is never hit
SELECT * FROM t1 RIGHT JOIN t2 ON t1.a = t2.b;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;

