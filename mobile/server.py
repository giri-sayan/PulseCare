"""
PulseCare Mobile Application - Flask REST API & PWA Server
Connects directly to Oracle Database 21c XE (localhost:1521/XEPDB1)
with automatic fallback to local high-performance SQLite engine.
"""

from flask import Flask, jsonify, request, send_from_directory
import os
import sys
import socket
from datetime import datetime, date

# Ensure project root is in sys.path so 'app.local_db' imports reliably
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

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

STATIC_DIR = os.path.dirname(os.path.abspath(__file__))
app = Flask(__name__, static_folder=STATIC_DIR, static_url_path="")

def ensure_icons():
    """Generates crisp medical cross PWA icons if not present"""
    icon_192 = os.path.join(STATIC_DIR, "icon-192.png")
    icon_512 = os.path.join(STATIC_DIR, "icon-512.png")
    root_icon = os.path.join(PROJECT_ROOT, "pulsecare_icon.png")
    if not os.path.exists(icon_192) or not os.path.exists(icon_512):
        try:
            from PIL import Image, ImageDraw
            for size, path in [(192, icon_192), (512, icon_512)]:
                img = Image.new("RGBA", (size, size), (30, 58, 138, 255))
                draw = ImageDraw.Draw(img)
                # Draw white medical cross
                cross_w = int(size * 0.18)
                cross_len = int(size * 0.6)
                offset = (size - cross_len) // 2
                mid = (size - cross_w) // 2
                draw.rectangle([mid, offset, mid + cross_w, offset + cross_len], fill="white")
                draw.rectangle([offset, mid, offset + cross_len, mid + cross_w], fill="white")
                img.save(path, "PNG")
                if size == 512:
                    img.save(root_icon, "PNG")
        except Exception:
            pass
    elif not os.path.exists(root_icon) and os.path.exists(icon_512):
        try:
            import shutil
            shutil.copyfile(icon_512, root_icon)
        except Exception:
            pass

ensure_icons()

# Oracle Database Connection
def get_db():
    if ORACLE_AVAILABLE:
        try:
            conn = oracledb.connect(
                user="PULSECARE_DB",
                password="PulseCare#2026",
                dsn="localhost:1521/XEPDB1"
            )
            return conn, "ORACLE"
        except Exception:
            pass
    conn = init_local_db()
    return conn, "LOCAL"

# ---------------------------------------------------------------------------
# Static PWA Routes
# ---------------------------------------------------------------------------
@app.route("/")
def index():
    return send_from_directory(STATIC_DIR, "index.html")

@app.route("/manifest.json")
def manifest():
    return send_from_directory(STATIC_DIR, "manifest.json")

@app.route("/sw.js")
def service_worker():
    return send_from_directory(STATIC_DIR, "sw.js")

@app.route("/icon-192.png")
def icon_192():
    return send_from_directory(STATIC_DIR, "icon-192.png")

@app.route("/icon-512.png")
def icon_512():
    return send_from_directory(STATIC_DIR, "icon-512.png")

