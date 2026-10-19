# Backend security

## Controls

1. RLS on all public-facing tables
2. Service role key only in trusted server/Edge contexts — never rely on RLS alone when using the service role
3. Webhook handlers must verify signatures and be idempotent
4. No secrets in migrations or Git
5. Image uploads: validate MIME/signature, size, dimensions (`contracts/product-image-upload.ts`); re-encode before public serve
6. Admin access via `admin_profiles` + Supabase Auth (no public registration)
7. Stock adjustments and sensitive mutations write audit rows (`stock_adjustments`, `audit_events`) — never log passwords or payment secrets

## Admin roles (least privilege)

| Role    | Permissions                                                       |
| ------- | ----------------------------------------------------------------- |
| `owner` | products, inventory, import, audit read, manage other admins      |
| `staff` | products, inventory, import, audit read — **not** `admins:manage` |

Helpers: `is_admin()`, `admin_has_role(allowed[])`.

## Admin provisioning (one-time)

1. Create the user in Supabase Auth (dashboard / invite) — **no** self-serve admin signup.
2. With the service role (or SQL as a superuser), insert `admin_profiles` for that `user_id` with `role = 'owner'`.
3. Rotate any bootstrap tokens used during local development.
4. Additional staff: owner inserts `admin_profiles` rows only.

Never ship default passwords or hardcoded credentials.

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

## Threat notes

- Price tampering from the client → server recomputes totals
- WhatsApp deep-link spoofing → order must exist server-side first
- Public bucket exposure of originals → prefer private originals + public derivatives
- Hidden admin UI is not authorisation — every mutation checks role server-side / RLS
- Login responses must not disclose whether an email exists
- Payment callbacks → signature verification + idempotent event store (never trust redirects)
- Order PII → no anon SELECT on orders/items (see `RLS_INVENTORY.md`)
- Audit logs → no passwords, cards, or webhook secrets

## Privacy

See `PRIVACY_AND_RETENTION.md`. Launch confirmation items: `RWANDA_LAUNCH_CHECKLIST.md`.
