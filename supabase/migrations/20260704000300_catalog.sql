-- Blue Wagon — Step 2: catalog.
-- Generic variant model (Blueprint flag #1): product_options / product_option_values /
-- product_variant_values, so an e-bike can vary by frame size + battery + color while
-- stationery varies by color + pack size. No hardcoded size/color columns.

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id) on delete set null,
  name text not null,
  slug text not null unique,
  sort_order integer not null default 0,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;

create index categories_parent_id_idx on public.categories (parent_id);

create trigger set_categories_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

create table public.products (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  category_id uuid references public.categories (id) on delete set null,
  base_price numeric(10, 2) not null check (base_price >= 0),
  status text not null default 'draft' check (status in ('draft', 'active', 'archived')),
  weight_oz numeric(8, 2),
  dimensions jsonb,
  -- Blueprint flag #2: freight items are excluded from live-rate checkout later
  -- (Step 8). Column only for now, no logic.
  requires_freight boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;

create index products_category_id_idx on public.products (category_id);
create index products_status_idx on public.products (status);

create trigger set_products_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  url text not null,
  alt text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.product_images enable row level security;

create index product_images_product_id_idx on public.product_images (product_id);

create trigger set_product_images_updated_at
  before update on public.product_images
  for each row execute function public.set_updated_at();

-- e.g. "Size", "Color", "Frame Size", "Battery" — per product, not global.
create table public.product_options (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  name text not null,
  unique (product_id, name),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.product_options enable row level security;

create index product_options_product_id_idx on public.product_options (product_id);

create trigger set_product_options_updated_at
  before update on public.product_options
  for each row execute function public.set_updated_at();

-- e.g. "Large", "Red", "500Wh".
create table public.product_option_values (
  id uuid primary key default gen_random_uuid(),
  option_id uuid not null references public.product_options (id) on delete cascade,
  value text not null,
  unique (option_id, value),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.product_option_values enable row level security;

create index product_option_values_option_id_idx on public.product_option_values (option_id);

create trigger set_product_option_values_updated_at
  before update on public.product_option_values
  for each row execute function public.set_updated_at();

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  sku text not null unique,
  price_override numeric(10, 2) check (price_override >= 0),
  stock_qty integer not null default 0 check (stock_qty >= 0),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.product_variants enable row level security;

create index product_variants_product_id_idx on public.product_variants (product_id);

create trigger set_product_variants_updated_at
  before update on public.product_variants
  for each row execute function public.set_updated_at();

-- join: a variant is defined by any combination of option values.
create table public.product_variant_values (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  option_value_id uuid not null references public.product_option_values (id) on delete cascade,
  unique (variant_id, option_value_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.product_variant_values enable row level security;

create index product_variant_values_variant_id_idx on public.product_variant_values (variant_id);
create index product_variant_values_option_value_id_idx on public.product_variant_values (option_value_id);

create trigger set_product_variant_values_updated_at
  before update on public.product_variant_values
  for each row execute function public.set_updated_at();
