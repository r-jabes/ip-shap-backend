# Payments

See also: `PAYMENT_PROVIDER_DECISION.md`, `ORDER_AND_PAYMENT_LIFECYCLE.md`.

## Status

**Live provider:** unselected (2026-10-19). Production must keep online checkout off until the decision gate is completed with official sources.

## Architecture

- Payment status is separate from fulfilment.
- Attempts live in `payment_attempts` (provider, amount, mode, idempotency).
- Webhook event ids are stored in `payment_webhook_events` for idempotent processing.
- Contracts: `contracts/payments.ts`. Sandbox adapter: `src/payments/sandbox-adapter.ts`.

## Sandbox (tests only)

| Item        | Value                                 |
| ----------- | ------------------------------------- |
| Provider id | `sandbox`                             |
| Mode label  | always `sandbox` — never show as live |
| Signature   | HMAC-SHA256 hex over raw body         |
| Header      | `x-ipshap-sandbox-signature`          |

Never accept a browser return URL alone as payment proof.

## Go-live

Complete the checklist in `PAYMENT_PROVIDER_DECISION.md` before setting any live provider id or enabling online checkout.
