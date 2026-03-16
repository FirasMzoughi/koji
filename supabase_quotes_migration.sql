-- ========================================================================================
-- KÔJI MIGRATION: QUOTES, ROOMS, TASKS, DOCUMENTS & SIGNATURES
-- ========================================================================================

-- 1. QUOTES TABLE
CREATE TABLE IF NOT EXISTS public.quotes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone,
  user_id uuid REFERENCES auth.users NOT NULL DEFAULT auth.uid(),
  chantier_id uuid REFERENCES public.chantiers(id) ON DELETE CASCADE NOT NULL,
  status text DEFAULT 'Draft', -- 'Draft', 'Sent', 'Signed', 'Rejected'
  reference text,
  total_ht numeric DEFAULT 0,
  total_ttc numeric DEFAULT 0,
  tva_rate numeric DEFAULT 20.0,
  metadata jsonb
);

ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read access for user quotes" ON public.quotes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Enable insert access for user quotes" ON public.quotes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Enable update access for user quotes" ON public.quotes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Enable delete access for user quotes" ON public.quotes FOR DELETE USING (auth.uid() = user_id);

-- 2. QUOTE ROOMS TABLE
CREATE TABLE IF NOT EXISTS public.quote_rooms (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  quote_id uuid REFERENCES public.quotes(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL, -- e.g. 'salon', 'cuisine'
  surface numeric DEFAULT 0,
  access_factor numeric DEFAULT 1.0,
  condition_factor numeric DEFAULT 1.0,
  room_order integer DEFAULT 0
);

ALTER TABLE public.quote_rooms ENABLE ROW LEVEL SECURITY;
-- Using nested check for RLS on quote_rooms based on quote owner
CREATE POLICY "Enable read access for quote_rooms" ON public.quote_rooms FOR SELECT 
  USING (EXISTS (SELECT 1 FROM public.quotes WHERE quotes.id = quote_rooms.quote_id AND quotes.user_id = auth.uid()));
CREATE POLICY "Enable insert access for quote_rooms" ON public.quote_rooms FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM public.quotes WHERE quotes.id = quote_rooms.quote_id AND quotes.user_id = auth.uid()));
CREATE POLICY "Enable update access for quote_rooms" ON public.quote_rooms FOR UPDATE 
  USING (EXISTS (SELECT 1 FROM public.quotes WHERE quotes.id = quote_rooms.quote_id AND quotes.user_id = auth.uid()));
CREATE POLICY "Enable delete access for quote_rooms" ON public.quote_rooms FOR DELETE 
  USING (EXISTS (SELECT 1 FROM public.quotes WHERE quotes.id = quote_rooms.quote_id AND quotes.user_id = auth.uid()));

-- 3. QUOTE TASKS TABLE
CREATE TABLE IF NOT EXISTS public.quote_tasks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  room_id uuid REFERENCES public.quote_rooms(id) ON DELETE CASCADE NOT NULL,
  task_id text NOT NULL, -- Smart task ID or Custom task ID
  label text NOT NULL,
  inputs jsonb, -- Map of surface, length, etc.
  selected_products jsonb, -- Map of {productId: quantity}
  note text,
  photo_paths text[], -- Array of image URLs
  unit_price_ht numeric DEFAULT 0,
  total_price_ht numeric DEFAULT 0,
  is_custom boolean DEFAULT false
);

ALTER TABLE public.quote_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for quote_tasks via quote owner" ON public.quote_tasks FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.quote_rooms 
    JOIN public.quotes ON quotes.id = quote_rooms.quote_id 
    WHERE quote_rooms.id = quote_tasks.room_id AND quotes.user_id = auth.uid()
  ));

