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
       ('minimums_weekend', '{"אחמ\"ש": 3, "מאבטח": 6, "שומר": 3}'::jsonb)
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
