# Backend testing

## Layers

| Layer        | Tool                   | Scope                                              |
| ------------ | ---------------------- | -------------------------------------------------- |
| Unit         | Vitest                 | Zod contracts, env, money, payments, notifications |
| SQL (later)  | Supabase local / pgTAP | RLS behaviour                                      |
| Edge (later) | Deno / integration     | Live webhooks                                      |

## Commands

```bash
npm run test
npm run lint
npm run typecheck
```

## Phase 08 coverage additions

- `multiplyRwfAmount` overflow + random integer invariants
- Sandbox webhook forged signature rejection (existing)
- Notification idempotency (existing)

## Manual / SQL before go-live

1. `supabase db reset` on clean local DB
2. As `anon`: confirm `select * from orders` returns zero rows / denied
3. As admin JWT: confirm order read works
4. See `RELEASE_CHECKLIST.md` and `RLS_INVENTORY.md`
