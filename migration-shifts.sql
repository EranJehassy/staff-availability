-- הוספת "משמרות בשבוע" לעובדים.
-- להריץ פעם אחת ב: Supabase → SQL Editor → New query → Run
-- (לפני שמעלים את index.html החדש ל-GitHub)
alter table public.employees
  add column if not exists max_shifts integer not null default 0 check (max_shifts between 0 and 21);

-- משמרות נדרשות בשבוע לכל תפקיד (אפשר לשנות אחר כך בלשונית ההגדרות)
insert into public.settings (key, value)
values ('shift_needs', '{"אחמ\"ש": 21, "מאבטח": 47, "שומר": 21}'::jsonb)
on conflict (key) do nothing;
