-- ===== Commit 123 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_heap_update_vm CASCADE;
CREATE TABLE test_heap_update_vm (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_heap_update_vm SELECT generate_series(1, 100), 'initial';
-- Create a situation where otherBuffer's all-visible bit might be set
VACUUM test_heap_update_vm;

-- Execution: Perform an UPDATE that triggers heap_update with a non-target buffer (otherBuffer) that may have all-visible set
BEGIN;
UPDATE test_heap_update_vm SET val = 'updated' WHERE id = 1;
-- This should reach the modified code path in hio.c where GetVisibilityMapPins is called after conditional lock succeeds
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_update_vm CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_heap_update_lock CASCADE;
CREATE TABLE test_heap_update_lock (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_heap_update_lock SELECT generate_series(1, 100), 'initial';

-- Execution: Simulate contention on otherBuffer to force conditional lock failure
BEGIN;
-- First session holds lock on otherBuffer (simulate by using a different tuple)
UPDATE test_heap_update_lock SET val = 'locked' WHERE id = 2;
-- In same session, update another tuple to trigger heap_update with otherBuffer contention
UPDATE test_heap_update_lock SET val = 'updated' WHERE id = 1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_update_lock CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_heap_update_extend CASCADE;
CREATE TABLE test_heap_update_extend (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_heap_update_extend SELECT generate_series(1, 100), 'initial';
-- Ensure some pages are all-visible
VACUUM test_heap_update_extend;

-- Execution: Insert a new tuple that causes page extension, then update another tuple to trigger the code path
BEGIN;
INSERT INTO test_heap_update_extend VALUES (101, 'new');
UPDATE test_heap_update_extend SET val = 'updated' WHERE id = 1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_update_extend CASCADE;

