# Backend operations

## Migrations

```bash
npm run db:reset           # local Docker only
npm run db:push            # linked remote staging/prod (careful)
npx supabase migration new <name>
```

Never edit applied migrations on shared environments; add a new migration instead.

## Orders (created from the frontend)

Orders are inserted by the Next.js server with the service role: `orders` + `order_items` + history, then `reserve_order_stock`. Public clients never list orders. Lookup uses `reference` + `lookup_token` (rate limited, constant-time compare).

Configure on the **frontend** host: `ORDER_NOTIFY_EMAILS`, `EMAIL_FROM`, `RESEND_API_KEY`.

## Stock

- `orders.stock_committed` — set when place-order decrements on-hand inventory (not on confirm/payment)
- `reserve_order_stock(order_id)` / `restore_order_stock(order_id)` — row-locked, idempotent
- `adjust_inventory_level(...)` — optimistic expected-qty guard for admin adjusts

Unknown availability is never decremented as counted stock. Cancel restores quantities reserved at place.

## Media storage

- Bucket `product-originals` — private sources
- Bucket `product-catalogue` — public JPEG derivatives
- RPC `apply_bulk_catalogue_import(jsonb)` — transactional CSV apply (service role only)

Admin uploads (frontend): magic-byte check → private original → sharp re-encode → public derivative + `product_images` row.

## Seed + RLS smoke (staging)

```bash
npm run db:seed:p1
npm run db:rls-smoke
```

Or paste `supabase/seed/p1_minimal_catalogue.sql` and `supabase/seed/rls_smoke_checks.sql` in the SQL editor.

With frontend env pointed at staging and `NEXT_PUBLIC_DEMO_MODE=false`, the shop should show the seed product.

## Admin Auth

**Preferred:** `npm run db:seed:admins` after setting `ADMIN_OWNER_*` in `backend/.env.local` (see `.env.example`).

Creates/updates Auth users and upserts `admin_profiles` as `owner`. Sign in at `/admin/login`.

Further invites: `/admin/team` in the frontend.

**Roles:** `owner` (invite + prices) · `manager` (prices, no invite) · `staff` (no prices / invite / CSV).

**Break-glass:** frontend `ADMIN_BOOTSTRAP_TOKEN` — emergency only.

## Bulk import CSV

Headers: `contracts/bulk-import.ts` (`BULK_IMPORT_HEADERS`). Always dry-run validate; never silently skip invalid rows.

## Backups

Use Supabase automated backups / PITR for the paid plan. Document a staging restore drill in [`BACKUP_RESTORE.md`](./BACKUP_RESTORE.md) before production sign-off.

## Incident / rollback

1. Identify failing migration or function version.
2. Roll forward with a corrective migration when possible.
3. Coordinate frontend deploy compatibility via contract notes.

## Secrets rotation

Rotate service role keys via the Supabase dashboard; update Vercel / `.env.local`; never commit values.

## Release

Follow `RELEASE_CHECKLIST.md`. Confirm `RWANDA_LAUNCH_CHECKLIST.md` with the business before marketing launch.
