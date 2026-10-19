# Release checklist

## Severity triage

| Severity | Examples                                                            | Launch rule     |
| -------- | ------------------------------------------------------------------- | --------------- |
| Critical | Auth bypass, payment forgery, secret leak, oversell with money loss | **Block**       |
| High     | Broken checkout, RLS hole, XSS with session risk                    | **Block**       |
| Medium   | A11y gaps, SEO mistakes, non-critical UX                            | Fix or document |
| Low      | Copy polish, demo-only issues                                       | Backlog OK      |

## Pre-release (every candidate)

1. `npm run lint && npm run typecheck && npm test` in `backend/` and `frontend/`
2. `npm run build` in `frontend/`
3. Apply migrations to a clean local Supabase and smoke RLS (admin vs anon)
4. Manual: keyboard-only skip link, cart drawer Escape, checkout create + lookup
5. Manual: forged payment webhook rejected; duplicate event id no-ops
6. Confirm `ONLINE_PAYMENT_ENABLED=false` unless provider gate completed
7. Confirm no secrets in `.env.example`, logs, or client bundles (`NEXT_PUBLIC_*`)
8. Review open Critical/High bugs — none unresolved

## Post-release

- Monitor webhook error rates and order create failures
- Keep rollback artifact of previous frontend deploy
- Schedule backup restore drill

## Known limitations (honest)

- Live payment provider unselected — WhatsApp-assisted primary
- Admin bootstrap token is for local/staging until Supabase Auth is live
- Delivery zones empty until business configures fees
- Demo catalogue / prices may need confirmation
- CSP still allows `'unsafe-inline'` / `'unsafe-eval'` for Next.js — plan nonces later
- In-memory rate limits are single-instance only
