-- Migration: Add Signature Columns to Quotes Table
-- Run this in your Supabase SQL Editor

-- Add the new signature-related columns
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS signature_url TEXT,
ADD COLUMN IF NOT EXISTS signature_data TEXT,
ADD COLUMN IF NOT EXISTS signed_at TIMESTAMPTZ;

-- Drop existing client access policies if they exist
DROP POLICY IF EXISTS "Clients can view quotes by email" ON quotes;
DROP POLICY IF EXISTS "Clients can update signature" ON quotes;

-- Create client access policies for signature workflow
-- Clients can view quotes matching their email (no auth required)
CREATE POLICY "Clients can view quotes by email"
  ON quotes FOR SELECT
  USING (client_email = current_setting('request.jwt.claims', true)::json->>'email' 
         OR auth.uid() = user_id);

-- Clients can update signature data for their quotes
CREATE POLICY "Clients can update signature"
  ON quotes FOR UPDATE
  USING (client_email = current_setting('request.jwt.claims', true)::json->>'email' 
         OR auth.uid() = user_id)
  WITH CHECK (client_email = current_setting('request.jwt.claims', true)::json->>'email' 
              OR auth.uid() = user_id);

-- Verify the columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'quotes' 
  AND column_name IN ('signature_url', 'signature_data', 'signed_at');
