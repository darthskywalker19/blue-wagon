-- Blue Wagon — Step 2: reviews.
-- Flag #6 resolution: every review is anchored to a purchased order item
-- (order_item_id NOT NULL + unique = verified purchase, one review per item bought).
-- user_id stays nullable; guest reviewers are identified by guest_email and submit
-- through a server route (service role) that verifies order number + email.

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  user_id uuid references auth.users (id) on delete set null,
  guest_email text,
  order_item_id uuid not null unique references public.order_items (id) on delete restrict,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  verified_purchase boolean not null default true,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  check (user_id is not null or guest_email is not null),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

create index reviews_product_id_status_idx on public.reviews (product_id, status);
create index reviews_user_id_idx on public.reviews (user_id);

create trigger set_reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();
