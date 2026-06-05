-- ===== Commit 129 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_wide CASCADE;
CREATE TABLE test_wide (id INT, data text);
INSERT INTO test_wide SELECT generate_series(1, 100), repeat('x', 10000);

-- Execution: Hash join with large tuples and small work_mem
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_wide a JOIN test_wide b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_wide CASCADE;
RESET work_mem;

-- --- Test Case 2 ---
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_wide2 CASCADE;
CREATE TABLE test_wide2 (id INT, data text);
INSERT INTO test_wide2 SELECT generate_series(1, 50), repeat('y', 20000);

-- Execution: Hash join with very large tuples
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_wide2 a JOIN test_wide2 b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_wide2 CASCADE;
RESET work_mem;

-- --- Test Case 3 ---
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_single_wide CASCADE;
CREATE TABLE test_single_wide (id INT, data text);
INSERT INTO test_single_wide VALUES (1, repeat('z', 50000));

-- Execution: Hash join with single very wide row
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_single_wide a JOIN test_single_wide b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_single_wide CASCADE;
RESET work_mem;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS hash129_a CASCADE;
DROP TABLE IF EXISTS hash129_b CASCADE;
SET work_mem = '64kB';
SET enable_mergejoin = off;
SET enable_nestloop = off;
SET enable_hashjoin = on;
CREATE TABLE hash129_a (id int, payload text);
CREATE TABLE hash129_b (id int, payload text);
INSERT INTO hash129_a SELECT g, repeat('a', 200000) FROM generate_series(1, 8) g;
INSERT INTO hash129_b SELECT g, repeat('b', 200000) FROM generate_series(1, 8) g;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT count(*) FROM hash129_a a JOIN hash129_b b ON a.id = b.id;
RESET enable_mergejoin;
RESET enable_nestloop;
RESET enable_hashjoin;
RESET work_mem;
DROP TABLE IF EXISTS hash129_a CASCADE;
DROP TABLE IF EXISTS hash129_b CASCADE;

