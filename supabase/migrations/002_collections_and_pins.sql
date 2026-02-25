-- Collections table: user-owned groups of pins
create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.collections enable row level security;

-- RLS: users can view only their own collections
drop policy if exists "Users can select own collections" on public.collections;

create policy "Users can select own collections"
on public.collections
for select
using (auth.uid() = user_id);

-- RLS: users can insert only collections for themselves
drop policy if exists "Users can insert own collections" on public.collections;

create policy "Users can insert own collections"
on public.collections
for insert
with check (auth.uid() = user_id);

-- RLS: users can update only their own collections
drop policy if exists "Users can update own collections" on public.collections;

create policy "Users can update own collections"
on public.collections
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- RLS: users can delete only their own collections
drop policy if exists "Users can delete own collections" on public.collections;

create policy "Users can delete own collections"
on public.collections
for delete
using (auth.uid() = user_id);


-- Pins table: individual travel pins
create table if not exists public.pins (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references public.collections (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text,
  image_url text,
  latitude double precision not null,
  longitude double precision not null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.pins enable row level security;

-- RLS: users can view only their own pins
drop policy if exists "Users can select own pins" on public.pins;

create policy "Users can select own pins"
on public.pins
for select
using (auth.uid() = user_id);

-- RLS: users can insert only pins for themselves
drop policy if exists "Users can insert own pins" on public.pins;

create policy "Users can insert own pins"
on public.pins
for insert
with check (auth.uid() = user_id);

-- RLS: users can update only their own pins
drop policy if exists "Users can update own pins" on public.pins;

create policy "Users can update own pins"
on public.pins
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- RLS: users can delete only their own pins
drop policy if exists "Users can delete own pins" on public.pins;

create policy "Users can delete own pins"
on public.pins
for delete
using (auth.uid() = user_id);

