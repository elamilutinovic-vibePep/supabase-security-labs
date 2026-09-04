-- Protect the authorization source used by the Storage policies.
-- Without RLS on family membership, Storage isolation can be bypassed
-- by changing the rows that user_in_family() relies on.

alter table public.families enable row level security;
alter table public.family_members enable row level security;

drop policy if exists "families_select_member"
on public.families;

create policy "families_select_member"
on public.families
for select
to authenticated
using (
  owner_user_id = auth.uid()
  or exists (
    select 1
    from public.family_members fm
    where fm.family_id = families.id
      and fm.user_id = auth.uid()
  )
);

drop policy if exists "family_members_select_self"
on public.family_members;

create policy "family_members_select_self"
on public.family_members
for select
to authenticated
using (user_id = auth.uid());

-- No client-facing INSERT, UPDATE, or DELETE policies are created.
-- Membership changes therefore require a trusted administrative flow.