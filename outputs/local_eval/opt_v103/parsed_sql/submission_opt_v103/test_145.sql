-- ===== Commit 145 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_reorder CASCADE;
CREATE TABLE test_reorder (id INT, val TEXT);
INSERT INTO test_reorder SELECT generate_series(1, 100), 'data' || generate_series(1, 100);
CREATE INDEX idx_test_reorder ON test_reorder (id);

-- Execution: Use an index scan with reordering (e.g., ORDER BY) and then rescan via a cursor or multiple executions
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM test_reorder ORDER BY id;
FETCH 10 FROM c;
FETCH 10 FROM c;  -- This triggers a rescan of the index scan
CLOSE c;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_reorder CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_empty CASCADE;
CREATE TABLE test_empty (id INT, val TEXT);
CREATE INDEX idx_test_empty ON test_empty (id);

-- Execution: Use an index scan with reordering on empty table, then rescan
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM test_empty ORDER BY id;
FETCH 1 FROM c;  -- No rows, but rescan still occurs
CLOSE c;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_empty CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_dup CASCADE;
CREATE TABLE test_dup (id INT, val TEXT);
INSERT INTO test_dup VALUES (1, 'a'), (1, 'b'), (2, 'c'), (2, 'd');
CREATE INDEX idx_test_dup ON test_dup (id);

-- Execution: Use an index scan with reordering and rescan to trigger the fix
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM test_dup ORDER BY id;
FETCH 2 FROM c;
FETCH 2 FROM c;  -- Rescan after partial fetch
CLOSE c;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_dup CASCADE;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS knn145_pts CASCADE;
CREATE TABLE knn145_pts (id int, p point);
INSERT INTO knn145_pts SELECT g, point(g % 100, (g * 17) % 100) FROM generate_series(1,5000) g;
INSERT INTO knn145_pts SELECT 5000 + g, point(50, 50) FROM generate_series(1,200) g;
CREATE INDEX knn145_pts_idx ON knn145_pts USING spgist (p kd_point_ops);
ANALYZE knn145_pts;
SET enable_seqscan = off;
SET enable_bitmapscan = off;
BEGIN;
DECLARE knn145_c CURSOR FOR SELECT id, p FROM knn145_pts ORDER BY p <-> point(50,50) LIMIT 1000;
FETCH 10 FROM knn145_c;
MOVE BACKWARD 5 FROM knn145_c;
FETCH 10 FROM knn145_c;
CLOSE knn145_c;
COMMIT;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT id FROM knn145_pts ORDER BY p <-> point(50,50) LIMIT 50;
RESET enable_seqscan;
RESET enable_bitmapscan;
DROP TABLE IF EXISTS knn145_pts CASCADE;

