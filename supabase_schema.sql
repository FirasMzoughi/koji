-- Create the table for workers if it doesn't exist
create table if not exists public.workers (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null default auth.uid(), -- Link to the user who created it
  first_name text not null,
  last_name text not null,
  profession text not null, -- e.g., 'Electricien', 'Plombier'
  status text default 'Disponible', -- 'Disponible', 'Sur Chantier', 'En cours de projet'
  profile_picture_url text,
  social_security_number text,
  address text,
  id_card_url text,
  phone_number text,
  email text,
  hourly_rate numeric,
  hire_date date
);

-- Ensure user_id column exists (safely add if missing)
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name = 'workers' and column_name = 'user_id') then
    alter table public.workers add column user_id uuid references auth.users default auth.uid();
  end if;
end $$;

-- Enable Row Level Security (RLS)
alter table public.workers enable row level security;

-- Policies (Drop first to avoid duplication error on re-run)
drop policy if exists "Enable read access for all users" on public.workers;
create policy "Enable read access for all users" on public.workers
  for select using (auth.uid() = user_id);

drop policy if exists "Enable insert access for all users" on public.workers;
create policy "Enable insert access for all users" on public.workers
  for insert with check (auth.uid() = user_id);

drop policy if exists "Enable update access for all users" on public.workers;
create policy "Enable update access for all users" on public.workers
  for update using (auth.uid() = user_id);

drop policy if exists "Enable delete access for all users" on public.workers;
create policy "Enable delete access for all users" on public.workers
  for delete using (auth.uid() = user_id);


-- STORAGE SETUP
-- Create a storage bucket for worker documents
insert into storage.buckets (id, name, public) 
values ('worker_docs', 'worker_docs', true)
on conflict (id) do nothing;

-- Storage Policies
drop policy if exists "Allow authenticated uploads" on storage.objects;
create policy "Allow authenticated uploads"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'worker_docs' );

drop policy if exists "Allow authenticated select" on storage.objects;
create policy "Allow authenticated select"
on storage.objects for select
to authenticated
using ( bucket_id = 'worker_docs' );

drop policy if exists "Allow authenticated update" on storage.objects;
create policy "Allow authenticated update"
on storage.objects for update
to authenticated
using ( bucket_id = 'worker_docs' );

drop policy if exists "Allow authenticated delete" on storage.objects;
create policy "Allow authenticated delete"
on storage.objects for delete
to authenticated
using ( bucket_id = 'worker_docs' );

-- PROJECTS TABLE
create table if not exists public.projects (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null default auth.uid(), -- Link to owner
  title text not null,
  client_name text not null,
  address text,
  status text default 'En Cours', -- 'En Cours', 'Terminé', 'À Venir'
  image_url text,
  start_date date,
  end_date date
);

-- Ensure user_id column exists for projects
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name = 'projects' and column_name = 'user_id') then
    alter table public.projects add column user_id uuid references auth.users default auth.uid();
  end if;
end $$;

-- Enable RLS for Projects
alter table public.projects enable row level security;

-- Policies for Projects
drop policy if exists "Enable read access for all users" on public.projects;
create policy "Enable read access for all users" on public.projects for select using (auth.uid() = user_id);

drop policy if exists "Enable insert access for all users" on public.projects;
create policy "Enable insert access for all users" on public.projects for insert with check (auth.uid() = user_id);

drop policy if exists "Enable update access for all users" on public.projects;
create policy "Enable update access for all users" on public.projects for update using (auth.uid() = user_id);

drop policy if exists "Enable delete access for all users" on public.projects;
create policy "Enable delete access for all users" on public.projects for delete using (auth.uid() = user_id);

-- PROJECT ASSIGNMENTS TABLE
create table if not exists public.project_assignments (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null default auth.uid(), -- Link to owner
  project_id uuid references public.projects(id) on delete cascade not null,
  worker_id uuid references public.workers(id) on delete cascade not null,
  role text,
  assigned_at timestamp with time zone default timezone('utc'::text, now())
);

-- Ensure user_id column exists for assignments
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name = 'project_assignments' and column_name = 'user_id') then
    alter table public.project_assignments add column user_id uuid references auth.users default auth.uid();
  end if;
end $$;

-- Enable RLS for Assignments
alter table public.project_assignments enable row level security;

-- Policies for Assignments
drop policy if exists "Enable read access for all users" on public.project_assignments;
create policy "Enable read access for all users" on public.project_assignments for select using (auth.uid() = user_id);

drop policy if exists "Enable insert access for all users" on public.project_assignments;
create policy "Enable insert access for all users" on public.project_assignments for insert with check (auth.uid() = user_id);

