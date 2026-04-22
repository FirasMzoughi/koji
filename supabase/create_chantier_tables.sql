-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Chantier tables
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. chantiers ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chantiers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reference    TEXT,
  street       TEXT,
  postal_code  TEXT,
  city         TEXT,
  property_type TEXT,
  status       TEXT DEFAULT 'En attente',
  created_at   TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE chantiers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chantiers_select" ON chantiers;
CREATE POLICY "chantiers_select" ON chantiers FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "chantiers_insert" ON chantiers;
CREATE POLICY "chantiers_insert" ON chantiers FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "chantiers_update" ON chantiers;
CREATE POLICY "chantiers_update" ON chantiers FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "chantiers_delete" ON chantiers;
CREATE POLICY "chantiers_delete" ON chantiers FOR DELETE USING (user_id = auth.uid());

-- ── 2. chantier_budgets ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chantier_budgets (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chantier_id              UUID NOT NULL REFERENCES chantiers(id) ON DELETE CASCADE,
  main_oeuvre_real         DOUBLE PRECISION DEFAULT 0,
  main_oeuvre_estimated    DOUBLE PRECISION DEFAULT 0,
  fourniture_real          DOUBLE PRECISION DEFAULT 0,
  fourniture_estimated     DOUBLE PRECISION DEFAULT 0,
  created_at               TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE chantier_budgets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chantier_budgets_select" ON chantier_budgets;
CREATE POLICY "chantier_budgets_select" ON chantier_budgets FOR SELECT
  USING (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "chantier_budgets_insert" ON chantier_budgets;
CREATE POLICY "chantier_budgets_insert" ON chantier_budgets FOR INSERT
  WITH CHECK (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "chantier_budgets_update" ON chantier_budgets;
CREATE POLICY "chantier_budgets_update" ON chantier_budgets FOR UPDATE
  USING (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));

-- ── 3. chantier_tasks ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chantier_tasks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chantier_id  UUID NOT NULL REFERENCES chantiers(id) ON DELETE CASCADE,
  label        TEXT NOT NULL,
  is_done      BOOLEAN DEFAULT false,
  created_at   TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE chantier_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chantier_tasks_select" ON chantier_tasks;
CREATE POLICY "chantier_tasks_select" ON chantier_tasks FOR SELECT
  USING (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "chantier_tasks_insert" ON chantier_tasks;
CREATE POLICY "chantier_tasks_insert" ON chantier_tasks FOR INSERT
  WITH CHECK (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "chantier_tasks_update" ON chantier_tasks;
CREATE POLICY "chantier_tasks_update" ON chantier_tasks FOR UPDATE
  USING (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "chantier_tasks_delete" ON chantier_tasks;
CREATE POLICY "chantier_tasks_delete" ON chantier_tasks FOR DELETE
  USING (chantier_id IN (SELECT id FROM chantiers WHERE user_id = auth.uid()));
