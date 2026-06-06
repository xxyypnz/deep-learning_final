-- ===== Commit 142 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP VIEW IF EXISTS ruleutils_values_view CASCADE;
CREATE VIEW ruleutils_values_view AS VALUES (1, 'a'), (2, 'b');
SELECT pg_get_viewdef('ruleutils_values_view'::regclass, true);
DROP VIEW IF EXISTS ruleutils_values_view CASCADE;

-- --- Test Case 2 ---
DROP VIEW IF EXISTS ruleutils_subquery_view CASCADE;
CREATE VIEW ruleutils_subquery_view AS SELECT sq.x FROM (SELECT 1 AS x) AS sq;
SELECT pg_get_viewdef('ruleutils_subquery_view'::regclass, true);
DROP VIEW IF EXISTS ruleutils_subquery_view CASCADE;

-- --- Test Case 3 ---
DROP VIEW IF EXISTS ruleutils_plain_view CASCADE;
CREATE VIEW ruleutils_plain_view AS SELECT * FROM (VALUES (1), (2)) AS v(x);
SELECT pg_get_viewdef('ruleutils_plain_view'::regclass, false);
DROP VIEW IF EXISTS ruleutils_plain_view CASCADE;

