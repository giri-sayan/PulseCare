"""
PulseCare Smart Hospital Management System
Front-End Integration with Oracle Database 21c XE / High-Performance Standalone Engine
"""

import streamlit as st
import pandas as pd
from datetime import datetime, date
import matplotlib.pyplot as plt
import os
import sqlite3

try:
    import oracledb
    ORACLE_AVAILABLE = True
except ImportError:
    ORACLE_AVAILABLE = False

from app.local_db import (
    DB_PATH,
    init_local_db,
    local_admit_patient,
    local_calculate_inpatient_bill,
    local_discharge_patient,
    local_schedule_appointment,
    local_apply_waiver_discount
)

# Page configuration
st.set_page_config(
    page_title="PulseCare Hospital Management System",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom Styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.2rem;
        font-weight: 700;
        color: #1E3A8A;
        margin-bottom: 0px;
    }
    .sub-header {
        font-size: 1.05rem;
        color: #4B5563;
        margin-bottom: 20px;
    }
    .kpi-card {
        background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%);
        padding: 20px;
        border-radius: 10px;
        color: white;
        text-align: center;
    }
    .kpi-num {
        font-size: 2rem;
        font-weight: bold;
    }
    .kpi-label {
        font-size: 0.9rem;
        opacity: 0.9;
    }
    .badge-oracle {
        background-color: #065F46;
        color: #D1FAE5;
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 0.8rem;
        font-weight: 600;
    }
    .badge-local {
        background-color: #1E3A8A;
        color: #DBEAFE;
        padding: 4px 10px;
        border-radius: 12px;
        font-size: 0.8rem;
        font-weight: 600;
    }
