-- ============================================================================
-- Worker (ouvrier) access login + task follow-up
-- ----------------------------------------------------------------------------
-- Mirrors the per-chantier client login: each worker gets an Identifiant
-- (access_code, e.g. OUV-7F3A2B) + Mot de passe (access_password). The worker
-- enters them in the app's "Espace Particulier" and sees the tasks assigned to
-- them (scheduled_tasks), and can flip each one between "À faire" and "Terminé".
--
-- No Supabase auth session is created for the worker — the unguessable code is
-- the authorization, exactly like the client flow. RPCs are SECURITY DEFINER and
-- granted to anon so a sessionless worker can call them.
--
-- Run this whole file in Supabase → SQL editor → New query. Idempotent.
-- ============================================================================

-- 1) Credential columns on the worker ---------------------------------------
ALTER TABLE workers
  ADD COLUMN IF NOT EXISTS access_code text,
  ADD COLUMN IF NOT EXISTS access_password text;

-- Unique, case-insensitive lookups by code.
CREATE UNIQUE INDEX IF NOT EXISTS workers_access_code_key
  ON workers (UPPER(access_code))
  WHERE access_code IS NOT NULL;

-- 2) Set worker credentials (entreprise app, on worker save) -----------------
--    Owner (workers.user_id = auth.uid()) can (re)set; first-time assignment is
--    also allowed while access_code IS NULL.
CREATE OR REPLACE FUNCTION set_worker_access_credentials(
  p_worker_id uuid,
  p_access_code text,
  p_access_password text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows integer;
BEGIN
  UPDATE workers
  SET access_code = p_access_code,
      access_password = p_access_password
  WHERE id = p_worker_id
    AND (user_id = auth.uid() OR access_code IS NULL);

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END;
$$;

-- 3) Verify a worker code + password, return the worker id -------------------
--    Returns the matching worker id, or NULL. Case-insensitive on the code.
CREATE OR REPLACE FUNCTION login_worker_with_code(
  p_code text,
  p_password text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id uuid;
BEGIN
  SELECT id INTO v_id
  FROM workers
  WHERE access_code IS NOT NULL
    AND UPPER(TRIM(access_code)) = UPPER(TRIM(COALESCE(p_code, '')))
    AND access_password = COALESCE(p_password, '')
  LIMIT 1;

  RETURN v_id; -- NULL when no match
END;
$$;

-- 4) Fetch every task assigned to a worker -----------------------------------
--    A worker is assigned to a scheduled_task either directly (worker_id) or via
--    the scheduled_task_workers join. We return the union, newest first, with
--    the chantier reference for grouping in the UI.
CREATE OR REPLACE FUNCTION get_worker_tasks(p_worker_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v json;
BEGIN
  SELECT COALESCE(json_agg(t ORDER BY t.scheduled_date DESC, t.start_time), '[]'::json)
  INTO v
  FROM (
    SELECT DISTINCT
      st.id,
      st.title,
      st.status,
      st.scheduled_date,
      st.start_time,
      st.chantier_id,
      c.reference AS chantier_reference
    FROM scheduled_tasks st
    LEFT JOIN chantiers c ON c.id = st.chantier_id
    LEFT JOIN scheduled_task_workers stw ON stw.scheduled_task_id = st.id
    WHERE st.worker_id = p_worker_id
       OR stw.worker_id = p_worker_id
  ) t;

  RETURN v;
END;
$$;

-- 5) Worker flips a task's status (À faire / Terminé) ------------------------
--    Guarded: the worker may only update a task they are actually assigned to.
CREATE OR REPLACE FUNCTION set_worker_task_status(
  p_worker_id uuid,
  p_task_id uuid,
  p_status text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows integer;
BEGIN
  UPDATE scheduled_tasks st
  SET status = p_status
  WHERE st.id = p_task_id
    AND (
      st.worker_id = p_worker_id
      OR EXISTS (
        SELECT 1 FROM scheduled_task_workers stw
        WHERE stw.scheduled_task_id = st.id AND stw.worker_id = p_worker_id
      )
    );

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END;
$$;

-- 6) Grants ------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION set_worker_access_credentials(uuid, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION login_worker_with_code(text, text)              TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_worker_tasks(uuid)                          TO anon, authenticated;
GRANT EXECUTE ON FUNCTION set_worker_task_status(uuid, uuid, text)        TO anon, authenticated;
