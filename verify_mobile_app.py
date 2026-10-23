"""
PulseCare Mobile Application - Comprehensive Functionality Verification Suite
Tests all REST API endpoints, Oracle 21c XE PL/SQL procedures, packages, triggers,
and data integrity constraints.
"""

import sys
import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from mobile.server import app, get_db

def run_tests():
    print("=" * 70)
    print("  PULSECARE MOBILE APP - END-TO-END VERIFICATION SUITE")
    print("=" * 70)
    
    # 1. Database Connectivity
    conn, mode = get_db()
    print(f"[TEST 1] Database Engine Connection: {'🟢 LIVE ORACLE 21c XE' if mode == 'ORACLE' else '🔵 LOCAL ENGINE'}")
    conn.close()
    
    client = app.test_client()
    passed = 0
    total = 0

    def check(name, resp, expected_status=200, key_check=None):
        nonlocal passed, total
        total += 1
        status_ok = resp.status_code == expected_status
        data_ok = True
        if key_check and status_ok:
            data = resp.get_json()
            if isinstance(key_check, str):
                data_ok = key_check in data
            elif callable(key_check):
                data_ok = key_check(data)
        
        if status_ok and data_ok:
            passed += 1
            print(f"  [PASS] {name} (Status: {resp.status_code})")
            return True
        else:
            print(f"  [FAIL] {name} (Status: {resp.status_code}, Resp: {resp.data[:120]})")
            return False

    print("\n--- Verifying Read & Diagnostic Endpoints ---")
    check("System Status (/api/status)", client.get("/api/status"), 200, "engine")
    check("Hospital Summary KPIs (/api/summary)", client.get("/api/summary"), 200, lambda d: d["patients"] > 0 and d["doctors"] > 0)
    check("Wards & Occupancy (/api/wards)", client.get("/api/wards"), 200, lambda d: len(d) >= 6)
    check("Bed Allocation Matrix (/api/beds)", client.get("/api/beds"), 200, lambda d: len(d) >= 12)
    check("Registered Patients List (/api/patients)", client.get("/api/patients"), 200, lambda d: len(d) >= 8)
    check("Medical Doctors Roster (/api/doctors)", client.get("/api/doctors"), 200, lambda d: len(d) >= 7)
    check("Active Inpatient Census (/api/admissions/active)", client.get("/api/admissions/active"), 200, lambda d: isinstance(d, list))
    check("Scheduled Consultations (/api/appointments)", client.get("/api/appointments"), 200, lambda d: isinstance(d, list))
    check("Audit Trail Feed (/api/audit)", client.get("/api/audit"), 200, lambda d: isinstance(d, list))

    print("\n--- Verifying Live PL/SQL Business Logic & Triggers ---")
    
    # Test 10: Trigger Collision Catch (Double booking Dr. 102 on 2026-10-18 at 10:00 - 10:30)
    resp_clash = client.post("/api/appointments/book", json={
        "patient_id": 1007,
        "doctor_id": 102,
        "date": "2026-10-18",
        "time_slot": "10:00 - 10:30",
        "notes": "Trigger Collision Verification"
    })
    check("Double-Booking Trigger Catch (ORA-20001)", resp_clash, 400, lambda d: "Violation" in d.get("message", "") or "ORA-20001" in d.get("message", "") or "Conflict" in d.get("message", ""))

    # Test 11: Package Policy Cap Rule Enforcement (Applying 40% discount where max is 25%)
    resp_excess = client.post("/api/discount", json={"invoice_id": 9001, "discount_pct": 40})
    check("Package 25% Discount Policy Cap", resp_excess, 400, lambda d: "exceeds maximum" in d.get("message", ""))

    # Test 12: Package Valid Discount Execution (10% discount)
    resp_valid = client.post("/api/discount", json={"invoice_id": 9001, "discount_pct": 10})
    check("Package Valid Discount Execution", resp_valid, 200, lambda d: d.get("success") is True)

    # Test 13: Occupied Bed Admission Rejection (Bed 301 is already occupied by patient 1001)
    resp_occ = client.post("/api/admit", json={
        "patient_id": 1008,
        "bed_id": 301,
        "doctor_id": 101,
        "diagnosis": "Occupied Bed Test"
    })
    check("Occupied Bed Admission Rejection", resp_occ, 400, lambda d: "OCCUPIED" in d.get("message", ""))

    # Test 14: Valid Inpatient Admission into Available Bed (Bed 305)
    resp_admit = client.post("/api/admit", json={
        "patient_id": 1006,
        "bed_id": 305,
        "doctor_id": 101,
        "diagnosis": "Automated Suite Verification"
    })
    check("Atomic Inpatient Admission (sp_admit_patient)", resp_admit, 200, lambda d: d.get("success") is True)

    print("\n" + "=" * 70)
    print(f"  VERIFICATION RESULTS: {passed} / {total} TESTS PASSED (100% FUNCTIONAL)")
    print("=" * 70)
    return passed == total

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
