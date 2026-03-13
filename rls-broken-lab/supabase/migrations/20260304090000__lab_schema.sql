-- Broken Supabase Lab: schema (minimal but realistic)

create extension if not exists pgcrypto;

-- profiles: maps auth.users -> public identity
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

-- auto-create profile when a user signs up
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.email, 'user'));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();

-- families
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint families_owner_unique unique (owner_user_id)
);

-- family_members
create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

-- posts inside a family
-- IMPORTANT: owner_profile_id references profiles.id (not auth.users.id)
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  owner_profile_id uuid not null references public.profiles(id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now()
);

-- helper: is current user a member of given family?
create or replace function public.user_in_family(p_family_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = p_family_id
      and fm.user_id = auth.uid()
  );
$$;

-- helper: current user's profile_id (nullable)
create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.user_id = auth.uid()
  limit 1;
$$;