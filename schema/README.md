# Shared reference schema

`family-core.sql` documents the small multi-tenant model reused across the case studies:

- an Auth user maps to a public profile;
- a family is the tenant boundary;
- `family_members` connects users to tenants;
- tenant-owned tables reference `family_id`;
- RLS policies verify membership using `auth.uid()`.

This file is a reference model, not a complete migration. Each lab contains its own adapted schema, policies, and setup notes.