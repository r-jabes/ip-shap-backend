-- Phase 07: payment attempts + webhook idempotency. No live provider credentials.

alter type public.payment_status add value if not exists 'cancelled';

create type public.payment_attempt_status as enum (
  'unpaid',
  'pending',
  'paid',
  'failed',
  'cancelled',
  'refunded'
);

create table public.payment_attempts (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  provider text not null,
  provider_attempt_id text not null,
  status public.payment_attempt_status not null default 'pending',
  amount_rwf integer not null check (amount_rwf >= 0),
  currency text not null default 'RWF' check (currency = 'RWF'),
  mode text not null check (mode in ('sandbox', 'live')),
  idempotency_key text not null,
  redirect_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_attempt_id),
  unique (provider, idempotency_key)
);

create index payment_attempts_order_id_idx on public.payment_attempts (order_id);

create table public.payment_webhook_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  provider_event_id text not null,
  payload jsonb not null default '{}'::jsonb,
  processed_at timestamptz not null default now(),
  unique (provider, provider_event_id)
);

comment on table public.payment_webhook_events is
  'Idempotency store for provider webhooks — duplicate event ids are no-ops.';

alter table public.payment_attempts enable row level security;
alter table public.payment_webhook_events enable row level security;

create policy payment_attempts_admin_read on public.payment_attempts
  for select to authenticated
  using (public.is_admin());

create policy payment_webhook_events_admin_read on public.payment_webhook_events
  for select to authenticated
  using (public.is_admin());
