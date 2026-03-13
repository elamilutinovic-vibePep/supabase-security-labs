
# Service Role Bypass

This lab demonstrates one of the most common Supabase security mistakes:

using `service_role` inside a user-facing Edge Function.

## Problem

The database is protected by RLS, but the Edge Function creates a privileged Supabase client:

```ts
createClient(url, serviceRoleKey)
```

Because service_role bypasses RLS, the function can return rows outside the caller's tenant boundary.

## Result

A valid authenticated user can call the endpoint and receive rows belonging to another family.

## Correct Fix

Use:

+ anon key

+ forwarded user JWT in the Authorization header

This preserves the auth context and allows PostgreSQL to enforce RLS normally.

## Diagram

See:

+ ../diagrams/service-role-bypass.md

+ ../diagrams/service-role-bypass.svg

## Key Point

`service_role` is acceptable only for trusted server-side tasks that are not user-facing.

For user-facing queries, it is a data leak waiting to happen unless ownership is enforced manually.