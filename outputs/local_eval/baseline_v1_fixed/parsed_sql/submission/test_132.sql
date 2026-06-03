-- ===== Commit 132 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t1 (id INT);
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t1 VALUES (1);
INSERT INTO test_t2 VALUES (2);

-- Execution: Create a view that joins without alias, then lock the base table "unnamed_join" (which doesn't exist) to trigger the skip
CREATE VIEW test_v1 AS SELECT * FROM test_t1 JOIN test_t2 ON test_t1.id = test_t2.id;
SELECT * FROM test_v1 FOR UPDATE OF test_t1;

-- Teardown
DROP VIEW IF EXISTS test_v1 CASCADE;
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t1 (id INT);
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t1 VALUES (1);
INSERT INTO test_t2 VALUES (2);

-- Execution: Create a view with JOIN USING (which generates a join_using_alias), then attempt to lock the join alias
CREATE VIEW test_v2 AS SELECT * FROM test_t1 JOIN test_t2 USING (id);
SELECT * FROM test_v2 FOR UPDATE OF test_t1;

-- Teardown
DROP VIEW IF EXISTS test_v2 CASCADE;
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t1 (id INT);
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t1 VALUES (1);
INSERT INTO test_t2 VALUES (2);

-- Execution: Create a view with an explicit alias for the join, then lock that alias
CREATE VIEW test_v3 AS SELECT * FROM test_t1 JOIN test_t2 AS myjoin ON test_t1.id = test_t2.id;
SELECT * FROM test_v3 FOR UPDATE OF myjoin;

-- Teardown
DROP VIEW IF EXISTS test_v3 CASCADE;
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

