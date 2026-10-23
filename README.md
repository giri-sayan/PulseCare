# PulseCare: Smart Hospital Resource, Inpatient Admission & Clinical Billing Management System

[![Oracle 21c XE](https://img.shields.io/badge/Database-Oracle%2021c%20XE-F80000?style=for-the-badge&logo=oracle&logoColor=white)](https://www.oracle.com/database/)
[![PL/SQL](https://img.shields.io/badge/Language-PL%2FSQL-orange?style=for-the-badge)](https://en.wikipedia.org/wiki/PL/SQL)
[![Python 3.12](https://img.shields.io/badge/Backend-Python%203.12-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Streamlit](https://img.shields.io/badge/Web%20Dashboard-Streamlit-FF4B4B?style=for-the-badge&logo=streamlit&logoColor=white)](https://streamlit.io/)
[![PWA Mobile](https://img.shields.io/badge/Mobile-PWA%20Ready-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)

**Course:** BCSE302P – Database Systems Laboratory  
**Faculty Guide:** Dr. G. M. Karthik, Associate Professor, SCOPE, VIT Vellore  
**Student Name:** Sayan Giri  
**Registration Number:** 24BCT0281  
**Target Rubric Category:** **10 / 10 Marks** (Individual Submission + Complex Application with Full PL/SQL + Web Interface + Mobile PWA + Complete Test Suite Verification)

---

## 📁 Repository & File Structure

```
PulseCare/
├── BCSE302P_Project_24BCT0281.pdf         # Final submission-ready PDF (45 pages, auto-synchronized TOC)
├── pulsecare_icon.png                     # Application branding & hospital crest
├── run_app.bat                            # One-click launcher for Streamlit Web Dashboard
├── run_mobile_app.bat                     # One-click launcher for Smartphone Mobile PWA
├── run_tests.bat                          # Automated SQL*Plus verification test suite runner
├── run_trigger_demo.bat                   # Trigger & audit log demonstration
├── setup_database.bat                     # Schema creation & seed data initialization
├── verify_app.bat                         # Streamlit front-end sanity checker
├── verify_mobile_app.py                   # Automated end-to-end mobile HTTP test suite
├── view_database.bat                      # Database inspection & table counter
├── sql/                                   # Complete Oracle 21c XE PL/SQL Scripts
│   ├── 01_schema_ddl.sql                  # 12 Normalized Relational Tables (BCNF), Constraints & Sequences
│   ├── 02_seed_data.sql                   # Realistic Hospital Clinical & Operational Seed Data
│   ├── 03_functions.sql                   # Stored Functions (fn_calculate_inpatient_bill, etc.)
│   ├── 04_procedures.sql                  # Stored Procedures (sp_admit_patient, sp_discharge_patient, etc.)
│   ├── 05_packages.sql                    # Package pkg_hospital_billing (Spec & Body)
│   ├── 06_triggers.sql                    # Triggers (trg_prevent_double_booking Compound Trigger, etc.)
│   ├── 07_cursors.sql                     # Parameterized Cursors & Cursor FOR Loops
│   └── 08_test_suite.sql                  # Automated Test Harness executing TC01 to TC11
├── app/
│   └── main.py                            # Multi-Page Streamlit Web Front-End (Direct Oracle Integration)
├── mobile/                                # Progressive Web Application (PWA) for Mobile Devices
│   ├── index.html                         # Mobile UI (Bottom navigation, responsive cards, touch UX)
│   ├── manifest.json                      # PWA web manifest (PulseCare Hospital)
│   ├── sw.js                              # Service Worker for offline capability & caching
│   ├── server.py                          # Lightweight HTTP server & RESTful API bridge
│   ├── icon-192.png                       # App icon (192x192)
│   └── icon-512.png                       # App icon (512x512)
├── diagrams/
│   ├── er_diagram.png                     # High-Resolution Entity-Relationship Diagram (12 Entities)
│   └── generate_er_diagram.py             # Matplotlib script generating the ER diagram
├── screenshots/                           # High-Resolution System Captures for Report Figures
│   ├── fig_5_1_dashboard.png              # Clinical Operations Dashboard
│   ├── fig_5_2_admission_form.png         # Inpatient Admission & Bed Allocation Module
│   ├── fig_5_3_billing_settlement.png     # Inpatient Discharge & Billing Settlement Summary
│   ├── fig_6_1_test_suite_execution.png   # SQL*Plus Verification Test Suite Output
│   └── fig_6_2_trigger_execution.png      # Trigger Enforcement & Audit Log Table Output
└── report/
    ├── BCSE302P_Project_24BCT0281.docx    # Fully formatted Word Report conforming to template
    ├── BCSE302P_Project_24BCT0281.pdf     # Identical compiled PDF in report folder
    ├── build_full_report.py               # Automated master report generator script
    └── export_pdf.ps1                     # PowerShell Word COM automation for TOC & PDF export
```

---

## 🗄️ Database Credentials & Connection Details

- **DBMS:** Oracle Database 21c Express Edition (XE)
- **Pluggable Database (PDB):** `XEPDB1`
- **Host / Port:** `localhost:1521`
- **Database Schema / Username:** `PULSECARE_DB`
- **Password:** `PulseCare#2026`
- **Oracle Net Service Name:** `localhost:1521/XEPDB1`

---

## 🚀 How to Run the Application & Database Scripts

### 1. Execute SQL Scripts in Oracle SQL*Plus
Open PowerShell or Command Prompt and run:
```powershell
sqlplus PULSECARE_DB/"PulseCare#2026"@localhost:1521/XEPDB1
```
Inside SQL*Plus, run the automated test suite:
```sql
@sql/08_test_suite.sql
```
*(All 11 test cases TC01–TC11 will run and display PASS status).*

Alternatively, double-click `run_tests.bat` to execute the full automated verification test suite.

### 2. Launch the Web Front-End Dashboard (Streamlit)
Double-click `run_app.bat` or run:
```powershell
python -m streamlit run app/main.py
```
This opens the web interface in your browser (`http://localhost:8501`), featuring:
- **Hospital Dashboard:** Live ward occupancy metrics, charts, and admitted inpatient rosters.
- **Inpatient Admission:** Form invoking `sp_admit_patient` with pessimistic row locking.
- **Discharge & Billing:** Form invoking `fn_calculate_inpatient_bill` and `pkg_hospital_billing`.
- **Doctor Appointments:** Form demonstrating collision prevention via `trg_prevent_double_booking`.
- **Audit Console:** Real-time inspector for `AUDIT_BILLING_LOG`.

### 3. Launch the Mobile Smartphone Application (PWA)
Double-click `run_mobile_app.bat` or run:
```powershell
python mobile/server.py
```
This opens the mobile smartphone application interface (`http://localhost:8080`), featuring:
- **Responsive Mobile Viewport:** Bottom navigation bar, floating action buttons, and touch-optimized controls.
- **Progressive Web App (PWA):** Service worker caching and installable web manifest (`manifest.json`).
- **RESTful API Bridge:** Communicates directly with Oracle 21c backend procedures and functions.

---

## 📧 Email Submission Guidelines (As instructed by Dr. Karthik)

- **To:** `karthik.gm@vit.ac.in`
- **Subject:** `BCSE302P Mini Project – 24BCT0281 – PulseCare: Smart Hospital Resource, Inpatient Admission & Clinical Billing Management System`
- **Attachment:** `BCSE302P_Project_24BCT0281.pdf`
- **Body:**
  ```text
  Respected Sir,

  Please find attached my Mini Project Report for BCSE302P – Database Systems Laboratory.

  Project Title: PulseCare: Smart Hospital Resource, Inpatient Admission & Clinical Billing Management System
  Course Code: BCSE302P
  Submission Type: Individual Project

  Student Details:
  - Name: Sayan Giri
  - Registration Number: 24BCT0281

  Thank you.

  Sincerely,
  Sayan Giri
  ```
