-- Create profiles table in public schema
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique,
  full_name text,
  avatar_url text,
  bio text,
  website text,
  updated_at timestamptz not null default timezone('utc'::text, now())
);

-- Ensure RLS is enabled
alter table public.profiles enable row level security;

-- Everyone can read profiles
drop policy if exists "Public read access to profiles" on public.profiles;

create policy "Public read access to profiles"
on public.profiles
for select
using (true);

-- Only the owner can update their profile
drop policy if exists "Users can update own profile" on public.profiles;

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Optional: only owners can insert (usually done by the trigger below)
drop policy if exists "Users can insert own profile" on public.profiles;

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = id);

-- Function to insert into public.profiles when a user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_full_name text;
begin
  -- Pull values from user_metadata
  v_username := coalesce(new.raw_user_meta_data->>'username', '');
  v_full_name := coalesce(new.raw_user_meta_data->>'full_name', '');

  insert into public.profiles (id, username, full_name)
  values (
    new.id,
    nullif(v_username, ''),
    nullif(v_full_name, '')
  );

  return new;
end;
$$;

-- Trigger on auth.users to call the function
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();