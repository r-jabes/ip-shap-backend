# Changelog

## 0.2.0 — Phase 02 image contracts (2026-10-19)

- Extend catalogue image schema with `processingStatus`, `zoomSrc`, `originalRef`, crop/rights notes
- Add upload boundary validators (`contracts/product-image-upload.ts`) for future endpoints
- Document private originals vs public derivatives and storage access intent
- Bump `CONTRACT_VERSION` to `0.2.0`

## 0.1.0 — Phase 00 foundation (2026-10-19)

- Establish Supabase-oriented backend repository layout
- Add Zod contracts for money, catalogue and orders (`CONTRACT_VERSION` 0.1.0)
- Add env validation helpers and Vitest coverage
- Add initial migration enabling `pgcrypto` only
- Add documentation set, Prettier/ESLint and GitHub Actions CI
- No catalogue seed data and no payment provider selection
