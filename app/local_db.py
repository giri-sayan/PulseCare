import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "pulsecare.db")

def init_local_db(force_reinit=False):
    if os.path.exists(DB_PATH) and not force_reinit:
        return sqlite3.connect(DB_PATH, check_same_thread=False)
    
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    cur = conn.cursor()
    
    # 1. Departments
    cur.execute("""
    CREATE TABLE IF NOT EXISTS departments (
        dept_id INTEGER PRIMARY KEY,
        dept_name TEXT UNIQUE NOT NULL,
        building_block TEXT NOT NULL,
        head_of_dept TEXT NOT NULL,
        phone TEXT NOT NULL
    )""")
    
    # 2. Doctors
    cur.execute("""
    CREATE TABLE IF NOT EXISTS doctors (
        doctor_id INTEGER PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        dept_id INTEGER NOT NULL REFERENCES departments(dept_id),
        specialization TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        consultation_fee REAL NOT NULL,
        available_days TEXT NOT NULL
    )""")
    
    # 3. Patients
    cur.execute("""
    CREATE TABLE IF NOT EXISTS patients (
        patient_id INTEGER PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        dob TEXT NOT NULL,
        gender TEXT NOT NULL,
        blood_group TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        emergency_contact TEXT NOT NULL,
        address TEXT,
        insurance_provider TEXT,
        policy_number TEXT,
        created_at TEXT NOT NULL
    )""")
    
    # 4. Wards
    cur.execute("""
    CREATE TABLE IF NOT EXISTS wards (
        ward_id INTEGER PRIMARY KEY,
        ward_name TEXT UNIQUE NOT NULL,
        ward_type TEXT NOT NULL,
        total_beds INTEGER NOT NULL,
        daily_charge REAL NOT NULL
    )""")
    
    # 5. Beds
    cur.execute("""
    CREATE TABLE IF NOT EXISTS beds (
        bed_id INTEGER PRIMARY KEY,
        ward_id INTEGER NOT NULL REFERENCES wards(ward_id),
        bed_number TEXT NOT NULL,
        status TEXT NOT NULL,
        UNIQUE (ward_id, bed_number)
    )""")
    
    # 6. Inpatient Admissions
    cur.execute("""
    CREATE TABLE IF NOT EXISTS inpatient_admissions (
        admission_id INTEGER PRIMARY KEY,
        patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
        bed_id INTEGER NOT NULL REFERENCES beds(bed_id),
        attending_doc_id INTEGER NOT NULL REFERENCES doctors(doctor_id),
        admission_date TEXT NOT NULL,
        discharge_date TEXT,
        initial_diagnosis TEXT NOT NULL,
        admission_status TEXT NOT NULL
    )""")
    
    # 7. Diagnostic Tests
    cur.execute("""
    CREATE TABLE IF NOT EXISTS diagnostic_tests (
        test_id INTEGER PRIMARY KEY,
        test_name TEXT NOT NULL,
        category TEXT NOT NULL,
        standard_cost REAL NOT NULL
    )""")
    
    # 8. Patient Test Orders
    cur.execute("""
    CREATE TABLE IF NOT EXISTS patient_test_orders (
        order_id INTEGER PRIMARY KEY,
        admission_id INTEGER REFERENCES inpatient_admissions(admission_id),
        patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
        test_id INTEGER NOT NULL REFERENCES diagnostic_tests(test_id),
        order_date TEXT NOT NULL,
        result_summary TEXT,
        order_status TEXT NOT NULL,
        billed_cost REAL NOT NULL
    )""")
    
    # 9. Medications
    cur.execute("""
    CREATE TABLE IF NOT EXISTS medications (
        med_id INTEGER PRIMARY KEY,
        med_name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL
    )""")
    
    # 10. Appointments
    cur.execute("""
    CREATE TABLE IF NOT EXISTS appointments (
        appointment_id INTEGER PRIMARY KEY,
        patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
        doctor_id INTEGER NOT NULL REFERENCES doctors(doctor_id),
        appointment_date TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
    )""")
    
    # 11. Billing Invoices
    cur.execute("""
    CREATE TABLE IF NOT EXISTS billing_invoices (
        invoice_id INTEGER PRIMARY KEY,
        admission_id INTEGER REFERENCES inpatient_admissions(admission_id),
        patient_id INTEGER NOT NULL REFERENCES patients(patient_id),
        invoice_date TEXT NOT NULL,
        room_charges REAL NOT NULL,
        doctor_fees REAL NOT NULL,
        test_charges REAL NOT NULL,
        medication_charges REAL NOT NULL,
        gross_total REAL NOT NULL,
        discount_amount REAL NOT NULL,
        insurance_covered REAL NOT NULL,
        net_payable REAL NOT NULL,
        payment_status TEXT NOT NULL,
        payment_mode TEXT
    )""")
    
    # 12. Audit Log
    cur.execute("""
    CREATE TABLE IF NOT EXISTS audit_billing_log (
        audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        old_net_payable REAL,
        new_net_payable REAL,
        old_status TEXT,
        new_status TEXT,
        action_type TEXT NOT NULL,
        modified_by TEXT NOT NULL,
        modified_at TEXT NOT NULL
    )""")
    
    # Insert Seed Data
    cur.execute("DELETE FROM departments")
    cur.executemany("INSERT INTO departments VALUES (?,?,?,?,?)", [
        (10, 'Cardiology', 'Block-A Level 3', 'Dr. Ramesh Sharma', '0416-220101'),
        (20, 'Orthopedics', 'Block-B Level 2', 'Dr. Priya Sundaram', '0416-220102'),
        (30, 'Neurology', 'Block-A Level 4', 'Dr. Ananya Roy', '0416-220103'),
        (40, 'Pediatrics', 'Block-C Level 1', 'Dr. Rajesh Nair', '0416-220104'),
        (50, 'General Medicine', 'Block-B Level 1', 'Dr. Suresh Varma', '0416-220105'),
        (60, 'Emergency & Trauma', 'Block-E Ground', 'Dr. Arvind Swaminathan', '0416-220106')
    ])
    
    cur.execute("DELETE FROM doctors")
    cur.executemany("INSERT INTO doctors VALUES (?,?,?,?,?,?,?,?,?)", [
        (101, 'Ramesh', 'Sharma', 10, 'Interventional Cardiologist', '9840111221', 'ramesh.sharma@pulsecare.org', 1200.00, '09:00 - 15:00'),
        (102, 'Priya', 'Sundaram', 20, 'Joint Replacement Specialist', '9840111222', 'priya.sundaram@pulsecare.org', 1000.00, '10:00 - 16:00'),
        (103, 'Ananya', 'Roy', 30, 'Neurosurgeon', '9840111223', 'ananya.roy@pulsecare.org', 1500.00, '08:00 - 14:00'),
        (104, 'Rajesh', 'Nair', 40, 'Pediatric Consultant', '9840111224', 'rajesh.nair@pulsecare.org', 800.00, '11:00 - 17:00'),
        (105, 'Suresh', 'Varma', 50, 'Senior Physician', '9840111225', 'suresh.varma@pulsecare.org', 900.00, '09:00 - 17:00'),
        (106, 'Vikram', 'Mehta', 10, 'Cardiothoracic Surgeon', '9840111226', 'vikram.mehta@pulsecare.org', 1600.00, '12:00 - 18:00'),
        (107, 'Deepa', 'Balaji', 60, 'Trauma Critical Care', '9840111227', 'deepa.balaji@pulsecare.org', 1100.00, '18:00 - 02:00')
    ])
    
    cur.execute("DELETE FROM patients")
    cur.executemany("INSERT INTO patients VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", [
        (1001, 'Rahul', 'Verma', '1988-04-12', 'Male', 'B+', '9876500001', '9876599001', '12 Gandhi Road, Vellore', 'Star Health', 'SH-889921', '2026-09-01'),
        (1002, 'Sneha', 'Mukherjee', '1995-09-23', 'Female', 'O+', '9876500002', '9876599002', '45 Katpadi Main Rd, Vellore', 'HDFC ERGO', 'HE-114422', '2026-09-05'),
        (1003, 'Arun', 'Kumar', '1972-11-15', 'Male', 'A+', '9876500003', '9876599003', '88 Anna Nagar, Chennai', 'Care Health', 'CH-553311', '2026-09-10'),
        (1004, 'Meera', 'Iyer', '2001-02-18', 'Female', 'AB+', '9876500004', '9876599004', '19 Sathuvachari, Vellore', None, None, '2026-09-12'),
        (1005, 'Vikrant', 'Gupta', '1965-07-30', 'Male', 'O-', '9876500005', '9876599005', '77 Bagayam, Vellore', 'Star Health', 'SH-442211', '2026-09-15'),
        (1006, 'Pooja', 'Menon', '1992-12-05', 'Female', 'B-', '9876500006', '9876599006', '33 Ranipet High St, Ranipet', 'Niva Bupa', 'NB-778899', '2026-09-20'),
        (1007, 'Amit', 'Banerjee', '1984-03-25', 'Male', 'A-', '9876500007', '9876599007', '56 Thiruvalam, Vellore', None, None, '2026-09-25'),
        (1008, 'Kavita', 'Krishnan', '2010-06-14', 'Female', 'O+', '9876500008', '9876599008', '102 Silk Mill, Katpadi', 'Star Health', 'SH-990011', '2026-10-01')
    ])
    
    cur.execute("DELETE FROM wards")
    cur.executemany("INSERT INTO wards VALUES (?,?,?,?,?)", [
        (201, 'Intensive Care Unit (ICU)', 'ICU', 6, 4500.00),
        (202, 'Cardiac Care Unit (CCU)', 'ICU', 6, 5000.00),
        (203, 'Executive Private Ward', 'PRIVATE', 8, 3000.00),
        (204, 'Semi-Private Ward B', 'SEMI-PRIVATE', 12, 1800.00),
        (205, 'General Ward - Male', 'GENERAL', 20, 800.00),
        (206, 'General Ward - Female', 'GENERAL', 20, 800.00)
    ])
    
    cur.execute("DELETE FROM beds")
    cur.executemany("INSERT INTO beds VALUES (?,?,?,?)", [
        (301, 201, 'ICU-01', 'OCCUPIED'),
        (302, 201, 'ICU-02', 'AVAILABLE'),
        (303, 201, 'ICU-03', 'AVAILABLE'),
        (304, 202, 'CCU-01', 'OCCUPIED'),
        (305, 202, 'CCU-02', 'AVAILABLE'),
        (306, 203, 'PVT-101', 'OCCUPIED'),
        (307, 203, 'PVT-102', 'AVAILABLE'),
        (308, 203, 'PVT-103', 'AVAILABLE'),
        (309, 204, 'SP-201', 'AVAILABLE'),
        (310, 204, 'SP-202', 'AVAILABLE'),
        (311, 205, 'GM-01', 'AVAILABLE'),
        (312, 205, 'GM-02', 'AVAILABLE'),
        (313, 205, 'GM-03', 'MAINTENANCE')
    ])
    
    cur.execute("DELETE FROM inpatient_admissions")
    cur.executemany("INSERT INTO inpatient_admissions VALUES (?,?,?,?,?,?,?,?)", [
        (5001, 1001, 301, 101, '2026-10-10 09:30:00', None, 'Acute Coronary Syndrome', 'ADMITTED'),
        (5002, 1003, 304, 106, '2026-10-11 14:00:00', None, 'Post-Myocardial Infarction Surveillance', 'ADMITTED'),
        (5003, 1005, 306, 103, '2026-10-08 11:15:00', None, 'Cervical Spondylotic Myelopathy', 'ADMITTED'),
        (5000, 1002, 307, 102, '2026-10-01 10:00:00', '2026-10-05 16:30:00', 'Meniscus Tear Repair Post-Op', 'DISCHARGED')
    ])
    
    cur.execute("DELETE FROM diagnostic_tests")
    cur.executemany("INSERT INTO diagnostic_tests VALUES (?,?,?,?)", [
        (401, 'Complete Blood Count (CBC)', 'Hematology', 450.00),
        (402, 'Comprehensive Metabolic Panel (CMP)', 'Biochemistry', 850.00),
        (403, '12-Lead Electrocardiogram (ECG)', 'Cardiology', 600.00),
        (404, 'Echocardiography (2D Echo)', 'Cardiology', 2800.00),
        (405, 'Chest Radiography (X-Ray)', 'Radiology', 750.00),
        (406, 'Magnetic Resonance Imaging (MRI Brain)', 'Radiology', 7500.00),
        (407, 'Serum Troponin-I Rapid Assay', 'Pathology', 1200.00)
    ])
    
    cur.execute("DELETE FROM patient_test_orders")
    cur.executemany("INSERT INTO patient_test_orders VALUES (?,?,?,?,?,?,?,?)", [
        (8001, 5001, 1001, 403, '2026-10-10 10:00:00', 'ST Elevation in leads V1-V4 confirmed', 'COMPLETED', 600.00),
        (8002, 5001, 1001, 407, '2026-10-10 10:15:00', 'Troponin-I elevated at 4.2 ng/mL', 'COMPLETED', 1200.00),
        (8003, 5002, 1003, 404, '2026-10-11 15:30:00', 'Ejection Fraction 48%, regional wall hypokinesia', 'COMPLETED', 2800.00),
        (8004, 5003, 1005, 406, '2026-10-09 11:00:00', 'C5-C6 disc extrusion with cord compression', 'COMPLETED', 7500.00),
        (8005, None, 1004, 401, '2026-10-14 09:30:00', 'Hb 12.8 g/dL, normal platelet count', 'COMPLETED', 450.00)
    ])
    
    cur.execute("DELETE FROM appointments")
    cur.executemany("INSERT INTO appointments VALUES (?,?,?,?,?,?,?)", [
        (7001, 1002, 102, '2026-10-18', '10:00 - 10:30', 'SCHEDULED', 'Follow-up on right knee rehab'),
        (7002, 1004, 104, '2026-10-18', '11:30 - 12:00', 'SCHEDULED', 'Pediatric allergic rhinitis checkup'),
        (7003, 1006, 105, '2026-10-19', '09:30 - 10:00', 'SCHEDULED', 'Chronic hypertension management'),
        (7004, 1007, 101, '2026-10-19', '14:00 - 14:30', 'SCHEDULED', 'Cardiology preventative screening')
    ])
    
    cur.execute("DELETE FROM billing_invoices")
    cur.executemany("INSERT INTO billing_invoices VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)", [
        (9001, 5000, 1002, '2026-10-05', 12000.00, 4000.00, 3250.00, 2150.00, 21400.00, 1400.00, 16000.00, 4000.00, 'PAID', 'CREDIT_CARD'),
        (9100, 5002, 1003, '2026-10-15', 5000.00, 1600.00, 2800.00, 0.00, 9400.00, 0.00, 0.00, 9400.00, 'PAID', 'UPI')
    ])
    
    cur.execute("DELETE FROM audit_billing_log")
    cur.executemany("INSERT INTO audit_billing_log (audit_id, invoice_id, old_net_payable, new_net_payable, old_status, new_status, action_type, modified_by, modified_at) VALUES (?,?,?,?,?,?,?,?,?)", [
        (100, 9001, 0.00, 4000.00, 'PENDING', 'PAID', 'SETTLEMENT', 'ACCOUNTS_ADMIN', '2026-10-05 16:35:00'),
        (101, 9001, 4000.00, 4000.00, 'PAID', 'PARTIAL', 'STATUS_CHANGE', 'PULSECARE_DB', '2026-10-06 10:12:00'),
        (102, 9001, 4000.00, 4000.00, 'PARTIAL', 'PAID', 'STATUS_CHANGE', 'PULSECARE_DB', '2026-10-06 14:45:00'),
        (103, 9100, None, 9588.00, None, 'PAID', 'INVOICE_CREATED', 'PULSECARE_DB', '2026-10-15 22:45:00')
    ])
    
    conn.commit()
    return conn

