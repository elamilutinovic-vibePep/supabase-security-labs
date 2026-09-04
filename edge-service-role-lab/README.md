# Edge Service Role Lab

This lab demonstrates one of the most common Supabase security mistakes:

using the `service_role` key inside a user-facing Edge Function.

## Problem

Supabase Row Level Security protects database tables by filtering rows using `auth.uid()`.

However, the `service_role` key bypasses RLS completely.

If an Edge Function uses `service_role` to fetch data and returns it to the caller, the database will not enforce tenant isolation.

## Lab structure

```text
edge-service-role-lab
├── docs
│   └── service-role-bypass-diagram.md
├── diagrams
│   └── service-role-bypass.*
├── scripts
│   ├── lab-login.sh
│   └── test-leak.sh
└── supabase
    ├── functions
    │   ├── leaky_list_family_photos
    │   └── secure_list_family_photos
    └── migrations
```

## Vulnerable endpoint

The vulnerable function creates a Supabase client using:

```text
service_role
```

Because this role bypasses RLS, the query can return rows from other tenants.

A user calling the endpoint may therefore receive data belonging to another family.

## Secure endpoint

The corrected version:

- uses the `anon` key;
- forwards the user's JWT;
- allows PostgreSQL to enforce RLS in the caller's context.

This ensures that only rows allowed by the tenant policies are returned.

## Test material

The repository includes:

```text
scripts/lab-login.sh
scripts/test-leak.sh
```

The intended workflow is:

1. create two users in different families;
2. call the vulnerable endpoint;
3. observe cross-tenant data;
4. call the secure endpoint;
5. verify tenant isolation.

The repository currently provides the request script and both function implementations, but not a one-command environment setup. Create the two users and family rows before running the request script.

Use only a disposable local or test project.

## Key lesson

Never use `service_role` in a user-facing Edge Function unless authorization checks are implemented explicitly before privileged data access.

For requests that should remain subject to RLS, use:

```text
anon key + forwarded user JWT
```

This preserves the caller's database context and keeps PostgreSQL RLS enforcement active.