
-- Shared reference schema used across multiple labs.
-- This file documents the core multi-tenant family model.
-- Individual labs may implement simplified or adapted versions.

create table if not exists public.profiles (
  id uuid primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.families (
  id uuid primary key,
  name text,
  owner_user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

-- Typical helper used in RLS policies
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

-- Example policy pattern:
-- USING (
--   exists (
--     select 1
--     from public.family_members fm
--     where fm.family_id = target_table.family_id
--       and fm.user_id = auth.uid()
--   )
-- );