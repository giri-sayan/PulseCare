-- ============================================================================
-- Project: PulseCare Smart Hospital Resource & Billing Management System
-- Script 05: PL/SQL Packages (Specification & Body)
-- Package Name: pkg_hospital_billing
-- ============================================================================

-- ============================================================================
-- PACKAGE SPECIFICATION
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_hospital_billing AS
    -- Public Constants
    c_hospital_name     CONSTANT VARCHAR2(50) := 'PulseCare Super Speciality Hospital';
    c_tax_rate          CONSTANT NUMBER(4, 2) := 0.05;  -- 5% GST on non-ICU amenities
    c_max_discount_pct  CONSTANT NUMBER(3, 2) := 0.25;  -- Max 25% waiver

    -- Custom Exceptions
    ex_invoice_not_found EXCEPTION;
    ex_already_paid      EXCEPTION;
    ex_excess_discount   EXCEPTION;

    -- Public Record & Table Types
    TYPE t_invoice_summary IS RECORD (
        invoice_id   NUMBER(8),
        patient_name VARCHAR2(80),
        net_payable  NUMBER(10, 2),
        status       VARCHAR2(15)
    );

    -- Public Cursor: retrieves all pending or partially paid invoices
    CURSOR cur_pending_invoices RETURN t_invoice_summary;

    -- Public Procedures
    PROCEDURE generate_discharge_invoice (
        p_admission_id  IN  NUMBER,
        p_payment_mode  IN  VARCHAR2,
        p_invoice_id    OUT NUMBER,
        p_net_payable   OUT NUMBER,
        p_message       OUT VARCHAR2
    );

    PROCEDURE process_invoice_payment (
        p_invoice_id    IN  NUMBER,
        p_payment_mode  IN  VARCHAR2,
        p_status_msg    OUT VARCHAR2
    );

    PROCEDURE apply_waiver_discount (
        p_invoice_id     IN  NUMBER,
        p_discount_pct   IN  NUMBER,
        p_revised_amount OUT NUMBER,
        p_message        OUT VARCHAR2
    );

    -- Public Functions
    FUNCTION get_patient_outstanding (
        p_patient_id IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_hospital_gross_revenue RETURN NUMBER;

END pkg_hospital_billing;
/

-- ============================================================================
-- PACKAGE BODY
-- ============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_hospital_billing AS

    -- Cursor Definition
    CURSOR cur_pending_invoices RETURN t_invoice_summary IS
        SELECT i.invoice_id, 
               p.first_name || ' ' || p.last_name AS patient_name,
               i.net_payable, 
               i.payment_status
        FROM billing_invoices i
        JOIN patients p ON i.patient_id = p.patient_id
        WHERE i.payment_status IN ('PENDING', 'PARTIAL');

    -- Procedure 1: generate_discharge_invoice
    PROCEDURE generate_discharge_invoice (
        p_admission_id  IN  NUMBER,
        p_payment_mode  IN  VARCHAR2,
        p_invoice_id    OUT NUMBER,
        p_net_payable   OUT NUMBER,
        p_message       OUT VARCHAR2
    ) IS
        v_final_bill NUMBER(10, 2);
    BEGIN
        sp_discharge_patient(p_admission_id, p_payment_mode, p_invoice_id, v_final_bill, p_message);
        p_net_payable := v_final_bill;
    EXCEPTION
        WHEN OTHERS THEN
            p_message := 'Package Error in generate_discharge_invoice: ' || SQLERRM;
            p_invoice_id := NULL;
            p_net_payable := 0;
    END generate_discharge_invoice;

    -- Procedure 2: process_invoice_payment
    PROCEDURE process_invoice_payment (
        p_invoice_id    IN  NUMBER,
        p_payment_mode  IN  VARCHAR2,
        p_status_msg    OUT VARCHAR2
    ) IS
        v_current_status VARCHAR2(15);
        v_amount         NUMBER(10, 2);
    BEGIN
        SELECT payment_status, net_payable
        INTO v_current_status, v_amount
        FROM billing_invoices
        WHERE invoice_id = p_invoice_id
        FOR UPDATE;

        IF v_current_status = 'PAID' THEN
            p_status_msg := 'WARNING: Invoice #' || p_invoice_id || ' is already fully settled.';
            RETURN;
        END IF;

        UPDATE billing_invoices
        SET payment_status = 'PAID',
            payment_mode   = NVL(p_payment_mode, 'CASH'),
            invoice_date   = SYSDATE
        WHERE invoice_id = p_invoice_id;

        COMMIT;
        p_status_msg := 'SUCCESS: Invoice #' || p_invoice_id || ' paid in full (Rs. ' || v_amount || ') via ' || p_payment_mode;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status_msg := 'ERROR: Invoice #' || p_invoice_id || ' does not exist.';
        WHEN OTHERS THEN
            ROLLBACK;
            p_status_msg := 'ERROR processing payment: ' || SQLERRM;
    END process_invoice_payment;

    -- Procedure 3: apply_waiver_discount
    PROCEDURE apply_waiver_discount (
        p_invoice_id     IN  NUMBER,
        p_discount_pct   IN  NUMBER,
        p_revised_amount OUT NUMBER,
        p_message        OUT VARCHAR2
    ) IS
        v_gross       NUMBER(10, 2);
        v_current_net NUMBER(10, 2);
        v_disc_val    NUMBER(10, 2);
    BEGIN
        IF p_discount_pct > c_max_discount_pct THEN
            p_message := 'ERROR: Requested discount (' || (p_discount_pct * 100) || '%) exceeds maximum permitted limit (' || (c_max_discount_pct * 100) || '%).';
            RAISE ex_excess_discount;
        END IF;

        SELECT net_payable, gross_total
        INTO v_current_net, v_gross
        FROM billing_invoices
        WHERE invoice_id = p_invoice_id
        FOR UPDATE;

        v_disc_val := ROUND(v_gross * p_discount_pct, 2);
        v_current_net := GREATEST(0, v_current_net - v_disc_val);

        UPDATE billing_invoices
        SET discount_amount = discount_amount + v_disc_val,
            net_payable = v_current_net
        WHERE invoice_id = p_invoice_id;

        COMMIT;
        p_revised_amount := v_current_net;
        p_message := 'SUCCESS: Applied discount of Rs. ' || v_disc_val || '. Revised payable: Rs. ' || v_current_net;
    EXCEPTION
        WHEN ex_excess_discount THEN
            p_revised_amount := NULL;
        WHEN NO_DATA_FOUND THEN
            p_revised_amount := NULL;
            p_message := 'ERROR: Invoice #' || p_invoice_id || ' not found.';
        WHEN OTHERS THEN
            ROLLBACK;
            p_revised_amount := NULL;
            p_message := 'ERROR applying waiver: ' || SQLERRM;
    END apply_waiver_discount;

    -- Function 1: get_patient_outstanding
    FUNCTION get_patient_outstanding (
        p_patient_id IN NUMBER
    ) RETURN NUMBER IS
        v_outstanding NUMBER(10, 2) := 0;
    BEGIN
        SELECT NVL(SUM(net_payable), 0)
        INTO v_outstanding
        FROM billing_invoices
        WHERE patient_id = p_patient_id
          AND payment_status IN ('PENDING', 'PARTIAL');

        RETURN v_outstanding;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN -1;
    END get_patient_outstanding;

    -- Function 2: get_hospital_gross_revenue
    FUNCTION get_hospital_gross_revenue RETURN NUMBER IS
        v_total NUMBER(12, 2) := 0;
    BEGIN
        SELECT NVL(SUM(net_payable), 0)
        INTO v_total
        FROM billing_invoices
        WHERE payment_status = 'PAID';

        RETURN v_total;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_hospital_gross_revenue;

END pkg_hospital_billing;
/

COMMIT;
