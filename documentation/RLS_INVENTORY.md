# RLS inventory (Phase 08)

Verified against migrations under `supabase/migrations/`. Policies are the source of truth.

| Table                    | Anon / public                     | Authenticated admin (`owner` / `manager` / `staff`) |
| ------------------------ | --------------------------------- | --------------------------------------------------- |
| `products` (+ related)   | Published catalogue reads only    | Write via `admin_has_role` (manager = staff rights) |
| `delivery_zones`         | Active zones select               | Admin write                                         |
| `orders`                 | **No** public select/list         | Admin select/update                                 |
| `order_items`            | **No** public select              | Admin select                                        |
| `order_status_history`   | **No** public select              | Admin select/insert                                 |
| `payment_attempts`       | **No** public                     | Admin select                                        |
| `payment_webhook_events` | **No** public                     | Admin select                                        |
| `admin_profiles`         | Self / admin only (see migration) | **Owner** manage only                               |
| `inventory_levels`       | Not public                        | Admin adjust                                        |
| `audit_events`           | Not public                        | Admin read                                          |

P1 adds `products.is_featured`, `orders.lookup_token_hash`, and `admin_role.manager`. Smoke SQL: `supabase/seed/rls_smoke_checks.sql`.

P3 storage: `product-originals` (private; admin read/write) · `product-catalogue` (public read; admin write). Bulk apply RPC is `service_role` only.

Order creation and webhook application use the **service role** / trusted server — never grant anon INSERT on orders.

## Residual risk

- Local frontend still uses an in-memory order store until Supabase Edge wiring is complete.
- Service role bypasses RLS — keep it out of the browser and out of logs.
