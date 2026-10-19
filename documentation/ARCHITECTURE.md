# Backend architecture

## Overview

```text
frontend (Next.js)
    │  anon key + RLS
    │  service role (server only, sparingly)
    ▼
Supabase
    ├── Postgres (schema/migrations in this repo)
    ├── Auth
    ├── Storage
    └── Edge Functions (this repo)

contracts/ ── versioned Zod schemas mirrored by frontend domain types
```

## Repository layout

```text
backend/
├── contracts/                 # Zod schemas + contract version
├── src/validation/            # Env and shared validation helpers
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   └── functions/             # Edge Functions (later)
├── documentation/
└── .github/workflows/ci.yml
```

## Responsibility split with frontend

| Concern                                    | Owner                                         |
| ------------------------------------------ | --------------------------------------------- |
| UI / UX / SEO                              | frontend                                      |
| Schema, RLS, storage policies              | backend                                       |
| Order creation integrity, payment webhooks | backend (+ frontend BFF only when documented) |
| Demo fixtures                              | frontend (gated); never auto-seed production  |

## Product imagery (Phase 02)

- Private originals vs public derivatives (see `DATA_MODEL.md` / `SECURITY.md`)
- Upload boundary validation in `contracts/product-image-upload.ts` (no live endpoint yet)
- Catalogue image metadata includes roles and `processing_status`; unreviewed assets must not auto-publish

## Money

All monetary columns and contract fields use integer RWF. No floating-point money.

## Scaling posture

Schema and indexes will be designed for 300+ products from the catalogue phase onward. Phase 00 only enables required extensions.
