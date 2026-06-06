-- ===== Commit 136 =====
-- Source:  - 

-- --- Test Case 1 ---
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

-- --- Test Case 2 ---
-- Setup
DROP OPERATOR FAMILY IF EXISTS test_opfamily2 USING btree CASCADE;

-- Execution: Create an operator family directly
CREATE OPERATOR FAMILY test_opfamily2 USING btree;

-- Teardown
DROP OPERATOR FAMILY test_opfamily2 USING btree CASCADE;

-- --- Test Case 3 ---
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

