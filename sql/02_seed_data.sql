-- ============================================================================
-- Course: BCSE302P - Database Systems Laboratory
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Student: Sayan Giri (Reg No: 24BCT0281)
-- Script 02: Realistic Seed Data Insertion
-- ============================================================================

SET DEFINE OFF;
SET ECHO OFF;

-- 1. Departments
INSERT INTO departments VALUES (10, 'Cardiology', 'Block-A Level 3', 'Dr. Ramesh Sharma', '0416-220101');
INSERT INTO departments VALUES (20, 'Orthopedics', 'Block-B Level 2', 'Dr. Priya Sundaram', '0416-220102');
INSERT INTO departments VALUES (30, 'Neurology', 'Block-A Level 4', 'Dr. Ananya Roy', '0416-220103');
INSERT INTO departments VALUES (40, 'Pediatrics', 'Block-C Level 1', 'Dr. Rajesh Nair', '0416-220104');
INSERT INTO departments VALUES (50, 'General Medicine', 'Block-B Level 1', 'Dr. Suresh Varma', '0416-220105');
INSERT INTO departments VALUES (60, 'Emergency & Trauma', 'Block-E Ground', 'Dr. Arvind Swaminathan', '0416-220106');

-- 2. Doctors
INSERT INTO doctors VALUES (101, 'Ramesh', 'Sharma', 10, 'Interventional Cardiologist', '9840111221', 'ramesh.sharma@pulsecare.org', 1200.00, '09:00 - 15:00');
INSERT INTO doctors VALUES (102, 'Priya', 'Sundaram', 20, 'Joint Replacement Specialist', '9840111222', 'priya.sundaram@pulsecare.org', 1000.00, '10:00 - 16:00');
INSERT INTO doctors VALUES (103, 'Ananya', 'Roy', 30, 'Neurosurgeon', '9840111223', 'ananya.roy@pulsecare.org', 1500.00, '08:00 - 14:00');
INSERT INTO doctors VALUES (104, 'Rajesh', 'Nair', 40, 'Pediatric Consultant', '9840111224', 'rajesh.nair@pulsecare.org', 800.00, '11:00 - 17:00');
INSERT INTO doctors VALUES (105, 'Suresh', 'Varma', 50, 'Senior Physician', '9840111225', 'suresh.varma@pulsecare.org', 900.00, '09:00 - 17:00');
INSERT INTO doctors VALUES (106, 'Vikram', 'Mehta', 10, 'Cardiothoracic Surgeon', '9840111226', 'vikram.mehta@pulsecare.org', 1600.00, '12:00 - 18:00');
INSERT INTO doctors VALUES (107, 'Deepa', 'Balaji', 60, 'Trauma Critical Care', '9840111227', 'deepa.balaji@pulsecare.org', 1100.00, '18:00 - 02:00');

