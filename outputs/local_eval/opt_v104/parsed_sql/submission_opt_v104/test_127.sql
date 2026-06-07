-- ===== Commit 127 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup: Create parent table with a foreign key constraint, and a partition that already has a constraint with the same name
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
DROP TABLE IF EXISTS ref_tbl CASCADE;

CREATE TABLE ref_tbl (id INT PRIMARY KEY);
CREATE TABLE parent_tbl (id INT, ref_id INT REFERENCES ref_tbl(id)) PARTITION BY LIST (id);
CREATE TABLE child_tbl (id INT, ref_id INT);
-- Add a constraint with the same name as the parent's FK on the partition to force conflict
ALTER TABLE child_tbl ADD CONSTRAINT parent_tbl_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES ref_tbl(id);

-- Execution: Attach partition, which triggers CloneFkReferencing and the new code path
ALTER TABLE parent_tbl ATTACH PARTITION child_tbl FOR VALUES IN (1);

-- Teardown
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
DROP TABLE IF EXISTS ref_tbl CASCADE;

-- --- Test Case 2 ---
-- Setup: Create parent table with a foreign key constraint, and a partition with no conflicting constraint
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
DROP TABLE IF EXISTS ref_tbl CASCADE;

CREATE TABLE ref_tbl (id INT PRIMARY KEY);
CREATE TABLE parent_tbl (id INT, ref_id INT REFERENCES ref_tbl(id)) PARTITION BY LIST (id);
CREATE TABLE child_tbl (id INT, ref_id INT);

-- Execution: Attach partition, no name conflict, so else branch is taken
ALTER TABLE parent_tbl ATTACH PARTITION child_tbl FOR VALUES IN (1);

-- Teardown
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
DROP TABLE IF EXISTS ref_tbl CASCADE;

-- --- Test Case 3 ---
-- Setup: Create parent table with a composite foreign key, and a partition with a conflicting constraint name
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
DROP TABLE IF EXISTS ref_tbl CASCADE;

CREATE TABLE ref_tbl (a INT, b INT, PRIMARY KEY (a, b));
CREATE TABLE parent_tbl (id INT, a INT, b INT, FOREIGN KEY (a, b) REFERENCES ref_tbl(a, b)) PARTITION BY LIST (id);
CREATE TABLE child_tbl (id INT, a INT, b INT);
-- Add a constraint with the same name as the parent's FK to force conflict
ALTER TABLE child_tbl ADD CONSTRAINT parent_tbl_a_b_fkey FOREIGN KEY (a, b) REFERENCES ref_tbl(a, b);

-- Execution: Attach partition, triggers new code path with multiple FK attributes
ALTER TABLE parent_tbl ATTACH PARTITION child_tbl FOR VALUES IN (1);

-- Teardown
DROP TABLE IF EXISTS parent_tbl CASCADE;
DROP TABLE IF EXISTS child_tbl CASCADE;
DROP TABLE IF EXISTS ref_tbl CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS fk127_parent CASCADE;
DROP TABLE IF EXISTS fk127_child CASCADE;
DROP TABLE IF EXISTS fk127_ref CASCADE;
CREATE TABLE fk127_ref (id int PRIMARY KEY);
CREATE TABLE fk127_parent (id int NOT NULL, ref_id int REFERENCES fk127_ref(id)) PARTITION BY LIST (id);
CREATE TABLE fk127_child (id int NOT NULL, ref_id int);
ALTER TABLE fk127_parent ATTACH PARTITION fk127_child FOR VALUES IN (1);
SELECT conname FROM pg_constraint WHERE conrelid='fk127_child'::regclass ORDER BY conname;
DROP TABLE IF EXISTS fk127_parent CASCADE;
DROP TABLE IF EXISTS fk127_child CASCADE;
DROP TABLE IF EXISTS fk127_ref CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS fk127_conflict_parent CASCADE;
DROP TABLE IF EXISTS fk127_conflict_child CASCADE;
DROP TABLE IF EXISTS fk127_conflict_ref CASCADE;
CREATE TABLE fk127_conflict_ref (id int PRIMARY KEY);
CREATE TABLE fk127_conflict_parent (id int NOT NULL, ref_id int REFERENCES fk127_conflict_ref(id)) PARTITION BY LIST (id);
CREATE TABLE fk127_conflict_child (id int NOT NULL, ref_id int);
ALTER TABLE fk127_conflict_child ADD CONSTRAINT fk127_conflict_parent_ref_id_fkey CHECK (ref_id IS NULL OR ref_id IS NOT NULL);
ALTER TABLE fk127_conflict_parent ATTACH PARTITION fk127_conflict_child FOR VALUES IN (1);
SELECT conname FROM pg_constraint WHERE conrelid='fk127_conflict_child'::regclass ORDER BY conname;
DROP TABLE IF EXISTS fk127_conflict_parent CASCADE;
DROP TABLE IF EXISTS fk127_conflict_child CASCADE;
DROP TABLE IF EXISTS fk127_conflict_ref CASCADE;

-- --- Test Case 6 ---
DROP TABLE IF EXISTS parted_self_fk_127 CASCADE;
CREATE TABLE parted_self_fk_127 (
    id bigint NOT NULL PRIMARY KEY,
    id_abc bigint,
    FOREIGN KEY (id_abc) REFERENCES parted_self_fk_127(id)
) PARTITION BY RANGE (id);
CREATE TABLE part1_self_fk_127 (
    id bigint NOT NULL PRIMARY KEY,
    id_abc bigint
);
ALTER TABLE parted_self_fk_127 ATTACH PARTITION part1_self_fk_127 FOR VALUES FROM (0) TO (10);
CREATE TABLE part2_self_fk_127 PARTITION OF parted_self_fk_127 FOR VALUES FROM (10) TO (20);
ALTER TABLE parted_self_fk_127 DETACH PARTITION part2_self_fk_127;
ALTER TABLE parted_self_fk_127 ATTACH PARTITION part2_self_fk_127 FOR VALUES FROM (10) TO (20);
SELECT conrelid::regclass::text, conname, conparentid <> 0 AS inherited
FROM pg_constraint
WHERE contype = 'f' AND conrelid IN ('part1_self_fk_127'::regclass, 'part2_self_fk_127'::regclass)
ORDER BY 1,2;
DROP TABLE IF EXISTS parted_self_fk_127 CASCADE;

