-- Pins: locations the user created (scanned with Gemini and added to map).
create table if not exists public.pins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_url text,
  name text not null,
  location_label text,
  city text,
  country text,
  lat double precision,
  lng double precision,
  created_at timestamptz default now()
);

-- Bookmarks: pins saved from Explore/Following feed.
create table if not exists public.bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  pin_id uuid not null references public.pins(id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, pin_id)
);

-- RLS (optional): enable when using Supabase Auth.
-- alter table public.pins enable row level security;
-- alter table public.bookmarks enable row level security;

-- My Pins: select * from pins where user_id = auth.uid()
-- Saved Pins: select p.*, u.raw_user_meta_data->>'username' as creator_username
--             from bookmarks b join pins p on b.pin_id = p.id
--             join auth.users u on p.user_id = u.id
--             where b.user_id = auth.uid()