# Business Logic Handlers (matching Oracle PL/SQL stored procedures & functions)

def local_admit_patient(conn, p_id, b_id, d_id, diagnosis):
    cur = conn.cursor()
    # Check bed
    cur.execute("SELECT status FROM beds WHERE bed_id = ?", (b_id,))
    row = cur.fetchone()
    if not row or row[0] != 'AVAILABLE':
        return False, None, f"ERROR: Bed ID {b_id} is currently {row[0] if row else 'NOT FOUND'} and cannot be assigned."
    
    # Generate new admission ID
    cur.execute("SELECT IFNULL(MAX(admission_id), 5100) + 1 FROM inpatient_admissions")
    new_adm_id = cur.fetchone()[0]
    
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cur.execute("""
        INSERT INTO inpatient_admissions (admission_id, patient_id, bed_id, attending_doc_id, admission_date, initial_diagnosis, admission_status)
        VALUES (?, ?, ?, ?, ?, ?, 'ADMITTED')
    """, (new_adm_id, p_id, b_id, d_id, now_str, diagnosis))
    
    cur.execute("UPDATE beds SET status = 'OCCUPIED' WHERE bed_id = ?", (b_id,))
    conn.commit()
    return True, new_adm_id, f"SUCCESS: Patient {p_id} admitted under Admission #{new_adm_id} into Bed {b_id}"

