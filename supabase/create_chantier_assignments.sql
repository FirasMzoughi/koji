-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — chantier_assignments
-- Links workers to chantiers (replaces legacy project_assignments which
-- referenced the deprecated projects table).
-- Run this in Supabase → SQL Editor → Run.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS chantier_assignments (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chantier_id  UUID NOT NULL REFERENCES chantiers(id) ON DELETE CASCADE,
  worker_id    UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  role         TEXT,
  assigned_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (chantier_id, worker_id)
);

CREATE INDEX IF NOT EXISTS idx_chantier_assignments_chantier
  ON chantier_assignments(chantier_id);
CREATE INDEX IF NOT EXISTS idx_chantier_assignments_worker
  ON chantier_assignments(worker_id);

ALTER TABLE chantier_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chantier_assignments_select" ON chantier_assignments;
CREATE POLICY "chantier_assignments_select" ON chantier_assignments FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "chantier_assignments_insert" ON chantier_assignments;
CREATE POLICY "chantier_assignments_insert" ON chantier_assignments FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "chantier_assignments_update" ON chantier_assignments;
CREATE POLICY "chantier_assignments_update" ON chantier_assignments FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "chantier_assignments_delete" ON chantier_assignments;
CREATE POLICY "chantier_assignments_delete" ON chantier_assignments FOR DELETE
  USING (user_id = auth.uid());
