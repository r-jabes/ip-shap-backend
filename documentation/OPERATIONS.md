# Backend operations

## Migrations

```bash
npm run db:reset           # local (supabase db reset)
npm run db:push            # linked remote (careful)
supabase migration new <name>
```

Never edit applied migrations in place on shared environments; add a new migration.

## P4 stock engine

After `20261021190000_p4_stock_engine.sql`:

- `orders.stock_committed` — set when confirm decrements on-hand inventory
- `confirm_order_stock(order_id)` / `restore_order_stock(order_id)` — row-locked, idempotent (service role)
- `adjust_inventory_level(...)` — optimistic expected-qty guard for admin adjusts

Unknown availability is never decremented as counted stock. Cancel after confirm restores quantities.

## P3 media storage

After `20261021180000_p3_catalogue_media.sql`:

- Bucket `product-originals` — private sources (not publicly readable)
- Bucket `product-catalogue` — public JPEG derivatives
- RPC `apply_bulk_catalogue_import(jsonb)` — transactional CSV apply (service role only)

Admin uploads go through the frontend service role: magic-byte check → private original → sharp re-encode → public derivative + `product_images` row.

## P1 seed + RLS smoke

After migrations on **staging** (not production until cutover):

```bash
npm run db:seed:p1         # minimal published product
npm run db:rls-smoke       # asserts no anon order SELECT + P1 columns
```

Or paste `supabase/seed/p1_minimal_catalogue.sql` and `supabase/seed/rls_smoke_checks.sql` into the Supabase SQL editor.

Then from the frontend (with staging URL + anon or service key, `NEXT_PUBLIC_DEMO_MODE=false`):

```ts
import { getCatalogueRepository } from "@/lib/catalogue";
const products = await getCatalogueRepository().listProducts();
// expect seed-house-red after seed
```

## Backups

Use Supabase automated backups / point-in-time recovery appropriate to the paid plan. Document restore drills before production launch.

## Incident / rollback

1. Identify failing migration or function version
2. Roll forward with a corrective migration when possible
3. Coordinate frontend deploy compatibility via contract version notes

## Secrets rotation

Rotate service role keys and webhook secrets via the Supabase dashboard / provider console; update hosting env vars; never commit values.

## Admin Auth (P2)

**Primary:** Supabase Auth email/password. Users must have an active `admin_profiles` row. Owners invite teammates from `/admin/team` (no public `/admin` registration).

**First owners (staging):**

1. Create Auth users in Supabase (Dashboard → Authentication → invite/password).
2. Insert profiles (service role / SQL editor):

```sql
insert into public.admin_profiles (user_id, role, display_name, is_active)
values
  ('<wife-auth-uuid>', 'owner', 'Owner A', true),
  ('<husband-auth-uuid>', 'owner', 'Owner B', true);
```

3. Sign in at `/admin/login` with email + password.
4. Further staff/manager/owner invites go through `/admin/team`.

**Break-glass (local / emergency):** `ADMIN_BOOTSTRAP_TOKEN` (+ optional `ADMIN_BOOTSTRAP_EMAIL`) on the login form’s break-glass mode. Prefer Auth for day-to-day; document rotation of the bootstrap token.

**Roles:** `owner` (invite + prices) · `manager` (prices, no invite) · `staff` (no prices, no invite, no CSV import).

## Bulk import CSV

Template headers are defined in `contracts/bulk-import.ts` (`BULK_IMPORT_HEADERS`). Always dry-run validate; never silently skip invalid rows.

## Release

Follow `RELEASE_CHECKLIST.md`. Confirm `RWANDA_LAUNCH_CHECKLIST.md` items with the business before marketing launch.
