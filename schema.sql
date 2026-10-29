-- =====================================================================
--  מערכת זמינות כוח אדם – הקמת מסד הנתונים ב-Supabase
--  להדביק ב: Supabase → SQL Editor → New query → Run
--  אפשר להריץ שוב בלי לשבור כלום.
-- =====================================================================

-- ---------- עובדים ----------
create table if not exists public.employees (
  id          text primary key default gen_random_uuid()::text,
  name        text not null,
  role        text not null check (role in ('אחמ"ש', 'מאבטח', 'שומר')),
  phone       text default '',
  student     boolean not null default false,
  shabbat     boolean not null default false,
  created_at  timestamptz not null default now()
);
-- עדכון למסד קיים (מוסיף את העמודה אם היא חסרה)
alter table public.employees add column if not exists shabbat boolean not null default false;
alter table public.employees add column if not exists max_shifts integer not null default 0 check (max_shifts between 0 and 21);

-- ---------- היעדרויות ----------
create table if not exists public.absences (
  id          text primary key default gen_random_uuid()::text,
  emp_id      text not null references public.employees(id) on delete cascade,
  type        text not null check (type in ('vacation', 'sick', 'reserve')),
  date_from   date not null,
  date_to     date not null,
  note        text default '',
  created_at  timestamptz not null default now(),
  constraint absences_dates_valid check (date_to >= date_from)
);
create index if not exists absences_emp_idx   on public.absences (emp_id);
create index if not exists absences_dates_idx on public.absences (date_from, date_to);

-- ---------- הגדרות (תקן מינימלי לפי תפקיד) ----------
create table if not exists public.settings (
  key    text primary key,
  value  jsonb not null
);
insert into public.settings (key, value)
values ('minimums',         '{"אחמ\"ש": 1, "מאבטח": 3, "שומר": 2}'::jsonb),
       ('minimums_weekend', '{"אחמ\"ש": 3, "מאבטח": 6, "שומר": 3}'::jsonb),
       ('shift_needs',      '{"אחמ\"ש": 21, "מאבטח": 47, "שומר": 21}'::jsonb)
on conflict (key) do nothing;

-- ---------- אבטחה: רק משתמשים מחוברים יכולים לקרוא ולכתוב ----------
alter table public.employees enable row level security;
alter table public.absences  enable row level security;
alter table public.settings  enable row level security;

drop policy if exists "signed-in full access" on public.employees;
drop policy if exists "signed-in full access" on public.absences;
drop policy if exists "signed-in full access" on public.settings;

create policy "signed-in full access" on public.employees
  for all to authenticated using (true) with check (true);
create policy "signed-in full access" on public.absences
  for all to authenticated using (true) with check (true);
create policy "signed-in full access" on public.settings
  for all to authenticated using (true) with check (true);

-- ---------- סנכרון חי בין מכשירים (Realtime) ----------
do $$
begin
  begin alter publication supabase_realtime add table public.employees; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.absences;  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.settings;  exception when duplicate_object then null; end;
end $$;

-- =====================================================================
--  רענוני ירי
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
