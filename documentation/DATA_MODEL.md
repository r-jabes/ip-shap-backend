# Data model

## Conventions

- Primary keys: UUID (`gen_random_uuid()`)
- Money: integer RWF columns (e.g. `price_rwf integer check (price_rwf >= 0)`)
- Timestamps: `timestamptz` defaults to `now()`
- Soft operational states via status enums rather than physical deletes where practical

## Core entities

| Entity | Purpose |
| ------ | ------- |
| `products` | Sellable SKUs (incl. featured flags) |
| `product_images` | Image metadata + roles + processing status |
| `categories` / `brands` | Browse taxonomy |
| `inventory_levels` | Stock counts / availability |
| `stock_adjustments` | Immutable stock audit |
| `delivery_zones` | Coverage + optional fees |
| `orders` / `order_items` | Server-created orders with price snapshots |
| `payments` | Provider attempts / reconciliation (stubs) |
| `admin_profiles` | Operator authorization (`owner` / `manager` / `staff`) |
| `audit_events` | Sensitive action log (no secrets) |

## Product images

| Field | Notes |
| ----- | ----- |
| `product_id` | FK — stable identity |
| `role` | catalogue_primary / secondary / editorial / thumbnail / zoom |
| `sort_order` | Non-negative integer |
| `alt` | Required accessible description |
| `src` / `zoom_src` | Public derivative URLs |
| `original_ref` | Private original key |
| `width` / `height` | Intrinsic pixels |
| `processing_status` | source_received → needs_review → approved / rejected / archived |

Unreviewed / rejected images must not appear in public catalogue reads.

## Admin and inventory

Negative stock is rejected. `unknown` availability must not be treated as in stock. Counted stock moves via `reserve_order_stock` / `restore_order_stock` and admin adjusts.

## Orders and delivery

- Opaque public `reference`; lookup requires high-entropy token (hash stored when configured).
- Line items snapshot unit prices at place time.
- Delivery zones are optional; checkout must not invent fees.

See `ORDER_AND_PAYMENT_LIFECYCLE.md` for status transitions and stock timing.
