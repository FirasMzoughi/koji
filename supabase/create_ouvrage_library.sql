-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — ouvrage_library
-- Per-user catalogue of reusable "ouvrages" (works) that can be picked from
-- the Bibliothèque d'ouvrages screen and inserted directly into a chantier.
-- Mirrors the columns shown in the user's reference spreadsheet:
-- Code, Famille, Unité, Temps (h/u), Taux horaire, Coût MO/u, Commentaire,
-- Coefficient, Réduction.
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ouvrage_library (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code          TEXT NOT NULL,
  designation   TEXT NOT NULL,
  famille       TEXT,
  unite         TEXT,
  temps_hu      NUMERIC(10, 3) NOT NULL DEFAULT 0,
  taux_horaire  NUMERIC(10, 2) NOT NULL DEFAULT 0,
  cout_mo_u     NUMERIC(12, 2) NOT NULL DEFAULT 0,
  commentaire   TEXT,
  coefficient   NUMERIC(8, 3) NOT NULL DEFAULT 1.0,
  reduction     NUMERIC(6, 2) NOT NULL DEFAULT 0.0,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, code)
);

CREATE INDEX IF NOT EXISTS ouvrage_library_user_famille_idx
  ON ouvrage_library (user_id, famille);

ALTER TABLE ouvrage_library ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ouvrage_library_select" ON ouvrage_library;
CREATE POLICY "ouvrage_library_select" ON ouvrage_library FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "ouvrage_library_insert" ON ouvrage_library;
CREATE POLICY "ouvrage_library_insert" ON ouvrage_library FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "ouvrage_library_update" ON ouvrage_library;
CREATE POLICY "ouvrage_library_update" ON ouvrage_library FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "ouvrage_library_delete" ON ouvrage_library;
CREATE POLICY "ouvrage_library_delete" ON ouvrage_library FOR DELETE
  USING (user_id = auth.uid());
