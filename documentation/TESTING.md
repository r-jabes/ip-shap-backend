# Backend testing

## Layers

| Layer        | Tool                                   | Scope                      |
| ------------ | -------------------------------------- | -------------------------- |
| Unit         | Vitest                                 | Zod contracts, env parsing |
| SQL (later)  | Supabase local / pgTAP or policy tests | RLS behaviour              |
| Edge (later) | Deno tests / integration harness       | Webhooks                   |

## Commands

```bash
npm run test
npm run lint
npm run typecheck
```

## Phase 00 coverage

- Integer money schema rejects fractions
- Backend env parser accepts unset Supabase values during foundation setup
