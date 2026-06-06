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

-- --- Test Case 4 ---
DROP EVENT TRIGGER IF EXISTS evt136_report_end;
DROP FUNCTION IF EXISTS evt136_report_end();
DROP OPERATOR CLASS IF EXISTS evt136_opclass USING btree CASCADE;
CREATE OR REPLACE FUNCTION evt136_report_end()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        RAISE NOTICE 'END: command_tag=% type=% identity=%',
            r.command_tag, r.object_type, r.object_identity;
    END LOOP;
END; $$;
CREATE EVENT TRIGGER evt136_report_end ON ddl_command_end
  EXECUTE PROCEDURE evt136_report_end();
CREATE OPERATOR CLASS evt136_opclass FOR TYPE int USING btree AS STORAGE int;
DROP EVENT TRIGGER IF EXISTS evt136_report_end;
DROP OPERATOR CLASS IF EXISTS evt136_opclass USING btree CASCADE;
DROP FUNCTION IF EXISTS evt136_report_end();

