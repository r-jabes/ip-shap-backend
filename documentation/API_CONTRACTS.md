# API contracts

Canonical schemas live in `contracts/` and are versioned via `CONTRACT_VERSION` in `contracts/money.ts` (currently `0.1.0`).

## Modules

| Module    | File                     | Purpose                      |
| --------- | ------------------------ | ---------------------------- |
| Money     | `contracts/money.ts`     | Integer RWF                  |
| Catalogue | `contracts/catalogue.ts` | Product + list query         |
| Orders    | `contracts/orders.ts`    | Create order request/summary |

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
