-- ===== Commit 121 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup: Create a partitioned table with a self-referencing foreign key and a primary key
DROP TABLE IF EXISTS test_part_fk CASCADE;
CREATE TABLE test_part_fk (
    id INT NOT NULL,
    ref_id INT,
    PRIMARY KEY (id),
    FOREIGN KEY (ref_id) REFERENCES test_part_fk(id)
) PARTITION BY RANGE (id);
CREATE TABLE test_part_fk_1 PARTITION OF test_part_fk FOR VALUES FROM (1) TO (100);

-- Execution: This should trigger the modified code path when cloning constraints for the partition
-- The foreign key constraint should be ignored when looking for the index-backed constraint
INSERT INTO test_part_fk (id, ref_id) VALUES (1, NULL);
INSERT INTO test_part_fk (id, ref_id) VALUES (2, 1);

-- Teardown
DROP TABLE IF EXISTS test_part_fk CASCADE;

-- --- Test Case 2 ---
-- Setup: Create a partitioned table with a self-referencing foreign key and a unique constraint
DROP TABLE IF EXISTS test_part_selfref CASCADE;
CREATE TABLE test_part_selfref (
    id INT NOT NULL,
    ref_id INT,
    UNIQUE (id),
    FOREIGN KEY (ref_id) REFERENCES test_part_selfref(id)
) PARTITION BY RANGE (id);
CREATE TABLE test_part_selfref_1 PARTITION OF test_part_selfref FOR VALUES FROM (1) TO (100);

-- Execution: Insert data to trigger constraint cloning; should not create duplicate foreign keys
INSERT INTO test_part_selfref (id, ref_id) VALUES (10, NULL);
INSERT INTO test_part_selfref (id, ref_id) VALUES (20, 10);

-- Teardown
DROP TABLE IF EXISTS test_part_selfref CASCADE;

-- --- Test Case 3 ---
-- Setup: Create a partitioned table with both a primary key and a foreign key referencing the same column
DROP TABLE IF EXISTS test_part_multi CASCADE;
CREATE TABLE test_part_multi (
    id INT NOT NULL,
    ref_id INT,
    PRIMARY KEY (id),
    FOREIGN KEY (ref_id) REFERENCES test_part_multi(id)
) PARTITION BY RANGE (id);
CREATE TABLE test_part_multi_1 PARTITION OF test_part_multi FOR VALUES FROM (1) TO (100);

-- Execution: Insert data to trigger constraint lookups; the primary key should be found, not the foreign key
INSERT INTO test_part_multi (id, ref_id) VALUES (100, NULL);
INSERT INTO test_part_multi (id, ref_id) VALUES (200, 100);

-- Teardown
DROP TABLE IF EXISTS test_part_multi CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS self_fk_part CASCADE;
CREATE TABLE self_fk_part (
  id int NOT NULL,
  parent_id int,
  CONSTRAINT self_fk_part_pk PRIMARY KEY (id),
  CONSTRAINT self_fk_part_fk FOREIGN KEY (parent_id) REFERENCES self_fk_part(id)
) PARTITION BY RANGE (id);
CREATE TABLE self_fk_part_1 PARTITION OF self_fk_part FOR VALUES FROM (1) TO (100);
CREATE INDEX self_fk_part_parent_idx ON self_fk_part(parent_id);
ALTER INDEX self_fk_part_parent_idx ATTACH PARTITION self_fk_part_1_parent_id_idx;
SELECT conname, contype FROM pg_constraint WHERE conrelid='self_fk_part_1'::regclass ORDER BY conname;
DROP TABLE IF EXISTS self_fk_part CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS parted_self_fk CASCADE;
CREATE TABLE parted_self_fk (
    id bigint NOT NULL PRIMARY KEY,
    id_abc bigint,
    FOREIGN KEY (id_abc) REFERENCES parted_self_fk(id)
) PARTITION BY RANGE (id);
CREATE TABLE part1_self_fk (
    id bigint NOT NULL PRIMARY KEY,
    id_abc bigint
);
ALTER TABLE parted_self_fk ATTACH PARTITION part1_self_fk FOR VALUES FROM (0) TO (10);
CREATE TABLE part2_self_fk PARTITION OF parted_self_fk FOR VALUES FROM (10) TO (20);
CREATE TABLE part3_self_fk (
    id bigint NOT NULL PRIMARY KEY,
    id_abc bigint
) PARTITION BY RANGE (id);
CREATE TABLE part32_self_fk PARTITION OF part3_self_fk FOR VALUES FROM (20) TO (30);
ALTER TABLE parted_self_fk ATTACH PARTITION part3_self_fk FOR VALUES FROM (20) TO (40);
CREATE TABLE part33_self_fk (id bigint NOT NULL PRIMARY KEY, id_abc bigint);
ALTER TABLE part3_self_fk ATTACH PARTITION part33_self_fk FOR VALUES FROM (30) TO (40);
INSERT INTO parted_self_fk VALUES (1, NULL), (2, NULL), (3, NULL);
INSERT INTO parted_self_fk VALUES (10, 1), (11, 2), (12, 3);
SELECT cr.relname, co.conname, co.convalidated, p.conname AS conparent, cf.relname AS foreignrel
FROM pg_constraint co
JOIN pg_class cr ON cr.oid = co.conrelid
LEFT JOIN pg_class cf ON cf.oid = co.confrelid
LEFT JOIN pg_constraint p ON p.oid = co.conparentid
WHERE co.contype = 'f' AND cr.oid IN (SELECT relid FROM pg_partition_tree('parted_self_fk'))
ORDER BY cr.relname, co.conname, p.conname;
ALTER TABLE parted_self_fk DETACH PARTITION part2_self_fk;
ALTER TABLE parted_self_fk ATTACH PARTITION part2_self_fk FOR VALUES FROM (10) TO (20);
ALTER TABLE parted_self_fk DETACH PARTITION part3_self_fk;
ALTER TABLE parted_self_fk ATTACH PARTITION part3_self_fk FOR VALUES FROM (20) TO (40);
ALTER TABLE part3_self_fk DETACH PARTITION part33_self_fk;
ALTER TABLE part3_self_fk ATTACH PARTITION part33_self_fk FOR VALUES FROM (30) TO (40);
DROP TABLE IF EXISTS parted_self_fk CASCADE;

