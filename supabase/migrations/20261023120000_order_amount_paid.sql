-- Record how much was actually received when staff mark an order as paid.
-- It can differ from the order total (for example a discount agreed with the customer).
-- Null means "no manual payment recorded"; existing paid orders stay null.

alter table public.orders
  add column if not exists amount_paid_rwf integer
    check (amount_paid_rwf is null or amount_paid_rwf >= 0);

comment on column public.orders.amount_paid_rwf is
  'Amount received in RWF when payment was recorded by staff. May differ from total_rwf.';
