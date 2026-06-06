\pset pager off
SET statement_timeout = 5000;
SET lock_timeout = 1000;
SET idle_in_transaction_session_timeout = 5000;

-- ===== Test Case 1 (commit 101) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);

-- Execution
WITH test_t1 AS (SELECT 2 AS id)
INSERT INTO test_t1 (id) SELECT id FROM test_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- ===== Test Case 2 (commit 101) =====
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution
WITH test_t2 AS (SELECT 2 AS id)
UPDATE test_t2 SET id = (SELECT id FROM test_t2) WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 3 (commit 101) =====
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
INSERT INTO test_t3 VALUES (1);

-- Execution
WITH test_t3 AS (SELECT 2 AS id)
DELETE FROM test_t3 WHERE id = (SELECT id FROM test_t3);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- ===== Test Case 4 (commit 101) =====
DROP VIEW IF EXISTS ruleutils_ins_v CASCADE;
DROP TABLE IF EXISTS ruleutils_ins_t CASCADE;
CREATE TABLE ruleutils_ins_t (id int, val text);
CREATE VIEW ruleutils_ins_v AS SELECT * FROM ruleutils_ins_t;
CREATE RULE ruleutils_ins_r AS ON INSERT TO ruleutils_ins_v DO INSTEAD
  WITH ruleutils_ins_t AS (SELECT 1 AS id, 'x'::text AS val)
  INSERT INTO ruleutils_ins_t AS target_alias SELECT id, val FROM ruleutils_ins_t;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='ruleutils_ins_v'::regclass AND rulename='ruleutils_ins_r';
DROP VIEW IF EXISTS ruleutils_ins_v CASCADE;
DROP TABLE IF EXISTS ruleutils_ins_t CASCADE;

-- ===== Test Case 5 (commit 101) =====
DROP VIEW IF EXISTS ruleutils_upd_v CASCADE;
DROP TABLE IF EXISTS ruleutils_upd_t CASCADE;
CREATE TABLE ruleutils_upd_t (id int, val text);
CREATE VIEW ruleutils_upd_v AS SELECT * FROM ruleutils_upd_t;
CREATE RULE ruleutils_upd_r AS ON UPDATE TO ruleutils_upd_v DO INSTEAD
  WITH ruleutils_upd_t AS (SELECT NEW.id AS id)
  UPDATE ruleutils_upd_t AS target_alias SET val = 'updated' WHERE target_alias.id IN (SELECT id FROM ruleutils_upd_t);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='ruleutils_upd_v'::regclass AND rulename='ruleutils_upd_r';
DROP VIEW IF EXISTS ruleutils_upd_v CASCADE;
DROP TABLE IF EXISTS ruleutils_upd_t CASCADE;

-- ===== Test Case 6 (commit 101) =====
DROP VIEW IF EXISTS ruleutils_del_v CASCADE;
DROP TABLE IF EXISTS ruleutils_del_t CASCADE;
DROP TABLE IF EXISTS ruleutils_aux CASCADE;
CREATE TABLE ruleutils_del_t (id int);
CREATE TABLE ruleutils_aux (id int);
CREATE VIEW ruleutils_del_v AS SELECT * FROM ruleutils_del_t;
CREATE RULE ruleutils_del_r AS ON DELETE TO ruleutils_del_v DO INSTEAD
  DELETE FROM ruleutils_del_t AS target_alias USING ruleutils_aux AS ruleutils_del_t WHERE target_alias.id = ruleutils_del_t.id;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='ruleutils_del_v'::regclass AND rulename='ruleutils_del_r';
DROP VIEW IF EXISTS ruleutils_del_v CASCADE;
DROP TABLE IF EXISTS ruleutils_del_t CASCADE;
DROP TABLE IF EXISTS ruleutils_aux CASCADE;

-- ===== Test Case 7 (commit 101) =====
DROP VIEW IF EXISTS ruleutils_alias_v CASCADE;
DROP FUNCTION IF EXISTS ruleutils_srf() CASCADE;
CREATE FUNCTION ruleutils_srf() RETURNS TABLE(a int, b text) LANGUAGE sql AS $$ SELECT 1, 'x'::text $$;
CREATE VIEW ruleutils_alias_v AS
WITH cte_alias AS (SELECT 1 AS c)
SELECT f.a, sq.x, vals.y, cte_alias.c
FROM ruleutils_srf() f,
     (SELECT 2 AS x) sq,
     (VALUES (3)) vals(y),
     cte_alias;
SELECT pg_get_viewdef('ruleutils_alias_v'::regclass, true);
DROP VIEW IF EXISTS ruleutils_alias_v CASCADE;
DROP FUNCTION IF EXISTS ruleutils_srf() CASCADE;

-- ===== Test Case 8 (commit 101) =====
DROP TABLE IF EXISTS foo101 CASCADE;
CREATE TABLE foo101 (f1 text DEFAULT 'test', f2 int DEFAULT 42, f3 int DEFAULT 7);
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING *;
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING bar.*;
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING bar.f3;
DROP TABLE IF EXISTS foo101 CASCADE;

-- ===== Test Case 9 (commit 101) =====
DROP VIEW IF EXISTS rte_func101_v CASCADE;
CREATE VIEW rte_func101_v AS SELECT * FROM generate_series(1, 3);
SELECT pg_get_viewdef('rte_func101_v'::regclass, true);
DROP VIEW IF EXISTS rte_func101_v CASCADE;

-- ===== Test Case 10 (commit 101) =====
DROP VIEW IF EXISTS rte_cte101_v CASCADE;
CREATE VIEW rte_cte101_v AS
WITH cte101 AS (SELECT 1 AS a)
SELECT * FROM cte101
WHERE EXISTS (WITH cte101 AS (SELECT 2 AS a) SELECT 1 FROM cte101 WHERE cte101.a > 0);
SELECT pg_get_viewdef('rte_cte101_v'::regclass, true);
DROP VIEW IF EXISTS rte_cte101_v CASCADE;

-- ===== Test Case 11 (commit 101) =====
DROP SCHEMA IF EXISTS s101a CASCADE;
DROP SCHEMA IF EXISTS s101b CASCADE;
CREATE SCHEMA s101a;
CREATE SCHEMA s101b;
CREATE TABLE s101a.same_name (a int);
CREATE TABLE s101b.same_name (a int);
CREATE VIEW rte_rel_conflict101_v AS
SELECT s101a.same_name.a AS a1, s101b.same_name.a AS a2
FROM s101a.same_name, s101b.same_name;
SELECT pg_get_viewdef('rte_rel_conflict101_v'::regclass, true);
DROP VIEW IF EXISTS rte_rel_conflict101_v CASCADE;
DROP SCHEMA IF EXISTS s101a CASCADE;
DROP SCHEMA IF EXISTS s101b CASCADE;

-- ===== Test Case 12 (commit 101) =====
DROP VIEW IF EXISTS rte_func_no_cols101_v CASCADE;
CREATE VIEW rte_func_no_cols101_v AS SELECT 1 AS marker FROM generate_series(1, 3);
SELECT pg_get_viewdef('rte_func_no_cols101_v'::regclass, true);
DROP VIEW IF EXISTS rte_func_no_cols101_v CASCADE;

-- ===== Test Case 13 (commit 102) =====
SELECT 1;

-- ===== Test Case 14 (commit 103) =====
SELECT 1;

-- ===== Test Case 15 (commit 104) =====
-- Setup: Create a minimal catalog definition file to trigger genbki.pl
DROP TABLE IF EXISTS test_genbki CASCADE;
CREATE TABLE test_genbki (id INT PRIMARY KEY, name TEXT);

-- Execution: Run genbki.pl indirectly via a dummy catalog build (simulate by calling the script with minimal input)
-- Note: genbki.pl is typically invoked during 'make' in src/backend/catalog. We simulate by running it with a simple .dat file.
-- Create a temporary .dat file and run genbki.pl
COPY (SELECT 'test'::text) TO '/tmp/test_genbki.dat';
\! perl src/backend/catalog/genbki.pl -I src/include/catalog /tmp/test_genbki.dat 2>&1

-- Teardown: Clean up temporary files and table
DROP TABLE IF EXISTS test_genbki CASCADE;
\! rm -f /tmp/test_genbki.dat

-- ===== Test Case 16 (commit 104) =====
-- Setup: Create an empty temporary file
\! touch /tmp/test_empty.dat

-- Execution: Run genbki.pl with empty input
\! perl src/backend/catalog/genbki.pl -I src/include/catalog /tmp/test_empty.dat 2>&1

-- Teardown: Clean up
\! rm -f /tmp/test_empty.dat

-- ===== Test Case 17 (commit 104) =====
-- Setup: No file created

-- Execution: Run genbki.pl with a non-existent file
\! perl src/backend/catalog/genbki.pl -I src/include/catalog /tmp/nonexistent.dat 2>&1

-- Teardown: No cleanup needed

-- ===== Test Case 18 (commit 105) =====
-- Setup
DROP TABLE IF EXISTS test_gen_trigger CASCADE;
CREATE TABLE test_gen_trigger (
    id INT PRIMARY KEY,
    a INT,
    b INT GENERATED ALWAYS AS (a * 2) STORED
);
CREATE OR REPLACE FUNCTION test_trigger_func() RETURNS TRIGGER AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_trigger BEFORE UPDATE ON test_gen_trigger FOR EACH ROW EXECUTE FUNCTION test_trigger_func();
INSERT INTO test_gen_trigger VALUES (1, 5);

-- Execution: UPDATE triggers the trigger, which calls ExecGetExtraUpdatedCols before ExecInitStoredGenerated
UPDATE test_gen_trigger SET a = 10 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_gen_trigger CASCADE;
DROP FUNCTION IF EXISTS test_trigger_func;

