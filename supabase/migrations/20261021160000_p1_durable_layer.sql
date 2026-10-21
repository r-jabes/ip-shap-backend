-- P1: featured catalogue fields, manager role, lookup token hash, policy alignment.
-- Opaque order.reference already unique; public order listing remains denied to anon.

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

-- Align write policies: manager has staff-equivalent catalogue/inventory/order rights.
-- Owners retain admin_profiles management.

drop policy if exists inventory_admin_write on public.inventory_levels;
create policy inventory_admin_write on public.inventory_levels
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists stock_adjustments_admin_insert on public.stock_adjustments;
create policy stock_adjustments_admin_insert on public.stock_adjustments
  for insert to authenticated
  with check (
    public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[])
    and actor_user_id = auth.uid()
  );

drop policy if exists products_admin_write on public.products;
create policy products_admin_write on public.products
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists product_images_admin_write on public.product_images;
create policy product_images_admin_write on public.product_images
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists categories_admin_write on public.categories;
create policy categories_admin_write on public.categories
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists brands_admin_write on public.brands;
create policy brands_admin_write on public.brands
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists product_slug_redirects_admin_write on public.product_slug_redirects;
create policy product_slug_redirects_admin_write on public.product_slug_redirects
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists delivery_zones_admin_write on public.delivery_zones;
create policy delivery_zones_admin_write on public.delivery_zones
  for all to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

drop policy if exists orders_admin_update on public.orders;
create policy orders_admin_update on public.orders
  for update to authenticated
  using (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[]));

-- Explicit deny note: anon must never SELECT orders (no policy = deny).
comment on table public.orders is
  'Customer orders. No anon SELECT policy — lookup goes through server with reference + token.';
