-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — task_codes catalog
-- Reusable code prefixes (CAR, PLO, ELE…) for the Nouvelle tâche form.
-- The actual task code stored in `tasks.code` is built as `<prefix>-NN`.
-- Run this in Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS task_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prefix      TEXT NOT NULL,
  label       TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, prefix)
);

ALTER TABLE task_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "task_codes_select" ON task_codes;
CREATE POLICY "task_codes_select" ON task_codes FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "task_codes_insert" ON task_codes;
CREATE POLICY "task_codes_insert" ON task_codes FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "task_codes_update" ON task_codes;
CREATE POLICY "task_codes_update" ON task_codes FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "task_codes_delete" ON task_codes;
CREATE POLICY "task_codes_delete" ON task_codes FOR DELETE
  USING (user_id = auth.uid());
