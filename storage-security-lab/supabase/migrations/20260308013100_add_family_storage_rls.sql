-- families + family_members (minimal)
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index if not exists families_owner_user_id_key on public.families(owner_user_id);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

-- Helper: user is member of family (IMPORTANT: uses auth.uid())
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

-- Storage RLS must be on (Supabase usually has it enabled, but explicit is ok)
alter table storage.objects enable row level security;

-- READ: allow authenticated users to read objects in their family's folder
drop policy if exists "family_photos_read" on storage.objects;
create policy "family_photos_read"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'family-photos'
  and public.user_in_family( (storage.foldername(name))[1]::uuid )
);

-- WRITE: allow uploads only into your family folder
drop policy if exists "family_photos_insert" on storage.objects;
create policy "family_photos_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'family-photos'
  and public.user_in_family( (storage.foldername(name))[1]::uuid )
);

-- OPTIONAL: allow delete only for members (often enough for early beta)
drop policy if exists "family_photos_delete" on storage.objects;
create policy "family_photos_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'family-photos'
  and public.user_in_family( (storage.foldername(name))[1]::uuid )
);