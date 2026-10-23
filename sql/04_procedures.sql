-- ============================================================================
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Script 04: PL/SQL Stored Procedures
-- ============================================================================

-- Procedure 1: sp_admit_patient
-- Performs atomic inpatient admission: validates bed availability, assigns bed,
-- logs the clinical admission, updates bed status, and commits transaction safely.
CREATE OR REPLACE PROCEDURE sp_admit_patient (
    p_patient_id     IN  NUMBER,
    p_bed_id         IN  NUMBER,
    p_doctor_id      IN  NUMBER,
    p_diagnosis      IN  VARCHAR2,
    p_admission_id   OUT NUMBER,
    p_status_message OUT VARCHAR2
) IS
    v_bed_status     VARCHAR2(15);
    v_patient_exists NUMBER := 0;
    v_doctor_exists  NUMBER := 0;
    ex_bed_not_free  EXCEPTION;
    ex_invalid_data  EXCEPTION;
BEGIN
    -- Validate Patient existence
    SELECT COUNT(*) INTO v_patient_exists FROM patients WHERE patient_id = p_patient_id;
    IF v_patient_exists = 0 THEN
        p_status_message := 'ERROR: Patient ID ' || p_patient_id || ' does not exist.';
        RAISE ex_invalid_data;
    END IF;

    -- Validate Doctor existence
    SELECT COUNT(*) INTO v_doctor_exists FROM doctors WHERE doctor_id = p_doctor_id;
    IF v_doctor_exists = 0 THEN
        p_status_message := 'ERROR: Doctor ID ' || p_doctor_id || ' does not exist.';
        RAISE ex_invalid_data;
    END IF;

    -- Validate Bed Availability
    BEGIN
        SELECT status INTO v_bed_status FROM beds WHERE bed_id = p_bed_id FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status_message := 'ERROR: Bed ID ' || p_bed_id || ' does not exist.';
            RAISE ex_invalid_data;
    END;

    IF v_bed_status <> 'AVAILABLE' THEN
        p_status_message := 'ERROR: Bed ID ' || p_bed_id || ' is currently ' || v_bed_status || ' and cannot be assigned.';
        RAISE ex_bed_not_free;
    END IF;

    -- Generate new Admission ID
    SELECT seq_admission_id.NEXTVAL INTO p_admission_id FROM dual;

    -- Insert Inpatient Admission record
    INSERT INTO inpatient_admissions (
        admission_id, patient_id, bed_id, attending_doc_id, 
        admission_date, discharge_date, initial_diagnosis, admission_status
    ) VALUES (
        p_admission_id, p_patient_id, p_bed_id, p_doctor_id,
        SYSDATE, NULL, p_diagnosis, 'ADMITTED'
    );

    -- Update bed status to OCCUPIED
    UPDATE beds SET status = 'OCCUPIED' WHERE bed_id = p_bed_id;

    COMMIT;
    p_status_message := 'SUCCESS: Patient ' || p_patient_id || ' admitted under Admission #' || p_admission_id || ' into Bed ' || p_bed_id;
EXCEPTION
    WHEN ex_bed_not_free OR ex_invalid_data THEN
        ROLLBACK;
    WHEN OTHERS THEN
        ROLLBACK;
        p_status_message := 'ERROR: Admission transaction failed - ' || SQLERRM;
END sp_admit_patient;
/

-- Procedure 2: sp_discharge_patient
-- Completes patient discharge, calculates final inpatient bill, frees the bed,
-- generates formal billing invoice, and commits transaction.
CREATE OR REPLACE PROCEDURE sp_discharge_patient (
    p_admission_id   IN  NUMBER,
    p_payment_mode   IN  VARCHAR2,
    p_invoice_id     OUT NUMBER,
    p_final_bill     OUT NUMBER,
    p_status_message OUT VARCHAR2
) IS
    v_bed_id         NUMBER;
    v_patient_id     NUMBER;
    v_adm_status     VARCHAR2(15);
    v_calc_bill      NUMBER(10, 2);
    ex_not_admitted  EXCEPTION;
