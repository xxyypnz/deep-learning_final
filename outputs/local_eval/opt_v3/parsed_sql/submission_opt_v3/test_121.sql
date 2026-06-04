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
DROP TABLE IF EXISTS r121_self CASCADE;
CREATE TABLE r121_self (
  id int NOT NULL,
  parent_id int,
  PRIMARY KEY(id),
  FOREIGN KEY(parent_id) REFERENCES r121_self(id)
) PARTITION BY LIST(id);
CREATE TABLE r121_self_1 PARTITION OF r121_self FOR VALUES IN (1);
CREATE UNIQUE INDEX r121_self_1_uidx ON r121_self_1(id);
ALTER INDEX r121_self_pkey ATTACH PARTITION r121_self_1_uidx;
SELECT conname, contype, conindid::regclass FROM pg_constraint WHERE conrelid='r121_self_1'::regclass ORDER BY contype, conname;
DROP TABLE IF EXISTS r121_self CASCADE;