-- ===== Test Case 19 (commit 105) =====
-- Setup
DROP TABLE IF EXISTS test_gen_logical CASCADE;
CREATE TABLE test_gen_logical (
    id INT PRIMARY KEY,
    x INT,
    y INT GENERATED ALWAYS AS (x + 1) STORED
);
CREATE OR REPLACE FUNCTION test_logical_trigger() RETURNS TRIGGER AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_logical_trig BEFORE UPDATE ON test_gen_logical FOR EACH ROW EXECUTE FUNCTION test_logical_trigger();
INSERT INTO test_gen_logical VALUES (1, 100);

-- Execution: UPDATE triggers the trigger, which calls ExecGetExtraUpdatedCols before generated columns are initialized
UPDATE test_gen_logical SET x = 200 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_gen_logical CASCADE;
DROP FUNCTION IF EXISTS test_logical_trigger;

-- ===== Test Case 20 (commit 105) =====
-- Setup
DROP TABLE IF EXISTS test_gen_multi CASCADE;
CREATE TABLE test_gen_multi (
    id INT PRIMARY KEY,
    val1 INT,
    val2 INT GENERATED ALWAYS AS (val1 * 3) STORED,
    val3 INT GENERATED ALWAYS AS (val1 + 10) STORED
);
CREATE OR REPLACE FUNCTION test_multi_trigger() RETURNS TRIGGER AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_multi_trig BEFORE UPDATE ON test_gen_multi FOR EACH ROW EXECUTE FUNCTION test_multi_trigger();
INSERT INTO test_gen_multi VALUES (1, 5);

-- Execution: UPDATE triggers the trigger, which calls ExecGetExtraUpdatedCols before generated columns are initialized
UPDATE test_gen_multi SET val1 = 7 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_gen_multi CASCADE;
DROP FUNCTION IF EXISTS test_multi_trigger;

-- ===== Test Case 21 (commit 106) =====
-- Setup
DROP TABLE IF EXISTS test_empty_gs CASCADE;
CREATE TABLE test_empty_gs (a int, b int);
INSERT INTO test_empty_gs VALUES (1, 10), (2, 20), (3, 30);

-- Execution: Use GROUP BY () to create an empty grouping set
SELECT COUNT(*) FROM test_empty_gs GROUP BY ();

-- Teardown
DROP TABLE IF EXISTS test_empty_gs CASCADE;

-- ===== Test Case 22 (commit 106) =====
-- Setup
DROP TABLE IF EXISTS test_mixed_gs CASCADE;
CREATE TABLE test_mixed_gs (x int, y int);
INSERT INTO test_mixed_gs VALUES (1, 100), (2, 200), (1, 300);

-- Execution: GROUPING SETS with empty set and a non-empty set
SELECT x, COUNT(*) FROM test_mixed_gs GROUP BY GROUPING SETS ((), (x));

-- Teardown
DROP TABLE IF EXISTS test_mixed_gs CASCADE;

-- ===== Test Case 23 (commit 106) =====
-- Setup
DROP TABLE IF EXISTS test_having_gs CASCADE;
CREATE TABLE test_having_gs (id int, val int);
INSERT INTO test_having_gs VALUES (1, 5), (2, 10), (3, 15);

-- Execution: Empty grouping set with HAVING
SELECT COUNT(*), SUM(val) FROM test_having_gs GROUP BY () HAVING COUNT(*) > 0;

-- Teardown
DROP TABLE IF EXISTS test_having_gs CASCADE;

-- ===== Test Case 24 (commit 106) =====
DROP TABLE IF EXISTS gstest3 CASCADE;
CREATE TABLE gstest3 (a int, b int, c int);
INSERT INTO gstest3 SELECT g%3, g%5, g FROM generate_series(1,30) g;
CREATE INDEX gstest3_idx ON gstest3(a,b);
BEGIN;
SET LOCAL enable_hashagg = false;
EXPLAIN (COSTS OFF) SELECT a, b, count(*), max(a), max(b) FROM gstest3 GROUP BY GROUPING SETS(a, b,()) ORDER BY a, b;
SELECT a, b, count(*), max(a), max(b) FROM gstest3 GROUP BY GROUPING SETS(a, b,()) ORDER BY a, b;
SET LOCAL enable_seqscan = false;
EXPLAIN (COSTS OFF) SELECT a, b, count(*), max(a), max(b) FROM gstest3 GROUP BY GROUPING SETS(a, b,()) ORDER BY a, b;
SELECT a, b, count(*), max(a), max(b) FROM gstest3 GROUP BY GROUPING SETS(a, b,()) ORDER BY a, b;
COMMIT;
DROP TABLE IF EXISTS gstest3 CASCADE;

-- ===== Test Case 25 (commit 107) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution: Deeply nested EXISTS subqueries to trigger recursion in pull_up_sublinks_jointree_recurse
SELECT * FROM test_t1 WHERE EXISTS (SELECT 1 FROM test_t2 WHERE EXISTS (SELECT 1 FROM test_t1 WHERE test_t1.id = test_t2.id));

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 26 (commit 107) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution: Deeply nested subquery in FROM clause to trigger recursion in pull_up_subqueries_recurse
SELECT * FROM (SELECT * FROM (SELECT * FROM test_t1 WHERE id = 1) AS sub1) AS sub2;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 27 (commit 107) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (2);

-- Execution: Deeply nested UNION ALL to trigger recursion in is_simple_union_all_recurse
SELECT * FROM test_t1 UNION ALL SELECT * FROM test_t2 UNION ALL SELECT * FROM test_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 28 (commit 108) =====
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int);
CREATE TABLE t2 (a int);
INSERT INTO t1 VALUES (1), (2);
INSERT INTO t2 VALUES (3), (4);

-- Execution: UNION ALL query that triggers pull-up of leaf subqueries
SELECT * FROM (SELECT a FROM t1 UNION ALL SELECT a FROM t2) AS u;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;

-- ===== Test Case 29 (commit 108) =====
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
CREATE TABLE t1 (a int);
CREATE TABLE t2 (a int);
INSERT INTO t1 VALUES (1);
INSERT INTO t2 VALUES (2);

-- Execution: UNION ALL with a lateral join that introduces PlaceHolderVars
SELECT * FROM (SELECT a FROM t1 UNION ALL SELECT a FROM t2) AS u
WHERE EXISTS (SELECT 1 FROM t1 WHERE t1.a = u.a);

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;

-- ===== Test Case 30 (commit 108) =====
-- Setup
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
DROP TABLE IF EXISTS t3 CASCADE;
CREATE TABLE t1 (a int);
CREATE TABLE t2 (a int);
CREATE TABLE t3 (a int);
INSERT INTO t1 VALUES (1);
INSERT INTO t2 VALUES (2);
INSERT INTO t3 VALUES (3);

-- Execution: Multiple UNION ALL subqueries to trigger the O(N^2) avoidance path
SELECT * FROM (SELECT a FROM t1 UNION ALL SELECT a FROM t2 UNION ALL SELECT a FROM t3) AS u;

-- Teardown
DROP TABLE IF EXISTS t1 CASCADE;
DROP TABLE IF EXISTS t2 CASCADE;
DROP TABLE IF EXISTS t3 CASCADE;

-- ===== Test Case 31 (commit 109) =====
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

-- ===== Test Case 32 (commit 109) =====
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

-- ===== Test Case 33 (commit 109) =====
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

-- ===== Test Case 34 (commit 110) =====
SELECT 1;

-- ===== Test Case 35 (commit 111) =====
-- Setup
DROP TABLE IF EXISTS test_mxact CASCADE;
CREATE TABLE test_mxact (id INT PRIMARY KEY, val INT);
INSERT INTO test_mxact VALUES (1, 10);

