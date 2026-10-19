# THE IP SHAP BUSINESS LTD — Backend

This repository owns the **data plane** for the IP SHAP drinks storefront:

- Postgres migrations and RLS policies (Supabase)
- Storage policies for product imagery (later)
- Edge Functions and payment/webhook handlers (later)
- Versioned API contracts (`contracts/`)
- Backend documentation and CI

It is **not** a custom always-on Node HTTP server. The companion UI lives in `../frontend/`.

## Architecture choice

**Next.js + managed Supabase** was selected over a custom API + Postgres stack. See [DECISIONS.md](./DECISIONS.md).

| Runtime                        | Responsibility                                |
| ------------------------------ | --------------------------------------------- |
| Supabase Postgres + RLS        | Catalogue, inventory, orders, delivery config |
| Supabase Auth                  | Customer/admin identity (later)               |
| Supabase Storage               | Product image originals/derivatives (later)   |
| Edge Functions                 | Webhooks, privileged jobs (later)             |
| Next.js server (frontend repo) | SSR, some BFF Route Handlers when simplest    |

## Local setup

Prerequisites: Node 22+, npm, and optionally the [Supabase CLI](https://supabase.com/docs/guides/cli).

```bash
cd backend
cp .env.example .env
npm install
npm run test
npm run typecheck
```

With Supabase CLI installed:

```bash
supabase start
supabase db reset
```

Copy local API URL and keys into `frontend/.env.local` as documented in the frontend environment guide.

## Scripts

| Command                | Purpose                         |
| ---------------------- | ------------------------------- |
| `npm run test`         | Vitest (contracts + validation) |
| `npm run typecheck`    | TypeScript                      |
| `npm run lint`         | ESLint                          |
| `npm run format:check` | Prettier                        |

## Documentation index

- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [DECISIONS.md](./DECISIONS.md)
- [ENVIRONMENT.md](./ENVIRONMENT.md)
- [DATA_MODEL.md](./DATA_MODEL.md)
- [SECURITY.md](./SECURITY.md)
- [TESTING.md](./TESTING.md)
- [OPERATIONS.md](./OPERATIONS.md)
- [API_CONTRACTS.md](./API_CONTRACTS.md)
- [ORDER_AND_PAYMENT_LIFECYCLE.md](./ORDER_AND_PAYMENT_LIFECYCLE.md)
- [CHANGELOG.md](./CHANGELOG.md)

## Phase status

Phase 00 establishes structure, contracts, initial migration (extensions only), docs and CI. Catalogue tables and seed data intentionally wait for later phases.
