-- Phase 05: admin roles, inventory, stock audit, sensitive audit events.
-- No public admin registration. Bootstrap owners via documented ops process.

create type public.admin_role as enum ('owner', 'staff');

create table public.admin_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.admin_role not null default 'staff',
  display_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users (id)
);

comment on table public.admin_profiles is
  'Privileged operators only. Rows are created by an existing owner/service role — never via public signup.';

create table public.inventory_levels (
  product_id uuid primary key references public.products (id) on delete cascade,
  quantity integer check (quantity is null or quantity >= 0),
  availability public.product_availability not null default 'unknown',
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id),
  constraint inventory_unknown_allows_null_qty check (
    (availability = 'unknown' and quantity is null)
    or (availability <> 'unknown')
  )
);

comment on column public.inventory_levels.quantity is
  'Non-negative integer units, or null when availability is unknown. Negative stock is not allowed.';

create table public.stock_adjustments (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  actor_user_id uuid not null references auth.users (id),
  previous_quantity integer,
  new_quantity integer,
  previous_availability public.product_availability not null,
  new_availability public.product_availability not null,
  reason text not null check (char_length(reason) between 1 and 500),
  created_at timestamptz not null default now()
);

create index stock_adjustments_product_created_idx
  on public.stock_adjustments (product_id, created_at desc);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users (id),
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_events_created_idx on public.audit_events (created_at desc);
create index audit_events_actor_idx on public.audit_events (actor_user_id, created_at desc);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_profiles ap
    where ap.user_id = auth.uid()
      and ap.is_active = true
  );
$$;

create or replace function public.admin_has_role(allowed public.admin_role[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_profiles ap
    where ap.user_id = auth.uid()
      and ap.is_active = true
      and ap.role = any (allowed)
  );
$$;

alter table public.admin_profiles enable row level security;
alter table public.inventory_levels enable row level security;
alter table public.stock_adjustments enable row level security;
alter table public.audit_events enable row level security;

-- Admins can read their own profile; owners can read all profiles.
create policy admin_profiles_self_read on public.admin_profiles
  for select to authenticated
  using (user_id = auth.uid() or public.admin_has_role(array['owner']::public.admin_role[]));

create policy admin_profiles_owner_write on public.admin_profiles
  for all to authenticated
  using (public.admin_has_role(array['owner']::public.admin_role[]))
  with check (public.admin_has_role(array['owner']::public.admin_role[]));

-- Inventory readable by any admin; writable by owner/staff
create policy inventory_admin_read on public.inventory_levels
  for select to authenticated
  using (public.is_admin());

create policy inventory_admin_write on public.inventory_levels
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

create policy stock_adjustments_admin_read on public.stock_adjustments
  for select to authenticated
  using (public.is_admin());

create policy stock_adjustments_admin_insert on public.stock_adjustments
  for insert to authenticated
  with check (
    public.admin_has_role(array['owner', 'staff']::public.admin_role[])
    and actor_user_id = auth.uid()
  );

create policy audit_events_admin_read on public.audit_events
  for select to authenticated
  using (public.is_admin());

create policy audit_events_admin_insert on public.audit_events
  for insert to authenticated
  with check (public.is_admin() and (actor_user_id is null or actor_user_id = auth.uid()));

-- Extend product write policies for admins (public read already exists)
create policy products_admin_write on public.products
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

create policy product_images_admin_write on public.product_images
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

create policy categories_admin_write on public.categories
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

create policy brands_admin_write on public.brands
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));

create policy product_slug_redirects_admin_write on public.product_slug_redirects
  for all to authenticated
  using (public.admin_has_role(array['owner', 'staff']::public.admin_role[]))
  with check (public.admin_has_role(array['owner', 'staff']::public.admin_role[]));
