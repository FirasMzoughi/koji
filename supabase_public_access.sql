-- PUBLIC ACCESS FOR CLIENTS (Run this in Supabase SQL Editor)

-- 1. Function to safely get a quote without being logged in
-- It only returns data if the ID and Email EXACTLY match.
CREATE OR REPLACE FUNCTION get_quote_for_client(p_quote_id uuid, p_email text)
RETURNS setof quotes
LANGUAGE plpgsql
SECURITY DEFINER -- Run with admin privileges to bypass RLS
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM quotes
  WHERE id = p_quote_id 
    AND LOWER(TRIM(client_email)) = LOWER(TRIM(p_email))
  LIMIT 1;
END;
$$;

-- 2. Function to safely sign a quote without being logged in
-- It only updates if the ID and Email EXACTLY match.
CREATE OR REPLACE FUNCTION submit_quote_signature(p_quote_id uuid, p_email text, p_signature_data text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated boolean;
BEGIN
  UPDATE quotes
  SET 
    signature_data = p_signature_data,
    signed_at = NOW(),
    status = 'accepte'
  WHERE id = p_quote_id 
    AND LOWER(TRIM(client_email)) = LOWER(TRIM(p_email));

  -- Check if any row was actually updated
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  
  RETURN v_updated > 0;
END;
$$;

-- Grant access to these functions to the public (anon) role
GRANT EXECUTE ON FUNCTION get_quote_for_client(uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION submit_quote_signature(uuid, text, text) TO anon, authenticated;
