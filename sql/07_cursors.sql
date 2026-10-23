-- ============================================================================
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Script 07: PL/SQL Cursors (Explicit & Parameterized)
-- ============================================================================

SET SERVEROUTPUT ON SIZE 1000000;

-- ----------------------------------------------------------------------------
-- Cursor Block 1: Parameterized Explicit Cursor
-- Purpose: Generates daily outpatient consultation roster for a specific doctor.
-- Iterates row-by-row across appointments scheduled for the specified date.
-- ----------------------------------------------------------------------------
DECLARE
    -- Parameterized Cursor definition
    CURSOR c_doc_appointments (
        p_doctor_id NUMBER,
        p_date      DATE
    ) IS
        SELECT a.appointment_id,
               p.first_name || ' ' || p.last_name AS patient_name,
               p.phone,
               p.blood_group,
               a.time_slot,
               a.notes
        FROM appointments a
        JOIN patients p ON a.patient_id = p.patient_id
        WHERE a.doctor_id = p_doctor_id
          AND TRUNC(a.appointment_date) = TRUNC(p_date)
          AND a.status = 'SCHEDULED'
        ORDER BY a.time_slot;

    -- Record variable based on cursor rowtype
    v_apt_rec c_doc_appointments%ROWTYPE;
    
    v_target_doc_id NUMBER := 102;
    v_target_date   DATE   := TO_DATE('2026-10-18', 'YYYY-MM-DD');
    v_doc_name      VARCHAR2(80);
    v_dept_name     VARCHAR2(60);
    v_count         NUMBER := 0;
BEGIN
    SELECT d.first_name || ' ' || d.last_name, dept.dept_name
    INTO v_doc_name, v_dept_name
    FROM doctors d
    JOIN departments dept ON d.dept_id = dept.dept_id
    WHERE d.doctor_id = v_target_doc_id;

    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('PULSECARE HOSPITAL - DAILY OUTPATIENT ROSTER (PARAMETERIZED CURSOR)');
    DBMS_OUTPUT.PUT_LINE('Doctor: Dr. ' || v_doc_name || ' | Department: ' || v_dept_name);
    DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(v_target_date, 'DD-MON-YYYY (Day)'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('APT ID', 8) || RPAD('TIME SLOT', 16) || RPAD('PATIENT NAME', 22) || RPAD('CONTACT', 14) || 'NOTES');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');

    -- Open cursor with explicit parameters
    OPEN c_doc_appointments(v_target_doc_id, v_target_date);
    LOOP
        FETCH c_doc_appointments INTO v_apt_rec;
        EXIT WHEN c_doc_appointments%NOTFOUND;

        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(v_apt_rec.appointment_id), 8) ||
            RPAD(v_apt_rec.time_slot, 16) ||
            RPAD(v_apt_rec.patient_name || ' (' || v_apt_rec.blood_group || ')', 22) ||
            RPAD(v_apt_rec.phone, 14) ||
            v_apt_rec.notes
        );
    END LOOP;
    CLOSE c_doc_appointments;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No scheduled appointments found for this doctor on the selected date.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('Total Consultations Queued: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('================================================================================');
END;
/

-- ----------------------------------------------------------------------------
-- Cursor Block 2: Explicit Cursor with Cursor FOR Loop & Financial Analytics
-- Purpose: Computes row-by-row ward occupancy metrics and daily revenue yield.
-- ----------------------------------------------------------------------------
DECLARE
    -- Cursor joining wards with aggregated bed occupancy
    CURSOR c_ward_analytics IS
        SELECT w.ward_id,
               w.ward_name,
               w.ward_type,
               w.daily_charge,
               w.total_beds,
               NVL(b_stats.occupied_count, 0) AS occupied_beds,
               NVL(b_stats.available_count, 0) AS available_beds
        FROM wards w
        LEFT JOIN (
            SELECT ward_id,
                   COUNT(CASE WHEN status = 'OCCUPIED' THEN 1 END) AS occupied_count,
                   COUNT(CASE WHEN status = 'AVAILABLE' THEN 1 END) AS available_count
            FROM beds
            GROUP BY ward_id
        ) b_stats ON w.ward_id = b_stats.ward_id
        ORDER BY w.ward_id;

    v_occupancy_rate NUMBER(5, 2);
    v_daily_revenue  NUMBER(10, 2);
    v_total_revenue  NUMBER(10, 2) := 0;
    v_total_occupied NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('PULSECARE HOSPITAL - WARD BED OCCUPANCY & REVENUE ANALYTICS (CURSOR FOR LOOP)');
    DBMS_OUTPUT.PUT_LINE('Generated on: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('WARD ID', 9) || 
        RPAD('WARD NAME', 28) || 
        RPAD('TYPE', 14) || 
        RPAD('BEDS', 8) || 
        RPAD('OCCUPIED', 10) || 
        RPAD('RATE (%)', 10) || 
        'DAILY REV (Rs.)'
    );
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');

    FOR r IN c_ward_analytics LOOP
        IF r.total_beds > 0 THEN
            v_occupancy_rate := ROUND((r.occupied_beds / r.total_beds) * 100, 2);
        ELSE
            v_occupancy_rate := 0;
        END IF;

        v_daily_revenue := r.occupied_beds * r.daily_charge;
        v_total_revenue := v_total_revenue + v_daily_revenue;
        v_total_occupied := v_total_occupied + r.occupied_beds;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(r.ward_id), 9) ||
            RPAD(SUBSTR(r.ward_name, 1, 26), 28) ||
            RPAD(r.ward_type, 14) ||
            RPAD(TO_CHAR(r.total_beds), 8) ||
            RPAD(TO_CHAR(r.occupied_beds), 10) ||
            RPAD(TO_CHAR(v_occupancy_rate, '990.99') || '%', 10) ||
            TO_CHAR(v_daily_revenue, '999,990.00')
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total Inpatients Currently Hospitalized: ' || v_total_occupied);
    DBMS_OUTPUT.PUT_LINE('Total Projected Daily Inpatient Bed Revenue: Rs. ' || TO_CHAR(v_total_revenue, '999,990.00'));
    DBMS_OUTPUT.PUT_LINE('================================================================================');
END;
/
