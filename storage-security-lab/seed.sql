-- choose fixed family ids to make testing deterministic
-- (or remove the id columns to auto-generate)
insert into public.families (id, owner_user_id)
values
  ('11111111-1111-1111-1111-111111111111', 'USER_A_UUID'),
  ('22222222-2222-2222-2222-222222222222', 'USER_B_UUID')
on conflict do nothing;
insert into public.family_members (family_id, user_id, role)
values
  ('11111111-1111-1111-1111-111111111111', 'USER_A_UUID', 'owner'),
  ('22222222-2222-2222-2222-222222222222', 'USER_B_UUID', 'owner')
on conflict do nothing;