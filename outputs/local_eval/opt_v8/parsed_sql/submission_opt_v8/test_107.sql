-- ===== Commit 107 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution: Deeply nested EXISTS subqueries to trigger recursion in pull_up_sublinks_jointree_recurse
SELECT * FROM test_t1 WHERE EXISTS (SELECT 1 FROM test_t2 WHERE EXISTS (SELECT 1 FROM test_t1 WHERE test_t1.id = test_t2.id));

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution: Deeply nested subquery in FROM clause to trigger recursion in pull_up_subqueries_recurse
SELECT * FROM (SELECT * FROM (SELECT * FROM test_t1 WHERE id = 1) AS sub1) AS sub2;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (2);

-- Execution: Deeply nested UNION ALL to trigger recursion in is_simple_union_all_recurse
SELECT * FROM test_t1 UNION ALL SELECT * FROM test_t2 UNION ALL SELECT * FROM test_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

