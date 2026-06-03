-- ===== Commit 101 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);

-- Execution
WITH test_t1 AS (SELECT 2 AS id)
INSERT INTO test_t1 (id) SELECT id FROM test_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution
WITH test_t2 AS (SELECT 2 AS id)
UPDATE test_t2 SET id = (SELECT id FROM test_t2) WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
INSERT INTO test_t3 VALUES (1);

-- Execution
WITH test_t3 AS (SELECT 2 AS id)
DELETE FROM test_t3 WHERE id = (SELECT id FROM test_t3);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

