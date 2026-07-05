-- Blue Wagon — Step 2: carts.
-- Guest carts are keyed by session_token and accessed through server routes using the
-- service role (RLS only covers logged-in owners; anon clients can't prove token ownership).

create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  session_token text unique,
  status text not null default 'active' check (status in ('active', 'converted', 'abandoned')),
  check (user_id is not null or session_token is not null),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.carts enable row level security;

create index carts_user_id_idx on public.carts (user_id);

create trigger set_carts_updated_at
  before update on public.carts
  for each row execute function public.set_updated_at();

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts (id) on delete cascade,
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  qty integer not null check (qty > 0),
  unique (cart_id, variant_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.cart_items enable row level security;

create index cart_items_cart_id_idx on public.cart_items (cart_id);
create index cart_items_variant_id_idx on public.cart_items (variant_id);

create trigger set_cart_items_updated_at
  before update on public.cart_items
  for each row execute function public.set_updated_at();
