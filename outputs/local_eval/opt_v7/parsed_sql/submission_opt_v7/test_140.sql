-- ===== Commit 140 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_lock CASCADE;
CREATE TABLE test_lock (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_lock VALUES (1, 'initial');

-- Execution: Use a concurrent transaction to lock and modify the tuple, then try to lock it again in a way that triggers heapam_tuple_lock() with keep_buf=true
BEGIN;
UPDATE test_lock SET val = 'updated' WHERE id = 1;
-- In another session, this would trigger the code path; simulate with a self-contained approach using a savepoint and rollback
SAVEPOINT sp;
SELECT * FROM test_lock WHERE id = 1 FOR UPDATE;
ROLLBACK TO sp;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_lock CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_fetch CASCADE;
CREATE TABLE test_fetch (id INT, val TEXT);
INSERT INTO test_fetch VALUES (1, 'visible');

-- Execution: Use a snapshot that sees the tuple as invisible (e.g., using a different transaction isolation level or explicit snapshot)
BEGIN ISOLATION LEVEL REPEATABLE READ;
UPDATE test_fetch SET val = 'invisible' WHERE id = 1;
-- Now in the same transaction, the old snapshot sees the old tuple as invisible
SELECT * FROM test_fetch WHERE id = 1;  -- This will use heap_fetch with keep_buf=false
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_fetch CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_lock2 CASCADE;
CREATE TABLE test_lock2 (id INT, val TEXT);
INSERT INTO test_lock2 VALUES (1, 'original');

-- Execution: Simulate a concurrent update that triggers heapam_tuple_lock with keep_buf=true
BEGIN;
UPDATE test_lock2 SET val = 'modified' WHERE id = 1;
-- Use a subtransaction to simulate the EvalPlanQualFetch path
SAVEPOINT sp1;
SELECT * FROM test_lock2 WHERE id = 1 FOR UPDATE;
ROLLBACK TO sp1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_lock2 CASCADE;

