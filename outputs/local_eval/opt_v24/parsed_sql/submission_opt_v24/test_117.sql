-- ===== Commit 117 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS fk_ref_parent CASCADE;
DROP TABLE IF EXISTS fk_part_parent CASCADE;
CREATE TABLE fk_ref_parent (id int PRIMARY KEY);
CREATE TABLE fk_part_parent (id int NOT NULL REFERENCES fk_ref_parent(id)) PARTITION BY RANGE (id);
CREATE TABLE fk_part_child PARTITION OF fk_part_parent FOR VALUES FROM (1) TO (10);
INSERT INTO fk_ref_parent VALUES (1);
INSERT INTO fk_part_parent VALUES (1);
ALTER TABLE fk_part_parent ATTACH PARTITION fk_part_child FOR VALUES FROM (1) TO (10);
DROP TABLE IF EXISTS fk_part_parent CASCADE;
DROP TABLE IF EXISTS fk_ref_parent CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS detach_ref_plain CASCADE;
DROP TABLE IF EXISTS detach_parent CASCADE;
CREATE TABLE detach_ref_plain (id int PRIMARY KEY);
CREATE TABLE detach_parent (id int NOT NULL REFERENCES detach_ref_plain(id)) PARTITION BY RANGE (id);
CREATE TABLE detach_child PARTITION OF detach_parent FOR VALUES FROM (1) TO (10);
INSERT INTO detach_ref_plain VALUES (1);
INSERT INTO detach_parent VALUES (1);
ALTER TABLE detach_parent DETACH PARTITION detach_child;
DROP TABLE IF EXISTS detach_child CASCADE;
DROP TABLE IF EXISTS detach_parent CASCADE;
DROP TABLE IF EXISTS detach_ref_plain CASCADE;

-- --- Test Case 3 ---
DROP TABLE IF EXISTS ref_parent_ok CASCADE;
DROP TABLE IF EXISTS ref_parted_ok CASCADE;
CREATE TABLE ref_parent_ok (id int PRIMARY KEY);
CREATE TABLE ref_parted_ok (id int NOT NULL REFERENCES ref_parent_ok(id)) PARTITION BY RANGE (id);
CREATE TABLE ref_child_ok (id int NOT NULL REFERENCES ref_parent_ok(id));
ALTER TABLE ref_parted_ok ATTACH PARTITION ref_child_ok FOR VALUES FROM (1) TO (10);
DROP TABLE IF EXISTS ref_parted_ok CASCADE;
DROP TABLE IF EXISTS ref_parent_ok CASCADE;

