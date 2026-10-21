# Backend architecture

## Overview

```text
frontend (Next.js on Vercel)
    │  anon key + RLS
    │  service role (server only)
    ▼
Supabase
    ├── Postgres (migrations in this repo)
    ├── Auth (admin users + admin_profiles)
    ├── Storage (product-originals / product-catalogue)
    └── (optional) Edge Functions later

contracts/ ── versioned Zod schemas mirrored by the frontend
```

## Repository layout

```text
backend/
├── contracts/              # Zod schemas + contract version
├── src/validation/         # Env helpers
├── scripts/                # Ops scripts (e.g. seed-admins)
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   └── seed/
├── documentation/
└── package.json
```

## Responsibility split

| Concern | Owner |
| ------- | ----- |
| UI / SEO / checkout UX | frontend |
| Schema, RLS, storage policies, stock RPCs | backend |
| Staff email send | frontend (Resend) using order data |
| Demo fixtures | frontend only; never auto-seed production DB |
| Backups / restore drill | Supabase plan + `BACKUP_RESTORE.md` |

## Catalogue & media

- Published products drive the storefront.
- Originals stay in private `product-originals`; public JPEGs in `product-catalogue`.
- Admin uploads: validate → private original → sharp re-encode → public derivative (frontend service role).

## Orders & stock

- Orders are created by the Next.js server with the service role.
- Counted stock is reserved when the order is **placed** (not on confirm/payment).
- Cancel restores reserved quantities. See `ORDER_AND_PAYMENT_LIFECYCLE.md`.

## Money

All monetary columns and contract fields use integer RWF. No floating-point money.
