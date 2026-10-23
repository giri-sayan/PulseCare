-- overview.sql: Display complete PulseCare Database status in one shot
SET LINESIZE 150;
SET PAGESIZE 100;
SET FEEDBACK OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================================
PROMPT               PULSECARE HOSPITAL MANAGEMENT SYSTEM - MASTER DATABASE OVERVIEW
PROMPT =========================================================================================

PROMPT
PROMPT 1. SCHEMA OBJECT SUMMARY
SELECT object_type, COUNT(*) AS object_count 
FROM user_objects 
GROUP BY object_type 
ORDER BY object_type;

PROMPT
PROMPT 2. TABLE RECORD COUNTS (LIVE)
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('TABLE NAME', 32) || 'RECORD COUNT');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    FOR t IN (SELECT table_name FROM user_tables ORDER BY table_name) LOOP
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || t.table_name || '"' INTO v_count;
        DBMS_OUTPUT.PUT_LINE(RPAD(t.table_name, 32) || LPAD(TO_CHAR(v_count), 12));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
END;
/

PROMPT
PROMPT 3. ACTIVE INPATIENT ADMISSIONS & BEDS
COLUMN admission_id FORMAT 9999 HEADING "ADM_ID"
COLUMN patient_id FORMAT 9999 HEADING "PAT_ID"
COLUMN doctor_id FORMAT 9999 HEADING "DOC_ID"
COLUMN bed_id FORMAT 9999 HEADING "BED_ID"
COLUMN admission_date FORMAT A11 HEADING "ADM_DATE"
COLUMN discharge_date FORMAT A11 HEADING "DISC_DATE"
COLUMN diagnosis FORMAT A25 HEADING "DIAGNOSIS"
COLUMN status FORMAT A12 HEADING "STATUS"

SELECT admission_id, patient_id, doctor_id, bed_id, 
       TO_CHAR(admission_date, 'YYYY-MM-DD') AS admission_date,
       TO_CHAR(discharge_date, 'YYYY-MM-DD') AS discharge_date,
       diagnosis, status
FROM inpatient_admissions
ORDER BY admission_id;

PROMPT
PROMPT 4. BILLING INVOICES & SETTLEMENTS
COLUMN invoice_id FORMAT 9999 HEADING "INV_ID"
COLUMN gross_total FORMAT 999990.99 HEADING "GROSS_TOT"
COLUMN discount_amount FORMAT 99990.99 HEADING "DISCOUNT"
COLUMN insurance_covered FORMAT 999990.99 HEADING "INSURANCE"
COLUMN net_payable FORMAT 999990.99 HEADING "NET_PAYABLE"
COLUMN payment_status FORMAT A10 HEADING "STATUS"
COLUMN payment_mode FORMAT A12 HEADING "PAY_MODE"

SELECT invoice_id, admission_id, patient_id, gross_total, discount_amount, 
       insurance_covered, net_payable, payment_status, payment_mode
FROM billing_invoices
ORDER BY invoice_id;

PROMPT
PROMPT 5. AUDIT TRAIL LOG (TRIGGER RECORDINGS)
COLUMN audit_id FORMAT 9999 HEADING "AUDIT_ID"
COLUMN old_net_payable FORMAT 999990.99 HEADING "OLD_NET"
COLUMN new_net_payable FORMAT 999990.99 HEADING "NEW_NET"
COLUMN old_status FORMAT A10 HEADING "OLD_STAT"
COLUMN new_status FORMAT A10 HEADING "NEW_STAT"
COLUMN action_type FORMAT A16 HEADING "ACTION_TYPE"
COLUMN modified_by FORMAT A15 HEADING "MODIFIED_BY"

SELECT audit_id, invoice_id, old_net_payable, new_net_payable, 
       old_status, new_status, action_type, modified_by
FROM audit_billing_log
ORDER BY audit_id;

PROMPT =========================================================================================
PROMPT                        OVERVIEW EXECUTION COMPLETED
PROMPT =========================================================================================
SET FEEDBACK ON;
