-- ===== Commit 150 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
CREATE TABLE test_partitioned (a int) PARTITION BY LIST (a);
CREATE TABLE test_uses_rowtype (b test_partitioned);
-- Execution: Attempt to alter column type on partitioned table; should fail with error about composite type dependencies
ALTER TABLE test_partitioned ALTER COLUMN a TYPE bigint;
-- Teardown
DROP TABLE IF EXISTS test_uses_rowtype CASCADE;
DROP TABLE IF EXISTS test_partitioned CASCADE;

-- --- Test Case 2 ---
-- Setup
CREATE TABLE test_regular (a int);
CREATE TABLE test_uses_rowtype2 (b test_regular);
-- Execution: Alter column type on regular table; should succeed (check deferred to rewrite phase)
ALTER TABLE test_regular ALTER COLUMN a TYPE bigint;
-- Teardown
DROP TABLE IF EXISTS test_uses_rowtype2 CASCADE;
DROP TABLE IF EXISTS test_regular CASCADE;

-- --- Test Case 3 ---
-- Setup
CREATE FOREIGN DATA WRAPPER test_fdw VALIDATOR (pg_catalog.postgresql_fdw_validator);
CREATE SERVER test_server FOREIGN DATA WRAPPER test_fdw;
CREATE FOREIGN TABLE test_foreign (a int) SERVER test_server;
CREATE TABLE test_uses_rowtype3 (b test_foreign);
-- Execution: Attempt to alter column type on foreign table; should fail with error about composite type dependencies
ALTER TABLE test_foreign ALTER COLUMN a TYPE bigint;
-- Teardown
DROP TABLE IF EXISTS test_uses_rowtype3 CASCADE;
DROP FOREIGN TABLE IF EXISTS test_foreign CASCADE;
DROP SERVER IF EXISTS test_server CASCADE;
DROP FOREIGN DATA WRAPPER IF EXISTS test_fdw CASCADE;