drop policy if exists "Enable update access for all users" on public.project_assignments;
create policy "Enable update access for all users" on public.project_assignments for update using (auth.uid() = user_id);

drop policy if exists "Enable delete access for all users" on public.project_assignments;
create policy "Enable delete access for all users" on public.project_assignments for delete using (auth.uid() = user_id);

-- PROJECT TASKS TABLE
create table if not exists public.project_tasks (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null default auth.uid(), -- Link to owner
  project_id uuid references public.projects(id) on delete cascade not null,
  task_name text not null,
  room_name text,
  status text default 'À Faire', -- 'À Faire', 'En Cours', 'Terminé'
  worker_id uuid references public.workers(id), -- Optional: Assign specific worker to task
  details jsonb -- Store inputs, products etc.
);

-- Ensure columns exist for project_tasks
do $$ 
begin 
  if not exists (select 1 from information_schema.columns where table_name = 'project_tasks' and column_name = 'user_id') then
    alter table public.project_tasks add column user_id uuid references auth.users default auth.uid();
  end if;
  if not exists (select 1 from information_schema.columns where table_name = 'project_tasks' and column_name = 'worker_id') then
    alter table public.project_tasks add column worker_id uuid references public.workers(id);
  end if;
end $$;

-- Enable RLS for Project Tasks
alter table public.project_tasks enable row level security;

-- Policies for Project Tasks
drop policy if exists "Enable read access for all users" on public.project_tasks;
create policy "Enable read access for all users" on public.project_tasks for select using (auth.uid() = user_id);

drop policy if exists "Enable insert access for all users" on public.project_tasks;
create policy "Enable insert access for all users" on public.project_tasks for insert with check (auth.uid() = user_id);

drop policy if exists "Enable update access for all users" on public.project_tasks;
create policy "Enable update access for all users" on public.project_tasks for update using (auth.uid() = user_id);

drop policy if exists "Enable delete access for all users" on public.project_tasks;
create policy "Enable delete access for all users" on public.project_tasks for delete using (auth.uid() = user_id);



-- TASKS LIBRARY TABLE (User defined tasks)
create table if not exists public.tasks (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users not null default auth.uid(),
  title text not null,
  description text,
  profession text, -- e.g. 'Peintre'
  image_urls text[], -- Array of image URLs
  default_products jsonb -- List of default product IDs or details
);

-- Enable RLS for Tasks
alter table public.tasks enable row level security;

-- Policies for Tasks
drop policy if exists "Enable read access for all users" on public.tasks;
create policy "Enable read access for all users" on public.tasks for select using (auth.uid() = user_id);

drop policy if exists "Enable insert access for all users" on public.tasks;
create policy "Enable insert access for all users" on public.tasks for insert with check (auth.uid() = user_id);

drop policy if exists "Enable update access for all users" on public.tasks;
create policy "Enable update access for all users" on public.tasks for update using (auth.uid() = user_id);

drop policy if exists "Enable delete access for all users" on public.tasks;
create policy "Enable delete access for all users" on public.tasks for delete using (auth.uid() = user_id);

-- STORAGE for TASK IMAGES
insert into storage.buckets (id, name, public) 
values ('task_images', 'task_images', true)
on conflict (id) do nothing;

-- Storage Policies for task_images
drop policy if exists "Allow authenticated uploads task_images" on storage.objects;
create policy "Allow authenticated uploads task_images"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'task_images' );

drop policy if exists "Allow authenticated select task_images" on storage.objects;
create policy "Allow authenticated select task_images"
on storage.objects for select
to authenticated
using ( bucket_id = 'task_images' );

drop policy if exists "Allow authenticated update task_images" on storage.objects;
create policy "Allow authenticated update task_images"
on storage.objects for update
to authenticated
using ( bucket_id = 'task_images' );

drop policy if exists "Allow authenticated delete task_images" on storage.objects;
create policy "Allow authenticated delete task_images"
on storage.objects for delete
to authenticated
using ( bucket_id = 'task_images' );

-- ============================================================
-- PRICING SYSTEM TABLES
-- ============================================================

-- PRICING PROFILES TABLE (Global pricing configuration per profession)
create table if not exists public.pricing_profiles (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  profession text not null unique,
  daily_rate_ht numeric not null default 350.0,
  hours_per_day numeric not null default 7.0,
  is_active boolean default true
);

-- Enable RLS for Pricing Profiles
alter table public.pricing_profiles enable row level security;

-- Policies for Pricing Profiles (Read-only for all authenticated users)
drop policy if exists "Enable read access for all users" on public.pricing_profiles;
create policy "Enable read access for all users" on public.pricing_profiles for select to authenticated using (true);

