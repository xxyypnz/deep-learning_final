-- ===== Commit 109 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int, b int);
CREATE TABLE t2 (c int, d int);
INSERT INTO t1 SELECT generate_series(1,100), generate_series(1,100);
INSERT INTO t2 SELECT generate_series(1,100), generate_series(1,100);
ANALYZE t1, t2;

-- Execution: Force a parameterized nested loop join that may use Memoize
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
EXPLAIN (COSTS OFF) SELECT * FROM t1, t2 WHERE t1.a = t2.c AND t1.b = 1;
SELECT * FROM t1, t2 WHERE t1.a = t2.c AND t1.b = 1;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int PRIMARY KEY);
CREATE TABLE t2 (b int REFERENCES t1(a));
INSERT INTO t1 SELECT generate_series(1,10);
INSERT INTO t2 SELECT generate_series(1,10);
ANALYZE t1, t2;

-- Execution: Use a parameterized join that might fail reparameterization due to outer rel mismatch
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
EXPLAIN (COSTS OFF) SELECT * FROM t1, t2 WHERE t1.a = t2.b AND t2.b = 5;
SELECT * FROM t1, t2 WHERE t1.a = t2.b AND t2.b = 5;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (x int, y int);
CREATE TABLE t2 (z int, w int);
INSERT INTO t1 SELECT generate_series(1,50), generate_series(1,50);
INSERT INTO t2 SELECT generate_series(1,50), generate_series(1,50);
ANALYZE t1, t2;

-- Execution: Use a subquery with parameterized join and Memoize
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
EXPLAIN (COSTS OFF) SELECT * FROM t1 WHERE t1.x IN (SELECT t2.z FROM t2 WHERE t2.w = t1.y AND t2.z > 10);
SELECT * FROM t1 WHERE t1.x IN (SELECT t2.z FROM t2 WHERE t2.w = t1.y AND t2.z > 10);

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
RESET enable_hashjoin;
RESET enable_mergejoin;
RESET enable_nestloop;

-- --- Test Case 4 ---
DROP TABLE IF EXISTS memo109_p CASCADE;
DROP TABLE IF EXISTS memo109_q CASCADE;
CREATE TABLE memo109_p (a int, b int) PARTITION BY RANGE (a);
CREATE TABLE memo109_p1 PARTITION OF memo109_p FOR VALUES FROM (0) TO (100);
CREATE TABLE memo109_p2 PARTITION OF memo109_p FOR VALUES FROM (100) TO (200);
CREATE TABLE memo109_q (a int, b int) PARTITION BY RANGE (a);
CREATE TABLE memo109_q1 PARTITION OF memo109_q FOR VALUES FROM (0) TO (100);
CREATE TABLE memo109_q2 PARTITION OF memo109_q FOR VALUES FROM (100) TO (200);
CREATE INDEX memo109_p_b_idx ON memo109_p (b);
CREATE INDEX memo109_q_b_idx ON memo109_q (b);
INSERT INTO memo109_p SELECT g, g % 10 FROM generate_series(1,199) g;
INSERT INTO memo109_q SELECT g, g % 10 FROM generate_series(1,199) g;
ANALYZE memo109_p; ANALYZE memo109_q;
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
SET enable_partitionwise_join = on;
SET enable_memoize = on;
EXPLAIN (COSTS OFF)
SELECT * FROM memo109_p p JOIN memo109_q q ON q.b = p.b WHERE p.a < 150 AND q.a < 150;
SELECT count(*) FROM memo109_p p JOIN memo109_q q ON q.b = p.b WHERE p.a < 150 AND q.a < 150;
RESET enable_hashjoin; RESET enable_mergejoin; RESET enable_nestloop; RESET enable_partitionwise_join; RESET enable_memoize;
DROP TABLE IF EXISTS memo109_p CASCADE;
DROP TABLE IF EXISTS memo109_q CASCADE;

-- --- Test Case 5 ---
DROP TABLE IF EXISTS memo109_outer CASCADE;
DROP TABLE IF EXISTS memo109_inner CASCADE;
CREATE TABLE memo109_outer (k int);
CREATE TABLE memo109_inner (k int, v int) PARTITION BY RANGE (k);
CREATE TABLE memo109_inner1 PARTITION OF memo109_inner FOR VALUES FROM (0) TO (50);
CREATE TABLE memo109_inner2 PARTITION OF memo109_inner FOR VALUES FROM (50) TO (100);
CREATE INDEX memo109_inner_k_idx ON memo109_inner (k);
INSERT INTO memo109_outer SELECT (g % 80) FROM generate_series(1,1000) g;
INSERT INTO memo109_inner SELECT g, g FROM generate_series(0,99) g;
ANALYZE memo109_outer; ANALYZE memo109_inner;
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;
SET enable_memoize = on;
EXPLAIN (COSTS OFF)
SELECT o.k, s.v FROM memo109_outer o JOIN LATERAL (SELECT v FROM memo109_inner i WHERE i.k = o.k) s ON true;
SELECT count(*) FROM memo109_outer o JOIN LATERAL (SELECT v FROM memo109_inner i WHERE i.k = o.k) s ON true;
RESET enable_hashjoin; RESET enable_mergejoin; RESET enable_nestloop; RESET enable_memoize;
DROP TABLE IF EXISTS memo109_outer CASCADE;
DROP TABLE IF EXISTS memo109_inner CASCADE;

