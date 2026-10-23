-- "Tell me when it is back" requests from the storefront. One row per shopper per product:
-- the unique (product_id, contact) pair stops duplicates and repeat spam. When stock returns,
-- email requests get a branded email through the notification outbox and are marked notified;
-- phone requests wait for staff, who see them on the product page in the admin.

create table if not exists public.restock_requests (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  kind text not null check (kind in ('email', 'phone')),
  -- Lower-cased email, or the phone number as typed without spaces.
  contact text not null check (char_length(contact) between 5 and 200),
  created_at timestamptz not null default now(),
  notified_at timestamptz,
  unique (product_id, contact)
);

create index if not exists restock_requests_waiting_idx
  on public.restock_requests (product_id)
  where notified_at is null;

create index if not exists restock_requests_created_idx
  on public.restock_requests (created_at);

alter table public.restock_requests enable row level security;
-- No policies: only the server (service role) reads or writes these rows.
