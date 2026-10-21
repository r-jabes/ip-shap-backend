# API contracts

Canonical schemas live in `contracts/` and are versioned via `CONTRACT_VERSION` in `contracts/money.ts`.

## Modules

| Module | File | Purpose |
| ------ | ---- | ------- |
| Money | `contracts/money.ts` | Integer RWF |
| Catalogue | `contracts/catalogue.ts` | Product + image metadata + list query |
| Admin | `contracts/admin.ts` | Roles, product write, stock adjustment |
| Bulk import | `contracts/bulk-import.ts` | CSV template + dry-run validation |
| Image upload | `contracts/product-image-upload.ts` | Upload meta + MIME/signature gate |
| Orders | `contracts/orders.ts` | Create/lookup, snapshots, fulfilment/payment |
| Transitions | `contracts/order-transitions.ts` | Legal fulfilment/payment state changes |
| Payments | `contracts/payments.ts` | Initiate + sandbox webhook signatures |
| Notifications | `contracts/notifications.ts` | Template ids + idempotent send request |

## Sync process with frontend

1. Change Zod schema in this repo.
2. Bump `CONTRACT_VERSION` when breaking.
3. Update frontend domain types / validators.
4. Note both changelogs when behaviour changes.

## Runtime transport

| Path | Mechanism |
| ---- | --------- |
| Catalogue reads | Supabase PostgREST / client + RLS (and cached server reads) |
| Place order / lookup | Next.js Server Actions (service role) |
| Search suggest | Next.js Route Handler + `suggest_catalogue` RPC |
| Admin mutations | Next.js Server Actions + Auth / session |
| Payment webhooks | Next.js Route Handler (sandbox HMAC) |

There is no separate always-on backend HTTP server in this repo.
