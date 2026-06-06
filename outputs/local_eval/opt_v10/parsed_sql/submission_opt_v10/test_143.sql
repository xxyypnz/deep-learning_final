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
DROP TABLE IF EXISTS wrongdrop143 CASCADE;
CREATE TABLE wrongdrop143 (a int) PARTITION BY RANGE (a);
CREATE TABLE wrongdrop143_1 PARTITION OF wrongdrop143 FOR VALUES FROM (0) TO (10);
CREATE INDEX wrongdrop143_a_idx ON wrongdrop143 (a);
DROP TABLE wrongdrop143_a_idx;
DROP INDEX wrongdrop143_a_idx;
DROP TABLE IF EXISTS wrongdrop143 CASCADE;

