-- ===== Commit 135 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (a int);
INSERT INTO test_t1 VALUES (1);

-- Create a view with an expression that would get "?column?" as its column name
CREATE VIEW test_view1 AS SELECT a + 1 FROM test_t1;

-- Execution: deparse the view definition (triggers make_viewdef with colNamesVisible=true)
SELECT pg_get_viewdef('test_view1'::regclass);

-- Teardown
DROP VIEW IF EXISTS test_view1 CASCADE;
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (x int);
INSERT INTO test_t2 VALUES (1);

-- Execution: Use a subquery in FROM with an expression that would get "?column?"
SELECT * FROM (SELECT x + 1 FROM test_t2) AS subq;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id int);
INSERT INTO test_t3 VALUES (1);

-- Execution: Use EXISTS with a subquery that has an expression producing "?column?"
SELECT * FROM test_t3 WHERE EXISTS (SELECT id + 1 FROM test_t3 WHERE id = 1);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