def local_calculate_inpatient_bill(conn, adm_id):
    cur = conn.cursor()
    # Room charges: days * daily_charge (minimum 1 day)
    cur.execute("""
        SELECT w.daily_charge, a.admission_date
        FROM inpatient_admissions a
        JOIN beds b ON a.bed_id = b.bed_id
        JOIN wards w ON b.ward_id = w.ward_id
        WHERE a.admission_id = ?
    """, (adm_id,))
    row = cur.fetchone()
    if not row:
        return 0.0
    
    daily_charge = row[0]
    # For demo estimation: default 2 days if newly admitted or calculated
    days = 2
    room_cost = daily_charge * days
    
    # Doctor fees
    cur.execute("""
        SELECT d.consultation_fee
        FROM inpatient_admissions a
        JOIN doctors d ON a.attending_doc_id = d.doctor_id
        WHERE a.admission_id = ?
    """, (adm_id,))
    doc_row = cur.fetchone()
    doc_cost = (doc_row[0] * 1.5) if doc_row else 1500.0
    
    # Test charges
    cur.execute("SELECT IFNULL(SUM(billed_cost), 0) FROM patient_test_orders WHERE admission_id = ?", (adm_id,))
    test_cost = cur.fetchone()[0]
    if test_cost == 0:
        test_cost = 1800.0
        
    return float(room_cost + doc_cost + test_cost)

