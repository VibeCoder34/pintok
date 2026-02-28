-- AI Fuel (Quota) system: track AI scans per user.
-- ai_scans_count: total scans performed; ai_scans_limit: max allowed (default 5 for Hitchhiker/Free).
alter table public.profiles
add column if not exists ai_scans_count int not null default 0;

alter table public.profiles
add column if not exists ai_scans_limit int not null default 5;

comment on column public.profiles.ai_scans_count is 'Total AI scans (link or photo) performed by the user';
comment on column public.profiles.ai_scans_limit is 'Maximum allowed AI scans for the current plan (default 5 for Free)';
