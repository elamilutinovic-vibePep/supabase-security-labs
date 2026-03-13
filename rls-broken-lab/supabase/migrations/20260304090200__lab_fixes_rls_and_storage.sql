-- Broken Supabase Lab: fixes for RLS + storage

-- FIX: lock down families / members / posts with real ownership checks

-- Families: only owner can see their family
drop policy if exists "families_select_all" on public.families;
create policy "families_select_owner"
on public.families
for select
to authenticated
using (owner_user_id = auth.uid());

-- Members: user can see memberships only for families they belong to
drop policy if exists "family_members_select_all" on public.family_members;
create policy "family_members_select_own_families"
on public.family_members
for select
to authenticated
using (public.user_in_family(family_id));

-- Posts: remove leaky select
drop policy if exists "posts_select_leaky" on public.posts;

-- Posts: only members of family can read
create policy "posts_select_family"
on public.posts
for select
to authenticated
using (public.user_in_family(family_id));

-- Posts: insert allowed if:
-- 1) current user is member of family
-- 2) owner_profile_id matches current user's profile id
drop policy if exists "posts_insert_mismatch" on public.posts;
create policy "posts_insert_family"
on public.posts
for insert
to authenticated
with check (
  public.user_in_family(family_id)
  and owner_profile_id = public.current_profile_id()
);

-- Posts: update allowed only if same owner_profile_id and in family
drop policy if exists "posts_update_owner" on public.posts;
create policy "posts_update_owner"
on public.posts
for update
to authenticated
using (
  public.user_in_family(family_id)
  and owner_profile_id = public.current_profile_id()
)
with check (
  public.user_in_family(family_id)
  and owner_profile_id = public.current_profile_id()
);

-- STORAGE FIXES
-- Make bucket private
update storage.buckets set public = false where id = 'family-media';

-- Lock down storage.objects:
-- user can read/write only objects where metadata->>'user_id' = auth.uid()
-- (simple, common pattern; could also tie to family_id)
--alter table storage.objects enable row level security;

drop policy if exists "storage_read_own" on storage.objects;
create policy "storage_read_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'family-media'
  and (metadata->>'user_id')::uuid = auth.uid()
);

drop policy if exists "storage_write_own" on storage.objects;
create policy "storage_write_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'family-media'
  and (metadata->>'user_id')::uuid = auth.uid()
);

drop policy if exists "storage_update_own" on storage.objects;
create policy "storage_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'family-media'
  and (metadata->>'user_id')::uuid = auth.uid()
)
with check (
  bucket_id = 'family-media'
  and (metadata->>'user_id')::uuid = auth.uid()
);