-- Phase 00: enable extensions required by later catalogue/order migrations.
-- No product or order tables are created in this phase.

create extension if not exists "pgcrypto";

comment on extension "pgcrypto" is
  'Provides gen_random_uuid() for primary keys in later migrations.';
