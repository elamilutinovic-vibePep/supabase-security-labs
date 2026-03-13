# Service Role Bypass Diagram

```mermaid
flowchart TD

    A[User A] --> B[Edge Function]
    B --> C{Which key is used?}

    C -->|service_role| D[Supabase DB]
    D --> E[RLS is bypassed]
    E --> F[All family_photos rows returned]
    F --> G[Data leak]

    C -->|anon + user JWT| H[Supabase DB]
    H --> I[RLS is applied]
    I --> J[Only rows for user's family]
    J --> K[Correct behavior]

```

## Key point

`service_role` bypasses RLS completely.

If an Edge Function uses `service_role` for user-facing queries,
the database will return rows outside the user's tenant boundary
unless ownership is manually enforced.

Using `anon` + forwarded user JWT keeps RLS active.