-- ============================================================================
-- Course: BCSE302P - Database Systems Laboratory
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Student: Sayan Giri (Reg No: 24BCT0281)
-- Script 01: Relational Schema DDL & Constraints
-- Target DBMS: Oracle Database 21c XE
-- ============================================================================

-- Clean up existing objects if any
BEGIN
  FOR cur_rec IN (SELECT table_name FROM user_tables WHERE table_name IN (
    'AUDIT_BILLING_LOG', 'BILLING_INVOICES', 'PATIENT_TEST_ORDERS', 
    'MEDICATIONS', 'DIAGNOSTIC_TESTS', 'APPOINTMENTS', 'INPATIENT_ADMISSIONS', 
    'BEDS', 'WARDS', 'PATIENTS', 'DOCTORS', 'DEPARTMENTS'
  )) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || cur_rec.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

-- ----------------------------------------------------------------------------
-- Table 1: DEPARTMENTS
-- ----------------------------------------------------------------------------
CREATE TABLE departments (
    dept_id          NUMBER(5) CONSTRAINT pk_departments PRIMARY KEY,
    dept_name        VARCHAR2(60) CONSTRAINT nn_dept_name NOT NULL CONSTRAINT uq_dept_name UNIQUE,
    building_block   VARCHAR2(20) CONSTRAINT nn_dept_block NOT NULL,
    head_doctor_name VARCHAR2(80),
    contact_phone    VARCHAR2(15) CONSTRAINT nn_dept_phone NOT NULL
);

-- ----------------------------------------------------------------------------
-- Table 2: DOCTORS
-- ----------------------------------------------------------------------------
CREATE TABLE doctors (
    doctor_id        NUMBER(6) CONSTRAINT pk_doctors PRIMARY KEY,
    first_name       VARCHAR2(40) CONSTRAINT nn_doc_fname NOT NULL,
    last_name        VARCHAR2(40) CONSTRAINT nn_doc_lname NOT NULL,
    dept_id          NUMBER(5) CONSTRAINT fk_doc_dept REFERENCES departments(dept_id) ON DELETE CASCADE,
    specialization   VARCHAR2(50) CONSTRAINT nn_doc_spec NOT NULL,
    phone            VARCHAR2(15) CONSTRAINT uq_doc_phone UNIQUE CONSTRAINT nn_doc_phone NOT NULL,
    email            VARCHAR2(60) CONSTRAINT uq_doc_email UNIQUE CONSTRAINT nn_doc_email NOT NULL,
    consultation_fee NUMBER(8, 2) CONSTRAINT chk_doc_fee CHECK (consultation_fee >= 0),
    shift_timing     VARCHAR2(30) DEFAULT '09:00 - 17:00' CONSTRAINT nn_doc_shift NOT NULL
);

-- ----------------------------------------------------------------------------
-- Table 3: PATIENTS
-- ----------------------------------------------------------------------------
CREATE TABLE patients (
    patient_id        NUMBER(8) CONSTRAINT pk_patients PRIMARY KEY,
    first_name        VARCHAR2(40) CONSTRAINT nn_pat_fname NOT NULL,
    last_name         VARCHAR2(40) CONSTRAINT nn_pat_lname NOT NULL,
    dob               DATE CONSTRAINT nn_pat_dob NOT NULL,
    gender            VARCHAR2(10) CONSTRAINT chk_pat_gender CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group       VARCHAR2(5) CONSTRAINT chk_pat_blood CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    phone             VARCHAR2(15) CONSTRAINT uq_pat_phone UNIQUE CONSTRAINT nn_pat_phone NOT NULL,
    emergency_contact VARCHAR2(15) CONSTRAINT nn_pat_emrg NOT NULL,
    address           VARCHAR2(120),
    insurance_provider VARCHAR2(60),
    insurance_policy_no VARCHAR2(40),
    created_at        DATE DEFAULT SYSDATE NOT NULL
);

-- ----------------------------------------------------------------------------
-- Table 4: WARDS
-- ----------------------------------------------------------------------------
CREATE TABLE wards (
    ward_id          NUMBER(4) CONSTRAINT pk_wards PRIMARY KEY,
    ward_name        VARCHAR2(50) CONSTRAINT nn_ward_name NOT NULL,
    ward_type        VARCHAR2(20) CONSTRAINT chk_ward_type CHECK (ward_type IN ('ICU', 'EMERGENCY', 'PRIVATE', 'SEMI-PRIVATE', 'GENERAL')),
    total_beds       NUMBER(4) CONSTRAINT chk_ward_beds CHECK (total_beds > 0),
    daily_charge     NUMBER(8, 2) CONSTRAINT chk_ward_charge CHECK (daily_charge >= 0)
);

