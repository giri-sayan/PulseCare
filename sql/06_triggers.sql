-- ============================================================================
-- Course: BCSE302P - Database Systems Laboratory
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Student: Sayan Giri (Reg No: 24BCT0281)
-- Script 06: PL/SQL Database Triggers
-- ============================================================================

-- Trigger 1: trg_audit_billing_changes
-- Triggering Event: AFTER INSERT OR UPDATE ON billing_invoices
-- Level: Row-Level (FOR EACH ROW)
-- Business Rule: Automatically records an audit trail in AUDIT_BILLING_LOG
-- whenever an invoice is created, updated, or settled, logging old and new balances.
CREATE OR REPLACE TRIGGER trg_audit_billing_changes
AFTER INSERT OR UPDATE ON billing_invoices
FOR EACH ROW
DECLARE
    v_action VARCHAR2(15);
BEGIN
    IF INSERTING THEN
        v_action := 'INVOICE_CREATED';
        INSERT INTO audit_billing_log (
            audit_id, invoice_id, old_net_payable, new_net_payable,
            old_status, new_status, action_type, modified_by, modified_at
        ) VALUES (
            seq_audit_id.NEXTVAL, :NEW.invoice_id, NULL, :NEW.net_payable,
            NULL, :NEW.payment_status, v_action, USER, SYSDATE
        );
    ELSIF UPDATING THEN
        IF :OLD.payment_status <> :NEW.payment_status THEN
            v_action := 'STATUS_CHANGE';
        ELSE
            v_action := 'AMOUNT_UPDATE';
        END IF;

        INSERT INTO audit_billing_log (
            audit_id, invoice_id, old_net_payable, new_net_payable,
            old_status, new_status, action_type, modified_by, modified_at
        ) VALUES (
            seq_audit_id.NEXTVAL, :NEW.invoice_id, :OLD.net_payable, :NEW.net_payable,
            :OLD.payment_status, :NEW.payment_status, v_action, USER, SYSDATE
        );
    END IF;
END trg_audit_billing_changes;
/

-- Trigger 2: trg_sync_bed_status
-- Triggering Event: AFTER INSERT OR UPDATE OF admission_status ON inpatient_admissions
-- Level: Row-Level (FOR EACH ROW)
-- Business Rule: Synchronizes the physical bed status with the clinical admission lifecycle.
-- Automatically marks the bed 'OCCUPIED' upon patient admission, and releases it as 'AVAILABLE' upon discharge.
CREATE OR REPLACE TRIGGER trg_sync_bed_status
AFTER INSERT OR UPDATE OF admission_status ON inpatient_admissions
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.admission_status = 'ADMITTED' THEN
            UPDATE beds
            SET status = 'OCCUPIED'
            WHERE bed_id = :NEW.bed_id;
        END IF;
    ELSIF UPDATING THEN
        IF :NEW.admission_status = 'DISCHARGED' THEN
            UPDATE beds
            SET status = 'AVAILABLE'
            WHERE bed_id = :NEW.bed_id;
        ELSIF :NEW.admission_status = 'ADMITTED' AND :OLD.admission_status <> 'ADMITTED' THEN
            UPDATE beds
            SET status = 'OCCUPIED'
            WHERE bed_id = :NEW.bed_id;
        END IF;
    END IF;
END trg_sync_bed_status;
/

-- Trigger 3: trg_prevent_double_booking
-- Triggering Event: BEFORE INSERT OR UPDATE ON appointments
-- Level: Compound Trigger (to prevent mutating-table ORA-04091 errors in Oracle)
-- Business Rule: Enforces that no doctor can be scheduled for overlapping appointments
-- on the same date and time slot.
CREATE OR REPLACE TRIGGER trg_prevent_double_booking
FOR INSERT OR UPDATE ON appointments
COMPOUND TRIGGER

    TYPE t_apt IS RECORD (
        doctor_id        NUMBER(6),
        appointment_date DATE,
        time_slot        VARCHAR2(20),
        appointment_id   NUMBER(8)
    );
    TYPE t_apt_list IS TABLE OF t_apt INDEX BY PLS_INTEGER;
    g_new_appointments t_apt_list;
    g_idx PLS_INTEGER := 0;

    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.status = 'SCHEDULED' THEN
            g_idx := g_idx + 1;
            g_new_appointments(g_idx).doctor_id := :NEW.doctor_id;
            g_new_appointments(g_idx).appointment_date := :NEW.appointment_date;
            g_new_appointments(g_idx).time_slot := :NEW.time_slot;
            g_new_appointments(g_idx).appointment_id := NVL(:NEW.appointment_id, -1);
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_clash_count NUMBER := 0;
    BEGIN
        FOR i IN 1..g_idx LOOP
            SELECT COUNT(*)
            INTO v_clash_count
            FROM appointments
            WHERE doctor_id = g_new_appointments(i).doctor_id
              AND TRUNC(appointment_date) = TRUNC(g_new_appointments(i).appointment_date)
              AND time_slot = g_new_appointments(i).time_slot
              AND appointment_id <> g_new_appointments(i).appointment_id
              AND status = 'SCHEDULED';

            IF v_clash_count > 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20001, 
                    'Double Booking Violation: Doctor #' || g_new_appointments(i).doctor_id || 
                    ' already has a scheduled appointment on ' || 
                    TO_CHAR(g_new_appointments(i).appointment_date, 'YYYY-MM-DD') || 
                    ' during slot ' || g_new_appointments(i).time_slot
                );
            END IF;
        END LOOP;
        g_idx := 0;
    END AFTER STATEMENT;

END trg_prevent_double_booking;
/

COMMIT;
