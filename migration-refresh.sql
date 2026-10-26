-- =====================================================================
--  הוספת טבלת רענוני ירי
--  להריץ פעם אחת ב: Supabase → SQL Editor → New query → Run
--  (לפני שמעלים את index.html החדש ל-GitHub). אפשר להריץ שוב בלי נזק.
-- =====================================================================

-- תקופות רענון (עמודות בטבלה) – השם נכתב ידנית, sort קובע את הסדר
create table if not exists public.refresh_periods (
  id          text primary key default gen_random_uuid()::text,
  name        text not null,
  sort        integer not null default 0,
  created_at  timestamptz not null default now()
);

-- רשומת רענון לעובד בתקופה: בוצע (עם תאריך) או פטור (עם סיבה)
create table if not exists public.refresh_records (
  id             text primary key,                 -- <emp_id>_<period_id>
  emp_id         text not null references public.employees(id)       on delete cascade,
  period_id      text not null references public.refresh_periods(id) on delete cascade,
  status         text not null check (status in ('done', 'exempt')),
  done_date      date,
  exempt_reason  text check (exempt_reason in ('מילואים', 'קורס', 'אחר')),
  note           text default '',
  created_at     timestamptz not null default now(),
  unique (emp_id, period_id),
  constraint refresh_fields_valid check (
    (status = 'done'   and done_date is not null) or
    (status = 'exempt' and exempt_reason is not null)
  )
);
create index if not exists refresh_records_period_idx on public.refresh_records (period_id);

-- אבטחה: רק משתמשים מחוברים
alter table public.refresh_periods enable row level security;
alter table public.refresh_records enable row level security;
drop policy if exists "signed-in full access" on public.refresh_periods;
drop policy if exists "signed-in full access" on public.refresh_records;
create policy "signed-in full access" on public.refresh_periods
  for all to authenticated using (true) with check (true);
create policy "signed-in full access" on public.refresh_records
  for all to authenticated using (true) with check (true);

-- סנכרון חי
do $$
begin
  begin alter publication supabase_realtime add table public.refresh_periods; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.refresh_records; exception when duplicate_object then null; end;
end $$;