-- 3. Patients
INSERT INTO patients VALUES (1001, 'Rahul', 'Verma', TO_DATE('1988-04-12', 'YYYY-MM-DD'), 'Male', 'B+', '9876500001', '9876599001', '12 Gandhi Road, Vellore', 'Star Health', 'SH-889921', TO_DATE('2026-09-01', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1002, 'Sneha', 'Mukherjee', TO_DATE('1995-09-23', 'YYYY-MM-DD'), 'Female', 'O+', '9876500002', '9876599002', '45 Katpadi Main Rd, Vellore', 'HDFC ERGO', 'HE-114422', TO_DATE('2026-09-05', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1003, 'Arun', 'Kumar', TO_DATE('1972-11-15', 'YYYY-MM-DD'), 'Male', 'A+', '9876500003', '9876599003', '88 Anna Nagar, Chennai', 'Care Health', 'CH-553311', TO_DATE('2026-09-10', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1004, 'Meera', 'Iyer', TO_DATE('2001-02-18', 'YYYY-MM-DD'), 'Female', 'AB+', '9876500004', '9876599004', '19 Sathuvachari, Vellore', NULL, NULL, TO_DATE('2026-09-12', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1005, 'Vikrant', 'Gupta', TO_DATE('1965-07-30', 'YYYY-MM-DD'), 'Male', 'O-', '9876500005', '9876599005', '77 Bagayam, Vellore', 'Star Health', 'SH-442211', TO_DATE('2026-09-15', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1006, 'Pooja', 'Menon', TO_DATE('1992-12-05', 'YYYY-MM-DD'), 'Female', 'B-', '9876500006', '9876599006', '33 Ranipet High St, Ranipet', 'Niva Bupa', 'NB-778899', TO_DATE('2026-09-20', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1007, 'Amit', 'Banerjee', TO_DATE('1984-03-25', 'YYYY-MM-DD'), 'Male', 'A-', '9876500007', '9876599007', '56 Thiruvalam, Vellore', NULL, NULL, TO_DATE('2026-09-25', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (1008, 'Kavita', 'Krishnan', TO_DATE('2010-06-14', 'YYYY-MM-DD'), 'Female', 'O+', '9876500008', '9876599008', '102 Silk Mill, Katpadi', 'Star Health', 'SH-990011', TO_DATE('2026-10-01', 'YYYY-MM-DD'));

-- 4. Wards
INSERT INTO wards VALUES (201, 'Intensive Care Unit (ICU)', 'ICU', 6, 4500.00);
INSERT INTO wards VALUES (202, 'Cardiac Care Unit (CCU)', 'ICU', 6, 5000.00);
INSERT INTO wards VALUES (203, 'Executive Private Ward', 'PRIVATE', 8, 3000.00);
INSERT INTO wards VALUES (204, 'Semi-Private Ward B', 'SEMI-PRIVATE', 12, 1800.00);
INSERT INTO wards VALUES (205, 'General Ward - Male', 'GENERAL', 20, 800.00);
INSERT INTO wards VALUES (206, 'General Ward - Female', 'GENERAL', 20, 800.00);

-- 5. Beds
-- Ward 201 (ICU)
INSERT INTO beds VALUES (301, 201, 'ICU-01', 'OCCUPIED');
INSERT INTO beds VALUES (302, 201, 'ICU-02', 'AVAILABLE');
INSERT INTO beds VALUES (303, 201, 'ICU-03', 'AVAILABLE');
-- Ward 202 (CCU)
INSERT INTO beds VALUES (304, 202, 'CCU-01', 'OCCUPIED');
INSERT INTO beds VALUES (305, 202, 'CCU-02', 'AVAILABLE');
-- Ward 203 (Private)
INSERT INTO beds VALUES (306, 203, 'PVT-101', 'OCCUPIED');
INSERT INTO beds VALUES (307, 203, 'PVT-102', 'AVAILABLE');
INSERT INTO beds VALUES (308, 203, 'PVT-103', 'AVAILABLE');
-- Ward 204 (Semi-Private)
INSERT INTO beds VALUES (309, 204, 'SP-201', 'AVAILABLE');
INSERT INTO beds VALUES (310, 204, 'SP-202', 'AVAILABLE');
-- Ward 205 (General Male)
INSERT INTO beds VALUES (311, 205, 'GM-01', 'AVAILABLE');
INSERT INTO beds VALUES (312, 205, 'GM-02', 'AVAILABLE');
INSERT INTO beds VALUES (313, 205, 'GM-03', 'MAINTENANCE');

-- 6. Inpatient Admissions
-- Patient 1001 (Admitted in ICU-01)
INSERT INTO inpatient_admissions VALUES (
    5001, 1001, 301, 101, 
    TO_DATE('2026-10-10 09:30:00', 'YYYY-MM-DD HH24:MI:SS'), 
    NULL, 
    'Acute Coronary Syndrome', 'ADMITTED'
);

-- Patient 1003 (Admitted in CCU-01)
INSERT INTO inpatient_admissions VALUES (
    5002, 1003, 304, 106, 
    TO_DATE('2026-10-11 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    NULL, 
    'Post-Myocardial Infarction Surveillance', 'ADMITTED'
);

-- Patient 1005 (Admitted in PVT-101)
INSERT INTO inpatient_admissions VALUES (
    5003, 1005, 306, 103, 
    TO_DATE('2026-10-08 11:15:00', 'YYYY-MM-DD HH24:MI:SS'), 
    NULL, 
    'Cervical Spondylotic Myelopathy', 'ADMITTED'
);

-- Patient 1002 (Discharged past record)
INSERT INTO inpatient_admissions VALUES (
    5000, 1002, 307, 102, 
    TO_DATE('2026-10-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 
    TO_DATE('2026-10-05 16:30:00', 'YYYY-MM-DD HH24:MI:SS'), 
    'Meniscus Tear Repair Post-Op', 'DISCHARGED'
);

-- 7. Diagnostic Tests Catalog
INSERT INTO diagnostic_tests VALUES (401, 'Complete Blood Count (CBC)', 'Hematology', 450.00);
INSERT INTO diagnostic_tests VALUES (402, 'Comprehensive Metabolic Panel (CMP)', 'Biochemistry', 850.00);
INSERT INTO diagnostic_tests VALUES (403, '12-Lead Electrocardiogram (ECG)', 'Cardiology', 600.00);
INSERT INTO diagnostic_tests VALUES (404, 'Echocardiography (2D Echo)', 'Cardiology', 2800.00);
INSERT INTO diagnostic_tests VALUES (405, 'Chest Radiography (X-Ray)', 'Radiology', 750.00);
INSERT INTO diagnostic_tests VALUES (406, 'Magnetic Resonance Imaging (MRI Brain)', 'Radiology', 7500.00);
INSERT INTO diagnostic_tests VALUES (407, 'Serum Troponin-I Rapid Assay', 'Pathology', 1200.00);

-- 8. Patient Test Orders
INSERT INTO patient_test_orders VALUES (8001, 5001, 1001, 403, TO_DATE('2026-10-10 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'ST Elevation in leads V1-V4 confirmed', 'COMPLETED', 600.00);
INSERT INTO patient_test_orders VALUES (8002, 5001, 1001, 407, TO_DATE('2026-10-10 10:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'Troponin-I elevated at 4.2 ng/mL', 'COMPLETED', 1200.00);
INSERT INTO patient_test_orders VALUES (8003, 5002, 1003, 404, TO_DATE('2026-10-11 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Ejection Fraction 48%, regional wall hypokinesia', 'COMPLETED', 2800.00);
INSERT INTO patient_test_orders VALUES (8004, 5003, 1005, 406, TO_DATE('2026-10-09 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'C5-C6 disc extrusion with cord compression', 'COMPLETED', 7500.00);
INSERT INTO patient_test_orders VALUES (8005, NULL, 1004, 401, TO_DATE('2026-10-14 09:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Hb 12.8 g/dL, normal platelet count', 'COMPLETED', 450.00);

-- 9. Medications Catalog
INSERT INTO medications VALUES (601, 'Aspirin 75mg Gastro-resistant', 'Antiplatelet', 3.50, 2500);
INSERT INTO medications VALUES (602, 'Clopidogrel 75mg Film-coated', 'Antiplatelet', 12.00, 1800);
INSERT INTO medications VALUES (603, 'Atorvastatin 40mg', 'Lipid lowering', 18.50, 1500);
INSERT INTO medications VALUES (604, 'Enoxaparin 40mg Injection', 'Anticoagulant', 450.00, 300);
INSERT INTO medications VALUES (605, 'Pantoprazole 40mg IV', 'PPI', 65.00, 800);
INSERT INTO medications VALUES (606, 'Ceftriaxone 1g IV Infusion', 'Antibiotic', 145.00, 600);
INSERT INTO medications VALUES (607, 'Paracetamol 650mg Tablet', 'Analgesic', 2.00, 5000);

-- 10. Appointments
INSERT INTO appointments VALUES (7001, 1002, 102, TO_DATE('2026-10-18', 'YYYY-MM-DD'), '10:00 - 10:30', 'SCHEDULED', 'Follow-up on right knee rehab');
INSERT INTO appointments VALUES (7002, 1004, 104, TO_DATE('2026-10-18', 'YYYY-MM-DD'), '11:30 - 12:00', 'SCHEDULED', 'Pediatric allergic rhinitis checkup');
INSERT INTO appointments VALUES (7003, 1006, 105, TO_DATE('2026-10-19', 'YYYY-MM-DD'), '09:30 - 10:00', 'SCHEDULED', 'Chronic hypertension management');
INSERT INTO appointments VALUES (7004, 1007, 101, TO_DATE('2026-10-19', 'YYYY-MM-DD'), '14:00 - 14:30', 'SCHEDULED', 'Cardiology preventative screening');

-- 11. Past Billing Invoice (For Discharged Admission 5000)
INSERT INTO billing_invoices VALUES (
    9001, 5000, 1002, 
    TO_DATE('2026-10-05', 'YYYY-MM-DD'),
    12000.00,  -- 4 days in Private Ward (3000/day)
    4000.00,   -- Surgeon consultation & post-op visits
    3250.00,   -- Tests (CBC, X-ray, MRI)
    2150.00,   -- Post-op medications
    21400.00,  -- Gross total
    1400.00,   -- Hospital loyalty discount
    16000.00,  -- HDFC ERGO insurance coverage
    4000.00,   -- Net payable by patient
    'PAID', 
    'CREDIT_CARD'
);

-- 12. Initial Audit Log Entry
INSERT INTO audit_billing_log VALUES (
    seq_audit_id.NEXTVAL,
    9001, 0.00, 4000.00, 'PENDING', 'PAID',
    'SETTLEMENT', 'ACCOUNTS_ADMIN', SYSDATE
);

COMMIT;
