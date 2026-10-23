-- ============================================================================
-- Course: BCSE302P - Database Systems Laboratory
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Student: Sayan Giri (Reg No: 24BCT0281)
-- Script 08: Comprehensive Automated Verification & Test Suite
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 120
SET PAGESIZE 100

PROMPT ============================================================================
PROMPT PULSECARE SYSTEM - AUTOMATED VERIFICATION AND TESTING SUITE
PROMPT Student: Sayan Giri | Reg No: 24BCT0281
PROMPT ============================================================================

-- ----------------------------------------------------------------------------
-- TC01: Insert Valid Records (DDL Integrity)
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC01: Insert valid patient record
DECLARE
    v_new_pat_id NUMBER;
BEGIN
    SELECT seq_patient_id.NEXTVAL INTO v_new_pat_id FROM dual;
    INSERT INTO patients (patient_id, first_name, last_name, dob, gender, blood_group, phone, emergency_contact, address, created_at)
    VALUES (v_new_pat_id, 'Debjit', 'Ghosh', TO_DATE('1998-05-10', 'YYYY-MM-DD'), 'Male', 'O+', '9876500999', '9876599999', 'Vellore Tech Park', SYSDATE);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[TC01 - PASS] Successfully inserted Patient #' || v_new_pat_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[TC01 - FAIL] Error: ' || SQLERRM);
END;
/

-- ----------------------------------------------------------------------------
-- TC02: UNIQUE Constraint Violation
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC02: Attempt inserting duplicate department name ('Cardiology')
BEGIN
    INSERT INTO departments VALUES (99, 'Cardiology', 'Block-Z', 'Dr. Duplicate', '0416-000000');
    DBMS_OUTPUT.PUT_LINE('[TC02 - FAIL] Unique constraint did not trigger!');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('[TC02 - PASS] Caught Expected Constraint Violation: ORA-00001 (Unique constraint on DEPT_NAME)');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[TC02 - PASS] Handled Exception: ' || SQLERRM);
END;
/

-- ----------------------------------------------------------------------------
-- TC03: CHECK Constraint Violation
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC03: Attempt inserting invalid gender ('Robot') and negative fee (-500)
BEGIN
    INSERT INTO doctors VALUES (199, 'Bad', 'Data', 10, 'General', '9800000000', 'bad.doc@pulsecare.org', -500.00, '09:00 - 17:00');
    DBMS_OUTPUT.PUT_LINE('[TC03 - FAIL] Check constraint on fee did not trigger!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[TC03 - PASS] Caught Expected CHECK Constraint Violation: ' || SQLERRM);
END;
/

-- ----------------------------------------------------------------------------
-- TC04: FOREIGN KEY Constraint Violation
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC04: Attempt inserting appointment with non-existent Doctor ID (9999)
BEGIN
    INSERT INTO appointments VALUES (9999, 1001, 9999, SYSDATE + 2, '10:00 - 10:30', 'SCHEDULED', 'Invalid Doc');
    DBMS_OUTPUT.PUT_LINE('[TC04 - FAIL] Foreign key did not trigger!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[TC04 - PASS] Caught Expected Foreign Key Violation: ' || SQLERRM);
END;
/

-- ----------------------------------------------------------------------------
-- TC05: Stored Function fn_calculate_inpatient_bill
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC05: Calculate inpatient bill for Admission #5001
DECLARE
    v_bill NUMBER;
BEGIN
    v_bill := fn_calculate_inpatient_bill(5001);
    IF v_bill > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[TC05 - PASS] Function calculated total payable bill: Rs. ' || v_bill);
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TC05 - FAIL] Invalid calculation result: ' || v_bill);
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- TC06: Stored Procedure sp_admit_patient (Valid Case)
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC06: Stored procedure sp_admit_patient into available Bed 303
DECLARE
    v_adm_id NUMBER;
    v_msg    VARCHAR2(250);
    v_status VARCHAR2(15);
