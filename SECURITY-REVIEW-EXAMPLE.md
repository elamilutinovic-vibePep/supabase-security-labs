# Supabase Security Review – Example Findings

This document illustrates what a typical Supabase security review finding may look like.

The example is simplified but reflects real issues frequently discovered in Supabase applications using:

- Row Level Security (RLS)
- Edge Functions
- Supabase Storage
- multi-tenant data models

The goal is to demonstrate how security issues are identified, explained and remediated.

---

# Finding 1 — Edge Function Bypasses RLS

## Severity

High

## Category

Authorization / Multi-tenant isolation

---

## Description

An Edge Function responsible for returning tenant-specific data creates a Supabase client using the `service_role` key.

Example pattern:

```sql
createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
```


Because `service_role` bypasses Row Level Security, all database queries executed by this client ignore RLS policies.

If the function performs queries without explicitly filtering tenant data, records belonging to other tenants may be returned.

---

## Impact

Potential cross-tenant data exposure.

An attacker or normal user could receive data belonging to other tenants if:

- the Edge Function does not enforce strict tenant filtering
- queries rely on RLS to enforce isolation

This breaks the core security guarantee expected in multi-tenant systems.

---

## Example Scenario

1. User A belongs to tenant **Family A**  
2. User B belongs to tenant **Family B**

User A calls an Edge Function designed to return posts belonging to their family.

Because the function queries the database using `service_role`, the query executes with full privileges.

If the SQL query does not filter by tenant, results may include posts belonging to **Family B**.

---

## Root Cause

The Edge Function bypasses RLS by using a `service_role` client instead of preserving the user authorization context.

RLS policies are therefore not evaluated using the requesting user's identity.

---

## Recommended Fix

Create the Supabase client using the anon key and forward the user's JWT.

Example pattern:

```sql
createClient(
SUPABASE_URL,
ANON_KEY,
{
global: {
headers: {
Authorization: req.headers.get("Authorization")
}
}
}
)
```


This ensures that PostgreSQL evaluates RLS policies using the correct user identity.

---

# Finding 2 — Incomplete RLS Policy

## Severity

Medium

## Category

Authorization / Policy design

---

## Description

An RLS policy restricts access to rows using a direct comparison between the row owner and `auth.uid()`.

Example policy:

```sql
USING (posts.user_id = auth.uid())
```


However, the application uses a multi-tenant model where users access data through membership relationships.

Rows belong to tenants rather than directly to individual users.

---

## Impact

The policy may fail to enforce correct tenant boundaries.

Possible consequences include:

- legitimate users unable to access shared tenant data
- incorrect authorization logic
- reliance on application-layer filtering

---

## Root Cause

The policy compares the wrong identity relationship.

Tenant membership is stored in a separate table.

---

## Recommended Fix

Policies should validate tenant membership through a join with the membership table.

Example pattern:

```sql
USING (
EXISTS (
SELECT 1
FROM family_members fm
WHERE fm.family_id = posts.family_id
AND fm.user_id = auth.uid()
)
)
```


This ensures that users can only access rows belonging to tenants they are part of.

---

# Finding 3 — Signed URL Authorization Gap

## Severity

Medium

## Category

Storage access control

---

## Description

An Edge Function generates signed URLs for objects stored in a private Supabase Storage bucket.

The function accepts a file path and generates a signed URL without verifying whether the requesting user is authorized to access that file.

Example object path:

```text
<family_id>/photo.jpg
```


---

## Impact

Users may obtain signed URLs for files belonging to other tenants if they know or guess the object path.

This bypasses the intended access restrictions of the storage system.

---

## Root Cause

The Edge Function assumes that path structure alone enforces tenant isolation.

However, the function does not validate tenant membership before generating the signed URL.

---

## Recommended Fix

Before generating a signed URL, verify that the user belongs to the tenant associated with the object.

Example verification pattern:

```sql
EXISTS (
SELECT 1
FROM family_members
WHERE family_members.family_id = <family_id>
AND family_members.user_id = auth.uid()
)
```


Signed URLs should only be generated after successful authorization checks.

---

# Summary

These examples demonstrate how small implementation mistakes can introduce security risks in Supabase-based applications.

Common root causes include:

- bypassing RLS through `service_role`
- incomplete RLS policy design
- missing authorization checks in Edge Functions

A structured security review helps identify these issues before they reach production.