-- Fournitures (supplies) and fournisseurs (suppliers) tables.
-- Required by lib/features/fournitures/repository/fourniture_repository.dart
-- and lib/features/fournitures/add_fourniture_screen.dart.

create table if not exists public.fournisseurs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  logo_url   text,
  created_at timestamptz not null default now()
);

create index if not exists fournisseurs_user_id_idx on public.fournisseurs (user_id);
create index if not exists fournisseurs_name_idx    on public.fournisseurs (name);

create table if not exists public.fournitures (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  fournisseur_id  uuid references public.fournisseurs(id) on delete set null,
  name            text not null,
  category        text not null default 'Autre',
  prix_achat_ht   numeric(12, 2) not null default 0,
  prix_vente_ht   numeric(12, 2) not null default 0,
  conditionnement text,
  quantite        numeric(12, 3),
  unite           text,
  barcode         text,
  image_url       text,
  source_url      text,
  created_at      timestamptz not null default now()
);

-- Idempotent column adds for existing installations
alter table public.fournitures add column if not exists quantite numeric(12, 3);
alter table public.fournitures add column if not exists unite    text;

create index if not exists fournitures_user_id_idx        on public.fournitures (user_id);
create index if not exists fournitures_fournisseur_id_idx on public.fournitures (fournisseur_id);
create index if not exists fournitures_created_at_idx     on public.fournitures (created_at desc);

alter table public.fournisseurs enable row level security;
alter table public.fournitures  enable row level security;

drop policy if exists "fournisseurs_select_own" on public.fournisseurs;
drop policy if exists "fournisseurs_insert_own" on public.fournisseurs;
drop policy if exists "fournisseurs_update_own" on public.fournisseurs;
drop policy if exists "fournisseurs_delete_own" on public.fournisseurs;

create policy "fournisseurs_select_own" on public.fournisseurs
  for select using (auth.uid() = user_id);

create policy "fournisseurs_insert_own" on public.fournisseurs
  for insert with check (auth.uid() = user_id);

create policy "fournisseurs_update_own" on public.fournisseurs
  for update using (auth.uid() = user_id);

create policy "fournisseurs_delete_own" on public.fournisseurs
  for delete using (auth.uid() = user_id);

drop policy if exists "fournitures_select_own" on public.fournitures;
drop policy if exists "fournitures_insert_own" on public.fournitures;
drop policy if exists "fournitures_update_own" on public.fournitures;
drop policy if exists "fournitures_delete_own" on public.fournitures;

create policy "fournitures_select_own" on public.fournitures
  for select using (auth.uid() = user_id);

create policy "fournitures_insert_own" on public.fournitures
  for insert with check (auth.uid() = user_id);

create policy "fournitures_update_own" on public.fournitures
  for update using (auth.uid() = user_id);

create policy "fournitures_delete_own" on public.fournitures
  for delete using (auth.uid() = user_id);

-- Refresh PostgREST schema cache so the new tables are immediately visible.
notify pgrst, 'reload schema';