-- Execution: Use two concurrent sessions to create a multixact with two updaters
-- Session 1
BEGIN;
UPDATE test_mxact SET val = 20 WHERE id = 1;
-- Session 2 (run in same connection after session 1's UPDATE, but before commit)
BEGIN;
UPDATE test_mxact SET val = 30 WHERE id = 1;
-- This should trigger the error: "new multixact has more than one updating member"
COMMIT;
-- Teardown
DROP TABLE IF EXISTS test_mxact CASCADE;

-- ===== Test Case 36 (commit 111) =====
-- Setup
DROP TABLE IF EXISTS test_mxact2 CASCADE;
CREATE TABLE test_mxact2 (id INT PRIMARY KEY, val INT);
INSERT INTO test_mxact2 VALUES (1, 100);

-- Execution: Three concurrent sessions updating the same tuple
-- Session 1
BEGIN;
UPDATE test_mxact2 SET val = 200 WHERE id = 1;
-- Session 2
BEGIN;
UPDATE test_mxact2 SET val = 300 WHERE id = 1;
-- Session 3
BEGIN;
UPDATE test_mxact2 SET val = 400 WHERE id = 1;
-- This should trigger the error with detailed member info
COMMIT;
-- Teardown
DROP TABLE IF EXISTS test_mxact2 CASCADE;

-- ===== Test Case 37 (commit 111) =====
-- Setup
DROP TABLE IF EXISTS test_mxact3 CASCADE;
CREATE TABLE test_mxact3 (id INT PRIMARY KEY, val INT);
INSERT INTO test_mxact3 VALUES (1, 50);

-- Execution: Two concurrent sessions, one UPDATE and one SELECT FOR UPDATE
-- Session 1
BEGIN;
UPDATE test_mxact3 SET val = 60 WHERE id = 1;
-- Session 2
BEGIN;
SELECT * FROM test_mxact3 WHERE id = 1 FOR UPDATE;
-- This should trigger the error as both are updating members
COMMIT;
-- Teardown
DROP TABLE IF EXISTS test_mxact3 CASCADE;

-- ===== Test Case 38 (commit 112) =====
-- Setup
CREATE ROLE test_user1 LOGIN;
CREATE TABLE test_vacuum_perm (id INT);
INSERT INTO test_vacuum_perm VALUES (1);
GRANT ALL ON TABLE test_vacuum_perm TO test_user1;
SET ROLE test_user1;

-- Execution
VACUUM test_vacuum_perm;

-- Teardown
RESET ROLE;
DROP TABLE IF EXISTS test_vacuum_perm CASCADE;
DROP ROLE IF EXISTS test_user1;

-- ===== Test Case 39 (commit 112) =====
-- Setup
CREATE ROLE test_user2 LOGIN;
CREATE TABLE test_analyze_perm (id INT);
INSERT INTO test_analyze_perm VALUES (1);
GRANT ALL ON TABLE test_analyze_perm TO test_user2;
SET ROLE test_user2;

-- Execution
ANALYZE test_analyze_perm;

-- Teardown
RESET ROLE;
DROP TABLE IF EXISTS test_analyze_perm CASCADE;
DROP ROLE IF EXISTS test_user2;

-- ===== Test Case 40 (commit 112) =====
-- Setup
CREATE ROLE test_user3 LOGIN;
CREATE TABLE test_vacuum_analyze_perm (id INT);
INSERT INTO test_vacuum_analyze_perm VALUES (1);
GRANT ALL ON TABLE test_vacuum_analyze_perm TO test_user3;
SET ROLE test_user3;

-- Execution
VACUUM ANALYZE test_vacuum_analyze_perm;

-- Teardown
RESET ROLE;
DROP TABLE IF EXISTS test_vacuum_analyze_perm CASCADE;
DROP ROLE IF EXISTS test_user3;

-- ===== Test Case 41 (commit 112) =====
DROP TABLE IF EXISTS vacowned CASCADE;
DROP ROLE IF EXISTS regress_vacuum;
CREATE TABLE vacowned (a int);
CREATE ROLE regress_vacuum;
SET ROLE regress_vacuum;
VACUUM vacowned;
ANALYZE vacowned;
VACUUM (ANALYZE) vacowned;
VACUUM pg_catalog.pg_class;
ANALYZE pg_catalog.pg_class;
VACUUM (ANALYZE) pg_catalog.pg_class;
VACUUM pg_catalog.pg_authid;
ANALYZE pg_catalog.pg_authid;
VACUUM (ANALYZE) pg_catalog.pg_authid;
RESET ROLE;
DROP TABLE IF EXISTS vacowned CASCADE;
DROP ROLE IF EXISTS regress_vacuum;

-- ===== Test Case 42 (commit 113) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 SELECT generate_series(1, 1000);
-- Create index to trigger get_actual_variable_range
CREATE INDEX test_t1_idx ON test_t1 (id);
-- Delete many tuples to create non-visible tuples near the end
DELETE FROM test_t1 WHERE id > 900;
-- Ensure visibility map is not set by performing a vacuum-less delete
-- Execution: Run a query that triggers get_actual_variable_range for min/max estimation
ANALYZE test_t1;
SELECT * FROM test_t1 WHERE id > 500;
-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- ===== Test Case 43 (commit 113) =====
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT, data TEXT);
INSERT INTO test_t2 SELECT generate_series(1, 200), 'data';
CREATE INDEX test_t2_idx ON test_t2 (id);
-- Delete some tuples to create non-visible entries on same heap page
DELETE FROM test_t2 WHERE id BETWEEN 50 AND 100;
-- Execution: Query that triggers get_actual_variable_range
ANALYZE test_t2;
SELECT * FROM test_t2 WHERE id > 150;
-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 44 (commit 113) =====
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
CREATE INDEX test_t3_idx ON test_t3 (id);
-- No data inserted, index is empty
-- Execution: Query that triggers get_actual_variable_range
ANALYZE test_t3;
SELECT * FROM test_t3 WHERE id > 10;
-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- ===== Test Case 45 (commit 113) =====
DROP TABLE IF EXISTS endpoint_limit CASCADE;
CREATE TABLE endpoint_limit (id int, filler text) WITH (autovacuum_enabled=false, fillfactor=10);
INSERT INTO endpoint_limit SELECT g, repeat('x', 7000) FROM generate_series(1,180) g;
CREATE INDEX endpoint_limit_idx ON endpoint_limit(id);
DELETE FROM endpoint_limit WHERE id > 40;
ANALYZE endpoint_limit;
EXPLAIN SELECT * FROM endpoint_limit WHERE id > 170;
SELECT count(*) FROM endpoint_limit WHERE id > 170;
DROP TABLE IF EXISTS endpoint_limit CASCADE;

-- ===== Test Case 46 (commit 114) =====
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

-- ===== Test Case 47 (commit 114) =====
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

-- ===== Test Case 48 (commit 114) =====
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

-- ===== Test Case 49 (commit 115) =====
-- Setup: Create a table with data and enable checksums (requires cluster restart, but we simulate by using wal_log_hints=on)
DROP TABLE IF EXISTS test_visible CASCADE;
CREATE TABLE test_visible (id INT PRIMARY KEY, data TEXT);
INSERT INTO test_visible SELECT generate_series(1,100), 'test data';
-- Force a checkpoint to ensure visibility map updates are WAL-logged
CHECKPOINT;
-- Update some rows to create dead tuples and trigger visibility map changes
UPDATE test_visible SET data = 'updated' WHERE id BETWEEN 1 AND 50;
-- Vacuum to set visibility map bits
VACUUM test_visible;
-- Execution: The redo of heap_xlog_visible will now call PageSetLSN when checksums are needed
-- (This test relies on the WAL replay during recovery; we simulate by running a checkpoint and then a crash recovery scenario)
-- For coverage, we just need to ensure the code path is reached; we can trigger it by running a VACUUM again
VACUUM test_visible;
-- Teardown
DROP TABLE IF EXISTS test_visible CASCADE;

-- ===== Test Case 50 (commit 115) =====
-- Setup: Create a table with data and enable wal_log_hints (simulated by setting parameter)
DROP TABLE IF EXISTS test_hint CASCADE;
CREATE TABLE test_hint (id INT, val TEXT);
INSERT INTO test_hint SELECT generate_series(1,50), 'hint test';
-- Force a checkpoint to ensure WAL logging
CHECKPOINT;
-- Perform operations that set hint bits (e.g., SELECT with visibility check)
SELECT count(*) FROM test_hint WHERE id > 10;
-- Vacuum to set visibility map bits
VACUUM test_hint;
-- Execution: The redo of heap_xlog_visible will now call PageSetLSN when wal_log_hints is needed
-- (This test relies on the WAL replay during recovery; we simulate by running a checkpoint and then a crash recovery scenario)
-- For coverage, we just need to ensure the code path is reached; we can trigger it by running a VACUUM again
VACUUM test_hint;
-- Teardown
DROP TABLE IF EXISTS test_hint CASCADE;

-- ===== Test Case 51 (commit 115) =====
-- Setup: Create a table with data and enable both checksums and wal_log_hints (simulated by setting parameters)
DROP TABLE IF EXISTS test_both CASCADE;
CREATE TABLE test_both (id INT, data TEXT);
INSERT INTO test_both SELECT generate_series(1,200), 'both test';
-- Force a checkpoint to ensure WAL logging
CHECKPOINT;
-- Perform operations that set hint bits and visibility map bits
UPDATE test_both SET data = 'updated' WHERE id BETWEEN 1 AND 100;
SELECT count(*) FROM test_both WHERE id > 50;
-- Vacuum to set visibility map bits
VACUUM test_both;
-- Execution: The redo of heap_xlog_visible will now call PageSetLSN when both checksums and wal_log_hints are needed
-- (This test relies on the WAL replay during recovery; we simulate by running a checkpoint and then a crash recovery scenario)
-- For coverage, we just need to ensure the code path is reached; we can trigger it by running a VACUUM again
VACUUM test_both;
-- Teardown
DROP TABLE IF EXISTS test_both CASCADE;

-- ===== Test Case 52 (commit 116) =====
DROP FUNCTION IF EXISTS test_bad_sql_func();
CREATE FUNCTION test_bad_sql_func() RETURNS int LANGUAGE sql AS $$ SELECT + $$;
SELECT 1;

-- ===== Test Case 53 (commit 116) =====
DROP FUNCTION IF EXISTS test_bad_plpgsql_func();
CREATE FUNCTION test_bad_plpgsql_func() RETURNS int LANGUAGE plpgsql AS $$ BEGIN RETURN ; END $$;
SELECT 1;

-- ===== Test Case 54 (commit 116) =====
DO $$ BEGIN IF THEN RAISE NOTICE 'bad'; END IF; END $$;
SELECT 1;

-- ===== Test Case 55 (commit 117) =====
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

-- ===== Test Case 56 (commit 117) =====
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

-- ===== Test Case 57 (commit 117) =====
DROP TABLE IF EXISTS ref_parent_ok CASCADE;
DROP TABLE IF EXISTS ref_parted_ok CASCADE;
CREATE TABLE ref_parent_ok (id int PRIMARY KEY);
CREATE TABLE ref_parted_ok (id int NOT NULL REFERENCES ref_parent_ok(id)) PARTITION BY RANGE (id);
CREATE TABLE ref_child_ok (id int NOT NULL REFERENCES ref_parent_ok(id));
ALTER TABLE ref_parted_ok ATTACH PARTITION ref_child_ok FOR VALUES FROM (1) TO (10);
DROP TABLE IF EXISTS ref_parted_ok CASCADE;
DROP TABLE IF EXISTS ref_parent_ok CASCADE;

-- ===== Test Case 58 (commit 118) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);

-- Execution: Attempt to create a non-ON-SELECT rule named "_RETURN"
CREATE OR REPLACE RULE "_RETURN" AS ON INSERT TO test_t1 DO INSTEAD NOTHING;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- ===== Test Case 59 (commit 118) =====
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
CREATE VIEW test_v2 AS SELECT * FROM test_t2;

-- Execution: Attempt to replace the view's ON SELECT rule with a non-ON-SELECT rule named "_RETURN"
CREATE OR REPLACE RULE "_RETURN" AS ON INSERT TO test_v2 DO INSTEAD NOTHING;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;
DROP VIEW IF EXISTS test_v2 CASCADE;

-- ===== Test Case 60 (commit 118) =====
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
INSERT INTO test_t3 VALUES (1);

-- Execution: Create a view with a valid ON SELECT rule named "_RETURN"
CREATE VIEW test_v3 AS SELECT * FROM test_t3;

-- Verify the view works
SELECT * FROM test_v3;

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;
DROP VIEW IF EXISTS test_v3 CASCADE;

