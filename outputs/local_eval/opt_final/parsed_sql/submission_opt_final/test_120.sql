-- ===== Commit 120 =====
-- Source:  - 

-- --- Test Case 1 ---
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

-- --- Test Case 2 ---
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

-- --- Test Case 3 ---
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

-- --- Test Case 4 ---
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

-- --- Test Case 5 ---
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

