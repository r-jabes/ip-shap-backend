# Backend decisions (ADRs)

## ADR-001 — Managed Supabase instead of a custom API (2026-10-19)

### Context

Need secure catalogue, orders, auth, storage and webhooks for a single-retailer Rwanda drinks shop, while keeping separate `frontend/` and `backend/` repositories.

### Options

1. Next.js + managed Supabase (Postgres/Auth/Storage/RLS/Edge Functions)
2. Next.js + custom always-on API + Postgres

### Decision

Option 1. This repo holds migrations, policies, Edge Functions, contracts and ops docs.

### Rejected reason for option 2

Higher operational cost and duplicated auth/storage work without a clear requirement that Supabase cannot meet at this stage.

## ADR-002 — Contracts authored in backend (2026-10-19)

### Decision

Canonical Zod contracts live in `backend/contracts/`. Frontend mirrors types deliberately; no cross-repo filesystem imports.

## ADR-003 — No fabricated catalogue seed in Phase 00 (2026-10-19)

### Decision

Do not create product tables or seed invented products yet. Client photographs under `../resources/` will inform a later provisional catalogue after the storefront prototype exists.
