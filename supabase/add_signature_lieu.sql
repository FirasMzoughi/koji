-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Add "lieu" (place of signature) to signatures
-- Lets the signed devis render the legal mention "Fait à <lieu>, le <date>".
-- The value is also mirrored into quotes.metadata.signatureLieu so the PDF can
-- show it without a join.
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE signatures ADD COLUMN IF NOT EXISTS lieu TEXT;
