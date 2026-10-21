# Backend environment variables

Names and purposes only — never commit secrets.

## Environments

Use **separate** Supabase projects for staging and production. Migration CI and local `SUPABASE_DB_URL` should target staging by default.

| Variable | Required | Purpose |
| -------- | -------- | ------- |
| `SUPABASE_URL` | from P1 | Supabase API URL |
| `SUPABASE_ANON_KEY` | from P1 | Anon/publishable key (RLS) |
| `SUPABASE_SERVICE_ROLE_KEY` | from P1 | Service role — server/Edge only |
| `SUPABASE_DB_URL` | migrations | Direct DB URL for migrations/admin |
| `SUPABASE_JWT_SECRET` | advanced/local | JWT secret for local/advanced auth |
| `PAYMENT_PROVIDER` | default `unselected` | Stay unselected for handover (no MoMo) |
| `PAYMENT_WEBHOOK_SECRET` | if sandbox | HMAC for sandbox webhooks only |

Admin Auth users are created in the Supabase dashboard; privilege via `admin_profiles` (see `SECURITY.md`). No public admin registration env flags.

Validation helper: `src/validation/env.ts`.

Frontend app secrets and public contact vars live in `frontend/documentation/ENVIRONMENT.md`.