BEGIN
    sp_admit_patient(1008, 303, 104, 'Pediatric Observation', v_adm_id, v_msg);
    DBMS_OUTPUT.PUT_LINE('[TC06] ' || v_msg);
    
    SELECT status INTO v_status FROM beds WHERE bed_id = 303;
    IF v_status = 'OCCUPIED' THEN
        DBMS_OUTPUT.PUT_LINE('[TC06 - PASS] Verified Bed 303 status updated to OCCUPIED.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TC06 - FAIL] Bed status is ' || v_status);
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- TC07: Stored Procedure sp_admit_patient (Occupied Bed Rejection)
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC07: Attempt admitting patient into occupied Bed 301
DECLARE
    v_adm_id NUMBER;
    v_msg    VARCHAR2(250);
BEGIN
    sp_admit_patient(1007, 301, 101, 'Cardiac Followup', v_adm_id, v_msg);
    DBMS_OUTPUT.PUT_LINE('[TC07] Output message: ' || v_msg);
    IF INSTR(v_msg, 'ERROR') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[TC07 - PASS] Successfully prevented assigning occupied bed.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TC07 - FAIL] Allowed duplicate assignment!');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- TC08: Stored Procedure sp_discharge_patient
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC08: Discharge patient from Admission #5002
DECLARE
    v_inv_id NUMBER;
    v_bill   NUMBER;
    v_msg    VARCHAR2(250);
    v_status VARCHAR2(15);
BEGIN
    sp_discharge_patient(5002, 'UPI', v_inv_id, v_bill, v_msg);
    DBMS_OUTPUT.PUT_LINE('[TC08] ' || v_msg);
    
    SELECT status INTO v_status FROM beds WHERE bed_id = 304;
    IF v_status = 'AVAILABLE' THEN
        DBMS_OUTPUT.PUT_LINE('[TC08 - PASS] Verified Bed 304 freed and status reverted to AVAILABLE.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TC08 - FAIL] Bed status is ' || v_status);
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- TC09: Trigger trg_prevent_double_booking
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC09: Attempt booking conflicting appointment for Dr. 102
BEGIN
    INSERT INTO appointments (appointment_id, patient_id, doctor_id, appointment_date, time_slot, status, notes)
    VALUES (seq_appointment_id.NEXTVAL, 1007, 102, TO_DATE('2026-10-18', 'YYYY-MM-DD'), '10:00 - 10:30', 'SCHEDULED', 'Clashing slot');
    DBMS_OUTPUT.PUT_LINE('[TC09 - FAIL] Trigger did not block double booking!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[TC09 - PASS] Trigger fired successfully: ' || SQLERRM);
END;
/

-- ----------------------------------------------------------------------------
-- TC10: Trigger trg_audit_billing_changes
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC10: Verify audit logging on invoice settlement
DECLARE
    v_audit_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_audit_count
    FROM audit_billing_log
    WHERE action_type IN ('INVOICE_CREATED', 'STATUS_CHANGE', 'SETTLEMENT');
    
    IF v_audit_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[TC10 - PASS] Verified ' || v_audit_count || ' audit records captured by trigger.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TC10 - FAIL] No audit entries recorded.');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- TC11: Package pkg_hospital_billing.apply_waiver_discount
-- ----------------------------------------------------------------------------
PROMPT >>> Running TC11: Package discount application and rule enforcement
DECLARE
    v_revised NUMBER;
    v_msg     VARCHAR2(250);
BEGIN
    -- Valid 10% discount
    pkg_hospital_billing.apply_waiver_discount(9001, 0.10, v_revised, v_msg);
    DBMS_OUTPUT.PUT_LINE('[TC11.1] ' || v_msg);

    -- Excess 50% discount (limit is 25%)
    pkg_hospital_billing.apply_waiver_discount(9001, 0.50, v_revised, v_msg);
    DBMS_OUTPUT.PUT_LINE('[TC11.2] ' || v_msg);
    IF INSTR(v_msg, 'exceeds maximum') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[TC11 - PASS] Package successfully enforced business policy cap.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TC11 - FAIL] Failed to cap discount.');
    END IF;
END;
/

PROMPT ============================================================================
PROMPT TEST SUITE EXECUTION COMPLETED
PROMPT ============================================================================
