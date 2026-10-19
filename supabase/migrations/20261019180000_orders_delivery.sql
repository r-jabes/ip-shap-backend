-- Phase 06: delivery zones, orders, immutable line snapshots, status history.
-- Stock reservation policy: reserve (decrement known qty) at order creation;
-- release on cancel / reservation expiry. See ORDER_AND_PAYMENT_LIFECYCLE.md.

create type public.fulfilment_status as enum (
  'awaiting_confirmation',
  'confirmed',
  'processing',
  'ready_for_dispatch',
  'out_for_delivery',
  'delivered',
  'cancelled'
);

create type public.payment_status as enum (
  'not_applicable',
  'unpaid',
  'pending',
  'paid',
  'failed',
  'refunded'
);

create type public.checkout_channel as enum (
  'whatsapp_assisted',
  'online_payment'
);

create table public.delivery_zones (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  fee_rwf integer check (fee_rwf is null or fee_rwf >= 0),
  is_active boolean not null default true,
  estimate_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.delivery_zones is
  'Configurable Rwanda coverage. Empty/inactive means delivery fees are unavailable — never invent nationwide fees.';
comment on column public.delivery_zones.fee_rwf is
  'Integer RWF fee, or null when fee is not yet confirmed for the zone.';

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  lookup_token text not null unique,
  channel public.checkout_channel not null,
  fulfilment_status public.fulfilment_status not null default 'awaiting_confirmation',
  payment_status public.payment_status not null,
  currency text not null default 'RWF' check (currency = 'RWF'),
  subtotal_rwf integer not null check (subtotal_rwf >= 0),
  delivery_fee_rwf integer check (delivery_fee_rwf is null or delivery_fee_rwf >= 0),
  total_rwf integer not null check (total_rwf >= 0),
  customer_name text not null,
  customer_phone text not null,
  delivery_district text,
  delivery_sector text,
  delivery_cell text,
  delivery_village text,
  delivery_directions text,
  delivery_instructions text,
  customer_notes text,
  delivery_zone_id uuid references public.delivery_zones (id) on delete set null,
  idempotency_key text not null unique,
  stock_reserved boolean not null default false,
  reservation_expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index orders_created_at_idx on public.orders (created_at desc);
create index orders_fulfilment_status_idx on public.orders (fulfilment_status);
create index orders_customer_phone_idx on public.orders (customer_phone);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  product_name_snapshot text not null,
  product_slug_snapshot text not null,
  sku_snapshot text,
  quantity integer not null check (quantity > 0),
  unit_price_rwf integer not null check (unit_price_rwf >= 0),
  line_total_rwf integer not null check (line_total_rwf >= 0),
  created_at timestamptz not null default now()
);

create index order_items_order_id_idx on public.order_items (order_id);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  from_fulfilment public.fulfilment_status,
  to_fulfilment public.fulfilment_status not null,
  from_payment public.payment_status,
  to_payment public.payment_status,
  actor_user_id uuid references auth.users (id),
  actor_label text,
  reason text not null default '',
  created_at timestamptz not null default now()
);

create index order_status_history_order_created_idx
  on public.order_status_history (order_id, created_at desc);

alter table public.delivery_zones enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;

-- Public may read active zones (no customer PII)
create policy delivery_zones_public_read on public.delivery_zones
  for select to anon, authenticated
  using (is_active = true);

create policy delivery_zones_admin_write on public.delivery_zones
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

-- Orders are not publicly listable. Service role / Edge creates them.
-- Authenticated admins may read all orders.
create policy orders_admin_read on public.orders
  for select to authenticated
  using (public.is_admin());

create policy order_items_admin_read on public.order_items
  for select to authenticated
  using (public.is_admin());

create policy order_status_history_admin_read on public.order_status_history
  for select to authenticated
  using (public.is_admin());

create policy orders_admin_update on public.orders
  for update to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

create policy order_status_history_admin_insert on public.order_status_history
  for insert to authenticated
  with check (public.is_admin());
