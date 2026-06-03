-- ===== Commit 141 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_part CASCADE;
CREATE TABLE test_part (a INT, b INT) PARTITION BY RANGE (a);
CREATE TABLE test_part_1 PARTITION OF test_part FOR VALUES FROM (1) TO (100);
INSERT INTO test_part VALUES (50, 100);

-- Execution
SELECT * FROM test_part WHERE a = 50;

-- Teardown
DROP TABLE IF EXISTS test_part CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_part_empty CASCADE;
CREATE TABLE test_part_empty (a INT, b INT) PARTITION BY RANGE (a);
-- No partitions created

-- Execution
INSERT INTO test_part_empty VALUES (1, 2);

-- Teardown
DROP TABLE IF EXISTS test_part_empty CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_part_multi CASCADE;
CREATE TABLE test_part_multi (a INT, b INT) PARTITION BY RANGE (a);
CREATE TABLE test_part_sub PARTITION OF test_part_multi FOR VALUES FROM (1) TO (100) PARTITION BY RANGE (b);
CREATE TABLE test_part_leaf PARTITION OF test_part_sub FOR VALUES FROM (1) TO (50);
INSERT INTO test_part_multi VALUES (10, 20);

-- Execution
SELECT * FROM test_part_multi WHERE a = 10 AND b = 20;

-- Teardown
DROP TABLE IF EXISTS test_part_multi CASCADE;

