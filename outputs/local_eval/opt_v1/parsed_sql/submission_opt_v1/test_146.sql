-- ===== Commit 146 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS merge_test_outer CASCADE;
DROP TABLE IF EXISTS merge_test_inner CASCADE;
CREATE TABLE merge_test_outer (id INT);
CREATE TABLE merge_test_inner (id INT);
INSERT INTO merge_test_outer VALUES (2), (1);
INSERT INTO merge_test_inner VALUES (1), (2);
-- Execution: Force mergejoin with out-of-order outer input
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;
SELECT * FROM merge_test_outer o JOIN merge_test_inner i ON o.id = i.id;
-- Teardown
DROP TABLE IF EXISTS merge_test_outer CASCADE;
DROP TABLE IF EXISTS merge_test_inner CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS merge_test_outer2 CASCADE;
DROP TABLE IF EXISTS merge_test_inner2 CASCADE;
CREATE TABLE merge_test_outer2 (id INT);
CREATE TABLE merge_test_inner2 (id INT);
INSERT INTO merge_test_outer2 VALUES (1), (2);
INSERT INTO merge_test_inner2 VALUES (2), (1);
-- Execution: Force mergejoin with out-of-order inner input
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;
SELECT * FROM merge_test_outer2 o JOIN merge_test_inner2 i ON o.id = i.id;
-- Teardown
DROP TABLE IF EXISTS merge_test_outer2 CASCADE;
DROP TABLE IF EXISTS merge_test_inner2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS merge_test_outer3 CASCADE;
DROP TABLE IF EXISTS merge_test_inner3 CASCADE;
CREATE TABLE merge_test_outer3 (id INT);
CREATE TABLE merge_test_inner3 (id INT);
INSERT INTO merge_test_outer3 VALUES (1), (2), (3);
INSERT INTO merge_test_inner3 VALUES (1), (2), (3);
-- Execution: Normal mergejoin with ordered data
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;
SELECT * FROM merge_test_outer3 o JOIN merge_test_inner3 i ON o.id = i.id;
-- Teardown
DROP TABLE IF EXISTS merge_test_outer3 CASCADE;
DROP TABLE IF EXISTS merge_test_inner3 CASCADE;

