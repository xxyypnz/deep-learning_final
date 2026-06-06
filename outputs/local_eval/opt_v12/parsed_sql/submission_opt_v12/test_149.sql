-- ===== Commit 149 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS insert_rule_view CASCADE;
DROP TABLE IF EXISTS insert_rule_base CASCADE;
CREATE TABLE insert_rule_base (a int, b int);
CREATE VIEW insert_rule_view AS SELECT * FROM insert_rule_base;
CREATE RULE insert_rule_ins AS ON INSERT TO insert_rule_view DO INSTEAD INSERT INTO insert_rule_base VALUES (NEW.a, NEW.b);
SELECT pg_get_ruledef(oid, true) FROM pg_rewrite WHERE ev_class = 'insert_rule_view'::regclass AND rulename = 'insert_rule_ins';
DROP VIEW IF EXISTS insert_rule_view CASCADE;
DROP TABLE IF EXISTS insert_rule_base CASCADE;

-- --- Test Case 2 ---
DROP VIEW IF EXISTS rowcompare_view CASCADE;
DROP TABLE IF EXISTS rowcompare_base CASCADE;
CREATE TABLE rowcompare_base (a int, b int);
CREATE VIEW rowcompare_view AS SELECT * FROM rowcompare_base t WHERE ROW(t.*) = ROW(t.*);
SELECT pg_get_viewdef('rowcompare_view'::regclass, true);
DROP VIEW IF EXISTS rowcompare_view CASCADE;
DROP TABLE IF EXISTS rowcompare_base CASCADE;

-- --- Test Case 3 ---
DROP VIEW IF EXISTS values_row_view CASCADE;
DROP TABLE IF EXISTS values_row_base CASCADE;
CREATE TABLE values_row_base (x int);
INSERT INTO values_row_base VALUES (1);
CREATE VIEW values_row_view AS SELECT * FROM (VALUES ((SELECT values_row_base FROM values_row_base))) AS v(r);
SELECT pg_get_viewdef('values_row_view'::regclass, true);
DROP VIEW IF EXISTS values_row_view CASCADE;
DROP TABLE IF EXISTS values_row_base CASCADE;

