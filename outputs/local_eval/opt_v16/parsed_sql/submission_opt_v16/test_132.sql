-- ===== Commit 132 =====
-- Source:  - 

-- --- Test Case 1 ---
DROP TABLE IF EXISTS lock_a CASCADE;
DROP TABLE IF EXISTS lock_b CASCADE;
CREATE TABLE lock_a (id int);
CREATE TABLE lock_b (id int);
SELECT * FROM lock_a JOIN lock_b ON true FOR UPDATE OF unnamed_join;
DROP TABLE IF EXISTS lock_a CASCADE;
DROP TABLE IF EXISTS lock_b CASCADE;

-- --- Test Case 2 ---
DROP TABLE IF EXISTS lock_a2 CASCADE;
DROP TABLE IF EXISTS lock_b2 CASCADE;
DROP TABLE IF EXISTS lock_c2 CASCADE;
CREATE TABLE lock_a2 (id int);
CREATE TABLE lock_b2 (id int);
CREATE TABLE lock_c2 (id int);
SELECT * FROM lock_a2 JOIN lock_b2 ON true, lock_c2 AS unnamed_join FOR UPDATE OF unnamed_join;
DROP TABLE IF EXISTS lock_a2 CASCADE;
DROP TABLE IF EXISTS lock_b2 CASCADE;
DROP TABLE IF EXISTS lock_c2 CASCADE;

-- --- Test Case 3 ---
DROP TABLE IF EXISTS lock_plain CASCADE;
CREATE TABLE lock_plain (id int);
INSERT INTO lock_plain VALUES (1);
SELECT * FROM lock_plain FOR UPDATE OF lock_plain;
DROP TABLE IF EXISTS lock_plain CASCADE;