def local_discharge_patient(conn, adm_id, payment_mode):
    cur = conn.cursor()
    cur.execute("SELECT patient_id, bed_id, admission_status FROM inpatient_admissions WHERE admission_id = ?", (adm_id,))
    adm = cur.fetchone()
    if not adm or adm[2] != 'ADMITTED':
        return False, None, 0.0, "ERROR: Admission record not found or patient already discharged."
    
    p_id, b_id = adm[0], adm[1]
    final_bill = local_calculate_inpatient_bill(conn, adm_id)
    
    # Generate invoice id
    cur.execute("SELECT IFNULL(MAX(invoice_id), 9100) + 1 FROM billing_invoices")
    new_inv_id = cur.fetchone()[0]
    
    now_date = datetime.now().strftime("%Y-%m-%d")
    now_dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    room_chg = round(final_bill * 0.5, 2)
    doc_fee = round(final_bill * 0.25, 2)
    test_chg = round(final_bill - room_chg - doc_fee, 2)
    
    cur.execute("""
        INSERT INTO billing_invoices 
        (invoice_id, admission_id, patient_id, invoice_date, room_charges, doctor_fees, test_charges, medication_charges, gross_total, discount_amount, insurance_covered, net_payable, payment_status, payment_mode)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0.0, ?, 0.0, 0.0, ?, 'PAID', ?)
    """, (new_inv_id, adm_id, p_id, now_date, room_chg, doc_fee, test_chg, final_bill, final_bill, payment_mode))
    
    cur.execute("UPDATE inpatient_admissions SET discharge_date = ?, admission_status = 'DISCHARGED' WHERE admission_id = ?", (now_dt, adm_id))
    cur.execute("UPDATE beds SET status = 'AVAILABLE' WHERE bed_id = ?", (b_id,))
    
    cur.execute("""
        INSERT INTO audit_billing_log (invoice_id, old_net_payable, new_net_payable, old_status, new_status, action_type, modified_by, modified_at)
        VALUES (?, NULL, ?, NULL, 'PAID', 'INVOICE_CREATED', 'PULSECARE_DB', ?)
    """, (new_inv_id, final_bill, now_dt))
    
    conn.commit()
    return True, new_inv_id, final_bill, f"SUCCESS: Patient discharged successfully. Invoice #{new_inv_id} generated for Rs. {final_bill:,.0f}"

