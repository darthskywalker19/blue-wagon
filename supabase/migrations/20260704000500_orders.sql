-- Blue Wagon — Step 2: orders.
-- Orders are created server-side at checkout (service role); RLS gives customers
-- read access to their own orders. Guest orders carry guest_email (flag #4: guest
-- lookup by order number + email happens through server routes).

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  guest_email text,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'fulfilled', 'shipped', 'delivered', 'cancelled')),
  subtotal numeric(10, 2) not null default 0,
  tax_total numeric(10, 2) not null default 0,
  shipping_total numeric(10, 2) not null default 0,
  discount_total numeric(10, 2) not null default 0,
  grand_total numeric(10, 2) not null default 0,
  shipping_address jsonb,
  billing_address jsonb,
  stripe_payment_intent_id text,
  shippo_shipment_id text,
  check (user_id is not null or guest_email is not null),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders enable row level security;

create index orders_user_id_idx on public.orders (user_id);
create index orders_status_idx on public.orders (status);
-- webhook idempotency: one order per payment intent
create unique index orders_stripe_payment_intent_id_key
  on public.orders (stripe_payment_intent_id)
  where stripe_payment_intent_id is not null;

create trigger set_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  -- restrict: purchase history must survive catalog cleanup (archive products instead)
  variant_id uuid not null references public.product_variants (id) on delete restrict,
  qty integer not null check (qty > 0),
  unit_price_at_purchase numeric(10, 2) not null check (unit_price_at_purchase >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.order_items enable row level security;

create index order_items_order_id_idx on public.order_items (order_id);
create index order_items_variant_id_idx on public.order_items (variant_id);

create trigger set_order_items_updated_at
  before update on public.order_items
  for each row execute function public.set_updated_at();
