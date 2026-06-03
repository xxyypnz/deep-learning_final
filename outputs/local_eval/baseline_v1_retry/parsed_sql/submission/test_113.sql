-- ===== Commit 113 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 SELECT generate_series(1, 1000);
-- Create index to trigger get_actual_variable_range
CREATE INDEX test_t1_idx ON test_t1 (id);
-- Delete many tuples to create non-visible tuples near the end
DELETE FROM test_t1 WHERE id > 900;
-- Ensure visibility map is not set by performing a vacuum-less delete
-- Execution: Run a query that triggers get_actual_variable_range for min/max estimation
ANALYZE test_t1;
SELECT * FROM test_t1 WHERE id > 500;
-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT, data TEXT);
INSERT INTO test_t2 SELECT generate_series(1, 200), 'data';
CREATE INDEX test_t2_idx ON test_t2 (id);
-- Delete some tuples to create non-visible entries on same heap page
DELETE FROM test_t2 WHERE id BETWEEN 50 AND 100;
-- Execution: Query that triggers get_actual_variable_range
ANALYZE test_t2;
SELECT * FROM test_t2 WHERE id > 150;
-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
CREATE INDEX test_t3_idx ON test_t3 (id);
-- No data inserted, index is empty
-- Execution: Query that triggers get_actual_variable_range
ANALYZE test_t3;
SELECT * FROM test_t3 WHERE id > 10;
-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

