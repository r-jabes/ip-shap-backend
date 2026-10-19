# Order and payment lifecycle

## Channels

1. **Online payment** — only after a Rwanda-capable provider is verified (methods, settlement, fees, currency, API docs).
2. **WhatsApp-assisted** — create the order server-side first, then hand the customer a deep link. Opening WhatsApp is not proof of payment or acceptance.

## Planned state machine

```text
draft
  → pending_payment              (online channel)
  → awaiting_manual_confirmation (WhatsApp / manual)
  → paid
  → fulfilled
  → cancelled
  → refunded
```

## Idempotency

- Client supplies an idempotency key on create (later)
- Webhooks dedupe on provider event id
- Recomputing totals always uses authoritative catalogue prices

## Delivery fees

Fees and zones are configurable and unknown until the business confirms them. Orders may carry `deliveryFee: null` with an explicit unavailable/unknown UI state in the frontend.

## Phase 00 status

Lifecycle is documented only. No order tables or payment integrations are implemented.
