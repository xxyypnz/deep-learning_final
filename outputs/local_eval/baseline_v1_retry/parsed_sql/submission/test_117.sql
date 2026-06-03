-- ===== Commit 117 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
CREATE TABLE parent_tbl (id INT PRIMARY KEY);
CREATE TABLE child_tbl (id INT REFERENCES parent_tbl(id));
INSERT INTO parent_tbl VALUES (1);
INSERT INTO child_tbl VALUES (1);

-- Execution: attach child as partition of a new partitioned table
CREATE TABLE part_parent (id INT PRIMARY KEY) PARTITION BY RANGE (id);
ALTER TABLE part_parent ATTACH PARTITION child_tbl FOR VALUES FROM (1) TO (2);

-- Teardown
DROP TABLE IF EXISTS part_parent CASCADE;
DROP TABLE IF EXISTS parent_tbl CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS ref_parent CASCADE;
DROP TABLE IF EXISTS ref_child CASCADE;
CREATE TABLE ref_parent (id INT PRIMARY KEY);
CREATE TABLE ref_child (id INT REFERENCES ref_parent(id));
INSERT INTO ref_parent VALUES (1);
INSERT INTO ref_child VALUES (1);

-- Execution: create a partitioned table and attach ref_child as partition, triggering CloneFkReferencing
CREATE TABLE part_ref (id INT PRIMARY KEY) PARTITION BY RANGE (id);
ALTER TABLE part_ref ATTACH PARTITION ref_child FOR VALUES FROM (1) TO (2);

-- Teardown
DROP TABLE IF EXISTS part_ref CASCADE;
DROP TABLE IF EXISTS ref_parent CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS detach_parent CASCADE;
DROP TABLE IF EXISTS detach_child CASCADE;
CREATE TABLE detach_parent (id INT PRIMARY KEY) PARTITION BY RANGE (id);
CREATE TABLE detach_child (id INT PRIMARY KEY);
ALTER TABLE detach_parent ATTACH PARTITION detach_child FOR VALUES FROM (1) TO (2);
ALTER TABLE detach_child ADD CONSTRAINT fk_detach FOREIGN KEY (id) REFERENCES detach_parent(id);
INSERT INTO detach_parent VALUES (1);
INSERT INTO detach_child VALUES (1);

-- Execution: detach the partition, which recreates the FK constraint
ALTER TABLE detach_parent DETACH PARTITION detach_child;

-- Teardown
DROP TABLE IF EXISTS detach_parent CASCADE;
DROP TABLE IF EXISTS detach_child CASCADE;