BEGIN
    -- Verify admission record
    BEGIN
        SELECT bed_id, patient_id, admission_status 
        INTO v_bed_id, v_patient_id, v_adm_status
        FROM inpatient_admissions
        WHERE admission_id = p_admission_id
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status_message := 'ERROR: Admission ID ' || p_admission_id || ' not found.';
            p_invoice_id := NULL;
            p_final_bill := 0;
            RETURN;
    END;

    IF v_adm_status <> 'ADMITTED' THEN
        p_status_message := 'ERROR: Patient is not currently admitted (Status: ' || v_adm_status || ').';
        RAISE ex_not_admitted;
    END IF;

    -- Update Admission with discharge timestamp
    UPDATE inpatient_admissions
    SET discharge_date = SYSDATE,
        admission_status = 'DISCHARGED'
    WHERE admission_id = p_admission_id;

    -- Free the assigned bed
    UPDATE beds SET status = 'AVAILABLE' WHERE bed_id = v_bed_id;

    -- Compute final bill using stored function
    v_calc_bill := fn_calculate_inpatient_bill(p_admission_id);
    p_final_bill := v_calc_bill;

    -- Generate Billing Invoice
    SELECT seq_invoice_id.NEXTVAL INTO p_invoice_id FROM dual;

    INSERT INTO billing_invoices (
        invoice_id, admission_id, patient_id, invoice_date,
        room_charges, doctor_fees, test_charges, pharmacy_charges,
        gross_total, discount_amount, insurance_paid, net_payable,
        payment_status, payment_mode
    ) VALUES (
        p_invoice_id, p_admission_id, v_patient_id, SYSDATE,
        ROUND(v_calc_bill * 0.50, 2), ROUND(v_calc_bill * 0.20, 2),
        ROUND(v_calc_bill * 0.20, 2), ROUND(v_calc_bill * 0.10, 2),
        ROUND(v_calc_bill * 1.20, 2), 0.00,
        ROUND(v_calc_bill * 0.20, 2), v_calc_bill,
        'PAID', NVL(p_payment_mode, 'CASH')
    );

    COMMIT;
    p_status_message := 'SUCCESS: Patient discharged successfully. Invoice #' || p_invoice_id || ' generated for Rs. ' || v_calc_bill;
EXCEPTION
    WHEN ex_not_admitted THEN
        ROLLBACK;
    WHEN OTHERS THEN
        ROLLBACK;
        p_status_message := 'ERROR: Discharge transaction failed - ' || SQLERRM;
        p_invoice_id := NULL;
        p_final_bill := 0;
END sp_discharge_patient;
/

-- Procedure 3: sp_schedule_appointment
-- Books doctor appointment with pre-validation to avoid scheduling collisions.
CREATE OR REPLACE PROCEDURE sp_schedule_appointment (
    p_patient_id     IN  NUMBER,
    p_doctor_id      IN  NUMBER,
    p_date           IN  DATE,
    p_time_slot      IN  VARCHAR2,
    p_notes          IN  VARCHAR2,
    p_appointment_id OUT NUMBER,
    p_status_message OUT VARCHAR2
) IS
    v_avail VARCHAR2(20);
BEGIN
    -- Check doctor availability
    v_avail := fn_check_doctor_availability(p_doctor_id, p_date, p_time_slot);

    IF v_avail <> 'AVAILABLE' THEN
        p_appointment_id := NULL;
        p_status_message := 'ERROR: Doctor ' || p_doctor_id || ' is already booked for ' || p_time_slot || ' on ' || TO_CHAR(p_date, 'YYYY-MM-DD');
        RETURN;
    END IF;

    SELECT seq_appointment_id.NEXTVAL INTO p_appointment_id FROM dual;

    INSERT INTO appointments (
        appointment_id, patient_id, doctor_id, appointment_date, time_slot, status, notes
    ) VALUES (
        p_appointment_id, p_patient_id, p_doctor_id, p_date, p_time_slot, 'SCHEDULED', p_notes
    );

    COMMIT;
    p_status_message := 'SUCCESS: Appointment #' || p_appointment_id || ' booked successfully.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_appointment_id := NULL;
        p_status_message := 'ERROR: Booking failed - ' || SQLERRM;
END sp_schedule_appointment;
/

COMMIT;
