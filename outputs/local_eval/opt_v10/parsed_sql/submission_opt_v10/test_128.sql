-- ===== Commit 128 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_part_t1 CASCADE;
CREATE TABLE test_part_t1 (a INT, b INT) PARTITION BY RANGE (a);
CREATE TABLE test_part_t1_p1 PARTITION OF test_part_t1 FOR VALUES FROM (1) TO (100);
CREATE TABLE test_part_t1_p2 PARTITION OF test_part_t1 FOR VALUES FROM (100) TO (200);
CREATE INDEX ON test_part_t1_p1 (a);
CREATE INDEX ON test_part_t1_p2 (a);

-- Execution: create partitioned index, should match existing child indexes
CREATE INDEX ON test_part_t1 (a);

-- Teardown
DROP TABLE IF EXISTS test_part_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_part_t2 CASCADE;
CREATE TABLE test_part_t2 (a TEXT, b INT) PARTITION BY RANGE (a COLLATE "C");
CREATE TABLE test_part_t2_p1 PARTITION OF test_part_t2 FOR VALUES FROM ('a') TO ('m');
CREATE TABLE test_part_t2_p2 PARTITION OF test_part_t2 FOR VALUES FROM ('m') TO ('z');
CREATE INDEX ON test_part_t2_p1 (a COLLATE "POSIX");
CREATE INDEX ON test_part_t2_p2 (a COLLATE "POSIX");

-- Execution: create partitioned index with different collation, should not match existing child indexes
CREATE INDEX ON test_part_t2 (a COLLATE "C");

-- Teardown
DROP TABLE IF EXISTS test_part_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_part_t3 CASCADE;
CREATE TABLE test_part_t3 (a INT, b INT) PARTITION BY RANGE (a);
CREATE TABLE test_part_t3_p1 PARTITION OF test_part_t3 FOR VALUES FROM (1) TO (100);
CREATE TABLE test_part_t3_p2 PARTITION OF test_part_t3 FOR VALUES FROM (100) TO (200);
CREATE INDEX test_idx_p1 ON test_part_t3_p1 (a);
CREATE INDEX test_idx_p2 ON test_part_t3_p2 (a);

-- Execution: create partitioned index with same name, should fail due to duplicate
CREATE INDEX test_idx_parent ON test_part_t3 (a);

-- Teardown
DROP TABLE IF EXISTS test_part_t3 CASCADE;

