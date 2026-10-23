"""
Generate Clean, High-Legibility Professional ER Diagram for PulseCare HMS
Course: BCSE302P - Database Systems Laboratory
Student: Sayan Giri (24BCT0281)
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches

fig, ax = plt.subplots(figsize=(13, 9.5), dpi=300)
ax.set_facecolor('#FFFFFF')
fig.patch.set_facecolor('#FFFFFF')
ax.axis('off')

# Title & Subtitle
ax.text(6.5, 9.2, "PulseCare Hospital Management System - Entity Relationship Diagram", 
        fontsize=15, fontweight='bold', color='#0F172A', ha='center')
ax.text(6.5, 8.9, "Oracle Database 21c XE | 12 Relational Entities in Boyce-Codd Normal Form (BCNF)", 
        fontsize=10, color='#475569', ha='center')

def draw_table_card(ax, x, y, width, height, title, rows, pks=None, fks=None):
    if pks is None: pks = []
    if fks is None: fks = []
    
    # Header
    hdr_h = 0.36
    hdr = patches.Rectangle((x, y + height - hdr_h), width, hdr_h, facecolor='#1E3A8A', edgecolor='#0F172A', lw=1.2, zorder=3)
    ax.add_patch(hdr)
    ax.text(x + width/2, y + height - hdr_h/2, title, color='white', fontsize=8.5, fontweight='bold', ha='center', va='center', zorder=4)
    
    # Body
    body = patches.Rectangle((x, y), width, height - hdr_h, facecolor='#F8FAFC', edgecolor='#0F172A', lw=1.2, zorder=2)
    ax.add_patch(body)
    
    # Row items
    num_rows = len(rows)
    row_step = (height - hdr_h) / max(num_rows, 1)
    for i, r_text in enumerate(rows):
        curr_y = y + height - hdr_h - (i + 0.5) * row_step
        col = '#0F172A'
        weight = 'normal'
        prefix = "  "
        if i in pks:
            col = '#B91C1C'
            weight = 'bold'
            prefix = "PK "
        elif i in fks:
            col = '#1D4ED8'
            weight = 'bold'
            prefix = "FK "
        ax.text(x + 0.08, curr_y, prefix + r_text, fontsize=7.2, fontweight=weight, color=col, va='center', zorder=4)

# Grid Layout of 12 Tables
# Row 1: Top (Departments, Doctors, Appointments, Patients)
draw_table_card(ax, 0.4, 6.7, 2.5, 1.9, "DEPARTMENTS", 
                ["dept_id NUMBER", "dept_name VARCHAR2", "building_block VARCHAR2", "contact_phone VARCHAR2"], [0], [])

draw_table_card(ax, 3.5, 6.3, 2.7, 2.3, "DOCTORS", 
                ["doctor_id NUMBER", "dept_id NUMBER", "first_name VARCHAR2", "last_name VARCHAR2", 
                 "specialization VARCHAR2", "consultation_fee NUMBER"], [0], [1])

draw_table_card(ax, 6.8, 6.4, 2.7, 2.2, "APPOINTMENTS", 
                ["appointment_id NUMBER", "patient_id NUMBER", "doctor_id NUMBER", 
                 "appointment_date DATE", "time_slot VARCHAR2", "status VARCHAR2"], [0], [1, 2])

draw_table_card(ax, 10.1, 6.3, 2.5, 2.3, "PATIENTS", 
                ["patient_id NUMBER", "first_name VARCHAR2", "last_name VARCHAR2", "dob DATE", 
                 "gender VARCHAR2", "blood_group VARCHAR2", "phone VARCHAR2"], [0], [])

# Row 2: Middle (Wards, Beds, Inpatient Admissions, Diagnostic Tests)
draw_table_card(ax, 0.4, 3.6, 2.5, 2.0, "WARDS", 
                ["ward_id NUMBER", "ward_name VARCHAR2", "ward_type VARCHAR2", "total_beds NUMBER", "daily_charge NUMBER"], [0], [])

draw_table_card(ax, 3.5, 3.7, 2.6, 1.9, "BEDS", 
                ["bed_id NUMBER", "ward_id NUMBER", "bed_number VARCHAR2", "status VARCHAR2"], [0], [1])

draw_table_card(ax, 6.7, 3.4, 2.9, 2.3, "INPATIENT_ADMISSIONS", 
                ["admission_id NUMBER", "patient_id NUMBER", "bed_id NUMBER", "attending_doc_id NUMBER", 
                 "admission_date DATE", "discharge_date DATE", "admission_status VARCHAR2"], [0], [1, 2, 3])

draw_table_card(ax, 10.1, 3.6, 2.5, 1.9, "DIAGNOSTIC_TESTS", 
                ["test_id NUMBER", "test_name VARCHAR2", "category VARCHAR2", "standard_fee NUMBER"], [0], [])

# Row 3: Bottom (Audit Log, Billing Invoices, Test Orders, Medications)
draw_table_card(ax, 0.4, 0.8, 2.6, 2.0, "AUDIT_BILLING_LOG", 
                ["audit_id NUMBER", "invoice_id NUMBER", "old_net_payable NUMBER", "new_net_payable NUMBER", 
                 "action_type VARCHAR2", "modified_at DATE"], [0], [1])

draw_table_card(ax, 3.5, 0.7, 2.8, 2.2, "BILLING_INVOICES", 
                ["invoice_id NUMBER", "admission_id NUMBER", "patient_id NUMBER", "room_charges NUMBER", 
                 "doctor_fees NUMBER", "net_payable NUMBER", "payment_status VARCHAR2"], [0], [1, 2])

draw_table_card(ax, 6.8, 0.8, 2.8, 2.1, "PATIENT_TEST_ORDERS", 
                ["order_id NUMBER", "admission_id NUMBER", "patient_id NUMBER", "test_id NUMBER", 
                 "billed_amount NUMBER", "result_status VARCHAR2"], [0], [1, 2, 3])

draw_table_card(ax, 10.1, 0.9, 2.5, 1.8, "MEDICATIONS", 
                ["med_id NUMBER", "med_name VARCHAR2", "unit_price NUMBER", "stock_quantity NUMBER"], [0], [])

def draw_clean_rel(ax, p1, p2, label="1:N"):
    ax.plot([p1[0], p2[0]], [p1[1], p2[1]], color='#2563EB', lw=1.3, zorder=1)
    mid_x = (p1[0] + p2[0]) / 2
    mid_y = (p1[1] + p2[1]) / 2
    ax.text(mid_x, mid_y, label, fontsize=6.8, color='#1E40AF', fontweight='bold', ha='center', va='center',
            bbox=dict(boxstyle="round,pad=0.15", fc="#EFF6FF", ec="#3B82F6", lw=0.6), zorder=5)

# Relationships
# DEPARTMENTS -> DOCTORS
draw_clean_rel(ax, (2.9, 7.6), (3.5, 7.6), "1:N")

# DOCTORS -> APPOINTMENTS
draw_clean_rel(ax, (6.2, 7.5), (6.8, 7.5), "1:N")

# PATIENTS -> APPOINTMENTS
draw_clean_rel(ax, (10.1, 7.5), (9.5, 7.5), "1:N")

# WARDS -> BEDS
draw_clean_rel(ax, (2.9, 4.6), (3.5, 4.6), "1:N")

# BEDS -> INPATIENT_ADMISSIONS
draw_clean_rel(ax, (6.1, 4.5), (6.7, 4.5), "1:N")

# DOCTORS -> INPATIENT_ADMISSIONS
draw_clean_rel(ax, (4.8, 6.3), (6.7, 5.2), "1:N")

# PATIENTS -> INPATIENT_ADMISSIONS
draw_clean_rel(ax, (10.5, 6.3), (9.2, 5.4), "1:N")

# INPATIENT_ADMISSIONS -> BILLING_INVOICES
draw_clean_rel(ax, (7.0, 3.4), (5.5, 2.9), "1:1")

# BILLING_INVOICES -> AUDIT_BILLING_LOG
draw_clean_rel(ax, (3.5, 1.8), (3.0, 1.8), "1:N")

# INPATIENT_ADMISSIONS -> PATIENT_TEST_ORDERS
draw_clean_rel(ax, (8.2, 3.4), (8.2, 2.9), "1:N")

# DIAGNOSTIC_TESTS -> PATIENT_TEST_ORDERS
draw_clean_rel(ax, (10.5, 3.6), (9.2, 2.7), "1:N")

plt.subplots_adjust(left=0.01, right=0.99, top=0.95, bottom=0.02)
plt.savefig("diagrams/er_diagram.png", dpi=300)
plt.close(fig)
print("Clean, high-legibility ER diagram generated at diagrams/er_diagram.png")
