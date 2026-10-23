-- Notification outbox: every email (and, later, WhatsApp/SMS) is written here first, then sent.
-- If a send fails it is retried with a growing delay instead of being lost, and the unique
-- dedupe_key guarantees the same notification is never queued twice.

create table if not exists public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  channel text not null check (channel in ('email', 'whatsapp', 'sms')),
  kind text not null,
  dedupe_key text not null unique,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'sent', 'skipped', 'failed')),
  attempts integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sent_at timestamptz
);

create index if not exists notification_outbox_due_idx
  on public.notification_outbox (next_attempt_at)
  where status = 'pending';

create index if not exists notification_outbox_status_idx
  on public.notification_outbox (status, updated_at);

alter table public.notification_outbox enable row level security;
-- No policies: only the server (service role) reads or writes the outbox.
