-- ===== Commit 148 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS test_subxact CASCADE;
CREATE TABLE test_subxact (id INT);
BEGIN;
INSERT INTO test_subxact VALUES (1);
SAVEPOINT sp1;
INSERT INTO test_subxact VALUES (2);
SAVEPOINT sp2;
INSERT INTO test_subxact VALUES (3);
RELEASE SAVEPOINT sp2;
RELEASE SAVEPOINT sp1;
COMMIT;
SELECT count(*) FROM test_subxact;
DROP TABLE IF EXISTS test_subxact CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS test_no_subxact CASCADE;
CREATE TABLE test_no_subxact (id INT);
BEGIN;
INSERT INTO test_no_subxact VALUES (1);
COMMIT;
SELECT count(*) FROM test_no_subxact;
DROP TABLE IF EXISTS test_no_subxact CASCADE;

-- --- Test Case 3 ---
DROP TABLE IF EXISTS test_many_subxact CASCADE;
CREATE TABLE test_many_subxact (id INT);
BEGIN;
INSERT INTO test_many_subxact VALUES (1);
SAVEPOINT sp1;
INSERT INTO test_many_subxact VALUES (2);
SAVEPOINT sp2;
INSERT INTO test_many_subxact VALUES (3);
SAVEPOINT sp3;
INSERT INTO test_many_subxact VALUES (4);
RELEASE SAVEPOINT sp3;
RELEASE SAVEPOINT sp2;
RELEASE SAVEPOINT sp1;
COMMIT;
SELECT count(*) FROM test_many_subxact;
DROP TABLE IF EXISTS test_many_subxact CASCADE;

