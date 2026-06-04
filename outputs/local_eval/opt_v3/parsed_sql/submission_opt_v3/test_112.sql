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
DROP ROLE IF EXISTS vac112_role;
CREATE ROLE vac112_role LOGIN;
SET ROLE vac112_role;
VACUUM pg_class;
RESET ROLE;
DROP ROLE IF EXISTS vac112_role;

-- --- Test Case 5 ---
DROP ROLE IF EXISTS anl112_role;
CREATE ROLE anl112_role LOGIN;
SET ROLE anl112_role;
ANALYZE pg_class;
RESET ROLE;
DROP ROLE IF EXISTS anl112_role;

