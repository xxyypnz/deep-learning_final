-- ===== Commit 126 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS test_shutdown1 CASCADE;
CREATE TABLE test_shutdown1 (id INT);
INSERT INTO test_shutdown1 VALUES (1), (2), (3);

-- Execution: Force a query that triggers ExecShutdownNode during cleanup
BEGIN;
DECLARE c1 CURSOR FOR SELECT * FROM test_shutdown1;
FETCH ALL FROM c1;
CLOSE c1;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_shutdown1 CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS test_shutdown2 CASCADE;
CREATE TABLE test_shutdown2 (a INT, b INT);
INSERT INTO test_shutdown2 VALUES (1, 10), (2, 20);

-- Execution: Use subquery to create SubqueryScan plan node
BEGIN;
DECLARE c2 CURSOR FOR SELECT * FROM (SELECT a, b FROM test_shutdown2) sub;
FETCH ALL FROM c2;
CLOSE c2;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_shutdown2 CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS test_shutdown3a CASCADE;
DROP TABLE IF EXISTS test_shutdown3b CASCADE;
CREATE TABLE test_shutdown3a (x INT);
CREATE TABLE test_shutdown3b (x INT);
INSERT INTO test_shutdown3a VALUES (1), (2);
INSERT INTO test_shutdown3b VALUES (3), (4);

-- Execution: Use UNION ALL to create Append plan node
BEGIN;
DECLARE c3 CURSOR FOR SELECT x FROM test_shutdown3a UNION ALL SELECT x FROM test_shutdown3b;
FETCH ALL FROM c3;
CLOSE c3;
COMMIT;

-- Teardown
DROP TABLE IF EXISTS test_shutdown3a CASCADE;
DROP TABLE IF EXISTS test_shutdown3b CASCADE;

