# PulseCare: Smart Hospital Resource, Inpatient Admission & Clinical Billing Management System

[![Oracle 21c XE](https://img.shields.io/badge/Database-Oracle%2021c%20XE-F80000?style=for-the-badge&logo=oracle&logoColor=white)](https://www.oracle.com/database/)
[![PL/SQL](https://img.shields.io/badge/Language-PL%2FSQL-orange?style=for-the-badge)](https://en.wikipedia.org/wiki/PL/SQL)
[![Python 3.12](https://img.shields.io/badge/Backend-Python%203.12-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Streamlit](https://img.shields.io/badge/Web%20Dashboard-Streamlit-FF4B4B?style=for-the-badge&logo=streamlit&logoColor=white)](https://streamlit.io/)
[![PWA Mobile](https://img.shields.io/badge/Mobile-PWA%20Ready-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)

**PulseCare** is an enterprise-grade hospital clinical resource, inpatient admission, ward occupancy, and automated medical billing management system. Built upon Oracle Database 21c XE with PL/SQL business logic, it provides both an interactive desktop web dashboard (Streamlit) and a mobile Progressive Web Application (PWA).

---

## 📁 Repository Structure

```
PulseCare/
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
│   ├── 00_init_user.sql                   # User & tablespace provisioning
│   ├── 01_schema_ddl.sql                  # 12 Normalized Relational Tables (BCNF), Constraints & Sequences
│   ├── 02_seed_data.sql                   # Realistic Hospital Clinical & Operational Seed Data
│   ├── 03_functions.sql                   # Stored Functions (fn_calculate_inpatient_bill, fn_check_bed_availability)
│   ├── 04_procedures.sql                  # Stored Procedures (sp_admit_patient, sp_discharge_patient, etc.)
│   ├── 05_packages.sql                    # Package pkg_hospital_billing (Spec & Body)
│   ├── 06_triggers.sql                    # Triggers (trg_prevent_double_booking Compound Trigger, etc.)
│   ├── 07_cursors.sql                     # Parameterized Cursors & Cursor FOR Loops
│   ├── 08_test_suite.sql                  # Automated Test Harness executing TC01 to TC11
│   ├── demo_triggers.sql                  # Interactive trigger enforcement demonstration
│   ├── master_setup.sql                   # One-shot master schema setup runner
│   └── overview.sql                       # Database schema metrics & verification summary
├── app/
│   ├── main.py                            # Multi-Page Streamlit Web Front-End (Direct Oracle Integration)
│   ├── local_db.py                        # Local SQLite offline caching layer
│   └── pulsecare.db                       # Pre-seeded local SQLite fallback database
└── mobile/                                # Progressive Web Application (PWA) for Mobile Devices
    ├── index.html                         # Mobile UI (Bottom navigation, responsive cards, touch UX)
    ├── manifest.json                      # PWA web manifest (PulseCare Hospital)
    ├── sw.js                              # Service Worker for offline capability & caching
    ├── server.py                          # Lightweight HTTP server & RESTful API bridge
    ├── icon-192.png                       # App icon (192x192)
    └── icon-512.png                       # App icon (512x512)
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

## 🚀 Getting Started

### 1. Initialize Database & Run Test Suite
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

## 📄 License
This project is released under the MIT Open Source License.
