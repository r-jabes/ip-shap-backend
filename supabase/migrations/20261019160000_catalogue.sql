-- Phase 04: catalogue schema for 300+ published products.
-- No seed data. Demo fixtures stay in the frontend demo gate.

create extension if not exists "pg_trgm";
create extension if not exists "unaccent";

create type public.product_status as enum (
  'draft',
  'demo',
  'published',
  'archived'
);

create type public.product_availability as enum (
  'in_stock',
  'low_stock',
  'out_of_stock',
  'unknown'
);

create type public.product_image_role as enum (
  'catalogue_primary',
  'catalogue_secondary',
  'editorial',
  'thumbnail',
  'zoom'
);

create type public.image_processing_status as enum (
  'source_received',
  'needs_review',
  'approved_for_catalogue',
  'rejected',
  'archived'
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.brands (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  price_rwf integer not null check (price_rwf >= 0),
  status public.product_status not null default 'draft',
  availability public.product_availability not null default 'unknown',
  category_id uuid references public.categories (id) on delete set null,
  brand_id uuid references public.brands (id) on delete set null,
  is_provisional boolean not null default false,
  search_document text generated always as (
    coalesce(name, '') || ' ' || coalesce(description, '')
  ) stored,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint products_published_requires_timestamp check (
    status <> 'published' or published_at is not null
  )
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  role public.product_image_role not null default 'catalogue_primary',
  src text not null,
  zoom_src text,
  alt text not null,
  width integer not null check (width > 0),
  height integer not null check (height > 0),
  sort_order integer not null default 0 check (sort_order >= 0),
  processing_status public.image_processing_status not null default 'needs_review',
  original_ref text,
  source_filename text,
  crop_instructions text,
  rights_note text,
  is_shared_multi_product_photo boolean not null default false,
  needs_client_confirmation boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_slug_redirects (
  old_slug text primary key,
  product_id uuid not null references public.products (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Query-pattern indexes (list/filter/sort/search at 300+ scale)
create index products_status_published_at_idx
  on public.products (status, published_at desc nulls last)
  where status = 'published';

create index products_category_status_idx
  on public.products (category_id, status);

create index products_brand_status_idx
  on public.products (brand_id, status);

create index products_price_status_idx
  on public.products (price_rwf, status);

create index products_availability_status_idx
  on public.products (availability, status);

create index products_name_trgm_idx
  on public.products using gin (name gin_trgm_ops);

create index products_search_document_trgm_idx
  on public.products using gin (search_document gin_trgm_ops);

create index product_images_product_sort_idx
  on public.product_images (product_id, sort_order);

create index product_images_public_derivatives_idx
  on public.product_images (product_id, role)
  where processing_status in ('needs_review', 'approved_for_catalogue');

create index product_slug_redirects_product_id_idx
  on public.product_slug_redirects (product_id);

comment on table public.products is
  'Sellable SKUs. Public reads must filter status = published only.';
comment on column public.products.price_rwf is
  'Integer Rwandan Francs. Never store fractional money.';
comment on column public.products.availability is
  'Explicit stock model. unknown must never be treated as in_stock.';
comment on table public.product_slug_redirects is
  'Permanent slug change map for 301/canonical handling.';

-- Search helper: accent/case-insensitive containment via unaccent + ILIKE/trgm.
-- Strategy: pg_trgm similarity / ILIKE on unaccented fields (not Postgres FTS tsvector).
-- Limits: good for short catalogue queries; not ranked natural-language search;
-- operators should keep names consistent. Tune similarity threshold in app (default 0.2).
create or replace function public.catalogue_search_normalize(input text)
returns text
language sql
immutable
parallel safe
as $$
  select lower(public.unaccent(coalesce(input, '')));
$$;

alter table public.categories enable row level security;
alter table public.brands enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_slug_redirects enable row level security;

-- Anonymous/authenticated public read of taxonomy
create policy categories_public_read on public.categories
  for select to anon, authenticated
  using (true);

create policy brands_public_read on public.brands
  for select to anon, authenticated
  using (true);

-- Published products only on public APIs
create policy products_public_read_published on public.products
  for select to anon, authenticated
  using (status = 'published');

create policy product_images_public_read_published on public.product_images
  for select to anon, authenticated
  using (
    exists (
      select 1
      from public.products p
      where p.id = product_id
        and p.status = 'published'
    )
    and processing_status in ('needs_review', 'approved_for_catalogue')
  );

create policy product_slug_redirects_public_read on public.product_slug_redirects
  for select to anon, authenticated
  using (
    exists (
      select 1
      from public.products p
      where p.id = product_id
        and p.status = 'published'
    )
  );
