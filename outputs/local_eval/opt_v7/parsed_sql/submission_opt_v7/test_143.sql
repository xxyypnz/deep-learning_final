-- ===== Commit 143 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS parent_table CASCADE;
CREATE TABLE parent_table (id INT, data TEXT) PARTITION BY RANGE (id);
CREATE TABLE child_table PARTITION OF parent_table FOR VALUES FROM (1) TO (100);
CREATE INDEX idx_parent ON parent_table(id);
CREATE INDEX idx_child ON child_table(id);

-- Execution
DROP INDEX idx_parent;

-- Teardown
DROP TABLE IF EXISTS parent_table CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS parent_table2 CASCADE;
CREATE TABLE parent_table2 (id INT, data TEXT) PARTITION BY RANGE (id);
CREATE TABLE child_table2 PARTITION OF parent_table2 FOR VALUES FROM (1) TO (100);
CREATE INDEX idx_parent2 ON parent_table2(id);
CREATE INDEX idx_child2 ON child_table2(id);

-- Execution
DROP INDEX CONCURRENTLY idx_parent2;

-- Teardown
DROP TABLE IF EXISTS parent_table2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS plain_table CASCADE;
CREATE TABLE plain_table (id INT, data TEXT);
CREATE INDEX idx_plain ON plain_table(id);

-- Execution
DROP INDEX idx_plain;

-- Teardown
DROP TABLE IF EXISTS plain_table CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS idxpart143 CASCADE;
CREATE TABLE idxpart143 (a int) PARTITION BY RANGE (a);
CREATE INDEX idxpart143_a_idx ON idxpart143 (a);
CREATE TABLE idxpart143_1 PARTITION OF idxpart143 FOR VALUES FROM (0) TO (10);
DROP INDEX idxpart143_1_a_idx;
DROP INDEX CONCURRENTLY idxpart143_a_idx;
DROP INDEX idxpart143_a_idx;
SELECT relname, relkind FROM pg_class WHERE relname LIKE 'idxpart143%' ORDER BY relname;
DROP TABLE IF EXISTS idxpart143 CASCADE;

