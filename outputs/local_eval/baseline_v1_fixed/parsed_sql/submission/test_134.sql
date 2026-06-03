-- ===== Commit 134 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT, val TEXT);
INSERT INTO test_t1 VALUES (1, 'initial');

-- Execution: Use pg_xact_status to prime CLOG cache, then UPDATE to trigger visibility check
BEGIN;
UPDATE test_t1 SET val = 'updated' WHERE id = 1;
SELECT pg_xact_status(txid_current()) FROM test_t1 LIMIT 1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT, val TEXT);
INSERT INTO test_t2 VALUES (1, 'initial');

-- Execution: Use many subtransactions to overflow subxid cache, then UPDATE
BEGIN;
SAVEPOINT sp1;
UPDATE test_t2 SET val = 'sp1' WHERE id = 1;
SAVEPOINT sp2;
UPDATE test_t2 SET val = 'sp2' WHERE id = 1;
SAVEPOINT sp3;
UPDATE test_t2 SET val = 'sp3' WHERE id = 1;
SAVEPOINT sp4;
UPDATE test_t2 SET val = 'sp4' WHERE id = 1;
SAVEPOINT sp5;
UPDATE test_t2 SET val = 'sp5' WHERE id = 1;
SAVEPOINT sp6;
UPDATE test_t2 SET val = 'sp6' WHERE id = 1;
SAVEPOINT sp7;
UPDATE test_t2 SET val = 'sp7' WHERE id = 1;
SAVEPOINT sp8;
UPDATE test_t2 SET val = 'sp8' WHERE id = 1;
SAVEPOINT sp9;
UPDATE test_t2 SET val = 'sp9' WHERE id = 1;
SAVEPOINT sp10;
UPDATE test_t2 SET val = 'sp10' WHERE id = 1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT, val TEXT);
INSERT INTO test_t3 VALUES (1, 'initial');

-- Execution: Start a transaction, update, then check pg_xact_status before commit to see it returns 'in progress'
BEGIN;
UPDATE test_t3 SET val = 'updated' WHERE id = 1;
SELECT pg_xact_status(txid_current()) AS status;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

