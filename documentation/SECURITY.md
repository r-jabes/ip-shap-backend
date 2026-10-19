# Backend security

## Controls

1. RLS on all public-facing tables (when created)
2. Service role key only in trusted server/Edge contexts
3. Webhook handlers must verify signatures and be idempotent
4. No secrets in migrations or Git
5. Image uploads (later): validate MIME/signature, size, dimensions; re-encode before public serve

## Alcohol / regulated goods checklist (for qualified local review)

This project does **not** claim compliance. Before launch, obtain qualified local advice on:

- [ ] Minimum age / age verification for alcohol sales
- [ ] Advertising restrictions for alcoholic drinks
- [ ] Licensing / permitted online sale rules
- [ ] Delivery constraints (time, location, recipient)
- [ ] Consumer protection, returns and refunds
- [ ] Tax / invoicing obligations
- [ ] Privacy / personal data handling (customer phone, address)
- [ ] Cross-border sale restrictions (store is Rwanda-delivery focused)

## Threat notes (early)

- Price tampering from the client → server recomputes totals
- WhatsApp deep-link spoofing → order must exist server-side first
- Public bucket exposure of originals → prefer private originals + public derivatives