-- SMART TASKS TABLE (Task definitions with normative times)
create table if not exists public.smart_tasks (
  id text primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  label text not null,
  profession text not null,
  unit text not null, -- 'm2', 'ml', 'forfait', 'u'
  normative_time numeric not null, -- hours per unit (or fixed hours if is_fixed_time = true)
  is_fixed_time boolean default false
);

-- Enable RLS for Smart Tasks
alter table public.smart_tasks enable row level security;

-- Policies for Smart Tasks (Read-only for all authenticated users)
drop policy if exists "Enable read access for all users" on public.smart_tasks;
create policy "Enable read access for all users" on public.smart_tasks for select to authenticated using (true);

-- TASK MATERIAL REQUIREMENTS TABLE (Material requirements for each task)
create table if not exists public.task_material_requirements (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  task_id text references public.smart_tasks(id) on delete cascade not null,
  product_category text not null,
  yield numeric not null, -- m²/unit or units per application (0 for fixed quantity)
  default_price_per_unit numeric not null,
  is_fixed_quantity boolean default false
);

-- Enable RLS for Task Material Requirements
alter table public.task_material_requirements enable row level security;

-- Policies for Task Material Requirements (Read-only for all authenticated users)
drop policy if exists "Enable read access for all users" on public.task_material_requirements;
create policy "Enable read access for all users" on public.task_material_requirements for select to authenticated using (true);

-- ============================================================
-- SEED DATA - PRICING PROFILES
-- ============================================================
insert into public.pricing_profiles (profession, daily_rate_ht, hours_per_day) values
  ('Peintre', 350.0, 7.0)
on conflict (profession) do nothing;

-- ============================================================
-- SEED DATA - PAINTER TASKS
-- ============================================================
insert into public.smart_tasks (id, label, profession, unit, normative_time, is_fixed_time) values
  ('ratissage', 'Ratissage (Enduit)', 'Peintre', 'm2', 0.15, false),
  ('poncage', 'Ponçage des murs', 'Peintre', 'm2', 0.06, false),
  ('impression', 'Impression (Sous-couche)', 'Peintre', 'm2', 0.10, false),
  ('peinture_murs_2c', 'Peinture Murs (2 couches)', 'Peintre', 'm2', 0.60, false),
  ('peinture_plafond_2c', 'Peinture Plafond (2 couches)', 'Peintre', 'm2', 0.70, false),
  ('protection_meubles', 'Protection mobilier', 'Peintre', 'forfait', 2.5, true),
  ('nettoyage_fin', 'Nettoyage final', 'Peintre', 'forfait', 1.0, true)
on conflict (id) do nothing;

-- ============================================================
-- SEED DATA - MATERIAL REQUIREMENTS
-- ============================================================
-- Ratissage
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('ratissage', 'Enduit', 8.0, 18.0, false)
on conflict do nothing;

-- Impression
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('impression', 'Peinture', 8.0, 10.0, false)
on conflict do nothing;

-- Peinture Murs (2 coats: 10m²/L per coat → 5m²/L total)
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('peinture_murs_2c', 'Peinture', 5.0, 12.0, false)
on conflict do nothing;

-- Peinture Plafond (2 coats)
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('peinture_plafond_2c', 'Peinture', 5.0, 12.0, false)
on conflict do nothing;

-- Protection mobilier (Fixed cost consumables)
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('protection_meubles', 'Outillage', 0, 20.0, true)
on conflict do nothing;

-- Nettoyage (Optional consumables)
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('nettoyage_fin', 'Outillage', 0, 15.0, true)
on conflict do nothing;

-- ============================================================
-- SEED DATA - ADDITIONAL PROFESSIONS
-- ============================================================
insert into public.pricing_profiles (profession, daily_rate_ht, hours_per_day) values
  ('Électricien', 400.0, 7.0),
  ('Plombier', 380.0, 7.0),
  ('Menuisier', 360.0, 7.0),
  ('Maçon', 370.0, 7.0)
on conflict (profession) do nothing;

-- ============================================================
-- SEED DATA - ÉLECTRICIEN TASKS
-- ============================================================
insert into public.smart_tasks (id, label, profession, unit, normative_time, is_fixed_time) values
  ('elec_prise', 'Installation prise électrique', 'Électricien', 'u', 0.5, false),
  ('elec_interrupteur', 'Installation interrupteur', 'Électricien', 'u', 0.4, false),
  ('elec_tableau', 'Installation tableau électrique', 'Électricien', 'u', 4.0, false),
  ('elec_cablage', 'Câblage électrique', 'Électricien', 'ml', 0.15, false),
  ('elec_luminaire', 'Pose luminaire', 'Électricien', 'u', 0.8, false),
  ('elec_raccordement', 'Raccordement électrique', 'Électricien', 'forfait', 2.0, true)
