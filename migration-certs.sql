-- הוספת תוקף תעודות לעובדים (רישיון נשק ותעודת מאבטח).
-- להריץ פעם אחת ב: Supabase → SQL Editor → New query → Run
-- (לפני שמעלים את index.html החדש ל-GitHub)
alter table public.employees add column if not exists gun_license_exp date;
alter table public.employees add column if not exists guard_cert_exp  date;

-- כמה ימים לפני פקיעה מתחילה האזהרה (אפשר לשנות בלשונית ההגדרות)
insert into public.settings (key, value)
values ('cert_warn_days', '30'::jsonb)
on conflict (key) do nothing;
