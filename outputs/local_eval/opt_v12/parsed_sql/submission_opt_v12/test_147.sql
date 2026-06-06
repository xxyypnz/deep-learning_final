-- ===== Commit 147 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
CREATE UNIQUE INDEX idx_t1 ON test_t1 (id);

-- Execution: This should mark the index as primary and flush the table's relcache
ALTER TABLE test_t1 ADD PRIMARY KEY USING INDEX idx_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
CREATE UNIQUE INDEX idx_t2 ON test_t2 (id);

-- Execution: Empty table, still triggers the relcache flush
ALTER TABLE test_t2 ADD PRIMARY KEY USING INDEX idx_t2;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT PRIMARY KEY);
INSERT INTO test_t3 VALUES (1);
CREATE UNIQUE INDEX idx_t3 ON test_t3 (id);

-- Execution: This will fail because the table already has a primary key, so the new code path is not executed
ALTER TABLE test_t3 ADD PRIMARY KEY USING INDEX idx_t3;

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

