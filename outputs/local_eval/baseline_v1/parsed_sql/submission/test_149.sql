-- ===== Commit 149 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_insert_row CASCADE;
CREATE TABLE test_insert_row (a int, b int);

-- Execution: INSERT with single-row VALUES containing a whole-row Var
INSERT INTO test_insert_row VALUES ((SELECT test_insert_row FROM test_insert_row));

-- Teardown
DROP TABLE IF EXISTS test_insert_row CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_rowcompare CASCADE;
CREATE TABLE test_rowcompare (a int, b int);
INSERT INTO test_rowcompare VALUES (1, 2), (3, 4);

-- Execution: Row comparison with whole-row Vars in both left and right arguments
SELECT * FROM test_rowcompare WHERE ROW(test_rowcompare.*) = ROW(test_rowcompare.*);

-- Teardown
DROP TABLE IF EXISTS test_rowcompare CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_cte_row CASCADE;
CREATE TABLE test_cte_row (x int);
INSERT INTO test_cte_row VALUES (1);

-- Execution: Use a VALUES clause with a whole-row Var in a CTE to exercise the code path
WITH cte AS (VALUES ((SELECT test_cte_row FROM test_cte_row)))
SELECT * FROM cte;

-- Teardown
DROP TABLE IF EXISTS test_cte_row CASCADE;

