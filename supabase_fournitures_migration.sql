-- ============================================
-- Fournitures Feature - Supabase Migration
-- ============================================

-- 1. Fournisseurs Table
CREATE TABLE IF NOT EXISTS fournisseurs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Fournitures Table
CREATE TABLE IF NOT EXISTS fournitures (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fournisseur_id UUID REFERENCES fournisseurs(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  category TEXT DEFAULT 'Autre',
  prix_achat_ht NUMERIC DEFAULT 0,
  prix_vente_ht NUMERIC DEFAULT 0,
  conditionnement TEXT,
  barcode TEXT,
  image_url TEXT,
  source_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. RLS Policies
ALTER TABLE fournisseurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fournitures ENABLE ROW LEVEL SECURITY;

-- Fournisseurs: users can only see/modify their own
CREATE POLICY "Users can view own fournisseurs"
  ON fournisseurs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fournisseurs"
  ON fournisseurs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own fournisseurs"
  ON fournisseurs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own fournisseurs"
  ON fournisseurs FOR DELETE
  USING (auth.uid() = user_id);

-- Fournitures: users can only see/modify their own
CREATE POLICY "Users can view own fournitures"
  ON fournitures FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fournitures"
  ON fournitures FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own fournitures"
  ON fournitures FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own fournitures"
  ON fournitures FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Indexes
CREATE INDEX idx_fournitures_user ON fournitures(user_id);
CREATE INDEX idx_fournitures_fournisseur ON fournitures(fournisseur_id);
CREATE INDEX idx_fournisseurs_user ON fournisseurs(user_id);
