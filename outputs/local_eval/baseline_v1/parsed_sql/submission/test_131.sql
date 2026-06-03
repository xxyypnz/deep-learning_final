-- ===== Commit 131 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_spec_insert CASCADE;
CREATE TABLE test_spec_insert (id INT UNIQUE);
INSERT INTO test_spec_insert VALUES (1);

-- Execution: Attempt speculative insertion that conflicts, triggering loop back to vlock label
BEGIN;
INSERT INTO test_spec_insert VALUES (1) ON CONFLICT DO NOTHING;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_spec_insert CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_spec_update CASCADE;
CREATE TABLE test_spec_update (id INT UNIQUE, val INT);
INSERT INTO test_spec_update VALUES (1, 10);

-- Execution: Attempt speculative insertion with conflict that triggers update, looping back to vlock
BEGIN;
INSERT INTO test_spec_update VALUES (1, 20) ON CONFLICT (id) DO UPDATE SET val = EXCLUDED.val;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_spec_update CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_spec_multi CASCADE;
CREATE TABLE test_spec_multi (a INT UNIQUE, b INT UNIQUE);
INSERT INTO test_spec_multi VALUES (1, 10);

-- Execution: Insert a row that conflicts on one constraint, then another that conflicts on the other, forcing loop retry
BEGIN;
INSERT INTO test_spec_multi VALUES (1, 20) ON CONFLICT DO NOTHING;
INSERT INTO test_spec_multi VALUES (2, 10) ON CONFLICT DO NOTHING;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_spec_multi CASCADE;

