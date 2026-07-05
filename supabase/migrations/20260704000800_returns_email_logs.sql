-- Blue Wagon — Step 2: returns + email logs.
-- returns models the simple label-based flow; freight-item returns (flag #3) will
-- get a different path later without schema changes here.

create table public.returns (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null references public.order_items (id) on delete restrict,
  reason text,
  status text not null default 'requested'
    check (status in ('requested', 'approved', 'label_sent', 'received', 'refunded', 'rejected')),
  shippo_return_label_url text,
  refund_amount numeric(10, 2) check (refund_amount >= 0),
  refund_stripe_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.returns enable row level security;

create index returns_order_item_id_idx on public.returns (order_item_id);
create index returns_status_idx on public.returns (status);

create trigger set_returns_updated_at
  before update on public.returns
  for each row execute function public.set_updated_at();

-- written by server routes (service role) around Resend calls; admin read only.
create table public.email_logs (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  recipient text not null,
  order_id uuid references public.orders (id) on delete set null,
  resend_id text,
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.email_logs enable row level security;

create index email_logs_order_id_idx on public.email_logs (order_id);

create trigger set_email_logs_updated_at
  before update on public.email_logs
  for each row execute function public.set_updated_at();
