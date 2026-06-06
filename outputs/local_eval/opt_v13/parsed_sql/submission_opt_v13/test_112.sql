-- ===== Commit 112 =====
-- Source:  - 

-- --- Test Case 1 ---
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

-- --- Test Case 2 ---
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

-- --- Test Case 3 ---
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

-- --- Test Case 4 ---
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

