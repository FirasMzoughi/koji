-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Espace Client access (particulier / client accounts)
--
-- A client account never OWNS chantiers or quotes — those belong to the
-- entreprise (auth.uid() = quotes.user_id / chantiers.user_id). A client is
-- linked only by the email the entreprise typed into chantiers.client_email
-- when creating the chantier. This migration lets a logged-in client READ:
--
--   • the chantiers addressed to them      (chantiers.client_email = their email)
--   • the devis attached to those chantiers (quotes.chantier_id -> chantier)
--   • the works to follow                   (chantier_tasks of those chantiers)
--   • their signature rows                  (signatures of those quotes)
--
-- and lets them SIGN a devis (update quotes.status / signature columns on a
-- devis addressed to them) and READ/POST on its discussion (quote_messages).
--
-- This is ADDITIVE: it does not drop the entreprise-owner policies added in
-- quote_messages_rls.sql, nor the anon policies the signature web app relies on.
-- Run AFTER add_chantier_client_email.sql and quote_messages_rls.sql.
--
-- Email match: auth.jwt() ->> 'email', compared case-insensitively (lower()).
-- NOTE on casts: as in quote_messages_rls.sql, quote_id / chantier_id are TEXT
-- while quotes.id / chantiers.id are UUID, so cross-table comparisons cast
-- both sides with ::text to avoid "operator does not exist: text = uuid".
--
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

-- Helper expression reused below:
--   lower(client_email) = lower(auth.jwt() ->> 'email')

-- ── chantiers ────────────────────────────────────────────────────────────────
ALTER TABLE chantiers ENABLE ROW LEVEL SECURITY;

-- Keep the entreprise owner's full access intact.
DROP POLICY IF EXISTS "chantiers_owner_all" ON chantiers;
CREATE POLICY "chantiers_owner_all" ON chantiers FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Client can READ the chantiers addressed to their email.
DROP POLICY IF EXISTS "chantiers_select_client" ON chantiers;
CREATE POLICY "chantiers_select_client" ON chantiers FOR SELECT
  TO authenticated
  USING (lower(client_email) = lower(auth.jwt() ->> 'email'));

-- ── quotes ─────────────────────────────────────────────────────────────────
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quotes_owner_all" ON quotes;
CREATE POLICY "quotes_owner_all" ON quotes FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Client can READ devis attached to a chantier addressed to their email.
DROP POLICY IF EXISTS "quotes_select_client" ON quotes;
CREATE POLICY "quotes_select_client" ON quotes FOR SELECT
  TO authenticated
  USING (chantier_id::text IN (
    SELECT id::text FROM chantiers
    WHERE lower(client_email) = lower(auth.jwt() ->> 'email')
  ));

-- Client can SIGN such a devis (update status / signature columns). RLS gates
-- WHICH rows, not which columns, so the app only writes the signature fields.
DROP POLICY IF EXISTS "quotes_update_client_sign" ON quotes;
CREATE POLICY "quotes_update_client_sign" ON quotes FOR UPDATE
  TO authenticated
  USING (chantier_id::text IN (
    SELECT id::text FROM chantiers
    WHERE lower(client_email) = lower(auth.jwt() ->> 'email')
  ))
  WITH CHECK (chantier_id::text IN (
    SELECT id::text FROM chantiers
    WHERE lower(client_email) = lower(auth.jwt() ->> 'email')
  ));

-- ── chantier_tasks (works to follow) ─────────────────────────────────────────
ALTER TABLE chantier_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chantier_tasks_owner_all" ON chantier_tasks;
CREATE POLICY "chantier_tasks_owner_all" ON chantier_tasks FOR ALL
  USING (chantier_id::text IN (
    SELECT id::text FROM chantiers WHERE user_id = auth.uid()
  ))
  WITH CHECK (chantier_id::text IN (
    SELECT id::text FROM chantiers WHERE user_id = auth.uid()
  ));

-- Client can READ (only) the tasks of chantiers addressed to their email.
DROP POLICY IF EXISTS "chantier_tasks_select_client" ON chantier_tasks;
CREATE POLICY "chantier_tasks_select_client" ON chantier_tasks FOR SELECT
  TO authenticated
  USING (chantier_id::text IN (
    SELECT id::text FROM chantiers
    WHERE lower(client_email) = lower(auth.jwt() ->> 'email')
  ));

