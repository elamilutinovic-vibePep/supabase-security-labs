# Supabase RLS & Edge Security Review

Focused security review for Supabase applications using Row Level Security, Edge Functions and Storage.

This document outlines a practical review approach for identifying security issues in Supabase-based systems, especially multi-tenant applications.

The methodology is based on the same patterns demonstrated in the Security Labs contained in this repository.

---

# Why Supabase Security Reviews Matter

Supabase provides powerful security mechanisms, but many real-world applications still contain subtle authorization issues.

Common examples include:

- RLS policies that accidentally expose cross-tenant data
- policies comparing incorrect identity fields
- Edge Functions that bypass RLS through `service_role`
- missing JWT propagation to backend services
- Storage buckets relying on insecure path assumptions
- temporary debug policies left active

These issues often remain unnoticed during development because the application appears to function normally.

A structured review helps reveal these hidden risks.

---

# Typical Problems Found in Supabase Projects

## 1. RLS Policy Design Issues

Common mistakes include:

- missing SELECT policies
- incorrect identity comparisons
- policies that only partially enforce tenant isolation
- debug policies accidentally left enabled

These problems may cause either:

- empty result sets
- inconsistent access behavior
- cross-tenant data exposure

---

## 2. Incorrect Identity Usage

Developers sometimes compare the wrong identity values.

Examples:

Comparing:

```sql
profiles.id = auth.uid()
```

when the actual relation is:

```sql
profiles.user_id = auth.uid()
```

Small identity mismatches can silently break authorization logic.

---

## 3. Edge Function Authorization Context

A frequent security mistake is creating Supabase clients in Edge Functions using:

```text
service_role
```


This bypasses RLS entirely.

Example scenario:

Edge Function receives a request from an authenticated user but performs database queries using a service-role client.

Result:

- queries execute with full database access
- RLS protections are skipped
- cross-tenant data may be returned

The correct pattern is:

- create client using anon key
- forward the user JWT
- allow PostgreSQL and RLS to enforce access control

---

## 4. Storage Security Assumptions

Supabase Storage requires both:

- correct bucket configuration
- correct policy logic

Typical issues include:

- assuming path structure alone enforces isolation
- missing membership checks
- signed URL flows implemented without authorization validation

Even private buckets can expose data if server-side logic leaks signed URLs.

---

# What a Security Review Includes

A typical review examines several layers of the Supabase architecture.

---

## 1. Authentication and Identity Flow

Verify that user identity is correctly propagated across:

- client applications
- API calls
- Edge Functions
- database queries

Review areas include:

- JWT handling
- auth context propagation
- role usage

---

## 2. RLS Policy Review

Analyze Row Level Security configuration:

- tenant isolation logic
- membership verification
- policy completeness
- potential policy conflicts

The review focuses on whether policies enforce the intended access model.

---

## 3. Edge Function Security

Evaluate server-side logic implemented through Edge Functions.

Key checks include:

- use of `service_role`
- correct user JWT forwarding
- data access patterns
- authorization checks before issuing signed URLs

---

## 4. Storage Access Patterns

Review bucket configuration and storage policies:

- private vs public buckets
- tenant-scoped path structure
- membership-based access rules
- signed URL generation logic

---

## 5. Debugging and Verification

Security reviews should include verification steps, not only configuration inspection.

Example verification tasks:

- testing cross-tenant access
- validating policy behavior
- confirming that Edge Functions preserve identity context
- verifying storage isolation

---

# Example Review Outcomes

A Supabase security review typically produces findings such as:

- incorrect RLS identity comparisons
- policies missing tenant filters
- Edge Functions bypassing authorization
- storage policies not aligned with application model
- signed URL flows lacking membership checks

Each finding should include:

- explanation of the risk
- example scenario
- recommended remediation

---

# When a Security Review Is Useful

This type of review is particularly valuable for:

- SaaS applications with multi-tenant data models
- projects migrating from traditional backends to Supabase
- teams introducing RLS for the first time
- applications using Edge Functions extensively
- systems storing user-generated files in Supabase Storage

---

# Related Security Labs

The Security Labs in this repository demonstrate practical examples of the issues described here.

Included labs cover:

- RLS policy mistakes
- service_role authorization bypass
- storage policy design
- signed URL leak scenarios

These labs are intentionally small and reproducible to help developers understand how security issues appear in real systems.

---

# Summary

Supabase provides strong security primitives, but secure behavior depends on correct architecture and policy design.

A structured security review helps ensure that:

- tenant isolation is properly enforced
- Edge Functions respect user authorization
- storage access is correctly restricted
- RLS policies behave as intended

Careful verification and testing are essential to avoid subtle authorization flaws in production systems.