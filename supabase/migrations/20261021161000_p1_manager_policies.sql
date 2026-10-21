-- P1 (continued): align write policies after 'manager' enum value is committed.

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
