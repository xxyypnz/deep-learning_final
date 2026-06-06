-- ===== Commit 114 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS hash_test1 CASCADE;
CREATE TABLE hash_test1 (id int, val text);
CREATE INDEX hash_idx1 ON hash_test1 USING hash (id);
-- Insert enough rows to trigger a bucket split (requires multiple pages)
INSERT INTO hash_test1 SELECT generate_series(1, 1000), 'data' || generate_series(1, 1000);

-- Execution: force a checkpoint to ensure WAL replay occurs
CHECKPOINT;
-- Perform an INSERT that may cause a split (if not already)
INSERT INTO hash_test1 VALUES (2000, 'extra');

-- Teardown
DROP TABLE IF EXISTS hash_test1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS hash_test2 CASCADE;
CREATE TABLE hash_test2 (id int, val text);
CREATE INDEX hash_idx2 ON hash_test2 USING hash (id);
-- Insert many duplicate values to force splits with duplicates
INSERT INTO hash_test2 SELECT 1, 'dup' || generate_series(1, 500);
INSERT INTO hash_test2 SELECT 2, 'dup' || generate_series(1, 500);

-- Execution: checkpoint and then insert more to trigger split replay
CHECKPOINT;
INSERT INTO hash_test2 VALUES (1, 'more_dup');

-- Teardown
DROP TABLE IF EXISTS hash_test2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS hash_test3 CASCADE;
CREATE TABLE hash_test3 (id int, val text);
CREATE INDEX hash_idx3 ON hash_test3 USING hash (id);
-- Start with empty table, then insert to cause initial split
INSERT INTO hash_test3 VALUES (1, 'first');

-- Execution: checkpoint and then insert to trigger split replay
CHECKPOINT;
INSERT INTO hash_test3 SELECT generate_series(2, 100), 'batch' || generate_series(2, 100);

-- Teardown
DROP TABLE IF EXISTS hash_test3 CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS hash_replay114 CASCADE;
CREATE TABLE hash_replay114 (id int, payload text) WITH (autovacuum_enabled=false);
CREATE INDEX hash_replay114_idx ON hash_replay114 USING hash (id);
INSERT INTO hash_replay114 SELECT g, repeat(md5(g::text), 8) FROM generate_series(1, 20000) g;
CHECKPOINT;
INSERT INTO hash_replay114 SELECT g, repeat(md5(g::text), 8) FROM generate_series(20001, 50000) g;
\! /bin/sh -c "/workspaces/deep-learning_final/postgresql-13.23/install_coverage/bin/pg_ctl -D /workspaces/deep-learning_final/outputs/local_eval/opt_v20/coverage_workspace/data stop -m immediate; /workspaces/deep-learning_final/postgresql-13.23/install_coverage/bin/pg_ctl -D /workspaces/deep-learning_final/outputs/local_eval/opt_v20/coverage_workspace/data -l /workspaces/deep-learning_final/outputs/local_eval/opt_v20/coverage_workspace/server.log -o '-k /tmp/pgcov-55432 -p 55432' start" >/tmp/replay_hash_114_opt_v20.log 2>&1
\connect regression
SELECT count(*) FROM hash_replay114;
DROP TABLE IF EXISTS hash_replay114 CASCADE;

