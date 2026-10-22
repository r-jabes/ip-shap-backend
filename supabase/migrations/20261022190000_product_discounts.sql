-- Product discounts: price_rwf stays the price customers pay.
-- compare_at_price_rwf holds the regular ("was") price while a discount is active.

alter table public.products
  add column if not exists compare_at_price_rwf integer;

-- Optional product identifiers entered in the admin portal.
alter table public.products
  add column if not exists sku text,
  add column if not exists barcode text;

alter table public.products
  add constraint products_compare_at_above_price check (
    compare_at_price_rwf is null or compare_at_price_rwf > price_rwf
  );

-- A price written without touching compare_at (for example by a CSV import) is a new
-- regular price, so any active discount is cleared instead of becoming inconsistent.
create or replace function public.clear_discount_on_plain_price_change()
returns trigger
language plpgsql
as $$
begin
  if new.price_rwf is distinct from old.price_rwf
     and new.compare_at_price_rwf is not distinct from old.compare_at_price_rwf then
    new.compare_at_price_rwf := null;
  end if;
  return new;
end;
$$;

drop trigger if exists products_clear_discount_on_price_change on public.products;
create trigger products_clear_discount_on_price_change
  before update on public.products
  for each row execute function public.clear_discount_on_plain_price_change();
