-- ===== Commit 119 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_bf_const CASCADE;
CREATE TABLE test_bf_const (id INT);
INSERT INTO test_bf_const VALUES (1);

-- Execution: recursive query with SEARCH BREADTH FIRST and constant initial value
WITH RECURSIVE cte AS (
    SELECT 1 AS val, id FROM test_bf_const
    UNION ALL
    SELECT val + 1, id FROM cte WHERE val < 3
)
SEARCH BREADTH FIRST BY val SET order_col
SELECT * FROM cte ORDER BY order_col;

-- Teardown
DROP TABLE IF EXISTS test_bf_const CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_df_const CASCADE;
CREATE TABLE test_df_const (id INT);
INSERT INTO test_df_const VALUES (1);

-- Execution: recursive query with SEARCH DEPTH FIRST and constant initial value
WITH RECURSIVE cte AS (
    SELECT 1 AS val, id FROM test_df_const
    UNION ALL
    SELECT val + 1, id FROM cte WHERE val < 3
)
SEARCH DEPTH FIRST BY val SET order_col
SELECT * FROM cte ORDER BY order_col;

-- Teardown
DROP TABLE IF EXISTS test_df_const CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_cycle_const CASCADE;
CREATE TABLE test_cycle_const (id INT);
INSERT INTO test_cycle_const VALUES (1);

-- Execution: recursive query with CYCLE clause and constant initial value
WITH RECURSIVE cte AS (
    SELECT 1 AS val, id FROM test_cycle_const
    UNION ALL
    SELECT val + 1, id FROM cte WHERE val < 3
)
CYCLE val SET is_cycle USING path
SELECT * FROM cte ORDER BY val;

-- Teardown
DROP TABLE IF EXISTS test_cycle_const CASCADE;

