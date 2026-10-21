# Backup & restore drill

Supabase owns automated backups / PITR on paid plans. This doc is the operator drill — execute **once on staging** before production sign-off, then keep the evidence row.

## Prerequisites

- Staging Supabase project (never drill against production first)
- Dashboard access (Owner/Admin) or CLI linked to staging
- Note current migration head (`supabase migration list`)

## Backup posture (confirm)

1. Supabase Dashboard → Project Settings → Database → Backups  
2. Confirm daily backups (or PITR) match the paid plan  
3. Record retention window in the evidence table below  

## Restore drill (staging)

Pick **one** of:

### A — Point-in-time / backup restore (Dashboard)

1. Create a **temporary** restore target (new project or documented restore slot per Supabase UI)  
2. Restore a recent backup / PITR timestamp from staging  
3. Verify: `products` count, one known order (if any), `admin_profiles` rows, storage buckets present  
4. Run `npm run db:rls-smoke` against the restored project (or paste `rls_smoke_checks.sql`)  
5. Tear down the temporary project if created solely for the drill  

### B — Logical dump round-trip (CLI)

```bash
# From backend/, linked to staging
supabase db dump -f /tmp/ip-shap-staging-drill.sql
# Restore into a throwaway local or temporary remote DB, then:
# supabase db reset / psql apply — only on non-production
```

Verify catalogue seed product + RLS denials still hold.

## Evidence (fill once)

| Field | Value |
| ----- | ----- |
| Date | |
| Operator | |
| Staging project ref | |
| Method (A/B) | |
| Backup timestamp / dump name | |
| Verification notes | |
| Duration | |
| Issues / follow-ups | |

## Production rule

Do not run destructive restore drills against the live production project. Production restore is incident-only, with client Owner approval and a written rollback plan.

See also: `OPERATIONS.md` (Backups), frontend `HARDENING.md`.
