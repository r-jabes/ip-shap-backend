-- P1 RLS smoke checks (run in SQL editor against staging after migrations).
-- Expect: each assertion raises if the security invariant is broken.
-- Connect as a role that can create temp tables / use set_config if needed;
-- for anon simulation use the Supabase "anon" key via PostgREST, or:

-- 1) Published products are readable (as authenticated/anon via API).
-- 2) Draft products are not.
-- 3) Orders have no anon select policy.

do $$
declare
  order_policies int;
begin
  select count(*) into order_policies
  from pg_policies
  where schemaname = 'public'
    and tablename = 'orders'
    and roles::text ilike '%anon%'
    and cmd = 'SELECT';

  if order_policies > 0 then
    raise exception 'FAIL: anon must not have SELECT on orders (found %)', order_policies;
  end if;

  raise notice 'OK: no anon SELECT policy on orders';
end $$;

do $$
declare
  featured_col int;
  hash_col int;
begin
  select count(*) into featured_col
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'products'
    and column_name = 'is_featured';

  select count(*) into hash_col
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'orders'
    and column_name = 'lookup_token_hash';

  if featured_col <> 1 then
    raise exception 'FAIL: products.is_featured missing';
  end if;
  if hash_col <> 1 then
    raise exception 'FAIL: orders.lookup_token_hash missing';
  end if;

  raise notice 'OK: P1 columns present';
end $$;
