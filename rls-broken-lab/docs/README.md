# RLS Broken Lab

This lab demonstrates common Supabase RLS failure modes and how to fix them.

## Topics covered

- missing `SELECT` policies
- wrong identity comparisons (`profile_id` vs `auth.uid()`)
- temporary debug policies left enabled
- storage misconfiguration
- proper policy design for `SELECT`, `INSERT`, and `UPDATE`

## Files

- `security-overview.md` – overview of broken and fixed schema
- `../diagrams/rls-leak-flow.md` – simple flow of how leaks happen
- `../scripts/01_seed.sh` – seed users and test data
- `../scripts/02_repro_leak.sh` – reproduce the leak
- `../scripts/03_verify_fix.sh` – verify corrected behavior

## Goal

Understand how small policy mistakes lead either to:

- empty data
- or cross-tenant leaks