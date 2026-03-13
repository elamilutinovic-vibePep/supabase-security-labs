# Supabase Security Labs – Session Context

This document summarizes the work completed during the development of the **Supabase Security Labs** repository.

It provides context for continuing development or discussion in a new session.

---

# Project Goal

The repository is a collection of **small, reproducible security labs** demonstrating common Supabase security patterns, mistakes and debugging workflows.

The labs focus on:

- Row Level Security (RLS)
- multi-tenant isolation
- Supabase Storage policies
- Edge Function security
- service_role misuse
- real-world debugging scenarios

The project is intended for:

- personal learning
- internal reference
- potential client demonstration
- portfolio use

---

# Repository Structure

```text
SUPABASE-SECURITY-LABS
│
├ docs
│ ├ multi-tenant-isolation.md
│ ├ request-pipeline.md
│ ├ security-layers.md
│ └ rls-evaluation-order.md
│
├ schema
│ ├ family-core.sql
│ └ README.md
│
├ rls-broken-lab
│ ├ diagrams
│ │ └ rls-leak-flow.md
│ ├ docs
│ │ ├ README.md
│ │ └ security-overview.md
│ ├ scripts
│ ├ supabase
│ │ ├ migrations
│ │ └ functions
│ └ tmp
│
├ edge-service-role-lab
│ ├ diagrams
│ │ ├ service-role-bypass.md
│ │ ├ service-role-bypass.mmd
│ │ ├ service-role-bypass.svg
│ │ └ service-role-bypass.png
│ ├ docs
│ │ └ service-role-bypass.md
│ ├ scripts
│ │ ├ lab-login.sh
│ │ └ test-leak.sh
│ └ supabase
│ ├ migrations
│ └ functions
│
└ storage-security-lab
├ docs
│ ├ scenario_1_bucket_membership.md
│ └ scenario_2_signed_url_leak.md
├ scripts
├ supabase
│ └ migrations
└ README.md
```

---

# Core Data Model

The labs share a simplified **family-based multi-tenant model**.

Entities:

```text
users
profiles
families
family_members
posts
family_photos
```

Basic relationship:

```text
user
↓
family_members
↓
family
↓
posts / storage objects
```

Tenant isolation is enforced through:

- RLS policies
- membership tables
- `auth.uid()`

---

# Lab 1 – RLS Broken Lab

### Purpose:

Demonstrate common RLS mistakes.

### Topics covered:

- missing SELECT policies
- incorrect identity comparison (`profile_id` vs `auth.uid()`)
- temporary debug policies left enabled
- cross-tenant data leaks
- policy fixes

### Key idea:

Small RLS mistakes lead to either:

- empty result sets
- cross-tenant data exposure

---

# Lab 2 – Edge Service Role Lab

### Purpose:

Demonstrate how **service_role bypasses RLS**.

### Scenario:

An Edge Function creates a Supabase client using:

```text
service_role
```

### Result:

Database queries ignore RLS and return rows belonging to other tenants.

### Fix:

Use:

```text
anon key + forwarded user JWT
```

This preserves the auth context and allows PostgreSQL to enforce RLS.

---

# Lab 3 – Storage Security Lab

### Purpose:

Demonstrate correct file access patterns in Supabase Storage.

### Bucket configuration:

- private bucket
- tenant isolation through path structure

### Example path:

```text
<family_id>/photo.jpg
```

### Security is enforced through:

- storage policies
- membership checks
- `auth.uid()`

### Two scenarios documented:

1. Correct membership-based storage access
2. Signed URL leak through insecure Edge Function

---

# Architecture Documentation

The repository includes several architecture diagrams.

### Multi-Tenant Isolation

Explains how Supabase enforces tenant boundaries through:

- JWT identity
- RLS
- membership tables

---

### Request Pipeline

Illustrates the Supabase request flow:

```text
Client
→ Auth
→ JWT
→ PostgREST / Edge
→ PostgreSQL
→ RLS
```

---

### Security Layers

Shows layered protection:

1. Auth
2. JWT identity
3. API layer
4. RLS
5. Storage policies

---

### RLS Evaluation Order

Documents how PostgreSQL evaluates access:

1. identify table
2. check RLS enabled
3. collect policies
4. evaluate USING
5. evaluate WITH CHECK

---

# Scripts

Labs include small scripts used to reproduce scenarios:

Examples:

```text
seed users
login users
call vulnerable endpoint
verify data leak
verify fix
```

Scripts allow the labs to be reproduced quickly.

---

# Key Security Lessons

1. **RLS is the primary tenant isolation mechanism**
2. **service_role bypasses RLS completely**
3. **Edge Functions must forward the user JWT**
4. **Storage security requires both policies and correct path design**
5. **Debug policies are a common source of production leaks**

---

# Future Ideas

Possible future additions:

- RLS debugging checklist
- Supabase security audit checklist
- real-world freelance incident simulations
- rate limiting examples
- input validation examples
- API abuse scenarios

---

# Development Notes

The project was developed locally using:

- Supabase CLI
- Docker
- Edge Functions
- PostgreSQL migrations
- shell test scripts
- Mermaid diagrams

The repository is intended to remain **lightweight and educational**, not a full production application.

---

# Author Notes

This project was built as part of a structured self-learning process focused on:

- Supabase security
- multi-tenant system design
- backend debugging workflows
- practical security lab development

The repository may later be used as:

- a learning reference
- a debugging playbook
- a portfolio example
- a demonstration environment for clients