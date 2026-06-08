-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Facturation: paiements partiels, échéance et type complémentaire
--
-- Extends the invoices table to support the full payment-tracking spec:
--   • paid_amount  → cumulative amount settled on the invoice (partial OK)
--   • due_date     → échéance; an unpaid invoice past this date is "En retard"
--   • type adds 'complementaire' (fournitures/MO/travaux supplémentaires)
--
-- A new invoice_payments table stores each règlement (montant + date) so the
-- chantier history can list every payment, and paid_amount is kept in sync.
--
-- The display status is derived in the app:
--   reste = amount - paid_amount
--     reste <= 0                     → Payée
--     paid_amount > 0 && reste > 0   → Partiellement payée
--     paid_amount == 0 && past due   → En retard
--     otherwise                      → En attente
--
-- Run this in Supabase → SQL Editor → Run (after create_invoices.sql).
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE invoices ADD COLUMN IF NOT EXISTS paid_amount DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS due_date DATE;

-- ── invoice_payments ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS invoice_payments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invoice_id  UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  amount      DOUBLE PRECISION NOT NULL DEFAULT 0,
  paid_at     DATE NOT NULL DEFAULT CURRENT_DATE,
  method      TEXT,
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoice_payments_invoice_idx ON invoice_payments(invoice_id);

ALTER TABLE invoice_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "invoice_payments_select" ON invoice_payments;
CREATE POLICY "invoice_payments_select" ON invoice_payments FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "invoice_payments_insert" ON invoice_payments;
CREATE POLICY "invoice_payments_insert" ON invoice_payments FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "invoice_payments_update" ON invoice_payments;
CREATE POLICY "invoice_payments_update" ON invoice_payments FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "invoice_payments_delete" ON invoice_payments;
CREATE POLICY "invoice_payments_delete" ON invoice_payments FOR DELETE
  USING (user_id = auth.uid());

-- Keep invoices.paid_amount in sync with the sum of its payments, and stamp
-- paid_at / status='paid' once fully settled.
CREATE OR REPLACE FUNCTION sync_invoice_paid_amount() RETURNS TRIGGER AS $$
DECLARE
  inv_id UUID;
  total_paid DOUBLE PRECISION;
  inv_amount DOUBLE PRECISION;
BEGIN
  inv_id := COALESCE(NEW.invoice_id, OLD.invoice_id);

  SELECT COALESCE(SUM(amount), 0) INTO total_paid
    FROM invoice_payments WHERE invoice_id = inv_id;

  SELECT amount INTO inv_amount FROM invoices WHERE id = inv_id;

  UPDATE invoices
    SET paid_amount = total_paid,
        status = CASE WHEN total_paid >= inv_amount AND inv_amount > 0 THEN 'paid'
                      WHEN total_paid > 0 THEN 'sent'
                      ELSE status END,
        paid_at = CASE WHEN total_paid >= inv_amount AND inv_amount > 0
                       THEN now() ELSE NULL END,
        updated_at = now()
    WHERE id = inv_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_invoice_paid ON invoice_payments;
CREATE TRIGGER trg_sync_invoice_paid
  AFTER INSERT OR UPDATE OR DELETE ON invoice_payments
  FOR EACH ROW EXECUTE FUNCTION sync_invoice_paid_amount();

NOTIFY pgrst, 'reload schema';
