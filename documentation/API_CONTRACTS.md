# API contracts

Canonical schemas live in `contracts/` and are versioned via `CONTRACT_VERSION` in `contracts/money.ts` (currently `0.6.0`).

## Modules

| Module        | File                                | Purpose                                         |
| ------------- | ----------------------------------- | ----------------------------------------------- |
| Money         | `contracts/money.ts`                | Integer RWF                                     |
| Catalogue     | `contracts/catalogue.ts`            | Product + image metadata + list query           |
| Admin         | `contracts/admin.ts`                | Roles, product write, stock adjustment          |
| Bulk import   | `contracts/bulk-import.ts`          | CSV template + dry-run validation report        |
| Image upload  | `contracts/product-image-upload.ts` | Upload meta + MIME/signature gate (no HTTP yet) |
| Orders        | `contracts/orders.ts`               | Create/lookup, snapshots, fulfilment/payment    |
| Transitions   | `contracts/order-transitions.ts`    | Legal fulfilment/payment state changes          |
| Payments      | `contracts/payments.ts`             | Initiate + sandbox webhook signatures           |
| Notifications | `contracts/notifications.ts`        | Template ids + idempotent send request          |

## Sync process with frontend

1. Change Zod schema in this repo
2. Bump `CONTRACT_VERSION` when breaking
3. Update frontend domain types / validators
4. Note both changelogs

## Transport (planned)

- Supabase PostgREST for catalogue reads (RLS)
- Edge Function or Next.js Route Handler for `createOrder`
- Provider webhooks → Edge Function

No live HTTP endpoints are implemented in Phase 00.