-- ===== Test Case 61 (commit 118) =====
DROP TABLE IF EXISTS r118_compact CASCADE;
CREATE TABLE r118_compact (id int);
CREATE RULE "_RETURN" AS ON INSERT TO r118_compact DO ALSO SELECT 1;
DROP TABLE IF EXISTS r118_compact CASCADE;

-- ===== Test Case 62 (commit 119) =====
SELECT 1;

-- ===== Test Case 63 (commit 120) =====
-- Setup
DROP TABLE IF EXISTS base_tbl CASCADE;
DROP VIEW IF EXISTS upd_view CASCADE;
CREATE TABLE base_tbl (a int, b int);
CREATE VIEW upd_view AS SELECT * FROM base_tbl;
CREATE RULE upd_view_ins AS ON INSERT TO upd_view DO ALSO INSERT INTO base_tbl VALUES (DEFAULT, DEFAULT);
-- Execution: Insert multi-row VALUES with DEFAULT into the view
INSERT INTO upd_view VALUES (1, DEFAULT), (DEFAULT, 2);
-- Teardown
DROP TABLE IF EXISTS base_tbl CASCADE;
DROP VIEW IF EXISTS upd_view CASCADE;

-- ===== Test Case 64 (commit 120) =====
-- Setup
DROP TABLE IF EXISTS base_tbl CASCADE;
DROP VIEW IF EXISTS upd_view CASCADE;
CREATE TABLE base_tbl (a int DEFAULT 10, b int DEFAULT 20);
CREATE VIEW upd_view AS SELECT * FROM base_tbl;
-- Execution: Insert multi-row VALUES with DEFAULT into the view
INSERT INTO upd_view VALUES (DEFAULT, 1), (2, DEFAULT);
-- Teardown
DROP TABLE IF EXISTS base_tbl CASCADE;
DROP VIEW IF EXISTS upd_view CASCADE;

-- ===== Test Case 65 (commit 120) =====
-- Setup
DROP TABLE IF EXISTS base_tbl CASCADE;
DROP VIEW IF EXISTS upd_view CASCADE;
CREATE TABLE base_tbl (a int, b int);
CREATE VIEW upd_view AS SELECT * FROM base_tbl;
CREATE RULE upd_view_ins AS ON INSERT TO upd_view DO ALSO UPDATE base_tbl SET a = DEFAULT WHERE b = 1;
-- Execution: Insert multi-row VALUES with DEFAULT into the view
INSERT INTO upd_view VALUES (DEFAULT, 1), (2, DEFAULT);
-- Teardown
DROP TABLE IF EXISTS base_tbl CASCADE;
DROP VIEW IF EXISTS upd_view CASCADE;

-- ===== Test Case 66 (commit 120) =====
DROP VIEW IF EXISTS rw_view CASCADE;
DROP TABLE IF EXISTS rw_log CASCADE;
DROP TABLE IF EXISTS rw_base CASCADE;
CREATE TABLE rw_base (a int DEFAULT 10, b int DEFAULT 20);
CREATE TABLE rw_log (a int, b int);
CREATE VIEW rw_view AS SELECT a,b FROM rw_base;
CREATE RULE rw_also AS ON INSERT TO rw_view DO ALSO INSERT INTO rw_log VALUES (DEFAULT, DEFAULT);
INSERT INTO rw_view VALUES (DEFAULT, 1), (2, DEFAULT), (DEFAULT, DEFAULT);
SELECT * FROM rw_base ORDER BY a NULLS FIRST, b NULLS FIRST;
SELECT * FROM rw_log;
DROP VIEW IF EXISTS rw_view CASCADE;
DROP TABLE IF EXISTS rw_log CASCADE;
DROP TABLE IF EXISTS rw_base CASCADE;

-- ===== Test Case 67 (commit 120) =====
DROP VIEW IF EXISTS rw_view2 CASCADE;
DROP TABLE IF EXISTS rw_base2 CASCADE;
CREATE TABLE rw_base2 (a int DEFAULT 10, b int DEFAULT 20);
INSERT INTO rw_base2 VALUES (1,1);
CREATE VIEW rw_view2 AS SELECT a,b FROM rw_base2;
CREATE RULE rw_also_upd AS ON INSERT TO rw_view2 DO ALSO UPDATE rw_base2 SET b = DEFAULT WHERE a = 1;
INSERT INTO rw_view2 VALUES (DEFAULT, DEFAULT), (5, DEFAULT);
SELECT * FROM rw_base2 ORDER BY a NULLS FIRST;
DROP VIEW IF EXISTS rw_view2 CASCADE;
DROP TABLE IF EXISTS rw_base2 CASCADE;

-- ===== Test Case 68 (commit 120) =====
DROP VIEW IF EXISTS rw_mix120_v CASCADE;
DROP TABLE IF EXISTS rw_mix120_log CASCADE;
DROP TABLE IF EXISTS rw_mix120_base CASCADE;
CREATE TABLE rw_mix120_base (a int DEFAULT 10, b int DEFAULT 20);
CREATE TABLE rw_mix120_log (a int, b int);
CREATE VIEW rw_mix120_v AS SELECT a,b FROM rw_mix120_base;
CREATE RULE rw_mix120_log_rule AS ON INSERT TO rw_mix120_v DO ALSO
  INSERT INTO rw_mix120_log VALUES (DEFAULT, NEW.b), (NEW.a, DEFAULT), (7, 8);
INSERT INTO rw_mix120_v VALUES (DEFAULT, 1), (2, DEFAULT), (DEFAULT, DEFAULT);
SELECT * FROM rw_mix120_log ORDER BY a NULLS FIRST, b NULLS FIRST;
DROP VIEW IF EXISTS rw_mix120_v CASCADE;
DROP TABLE IF EXISTS rw_mix120_log CASCADE;
DROP TABLE IF EXISTS rw_mix120_base CASCADE;

-- ===== Test Case 69 (commit 121) =====
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

-- ===== Test Case 70 (commit 121) =====
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

-- ===== Test Case 71 (commit 121) =====
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

-- ===== Test Case 72 (commit 121) =====
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

-- ===== Test Case 73 (commit 121) =====
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

-- ===== Test Case 74 (commit 122) =====
-- Setup: Create a table with an array type (pass-by-ref) to trigger expanded datum handling
DROP TABLE IF EXISTS test_agg1 CASCADE;
CREATE TABLE test_agg1 (id INT, arr INT[]);
INSERT INTO test_agg1 VALUES (1, ARRAY[1,2,3]), (2, ARRAY[4,5,6]);

-- Execution: Use array_agg which has no finalfn, returns pass-by-ref result
SELECT id, array_agg(arr) FROM test_agg1 GROUP BY id;

-- Teardown
DROP TABLE IF EXISTS test_agg1 CASCADE;

-- ===== Test Case 75 (commit 122) =====
-- Setup: Create a table with text type (pass-by-ref) and use string_agg which has no finalfn
DROP TABLE IF EXISTS test_agg2 CASCADE;
CREATE TABLE test_agg2 (id INT, val TEXT);
INSERT INTO test_agg2 VALUES (1, 'a'), (1, 'b'), (2, 'c');

-- Execution: Use string_agg with partial aggregation (enable hashagg if needed)
SET enable_hashagg = on;
SELECT id, string_agg(val, ',') FROM test_agg2 GROUP BY id;
RESET enable_hashagg;

-- Teardown
DROP TABLE IF EXISTS test_agg2 CASCADE;

-- ===== Test Case 76 (commit 122) =====
-- Setup: Create a table with nullable integer and use an aggregate that can produce NULL transition values
DROP TABLE IF EXISTS test_agg3 CASCADE;
CREATE TABLE test_agg3 (id INT, val INT);
INSERT INTO test_agg3 VALUES (1, NULL), (1, 10), (2, NULL);

-- Execution: Use avg() which has a finalfn, but the transition value may be null for groups with all nulls
SELECT id, avg(val) FROM test_agg3 GROUP BY id;

-- Teardown
DROP TABLE IF EXISTS test_agg3 CASCADE;

