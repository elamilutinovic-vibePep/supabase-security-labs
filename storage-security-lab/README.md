# Storage Security Lab

This lab examines secure and insecure Supabase Storage patterns in a multi-tenant application.

The example uses families as tenant boundaries. Each family has its own Storage namespace, and membership determines access.

## Security goal

A user must be able to list, upload, download, or delete objects only inside a family to which that user belongs.

The private bucket uses tenant-scoped object paths:

```text
<family_id>/<filename>
```

Example:

```text
ce5693c5-71c8-4d49-b5bf-44bd1d53c99d/photo1.jpg
```

Authorization depends on:

- the caller identity from `auth.uid()`;
- membership rows in `family_members`;
- Storage policies that validate the first path segment;
- trusted server-side handling of signed URLs.

## Scenario 1: Bucket membership isolation

Documented in:

```text
docs/scenario_1_bucket_membership.md
```

The protected design uses:

- a private bucket;
- a tenant identifier in the object path;
- membership checks for Storage operations;
- RLS on the membership tables used as the authorization source.

Expected result:

- User A can access objects under Family A.
- User A cannot access objects under Family B.
- User B can access objects under Family B.
- User B cannot access objects under Family A.

The initial Storage migration defines tenant-scoped object policies. The later hardening migration enables RLS on `families` and `family_members`, preventing clients from directly changing the authorization source.

## Scenario 2: Signed URL leak

Documented in:

```text
docs/scenario_2_signed_url_leak.md
```

A server-side function that uses `service_role` can generate a signed URL for any object. If it accepts a path without validating the caller's tenant membership, a user may receive a valid URL for another tenant's file.

This scenario is documentation-only in the current repository. It explains the authorization gap but does not include a deployable vulnerable Edge Function.

## Included material

- `supabase/migrations/20260308013100_add_family_storage_rls.sql` defines the tenant model and Storage policies.
- `supabase/migrations/20260904090000__protect_membership_source.sql` protects the membership tables on which authorization depends.
- `scripts/login.sh` obtains a user access token.
- `scripts/test-storage-family.sh` exercises same-tenant and cross-tenant requests.
- `seed.sql` provides deterministic family IDs with test-user placeholders.

## Lab status

Replace the UUID placeholders in `seed.sql` with disposable test-user IDs before applying it.

The repository includes policy migrations and a two-user request script, but it is not a one-command environment setup. The scripts print HTTP responses for inspection; they do not currently provide automated pass/fail assertions.

Use only a disposable local or test project.

## Key lesson

A private bucket alone does not enforce tenant isolation.

Storage security depends on all of the following remaining correct:

1. object-path design;
2. Storage policies;
3. protection of the membership data used by those policies;
4. authorization checks before privileged signed-URL generation.