-- ── signatures ───────────────────────────────────────────────────────────────
ALTER TABLE signatures ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "signatures_owner_all" ON signatures;
CREATE POLICY "signatures_owner_all" ON signatures FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Client can READ signatures on devis addressed to their email …
DROP POLICY IF EXISTS "signatures_select_client" ON signatures;
CREATE POLICY "signatures_select_client" ON signatures FOR SELECT
  TO authenticated
  USING (quote_id::text IN (
    SELECT q.id::text FROM quotes q
    JOIN chantiers c ON c.id::text = q.chantier_id::text
    WHERE lower(c.client_email) = lower(auth.jwt() ->> 'email')
  ));

-- … and INSERT their own signature when signing such a devis.
DROP POLICY IF EXISTS "signatures_insert_client" ON signatures;
CREATE POLICY "signatures_insert_client" ON signatures FOR INSERT
  TO authenticated
  WITH CHECK (quote_id::text IN (
    SELECT q.id::text FROM quotes q
    JOIN chantiers c ON c.id::text = q.chantier_id::text
    WHERE lower(c.client_email) = lower(auth.jwt() ->> 'email')
  ));

-- ── quote_messages (client side, authenticated) ──────────────────────────────
-- The anon policies in quote_messages_rls.sql already let the web app read/post.
-- These add the same for an authenticated CLIENT app user, scoped to devis
-- addressed to their email (so a logged-in client can chat with the entreprise
-- from the mobile app, not only the web link).
DROP POLICY IF EXISTS "quote_messages_select_client" ON quote_messages;
CREATE POLICY "quote_messages_select_client" ON quote_messages FOR SELECT
  TO authenticated
  USING (quote_id::text IN (
    SELECT q.id::text FROM quotes q
    JOIN chantiers c ON c.id::text = q.chantier_id::text
    WHERE lower(c.client_email) = lower(auth.jwt() ->> 'email')
  ));

DROP POLICY IF EXISTS "quote_messages_insert_client" ON quote_messages;
CREATE POLICY "quote_messages_insert_client" ON quote_messages FOR INSERT
  TO authenticated
  WITH CHECK (quote_id::text IN (
    SELECT q.id::text FROM quotes q
    JOIN chantiers c ON c.id::text = q.chantier_id::text
    WHERE lower(c.client_email) = lower(auth.jwt() ->> 'email')
  ));

-- quote_message_attachments: allow the authenticated client to read/post
-- attachments on those same threads.
DROP POLICY IF EXISTS "quote_attachments_select_client" ON quote_message_attachments;
CREATE POLICY "quote_attachments_select_client" ON quote_message_attachments FOR SELECT
  TO authenticated
  USING (message_id::text IN (
    SELECT m.id::text FROM quote_messages m
    JOIN quotes q ON q.id::text = m.quote_id::text
    JOIN chantiers c ON c.id::text = q.chantier_id::text
    WHERE lower(c.client_email) = lower(auth.jwt() ->> 'email')
  ));

DROP POLICY IF EXISTS "quote_attachments_insert_client" ON quote_message_attachments;
CREATE POLICY "quote_attachments_insert_client" ON quote_message_attachments FOR INSERT
  TO authenticated
  WITH CHECK (message_id::text IN (
    SELECT m.id::text FROM quote_messages m
    JOIN quotes q ON q.id::text = m.quote_id::text
    JOIN chantiers c ON c.id::text = q.chantier_id::text
    WHERE lower(c.client_email) = lower(auth.jwt() ->> 'email')
  ));

-- ── signatures storage bucket ────────────────────────────────────────────────
-- Let an authenticated client upload their signature PNG. The path layout used
-- by SignatureRepository is "<uid>/<file>", and the client's uid is auth.uid().
DROP POLICY IF EXISTS "signatures_storage_insert_client" ON storage.objects;
CREATE POLICY "signatures_storage_insert_client" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'signatures' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "signatures_storage_select_auth" ON storage.objects;
CREATE POLICY "signatures_storage_select_auth" ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'signatures');
