-- P3: storage buckets for product media + transactional bulk import RPC.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-originals',
  'product-originals',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-catalogue',
  'product-catalogue',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Originals: no public read. Authenticated admins may read for review.
drop policy if exists product_originals_admin_read on storage.objects;
create policy product_originals_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'product-originals'
    and public.is_admin()
  );

drop policy if exists product_originals_admin_write on storage.objects;
create policy product_originals_admin_write on storage.objects
  for all to authenticated
  using (
    bucket_id = 'product-originals'
    and public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[])
  )
  with check (
    bucket_id = 'product-originals'
    and public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[])
  );

-- Catalogue derivatives: public read; admin write.
drop policy if exists product_catalogue_public_read on storage.objects;
create policy product_catalogue_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'product-catalogue');

drop policy if exists product_catalogue_admin_write on storage.objects;
create policy product_catalogue_admin_write on storage.objects
  for all to authenticated
  using (
    bucket_id = 'product-catalogue'
    and public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[])
  )
  with check (
    bucket_id = 'product-catalogue'
    and public.admin_has_role(array['owner', 'manager', 'staff']::public.admin_role[])
  );

comment on table storage.buckets is
  'product-originals = private sources; product-catalogue = public derivatives only.';

-- Transactional bulk catalogue apply (service role / trusted server only).
create or replace function public.apply_bulk_catalogue_import(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  cat_id uuid;
  brand_id uuid;
  prod_id uuid;
  applied int := 0;
  slug text;
begin
  if jsonb_typeof(payload) <> 'array' then
    raise exception 'payload must be a JSON array';
  end if;

  for item in select * from jsonb_array_elements(payload)
  loop
    slug := item->>'slug';
    if slug is null or length(slug) = 0 then
      raise exception 'row missing slug';
    end if;

    cat_id := null;
    if coalesce(item->>'category_slug', '') <> '' then
      insert into public.categories (slug, name, description)
      values (
        item->>'category_slug',
        coalesce(nullif(item->>'category_slug', ''), item->>'category_slug'),
        ''
      )
      on conflict (slug) do update set updated_at = now()
      returning id into cat_id;

      if cat_id is null then
        select id into cat_id from public.categories where slug = item->>'category_slug';
      end if;
    end if;

    brand_id := null;
    if coalesce(item->>'brand_slug', '') <> '' then
      insert into public.brands (slug, name)
      values (
        item->>'brand_slug',
        coalesce(nullif(item->>'brand_name', ''), item->>'brand_slug')
      )
      on conflict (slug) do update
      set
        name = coalesce(nullif(excluded.name, ''), public.brands.name),
        updated_at = now()
      returning id into brand_id;

      if brand_id is null then
        select id into brand_id from public.brands where slug = item->>'brand_slug';
      end if;
    end if;

    insert into public.products (
      slug,
      name,
      description,
      price_rwf,
      status,
      availability,
      category_id,
      brand_id,
      is_provisional,
      published_at
    )
    values (
      slug,
      item->>'name',
      coalesce(item->>'description', ''),
      (item->>'price_rwf')::integer,
      coalesce(item->>'status', 'draft')::public.product_status,
      coalesce(item->>'availability', 'unknown')::public.product_availability,
      cat_id,
      brand_id,
      coalesce((item->>'is_provisional')::boolean, false),
      case
        when coalesce(item->>'status', 'draft') = 'published' then now()
        else null
      end
    )
    on conflict (slug) do update
    set
      name = excluded.name,
      description = excluded.description,
      price_rwf = excluded.price_rwf,
      status = excluded.status,
      availability = excluded.availability,
      category_id = excluded.category_id,
      brand_id = excluded.brand_id,
      is_provisional = excluded.is_provisional,
      published_at = case
        when excluded.status = 'published'
          then coalesce(public.products.published_at, now())
        else public.products.published_at
      end,
      updated_at = now()
    returning id into prod_id;

    if prod_id is null then
      select id into prod_id from public.products where products.slug = slug;
    end if;

    if item ? 'stock_quantity' or item ? 'availability' then
      insert into public.inventory_levels (
        product_id,
        quantity,
        availability,
        updated_at
      )
      values (
        prod_id,
        case
          when item->>'availability' = 'unknown' then null
          when item->>'stock_quantity' is null
            or item->>'stock_quantity' = ''
            or item->>'stock_quantity' = 'null'
            then case
              when item->>'availability' = 'out_of_stock' then 0
              else null
            end
          else (item->>'stock_quantity')::integer
        end,
        coalesce(item->>'availability', 'unknown')::public.product_availability,
        now()
      )
      on conflict (product_id) do update
      set
        quantity = excluded.quantity,
        availability = excluded.availability,
        updated_at = now();
    end if;

    applied := applied + 1;
  end loop;

  return jsonb_build_object('applied', applied);
end;
$$;

revoke all on function public.apply_bulk_catalogue_import(jsonb) from public;
grant execute on function public.apply_bulk_catalogue_import(jsonb) to service_role;

comment on function public.apply_bulk_catalogue_import(jsonb) is
  'P3 transactional catalogue CSV apply. Call only from trusted server with service role.';
