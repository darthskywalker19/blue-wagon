-- Blue Wagon — Step 2: profiles (extends auth.users), addresses, admin_roles,
-- and the security-definer role helpers used by RLS policies everywhere else.

-- profiles: one row per auth user, id = auth uid.
-- default_address_id FK is added after addresses exists (circular reference).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  phone text,
  default_address_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- addresses: saved shipping addresses, owned by a user.
create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  label text,
  line1 text not null,
  line2 text,
  city text not null,
  state text not null,
  zip text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.addresses enable row level security;

create index addresses_user_id_idx on public.addresses (user_id);

create trigger set_addresses_updated_at
  before update on public.addresses
  for each row execute function public.set_updated_at();

alter table public.profiles
  add constraint profiles_default_address_id_fkey
  foreign key (default_address_id) references public.addresses (id) on delete set null;

-- admin_roles: presence of a row makes a user an admin; absence = regular customer.
create table public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'manager', 'staff')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.admin_roles enable row level security;

create trigger set_admin_roles_updated_at
  before update on public.admin_roles
  for each row execute function public.set_updated_at();

-- security definer so policies on admin_roles itself (and every other table)
-- can call these without recursive RLS evaluation.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_roles where user_id = auth.uid()
  );
$$;

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_roles where user_id = auth.uid() and role = 'owner'
  );
$$;
