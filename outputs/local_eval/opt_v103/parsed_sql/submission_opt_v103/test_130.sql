-- ===== Commit 130 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_check_valid CASCADE;
CREATE TABLE test_check_valid (id INT CHECK (id > 0));

-- Execution: Force debug output of the constraint node by examining the plan or using a debug function
-- This triggers _outConstraint() for the check constraint with initially_valid = true, skip_validation = false
SET client_min_messages TO DEBUG1;
EXPLAIN (COSTS OFF) SELECT * FROM test_check_valid WHERE id = 1;
RESET client_min_messages;

-- Teardown
DROP TABLE IF EXISTS test_check_valid CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_check_notvalid CASCADE;
CREATE TABLE test_check_notvalid (id INT);
ALTER TABLE test_check_notvalid ADD CONSTRAINT ck_notvalid CHECK (id > 0) NOT VALID;

-- Execution: Force debug output of the constraint node
SET client_min_messages TO DEBUG1;
EXPLAIN (COSTS OFF) SELECT * FROM test_check_notvalid WHERE id = 1;
RESET client_min_messages;

-- Teardown
DROP TABLE IF EXISTS test_check_notvalid CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_check_invalid CASCADE;
CREATE TABLE test_check_invalid (id INT);
INSERT INTO test_check_invalid VALUES (-1);
ALTER TABLE test_check_invalid ADD CONSTRAINT ck_invalid CHECK (id > 0) NOT VALID;
-- Attempt to validate (will fail due to existing data, but constraint remains invalid)
BEGIN;
ALTER TABLE test_check_invalid VALIDATE CONSTRAINT ck_invalid;
COMMIT;

-- Execution: Force debug output of the constraint node
SET client_min_messages TO DEBUG1;
EXPLAIN (COSTS OFF) SELECT * FROM test_check_invalid WHERE id = 1;
RESET client_min_messages;

-- Teardown
DROP TABLE IF EXISTS test_check_invalid CASCADE;

-- --- Test Case 4 ---
SET client_min_messages = log;
SET debug_print_parse = on;
SET debug_pretty_print = off;
DROP TABLE IF EXISTS outcon130 CASCADE;
CREATE TABLE outcon130 (a int, CONSTRAINT outcon130_chk CHECK (a > 0));
ALTER TABLE outcon130 ADD CONSTRAINT outcon130_notvalid CHECK (a < 100) NOT VALID;
ALTER TABLE outcon130 VALIDATE CONSTRAINT outcon130_notvalid;
RESET debug_print_parse;
RESET debug_pretty_print;
RESET client_min_messages;
DROP TABLE IF EXISTS outcon130 CASCADE;