on conflict (id) do nothing;

-- Material requirements for electrical tasks
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('elec_prise', 'Électricité', 0, 8.0, true),
  ('elec_interrupteur', 'Électricité', 0, 6.0, true),
  ('elec_tableau', 'Électricité', 0, 150.0, true),
  ('elec_cablage', 'Électricité', 10.0, 2.5, false),
  ('elec_luminaire', 'Électricité', 0, 25.0, true)
on conflict do nothing;

-- ============================================================
-- SEED DATA - PLOMBIER TASKS
-- ============================================================
insert into public.smart_tasks (id, label, profession, unit, normative_time, is_fixed_time) values
  ('plomb_lavabo', 'Pose lavabo', 'Plombier', 'u', 2.5, false),
  ('plomb_wc', 'Pose WC', 'Plombier', 'u', 2.0, false),
  ('plomb_douche', 'Installation douche', 'Plombier', 'u', 4.0, false),
  ('plomb_tuyauterie', 'Tuyauterie', 'Plombier', 'ml', 0.25, false),
  ('plomb_raccordement', 'Raccordement eau', 'Plombier', 'u', 1.5, false),
  ('plomb_radiateur', 'Pose radiateur', 'Plombier', 'u', 3.0, false)
on conflict (id) do nothing;

-- Material requirements for plumbing tasks
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('plomb_lavabo', 'Plomberie', 0, 120.0, true),
  ('plomb_wc', 'Plomberie', 0, 180.0, true),
  ('plomb_douche', 'Plomberie', 0, 350.0, true),
  ('plomb_tuyauterie', 'Plomberie', 5.0, 8.0, false),
  ('plomb_radiateur', 'Plomberie', 0, 200.0, true)
on conflict do nothing;

-- ============================================================
-- SEED DATA - MENUISIER TASKS
-- ============================================================
insert into public.smart_tasks (id, label, profession, unit, normative_time, is_fixed_time) values
  ('menu_porte', 'Pose porte intérieure', 'Menuisier', 'u', 3.0, false),
  ('menu_fenetre', 'Pose fenêtre', 'Menuisier', 'u', 4.0, false),
  ('menu_parquet', 'Pose parquet', 'Menuisier', 'm2', 0.5, false),
  ('menu_placard', 'Installation placard', 'Menuisier', 'u', 5.0, false),
  ('menu_plinthe', 'Pose plinthes', 'Menuisier', 'ml', 0.10, false),
  ('menu_etagere', 'Installation étagères', 'Menuisier', 'u', 1.5, false)
on conflict (id) do nothing;

-- Material requirements for carpentry tasks
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('menu_porte', 'Menuiserie', 0, 150.0, true),
  ('menu_fenetre', 'Menuiserie', 0, 300.0, true),
  ('menu_parquet', 'Menuiserie', 1.0, 35.0, false),
  ('menu_placard', 'Menuiserie', 0, 400.0, true),
  ('menu_plinthe', 'Menuiserie', 10.0, 5.0, false)
on conflict do nothing;

-- ============================================================
-- SEED DATA - MAÇON TASKS
-- ============================================================
insert into public.smart_tasks (id, label, profession, unit, normative_time, is_fixed_time) values
  ('macon_mur_parpaing', 'Mur en parpaing', 'Maçon', 'm2', 1.2, false),
  ('macon_chape', 'Chape béton', 'Maçon', 'm2', 0.8, false),
  ('macon_enduit_ext', 'Enduit extérieur', 'Maçon', 'm2', 0.5, false),
  ('macon_dalle', 'Dalle béton', 'Maçon', 'm2', 0.6, false),
  ('macon_cloison', 'Cloison placo', 'Maçon', 'm2', 0.7, false),
  ('macon_carrelage', 'Pose carrelage', 'Maçon', 'm2', 0.9, false)
on conflict (id) do nothing;

-- Material requirements for masonry tasks
insert into public.task_material_requirements (task_id, product_category, yield, default_price_per_unit, is_fixed_quantity) values
  ('macon_mur_parpaing', 'Maçonnerie', 1.0, 12.0, false),
  ('macon_chape', 'Maçonnerie', 1.0, 15.0, false),
  ('macon_enduit_ext', 'Maçonnerie', 5.0, 18.0, false),
  ('macon_dalle', 'Maçonnerie', 1.0, 20.0, false),
  ('macon_cloison', 'Maçonnerie', 1.0, 8.0, false),
  ('macon_carrelage', 'Maçonnerie', 1.0, 25.0, false)
on conflict do nothing;
