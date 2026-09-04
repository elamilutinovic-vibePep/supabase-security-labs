# RLS Broken Lab

This staged case study demonstrates two different RLS failure modes:

1. a policy compares a profile identifier with `auth.uid()`, so legitimate inserts fail;
2. a temporary `USING (true)` policy allows an authenticated user to read rows from another tenant.

The corrected policies use tenant membership for shared family data and the caller's profile identifier for row ownership.

## Threat model

- Family A and Family B are separate tenants.
- User A belongs only to Family A.
- User B belongs only to Family B.
- Each family contains a post owned by its own user.

User A must never receive Family B's post, and User B must never receive Family A's post.

## Investigation stages

| Stage | File | Expected behavior |
| --- | --- | --- |
| Schema | `supabase/migrations/20260304090000__lab_schema.sql` | Creates the simplified tenant model |
| Vulnerable | `supabase/migrations/20260304090100__lab_broken_rls_and_storage.sql` | Adds intentionally unsafe policies and a public bucket |
| Corrected | `supabase/migrations/20260304090200__lab_fixes_rls_and_storage.sql` | Removes broad policies and restores membership checks |

These files are evidence from three stages of one investigation. They are stored as ordered migrations so the change is easy to inspect. A normal migration run applies all three and therefore ends in the corrected state.

To observe the vulnerable midpoint, use only a disposable local or test project and stop after applying the first two SQL files. Seed the two test tenants with `scripts/01_seed.sh`, then inspect access with the user JWTs written under the lab's ignored `tmp/` directory. Apply the final SQL file before verifying the corrected behavior.

The current scripts are supporting investigation utilities, not a one-command test harness. They require a running Supabase environment and the Supabase CLI output consumed by `scripts/lib.sh`.

## Included evidence

- `docs/security-overview.md` compares the vulnerable and corrected policy designs.
- `diagrams/rls-leak-flow.md` traces the cross-tenant read path.
- `scripts/01_seed.sh` creates two users in two separate families.
- `scripts/02_repro_leak.sh` calls the intentionally unsafe Edge Function.
- `scripts/03_verify_fix.sh` calls the JWT-preserving Edge Function.

## Safety

The vulnerable policy and function are deliberately unsafe. Do not deploy them to a production Supabase project.