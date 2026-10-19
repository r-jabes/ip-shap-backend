# Privacy and retention (for qualified legal review)

This document states **engineering expectations**, not legal advice. Before launch, have a qualified advisor confirm Rwanda-applicable privacy and consumer rules.

## Personal data handled

| Data                        | Purpose               | Notes                          |
| --------------------------- | --------------------- | ------------------------------ |
| Customer name / phone       | Order contact         | Required for fulfilment        |
| Delivery address fields     | Delivery              | Optional until zones confirmed |
| Order notes                 | Customer instructions | Free text — minimise           |
| Admin email                 | Staff auth            | Via Auth / bootstrap           |
| Payment references (manual) | Reconciliation        | No raw card data stored        |

## Retention / deletion (proposed — confirm legally)

- Orders and status history: retain for business/tax period (confirm duration).
- Lookup tokens: treat as secrets; rotate/invalidate on request where feasible.
- Audit events: retain for security review; **must not** store passwords, full cards, or webhook secrets.
- Backups: follow Supabase plan retention; document restore ownership.

## Minimisation

- Cart localStorage: product id + quantity only (frontend).
- WhatsApp deep links: order reference + total only — avoid stuffing full addresses into query strings.
- Public APIs: no order list/enumeration; lookup requires reference + high-entropy token.
- Logs: use redacting logger; avoid dumping request bodies with PII.

## Customer rights (process TBD)

Document how a customer can request access/correction/deletion once legal requirements are confirmed. Engineering will need an operator runbook before go-live.
