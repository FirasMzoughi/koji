-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — scheduled_tasks
-- Single source of truth for per-worker / per-day planning.
-- Run this in Supabase → SQL Editor → Run (after create_chantier_tables.sql).
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS scheduled_tasks (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chantier_id       UUID NOT NULL REFERENCES chantiers(id) ON DELETE CASCADE,
  chantier_task_id  UUID REFERENCES chantier_tasks(id) ON DELETE SET NULL,
  worker_id         UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  notes             TEXT,
  scheduled_date    DATE NOT NULL,
  start_time        TIME NOT NULL,
  duration_minutes  INT  NOT NULL DEFAULT 60 CHECK (duration_minutes > 0),
  status            TEXT NOT NULL DEFAULT 'À faire',
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_user_date
  ON scheduled_tasks(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_worker_date
  ON scheduled_tasks(worker_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_chantier
  ON scheduled_tasks(chantier_id);

ALTER TABLE scheduled_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "scheduled_tasks_select" ON scheduled_tasks;
CREATE POLICY "scheduled_tasks_select" ON scheduled_tasks FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "scheduled_tasks_insert" ON scheduled_tasks;
CREATE POLICY "scheduled_tasks_insert" ON scheduled_tasks FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "scheduled_tasks_update" ON scheduled_tasks;
CREATE POLICY "scheduled_tasks_update" ON scheduled_tasks FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "scheduled_tasks_delete" ON scheduled_tasks;
CREATE POLICY "scheduled_tasks_delete" ON scheduled_tasks FOR DELETE
  USING (user_id = auth.uid());