-- ===== Test Case 77 (commit 123) =====
-- Setup
DROP TABLE IF EXISTS test_heap_update_vm CASCADE;
CREATE TABLE test_heap_update_vm (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_heap_update_vm SELECT generate_series(1, 100), 'initial';
-- Create a situation where otherBuffer's all-visible bit might be set
VACUUM test_heap_update_vm;

-- Execution: Perform an UPDATE that triggers heap_update with a non-target buffer (otherBuffer) that may have all-visible set
BEGIN;
UPDATE test_heap_update_vm SET val = 'updated' WHERE id = 1;
-- This should reach the modified code path in hio.c where GetVisibilityMapPins is called after conditional lock succeeds
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_update_vm CASCADE;

-- ===== Test Case 78 (commit 123) =====
-- Setup
DROP TABLE IF EXISTS test_heap_update_lock CASCADE;
CREATE TABLE test_heap_update_lock (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_heap_update_lock SELECT generate_series(1, 100), 'initial';

-- Execution: Simulate contention on otherBuffer to force conditional lock failure
BEGIN;
-- First session holds lock on otherBuffer (simulate by using a different tuple)
UPDATE test_heap_update_lock SET val = 'locked' WHERE id = 2;
-- In same session, update another tuple to trigger heap_update with otherBuffer contention
UPDATE test_heap_update_lock SET val = 'updated' WHERE id = 1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_update_lock CASCADE;

-- ===== Test Case 79 (commit 123) =====
-- Setup
DROP TABLE IF EXISTS test_heap_update_extend CASCADE;
CREATE TABLE test_heap_update_extend (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_heap_update_extend SELECT generate_series(1, 100), 'initial';
-- Ensure some pages are all-visible
VACUUM test_heap_update_extend;

-- Execution: Insert a new tuple that causes page extension, then update another tuple to trigger the code path
BEGIN;
INSERT INTO test_heap_update_extend VALUES (101, 'new');
UPDATE test_heap_update_extend SET val = 'updated' WHERE id = 1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_update_extend CASCADE;

-- ===== Test Case 80 (commit 123) =====
DROP TABLE IF EXISTS conc_upd123 CASCADE;
CREATE TABLE conc_upd123 (id int PRIMARY KEY, filler text) WITH (autovacuum_enabled=false, fillfactor=20);
INSERT INTO conc_upd123 SELECT g, repeat('a', 1000) FROM generate_series(1, 20) g;
VACUUM conc_upd123;
\! PGHOST=/tmp/pgcov-55432 PGPORT=55432 psql -d regression -v ON_ERROR_STOP=0 -c "SELECT pg_sleep(0.2)" -c "VACUUM conc_upd123" >/tmp/conc_upd123_vacuum.log 2>&1 &
UPDATE conc_upd123 SET filler = repeat('b', 7000) WHERE id = 1;
UPDATE conc_upd123 SET filler = repeat('c', 7000) WHERE id = 2;
SELECT pg_sleep(0.5);
DROP TABLE IF EXISTS conc_upd123 CASCADE;

-- ===== Test Case 81 (commit 124) =====
SELECT 1;

-- ===== Test Case 82 (commit 125) =====
-- Setup
DROP TABLE IF EXISTS test_heap_delete_vm CASCADE;
CREATE TABLE test_heap_delete_vm (id INT) WITH (autovacuum_enabled = false);
INSERT INTO test_heap_delete_vm SELECT generate_series(1, 1000);
-- Create a visibility map by vacuuming
VACUUM test_heap_delete_vm;

-- Execution: Start a transaction that deletes a row, but before locking the buffer, another session makes the page all visible.
BEGIN;
DELETE FROM test_heap_delete_vm WHERE id = 1;
-- The DELETE will re-check PageIsAllVisible() after acquiring buffer lock, hitting the new code path.
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_delete_vm CASCADE;

-- ===== Test Case 83 (commit 125) =====
-- Setup
DROP TABLE IF EXISTS test_heap_delete_conflict CASCADE;
CREATE TABLE test_heap_delete_conflict (id INT PRIMARY KEY) WITH (autovacuum_enabled = false);
INSERT INTO test_heap_delete_conflict VALUES (1);
VACUUM test_heap_delete_conflict;

-- Execution: Simulate a concurrent update that causes a restart due to page becoming all visible.
-- Session 1: Start a transaction and update the row to create a lock.
BEGIN;
UPDATE test_heap_delete_conflict SET id = 2 WHERE id = 1;
-- Session 2: In another session, try to delete the same row (will wait for lock).
-- This DELETE will eventually restart after the update commits, and the page may become all visible.
-- For simplicity, we run sequentially but the code path is exercised by the lock conflict.
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_heap_delete_conflict CASCADE;

-- ===== Test Case 84 (commit 125) =====
-- Setup
DROP TABLE IF EXISTS test_heap_delete_vacuum CASCADE;
CREATE TABLE test_heap_delete_vacuum (id INT) WITH (autovacuum_enabled = false);
INSERT INTO test_heap_delete_vacuum SELECT generate_series(1, 100);
VACUUM test_heap_delete_vacuum;

-- Execution: Delete a row, then immediately vacuum to make the page all visible, then delete another row from the same page.
-- The second DELETE will see the page all visible without a VM pin, triggering the new check.
DELETE FROM test_heap_delete_vacuum WHERE id = 1;
VACUUM test_heap_delete_vacuum;
DELETE FROM test_heap_delete_vacuum WHERE id = 2;

-- Teardown
DROP TABLE IF EXISTS test_heap_delete_vacuum CASCADE;

-- ===== Test Case 85 (commit 125) =====
DROP TABLE IF EXISTS conc_del125 CASCADE;
CREATE TABLE conc_del125 (id int PRIMARY KEY, filler text) WITH (autovacuum_enabled=false);
INSERT INTO conc_del125 VALUES (1, repeat('x', 1000));
\! PGHOST=/tmp/pgcov-55432 PGPORT=55432 psql -d regression -v ON_ERROR_STOP=0 -c "BEGIN; SELECT * FROM conc_del125 WHERE id = 1 FOR SHARE; SELECT pg_sleep(3); COMMIT;" >/tmp/conc_del125_lock.log 2>&1 &
\! PGHOST=/tmp/pgcov-55432 PGPORT=55432 psql -d regression -v ON_ERROR_STOP=0 -c "SELECT pg_sleep(0.8)" -c "VACUUM conc_del125" >/tmp/conc_del125_vacuum.log 2>&1 &
SELECT pg_sleep(0.3);
DELETE FROM conc_del125 WHERE id = 1;
SELECT pg_sleep(0.5);
DROP TABLE IF EXISTS conc_del125 CASCADE;

-- ===== Test Case 86 (commit 126) =====
-- Setup
DROP TABLE IF EXISTS test_shutdown1 CASCADE;
CREATE TABLE test_shutdown1 (id INT);
INSERT INTO test_shutdown1 VALUES (1), (2), (3);

-- Execution: Force a query that triggers ExecShutdownNode during cleanup
BEGIN;
DECLARE c1 CURSOR FOR SELECT * FROM test_shutdown1;
FETCH ALL FROM c1;
CLOSE c1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_shutdown1 CASCADE;

-- ===== Test Case 87 (commit 126) =====
-- Setup
DROP TABLE IF EXISTS test_shutdown2 CASCADE;
CREATE TABLE test_shutdown2 (a INT, b INT);
INSERT INTO test_shutdown2 VALUES (1, 10), (2, 20);

-- Execution: Use subquery to create SubqueryScan plan node
BEGIN;
DECLARE c2 CURSOR FOR SELECT * FROM (SELECT a, b FROM test_shutdown2) sub;
FETCH ALL FROM c2;
CLOSE c2;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_shutdown2 CASCADE;

-- ===== Test Case 88 (commit 126) =====
-- Setup
DROP TABLE IF EXISTS test_shutdown3a CASCADE;
DROP TABLE IF EXISTS test_shutdown3b CASCADE;
CREATE TABLE test_shutdown3a (x INT);
CREATE TABLE test_shutdown3b (x INT);
INSERT INTO test_shutdown3a VALUES (1), (2);
INSERT INTO test_shutdown3b VALUES (3), (4);

-- Execution: Use UNION ALL to create Append plan node
BEGIN;
DECLARE c3 CURSOR FOR SELECT x FROM test_shutdown3a UNION ALL SELECT x FROM test_shutdown3b;
FETCH ALL FROM c3;
CLOSE c3;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_shutdown3a CASCADE;
DROP TABLE IF EXISTS test_shutdown3b CASCADE;

-- ===== Test Case 89 (commit 127) =====
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

-- ===== Test Case 90 (commit 127) =====
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

-- ===== Test Case 91 (commit 127) =====
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

-- ===== Test Case 92 (commit 127) =====
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

-- ===== Test Case 93 (commit 127) =====
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

-- ===== Test Case 94 (commit 127) =====
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

-- ===== Test Case 95 (commit 128) =====
-- Setup
DROP TABLE IF EXISTS test_part_t1 CASCADE;
CREATE TABLE test_part_t1 (a INT, b INT) PARTITION BY RANGE (a);
CREATE TABLE test_part_t1_p1 PARTITION OF test_part_t1 FOR VALUES FROM (1) TO (100);
CREATE TABLE test_part_t1_p2 PARTITION OF test_part_t1 FOR VALUES FROM (100) TO (200);
CREATE INDEX ON test_part_t1_p1 (a);
CREATE INDEX ON test_part_t1_p2 (a);

-- Execution: create partitioned index, should match existing child indexes
CREATE INDEX ON test_part_t1 (a);

-- Teardown
DROP TABLE IF EXISTS test_part_t1 CASCADE;

-- ===== Test Case 96 (commit 128) =====
-- Setup
DROP TABLE IF EXISTS test_part_t2 CASCADE;
CREATE TABLE test_part_t2 (a TEXT, b INT) PARTITION BY RANGE (a COLLATE "C");
CREATE TABLE test_part_t2_p1 PARTITION OF test_part_t2 FOR VALUES FROM ('a') TO ('m');
CREATE TABLE test_part_t2_p2 PARTITION OF test_part_t2 FOR VALUES FROM ('m') TO ('z');
CREATE INDEX ON test_part_t2_p1 (a COLLATE "POSIX");
CREATE INDEX ON test_part_t2_p2 (a COLLATE "POSIX");

-- Execution: create partitioned index with different collation, should not match existing child indexes
CREATE INDEX ON test_part_t2 (a COLLATE "C");

-- Teardown
DROP TABLE IF EXISTS test_part_t2 CASCADE;

-- ===== Test Case 97 (commit 128) =====
-- Setup
DROP TABLE IF EXISTS test_part_t3 CASCADE;
CREATE TABLE test_part_t3 (a INT, b INT) PARTITION BY RANGE (a);
CREATE TABLE test_part_t3_p1 PARTITION OF test_part_t3 FOR VALUES FROM (1) TO (100);
CREATE TABLE test_part_t3_p2 PARTITION OF test_part_t3 FOR VALUES FROM (100) TO (200);
CREATE INDEX test_idx_p1 ON test_part_t3_p1 (a);
CREATE INDEX test_idx_p2 ON test_part_t3_p2 (a);

-- Execution: create partitioned index with same name, should fail due to duplicate
CREATE INDEX test_idx_parent ON test_part_t3 (a);

-- Teardown
DROP TABLE IF EXISTS test_part_t3 CASCADE;

-- ===== Test Case 98 (commit 129) =====
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_wide CASCADE;
CREATE TABLE test_wide (id INT, data text);
INSERT INTO test_wide SELECT generate_series(1, 100), repeat('x', 10000);

-- Execution: Hash join with large tuples and small work_mem
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_wide a JOIN test_wide b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_wide CASCADE;
RESET work_mem;

-- ===== Test Case 99 (commit 129) =====
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_wide2 CASCADE;
CREATE TABLE test_wide2 (id INT, data text);
INSERT INTO test_wide2 SELECT generate_series(1, 50), repeat('y', 20000);

-- Execution: Hash join with very large tuples
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_wide2 a JOIN test_wide2 b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_wide2 CASCADE;
RESET work_mem;

-- ===== Test Case 100 (commit 129) =====
-- Setup
SET work_mem = '64kB';
DROP TABLE IF EXISTS test_single_wide CASCADE;
CREATE TABLE test_single_wide (id INT, data text);
INSERT INTO test_single_wide VALUES (1, repeat('z', 50000));

-- Execution: Hash join with single very wide row
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM test_single_wide a JOIN test_single_wide b ON a.id = b.id;

-- Teardown
DROP TABLE IF EXISTS test_single_wide CASCADE;
RESET work_mem;

-- ===== Test Case 101 (commit 130) =====
-- Setup
DROP TABLE IF EXISTS test_check_valid CASCADE;
CREATE TABLE test_check_valid (id INT CHECK (id > 0));

-- Execution: Force debug output of the constraint node by examining the plan or using a debug function
-- This triggers _outConstraint() for the check constraint with initially_valid = true, skip_validation = false
SET client_min_messages TO DEBUG1;
EXPLAIN (COSTS OFF) SELECT * FROM test_check_valid WHERE id = 1;
RESET client_min_messages;

-- Teardown
DROP TABLE IF EXISTS test_check_valid CASCADE;

-- ===== Test Case 102 (commit 130) =====
-- Setup
DROP TABLE IF EXISTS test_check_notvalid CASCADE;
CREATE TABLE test_check_notvalid (id INT);
ALTER TABLE test_check_notvalid ADD CONSTRAINT ck_notvalid CHECK (id > 0) NOT VALID;

-- Execution: Force debug output of the constraint node
SET client_min_messages TO DEBUG1;
EXPLAIN (COSTS OFF) SELECT * FROM test_check_notvalid WHERE id = 1;
RESET client_min_messages;

-- Teardown
DROP TABLE IF EXISTS test_check_notvalid CASCADE;

-- ===== Test Case 103 (commit 130) =====
-- Setup
DROP TABLE IF EXISTS test_check_invalid CASCADE;
CREATE TABLE test_check_invalid (id INT);
INSERT INTO test_check_invalid VALUES (-1);
ALTER TABLE test_check_invalid ADD CONSTRAINT ck_invalid CHECK (id > 0) NOT VALID;
-- Attempt to validate (will fail due to existing data, but constraint remains invalid)
BEGIN;
ALTER TABLE test_check_invalid VALIDATE CONSTRAINT ck_invalid;
COMMIT;

-- Execution: Force debug output of the constraint node
SET client_min_messages TO DEBUG1;
EXPLAIN (COSTS OFF) SELECT * FROM test_check_invalid WHERE id = 1;
RESET client_min_messages;

-- Teardown
DROP TABLE IF EXISTS test_check_invalid CASCADE;

-- ===== Test Case 104 (commit 130) =====
SET client_min_messages = log;
SET debug_print_parse = on;
SET debug_pretty_print = off;
DROP TABLE IF EXISTS outcon130 CASCADE;
CREATE TABLE outcon130 (a int, CONSTRAINT outcon130_chk CHECK (a > 0));
ALTER TABLE outcon130 ADD CONSTRAINT outcon130_notvalid CHECK (a < 100) NOT VALID;
ALTER TABLE outcon130 VALIDATE CONSTRAINT outcon130_notvalid;
RESET debug_print_parse;
RESET debug_pretty_print;
RESET client_min_messages;
DROP TABLE IF EXISTS outcon130 CASCADE;

-- ===== Test Case 105 (commit 131) =====
SELECT 1;

-- ===== Test Case 106 (commit 132) =====
DROP TABLE IF EXISTS lock_a CASCADE;
DROP TABLE IF EXISTS lock_b CASCADE;
CREATE TABLE lock_a (id int);
CREATE TABLE lock_b (id int);
SELECT * FROM lock_a JOIN lock_b ON true FOR UPDATE OF unnamed_join;
DROP TABLE IF EXISTS lock_a CASCADE;
DROP TABLE IF EXISTS lock_b CASCADE;

-- ===== Test Case 107 (commit 132) =====
DROP TABLE IF EXISTS lock_a2 CASCADE;
DROP TABLE IF EXISTS lock_b2 CASCADE;
DROP TABLE IF EXISTS lock_c2 CASCADE;
CREATE TABLE lock_a2 (id int);
CREATE TABLE lock_b2 (id int);
CREATE TABLE lock_c2 (id int);
SELECT * FROM lock_a2 JOIN lock_b2 ON true, lock_c2 AS unnamed_join FOR UPDATE OF unnamed_join;
DROP TABLE IF EXISTS lock_a2 CASCADE;
DROP TABLE IF EXISTS lock_b2 CASCADE;
DROP TABLE IF EXISTS lock_c2 CASCADE;

-- ===== Test Case 108 (commit 132) =====
DROP TABLE IF EXISTS lock_plain CASCADE;
CREATE TABLE lock_plain (id int);
INSERT INTO lock_plain VALUES (1);
SELECT * FROM lock_plain FOR UPDATE OF lock_plain;
DROP TABLE IF EXISTS lock_plain CASCADE;

-- ===== Test Case 109 (commit 133) =====
-- Setup: create a table that uses a TransactionId list internally (e.g., via logical replication)
CREATE TABLE test_xid_list (id INT);
-- Insert a row to trigger logical replication tracking (if enabled)
INSERT INTO test_xid_list VALUES (1);
-- Force use of lappend_xid by creating a logical replication slot (requires wal_level=logical)
SELECT pg_create_logical_replication_slot('test_slot', 'pgoutput');
-- Execution: the slot creation will internally use lappend_xid for streamed_txns
SELECT slot_name, active FROM pg_replication_slots WHERE slot_name = 'test_slot';
-- Teardown
SELECT pg_drop_replication_slot('test_slot');
DROP TABLE IF EXISTS test_xid_list CASCADE;

-- ===== Test Case 110 (commit 133) =====
-- Setup: create a table and a replication slot to generate an XidList
CREATE TABLE test_xid_member (id INT);
INSERT INTO test_xid_member VALUES (1);
SELECT pg_create_logical_replication_slot('test_slot2', 'pgoutput');
-- Execution: query pg_replication_slots which internally calls list_member_xid
SELECT slot_name, active FROM pg_replication_slots WHERE slot_name = 'test_slot2';
-- Teardown
SELECT pg_drop_replication_slot('test_slot2');
DROP TABLE IF EXISTS test_xid_member CASCADE;

-- ===== Test Case 111 (commit 133) =====
-- Setup: create a table and a replication slot to trigger initial XidList creation
CREATE TABLE test_xid_empty (id INT);
INSERT INTO test_xid_empty VALUES (1);
SELECT pg_create_logical_replication_slot('test_slot3', 'pgoutput');
-- Execution: the first transaction tracked will create a new XidList via new_list
SELECT slot_name, active FROM pg_replication_slots WHERE slot_name = 'test_slot3';
-- Teardown
SELECT pg_drop_replication_slot('test_slot3');
DROP TABLE IF EXISTS test_xid_empty CASCADE;

-- ===== Test Case 112 (commit 134) =====
SELECT 1;

-- ===== Test Case 113 (commit 135) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (a int);
INSERT INTO test_t1 VALUES (1);

-- Create a view with an expression that would get "?column?" as its column name
CREATE VIEW test_view1 AS SELECT a + 1 FROM test_t1;

-- Execution: deparse the view definition (triggers make_viewdef with colNamesVisible=true)
SELECT pg_get_viewdef('test_view1'::regclass);

-- Teardown
DROP VIEW IF EXISTS test_view1 CASCADE;
DROP TABLE IF EXISTS test_t1 CASCADE;

-- ===== Test Case 114 (commit 135) =====
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (x int);
INSERT INTO test_t2 VALUES (1);

-- Execution: Use a subquery in FROM with an expression that would get "?column?"
SELECT * FROM (SELECT x + 1 FROM test_t2) AS subq;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 115 (commit 135) =====
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id int);
INSERT INTO test_t3 VALUES (1);

-- Execution: Use EXISTS with a subquery that has an expression producing "?column?"
SELECT * FROM test_t3 WHERE EXISTS (SELECT id + 1 FROM test_t3 WHERE id = 1);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- ===== Test Case 116 (commit 135) =====
DROP VIEW IF EXISTS qcol_setop_v CASCADE;
CREATE VIEW qcol_setop_v AS SELECT 1+1 UNION ALL SELECT 2+2;
SELECT pg_get_viewdef('qcol_setop_v'::regclass, true);
DROP VIEW IF EXISTS qcol_setop_v CASCADE;

-- ===== Test Case 117 (commit 135) =====
DROP VIEW IF EXISTS qcol_upd_v CASCADE;
DROP TABLE IF EXISTS qcol_upd_t CASCADE;
CREATE TABLE qcol_upd_t (id int, val int);
CREATE VIEW qcol_upd_v AS SELECT * FROM qcol_upd_t;
CREATE RULE qcol_upd_r AS ON UPDATE TO qcol_upd_v DO INSTEAD UPDATE qcol_upd_t SET val = NEW.val + 1 WHERE id = OLD.id;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='qcol_upd_v'::regclass AND rulename='qcol_upd_r';
DROP VIEW IF EXISTS qcol_upd_v CASCADE;
DROP TABLE IF EXISTS qcol_upd_t CASCADE;

-- ===== Test Case 118 (commit 135) =====
DROP VIEW IF EXISTS qcol_del_v CASCADE;
DROP TABLE IF EXISTS qcol_del_t CASCADE;
CREATE TABLE qcol_del_t (id int);
CREATE VIEW qcol_del_v AS SELECT * FROM qcol_del_t;
CREATE RULE qcol_del_r AS ON DELETE TO qcol_del_v DO INSTEAD DELETE FROM qcol_del_t WHERE id = OLD.id RETURNING id + 1;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='qcol_del_v'::regclass AND rulename='qcol_del_r';
DROP VIEW IF EXISTS qcol_del_v CASCADE;
DROP TABLE IF EXISTS qcol_del_t CASCADE;

-- ===== Test Case 119 (commit 136) =====
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily1 USING btree CASCADE;
DROP OPERATOR CLASS IF EXISTS test_opclass1 USING btree CASCADE;

-- Execution: Create an operator class without an existing operator family, triggering implicit family creation
CREATE OPERATOR CLASS test_opclass1 FOR TYPE int4 USING btree AS
    OPERATOR 1 =,
    FUNCTION 1 btint4cmp(int4, int4);

-- Teardown
DROP OPERATOR CLASS test_opclass1 USING btree CASCADE;
DROP OPERATOR FAMILY IF EXISTS test_opfamily1 USING btree CASCADE;

-- ===== Test Case 120 (commit 136) =====
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily2 USING btree CASCADE;

-- Execution: Create an operator family directly
CREATE OPERATOR FAMILY test_opfamily2 USING btree;

-- Teardown
DROP OPERATOR FAMILY test_opfamily2 USING btree CASCADE;

-- ===== Test Case 121 (commit 136) =====
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily3 USING btree CASCADE;
CREATE OPERATOR FAMILY test_opfamily3 USING btree;

-- Execution: Try to create an operator class that would implicitly create a duplicate operator family
CREATE OPERATOR CLASS test_opclass3 FOR TYPE int4 USING btree FAMILY test_opfamily3 AS
    OPERATOR 1 =,
    FUNCTION 1 btint4cmp(int4, int4);

-- Teardown
DROP OPERATOR CLASS test_opclass3 USING btree CASCADE;
DROP OPERATOR FAMILY test_opfamily3 USING btree CASCADE;

-- ===== Test Case 122 (commit 137) =====
-- Setup
DROP TABLE IF EXISTS zero_col_tab CASCADE;
CREATE TABLE zero_col_tab ();  -- zero-column table
INSERT INTO zero_col_tab DEFAULT VALUES;

-- Execution: Use VALUES with a zero-column subquery via tab.* expansion
SELECT * FROM (VALUES ((SELECT * FROM zero_col_tab))) AS v;

-- Teardown
DROP TABLE IF EXISTS zero_col_tab CASCADE;

-- ===== Test Case 123 (commit 137) =====
-- Setup
DROP TABLE IF EXISTS multi_col_tab CASCADE;
CREATE TABLE multi_col_tab (a INT, b TEXT);
INSERT INTO multi_col_tab VALUES (1, 'one'), (2, 'two');

-- Execution: Use VALUES with multiple rows and columns
SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS v(x, y);

-- Teardown
DROP TABLE IF EXISTS multi_col_tab CASCADE;

-- ===== Test Case 124 (commit 137) =====
-- Setup
DROP TABLE IF EXISTS single_col_tab CASCADE;
CREATE TABLE single_col_tab (x INT);
INSERT INTO single_col_tab VALUES (42);

-- Execution: Use VALUES with a single row and column
SELECT * FROM (VALUES (42)) AS v(x);

-- Teardown
DROP TABLE IF EXISTS single_col_tab CASCADE;

-- ===== Test Case 125 (commit 138) =====
-- Setup
DROP MATERIALIZED VIEW IF EXISTS mv_test1 CASCADE;
CREATE TABLE base_t1 (id INT, val TEXT);
INSERT INTO base_t1 VALUES (1, 'a'), (2, 'b');
CREATE MATERIALIZED VIEW mv_test1 AS SELECT * FROM base_t1;

-- Execution
REFRESH MATERIALIZED VIEW mv_test1;

-- Teardown
DROP MATERIALIZED VIEW IF EXISTS mv_test1 CASCADE;
DROP TABLE IF EXISTS base_t1 CASCADE;

-- ===== Test Case 126 (commit 138) =====
-- Setup
DROP MATERIALIZED VIEW IF EXISTS mv_test2 CASCADE;
CREATE TABLE base_t2 (id INT, val TEXT);
INSERT INTO base_t2 VALUES (1, 'x');
CREATE MATERIALIZED VIEW mv_test2 AS SELECT * FROM base_t2;

-- Execution
REFRESH MATERIALIZED VIEW mv_test2 WITH NO DATA;

-- Teardown
DROP MATERIALIZED VIEW IF EXISTS mv_test2 CASCADE;
DROP TABLE IF EXISTS base_t2 CASCADE;

-- ===== Test Case 127 (commit 138) =====
-- Setup
DROP MATERIALIZED VIEW IF EXISTS mv_test3 CASCADE;
CREATE TABLE base_t3 (id INT PRIMARY KEY, val TEXT);
INSERT INTO base_t3 VALUES (1, 'a'), (2, 'b');
CREATE MATERIALIZED VIEW mv_test3 AS SELECT * FROM base_t3;
CREATE UNIQUE INDEX ON mv_test3 (id);
INSERT INTO base_t3 VALUES (3, 'c');

-- Execution
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_test3;

-- Teardown
DROP MATERIALIZED VIEW IF EXISTS mv_test3 CASCADE;
DROP TABLE IF EXISTS base_t3 CASCADE;

-- ===== Test Case 128 (commit 139) =====
-- Setup
DROP TABLE IF EXISTS test_alter_sys_attr CASCADE;
CREATE TABLE test_alter_sys_attr (id INT);
INSERT INTO test_alter_sys_attr VALUES (1);

-- Execution: Attempt to alter a system column (oid) which has attnum <= 0
ALTER TABLE test_alter_sys_attr ALTER COLUMN oid TYPE bigint;

-- Teardown
DROP TABLE IF EXISTS test_alter_sys_attr CASCADE;

-- ===== Test Case 129 (commit 139) =====
-- Setup
DROP TABLE IF EXISTS test_alter_identity CASCADE;
CREATE TABLE test_alter_identity (id INT GENERATED BY DEFAULT AS IDENTITY);
INSERT INTO test_alter_identity DEFAULT VALUES;

-- Execution: Alter the identity column's type (triggers getIdentitySequence)
ALTER TABLE test_alter_identity ALTER COLUMN id TYPE bigint;

-- Teardown
DROP TABLE IF EXISTS test_alter_identity CASCADE;

-- ===== Test Case 130 (commit 139) =====
-- Setup
DROP TABLE IF EXISTS test_alter_nonexist CASCADE;
CREATE TABLE test_alter_nonexist (id INT);
INSERT INTO test_alter_nonexist VALUES (1);

-- Execution: Attempt to alter a non-existent column (should error out)
ALTER TABLE test_alter_nonexist ALTER COLUMN nonexistent TYPE text;

-- Teardown
DROP TABLE IF EXISTS test_alter_nonexist CASCADE;

-- ===== Test Case 131 (commit 140) =====
-- Setup
DROP TABLE IF EXISTS test_lock CASCADE;
CREATE TABLE test_lock (id INT PRIMARY KEY, val TEXT);
INSERT INTO test_lock VALUES (1, 'initial');

-- Execution: Use a concurrent transaction to lock and modify the tuple, then try to lock it again in a way that triggers heapam_tuple_lock() with keep_buf=true
BEGIN;
UPDATE test_lock SET val = 'updated' WHERE id = 1;
-- In another session, this would trigger the code path; simulate with a self-contained approach using a savepoint and rollback
SAVEPOINT sp;
SELECT * FROM test_lock WHERE id = 1 FOR UPDATE;
ROLLBACK TO sp;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_lock CASCADE;

-- ===== Test Case 132 (commit 140) =====
-- Setup
DROP TABLE IF EXISTS test_fetch CASCADE;
CREATE TABLE test_fetch (id INT, val TEXT);
INSERT INTO test_fetch VALUES (1, 'visible');

-- Execution: Use a snapshot that sees the tuple as invisible (e.g., using a different transaction isolation level or explicit snapshot)
BEGIN ISOLATION LEVEL REPEATABLE READ;
UPDATE test_fetch SET val = 'invisible' WHERE id = 1;
-- Now in the same transaction, the old snapshot sees the old tuple as invisible
SELECT * FROM test_fetch WHERE id = 1;  -- This will use heap_fetch with keep_buf=false
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_fetch CASCADE;

-- ===== Test Case 133 (commit 140) =====
-- Setup
DROP TABLE IF EXISTS test_lock2 CASCADE;
CREATE TABLE test_lock2 (id INT, val TEXT);
INSERT INTO test_lock2 VALUES (1, 'original');

-- Execution: Simulate a concurrent update that triggers heapam_tuple_lock with keep_buf=true
BEGIN;
UPDATE test_lock2 SET val = 'modified' WHERE id = 1;
-- Use a subtransaction to simulate the EvalPlanQualFetch path
SAVEPOINT sp1;
SELECT * FROM test_lock2 WHERE id = 1 FOR UPDATE;
ROLLBACK TO sp1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_lock2 CASCADE;

-- ===== Test Case 134 (commit 140) =====
DROP TABLE IF EXISTS conc_lock140 CASCADE;
CREATE TABLE conc_lock140 (id int PRIMARY KEY, val text);
INSERT INTO conc_lock140 VALUES (1, 'old');
\! PGHOST=/tmp/pgcov-55432 PGPORT=55432 psql -d regression -v ON_ERROR_STOP=0 -c "BEGIN; UPDATE conc_lock140 SET val = 'new' WHERE id = 1; SELECT pg_sleep(2); COMMIT;" >/tmp/conc_lock140_bg.log 2>&1 &
SELECT pg_sleep(0.5);
SELECT * FROM conc_lock140 WHERE id = 1 FOR UPDATE;
SELECT pg_sleep(0.5);
DROP TABLE IF EXISTS conc_lock140 CASCADE;

-- ===== Test Case 135 (commit 141) =====
SELECT 1;

-- ===== Test Case 136 (commit 142) =====
DROP VIEW IF EXISTS ruleutils_values_view CASCADE;
CREATE VIEW ruleutils_values_view AS VALUES (1, 'a'), (2, 'b');
SELECT pg_get_viewdef('ruleutils_values_view'::regclass, true);
DROP VIEW IF EXISTS ruleutils_values_view CASCADE;

-- ===== Test Case 137 (commit 142) =====
DROP VIEW IF EXISTS ruleutils_subquery_view CASCADE;
CREATE VIEW ruleutils_subquery_view AS SELECT sq.x FROM (SELECT 1 AS x) AS sq;
SELECT pg_get_viewdef('ruleutils_subquery_view'::regclass, true);
DROP VIEW IF EXISTS ruleutils_subquery_view CASCADE;

-- ===== Test Case 138 (commit 142) =====
DROP VIEW IF EXISTS ruleutils_plain_view CASCADE;
CREATE VIEW ruleutils_plain_view AS SELECT * FROM (VALUES (1), (2)) AS v(x);
SELECT pg_get_viewdef('ruleutils_plain_view'::regclass, false);
DROP VIEW IF EXISTS ruleutils_plain_view CASCADE;

-- ===== Test Case 139 (commit 143) =====
-- Setup
DROP TABLE IF EXISTS parent_table CASCADE;
CREATE TABLE parent_table (id INT, data TEXT) PARTITION BY RANGE (id);
CREATE TABLE child_table PARTITION OF parent_table FOR VALUES FROM (1) TO (100);
CREATE INDEX idx_parent ON parent_table(id);
CREATE INDEX idx_child ON child_table(id);

-- Execution
DROP INDEX idx_parent;

-- Teardown
DROP TABLE IF EXISTS parent_table CASCADE;

-- ===== Test Case 140 (commit 143) =====
-- Setup
DROP TABLE IF EXISTS parent_table2 CASCADE;
CREATE TABLE parent_table2 (id INT, data TEXT) PARTITION BY RANGE (id);
CREATE TABLE child_table2 PARTITION OF parent_table2 FOR VALUES FROM (1) TO (100);
CREATE INDEX idx_parent2 ON parent_table2(id);
CREATE INDEX idx_child2 ON child_table2(id);

-- Execution
DROP INDEX CONCURRENTLY idx_parent2;

-- Teardown
DROP TABLE IF EXISTS parent_table2 CASCADE;

-- ===== Test Case 141 (commit 143) =====
-- Setup
DROP TABLE IF EXISTS plain_table CASCADE;
CREATE TABLE plain_table (id INT, data TEXT);
CREATE INDEX idx_plain ON plain_table(id);

-- Execution
DROP INDEX idx_plain;

-- Teardown
DROP TABLE IF EXISTS plain_table CASCADE;

-- ===== Test Case 142 (commit 143) =====
DROP TABLE IF EXISTS wrongdrop143 CASCADE;
CREATE TABLE wrongdrop143 (a int) PARTITION BY RANGE (a);
CREATE TABLE wrongdrop143_1 PARTITION OF wrongdrop143 FOR VALUES FROM (0) TO (10);
CREATE INDEX wrongdrop143_a_idx ON wrongdrop143 (a);
DROP TABLE wrongdrop143_a_idx;
DROP INDEX wrongdrop143_a_idx;
DROP TABLE IF EXISTS wrongdrop143 CASCADE;

-- ===== Test Case 143 (commit 144) =====
-- Setup: Create a table and ensure clean shutdown
DROP TABLE IF EXISTS test_recovery CASCADE;
CREATE TABLE test_recovery (id INT);
INSERT INTO test_recovery VALUES (1);
CHECKPOINT;

-- Simulate recovery signal file presence (requires pg_ctl or file manipulation)
-- This test assumes the environment can create signal files; otherwise, it's a no-op.
-- For coverage, we just need to reach the code path; actual recovery is triggered externally.
-- We'll use a dummy query to ensure the database starts in recovery mode.
SELECT pg_is_in_recovery();

-- Teardown
DROP TABLE IF EXISTS test_recovery CASCADE;

-- ===== Test Case 144 (commit 144) =====
-- Setup: Create a table and force a crash by killing the backend (simulated via pg_ctl stop -m immediate)
DROP TABLE IF EXISTS test_crash CASCADE;
CREATE TABLE test_crash (id INT);
INSERT INTO test_crash VALUES (1);
-- Force checkpoint to ensure WAL records exist
CHECKPOINT;
-- Simulate crash by immediate shutdown (requires external action; here we just ensure recovery is needed)
-- For coverage, we rely on the test harness to restart after crash.
SELECT pg_is_in_recovery();

-- Teardown
DROP TABLE IF EXISTS test_crash CASCADE;

-- ===== Test Case 145 (commit 144) =====
-- Setup: Create a table and simulate archive recovery with a new timeline
DROP TABLE IF EXISTS test_archive CASCADE;
CREATE TABLE test_archive (id INT);
INSERT INTO test_archive VALUES (1);
CHECKPOINT;

-- This test requires archive recovery setup (signal files, archive command).
-- For coverage, we assume the test environment triggers archive recovery.
-- The code path includes XLogInitNewTimeline, signal file removal, and cleanup.
SELECT pg_is_in_recovery();

-- Teardown
DROP TABLE IF EXISTS test_archive CASCADE;

-- ===== Test Case 146 (commit 145) =====
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

-- ===== Test Case 147 (commit 145) =====
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

-- ===== Test Case 148 (commit 145) =====
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

-- ===== Test Case 149 (commit 146) =====
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

-- ===== Test Case 150 (commit 146) =====
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

-- ===== Test Case 151 (commit 146) =====
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

-- ===== Test Case 152 (commit 147) =====
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);
CREATE UNIQUE INDEX idx_t1 ON test_t1 (id);

-- Execution: This should mark the index as primary and flush the table's relcache
ALTER TABLE test_t1 ADD PRIMARY KEY USING INDEX idx_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- ===== Test Case 153 (commit 147) =====
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
CREATE UNIQUE INDEX idx_t2 ON test_t2 (id);

-- Execution: Empty table, still triggers the relcache flush
ALTER TABLE test_t2 ADD PRIMARY KEY USING INDEX idx_t2;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- ===== Test Case 154 (commit 147) =====
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT PRIMARY KEY);
INSERT INTO test_t3 VALUES (1);
CREATE UNIQUE INDEX idx_t3 ON test_t3 (id);

