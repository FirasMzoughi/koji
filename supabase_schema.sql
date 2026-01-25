-- Supabase Database Schema for Koji Application
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  is_pro BOOLEAN DEFAULT false,
  profession TEXT,
  is_profile_complete BOOLEAN DEFAULT false,
  is_business_info_complete BOOLEAN DEFAULT false,
  business_info JSONB,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Quotes Table
CREATE TABLE IF NOT EXISTS quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'en_cours',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Quote data fields (adjust based on your actual quote structure)
  client_name TEXT,
  client_email TEXT,
  client_phone TEXT,
  client_address TEXT,
  rooms JSONB,
  tasks JSONB,
  total_amount DECIMAL(10, 2),
  notes TEXT,
  -- Signature fields
  signature_url TEXT,
  signature_data TEXT,
  signed_at TIMESTAMPTZ
);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Users Table
-- Users can read their own data
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can insert their own data
CREATE POLICY "Users can insert own data"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- RLS Policies for Quotes Table
-- Users can view their own quotes
CREATE POLICY "Users can view own quotes"
  ON quotes FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own quotes
CREATE POLICY "Users can insert own quotes"
  ON quotes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own quotes
CREATE POLICY "Users can update own quotes"
  ON quotes FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own quotes
CREATE POLICY "Users can delete own quotes"
  ON quotes FOR DELETE
  USING (auth.uid() = user_id);

-- Client access policies (for signature workflow)
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_quotes_user_id ON quotes(user_id);
CREATE INDEX IF NOT EXISTS idx_quotes_created_at ON quotes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
