-- ===== Commit 105 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_gen_trigger CASCADE;
CREATE TABLE test_gen_trigger (
    id INT PRIMARY KEY,
    a INT,
    b INT GENERATED ALWAYS AS (a * 2) STORED
);
CREATE OR REPLACE FUNCTION test_trigger_func() RETURNS TRIGGER AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_trigger BEFORE UPDATE ON test_gen_trigger FOR EACH ROW EXECUTE FUNCTION test_trigger_func();
INSERT INTO test_gen_trigger VALUES (1, 5);

-- Execution: UPDATE triggers the trigger, which calls ExecGetExtraUpdatedCols before ExecInitStoredGenerated
UPDATE test_gen_trigger SET a = 10 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_gen_trigger CASCADE;
DROP FUNCTION IF EXISTS test_trigger_func;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_gen_logical CASCADE;
CREATE TABLE test_gen_logical (
    id INT PRIMARY KEY,
    x INT,
    y INT GENERATED ALWAYS AS (x + 1) STORED
);
CREATE OR REPLACE FUNCTION test_logical_trigger() RETURNS TRIGGER AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_logical_trig BEFORE UPDATE ON test_gen_logical FOR EACH ROW EXECUTE FUNCTION test_logical_trigger();
INSERT INTO test_gen_logical VALUES (1, 100);

-- Execution: UPDATE triggers the trigger, which calls ExecGetExtraUpdatedCols before generated columns are initialized
UPDATE test_gen_logical SET x = 200 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_gen_logical CASCADE;
DROP FUNCTION IF EXISTS test_logical_trigger;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_gen_multi CASCADE;
CREATE TABLE test_gen_multi (
    id INT PRIMARY KEY,
    val1 INT,
    val2 INT GENERATED ALWAYS AS (val1 * 3) STORED,
    val3 INT GENERATED ALWAYS AS (val1 + val2) STORED
);
CREATE OR REPLACE FUNCTION test_multi_trigger() RETURNS TRIGGER AS $$
BEGIN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_multi_trig BEFORE UPDATE ON test_gen_multi FOR EACH ROW EXECUTE FUNCTION test_multi_trigger();
INSERT INTO test_gen_multi VALUES (1, 5);

-- Execution: UPDATE triggers the trigger, which calls ExecGetExtraUpdatedCols before generated columns are initialized
UPDATE test_gen_multi SET val1 = 7 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_gen_multi CASCADE;
DROP FUNCTION IF EXISTS test_multi_trigger;

