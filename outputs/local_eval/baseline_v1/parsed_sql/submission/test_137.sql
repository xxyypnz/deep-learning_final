-- ===== Commit 137 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup
DROP TABLE IF EXISTS zero_col_tab CASCADE;
CREATE TABLE zero_col_tab ();  -- zero-column table
INSERT INTO zero_col_tab DEFAULT VALUES;

-- Execution: Use VALUES with a zero-column subquery via tab.* expansion
SELECT * FROM (VALUES ((SELECT * FROM zero_col_tab))) AS v;

-- Teardown
DROP TABLE IF EXISTS zero_col_tab CASCADE;

-- --- Test Case 2 ---
-- Setup
DROP TABLE IF EXISTS multi_col_tab CASCADE;
CREATE TABLE multi_col_tab (a INT, b TEXT);
INSERT INTO multi_col_tab VALUES (1, 'one'), (2, 'two');

-- Execution: Use VALUES with multiple rows and columns
SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS v(x, y);

-- Teardown
DROP TABLE IF EXISTS multi_col_tab CASCADE;

-- --- Test Case 3 ---
-- Setup
DROP TABLE IF EXISTS single_col_tab CASCADE;
CREATE TABLE single_col_tab (x INT);
INSERT INTO single_col_tab VALUES (42);

-- Execution: Use VALUES with a single row and column
SELECT * FROM (VALUES (42)) AS v(x);

-- Teardown
DROP TABLE IF EXISTS single_col_tab CASCADE;