-- ----------------------------------------------------------------------------
-- Table 5: BEDS
-- ----------------------------------------------------------------------------
CREATE TABLE beds (
    bed_id           NUMBER(6) CONSTRAINT pk_beds PRIMARY KEY,
    ward_id          NUMBER(4) CONSTRAINT fk_beds_ward REFERENCES wards(ward_id) ON DELETE CASCADE,
    bed_number       VARCHAR2(10) CONSTRAINT nn_bed_num NOT NULL,
    status           VARCHAR2(15) DEFAULT 'AVAILABLE' CONSTRAINT chk_bed_status CHECK (status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE')),
    CONSTRAINT uq_ward_bed UNIQUE (ward_id, bed_number)
);

-- ----------------------------------------------------------------------------
-- Table 6: INPATIENT_ADMISSIONS
-- ----------------------------------------------------------------------------
CREATE TABLE inpatient_admissions (
    admission_id     NUMBER(8) CONSTRAINT pk_admissions PRIMARY KEY,
    patient_id       NUMBER(8) CONSTRAINT fk_adm_patient REFERENCES patients(patient_id) ON DELETE CASCADE,
    bed_id           NUMBER(6) CONSTRAINT fk_adm_bed REFERENCES beds(bed_id),
    attending_doc_id NUMBER(6) CONSTRAINT fk_adm_doctor REFERENCES doctors(doctor_id),
    admission_date   DATE DEFAULT SYSDATE CONSTRAINT nn_adm_date NOT NULL,
    discharge_date   DATE,
    initial_diagnosis VARCHAR2(150) CONSTRAINT nn_adm_diag NOT NULL,
    admission_status VARCHAR2(15) DEFAULT 'ADMITTED' CONSTRAINT chk_adm_status CHECK (admission_status IN ('ADMITTED', 'DISCHARGED', 'TRANSFERRED')),
    CONSTRAINT chk_adm_dates CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

-- ----------------------------------------------------------------------------
-- Table 7: APPOINTMENTS
-- ----------------------------------------------------------------------------
CREATE TABLE appointments (
    appointment_id   NUMBER(8) CONSTRAINT pk_appointments PRIMARY KEY,
    patient_id       NUMBER(8) CONSTRAINT fk_apt_patient REFERENCES patients(patient_id) ON DELETE CASCADE,
    doctor_id        NUMBER(6) CONSTRAINT fk_apt_doctor REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    appointment_date DATE CONSTRAINT nn_apt_date NOT NULL,
    time_slot        VARCHAR2(20) CONSTRAINT nn_apt_slot NOT NULL,
    status           VARCHAR2(15) DEFAULT 'SCHEDULED' CONSTRAINT chk_apt_status CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED')),
    notes            VARCHAR2(200)
);

-- ----------------------------------------------------------------------------
-- Table 8: DIAGNOSTIC_TESTS
-- ----------------------------------------------------------------------------
CREATE TABLE diagnostic_tests (
    test_id          NUMBER(5) CONSTRAINT pk_diag_tests PRIMARY KEY,
    test_name        VARCHAR2(70) CONSTRAINT nn_test_name NOT NULL CONSTRAINT uq_test_name UNIQUE,
    category         VARCHAR2(40) CONSTRAINT nn_test_cat NOT NULL,
    standard_fee     NUMBER(8, 2) CONSTRAINT chk_test_fee CHECK (standard_fee >= 0)
);

-- ----------------------------------------------------------------------------
-- Table 9: PATIENT_TEST_ORDERS
-- ----------------------------------------------------------------------------
CREATE TABLE patient_test_orders (
    order_id         NUMBER(8) CONSTRAINT pk_test_orders PRIMARY KEY,
    admission_id     NUMBER(8) CONSTRAINT fk_ord_adm REFERENCES inpatient_admissions(admission_id) ON DELETE SET NULL,
    patient_id       NUMBER(8) CONSTRAINT fk_ord_patient REFERENCES patients(patient_id) ON DELETE CASCADE,
    test_id          NUMBER(5) CONSTRAINT fk_ord_test REFERENCES diagnostic_tests(test_id),
    order_date       DATE DEFAULT SYSDATE CONSTRAINT nn_ord_date NOT NULL,
    test_result      VARCHAR2(200),
    result_status    VARCHAR2(15) DEFAULT 'PENDING' CONSTRAINT chk_ord_status CHECK (result_status IN ('PENDING', 'COMPLETED', 'CANCELLED')),
    billed_amount    NUMBER(8, 2) CONSTRAINT chk_ord_fee CHECK (billed_amount >= 0)
);

-- ----------------------------------------------------------------------------
-- Table 10: MEDICATIONS
-- ----------------------------------------------------------------------------
CREATE TABLE medications (
    med_id           NUMBER(5) CONSTRAINT pk_medications PRIMARY KEY,
    med_name         VARCHAR2(70) CONSTRAINT nn_med_name NOT NULL CONSTRAINT uq_med_name UNIQUE,
    category         VARCHAR2(40) CONSTRAINT nn_med_cat NOT NULL,
    unit_price       NUMBER(8, 2) CONSTRAINT chk_med_price CHECK (unit_price >= 0),
    stock_quantity   NUMBER(5) CONSTRAINT chk_med_stock CHECK (stock_quantity >= 0)
);

-- ----------------------------------------------------------------------------
-- Table 11: BILLING_INVOICES
-- ----------------------------------------------------------------------------
CREATE TABLE billing_invoices (
    invoice_id       NUMBER(8) CONSTRAINT pk_invoices PRIMARY KEY,
    admission_id     NUMBER(8) CONSTRAINT fk_inv_adm REFERENCES inpatient_admissions(admission_id),
    patient_id       NUMBER(8) CONSTRAINT fk_inv_patient REFERENCES patients(patient_id),
    invoice_date     DATE DEFAULT SYSDATE CONSTRAINT nn_inv_date NOT NULL,
    room_charges     NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_room CHECK (room_charges >= 0),
    doctor_fees      NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_doc CHECK (doctor_fees >= 0),
    test_charges     NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_test CHECK (test_charges >= 0),
    pharmacy_charges NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_pharm CHECK (pharmacy_charges >= 0),
    gross_total      NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_gross CHECK (gross_total >= 0),
    discount_amount  NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_disc CHECK (discount_amount >= 0),
    insurance_paid   NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_ins CHECK (insurance_paid >= 0),
    net_payable      NUMBER(10, 2) DEFAULT 0 CONSTRAINT chk_inv_net CHECK (net_payable >= 0),
    payment_status   VARCHAR2(15) DEFAULT 'PENDING' CONSTRAINT chk_inv_status CHECK (payment_status IN ('PENDING', 'PARTIAL', 'PAID')),
    payment_mode     VARCHAR2(20) DEFAULT 'CASH' CONSTRAINT chk_inv_mode CHECK (payment_mode IN ('CASH', 'CREDIT_CARD', 'DEBIT_CARD', 'UPI', 'INSURANCE_CLAIM'))
);

-- ----------------------------------------------------------------------------
-- Table 12: AUDIT_BILLING_LOG
-- ----------------------------------------------------------------------------
CREATE TABLE audit_billing_log (
    audit_id         NUMBER(10) CONSTRAINT pk_audit_billing PRIMARY KEY,
    invoice_id       NUMBER(8) CONSTRAINT nn_aud_inv NOT NULL,
    old_net_payable  NUMBER(10, 2),
    new_net_payable  NUMBER(10, 2),
    old_status       VARCHAR2(15),
    new_status       VARCHAR2(15),
    action_type      VARCHAR2(15) CONSTRAINT nn_aud_action NOT NULL,
    modified_by      VARCHAR2(50) DEFAULT USER NOT NULL,
    modified_at      DATE DEFAULT SYSDATE NOT NULL
);

-- Sequences for ID Generation (Silent cleanup)
BEGIN
  FOR seq_rec IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN (
    'SEQ_DEPARTMENT_ID', 'SEQ_DOCTOR_ID', 'SEQ_PATIENT_ID', 'SEQ_WARD_ID',
    'SEQ_BED_ID', 'SEQ_ADMISSION_ID', 'SEQ_APPOINTMENT_ID', 'SEQ_TEST_ID',
    'SEQ_ORDER_ID', 'SEQ_MED_ID', 'SEQ_INVOICE_ID', 'SEQ_AUDIT_ID'
  )) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seq_rec.sequence_name;
  END LOOP;
END;
/

CREATE SEQUENCE seq_department_id START WITH 100 INCREMENT BY 10;
CREATE SEQUENCE seq_doctor_id START WITH 150 INCREMENT BY 1;
CREATE SEQUENCE seq_patient_id START WITH 1100 INCREMENT BY 1;
CREATE SEQUENCE seq_ward_id START WITH 250 INCREMENT BY 1;
CREATE SEQUENCE seq_bed_id START WITH 350 INCREMENT BY 1;
CREATE SEQUENCE seq_admission_id START WITH 5100 INCREMENT BY 1;
CREATE SEQUENCE seq_appointment_id START WITH 7100 INCREMENT BY 1;
CREATE SEQUENCE seq_test_id START WITH 450 INCREMENT BY 1;
CREATE SEQUENCE seq_order_id START WITH 8100 INCREMENT BY 1;
CREATE SEQUENCE seq_med_id START WITH 650 INCREMENT BY 1;
CREATE SEQUENCE seq_invoice_id START WITH 9100 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_id START WITH 100 INCREMENT BY 1;

COMMIT;
