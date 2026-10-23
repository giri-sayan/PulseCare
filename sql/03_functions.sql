-- ============================================================================
-- Course: BCSE302P - Database Systems Laboratory
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Student: Sayan Giri (Reg No: 24BCT0281)
-- Script 03: PL/SQL Stored Functions
-- ============================================================================

-- Function 1: fn_calculate_inpatient_bill
-- Computes complete inpatient hospitalization cost factoring ward rate,
-- length of stay, doctor visits, diagnostic lab tests, and insurance discount.
CREATE OR REPLACE FUNCTION fn_calculate_inpatient_bill (
    p_admission_id IN NUMBER
) RETURN NUMBER IS
    v_adm_date        DATE;
    v_disch_date      DATE;
    v_daily_charge    NUMBER(8, 2);
    v_doc_fee         NUMBER(8, 2);
    v_days            NUMBER;
    v_room_cost       NUMBER(10, 2);
    v_doc_cost        NUMBER(10, 2);
    v_lab_cost        NUMBER(10, 2) := 0;
    v_gross_total     NUMBER(10, 2);
    v_insurance_cover NUMBER(10, 2) := 0;
    v_net_payable     NUMBER(10, 2);
    v_ins_provider    VARCHAR2(60);
BEGIN
    -- 1. Fetch admission and ward rate details
    SELECT a.admission_date, NVL(a.discharge_date, SYSDATE), w.daily_charge, d.consultation_fee, p.insurance_provider
    INTO v_adm_date, v_disch_date, v_daily_charge, v_doc_fee, v_ins_provider
    FROM inpatient_admissions a
    JOIN beds b ON a.bed_id = b.bed_id
    JOIN wards w ON b.ward_id = w.ward_id
    JOIN doctors d ON a.attending_doc_id = d.doctor_id
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.admission_id = p_admission_id;

    -- Compute days stayed (minimum 1 day)
    v_days := GREATEST(1, CEIL(v_disch_date - v_adm_date));

    -- Room and doctor visiting costs
    v_room_cost := v_days * v_daily_charge;
    v_doc_cost  := (v_doc_fee * 1.0) + ((v_days - 1) * (v_doc_fee * 0.40));

    -- 2. Aggregate diagnostic lab tests ordered during this admission
    SELECT NVL(SUM(billed_amount), 0)
    INTO v_lab_cost
    FROM patient_test_orders
    WHERE admission_id = p_admission_id
      AND result_status = 'COMPLETED';

    -- Gross total before coverage
    v_gross_total := v_room_cost + v_doc_cost + v_lab_cost;

    -- 3. Calculate insurance coverage if applicable
    IF v_ins_provider IS NOT NULL THEN
        -- 70% covered by approved health insurance policies
        v_insurance_cover := ROUND(v_gross_total * 0.70, 2);
    ELSE
        v_insurance_cover := 0;
    END IF;

    v_net_payable := v_gross_total - v_insurance_cover;

    RETURN v_net_payable;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Admission ID ' || p_admission_id || ' not found.');
        RETURN -1;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error calculating bill: ' || SQLERRM);
        RETURN -1;
END fn_calculate_inpatient_bill;
/

-- Function 2: fn_check_doctor_availability
-- Checks whether a doctor has an existing scheduled appointment for a given date and slot
CREATE OR REPLACE FUNCTION fn_check_doctor_availability (
    p_doctor_id IN NUMBER,
    p_date      IN DATE,
    p_slot      IN VARCHAR2
) RETURN VARCHAR2 IS
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND TRUNC(appointment_date) = TRUNC(p_date)
      AND time_slot = p_slot
      AND status = 'SCHEDULED';

    IF v_count = 0 THEN
        RETURN 'AVAILABLE';
    ELSE
        RETURN 'BUSY';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END fn_check_doctor_availability;
/

-- Function 3: fn_get_bed_occupancy_rate
-- Computes the current percentage of occupied beds across the entire hospital or in a ward
CREATE OR REPLACE FUNCTION fn_get_bed_occupancy_rate (
    p_ward_id IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    v_total_beds    NUMBER := 0;
    v_occupied_beds NUMBER := 0;
    v_rate          NUMBER(5, 2) := 0;
BEGIN
    IF p_ward_id IS NULL THEN
        SELECT COUNT(*), COUNT(CASE WHEN status = 'OCCUPIED' THEN 1 END)
        INTO v_total_beds, v_occupied_beds
        FROM beds;
    ELSE
        SELECT COUNT(*), COUNT(CASE WHEN status = 'OCCUPIED' THEN 1 END)
        INTO v_total_beds, v_occupied_beds
        FROM beds
        WHERE ward_id = p_ward_id;
    END IF;

    IF v_total_beds > 0 THEN
        v_rate := ROUND((v_occupied_beds / v_total_beds) * 100, 2);
    ELSE
        v_rate := 0.00;
    END IF;

    RETURN v_rate;
END fn_get_bed_occupancy_rate;
/

COMMIT;
