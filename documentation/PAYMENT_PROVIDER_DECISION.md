# Payment provider decision (Rwanda) — Phase 07

**Status as of 2026-10-19:** **No live provider selected.** Credentials are unavailable. Production must keep `ONLINE_PAYMENT_ENABLED=false` until Rosine confirms a merchant account and this note is updated with dated official sources.

## Decision gate (required before go-live)

Confirm from **official** provider documentation (record URL + access date):

| Topic                            | Confirmed? | Notes |
| -------------------------------- | ---------- | ----- |
| Merchant onboarding / KYC        | ☐          |       |
| Local methods (e.g. MoMo, cards) | ☐          |       |
| RWF support & settlement         | ☐          |       |
| Fees, refunds, disputes          | ☐          |       |
| Webhook signatures / idempotency | ☐          |       |
| Test mode + production approval  | ☐          |       |

Candidate categories to evaluate (not an endorsement): regional PSP / card acquirers serving Rwanda, mobile-money aggregators, and pan-African gateways. Re-check eligibility for a Rwanda-registered drinks retailer before choosing.

## Current implementation

| Mode                        | Behaviour                                                             |
| --------------------------- | --------------------------------------------------------------------- |
| Production / default        | Online channel rejected; WhatsApp-assisted only                       |
| Sandbox adapter (`sandbox`) | Test-only initiation + HMAC-signed webhooks; never shown as “live” UI |

Browser redirects alone are **never** proof of payment. Only verified webhook / server-to-server confirmation updates `payment_status` to `paid`.

## Go-live checklist

- [ ] Provider selected; decision table above completed with source links
- [ ] Sandbox credentials rotated; production keys in host secrets only
- [ ] `ONLINE_PAYMENT_ENABLED=true` only after webhook verification in staging
- [ ] Refund / dispute runbook documented for staff
- [ ] Customer copy never claims “paid” before verified callback
