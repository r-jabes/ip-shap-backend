# Order and payment lifecycle

## Channels

1. **Online payment** — only after a Rwanda-capable provider is verified (methods, settlement, fees, currency, API docs). Until `ONLINE_PAYMENT_ENABLED=true` (frontend/server), the channel is rejected.
2. **WhatsApp-assisted** — create the durable order server-side first, then hand the customer a deep link. Opening WhatsApp is **not** proof of payment or acceptance.

## Fulfilment state machine

```text
awaiting_confirmation
  → confirmed → processing → ready_for_dispatch → out_for_delivery → delivered
  ↘ cancelled (from non-terminal states)
```

Illegal transitions are rejected in domain logic (`contracts/order-transitions.ts`), not only in UI.

## Payment status (separate)

| Status           | Meaning                              |
| ---------------- | ------------------------------------ |
| `not_applicable` | WhatsApp/manual channel (default)    |
| `unpaid`         | Online channel, not started          |
| `pending`        | Provider redirect / awaiting webhook |
| `paid`           | Verified paid (webhook or staff)     |
| `failed`         | Provider failure                     |
| `cancelled`      | Attempt cancelled before paid        |
| `refunded`       | Refunded after paid                  |

Browser redirects alone never set `paid`. Manual staff marks require reference + reason.

## Stock reservation policy

- **When:** at order creation (atomic with order + items).
- **What:** for products with a known non-null on-hand quantity, reserve units (`available = on_hand - open_reservations`). Fail if `available < ordered`. SQL uses conditional updates / row locks; the demo store uses an in-memory reservation map.
- **Unknown stock:** do not invent availability; lines may be accepted without a hard reservation when quantity is unknown.
- **Release:** on `cancelled`, release reservations; reservation expiry (`reservation_expires_at`, default 48h) applies while awaiting confirmation.
- **Oversell prevention:** never rely on UI-only checks.

## Idempotency

- Client supplies `idempotencyKey` (UUID) on create.
- Same key returns the original order summary (no duplicate rows).
- Payment webhooks (later) dedupe on provider event id.

## Money

All amounts are integer RWF. Server recomputes unit prices and totals from authoritative catalogue data — client prices are ignored.

## Delivery

- Zones/fees live in `delivery_zones`.
- If no active zones (or selected zone has `fee_rwf` null), checkout shows **delivery fee unavailable** and may still accept WhatsApp-assisted orders with `delivery_fee_rwf = null` for manual confirmation.
- Never invent nationwide fees or ETAs before the business configures zones.

## Customer order lookup

- Public lookup requires `reference` + high-entropy `lookup_token` (rate limited).
- No sequential ID enumeration; list endpoints are admin-only (RLS).

## Order reference

Human-readable `IPS-YYYYMMDD-XXXX` plus opaque UUID `id`.
