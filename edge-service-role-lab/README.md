# Edge Service Role Lab

This lab demonstrates one of the most common Supabase security mistakes:

using the `service_role` key inside a user-facing Edge Function.

---

## Problem

Supabase Row Level Security protects database tables by filtering rows using `auth.uid()`.

However, the `service_role` key **bypasses RLS completely**.

If an Edge Function uses `service_role` to fetch data and returns it to the caller, the database will not enforce tenant isolation.

---

## Lab Structure

edge-service-role-lab
├ docs
│ └ service-role-bypass.md
├ diagrams
│ └ service-role-bypass.*
├ scripts
│ ├ lab-login.sh
│ └ test-leak.sh
└ supabase
├ functions
│ ├ leaky_list_family_photos
│ └ secure_list_family_photos
└ migrations

---

## Vulnerable Endpoint

The vulnerable function creates a Supabase client using:

```text
service_role
```

Because this role bypasses RLS, the query can return rows from other tenants.

Result:

A user calling the endpoint may receive data belonging to another family.

---

## Secure Endpoint

The corrected version:

- uses the `anon` key
- forwards the user's JWT
- allows PostgreSQL to enforce RLS normally

This ensures only rows belonging to the user's tenant are returned.

---

## Test Scripts

Scripts demonstrate the vulnerability and the fix.

```text
scripts/lab-login.sh
scripts/test-leak.sh
```

The test workflow:

1. create two users in different families
2. call the vulnerable endpoint
3. observe cross-tenant data
4. call the secure endpoint
5. verify correct isolation

---

## Key Lesson

Never use `service_role` in user-facing Edge Functions unless ownership checks are implemented manually.

The safest pattern is:

```text
anon key + forwarded JWT
```

This keeps RLS enforcement active inside PostgreSQL.