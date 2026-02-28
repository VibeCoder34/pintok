-- Add avatar_key to profiles for Bitmoji selection.
-- Allowed values: gencerkek, genckadin, yaslierkek, yaslikadin
alter table public.profiles
add column if not exists avatar_key text;

comment on column public.profiles.avatar_key is 'Bitmoji key: gencerkek, genckadin, yaslierkek, or yaslikadin';
