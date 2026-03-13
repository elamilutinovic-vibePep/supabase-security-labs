# Storage Security Lab

This lab demonstrates secure and insecure patterns when using Supabase Storage in a multi-tenant application.

The example model uses a **family-based tenant structure** where users belong to families and each family has its own storage namespace.

---

## Goals

This lab demonstrates:

- how to design safe Storage policies
- how to organize object paths for multi-tenant isolation
- how membership tables are used to enforce file access
- how signed URL generation can accidentally bypass security

---

## Model

The storage bucket is **private** and object paths follow this pattern:

```text
<family_id>/<filename>
```
Example:

```text
ce5693c5-71c8-4d49-b5bf-44bd1d53c99d/photo1.jpg
```


Access to files is controlled through:

- `family_members`
- `auth.uid()`
- storage policies

---

## Scenarios

### Scenario 1 – Bucket membership isolation

Documented in:

```text
docs/scenario_1_bucket_membership.md
```


Demonstrates the correct approach:

- private bucket
- path-based tenant boundary
- membership validation

Expected result:

Users can access only files belonging to their own family.

---

### Scenario 2 – Signed URL leak

Documented in:

```text
docs/scenario_2_signed_url_leak.md
```


Demonstrates a common mistake:

An Edge Function generates signed URLs using `service_role` without validating ownership.

Result:

A user can receive a valid signed URL for another tenant's file.

---

## Key Idea

Supabase Storage security relies on three layers:

1. Private buckets
2. Storage policies
3. Correct Edge Function design

If any of these layers is misconfigured, cross-tenant data leaks can occur.