-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Budget lines + Budget history
-- Run this in Supabase → SQL Editor → Run
--
-- Adds:
--   1. chantier_budget_lines  — one row per itemized budget line
--      (Main d'œuvre / Fourniture / Divers). The category "real" total is
--      the SUM of its lines.
--   2. chantier_budget_history — audit log: every add / edit / delete of a
--      line, and every change to an estimated target, is recorded here.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. chantier_budget_lines ───────────────────────────────────────────────
create table if not exists public.chantier_budget_lines (
  id            uuid primary key default gen_random_uuid(),
  chantier_id   uuid not null references public.chantiers(id) on delete cascade,
  user_id       uuid not null references auth.users(id) on delete cascade,
  category      text not null check (category in ('main_oeuvre', 'fourniture', 'divers')),
  label         text not null,
  -- generic line amount = quantity * unit_price (or hours * rate)
  quantity      numeric(12, 3) not null default 1,
  unit_price    numeric(12, 2) not null default 0,
  amount        numeric(12, 2) not null default 0,
  attachment_url  text,
  attachment_type text check (attachment_type in ('photo', 'document') or attachment_type is null),
  created_at    timestamptz not null default now()
);

create index if not exists chantier_budget_lines_chantier_idx
  on public.chantier_budget_lines (chantier_id);
create index if not exists chantier_budget_lines_category_idx
  on public.chantier_budget_lines (category);

alter table public.chantier_budget_lines enable row level security;

drop policy if exists "chantier_budget_lines_select" on public.chantier_budget_lines;
drop policy if exists "chantier_budget_lines_insert" on public.chantier_budget_lines;
drop policy if exists "chantier_budget_lines_update" on public.chantier_budget_lines;
drop policy if exists "chantier_budget_lines_delete" on public.chantier_budget_lines;

create policy "chantier_budget_lines_select" on public.chantier_budget_lines
  for select using (auth.uid() = user_id);
create policy "chantier_budget_lines_insert" on public.chantier_budget_lines
  for insert with check (auth.uid() = user_id);
create policy "chantier_budget_lines_update" on public.chantier_budget_lines
  for update using (auth.uid() = user_id);
create policy "chantier_budget_lines_delete" on public.chantier_budget_lines
  for delete using (auth.uid() = user_id);

-- ── 2. chantier_budget_history ─────────────────────────────────────────────
create table if not exists public.chantier_budget_history (
  id            uuid primary key default gen_random_uuid(),
  chantier_id   uuid not null references public.chantiers(id) on delete cascade,
  user_id       uuid not null references auth.users(id) on delete cascade,
  category      text not null check (category in ('main_oeuvre', 'fourniture', 'divers')),
  -- 'add_line' | 'delete_line' | 'edit_estimated'
  action        text not null,
  label         text,
  -- signed delta applied to the category real total (+ for add, - for delete)
  amount_delta  numeric(12, 2) not null default 0,
  -- snapshot of the category real total AFTER this change
  total_after   numeric(12, 2) not null default 0,
  created_at    timestamptz not null default now()
);

create index if not exists chantier_budget_history_chantier_idx
  on public.chantier_budget_history (chantier_id);

alter table public.chantier_budget_history enable row level security;

drop policy if exists "chantier_budget_history_select" on public.chantier_budget_history;
drop policy if exists "chantier_budget_history_insert" on public.chantier_budget_history;

create policy "chantier_budget_history_select" on public.chantier_budget_history
  for select using (auth.uid() = user_id);
create policy "chantier_budget_history_insert" on public.chantier_budget_history
  for insert with check (auth.uid() = user_id);

notify pgrst, 'reload schema';
