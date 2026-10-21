# IP SHAP — Backend

Data plane for **THE IP SHAP BUSINESS LTD** (IP SHAP): Supabase Postgres migrations, RLS, storage buckets, Zod contracts, and ops scripts.

This is **not** a long-running Node HTTP API. The Next.js app in `../frontend/` is the application server; this repo owns the database and typed contracts.

## Stack

| Layer | Choice |
| ----- | ------ |
| Database | Supabase Postgres 15 |
| Auth / Storage | Supabase Auth + Storage |
| Migrations | Supabase CLI (`supabase/migrations/`) |
| Contracts | Zod schemas in `contracts/` |
| Tooling | TypeScript, Vitest, ESLint, Prettier |
| Scripts | Node + `@supabase/supabase-js` (admin seed) |

## What this repo owns

- Schema: catalogue, inventory, orders, delivery zones, admin profiles, payments stubs
- RLS policies and stock RPCs (`reserve_order_stock` / `restore_order_stock`)
- Storage buckets: `product-originals` (private), `product-catalogue` (public derivatives)
- Versioned request/response contracts mirrored by the frontend
- Staging helpers: seed catalogue, seed owners, RLS smoke SQL

## Prerequisites

- Node.js 22+ and npm
- [Supabase CLI](https://supabase.com/docs/guides/cli) via `npx` (no global install required)
- A Supabase project (use **staging** for day-to-day; production = separate project)

## Local / staging setup

```bash
cd backend
cp .env.example .env.local
# SUPABASE_URL + anon + service_role (same staging project as the frontend)
# Optional: ADMIN_OWNER_* for npm run db:seed:admins
npm install

npx supabase login          # once per machine
npx supabase link --project-ref <your-project-ref>
npm run db:push             # apply all migrations to the linked project
npm run db:seed:p1          # minimal published product
npm run db:seed:admins      # Auth users + owner profiles from .env.local
npm run db:rls-smoke        # optional sanity checks
```

Optional full local stack (Docker):

```bash
npx supabase start
npx supabase db reset
```

Then copy local URL/keys into `frontend/.env.local`.

## Scripts

| Command | Purpose |
| ------- | ------- |
| `npm run db:push` | Push migrations to the **linked** remote |
| `npm run db:seed:p1` | Seed minimal catalogue (linked remote) |
| `npm run db:seed:admins` | Create/update owner Auth users + `admin_profiles` |
| `npm run db:rls-smoke` | Run RLS smoke SQL (linked remote) |
| `npm run db:reset` | Reset **local** Supabase DB |
| `npm run test` / `typecheck` / `lint` | Quality gates |
| `npm run audit:prod` | Critical dependency audit |

## Deploy order

1. **This repo / Supabase** — migrations and seeds (no Vercel URL required).
2. **Frontend** — needs Supabase URL and keys in Vercel env.

## Documentation

Start at [documentation/README.md](./documentation/README.md).
