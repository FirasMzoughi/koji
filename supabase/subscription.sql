-- ============================================================================
-- Entreprise subscription + 7-day free trial
-- ----------------------------------------------------------------------------
-- An entreprise account gets a 7-day free trial starting at first entreprise
-- login/signup. After the trial ends, core actions are gated behind an active
-- subscription, purchased via Apple In-App Purchase (iOS) or Google Play
-- Billing (Android) through the `in_app_purchase` Flutter package.
--
-- This file adds the tracking columns + a helper RPC. The actual purchase is
-- verified on-device by the store; the app then calls set_subscription_status
-- to persist the result so the gate survives reinstalls / other devices.
--
-- Run in Supabase → SQL editor → New query. Idempotent.
-- ============================================================================

-- 1) Columns on users --------------------------------------------------------
--    trial_started_at    : when the 7-day trial began (set on first entreprise
--                          login). NULL until then.
--    trial_ends_at       : trial_started_at + 7 days (computed app-side and
--                          stored so the gate is a simple timestamp compare).
--    subscription_status : 'trial' | 'active' | 'expired' | 'cancelled'.
--    subscription_platform: 'ios' | 'android' (where it was bought).
--    subscription_product : the store product id (e.g. koji_monthly).
--    subscription_expires_at: store-reported expiry (for auto-renew tracking).
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS trial_started_at        timestamptz,
  ADD COLUMN IF NOT EXISTS trial_ends_at           timestamptz,
  ADD COLUMN IF NOT EXISTS subscription_status     text,
  ADD COLUMN IF NOT EXISTS subscription_platform   text,
  ADD COLUMN IF NOT EXISTS subscription_product    text,
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz;

-- 2) Start the trial (idempotent: only sets it the first time) ----------------
--    Called on first entreprise login. Sets trial_started_at = now() and
--    trial_ends_at = now() + 7 days, and status = 'trial', but ONLY if no trial
--    has started yet (so re-login doesn't reset the clock).
CREATE OR REPLACE FUNCTION start_trial_if_absent(p_user_id uuid)
RETURNS timestamptz   -- returns the effective trial_ends_at
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ends timestamptz;
BEGIN
  SELECT trial_ends_at INTO v_ends FROM users WHERE id = p_user_id;

  IF v_ends IS NULL THEN
    UPDATE users
    SET trial_started_at = now(),
        trial_ends_at    = now() + interval '7 days',
        subscription_status = COALESCE(subscription_status, 'trial')
    WHERE id = p_user_id
    RETURNING trial_ends_at INTO v_ends;
  END IF;

  RETURN v_ends;
END;
$$;

-- 3) Persist a verified subscription result ----------------------------------
--    Called after the store confirms a purchase/restore. Only the owner
--    (auth.uid()) may update their own row.
CREATE OR REPLACE FUNCTION set_subscription_status(
  p_status      text,
  p_platform    text,
  p_product     text,
  p_expires_at  timestamptz
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows integer;
BEGIN
  UPDATE users
  SET subscription_status     = p_status,
      subscription_platform   = p_platform,
      subscription_product    = p_product,
      subscription_expires_at = p_expires_at
  WHERE id = auth.uid();

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION start_trial_if_absent(uuid)                        TO authenticated;
GRANT EXECUTE ON FUNCTION set_subscription_status(text, text, text, timestamptz) TO authenticated;