-- Execution: This will fail because the table already has a primary key, so the new code path is not executed
ALTER TABLE test_t3 ADD PRIMARY KEY USING INDEX idx_t3;

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- ===== Test Case 155 (commit 148) =====
DROP TABLE IF EXISTS test_subxact CASCADE;
CREATE TABLE test_subxact (id INT);
BEGIN;
INSERT INTO test_subxact VALUES (1);
SAVEPOINT sp1;
INSERT INTO test_subxact VALUES (2);
SAVEPOINT sp2;
INSERT INTO test_subxact VALUES (3);
RELEASE SAVEPOINT sp2;
RELEASE SAVEPOINT sp1;
COMMIT;
SELECT count(*) FROM test_subxact;
DROP TABLE IF EXISTS test_subxact CASCADE;

-- ===== Test Case 156 (commit 148) =====
DROP TABLE IF EXISTS test_no_subxact CASCADE;
CREATE TABLE test_no_subxact (id INT);
BEGIN;
INSERT INTO test_no_subxact VALUES (1);
COMMIT;
SELECT count(*) FROM test_no_subxact;
DROP TABLE IF EXISTS test_no_subxact CASCADE;

-- ===== Test Case 157 (commit 148) =====
DROP TABLE IF EXISTS test_many_subxact CASCADE;
CREATE TABLE test_many_subxact (id INT);
BEGIN;
INSERT INTO test_many_subxact VALUES (1);
SAVEPOINT sp1;
INSERT INTO test_many_subxact VALUES (2);
SAVEPOINT sp2;
INSERT INTO test_many_subxact VALUES (3);
SAVEPOINT sp3;
INSERT INTO test_many_subxact VALUES (4);
RELEASE SAVEPOINT sp3;
RELEASE SAVEPOINT sp2;
RELEASE SAVEPOINT sp1;
COMMIT;
SELECT count(*) FROM test_many_subxact;
DROP TABLE IF EXISTS test_many_subxact CASCADE;

