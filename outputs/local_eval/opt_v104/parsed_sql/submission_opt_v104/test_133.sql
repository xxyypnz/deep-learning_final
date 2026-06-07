-- ===== Commit 133 =====
-- Source:  - 

-- --- Test Case 1 ---
-- Setup: create a table that uses a TransactionId list internally (e.g., via logical replication)
CREATE TABLE test_xid_list (id INT);
-- Insert a row to trigger logical replication tracking (if enabled)
INSERT INTO test_xid_list VALUES (1);
-- Force use of lappend_xid by creating a logical replication slot (requires wal_level=logical)
SELECT pg_create_logical_replication_slot('test_slot', 'pgoutput');
-- Execution: the slot creation will internally use lappend_xid for streamed_txns
SELECT slot_name, active FROM pg_replication_slots WHERE slot_name = 'test_slot';
-- Teardown
SELECT pg_drop_replication_slot('test_slot');
DROP TABLE IF EXISTS test_xid_list CASCADE;

-- --- Test Case 2 ---
-- Setup: create a table and a replication slot to generate an XidList
CREATE TABLE test_xid_member (id INT);
INSERT INTO test_xid_member VALUES (1);
SELECT pg_create_logical_replication_slot('test_slot2', 'pgoutput');
-- Execution: query pg_replication_slots which internally calls list_member_xid
SELECT slot_name, active FROM pg_replication_slots WHERE slot_name = 'test_slot2';
-- Teardown
SELECT pg_drop_replication_slot('test_slot2');
DROP TABLE IF EXISTS test_xid_member CASCADE;

-- --- Test Case 3 ---
-- Setup: create a table and a replication slot to trigger initial XidList creation
CREATE TABLE test_xid_empty (id INT);
INSERT INTO test_xid_empty VALUES (1);
SELECT pg_create_logical_replication_slot('test_slot3', 'pgoutput');
-- Execution: the first transaction tracked will create a new XidList via new_list
SELECT slot_name, active FROM pg_replication_slots WHERE slot_name = 'test_slot3';
-- Teardown
SELECT pg_drop_replication_slot('test_slot3');
DROP TABLE IF EXISTS test_xid_empty CASCADE;

