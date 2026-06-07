-- ===== Commit 111 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_mxact CASCADE;
CREATE TABLE test_mxact (id INT PRIMARY KEY, val INT);
INSERT INTO test_mxact VALUES (1, 10);

-- Execution: Use two concurrent sessions to create a multixact with two updaters
-- Session 1
BEGIN;
UPDATE test_mxact SET val = 20 WHERE id = 1;
-- Session 2 (run in same connection after session 1's UPDATE, but before commit)
BEGIN;
UPDATE test_mxact SET val = 30 WHERE id = 1;
-- This should trigger the error: "new multixact has more than one updating member"
COMMIT;
-- Teardown
DROP TABLE IF EXISTS test_mxact CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_mxact2 CASCADE;
CREATE TABLE test_mxact2 (id INT PRIMARY KEY, val INT);
INSERT INTO test_mxact2 VALUES (1, 100);

-- Execution: Three concurrent sessions updating the same tuple
-- Session 1
BEGIN;
UPDATE test_mxact2 SET val = 200 WHERE id = 1;
-- Session 2
BEGIN;
UPDATE test_mxact2 SET val = 300 WHERE id = 1;
-- Session 3
BEGIN;
UPDATE test_mxact2 SET val = 400 WHERE id = 1;
-- This should trigger the error with detailed member info
COMMIT;
-- Teardown
DROP TABLE IF EXISTS test_mxact2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_mxact3 CASCADE;
CREATE TABLE test_mxact3 (id INT PRIMARY KEY, val INT);
INSERT INTO test_mxact3 VALUES (1, 50);

-- Execution: Two concurrent sessions, one UPDATE and one SELECT FOR UPDATE
-- Session 1
BEGIN;
UPDATE test_mxact3 SET val = 60 WHERE id = 1;
-- Session 2
BEGIN;
SELECT * FROM test_mxact3 WHERE id = 1 FOR UPDATE;
-- This should trigger the error as both are updating members
COMMIT;
-- Teardown
DROP TABLE IF EXISTS test_mxact3 CASCADE;

