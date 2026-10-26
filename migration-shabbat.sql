-- הוספת "שומר שבת" לעובדים קיימים.
-- להריץ פעם אחת ב: Supabase → SQL Editor → New query → Run
-- (לפני שמעלים את index.html החדש ל-GitHub)
alter table public.employees add column if not exists shabbat boolean not null default false;
