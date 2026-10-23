-- PulseCare Trigger Demonstration & Audit Log Verification Script
SET DEFINE OFF;
SET LINESIZE 120
SET PAGESIZE 50

PROMPT ============================================================================
PROMPT PULSECARE - TRIGGER EXECUTION & AUDIT TRAIL VERIFICATION
PROMPT ============================================================================
PROMPT
PROMPT 1. Testing Trigger: trg_prevent_double_booking (Collision Prevention)
PROMPT Attempting to book conflicting slot for Dr. 102 on 2026-10-18 (10:00 - 10:30)...
PROMPT

INSERT INTO appointments (appointment_id, patient_id, doctor_id, appointment_date, time_slot, status, notes)
VALUES (seq_appointment_id.NEXTVAL, 1007, 102, TO_DATE('2026-10-18', 'YYYY-MM-DD'), '10:00 - 10:30', 'SCHEDULED', 'Clashing slot demonstration');

PROMPT
PROMPT 2. Testing Trigger: trg_audit_billing_changes (Audit Trail Contents)
PROMPT Displaying contents of AUDIT_BILLING_LOG table:
PROMPT

COLUMN audit_id FORMAT 9999 HEADING "AUDIT_ID"
COLUMN invoice_id FORMAT 9999 HEADING "INV_ID"
COLUMN old_net_payable FORMAT 99990.99 HEADING "OLD_PAYABLE"
COLUMN new_net_payable FORMAT 99990.99 HEADING "NEW_PAYABLE"
COLUMN old_status FORMAT A10 HEADING "OLD_STAT"
COLUMN new_status FORMAT A10 HEADING "NEW_STAT"
COLUMN action_type FORMAT A16 HEADING "ACTION_TYPE"
COLUMN modified_by FORMAT A15 HEADING "MODIFIED_BY"

SELECT audit_id, invoice_id, old_net_payable, new_net_payable, old_status, new_status, action_type, modified_by
FROM audit_billing_log
ORDER BY audit_id;

PROMPT
PROMPT ============================================================================
PROMPT TRIGGER VERIFICATION AND AUDIT LOGGING COMPLETED
PROMPT ============================================================================