-- 4. CHANTIER DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS public.chantier_documents (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  chantier_id uuid REFERENCES public.chantiers(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  file_url text NOT NULL,
  file_type text,
  file_size integer
);

-- Ensure user_id mapping if needed for simpler RLS, or join through chantiers
ALTER TABLE public.chantier_documents ADD COLUMN user_id uuid REFERENCES auth.users DEFAULT auth.uid();
ALTER TABLE public.chantier_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all access for user documents" ON public.chantier_documents FOR ALL
  USING (auth.uid() = user_id);

-- 5. SIGNATURES TABLE
CREATE TABLE IF NOT EXISTS public.signatures (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL DEFAULT auth.uid(),
  quote_id uuid REFERENCES public.quotes(id) ON DELETE CASCADE,
  client_name text NOT NULL,
  client_role text,
  signature_url text NOT NULL,
  signed_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.signatures ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for user signatures" ON public.signatures FOR ALL
  USING (auth.uid() = user_id);

-- 6. UPDATE CHANTIERS TABLE (Patch existing)
ALTER TABLE public.chantiers ADD COLUMN IF NOT EXISTS start_date date;
ALTER TABLE public.chantiers ADD COLUMN IF NOT EXISTS end_date date;
ALTER TABLE public.chantiers ADD COLUMN IF NOT EXISTS estimated_budget numeric DEFAULT 0;
ALTER TABLE public.chantiers ADD COLUMN IF NOT EXISTS notes text;

-- STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES ('chantier_documents', 'chantier_documents', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('signatures', 'signatures', true) ON CONFLICT DO NOTHING;

-- Storage Policies for chantier_documents
CREATE POLICY "Allow authenticated uploads chantier_documents" ON storage.objects FOR INSERT TO authenticated WITH CHECK ( bucket_id = 'chantier_documents' );
CREATE POLICY "Allow authenticated select chantier_documents" ON storage.objects FOR SELECT TO authenticated USING ( bucket_id = 'chantier_documents' );
CREATE POLICY "Allow authenticated update chantier_documents" ON storage.objects FOR UPDATE TO authenticated USING ( bucket_id = 'chantier_documents' );
CREATE POLICY "Allow authenticated delete chantier_documents" ON storage.objects FOR DELETE TO authenticated USING ( bucket_id = 'chantier_documents' );

-- Storage Policies for signatures
CREATE POLICY "Allow authenticated uploads signatures" ON storage.objects FOR INSERT TO authenticated WITH CHECK ( bucket_id = 'signatures' );
CREATE POLICY "Allow authenticated select signatures" ON storage.objects FOR SELECT TO authenticated USING ( bucket_id = 'signatures' );
CREATE POLICY "Allow authenticated update signatures" ON storage.objects FOR UPDATE TO authenticated USING ( bucket_id = 'signatures' );
CREATE POLICY "Allow authenticated delete signatures" ON storage.objects FOR DELETE TO authenticated USING ( bucket_id = 'signatures' );

-- 7. CHANTIER TASKS TABLE
CREATE TABLE IF NOT EXISTS public.chantier_tasks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  chantier_id uuid REFERENCES public.chantiers(id) ON DELETE CASCADE NOT NULL,
  label text NOT NULL,
  is_done boolean DEFAULT false
);

ALTER TABLE public.chantier_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for user tasks" ON public.chantier_tasks FOR ALL
  USING (EXISTS (SELECT 1 FROM public.chantiers WHERE chantiers.id = chantier_tasks.chantier_id AND chantiers.user_id = auth.uid()));

-- 8. CHANTIER BUDGETS TABLE
CREATE TABLE IF NOT EXISTS public.chantier_budgets (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone,
  chantier_id uuid REFERENCES public.chantiers(id) ON DELETE CASCADE NOT NULL,
  main_oeuvre_real numeric DEFAULT 0,
  main_oeuvre_estimated numeric DEFAULT 0,
  fourniture_real numeric DEFAULT 0,
  fourniture_estimated numeric DEFAULT 0
);

ALTER TABLE public.chantier_budgets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for user budgets" ON public.chantier_budgets FOR ALL
  USING (EXISTS (SELECT 1 FROM public.chantiers WHERE chantiers.id = chantier_budgets.chantier_id AND chantiers.user_id = auth.uid()));
