-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — scheduled_task_workers (many workers per scheduled task)
-- A scheduled_task keeps its original worker_id (the "primary" worker, kept for
-- backward compatibility and the NOT NULL constraint), and ALSO links to every
-- assigned worker through this join table. The planning UI reads the full set
-- from here, falling back to worker_id for legacy rows with no join entries.
-- Run in Supabase → SQL Editor → Run (after create_scheduled_tasks.sql).
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS scheduled_task_workers (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scheduled_task_id  UUID NOT NULL REFERENCES scheduled_tasks(id) ON DELETE CASCADE,
  worker_id          UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  created_at         TIMESTAMPTZ DEFAULT now(),
  UNIQUE (scheduled_task_id, worker_id)
);

CREATE INDEX IF NOT EXISTS idx_stw_task   ON scheduled_task_workers(scheduled_task_id);
CREATE INDEX IF NOT EXISTS idx_stw_worker ON scheduled_task_workers(worker_id);

-- Backfill: every existing scheduled_task gets a join row for its current worker.
INSERT INTO scheduled_task_workers (scheduled_task_id, worker_id)
SELECT id, worker_id FROM scheduled_tasks
ON CONFLICT (scheduled_task_id, worker_id) DO NOTHING;

ALTER TABLE scheduled_task_workers ENABLE ROW LEVEL SECURITY;

-- Access is gated through the parent scheduled_task's ownership.
DROP POLICY IF EXISTS "stw_select" ON scheduled_task_workers;
CREATE POLICY "stw_select" ON scheduled_task_workers FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM scheduled_tasks st
    WHERE st.id = scheduled_task_id AND st.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "stw_insert" ON scheduled_task_workers;
CREATE POLICY "stw_insert" ON scheduled_task_workers FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM scheduled_tasks st
    WHERE st.id = scheduled_task_id AND st.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "stw_delete" ON scheduled_task_workers;
CREATE POLICY "stw_delete" ON scheduled_task_workers FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM scheduled_tasks st
    WHERE st.id = scheduled_task_id AND st.user_id = auth.uid()
  ));
