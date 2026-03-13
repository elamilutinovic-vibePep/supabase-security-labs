# Supabase Security Audit Checklist

A practical checklist for reviewing the security of Supabase applications.

This checklist focuses on common failure patterns observed in real projects using:

- Row Level Security (RLS)
- Edge Functions
- Supabase Storage
- multi-tenant data models

The goal is to detect authorization flaws, tenant isolation failures and insecure server-side logic.

---

# 1. Authentication & Identity

Verify how user identity is propagated through the system.

Questions to check:

- Are requests authenticated using Supabase Auth?
- Is the correct user identity available in database queries?
- Is the user JWT forwarded to backend services?

Potential risks:

- anonymous access where authentication is expected
- backend services executing queries without user context

---

# 2. RLS Configuration

Check whether Row Level Security is correctly configured.

Review:

- is RLS enabled on all tenant-scoped tables?
- are policies defined for SELECT, INSERT, UPDATE and DELETE?
- do policies reference `auth.uid()` correctly?

Common mistakes:

- missing SELECT policies
- policies referencing the wrong identity column
- policies relying on application logic instead of database rules

---

# 3. Tenant Isolation

Verify that tenants cannot access each other's data.

Check:

- all queries enforce tenant filtering
- membership relationships are validated
- RLS policies reference membership tables

Typical secure pattern:

```sql
EXISTS (
SELECT 1
FROM family_members
WHERE family_members.family_id = posts.family_id
AND family_members.user_id = auth.uid()
)
```

Risk indicators:

- policies using only `user_id = auth.uid()` without tenant scope
- policies that do not reference membership tables

---

# 4. Edge Function Security

Review all Edge Functions interacting with the database.

Check:

- how Supabase clients are created
- whether the user JWT is forwarded
- whether `service_role` is used

Important rule:

Edge Functions should not query tenant data using `service_role`.

Risk scenario:

```ts
Edge Function
→ creates service_role client
→ performs SELECT queries
→ bypasses RLS
```


This can lead to cross-tenant data exposure.

Recommended pattern:

- create client using anon key
- forward Authorization header
- allow RLS to enforce access control

---

# 5. Storage Security

Review bucket configuration and policies.

Check:

- are buckets private when storing user data?
- are storage paths tenant-scoped?
- do storage policies validate membership?

Example path structure:

```text
<family_id>/photo.jpg
```


Storage policies should validate:

- the user belongs to the tenant
- the path corresponds to the correct tenant

Common mistakes:

- relying only on path structure
- missing membership checks
- generating signed URLs without authorization validation

---

# 6. service_role Usage

Review all places where `service_role` keys are used.

Check:

- server scripts
- Edge Functions
- background jobs

Important considerations:

`service_role` bypasses all RLS policies.

It should be used only when:

- performing trusted administrative operations
- executing migrations
- running backend jobs that require full access

Never expose `service_role` keys to client applications.

---

# 7. Debug Policies

Check whether temporary debugging policies exist.

Example:

```sql
USING (true)
  or
auth.role() = 'authenticated'
```


These shortcuts are sometimes used during development and accidentally left in production.

Risk:

- complete data exposure
- broken tenant isolation

---

# 8. Signed URL Flows

Review how signed URLs are generated.

Questions:

- who is allowed to generate signed URLs?
- does the server verify tenant membership before generating URLs?
- are signed URLs scoped to specific objects?

Common mistake:

Edge Function generates signed URL without validating the user's relationship to the file.

Result:

users may access files belonging to other tenants.

---

# 9. Verification Testing

Security reviews should include behavioral testing.

Examples:

- attempt cross-tenant queries
- verify RLS policy enforcement
- test Edge Functions using different users
- validate storage access restrictions

Configuration alone is not sufficient — real behavior must be verified.

---

# 10. Documentation & Observability

Check whether the system provides visibility into authorization behavior.

Helpful signals include:

- clear policy documentation
- reproducible debugging scripts
- consistent tenant identifiers
- logs for Edge Function access

Good observability greatly simplifies security debugging.

---

# Summary

Supabase provides strong primitives for building secure multi-tenant applications.

However, correct behavior depends on:

- proper RLS policy design
- correct identity propagation
- safe Edge Function patterns
- secure storage access models

This checklist can be used as a structured approach to reviewing and validating those aspects.