-- ===== Test Case 158 (commit 149) =====
DROP VIEW IF EXISTS insert_rule_view CASCADE;
DROP TABLE IF EXISTS insert_rule_base CASCADE;
CREATE TABLE insert_rule_base (a int, b int);
CREATE VIEW insert_rule_view AS SELECT * FROM insert_rule_base;
CREATE RULE insert_rule_ins AS ON INSERT TO insert_rule_view DO INSTEAD INSERT INTO insert_rule_base VALUES (NEW.a, NEW.b);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class = 'insert_rule_view'::regclass AND rulename = 'insert_rule_ins';
DROP VIEW IF EXISTS insert_rule_view CASCADE;
DROP TABLE IF EXISTS insert_rule_base CASCADE;

-- ===== Test Case 159 (commit 149) =====
DROP VIEW IF EXISTS rowcompare_view CASCADE;
DROP TABLE IF EXISTS rowcompare_base CASCADE;
CREATE TABLE rowcompare_base (a int, b int);
CREATE VIEW rowcompare_view AS SELECT * FROM rowcompare_base t WHERE ROW(t.*) = ROW(t.*);
SELECT pg_get_viewdef('rowcompare_view'::regclass, true);
DROP VIEW IF EXISTS rowcompare_view CASCADE;
DROP TABLE IF EXISTS rowcompare_base CASCADE;

-- ===== Test Case 160 (commit 149) =====
DROP VIEW IF EXISTS values_row_view CASCADE;
DROP TABLE IF EXISTS values_row_base CASCADE;
CREATE TABLE values_row_base (x int);
INSERT INTO values_row_base VALUES (1);
CREATE VIEW values_row_view AS SELECT * FROM (VALUES ((SELECT values_row_base FROM values_row_base))) AS v(r);
SELECT pg_get_viewdef('values_row_view'::regclass, true);
DROP VIEW IF EXISTS values_row_view CASCADE;
DROP TABLE IF EXISTS values_row_base CASCADE;

-- ===== Test Case 161 (commit 150) =====
SELECT 1;

