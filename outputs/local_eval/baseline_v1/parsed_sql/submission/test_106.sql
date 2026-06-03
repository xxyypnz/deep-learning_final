-- ===== Commit 106 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_empty_gs CASCADE;
CREATE TABLE test_empty_gs (a int, b int);
INSERT INTO test_empty_gs VALUES (1, 10), (2, 20), (3, 30);

-- Execution: Use GROUP BY () to create an empty grouping set
SELECT COUNT(*) FROM test_empty_gs GROUP BY ();

-- Teardown
DROP TABLE IF EXISTS test_empty_gs CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_mixed_gs CASCADE;
CREATE TABLE test_mixed_gs (x int, y int);
INSERT INTO test_mixed_gs VALUES (1, 100), (2, 200), (1, 300);

-- Execution: GROUPING SETS with empty set and a non-empty set
SELECT x, COUNT(*) FROM test_mixed_gs GROUP BY GROUPING SETS ((), (x));

-- Teardown
DROP TABLE IF EXISTS test_mixed_gs CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_having_gs CASCADE;
CREATE TABLE test_having_gs (id int, val int);
INSERT INTO test_having_gs VALUES (1, 5), (2, 10), (3, 15);

-- Execution: Empty grouping set with HAVING
SELECT COUNT(*), SUM(val) FROM test_having_gs GROUP BY () HAVING COUNT(*) > 0;

-- Teardown
DROP TABLE IF EXISTS test_having_gs CASCADE;

