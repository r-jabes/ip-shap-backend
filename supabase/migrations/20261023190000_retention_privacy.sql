-- Keeps the database small and respects customer privacy.
--
-- 1. purge_old_history: deletes stock history and the admin activity log once they are older than
--    the retention period (default 12 months). Run by the daily maintenance job.
-- 2. erase_customer_data: removes a customer's personal details on request. Finished orders are
--    kept for the shop's accounting, but the name, phone, address and notes are blanked, and any
--    "tell me when it is back" requests for that phone number are deleted. Orders still in
--    progress are never touched.

create or replace function public.purge_old_history(p_months integer default 12)
returns table (stock_rows integer, audit_rows integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  cutoff timestamptz := now() - make_interval(months => greatest(p_months, 3));
  stock_count integer;
  audit_count integer;
begin
  delete from public.stock_adjustments where created_at < cutoff;
  get diagnostics stock_count = row_count;
  delete from public.audit_events where created_at < cutoff;
  get diagnostics audit_count = row_count;
  return query select stock_count, audit_count;
end;
$$;

revoke all on function public.purge_old_history(integer) from public, anon, authenticated;
grant execute on function public.purge_old_history(integer) to service_role;

create or replace function public.erase_customer_data(p_phone_last9 text)
returns table (orders_erased integer, orders_in_progress integer, requests_deleted integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  digits text := regexp_replace(coalesce(p_phone_last9, ''), '\D', '', 'g');
  erased integer := 0;
  open_count integer := 0;
  deleted integer := 0;
begin
  if char_length(digits) < 9 then
    raise exception 'A full phone number is required';
  end if;
  digits := right(digits, 9);

  update public.orders
     set customer_name = 'Removed on request',
         customer_phone = 'removed',
         delivery_district = null,
         delivery_sector = null,
         delivery_cell = null,
         delivery_village = null,
         delivery_directions = null,
         delivery_instructions = null,
         customer_notes = null,
         updated_at = now()
   where right(regexp_replace(customer_phone, '\D', '', 'g'), 9) = digits
     and fulfilment_status in ('delivered', 'cancelled');
  get diagnostics erased = row_count;

  select count(*)::integer into open_count
    from public.orders
   where right(regexp_replace(customer_phone, '\D', '', 'g'), 9) = digits
     and fulfilment_status not in ('delivered', 'cancelled');

  delete from public.restock_requests
   where kind = 'phone'
     and right(regexp_replace(contact, '\D', '', 'g'), 9) = digits;
  get diagnostics deleted = row_count;

  return query select erased, open_count, deleted;
end;
$$;

revoke all on function public.erase_customer_data(text) from public, anon, authenticated;
grant execute on function public.erase_customer_data(text) to service_role;
