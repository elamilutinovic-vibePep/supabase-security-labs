# RLS Broken Lab – Security Overview

## 1. Broken Schema

```mermaid
flowchart TD

A1[Broken Supabase schema] --> B1[Intentionally broken RLS and storage setup]

B1 --> C1[Missing SELECT policies]
C1 --> D1[Data appears empty]

B1 --> C2[owner_profile_id compared to auth.uid]
C2 --> D2[Wrong identity type]

B1 --> C3[Temporary debug policy left enabled]
C3 --> D3[Any authenticated user can read posts]

B1 --> C4[Bucket created as PUBLIC]
C4 --> D4[Storage data leak]

```

## 2. Fixed Schema

```mermaid
flowchart TD;

A2[Fixed Supabase schema] --> B2[Correct RLS and storage configuration]

B2 --> C5[Policy families_select_owner]
C5 --> D5[Only owner can see family]

B2 --> C6[Policy family_members_select_own_families]
C6 --> D6[User sees only memberships they belong to]

B2 --> C7[Temporary debug policy removed]
C7 --> D7[Only family members can read posts]

B2 --> C8[Policy posts_insert_family]
C8 --> D8[Insert allowed if user belongs to family]

B2 --> C9[Policy posts_update_owner]
C9 --> D9[Update allowed only for owner]

B2 --> C10[Bucket set to PRIVATE]
C10 --> D10[Storage protected]

```

## 3. Edge Function Security

```mermaid
flowchart TD;

U[User A] --> E[Edge Function]

E --> K{Which key is used?}

K -->|service_role| DB1[Supabase DB]
DB1 --> R1[RLS bypassed]
R1 --> L1[All family posts returned]
L1 --> LEAK[Data leak]

K -->|anon + user JWT| DB2[Supabase DB]
DB2 --> R2[RLS applied]
R2 --> SAFE[Only user's family rows]

```

## Key Point

service_role bypasses RLS completely.

If an Edge Function uses service_role for user-facing queries, the database can return rows outside the user's tenant boundary unless ownership is manually enforced.

Using anon plus forwarded user JWT keeps RLS active.