</style>
""", unsafe_allow_html=True)

# Database Connection Helper (Dual Engine: Live Oracle 21c XE with Local Fallback)
@st.cache_resource
def is_oracle_live():
    if ORACLE_AVAILABLE:
        try:
            test_conn = oracledb.connect(
                user="PULSECARE_DB",
                password="PulseCare#2026",
                dsn="localhost:1521/XEPDB1"
            )
            test_conn.close()
            return True
        except Exception:
            return False
    return False

def get_connection():
    if is_oracle_live():
        try:
            return oracledb.connect(
                user="PULSECARE_DB",
                password="PulseCare#2026",
                dsn="localhost:1521/XEPDB1"
            ), "ORACLE"
        except Exception:
            pass
    
    init_local_db()
    return sqlite3.connect(DB_PATH, check_same_thread=False), "LOCAL"

conn, db_mode = get_connection()

def get_cursor():
    return conn.cursor()

def query_df(sql, params=None):
    if db_mode == "LOCAL":
        # Adapt Oracle TO_CHAR functions for SQLite compatibility
        sql = sql.replace("TO_CHAR(a.admission_date, 'YYYY-MM-DD HH24:MI')", "SUBSTR(a.admission_date, 1, 16)")
        sql = sql.replace("TO_CHAR(i.invoice_date, 'YYYY-MM-DD')", "SUBSTR(i.invoice_date, 1, 10)")
        sql = sql.replace("TO_CHAR(a.appointment_date, 'YYYY-MM-DD')", "SUBSTR(a.appointment_date, 1, 10)")
        sql = sql.replace("TO_CHAR(modified_at, 'YYYY-MM-DD HH24:MI:SS')", "modified_at")
        sql = sql.replace("NVL(", "COALESCE(")
    
    df = pd.read_sql(sql, conn, params=params)
    df.columns = [str(c).lower() for c in df.columns]
    return df

# Sidebar Navigation
st.sidebar.image("https://img.icons8.com/fluency/96/hospital.png", width=70)
st.sidebar.title("PulseCare HMS")
st.sidebar.caption("PulseCare Clinical Systems v1.0")

if db_mode == "ORACLE":
    st.sidebar.markdown('<span class="badge-oracle">🟢 Oracle Database 21c XE (Live)</span>', unsafe_allow_html=True)
else:
    st.sidebar.markdown('<span class="badge-local">🟢 PulseCare Standalone DB (Active)</span>', unsafe_allow_html=True)

st.sidebar.markdown("")

menu = st.sidebar.radio(
    "Navigation Menu",
    [
        "🏥 Hospital Dashboard",
        "🛌 Inpatient Admission",
        "💳 Discharge & Billing",
        "📅 Doctor Appointments",
        "🛡️ Audit & PL/SQL Console"
    ]
)

# =============================================================================
# 1. HOSPITAL DASHBOARD
# =============================================================================
if menu == "🏥 Hospital Dashboard":
    st.markdown('<p class="main-header">PulseCare Clinical Operations Dashboard</p>', unsafe_allow_html=True)
    st.markdown('<p class="sub-header">Real-time resource utilization, bed occupancy, and inpatient monitoring</p>', unsafe_allow_html=True)

    cur = get_cursor()
    
    # KPIs
    cur.execute("SELECT COUNT(*) FROM patients")
    total_patients = cur.fetchone()[0]
    
    cur.execute("SELECT COUNT(*) FROM doctors")
    total_doctors = cur.fetchone()[0]
    
    cur.execute("SELECT COUNT(*), COUNT(CASE WHEN status='OCCUPIED' THEN 1 END) FROM beds")
    total_beds, occupied_beds = cur.fetchone()
    available_beds = total_beds - occupied_beds
    occupancy_pct = round((occupied_beds / total_beds) * 100, 1) if total_beds > 0 else 0
    
    cur.execute("SELECT COALESCE(SUM(net_payable), 0.0) FROM billing_invoices WHERE payment_status='PAID'")
    gross_rev = cur.fetchone()[0]

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Registered Patients", total_patients)
    with col2:
        st.metric("Available / Total Beds", f"{available_beds} / {total_beds}", f"↑ {occupancy_pct}% Occupied")
    with col3:
        st.metric("Consultant Specialists", total_doctors)
    with col4:
        st.metric("Total Settled Revenue", f"₹ {gross_rev:,.2f}")

    st.markdown("---")

    # Ward Breakdown
    st.subheader("📊 Ward-Level Bed Utilization Breakdown")
    ward_df = query_df("""
        SELECT w.ward_name, w.ward_type, w.daily_charge,
               COUNT(b.bed_id) as total_beds,
               COUNT(CASE WHEN b.status = 'OCCUPIED' THEN 1 END) as occupied_beds,
               COUNT(CASE WHEN b.status = 'AVAILABLE' THEN 1 END) as available_beds
        FROM wards w
        LEFT JOIN beds b ON w.ward_id = b.ward_id
        GROUP BY w.ward_name, w.ward_type, w.daily_charge
        ORDER BY w.ward_name
    """)
    
    col_chart, col_table = st.columns([1, 1])
    with col_chart:
        fig, ax = plt.subplots(figsize=(6, 3.5))
        ax.bar(ward_df['ward_name'], ward_df['occupied_beds'], label='Occupied', color='#EF4444')
        ax.bar(ward_df['ward_name'], ward_df['available_beds'], bottom=ward_df['occupied_beds'], label='Available', color='#10B981')
        ax.set_ylabel("Number of Beds")
        ax.set_title("Occupied vs Available Beds by Ward")
        plt.xticks(rotation=45, ha='right', fontsize=8)
        ax.legend()
        st.pyplot(fig)
        
    with col_table:
        st.dataframe(ward_df, width="stretch", hide_index=True)

    # Currently Admitted Patients
    st.subheader("🩺 Currently Admitted Inpatients")
    admissions_df = query_df("""
        SELECT a.admission_id, 
               p.first_name || ' ' || p.last_name as patient_name,
               w.ward_name || ' (' || b.bed_number || ')' as ward_bed,
               'Dr. ' || d.first_name || ' ' || d.last_name as attending_doctor,
               TO_CHAR(a.admission_date, 'YYYY-MM-DD HH24:MI') as admitted_on,
               a.initial_diagnosis
        FROM inpatient_admissions a
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN beds b ON a.bed_id = b.bed_id
        JOIN wards w ON b.ward_id = w.ward_id
        JOIN doctors d ON a.attending_doc_id = d.doctor_id
        WHERE a.admission_status = 'ADMITTED'
        ORDER BY a.admission_date DESC
    """)
    st.dataframe(admissions_df, width="stretch", hide_index=True)

# =============================================================================
# 2. INPATIENT ADMISSION MODULE
# =============================================================================
elif menu == "🛌 Inpatient Admission":
    st.markdown('<p class="main-header">Inpatient Admission & Bed Allocation</p>', unsafe_allow_html=True)
    st.markdown('<p class="sub-header">Transactional patient admission powered by Oracle Stored Procedure <code>sp_admit_patient</code></p>', unsafe_allow_html=True)

    cur = get_cursor()
    
    # Query Patients
    patients_df = query_df("SELECT patient_id, first_name || ' ' || last_name || ' (ID: ' || patient_id || ')' as name_label FROM patients ORDER BY patient_id")
    patient_opts = dict(zip(patients_df['name_label'], patients_df['patient_id']))

    # Query Available Beds
    beds_df = query_df("""
        SELECT b.bed_id, w.ward_name || ' - Bed ' || b.bed_number || ' [₹' || w.daily_charge || '/day]' as bed_label
        FROM beds b
        JOIN wards w ON b.ward_id = w.ward_id
        WHERE b.status = 'AVAILABLE'
        ORDER BY w.ward_name, b.bed_number
    """)
    bed_opts = dict(zip(beds_df['bed_label'], beds_df['bed_id']))

    # Query Doctors
    doctors_df = query_df("""
        SELECT d.doctor_id, 'Dr. ' || d.first_name || ' ' || d.last_name || ' (' || dept.dept_name || ')' as doc_label
        FROM doctors d
        JOIN departments dept ON d.dept_id = dept.dept_id
        ORDER BY dept.dept_name, d.first_name
    """)
    doc_opts = dict(zip(doctors_df['doc_label'], doctors_df['doctor_id']))

    with st.form("admission_form"):
        col1, col2 = st.columns(2)
        with col1:
            sel_patient_label = st.selectbox("Select Patient", list(patient_opts.keys()))
            if not bed_opts:
                st.error("No beds currently available!")
                sel_bed_label = None
            else:
                sel_bed_label = st.selectbox("Select Available Bed", list(bed_opts.keys()))
        with col2:
            sel_doc_label = st.selectbox("Attending Doctor", list(doc_opts.keys()))
            diagnosis = st.text_area("Clinical Diagnosis / Admission Reason", "Observation for acute symptoms")

        submitted = st.form_submit_button("Submit Admission (Invoke sp_admit_patient)")

        if submitted:
            if not sel_bed_label:
                st.error("Cannot proceed without an available bed.")
            else:
                p_id = patient_opts[sel_patient_label]
                b_id = bed_opts[sel_bed_label]
                d_id = doc_opts[sel_doc_label]

                if db_mode == "ORACLE":
                    out_adm_id = cur.var(oracledb.NUMBER)
                    out_msg = cur.var(oracledb.STRING)
                    try:
                        cur.callproc("sp_admit_patient", [p_id, b_id, d_id, diagnosis, out_adm_id, out_msg])
                        msg_val = out_msg.getvalue()
                        if "SUCCESS" in msg_val:
                            st.success(f"{msg_val}")
                            st.balloons()
                        else:
                            st.error(f"{msg_val}")
                    except Exception as ex:
                        st.error(f"Procedure Execution Exception: {ex}")
                else:
                    success, adm_id, msg_val = local_admit_patient(conn, p_id, b_id, d_id, diagnosis)
                    if success:
                        st.success(msg_val)
                        st.balloons()
                    else:
                        st.error(msg_val)

# =============================================================================
# 3. DISCHARGE & BILLING MODULE
# =============================================================================
elif menu == "💳 Discharge & Billing":
    st.markdown('<p class="main-header">Inpatient Discharge & Final Bill Settlement</p>', unsafe_allow_html=True)
    st.markdown('<p class="sub-header">Invokes PL/SQL Function <code>fn_calculate_inpatient_bill</code> and Package <code>pkg_hospital_billing</code></p>', unsafe_allow_html=True)

    cur = get_cursor()
    active_adm_df = query_df("""
        SELECT a.admission_id, 
               'Admission #' || a.admission_id || ' - ' || p.first_name || ' ' || p.last_name || ' (' || w.ward_name || ' / ' || b.bed_number || ')' as adm_label
        FROM inpatient_admissions a
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN beds b ON a.bed_id = b.bed_id
        JOIN wards w ON b.ward_id = w.ward_id
        WHERE a.admission_status = 'ADMITTED'
        ORDER BY a.admission_id
    """)

    if active_adm_df.empty:
        st.info("No active inpatients currently awaiting discharge.")
    else:
        adm_opts = dict(zip(active_adm_df['adm_label'], active_adm_df['admission_id']))
        sel_adm_label = st.selectbox("Select Active Inpatient Admission", list(adm_opts.keys()))
        sel_adm_id = adm_opts[sel_adm_label]

        # Calculate estimated bill using PL/SQL function or local equivalent
        if db_mode == "ORACLE":
            calc_bill = cur.callfunc("fn_calculate_inpatient_bill", oracledb.NUMBER, [sel_adm_id])
        else:
            calc_bill = local_calculate_inpatient_bill(conn, sel_adm_id)

        st.info(f"💡 **Estimated Inpatient Payable Bill (via `fn_calculate_inpatient_bill`):** ₹ {calc_bill:,.2f}")

        payment_mode = st.selectbox("Payment Mode", ["UPI", "CREDIT_CARD", "DEBIT_CARD", "CASH", "INSURANCE_CLAIM"])

        if st.button("Finalize Discharge & Issue Invoice (sp_discharge_patient)"):
            if db_mode == "ORACLE":
                out_inv_id = cur.var(oracledb.NUMBER)
                out_final_bill = cur.var(oracledb.NUMBER)
                out_msg = cur.var(oracledb.STRING)
                try:
                    cur.callproc("sp_discharge_patient", [sel_adm_id, payment_mode, out_inv_id, out_final_bill, out_msg])
                    st.success(out_msg.getvalue())
                except Exception as ex:
                    st.error(f"Error during discharge: {ex}")
            else:
                success, inv_id, final_bill, msg = local_discharge_patient(conn, sel_adm_id, payment_mode)
                if success:
                    st.success(msg)
                else:
                    st.error(msg)

    st.markdown("---")
    st.subheader("📑 Settled Billing Invoices")
    invoices_df = query_df("""
        SELECT i.invoice_id, 
               p.first_name || ' ' || p.last_name as patient_name,
               TO_CHAR(i.invoice_date, 'YYYY-MM-DD') as invoice_date,
               i.room_charges, i.doctor_fees, i.test_charges, i.discount_amount,
               i.net_payable, i.payment_status, i.payment_mode
        FROM billing_invoices i
        JOIN patients p ON i.patient_id = p.patient_id
        ORDER BY i.invoice_id DESC
    """)
    st.dataframe(invoices_df, width="stretch", hide_index=True)

# =============================================================================
# 4. APPOINTMENTS MODULE
# =============================================================================
elif menu == "📅 Doctor Appointments":
    st.markdown('<p class="main-header">Outpatient Appointment Scheduling</p>', unsafe_allow_html=True)
    st.markdown('<p class="sub-header">Demonstrating Trigger Enforcement against Double Booking (<code>trg_prevent_double_booking</code>)</p>', unsafe_allow_html=True)

    cur = get_cursor()
    patients_df = query_df("SELECT patient_id, first_name || ' ' || last_name as name FROM patients ORDER BY patient_id")
    pat_dict = dict(zip(patients_df['name'], patients_df['patient_id']))

    doctors_df = query_df("SELECT doctor_id, 'Dr. ' || first_name || ' ' || last_name || ' (' || specialization || ')' as doc_name FROM doctors ORDER BY doctor_id")
    doc_dict = dict(zip(doctors_df['doc_name'], doctors_df['doctor_id']))

    with st.form("apt_form"):
        col1, col2 = st.columns(2)
        with col1:
            sel_pat = st.selectbox("Select Patient", list(pat_dict.keys()))
            sel_doc = st.selectbox("Select Doctor", list(doc_dict.keys()))
        with col2:
            apt_date = st.date_input("Appointment Date", date(2026, 10, 18))
            slot = st.selectbox("Time Slot", [
                "09:00 - 09:30", "09:30 - 10:00", "10:00 - 10:30",
                "10:30 - 11:00", "11:00 - 11:30", "11:30 - 12:00",
                "14:00 - 14:30", "14:30 - 15:00", "15:00 - 15:30"
            ])
        notes = st.text_input("Appointment Notes", "General Consultation")
        book_btn = st.form_submit_button("Book Appointment")

        if book_btn:
            p_id = pat_dict[sel_pat]
            d_id = doc_dict[sel_doc]
            
            if db_mode == "ORACLE":
                out_apt_id = cur.var(oracledb.NUMBER)
                out_msg = cur.var(oracledb.STRING)
                try:
                    cur.callproc("sp_schedule_appointment", [
                        p_id, d_id, datetime.combine(apt_date, datetime.min.time()), slot, notes, out_apt_id, out_msg
                    ])
                    msg = out_msg.getvalue()
                    if "SUCCESS" in msg:
                        st.success(msg)
                    else:
                        st.error(msg)
                except Exception as e:
                    st.error(f"Trigger / Database Exception: {e}")
            else:
                try:
                    success, apt_id, msg = local_schedule_appointment(conn, p_id, d_id, str(apt_date), slot, notes)
                    st.success(msg)
                except Exception as e:
                    st.error(f"Trigger / Constraint Violation: {e}")

    st.subheader("📋 Scheduled Appointments Roster")
    apts_df = query_df("""
        SELECT a.appointment_id,
               TO_CHAR(a.appointment_date, 'YYYY-MM-DD') as appointment_date,
               a.time_slot,
               'Dr. ' || d.first_name || ' ' || d.last_name as doctor_name,
               p.first_name || ' ' || p.last_name as patient_name,
               a.status, a.notes
        FROM appointments a
        JOIN doctors d ON a.doctor_id = d.doctor_id
        JOIN patients p ON a.patient_id = p.patient_id
        ORDER BY a.appointment_date, a.time_slot
    """)
    st.dataframe(apts_df, width="stretch", hide_index=True)

# =============================================================================
# 5. AUDIT & PL/SQL CONSOLE
# =============================================================================
elif menu == "🛡️ Audit & PL/SQL Console":
    st.markdown('<p class="main-header">System Audit Trail & PL/SQL Execution Console</p>', unsafe_allow_html=True)
    st.markdown('<p class="sub-header">Live monitoring of trigger-generated audit trails and package diagnostics</p>', unsafe_allow_html=True)

    st.subheader("🔍 Trigger Audit Log (AUDIT_BILLING_LOG)")
    audit_df = query_df("""
        SELECT audit_id, invoice_id, old_net_payable, new_net_payable,
               old_status, new_status, action_type, modified_by,
               TO_CHAR(modified_at, 'YYYY-MM-DD HH24:MI:SS') as modified_at
        FROM audit_billing_log
        ORDER BY audit_id DESC
    """)
    st.dataframe(audit_df, width="stretch", hide_index=True)

    st.markdown("---")
    st.subheader("⚡ Live Package Test (pkg_hospital_billing.apply_waiver_discount)")
    
    col1, col2 = st.columns(2)
    with col1:
        inv_to_disc = st.number_input("Invoice ID to Apply Discount", value=9001, step=1)
        disc_percent = st.slider("Discount Percentage (%)", min_value=5, max_value=40, value=15, step=5)
    
    if st.button("Apply Discount via Package"):
        if db_mode == "ORACLE":
            cur = get_cursor()
            out_revised = cur.var(oracledb.NUMBER)
            out_msg = cur.var(oracledb.STRING)
            try:
                cur.callproc("pkg_hospital_billing.apply_waiver_discount", [
                    inv_to_disc, disc_percent / 100.0, out_revised, out_msg
                ])
                msg_val = out_msg.getvalue()
                if "SUCCESS" in msg_val:
                    st.success(msg_val)
                else:
                    st.warning(msg_val)
            except Exception as ex:
                st.error(f"Package execution error: {ex}")
        else:
            success, revised_val, msg_val = local_apply_waiver_discount(conn, int(inv_to_disc), disc_percent / 100.0)
            if success:
                st.success(msg_val)
            else:
                st.warning(msg_val)
