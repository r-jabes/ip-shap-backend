# Backend environment variables

Names and purposes only — never commit secrets.

| Variable                    | Purpose                                      |
| --------------------------- | -------------------------------------------- |
| `SUPABASE_URL`              | Supabase API URL                             |
| `SUPABASE_ANON_KEY`         | Anon/publishable key (RLS)                   |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role — server/Edge only              |
| `SUPABASE_DB_URL`           | Direct DB URL for migrations/admin           |
| `SUPABASE_JWT_SECRET`       | JWT secret for local/advanced auth scenarios |
| `PAYMENT_PROVIDER`          | Reserved; unset until provider verified      |
| `PAYMENT_WEBHOOK_SECRET`    | Reserved webhook verification secret         |

Validation helper: `src/validation/env.ts`.
