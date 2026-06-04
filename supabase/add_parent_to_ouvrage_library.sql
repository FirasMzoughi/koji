-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — ouvrage_library : sous-ouvrages (parent / child)
-- Adds parent/child support so an ouvrage can contain sous-ouvrages, e.g.
--   CARMUR-001            (ouvrage)
--     ├─ CARMUR-001-01    (sous-ouvrage)
--     └─ CARMUR-001-02    (sous-ouvrage)
-- A sous-ouvrage points at its parent via parent_id. Deleting a parent
-- removes its sous-ouvrages automatically (ON DELETE CASCADE).
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE ouvrage_library
  ADD COLUMN IF NOT EXISTS parent_id UUID
  REFERENCES ouvrage_library(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS ouvrage_library_parent_idx
  ON ouvrage_library (parent_id);
