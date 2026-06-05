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
DROP TABLE IF EXISTS knn_poly145 CASCADE;
CREATE TABLE knn_poly145 (id int, f1 polygon);
INSERT INTO knn_poly145 VALUES
  (1, polygon '((0,0),(0,10),(10,10),(10,0))'),
  (2, polygon '((20,20),(20,30),(30,30),(30,20))'),
  (3, polygon '((40,40),(40,60),(60,60),(60,40))'),
  (4, polygon '((5,30),(5,40),(15,40),(15,30))');
CREATE INDEX knn_poly145_gist ON knn_poly145 USING gist (f1);
SET enable_seqscan = off;
SET enable_bitmapscan = off;
SET enable_indexscan = on;
SELECT point(x,x), (SELECT f1 FROM knn_poly145 ORDER BY f1 <-> point(x,x) LIMIT 1)
FROM generate_series(0,50,10) AS g(x);
RESET enable_seqscan;
RESET enable_bitmapscan;
RESET enable_indexscan;
DROP TABLE IF EXISTS knn_poly145 CASCADE;

