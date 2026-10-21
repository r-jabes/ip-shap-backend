-- Minimal published catalogue for staging smoke tests (P1).
-- Apply after migrations: supabase db query -f supabase/seed/p1_minimal_catalogue.sql
-- or paste into SQL editor. Idempotent on fixed UUIDs.

insert into public.categories (id, slug, name, description)
values (
  '11111111-1111-4111-8111-111111111111',
  'wine',
  'Wine',
  'Red, white and sparkling.'
)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description;

insert into public.brands (id, slug, name)
values (
  '22222222-2222-4222-8222-222222222222',
  'ip-shap-house',
  'IP SHAP'
)
on conflict (slug) do update
set name = excluded.name;

insert into public.products (
  id,
  slug,
  name,
  description,
  price_rwf,
  status,
  availability,
  category_id,
  brand_id,
  is_provisional,
  is_featured,
  featured_sort,
  published_at
)
values (
  '33333333-3333-4333-8333-333333333333',
  'seed-house-red',
  'House Red (seed)',
  'Staging seed product — replace with real catalogue before launch.',
  15000,
  'published',
  'in_stock',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  false,
  true,
  0,
  now()
)
on conflict (slug) do update
set
  name = excluded.name,
  description = excluded.description,
  price_rwf = excluded.price_rwf,
  status = excluded.status,
  availability = excluded.availability,
  is_featured = excluded.is_featured,
  featured_sort = excluded.featured_sort,
  published_at = coalesce(public.products.published_at, excluded.published_at);

insert into public.product_images (
  id,
  product_id,
  role,
  src,
  alt,
  width,
  height,
  sort_order,
  processing_status
)
values (
  '44444444-4444-4444-8444-444444444444',
  '33333333-3333-4333-8333-333333333333',
  'catalogue_primary',
  '/branding/app-icon.png',
  'House Red seed product',
  158,
  155,
  0,
  'approved_for_catalogue'
)
on conflict (id) do update
set src = excluded.src,
    alt = excluded.alt,
    processing_status = excluded.processing_status;

insert into public.inventory_levels (
  product_id,
  quantity,
  availability,
  updated_at
)
values (
  '33333333-3333-4333-8333-333333333333',
  12,
  'in_stock',
  now()
)
on conflict (product_id) do update
set quantity = excluded.quantity,
    availability = excluded.availability,
    updated_at = now();
