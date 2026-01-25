-- Migration: Add logo_url column to users table
-- Run this in Supabase SQL Editor if you already have the users table created

-- Add logo_url column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Create storage bucket for business logos
INSERT INTO storage.buckets (id, name, public)
VALUES ('business-logos', 'business-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies for business-logos bucket

-- Allow users to upload their own logo
CREATE POLICY "Users can upload own logo"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'business-logos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to read their own logo
CREATE POLICY "Users can read own logo"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'business-logos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to update their own logo
CREATE POLICY "Users can update own logo"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'business-logos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own logo
CREATE POLICY "Users can delete own logo"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'business-logos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
