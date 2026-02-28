-- Add visibility flag to collections: true = private (only owner), false = public (visible on profile).
alter table public.collections
  add column if not exists is_private boolean not null default true;

comment on column public.collections.is_private is 'When true, only the owner sees this collection; when false, it is visible on profile.';
