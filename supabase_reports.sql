-- ============================================================
-- ESEP: таблица reports (отчёты об оценке, привязанные к заявкам)
-- ============================================================
-- Статусы:
--   draft    — черновик (сгенерирован, но не оплачен / не подписан)
--   signed   — подписан оценщиком ЭЦП, официальный
--   paid     — оплачен клиентом (доступен для скачивания)
--
-- Файл PDF лежит в storage bucket 'reports', в БД хранится ссылка.
-- ============================================================

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  status text not null default 'draft'
    check (status in ('draft', 'signed', 'paid')),
  report_number text,
  report_data jsonb,              -- полные данные отчёта (ReportData)
  file_url text,                  -- публичный URL PDF в storage
  pdf_path text,                  -- путь в storage bucket 'reports'
  signer_name text,
  signer_iin text,
  signature_path text,            -- путь к .cms файлу подписи
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Индекс для быстрого поиска отчёта по заявке
create index if not exists reports_application_id_idx
  on public.reports (application_id);

-- RLS: владелец (клиент) видит свой отчёт; оценщик и админ — все
alter table public.reports enable row level security;

drop policy if exists reports_select_own on public.reports;
create policy reports_select_own on public.reports
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid() and p.role = 'appraiser'
    )
    or exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own on public.reports
  for insert with check (auth.uid() = user_id);

drop policy if exists reports_update_own on public.reports;
create policy reports_update_own on public.reports
  for update using (
    auth.uid() = user_id
    or exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid() and p.role = 'appraiser'
    )
    or exists (
      select 1 from public.profiles p
      where p.user_id = auth.uid() and p.role = 'admin'
    )
  );

-- Триггер обновления updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists reports_set_updated_at on public.reports;
create trigger reports_set_updated_at
  before update on public.reports
  for each row execute function public.set_updated_at();