# ---------------------------------------------------------------------------
# API Endpoints
# ---------------------------------------------------------------------------
@app.route("/api/status")
def api_status():
    conn, mode = get_db()
    conn.close()
    return jsonify({
        "status": "online",
        "mode": mode,
        "engine": "Oracle Database 21c XE (Live)" if mode == "ORACLE" else "High-Performance Local DB",
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

@app.route("/api/summary")
def api_summary():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT COUNT(*) FROM patients")
        total_patients = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM doctors")
        total_doctors = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM inpatient_admissions WHERE admission_status = 'ADMITTED'")
        active_inpatients = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM beds WHERE status = 'AVAILABLE'")
        available_beds = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM beds")
        total_beds = cur.fetchone()[0]
        
        cur.execute("SELECT NVL(SUM(net_payable), 0) FROM billing_invoices WHERE payment_status = 'PAID'" if mode == "ORACLE" else "SELECT COALESCE(SUM(net_payable), 0) FROM billing_invoices WHERE payment_status = 'PAID'")
        total_revenue = float(cur.fetchone()[0] or 0)
        
        return jsonify({
            "patients": total_patients,
            "doctors": total_doctors,
            "inpatients": active_inpatients,
            "available_beds": available_beds,
            "total_beds": total_beds,
            "revenue": total_revenue,
            "mode": mode
        })
    finally:
        conn.close()

@app.route("/api/wards")
def api_wards():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT w.ward_id, w.ward_name, w.ward_type, w.total_beds, w.daily_charge,
                   COUNT(CASE WHEN b.status = 'OCCUPIED' THEN 1 END) as occupied_count
            FROM wards w
            LEFT JOIN beds b ON w.ward_id = b.ward_id
            GROUP BY w.ward_id, w.ward_name, w.ward_type, w.total_beds, w.daily_charge
            ORDER BY w.ward_id
        """)
        rows = cur.fetchall()
        wards = []
        for r in rows:
            wards.append({
                "id": r[0],
                "name": r[1],
                "type": r[2],
                "total_beds": r[3],
                "daily_charge": float(r[4]),
                "occupied": r[5],
                "available": r[3] - r[5]
            })
        return jsonify(wards)
    finally:
        conn.close()

@app.route("/api/beds")
def api_beds():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT b.bed_id, b.bed_number, b.ward_id, w.ward_name, b.status
            FROM beds b
            JOIN wards w ON b.ward_id = w.ward_id
            ORDER BY b.ward_id, b.bed_id
        """)
        rows = cur.fetchall()
        beds = []
        for r in rows:
            beds.append({
                "bed_id": r[0],
                "bed_number": r[1],
                "ward_id": r[2],
                "ward_name": r[3],
                "status": r[4]
            })
        return jsonify(beds)
    finally:
        conn.close()

@app.route("/api/patients")
def api_patients():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT patient_id, first_name, last_name, blood_group, phone FROM patients ORDER BY patient_id")
        rows = cur.fetchall()
        patients = [{"id": r[0], "name": f"{r[1]} {r[2]}", "blood": r[3], "phone": r[4]} for r in rows]
        return jsonify(patients)
    finally:
        conn.close()

@app.route("/api/doctors")
def api_doctors():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT d.doctor_id, d.first_name, d.last_name, d.specialization, d.consultation_fee, dept.dept_name FROM doctors d JOIN departments dept ON d.dept_id = dept.dept_id ORDER BY d.doctor_id")
        rows = cur.fetchall()
        doctors = [{"id": r[0], "name": f"Dr. {r[1]} {r[2]}", "spec": r[3], "fee": float(r[4]), "dept": r[5]} for r in rows]
        return jsonify(doctors)
    finally:
        conn.close()

@app.route("/api/admissions/active")
def api_active_admissions():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        if mode == "ORACLE":
            sql = """
                SELECT a.admission_id, p.first_name || ' ' || p.last_name,
                       'Dr. ' || d.first_name || ' ' || d.last_name,
                       b.bed_number, w.ward_name,
                       TO_CHAR(a.admission_date, 'YYYY-MM-DD HH24:MI'),
                       a.initial_diagnosis
                FROM inpatient_admissions a
                JOIN patients p ON a.patient_id = p.patient_id
                JOIN doctors d ON a.attending_doc_id = d.doctor_id
                JOIN beds b ON a.bed_id = b.bed_id
                JOIN wards w ON b.ward_id = w.ward_id
                WHERE a.admission_status = 'ADMITTED'
                ORDER BY a.admission_id DESC
            """
        else:
            sql = """
                SELECT a.admission_id, p.first_name || ' ' || p.last_name,
                       'Dr. ' || d.first_name || ' ' || d.last_name,
                       b.bed_number, w.ward_name,
                       SUBSTR(a.admission_date, 1, 16),
                       a.initial_diagnosis
                FROM inpatient_admissions a
                JOIN patients p ON a.patient_id = p.patient_id
                JOIN doctors d ON a.attending_doc_id = d.doctor_id
                JOIN beds b ON a.bed_id = b.bed_id
                JOIN wards w ON b.ward_id = w.ward_id
                WHERE a.admission_status = 'ADMITTED'
                ORDER BY a.admission_id DESC
            """
        cur.execute(sql)
        rows = cur.fetchall()
        admissions = []
        for r in rows:
            admissions.append({
                "admission_id": r[0],
                "patient": r[1],
                "doctor": r[2],
                "bed": r[3],
                "ward": r[4],
                "admitted_at": r[5],
                "diagnosis": r[6]
            })
        return jsonify(admissions)
    finally:
        conn.close()

@app.route("/api/admit", methods=["POST"])
def api_admit():
    data = request.json or {}
    patient_id = int(data.get("patient_id", 0))
    bed_id = int(data.get("bed_id", 0))
    doctor_id = int(data.get("doctor_id", 0))
    diagnosis = str(data.get("diagnosis", "Observation")).strip()
    
    conn, mode = get_db()
    try:
        if mode == "ORACLE":
            cur = conn.cursor()
            out_adm_id = cur.var(oracledb.NUMBER)
            out_msg = cur.var(oracledb.STRING)
            cur.callproc("sp_admit_patient", [patient_id, bed_id, doctor_id, diagnosis, out_adm_id, out_msg])
            msg = out_msg.getvalue()
            if "SUCCESS" in msg:
                return jsonify({"success": True, "message": msg, "admission_id": out_adm_id.getvalue()})
            else:
                return jsonify({"success": False, "message": msg}), 400
        else:
            success, adm_id, msg = local_admit_patient(conn, patient_id, bed_id, doctor_id, diagnosis)
            if success:
                return jsonify({"success": True, "message": msg, "admission_id": adm_id})
            return jsonify({"success": False, "message": msg}), 400
    except Exception as e:
        return jsonify({"success": False, "message": f"Database Error: {str(e)}"}), 500
    finally:
        conn.close()

@app.route("/api/discharge", methods=["POST"])
def api_discharge():
    data = request.json or {}
    admission_id = int(data.get("admission_id", 0))
    pay_mode = str(data.get("payment_mode", "UPI")).strip()
    
    conn, mode = get_db()
    try:
        if mode == "ORACLE":
            cur = conn.cursor()
            out_inv_id = cur.var(oracledb.NUMBER)
            out_bill = cur.var(oracledb.NUMBER)
            out_msg = cur.var(oracledb.STRING)
            cur.callproc("sp_discharge_patient", [admission_id, pay_mode, out_inv_id, out_bill, out_msg])
            msg = out_msg.getvalue()
            if "SUCCESS" in msg:
                return jsonify({
                    "success": True,
                    "message": msg,
                    "invoice_id": out_inv_id.getvalue(),
                    "total_bill": out_bill.getvalue()
                })
            return jsonify({"success": False, "message": msg}), 400
        else:
            success, inv_id, bill, msg = local_discharge_patient(conn, admission_id, pay_mode)
            if success:
                return jsonify({"success": True, "message": msg, "invoice_id": inv_id, "total_bill": bill})
            return jsonify({"success": False, "message": msg}), 400
    except Exception as e:
        return jsonify({"success": False, "message": f"Discharge Error: {str(e)}"}), 500
    finally:
        conn.close()

@app.route("/api/appointments")
def api_appointments():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        if mode == "ORACLE":
            sql = """
                SELECT a.appointment_id,
                       TO_CHAR(a.appointment_date, 'YYYY-MM-DD'),
                       a.time_slot,
                       'Dr. ' || d.first_name || ' ' || d.last_name,
                       p.first_name || ' ' || p.last_name,
                       a.status, a.notes
                FROM appointments a
                JOIN doctors d ON a.doctor_id = d.doctor_id
                JOIN patients p ON a.patient_id = p.patient_id
                ORDER BY a.appointment_date DESC, a.time_slot
            """
        else:
            sql = """
                SELECT a.appointment_id,
                       SUBSTR(a.appointment_date, 1, 10),
                       a.time_slot,
                       'Dr. ' || d.first_name || ' ' || d.last_name,
                       p.first_name || ' ' || p.last_name,
                       a.status, a.notes
                FROM appointments a
                JOIN doctors d ON a.doctor_id = d.doctor_id
                JOIN patients p ON a.patient_id = p.patient_id
                ORDER BY a.appointment_date DESC, a.time_slot
            """
        cur.execute(sql)
        rows = cur.fetchall()
        apts = []
        for r in rows:
            apts.append({
                "id": r[0],
                "date": r[1],
                "slot": r[2],
                "doctor": r[3],
                "patient": r[4],
                "status": r[5],
                "notes": r[6]
            })
        return jsonify(apts)
    finally:
        conn.close()

@app.route("/api/appointments/book", methods=["POST"])
def api_book_appointment():
    data = request.json or {}
    patient_id = int(data.get("patient_id", 0))
    doctor_id = int(data.get("doctor_id", 0))
    apt_date_str = str(data.get("date", "2026-10-18")).strip()
    slot = str(data.get("time_slot", "10:00 - 10:30")).strip()
    notes = str(data.get("notes", "General OPD")).strip()
    
    conn, mode = get_db()
    try:
        if mode == "ORACLE":
            cur = conn.cursor()
            out_apt_id = cur.var(oracledb.NUMBER)
            out_msg = cur.var(oracledb.STRING)
            try:
                cur.callproc("sp_schedule_appointment", [
                    patient_id, doctor_id, datetime.strptime(apt_date_str, "%Y-%m-%d"),
                    slot, notes, out_apt_id, out_msg
                ])
                msg = out_msg.getvalue()
                if "SUCCESS" in msg:
                    return jsonify({"success": True, "message": msg, "appointment_id": out_apt_id.getvalue()})
                return jsonify({"success": False, "message": msg}), 400
            except Exception as trigger_err:
                # Catches ORA-20001 double-booking trigger error!
                return jsonify({
                    "success": False,
                    "message": f"Trigger Violation: {str(trigger_err)}",
                    "is_trigger_error": True
                }), 400
        else:
            try:
                success, apt_id, msg = local_schedule_appointment(conn, patient_id, doctor_id, apt_date_str, slot, notes)
                if success:
                    return jsonify({"success": True, "message": msg, "appointment_id": apt_id})
                return jsonify({"success": False, "message": msg}), 400
            except Exception as ex:
                return jsonify({"success": False, "message": f"Trigger Conflict: {str(ex)}", "is_trigger_error": True}), 400
    finally:
        conn.close()

@app.route("/api/discount", methods=["POST"])
def api_discount():
    data = request.json or {}
    invoice_id = int(data.get("invoice_id", 9001))
    pct = float(data.get("discount_pct", 15)) / 100.0
    
    conn, mode = get_db()
    try:
        if mode == "ORACLE":
            cur = conn.cursor()
            out_revised = cur.var(oracledb.NUMBER)
            out_msg = cur.var(oracledb.STRING)
            cur.callproc("pkg_hospital_billing.apply_waiver_discount", [invoice_id, pct, out_revised, out_msg])
            msg = out_msg.getvalue()
            if "SUCCESS" in msg:
                return jsonify({"success": True, "message": msg, "revised_payable": out_revised.getvalue()})
            return jsonify({"success": False, "message": msg}), 400
        else:
            success, revised, msg = local_apply_waiver_discount(conn, invoice_id, pct)
            if success:
                return jsonify({"success": True, "message": msg, "revised_payable": revised})
            return jsonify({"success": False, "message": msg}), 400
    except Exception as e:
        return jsonify({"success": False, "message": f"Package Error: {str(e)}"}), 500
    finally:
        conn.close()

@app.route("/api/audit")
def api_audit():
    conn, mode = get_db()
    cur = conn.cursor()
    try:
        if mode == "ORACLE":
            sql = """
                SELECT audit_id, invoice_id, old_net_payable, new_net_payable,
                       old_status, new_status, action_type, modified_by,
                       TO_CHAR(modified_at, 'YYYY-MM-DD HH24:MI:SS')
                FROM audit_billing_log
                ORDER BY audit_id DESC
                FETCH FIRST 15 ROWS ONLY
            """
        else:
            sql = """
                SELECT audit_id, invoice_id, old_net_payable, new_net_payable,
                       old_status, new_status, action_type, modified_by,
                       modified_at
                FROM audit_billing_log
                ORDER BY audit_id DESC
                LIMIT 15
            """
        cur.execute(sql)
        rows = cur.fetchall()
        logs = []
        for r in rows:
            logs.append({
                "audit_id": r[0],
                "invoice_id": r[1],
                "old_net": float(r[2]) if r[2] is not None else "-",
                "new_net": float(r[3]) if r[3] is not None else "-",
                "old_status": r[4] or "-",
                "new_status": r[5] or "-",
                "action": r[6],
                "user": r[7],
                "time": r[8]
            })
        return jsonify(logs)
    finally:
        conn.close()

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

if __name__ == "__main__":
    local_ip = get_local_ip()
    port = 5000
    print("=" * 65)
    print("  PULSECARE MOBILE APPLICATION SERVER (PWA)")
    print("=" * 65)
    print(f"  Local Laptop View  : http://localhost:{port}")
    print(f"  Mobile Phone View  : http://{local_ip}:{port}")
    print("=" * 65)
    print("  Connect your mobile phone to the same Wi-Fi and open the Mobile URL.")
    print("  Tap 'Install PulseCare' or 'Add to Home Screen' on your phone!")
    print("=" * 65)
    app.run(host="0.0.0.0", port=port, debug=False)
