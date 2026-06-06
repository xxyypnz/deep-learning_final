-- ===== Commit 135 =====
-- Source:  - 

-- --- Test Case 1 ---
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

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_t2 CASCADE;
CREATE TABLE test_t2 (x int);
INSERT INTO test_t2 VALUES (1);

-- Execution: Use a subquery in FROM with an expression that would get "?column?"
SELECT * FROM (SELECT x + 1 FROM test_t2) AS subq;

-- Teardown
DROP TABLE IF EXISTS test_t2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_t3 CASCADE;
CREATE TABLE test_t3 (id int);
INSERT INTO test_t3 VALUES (1);

-- Execution: Use EXISTS with a subquery that has an expression producing "?column?"
SELECT * FROM test_t3 WHERE EXISTS (SELECT id + 1 FROM test_t3 WHERE id = 1);

-- Teardown
DROP TABLE IF EXISTS test_t3 CASCADE;

-- --- Test Case 4 ---
DROP VIEW IF EXISTS qcol_setop_v CASCADE;
CREATE VIEW qcol_setop_v AS SELECT 1+1 UNION ALL SELECT 2+2;
SELECT pg_get_viewdef('qcol_setop_v'::regclass, true);
DROP VIEW IF EXISTS qcol_setop_v CASCADE;

-- --- Test Case 5 ---
DROP VIEW IF EXISTS qcol_upd_v CASCADE;
DROP TABLE IF EXISTS qcol_upd_t CASCADE;
CREATE TABLE qcol_upd_t (id int, val int);
CREATE VIEW qcol_upd_v AS SELECT * FROM qcol_upd_t;
CREATE RULE qcol_upd_r AS ON UPDATE TO qcol_upd_v DO INSTEAD UPDATE qcol_upd_t SET val = NEW.val + 1 WHERE id = OLD.id;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='qcol_upd_v'::regclass AND rulename='qcol_upd_r';
DROP VIEW IF EXISTS qcol_upd_v CASCADE;
DROP TABLE IF EXISTS qcol_upd_t CASCADE;

-- --- Test Case 6 ---
DROP VIEW IF EXISTS qcol_del_v CASCADE;
DROP TABLE IF EXISTS qcol_del_t CASCADE;
CREATE TABLE qcol_del_t (id int);
CREATE VIEW qcol_del_v AS SELECT * FROM qcol_del_t;
CREATE RULE qcol_del_r AS ON DELETE TO qcol_del_v DO INSTEAD DELETE FROM qcol_del_t WHERE id = OLD.id RETURNING id + 1;
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class='qcol_del_v'::regclass AND rulename='qcol_del_r';
DROP VIEW IF EXISTS qcol_del_v CASCADE;
DROP TABLE IF EXISTS qcol_del_t CASCADE;

-- --- Test Case 7 ---
DROP VIEW IF EXISTS qcol_outer135_v CASCADE;
DROP VIEW IF EXISTS qcol_inner135_v CASCADE;
CREATE VIEW qcol_inner135_v AS SELECT 1+1 UNION ALL SELECT 2+2;
CREATE VIEW qcol_outer135_v AS SELECT * FROM qcol_inner135_v;
SELECT pg_get_viewdef('qcol_outer135_v'::regclass, true);
SELECT pg_get_viewdef('qcol_inner135_v'::regclass, true);
DROP VIEW IF EXISTS qcol_outer135_v CASCADE;
DROP VIEW IF EXISTS qcol_inner135_v CASCADE;

