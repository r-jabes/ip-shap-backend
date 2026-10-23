-- Shared rate limiting (works across every server instance, unlike an in-memory counter).
-- One row per limited key (e.g. "checkout:203.0.113.5"); expired rows are swept automatically.

create table if not exists public.rate_limits (
  key text primary key,
  count integer not null default 0,
  reset_at timestamptz not null
);

create index if not exists rate_limits_reset_at_idx on public.rate_limits (reset_at);

alter table public.rate_limits enable row level security;
-- No policies: only the server (service role) may touch this table.

create or replace function public.consume_rate_limit(
  p_key text,
  p_limit integer,
  p_window_seconds integer
)
returns table (allowed boolean, retry_after integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
  v_reset timestamptz;
begin
  insert into public.rate_limits as r (key, count, reset_at)
  values (p_key, 1, now() + make_interval(secs => p_window_seconds))
  on conflict (key) do update
    set count = case when r.reset_at <= now() then 1 else r.count + 1 end,
        reset_at = case
          when r.reset_at <= now() then now() + make_interval(secs => p_window_seconds)
          else r.reset_at
        end
  returning r.count, r.reset_at into v_count, v_reset;

  -- Housekeeping: about 1 call in 50 clears rows that expired over an hour ago.
  if random() < 0.02 then
    delete from public.rate_limits where reset_at < now() - interval '1 hour';
  end if;

  allowed := v_count <= p_limit;
  retry_after := case
    when allowed then 0
    else greatest(1, ceil(extract(epoch from (v_reset - now())))::integer)
  end;
  return next;
end;
$$;

revoke all on function public.consume_rate_limit(text, integer, integer) from public, anon, authenticated;
grant execute on function public.consume_rate_limit(text, integer, integer) to service_role;
