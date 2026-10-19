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
| `product_images`   | Image metadata + roles                     |
| `categories`       | Browse taxonomy                            |
| `inventory_levels` | Stock counts / availability                |
| `delivery_zones`   | Rwanda coverage + fees (configurable)      |
| `orders`           | Server-created orders                      |
| `order_items`      | Line items with unit price snapshots       |
| `payments`         | Provider attempts / reconciliation (later) |
| `admin_profiles`   | Operator authorization                     |

## Phase 00 schema

Only `pgcrypto` is enabled. Catalogue and order tables arrive in later phases.

## Demo vs production

Demo fixtures belong in the frontend demo gate (or clearly isolated staging data). Do not auto-promote demo rows to production.
