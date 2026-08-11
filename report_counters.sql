-- ============================================================
-- ESEP: счётчик номеров отчётов (G-XXXX) + RPC next_report_number
-- ============================================================
-- Нумерация продолжается с последнего номера в шаблонах (G-0341, G-0349).
-- Чтобы стартовать с G-0350 — выполни UPDATE (см. конец файла).
-- Запусти в Supabase SQL Editor.
-- ============================================================

create table if not exists public.report_counters (
  prefix text primary key,          -- 'G' для отчётов GaMa Group
  last_number int not null default 0
);

alter table public.report_counters enable row level security;

-- RLS: никто не читает/пишет напрямую (всё через RPC security definer)
drop policy if exists report_counters_select on public.report_counters;
create policy report_counters_select on public.report_counters
  for select using (false);

drop policy if exists report_counters_insert on public.report_counters;
create policy report_counters_insert on public.report_counters
  for insert with check (false);

drop policy if exists report_counters_update on public.report_counters;
create policy report_counters_update on public.report_counters
  for update using (false);

-- RPC: выдать следующий номер (атомарно, без гонок)
-- Вызов: select next_report_number();  — по умолчанию префикс 'G'
create or replace function public.next_report_number(p_prefix text default 'G')
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next int;
begin
  -- строка счётчика (создаём при первом обращении)
  insert into public.report_counters (prefix, last_number)
  values (p_prefix, 0)
  on conflict (prefix) do nothing;

  update public.report_counters
  set last_number = last_number + 1
  where prefix = p_prefix
  returning last_number into v_next;

  return p_prefix || '-' || lpad(v_next::text, 4, '0');
end $$;

-- Права: только authenticated (любой залогиненный пользователь) может вызвать.
-- security definer делает INSERT/UPDATE от имени владельца (postgres),
-- поэтому RLS таблицы (false) не блокирует.
revoke all on function public.next_report_number(text) from public;
grant execute on function public.next_report_number(text) to authenticated;

-- ============================================================
-- Стартовая нумерация (раскомментируй при первом запуске):
-- последний номер в шаблонах — G-0349 → начинаем с G-0350
-- ============================================================
-- insert into public.report_counters (prefix, last_number) values ('G', 349)
-- on conflict (prefix) do update set last_number = 349;
