# Backend environment variables

Names and purposes only — never commit secrets.

| Variable                    | Purpose                                      |
| --------------------------- | -------------------------------------------- |
| `SUPABASE_URL`              | Supabase API URL                             |
| `SUPABASE_ANON_KEY`         | Anon/publishable key (RLS)                   |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role — server/Edge only              |
| `SUPABASE_DB_URL`           | Direct DB URL for migrations/admin           |
| `SUPABASE_JWT_SECRET`       | JWT secret for local/advanced auth scenarios |
| `PAYMENT_PROVIDER`          | `unselected` (default) or `sandbox` (tests)  |
| `PAYMENT_WEBHOOK_SECRET`    | HMAC secret for sandbox/live webhooks        |

Admin Auth users are created in the Supabase dashboard; privilege is granted via `admin_profiles` rows (see `SECURITY.md`). Do not add public admin registration env flags.

Validation helper: `src/validation/env.ts`.
