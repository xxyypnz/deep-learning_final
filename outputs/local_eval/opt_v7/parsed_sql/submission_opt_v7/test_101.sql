-- ===== Commit 101 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);

-- Execution
WITH test_t1 AS (SELECT 2 AS id)
INSERT INTO test_t1 (id) SELECT id FROM test_t1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (id INT);
INSERT INTO test_t2 VALUES (1);

-- Execution
WITH test_t2 AS (SELECT 2 AS id)
UPDATE test_t2 SET id = (SELECT id FROM test_t2) WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id INT);
INSERT INTO test_t3 VALUES (1);

-- Execution
WITH test_t3 AS (SELECT 2 AS id)
DELETE FROM test_t3 WHERE id = (SELECT id FROM test_t3);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- --- Test Case 4 ---
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

-- --- Test Case 5 ---
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

-- --- Test Case 6 ---
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

-- --- Test Case 7 ---
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

-- --- Test Case 8 ---
DROP TABLE IF EXISTS foo101 CASCADE;
CREATE TABLE foo101 (f1 text DEFAULT 'test', f2 int DEFAULT 42, f3 int DEFAULT 7);
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING *;
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING bar.*;
INSERT INTO foo101 AS bar DEFAULT VALUES RETURNING bar.f3;
DROP TABLE IF EXISTS foo101 CASCADE;

-- --- Test Case 9 ---
DROP VIEW IF EXISTS rte_rel101_v CASCADE;
DROP TABLE IF EXISTS rte_rel101 CASCADE;
CREATE TABLE rte_rel101 (a int);
CREATE VIEW rte_rel101_v AS
WITH rte_rel101 AS (SELECT 99 AS a)
SELECT * FROM public.rte_rel101;
SELECT pg_get_viewdef('rte_rel101_v'::regclass, true);
DROP VIEW IF EXISTS rte_rel101_v CASCADE;
DROP TABLE IF EXISTS rte_rel101 CASCADE;

-- --- Test Case 10 ---
DROP VIEW IF EXISTS rte_func101_v CASCADE;
CREATE VIEW rte_func101_v AS SELECT * FROM generate_series(1, 3);
SELECT pg_get_viewdef('rte_func101_v'::regclass, true);
DROP VIEW IF EXISTS rte_func101_v CASCADE;

-- --- Test Case 11 ---
DROP VIEW IF EXISTS rte_values101_v CASCADE;
CREATE VIEW rte_values101_v AS SELECT * FROM (VALUES (1), (2));
SELECT pg_get_viewdef('rte_values101_v'::regclass, true);
DROP VIEW IF EXISTS rte_values101_v CASCADE;

-- --- Test Case 12 ---
DROP VIEW IF EXISTS rte_cte101_v CASCADE;
CREATE VIEW rte_cte101_v AS
WITH cte101 AS (SELECT 1 AS a)
SELECT * FROM cte101
WHERE EXISTS (WITH cte101 AS (SELECT 2 AS a) SELECT 1 FROM cte101 WHERE cte101.a > 0);
SELECT pg_get_viewdef('rte_cte101_v'::regclass, true);
DROP VIEW IF EXISTS rte_cte101_v CASCADE;

