# Backend environment variables

Names only — never commit secrets. The **hosted storefront** uses the frontend env vars (`frontend/documentation/ENVIRONMENT.md`). This file is for the `backend/` folder (CLI migrate/seed, local validation).

## What you need for staging migrations

After `npx supabase login` + `npx supabase link --project-ref <staging-ref>`, the CLI remembers the project. For day-to-day:

```bash
npm run db:push
npm run db:seed:p1
```

**Why `supabase login`?** The dashboard is a browser session. The CLI is a separate tool that must prove *you* may change that project (`link` / `db push`). One login per machine is normal — not a second “Supabase account”.

**You do not need a filled `.env.local` for migrations** if the project is linked.

Optional `.env.local` (API keys + admin seed) — same three API values as the frontend:

| Variable | Purpose | Where in dashboard |
| -------- | ------- | ------------------ |
| `SUPABASE_URL` | HTTPS **API** URL (`https://xxxx.supabase.co`) | Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Anon / publishable key (RLS) | Settings → API → `anon` `public` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role (bypasses RLS) — never expose to browser | Settings → API → `service_role` |
| `ADMIN_OWNER_N_EMAIL` / `_PASSWORD` / `_NAME` | Staging owners for `npm run db:seed:admins` | You choose (passwords never in Git) |

## `SUPABASE_URL` vs `SUPABASE_DB_URL`

| | `SUPABASE_URL` | `SUPABASE_DB_URL` |
| - | -------------- | ----------------- |
| Protocol | `https://…supabase.co` | `postgresql://…` (or `postgres://…`) |
| Talks to | PostgREST / Auth / Storage API | Postgres directly |
| Used for | App clients, some scripts | `psql`, dumps, tools that need raw SQL over the wire |
| Needed now? | Same as frontend (optional in backend `.env`) | **Optional** — not required for `supabase link` + `db:push` |

Get `SUPABASE_DB_URL` only if you need it: Settings → Database → **Connection string** (URI). Prefer the **Session pooler** or direct connection as Supabase documents for your plan. Often includes the DB password you set at project creation.

## JWT secret

| | |
| - | - |
| What | Signing secret for Supabase Auth JWTs (`Settings → API → JWT Secret`) |
| Needed for this repo? | **No** — not read by backend validation or the Next.js app (Auth verifies via Supabase) |
| When you’d use it | Rare: custom JWT verify outside Supabase, or local deep debugging |

Omit it from `.env` unless you have a specific reason.

## Not needed for staging

- `PAYMENT_*` — keep payments disabled on the frontend (`ONLINE_PAYMENT_ENABLED=false`)
- Separate production Supabase keys — use a **different** project later; don’t put prod in this file

## Validation

Optional helper: `src/validation/env.ts` (does not include JWT).
