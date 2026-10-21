# Backend documentation

How the IP SHAP data plane (Supabase + contracts) is structured and operated.

## Start here

| Doc | Contents |
| --- | -------- |
| [../README.md](../README.md) | Stack, migrate/seed, scripts |
| [ENVIRONMENT.md](./ENVIRONMENT.md) | Backend env and CLI notes |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Repo layout and responsibility split |
| [OPERATIONS.md](./OPERATIONS.md) | Migrations, stock, admin seed, backups |

## Data & contracts

| Doc | Contents |
| --- | -------- |
| [DATA_MODEL.md](./DATA_MODEL.md) | Tables and relationships |
| [API_CONTRACTS.md](./API_CONTRACTS.md) | Zod contracts and versioning |
| [ORDER_AND_PAYMENT_LIFECYCLE.md](./ORDER_AND_PAYMENT_LIFECYCLE.md) | Order states and stock timing |
| [SEARCH.md](./SEARCH.md) | Catalogue suggest / `pg_trgm` |
| [NOTIFICATIONS.md](./NOTIFICATIONS.md) | Staff notify expectations |
| [PAYMENTS.md](./PAYMENTS.md) | Payment stubs (MoMo out of scope) |
| [PAYMENT_PROVIDER_DECISION.md](./PAYMENT_PROVIDER_DECISION.md) | Provider decision record |

## Security & release

| Doc | Contents |
| --- | -------- |
| [SECURITY.md](./SECURITY.md) | Backend security rules |
| [RLS_INVENTORY.md](./RLS_INVENTORY.md) | RLS coverage map |
| [PRIVACY_AND_RETENTION.md](./PRIVACY_AND_RETENTION.md) | PII posture |
| [BACKUP_RESTORE.md](./BACKUP_RESTORE.md) | Staging restore drill |
| [TESTING.md](./TESTING.md) | Contract/validation tests |
| [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) | Release gate |
| [RWANDA_LAUNCH_CHECKLIST.md](./RWANDA_LAUNCH_CHECKLIST.md) | Business/legal launch notes |
| [DECISIONS.md](./DECISIONS.md) | ADRs |
| [CHANGELOG.md](./CHANGELOG.md) | Version history |

Companion UI: `../../frontend/documentation/README.md`.
