-- P4: atomic stock confirm/restore and inventory adjust with row locks.

alter table public.orders
  add column if not exists stock_committed boolean not null default false;

comment on column public.orders.stock_committed is
  'True after fulfilment confirm decremented on-hand inventory. Cancel restores when true.';

create index if not exists inventory_levels_availability_idx
  on public.inventory_levels (availability);

-- Decrement on-hand stock for a confirmed order (idempotent).
create or replace function public.confirm_order_stock(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  ord public.orders%rowtype;
  item public.order_items%rowtype;
  inv public.inventory_levels%rowtype;
  decremented int := 0;
begin
  select * into ord
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'order not found';
  end if;

  if ord.stock_committed then
    return jsonb_build_object('ok', true, 'already_committed', true, 'decremented', 0);
  end if;

  for item in
    select * from public.order_items where order_id = p_order_id
  loop
    if item.product_id is null then
      continue;
    end if;

    select * into inv
    from public.inventory_levels
    where product_id = item.product_id
    for update;

    if not found then
      continue; -- no inventory row → treat as unknown / unmanaged
    end if;

    -- unknown availability must never be treated as sellable counted stock
    if inv.availability = 'unknown' or inv.quantity is null then
      continue;
    end if;

    if inv.quantity < item.quantity then
      raise exception 'insufficient stock for product % (have %, need %)',
        item.product_id, inv.quantity, item.quantity;
    end if;

    update public.inventory_levels
    set
      quantity = inv.quantity - item.quantity,
      availability = case
        when inv.quantity - item.quantity = 0 then 'out_of_stock'::public.product_availability
        when inv.quantity - item.quantity <= 5 then 'low_stock'::public.product_availability
        else inv.availability
      end,
      updated_at = now()
    where product_id = item.product_id;

    insert into public.stock_adjustments (
      product_id,
      actor_user_id,
      previous_quantity,
      new_quantity,
      previous_availability,
      new_availability,
      reason
    )
    values (
      item.product_id,
      auth.uid(),
      inv.quantity,
      inv.quantity - item.quantity,
      inv.availability,
      case
        when inv.quantity - item.quantity = 0 then 'out_of_stock'::public.product_availability
        when inv.quantity - item.quantity <= 5 then 'low_stock'::public.product_availability
        else inv.availability
      end,
      'order confirm ' || ord.reference
    );

    decremented := decremented + item.quantity;
  end loop;

  update public.orders
  set
    stock_committed = true,
    stock_reserved = false,
    reservation_expires_at = null,
    updated_at = now()
  where id = p_order_id;

  return jsonb_build_object(
    'ok', true,
    'already_committed', false,
    'decremented', decremented
  );
end;
$$;

-- Restore on-hand stock when cancelling a committed order (idempotent).
create or replace function public.restore_order_stock(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  ord public.orders%rowtype;
  item public.order_items%rowtype;
  inv public.inventory_levels%rowtype;
  restored int := 0;
begin
  select * into ord
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'order not found';
  end if;

  if not ord.stock_committed then
    return jsonb_build_object('ok', true, 'already_restored', true, 'restored', 0);
  end if;

  for item in
    select * from public.order_items where order_id = p_order_id
  loop
    if item.product_id is null then
      continue;
    end if;

    select * into inv
    from public.inventory_levels
    where product_id = item.product_id
    for update;

    if not found or inv.availability = 'unknown' or inv.quantity is null then
      continue;
    end if;

    update public.inventory_levels
    set
      quantity = inv.quantity + item.quantity,
      availability = case
        when inv.quantity + item.quantity > 5
          and inv.availability in ('out_of_stock', 'low_stock')
          then 'in_stock'::public.product_availability
        when inv.quantity + item.quantity > 0
          and inv.availability = 'out_of_stock'
          then 'low_stock'::public.product_availability
        else inv.availability
      end,
      updated_at = now()
    where product_id = item.product_id;

    insert into public.stock_adjustments (
      product_id,
      actor_user_id,
      previous_quantity,
      new_quantity,
      previous_availability,
      new_availability,
      reason
    )
    values (
      item.product_id,
      auth.uid(),
      inv.quantity,
      inv.quantity + item.quantity,
      inv.availability,
      case
        when inv.quantity + item.quantity > 5
          and inv.availability in ('out_of_stock', 'low_stock')
          then 'in_stock'::public.product_availability
        when inv.quantity + item.quantity > 0
          and inv.availability = 'out_of_stock'
          then 'low_stock'::public.product_availability
        else inv.availability
      end,
      'order cancel restore ' || ord.reference
    );

    restored := restored + item.quantity;
  end loop;

  update public.orders
  set
    stock_committed = false,
    updated_at = now()
  where id = p_order_id;

  return jsonb_build_object(
    'ok', true,
    'already_restored', false,
    'restored', restored
  );
end;
$$;

-- Atomic inventory adjust with optimistic expected quantity.
create or replace function public.adjust_inventory_level(
  p_product_id uuid,
  p_new_quantity integer,
  p_new_availability public.product_availability,
  p_reason text,
  p_expected_quantity integer default null,
  p_actor_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  inv public.inventory_levels%rowtype;
  actor uuid;
begin
  if p_reason is null or char_length(trim(p_reason)) < 1 then
    raise exception 'reason required';
  end if;
  if p_new_quantity is not null and p_new_quantity < 0 then
    raise exception 'negative stock is not allowed';
  end if;
  if p_new_availability = 'unknown' and p_new_quantity is not null then
    raise exception 'unknown availability requires null quantity';
  end if;

  actor := coalesce(p_actor_user_id, auth.uid());

  insert into public.inventory_levels (product_id, quantity, availability, updated_at)
  values (p_product_id, null, 'unknown', now())
  on conflict (product_id) do nothing;

  select * into inv
  from public.inventory_levels
  where product_id = p_product_id
  for update;

  if p_expected_quantity is not null and inv.quantity is distinct from p_expected_quantity then
    raise exception 'stock changed since you loaded the form — refresh and retry';
  end if;

  update public.inventory_levels
  set
    quantity = case
      when p_new_availability = 'out_of_stock' and p_new_quantity is null then 0
      else p_new_quantity
    end,
    availability = p_new_availability,
    updated_at = now(),
    updated_by = actor
  where product_id = p_product_id;

  insert into public.stock_adjustments (
    product_id,
    actor_user_id,
    previous_quantity,
    new_quantity,
    previous_availability,
    new_availability,
    reason
  )
  values (
    p_product_id,
    actor,
    inv.quantity,
    case
      when p_new_availability = 'out_of_stock' and p_new_quantity is null then 0
      else p_new_quantity
    end,
    inv.availability,
    p_new_availability,
    trim(p_reason)
  );

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.confirm_order_stock(uuid) from public;
revoke all on function public.restore_order_stock(uuid) from public;
revoke all on function public.adjust_inventory_level(uuid, integer, public.product_availability, text, integer, uuid) from public;

grant execute on function public.confirm_order_stock(uuid) to service_role;
grant execute on function public.restore_order_stock(uuid) to service_role;
grant execute on function public.adjust_inventory_level(uuid, integer, public.product_availability, text, integer, uuid) to service_role;

-- Allow null actor for service-role / system stock events (confirm/restore).
alter table public.stock_adjustments
  alter column actor_user_id drop not null;
