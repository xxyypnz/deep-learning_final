-- ===== Commit 142 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE test_querydef1 (a int, b text);
INSERT INTO test_querydef1 VALUES (1, 'hello');

-- Execution: Use pg_get_querydef to deparse a simple query
SELECT pg_get_querydef(plan, true) FROM (SELECT (SELECT * FROM test_querydef1 WHERE a = 1)::text::query AS plan) q;

-- Teardown
DROP TABLE IF EXISTS test_querydef1 CASCADE;

-- --- Test Case 2 ---
-- Setup
CREATE TABLE test_subquery_alias (x int);
INSERT INTO test_subquery_alias VALUES (1), (2);

-- Execution: Create a view with a subquery in FROM (no alias) and deparse it
CREATE VIEW test_subquery_view AS SELECT * FROM (SELECT x FROM test_subquery_alias) AS sq;
SELECT pg_get_viewdef('test_subquery_view', true);

-- Teardown
DROP VIEW IF EXISTS test_subquery_view CASCADE;
DROP TABLE IF EXISTS test_subquery_alias CASCADE;

-- --- Test Case 3 ---
-- Setup
CREATE TABLE test_pretty_false (id int, val text);
INSERT INTO test_pretty_false VALUES (1, 'a'), (2, 'b');

-- Execution: Use pg_get_querydef with pretty=false on a query with JOIN
SELECT pg_get_querydef(plan, false) FROM (SELECT (SELECT * FROM test_pretty_false t1 JOIN test_pretty_false t2 ON t1.id = t2.id)::text::query AS plan) q;

-- Teardown
DROP TABLE IF EXISTS test_pretty_false CASCADE;

