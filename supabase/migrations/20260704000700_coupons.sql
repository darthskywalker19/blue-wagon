-- Blue Wagon — Step 2: coupons.
-- No public read policy on purpose: codes are validated server-side at checkout
-- (Step 13), never listed to clients.

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_type text not null check (discount_type in ('percent', 'fixed')),
  discount_value numeric(10, 2) not null check (discount_value > 0),
  check (discount_type <> 'percent' or discount_value <= 100),
  min_order_amount numeric(10, 2),
  usage_limit integer check (usage_limit > 0),
  usage_count integer not null default 0 check (usage_count >= 0),
  expires_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.coupons enable row level security;

create trigger set_coupons_updated_at
  before update on public.coupons
  for each row execute function public.set_updated_at();

create table public.coupon_usages (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete cascade,
  user_id uuid references auth.users (id) on delete set null,
  guest_email text,
  unique (coupon_id, order_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.coupon_usages enable row level security;

create index coupon_usages_coupon_id_idx on public.coupon_usages (coupon_id);
create index coupon_usages_order_id_idx on public.coupon_usages (order_id);

create trigger set_coupon_usages_updated_at
  before update on public.coupon_usages
  for each row execute function public.set_updated_at();
