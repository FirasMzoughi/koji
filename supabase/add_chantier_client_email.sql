-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Add client_email to chantiers
-- The email entered when creating a chantier becomes the authoritative gate
-- for opening the devis signature link. It is auto-filled into each devis
-- created from the chantier (quotes.metadata.client.email), which the
-- signature web app validates against.
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE chantiers ADD COLUMN IF NOT EXISTS client_email TEXT;

-- No backfill: existing chantiers keep a NULL email, so their devis stay
-- openable by the unguessable quote UUID alone (matches the "strict only when
-- an email exists" gate enforced in the signature RPC functions).
