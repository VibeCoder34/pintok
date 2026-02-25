-- Ensure FKs use ON DELETE CASCADE (already set in 002; re-stating for clarity).
-- collections.user_id -> profiles(id) on delete cascade
-- pins.collection_id -> collections(id) on delete cascade
-- pins.user_id -> profiles(id) on delete cascade
-- Deleting a collection deletes its pins; deleting a user (profile) cascades to collections then pins.

-- PostgreSQL function: wipe current user's data (for "Delete Account" flow).
-- Callable by the authenticated user only; deletes their pins, then collections, then profile row.
create or replace function public.delete_user_data()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Pins (user_id FK to profiles; deleting pins first is redundant if we cascade from collections, but explicit is clear)
  delete from public.pins where user_id = v_uid;

  -- Collections (cascade would delete pins; we already deleted pins above)
  delete from public.collections where user_id = v_uid;

  -- Profile row (so the user can sign out and re-sign-up with same email if desired)
  delete from public.profiles where id = v_uid;

  -- Note: We do NOT delete auth.users here. That would require admin or a separate Supabase Auth API.
  -- The client should call deleteUserData() then signOut(). The auth user remains until deleted via Dashboard or Auth API.
end;
$$;

-- Allow authenticated users to call this (only affects their own data via v_uid = auth.uid()).
grant execute on function public.delete_user_data() to authenticated;
grant execute on function public.delete_user_data() to service_role;
