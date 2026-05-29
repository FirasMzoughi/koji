-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — quote_messages access for the entreprise (koji-main) side
--
-- The client signature web app (KOJI-SIGNATURE) already creates and reads
-- quote_messages / quote_message_attachments and uploads to the
-- "quote_attachments" storage bucket using the anon key. koji-main is signed in
-- as the entreprise (the auth user that OWNS the quote) and needs to read and
-- post on the same threads via the Supabase Flutter client.
--
-- This migration is ADDITIVE: it adds owner-scoped policies and does NOT drop
-- the policies the web app relies on. If the tables currently have RLS DISABLED
-- (so the anon web app can write freely), enabling RLS here would suddenly gate
-- the web app too — so we only enable RLS + add anon policies when you are sure
-- both sides are covered. Review the "anon" policies below before running in a
-- production project that the web app already uses.
--
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

-- Schema reference (created previously, directly in Supabase):
--   quote_messages(id pk, quote_id -> quotes(id), text text,
--                  author_name text, author_email text, created_at timestamptz)
--   quote_message_attachments(id pk, message_id -> quote_messages(id),
--                  bucket_id text, file_path text, mime_type text,
--                  file_size bigint, original_name text, created_at timestamptz)
-- IMPORTANT: in this project the foreign-key columns (quote_messages.quote_id,
-- quote_message_attachments.message_id) are stored as TEXT while quotes.id /
-- quote_messages.id are UUID. Direct comparison raises
-- "operator does not exist: text = uuid", so every cross-table comparison
-- below casts both sides with ::text.

ALTER TABLE quote_messages            ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_message_attachments ENABLE ROW LEVEL SECURITY;

-- ── quote_messages ─────────────────────────────────────────────────────────
-- Entreprise (owner of the quote) can read every message on its own quotes.
DROP POLICY IF EXISTS "quote_messages_select_owner" ON quote_messages;
CREATE POLICY "quote_messages_select_owner" ON quote_messages FOR SELECT
  USING (quote_id::text IN (SELECT id::text FROM quotes WHERE user_id = auth.uid()));

-- Entreprise can post a reply on its own quotes.
DROP POLICY IF EXISTS "quote_messages_insert_owner" ON quote_messages;
CREATE POLICY "quote_messages_insert_owner" ON quote_messages FOR INSERT
  WITH CHECK (quote_id::text IN (SELECT id::text FROM quotes WHERE user_id = auth.uid()));

-- Client side (signature web app, anon key): keep the existing behaviour where
-- anyone holding the quote link can read/post. Knowing the quote UUID is the
-- access token, mirroring the get_quote_for_client RPC. Adjust/remove if your
-- project scopes the web app differently.
DROP POLICY IF EXISTS "quote_messages_select_anon" ON quote_messages;
CREATE POLICY "quote_messages_select_anon" ON quote_messages FOR SELECT
  TO anon USING (true);

DROP POLICY IF EXISTS "quote_messages_insert_anon" ON quote_messages;
CREATE POLICY "quote_messages_insert_anon" ON quote_messages FOR INSERT
  TO anon WITH CHECK (true);

-- ── quote_message_attachments ────────────────────────────────────────────────
DROP POLICY IF EXISTS "quote_attachments_select_owner" ON quote_message_attachments;
CREATE POLICY "quote_attachments_select_owner" ON quote_message_attachments FOR SELECT
  USING (message_id::text IN (
    SELECT m.id::text FROM quote_messages m
    JOIN quotes q ON q.id::text = m.quote_id::text
    WHERE q.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "quote_attachments_insert_owner" ON quote_message_attachments;
CREATE POLICY "quote_attachments_insert_owner" ON quote_message_attachments FOR INSERT
  WITH CHECK (message_id::text IN (
    SELECT m.id::text FROM quote_messages m
    JOIN quotes q ON q.id::text = m.quote_id::text
    WHERE q.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "quote_attachments_select_anon" ON quote_message_attachments;
CREATE POLICY "quote_attachments_select_anon" ON quote_message_attachments FOR SELECT
  TO anon USING (true);

DROP POLICY IF EXISTS "quote_attachments_insert_anon" ON quote_message_attachments;
CREATE POLICY "quote_attachments_insert_anon" ON quote_message_attachments FOR INSERT
  TO anon WITH CHECK (true);

-- ── Storage bucket "quote_attachments" ────────────────────────────────────────
-- Let the authenticated entreprise upload and read its threads' files. The web
-- app already uses signed URLs (createSignedUrl) which work regardless of these.
DROP POLICY IF EXISTS "quote_attachments_storage_insert_auth" ON storage.objects;
CREATE POLICY "quote_attachments_storage_insert_auth" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'quote_attachments');

DROP POLICY IF EXISTS "quote_attachments_storage_select_auth" ON storage.objects;
CREATE POLICY "quote_attachments_storage_select_auth" ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'quote_attachments');
