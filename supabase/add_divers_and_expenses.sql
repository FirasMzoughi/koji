-- Adds:
--   1. divers_real / divers_estimated columns on chantier_budgets
--   2. chantier_expenses table for itemized expense lines (Main d'œuvre,
--      Fourniture, Divers) with optional attachment URL
--   3. Storage bucket 'chantier-attachments' + policies
--
-- Required by lib/features/quote/chantier_budget_screen.dart (Divers row +
-- Photo / Caméra / Document upload buttons in the Divers add dialog).

-- ── 1. Budget columns ──────────────────────────────────────────────────────
alter table public.chantier_budgets
  add column if not exists divers_real      double precision default 0,
  add column if not exists divers_estimated double precision default 0;

-- ── 2. chantier_expenses ───────────────────────────────────────────────────
create table if not exists public.chantier_expenses (
  id             uuid primary key default gen_random_uuid(),
  chantier_id    uuid not null references public.chantiers(id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  category       text not null check (category in ('main_oeuvre', 'fourniture', 'divers')),
  description    text not null,
  amount         numeric(12, 2) not null default 0,
  quantity       numeric(12, 3),
  unit_price     numeric(12, 2),
  attachment_url text,
  attachment_type text check (attachment_type in ('photo', 'document') or attachment_type is null),
  created_at     timestamptz not null default now()
);

create index if not exists chantier_expenses_chantier_idx on public.chantier_expenses (chantier_id);
create index if not exists chantier_expenses_category_idx on public.chantier_expenses (category);

alter table public.chantier_expenses enable row level security;

drop policy if exists "chantier_expenses_select" on public.chantier_expenses;
drop policy if exists "chantier_expenses_insert" on public.chantier_expenses;
drop policy if exists "chantier_expenses_update" on public.chantier_expenses;
drop policy if exists "chantier_expenses_delete" on public.chantier_expenses;

create policy "chantier_expenses_select" on public.chantier_expenses
  for select using (auth.uid() = user_id);

create policy "chantier_expenses_insert" on public.chantier_expenses
  for insert with check (auth.uid() = user_id);

create policy "chantier_expenses_update" on public.chantier_expenses
  for update using (auth.uid() = user_id);

create policy "chantier_expenses_delete" on public.chantier_expenses
  for delete using (auth.uid() = user_id);

-- ── 3. Storage bucket for attachments ──────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('chantier-attachments', 'chantier-attachments', true)
on conflict (id) do nothing;

drop policy if exists "chantier_attachments_select" on storage.objects;
drop policy if exists "chantier_attachments_insert" on storage.objects;
drop policy if exists "chantier_attachments_delete" on storage.objects;

create policy "chantier_attachments_select" on storage.objects
  for select using (bucket_id = 'chantier-attachments');

create policy "chantier_attachments_insert" on storage.objects
  for insert with check (
    bucket_id = 'chantier-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "chantier_attachments_delete" on storage.objects
  for delete using (
    bucket_id = 'chantier-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

notify pgrst, 'reload schema';
