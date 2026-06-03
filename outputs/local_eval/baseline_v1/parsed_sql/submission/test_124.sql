-- ===== Commit 124 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_part CASCADE;
CREATE TABLE test_part (id INT) PARTITION BY RANGE (id);
CREATE TABLE test_part_1 PARTITION OF test_part FOR VALUES FROM (1) TO (100);
CREATE OR REPLACE FUNCTION test_trigger_func() RETURNS TRIGGER AS $$ BEGIN RETURN NULL; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER test_stmt_trigger AFTER INSERT ON test_part FOR EACH STATEMENT EXECUTE FUNCTION test_trigger_func();

-- Execution
COPY test_part FROM STDIN WITH (FORMAT CSV);
1
2
3
\.

-- Teardown
DROP TABLE IF EXISTS test_part CASCADE;
DROP FUNCTION IF EXISTS test_trigger_func CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_part_row CASCADE;
CREATE TABLE test_part_row (id INT) PARTITION BY RANGE (id);
CREATE TABLE test_part_row_1 PARTITION OF test_part_row FOR VALUES FROM (1) TO (100);
CREATE OR REPLACE FUNCTION test_row_trigger_func() RETURNS TRIGGER AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER test_row_trigger AFTER INSERT ON test_part_row FOR EACH ROW EXECUTE FUNCTION test_row_trigger_func();

-- Execution
COPY test_part_row FROM STDIN WITH (FORMAT CSV);
10
20
30
\.

-- Teardown
DROP TABLE IF EXISTS test_part_row CASCADE;
DROP FUNCTION IF EXISTS test_row_trigger_func CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_part_multi CASCADE;
CREATE TABLE test_part_multi (id INT) PARTITION BY RANGE (id);
CREATE TABLE test_part_multi_1 PARTITION OF test_part_multi FOR VALUES FROM (1) TO (100);
CREATE OR REPLACE FUNCTION test_multi_row_func() RETURNS TRIGGER AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION test_multi_stmt_func() RETURNS TRIGGER AS $$ BEGIN RETURN NULL; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER test_multi_row_trigger AFTER INSERT ON test_part_multi FOR EACH ROW EXECUTE FUNCTION test_multi_row_func();
CREATE TRIGGER test_multi_stmt_trigger AFTER INSERT ON test_part_multi FOR EACH STATEMENT EXECUTE FUNCTION test_multi_stmt_func();

-- Execution
COPY test_part_multi FROM STDIN WITH (FORMAT CSV);
100
200
300
\.

-- Teardown
DROP TABLE IF EXISTS test_part_multi CASCADE;
DROP FUNCTION IF EXISTS test_multi_row_func CASCADE;
DROP FUNCTION IF EXISTS test_multi_stmt_func CASCADE;

