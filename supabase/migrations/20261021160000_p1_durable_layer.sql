-- P1: featured catalogue fields, manager role enum, lookup token hash.
-- Policies that reference 'manager' are in the next migration — Postgres
-- cannot use a newly added enum value in the same transaction (55P04).

-- Manager role (owner > manager > staff). Safe if re-run.
do $$
begin
  alter type public.admin_role add value 'manager';
exception
  when duplicate_object then null;
end $$;

alter table public.products
  add column if not exists is_featured boolean not null default false;

alter table public.products
  add column if not exists featured_sort integer not null default 0
    check (featured_sort >= 0);

create index if not exists products_featured_sort_idx
  on public.products (featured_sort asc, published_at desc nulls last)
  where is_featured = true and status = 'published';

comment on column public.products.is_featured is
  'When true and published, eligible for home featured rails.';
comment on column public.products.featured_sort is
  'Lower sorts first among featured products.';

-- Prefer hashing lookup tokens at rest (app writes hash from P5). Plain token
-- column remains until cutover; unique hash when present.
alter table public.orders
  add column if not exists lookup_token_hash text;

create unique index if not exists orders_lookup_token_hash_uidx
  on public.orders (lookup_token_hash)
  where lookup_token_hash is not null;

create index if not exists products_slug_status_idx
  on public.products (slug, status);

comment on table public.orders is
  'Customer orders. No anon SELECT policy — lookup goes through server with reference + token.';
