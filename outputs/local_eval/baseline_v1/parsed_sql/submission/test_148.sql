-- ===== Commit 148 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
SET track_commit_timestamp = on;
DROP TABLE IF EXISTS test_subxact CASCADE;
CREATE TABLE test_subxact (id INT);
BEGIN;
INSERT INTO test_subxact VALUES (1);
SAVEPOINT sp1;
INSERT INTO test_subxact VALUES (2);
SAVEPOINT sp2;
INSERT INTO test_subxact VALUES (3);
RELEASE SAVEPOINT sp2;
RELEASE SAVEPOINT sp1;
COMMIT;
-- Execution (triggers commit timestamp writing for subtransactions)
SELECT count(*) FROM test_subxact;
-- Teardown
DROP TABLE IF EXISTS test_subxact CASCADE;
SET track_commit_timestamp = off;

-- --- Test Case 2 ---
-- Setup
SET track_commit_timestamp = on;
DROP TABLE IF EXISTS test_no_subxact CASCADE;
CREATE TABLE test_no_subxact (id INT);
BEGIN;
INSERT INTO test_no_subxact VALUES (1);
COMMIT;
-- Execution (triggers commit timestamp writing for top-level transaction only)
SELECT count(*) FROM test_no_subxact;
-- Teardown
DROP TABLE IF EXISTS test_no_subxact CASCADE;
SET track_commit_timestamp = off;

-- --- Test Case 3 ---
-- Setup
SET track_commit_timestamp = on;
DROP TABLE IF EXISTS test_many_subxact CASCADE;
CREATE TABLE test_many_subxact (id INT);
BEGIN;
INSERT INTO test_many_subxact VALUES (1);
SAVEPOINT sp1;
INSERT INTO test_many_subxact VALUES (2);
SAVEPOINT sp2;
INSERT INTO test_many_subxact VALUES (3);
SAVEPOINT sp3;
INSERT INTO test_many_subxact VALUES (4);
SAVEPOINT sp4;
INSERT INTO test_many_subxact VALUES (5);
RELEASE SAVEPOINT sp4;
RELEASE SAVEPOINT sp3;
RELEASE SAVEPOINT sp2;
RELEASE SAVEPOINT sp1;
COMMIT;
-- Execution (triggers commit timestamp writing for multiple subtransactions)
SELECT count(*) FROM test_many_subxact;
-- Teardown
DROP TABLE IF EXISTS test_many_subxact CASCADE;
SET track_commit_timestamp = off;

