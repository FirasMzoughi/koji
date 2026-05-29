-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — scheduled_tasks: explicit end date + time
-- Lets a planned task span multiple days (start date/time → end date/time)
-- instead of only start_time + duration_minutes.
-- Run in Supabase → SQL Editor → Run (after create_scheduled_tasks.sql).
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE scheduled_tasks
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS end_time TIME,
  -- Link to a devis task (quote_tasks.id). No FK so we stay decoupled from the
  -- quote schema; lets the planning screen assign the SAME tasks shown in the
  -- devis. chantier_task_id remains for the separate checklist linkage.
  ADD COLUMN IF NOT EXISTS quote_task_id UUID;

CREATE INDEX IF NOT EXISTS idx_scheduled_tasks_quote_task
  ON scheduled_tasks(quote_task_id);

-- Backfill existing rows: derive the end timestamp from
-- scheduled_date + start_time + duration_minutes, then split into date/time.
UPDATE scheduled_tasks
SET
  end_date = (scheduled_date + start_time + make_interval(mins => duration_minutes))::date,
  end_time = (scheduled_date + start_time + make_interval(mins => duration_minutes))::time
WHERE end_time IS NULL;
