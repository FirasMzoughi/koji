-- Appointments (rendez-vous) table.
-- Required by lib/features/synchronization/data/rdv_repository.dart
-- and lib/features/synchronization/data/availability_service.dart.

create table if not exists public.rdvs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  chantier_id uuid references public.chantiers(id) on delete cascade,
  worker_id   uuid,
  worker_name text,
  title       text not null,
  note        text,
  scheduled_at timestamptz not null,
  duration    text not null default '1h',
  created_at  timestamptz not null default now()
);

create index if not exists rdvs_user_id_idx     on public.rdvs (user_id);
create index if not exists rdvs_chantier_id_idx on public.rdvs (chantier_id);
create index if not exists rdvs_worker_id_idx   on public.rdvs (worker_id);
create index if not exists rdvs_scheduled_at_idx on public.rdvs (scheduled_at);

alter table public.rdvs enable row level security;

drop policy if exists "rdvs_select_own"  on public.rdvs;
drop policy if exists "rdvs_insert_own"  on public.rdvs;
drop policy if exists "rdvs_update_own"  on public.rdvs;
drop policy if exists "rdvs_delete_own"  on public.rdvs;

create policy "rdvs_select_own" on public.rdvs
  for select using (auth.uid() = user_id);

create policy "rdvs_insert_own" on public.rdvs
  for insert with check (auth.uid() = user_id);

create policy "rdvs_update_own" on public.rdvs
  for update using (auth.uid() = user_id);

create policy "rdvs_delete_own" on public.rdvs
  for delete using (auth.uid() = user_id);

-- Force PostgREST to refresh its schema cache so the new table is visible
-- (this is what was missing — the PGRST205 error is the schema cache, not RLS).
notify pgrst, 'reload schema';
