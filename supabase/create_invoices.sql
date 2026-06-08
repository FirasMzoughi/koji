-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Facturation (Invoices)
-- Factures created from a signed devis, tied to a chantier + quote + client.
--
-- An invoice represents one billing step against a signed quote:
--   • acompte       → initial deposit
--   • intermediaire → progress / interim invoice (one or many)
--   • finale        → final / balance invoice
--
-- The amount on each invoice is an absolute € amount (total_ttc-based). The UI
-- lets the user enter it as a fixed amount, a % of the signed quote total, a
-- predefined deposit, or the remaining balance — but it is always persisted as
-- a concrete `amount`. Summing a chantier's invoice amounts gives "déjà
-- facturé"; the signed quote total minus that gives "restant à facturer".
--
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS invoices (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chantier_id   UUID NOT NULL REFERENCES chantiers(id) ON DELETE CASCADE,
  quote_id      UUID REFERENCES quotes(id) ON DELETE SET NULL,
  -- Snapshot of the quote total at time of invoicing, so the "restant à
  -- facturer" math stays stable even if the quote is later edited.
  quote_total   DOUBLE PRECISION DEFAULT 0,
  reference     TEXT,
  -- 'acompte' | 'intermediaire' | 'finale'
  type          TEXT NOT NULL DEFAULT 'intermediaire',
  -- How the amount was chosen (informational): 'fixed' | 'percent' | 'deposit' | 'balance'
  amount_mode   TEXT,
  -- The billed amount in €. Authoritative; percent is stored for display only.
  amount        DOUBLE PRECISION NOT NULL DEFAULT 0,
  percent       DOUBLE PRECISION,
  -- 'draft' | 'sent' | 'paid'
  status        TEXT NOT NULL DEFAULT 'draft',
  note          TEXT,
  client_name   TEXT,
  client_email  TEXT,
  issued_at     DATE DEFAULT CURRENT_DATE,
  paid_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoices_chantier_idx ON invoices(chantier_id);
CREATE INDEX IF NOT EXISTS invoices_quote_idx    ON invoices(quote_id);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "invoices_select" ON invoices;
CREATE POLICY "invoices_select" ON invoices FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "invoices_insert" ON invoices;
CREATE POLICY "invoices_insert" ON invoices FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "invoices_update" ON invoices;
CREATE POLICY "invoices_update" ON invoices FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "invoices_delete" ON invoices;
CREATE POLICY "invoices_delete" ON invoices FOR DELETE USING (user_id = auth.uid());
