-- Families + memberships
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);
create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);
-- A "photo" row points to storage object path (not the file itself)
create table if not exists public.family_photos (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  object_path text not null, -- e.g. "<family_uuid>/a-hello.txt"
  caption text null,
  created_at timestamptz not null default now()
);
alter table public.family_members enable row level security;
alter table public.family_photos enable row level security;
-- Helper: does current user belong to family?
create or replace function public.user_in_family(p_family_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = auth.uid()
  );
$$;
-- RLS: membership rows (users can see only their own memberships)
drop policy if exists "family_members_select_own" on public.family_members;
create policy "family_members_select_own"
on public.family_members
for select
to authenticated
using (user_id = auth.uid());
-- RLS: photos visible only to members of that family
drop policy if exists "family_photos_select_family" on public.family_photos;
create policy "family_photos_select_family"
on public.family_photos
for select
to authenticated
using (public.user_in_family(family_id));