# RLS Leak Flow

```mermaid
flowchart TD

A[User request] --> B[Query hits posts table]

B --> C{RLS policy state}

C -->|Missing SELECT policy| D[No rows returned]
C -->|Wrong identity comparison| E[Rows filtered incorrectly]
C -->|Temporary broad policy enabled| F[Rows from other users become visible]

F --> G[Cross-tenant data leak]

E --> H[Confusing empty results]
D --> H

```

## Meaning

This lab demonstrates that RLS problems usually appear in one of two ways:

+ data is unexpectedly invisible

+ data is unexpectedly visible

Both are policy bugs.

The most dangerous case is a broad temporary policy left behind during debugging.