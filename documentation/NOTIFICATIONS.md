# Notifications

## Adapter

Default channel is **log** (`src/notifications/log-adapter.ts`). No email/SMS/WhatsApp provider credentials are assumed.

Templates are versioned by id in `contracts/notifications.ts`:

- `order_awaiting_confirmation`
- `order_confirmed`
- `payment_received`
- `order_cancelled`
- `fulfilment_update`

## Rules

- Sends are idempotent on `idempotencyKey`.
- A failed notification must not mutate order or payment state.
- Customer templates should include order reference, status and next steps — never invent delivery ETAs.
- Avoid sending unnecessary PII to analytics or third parties.
