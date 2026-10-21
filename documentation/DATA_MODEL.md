# Data model

## Conventions

- Primary keys: UUID (`gen_random_uuid()`)
- Money: integer RWF columns (e.g. `price_rwf integer check (price_rwf >= 0)`)
- Timestamps: `timestamptz` defaults to `now()`
- Soft operational states via status enums rather than physical deletes where practical

## Planned entities (not all migrated yet)

| Entity             | Purpose                                    |
| ------------------ | ------------------------------------------ |
| `products`         | Sellable SKUs                              |
| `product_images`   | Image metadata + roles + processing status |
| `categories`       | Browse taxonomy                            |
| `inventory_levels` | Stock counts / availability                |
| `delivery_zones`   | Rwanda coverage + fees (configurable)      |
| `orders`           | Server-created orders                      |
| `order_items`      | Line items with unit price snapshots       |
| `payments`         | Provider attempts / reconciliation (later) |
| `admin_profiles`   | Operator authorization                     |

## Product image fields (contract-aligned)

Planned `product_images` columns (not migrated yet):

| Field               | Notes                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------- |
| `product_id`        | FK — stable identity; never derive from filenames                                       |
| `role`              | `catalogue_primary` \| `catalogue_secondary` \| `editorial` \| `thumbnail` \| `zoom`    |
| `sort_order`        | Non-negative integer                                                                    |
| `alt`               | Required accessible description                                                         |
| `src` / `zoom_src`  | Public derivative URLs/paths                                                            |
| `original_ref`      | Private original key; not public by default                                             |
| `width` / `height`  | Intrinsic pixels of the served derivative                                               |
| `processing_status` | `source_received` → `needs_review` → `approved_for_catalogue` / `rejected` / `archived` |
| `crop_instructions` | Operator guidance                                                                       |
| `rights_note`       | Source / rights                                                                         |
| flags               | e.g. shared multi-product photo, needs client confirmation                              |

Unreviewed / rejected images must not auto-publish to production catalogue reads.

## Admin and inventory (Phase 05)

| Table               | Purpose                                                     |
| ------------------- | ----------------------------------------------------------- |
| `admin_profiles`    | `owner` / `staff` linked to `auth.users` — no public signup |
| `inventory_levels`  | Per-product quantity (nullable when unknown) + availability |
| `stock_adjustments` | Immutable audit of quantity/availability changes            |
| `audit_events`      | Sensitive action log (no secrets/passwords)                 |

Negative stock is rejected. `unknown` availability must not be treated as in stock.

## Orders and delivery (Phase 06)

| Table                  | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `delivery_zones`       | Configurable coverage + optional integer RWF fee    |
| `orders`               | Reference, lookup token, money totals, customer PII |
| `order_items`          | Immutable name/price/qty snapshots                  |
| `order_status_history` | Fulfilment/payment transitions with actor + reason  |

Public cannot list orders. Lookup is reference + token (app layer). Admins read via RLS.

## Schema status

Extensions + catalogue + admin/inventory + orders + P1 durable-layer + P3 media/storage migrations are in `supabase/migrations/`. Optional staging seed: `supabase/seed/p1_minimal_catalogue.sql` (not for production).

## Demo vs production

Demo fixtures belong in the frontend demo gate (or clearly isolated staging data). Do not auto-promote demo rows to production.
