-- Broken Supabase Lab: intentionally broken RLS + storage setup

-- Enable RLS
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.posts enable row level security;

-- BUG #1: missing SELECT policies (so data appears empty)
-- We'll add only INSERT on posts, but with a subtle ownership mismatch.

drop policy if exists "posts_insert_mismatch" on public.posts;
create policy "posts_insert_mismatch"
on public.posts
for insert
to authenticated
with check (
  -- BUG #2: compares owner_profile_id to auth.uid() (wrong type of id!)
  owner_profile_id = auth.uid()
);

-- BUG #3: allow anyone to read posts (data leak) via a too-broad policy
-- (This simulates "someone added a temporary policy and forgot to remove it")
drop policy if exists "posts_select_leaky" on public.posts;
create policy "posts_select_leaky"
on public.posts
for select
to authenticated
using (true);

-- Families/members: also too open (common early MVP mistake)
drop policy if exists "families_select_all" on public.families;
create policy "families_select_all"
on public.families
for select
to authenticated
using (true);

drop policy if exists "family_members_select_all" on public.family_members;
create policy "family_members_select_all"
on public.family_members
for select
to authenticated
using (true);

-- STORAGE (broken)
-- Create bucket and set it PUBLIC (leak)
insert into storage.buckets (id, name, public)
values ('family-media', 'family-media', true)
on conflict (id) do update set public = excluded.public;

-- Note: No storage.objects RLS policies here -> with public bucket, files are exposed.