-- ===== Commit 122 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup: Create a table with an array type (pass-by-ref) to trigger expanded datum handling
DROP TABLE IF EXISTS test_agg1 CASCADE;
CREATE TABLE test_agg1 (id INT, arr INT[]);
INSERT INTO test_agg1 VALUES (1, ARRAY[1,2,3]), (2, ARRAY[4,5,6]);

-- Execution: Use array_agg which has no finalfn, returns pass-by-ref result
SELECT id, array_agg(arr) FROM test_agg1 GROUP BY id;

-- Teardown
DROP TABLE IF EXISTS test_agg1 CASCADE;

-- --- Test Case 2 ---
-- Setup: Create a table with text type (pass-by-ref) and use string_agg which has no finalfn
DROP TABLE IF EXISTS test_agg2 CASCADE;
CREATE TABLE test_agg2 (id INT, val TEXT);
INSERT INTO test_agg2 VALUES (1, 'a'), (1, 'b'), (2, 'c');

-- Execution: Use string_agg with partial aggregation (enable hashagg if needed)
SET enable_hashagg = on;
SELECT id, string_agg(val, ',') FROM test_agg2 GROUP BY id;
RESET enable_hashagg;

-- Teardown
DROP TABLE IF EXISTS test_agg2 CASCADE;

-- --- Test Case 3 ---
-- Setup: Create a table with nullable integer and use an aggregate that can produce NULL transition values
DROP TABLE IF EXISTS test_agg3 CASCADE;
CREATE TABLE test_agg3 (id INT, val INT);
INSERT INTO test_agg3 VALUES (1, NULL), (1, 10), (2, NULL);

-- Execution: Use avg() which has a finalfn, but the transition value may be null for groups with all nulls
SELECT id, avg(val) FROM test_agg3 GROUP BY id;

-- Teardown
DROP TABLE IF EXISTS test_agg3 CASCADE;

