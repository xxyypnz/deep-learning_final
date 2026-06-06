-- ===== Commit 118 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);

-- Execution: Attempt to create a non-ON-SELECT rule named "_RETURN"
CREATE OR REPLACE RULE "_RETURN" AS ON INSERT TO test_t1 DO INSTEAD NOTHING;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
CREATE VIEW test_v2 AS SELECT * FROM test_t2;

-- Execution: Attempt to replace the view's ON SELECT rule with a non-ON-SELECT rule named "_RETURN"
CREATE OR REPLACE RULE "_RETURN" AS ON INSERT TO test_v2 DO INSTEAD NOTHING;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;
DROP VIEW IF EXISTS test_v2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
INSERT INTO test_t3 VALUES (1);

-- Execution: Create a view with a valid ON SELECT rule named "_RETURN"
CREATE VIEW test_v3 AS SELECT * FROM test_t3;

-- Verify the view works
SELECT * FROM test_v3;

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;
DROP VIEW IF EXISTS test_v3 CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS r118_compact CASCADE;
CREATE TABLE r118_compact (id int);
CREATE RULE "_RETURN" AS ON INSERT TO r118_compact DO ALSO SELECT 1;
DROP TABLE IF EXISTS r118_compact CASCADE;