def local_schedule_appointment(conn, p_id, d_id, apt_date, slot, notes):
    cur = conn.cursor()
    # Collision prevention trigger logic
    cur.execute("""
        SELECT COUNT(*) FROM appointments 
        WHERE doctor_id = ? AND appointment_date = ? AND time_slot = ? AND status != 'CANCELLED'
    """, (d_id, apt_date, slot))
    if cur.fetchone()[0] > 0:
        raise Exception(f"ORA-20001: Double Booking Violation: Doctor #{d_id} already has a scheduled appointment on {apt_date} during slot {slot}")
    
    cur.execute("SELECT IFNULL(MAX(appointment_id), 7100) + 1 FROM appointments")
    new_apt_id = cur.fetchone()[0]
    
    cur.execute("""
        INSERT INTO appointments (appointment_id, patient_id, doctor_id, appointment_date, time_slot, status, notes)
        VALUES (?, ?, ?, ?, ?, 'SCHEDULED', ?)
    """, (new_apt_id, p_id, d_id, apt_date, slot, notes))
    conn.commit()
    return True, new_apt_id, f"SUCCESS: Appointment #{new_apt_id} scheduled with Dr. {d_id} on {apt_date} ({slot})"

def local_apply_waiver_discount(conn, inv_id, discount_pct):
    cur = conn.cursor()
    if discount_pct > 0.25:
        return False, 0.0, f"ERROR: Requested discount ({discount_pct*100:.0f}%) exceeds maximum permitted policy limit (25%)."
    
    cur.execute("SELECT net_payable FROM billing_invoices WHERE invoice_id = ?", (inv_id,))
    row = cur.fetchone()
    if not row:
        return False, 0.0, f"ERROR: Invoice #{inv_id} not found."
    
    old_val = row[0]
    discount_val = round(old_val * discount_pct, 2)
    new_val = round(old_val - discount_val, 2)
    
    cur.execute("UPDATE billing_invoices SET discount_amount = discount_amount + ?, net_payable = ? WHERE invoice_id = ?", (discount_val, new_val, inv_id))
    now_dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cur.execute("""
        INSERT INTO audit_billing_log (invoice_id, old_net_payable, new_net_payable, old_status, new_status, action_type, modified_by, modified_at)
        VALUES (?, ?, ?, 'PAID', 'PAID', 'DISCOUNT_WAIVER', 'PULSECARE_PKG', ?)
    """, (inv_id, old_val, new_val, now_dt))
    conn.commit()
    return True, new_val, f"SUCCESS: Applied waiver discount of Rs. {discount_val:,.2f} ({discount_pct*100:.0f}%). Revised Net Payable: Rs. {new_val:,.2f}"
