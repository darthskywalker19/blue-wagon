-- Blue Wagon — Step 2: RLS policies.
-- Model:
--   * public (anon + authenticated) read: active products + their satellite tables,
--     categories, approved reviews.
--   * customers read/write only their own profiles, addresses, carts, cart items;
--     read their own orders, order items, reviews, returns.
--   * admin writes require a row in admin_roles (public.is_admin(), security definer);
--     role management itself is owner-only (public.is_owner()).
--   * checkout, guest carts, guest reviews, and email logging go through server
--     routes with the service role, which bypasses RLS.
-- (select auth.uid()) is wrapped in a scalar subquery so Postgres caches it per
-- statement instead of re-evaluating per row.

-- profiles ------------------------------------------------------------------
create policy "profiles_select_own_or_admin" on public.profiles
  for select using (id = (select auth.uid()) or public.is_admin());

create policy "profiles_insert_own" on public.profiles
  for insert with check (id = (select auth.uid()));

create policy "profiles_update_own" on public.profiles
  for update using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- admin_roles ---------------------------------------------------------------
create policy "admin_roles_select_own_or_admin" on public.admin_roles
  for select using (user_id = (select auth.uid()) or public.is_admin());

create policy "admin_roles_insert_owner" on public.admin_roles
  for insert with check (public.is_owner());

create policy "admin_roles_update_owner" on public.admin_roles
  for update using (public.is_owner()) with check (public.is_owner());

create policy "admin_roles_delete_owner" on public.admin_roles
  for delete using (public.is_owner());

-- addresses -----------------------------------------------------------------
create policy "addresses_select_own_or_admin" on public.addresses
  for select using (user_id = (select auth.uid()) or public.is_admin());

create policy "addresses_insert_own" on public.addresses
  for insert with check (user_id = (select auth.uid()));

create policy "addresses_update_own" on public.addresses
  for update using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "addresses_delete_own" on public.addresses
  for delete using (user_id = (select auth.uid()));

-- categories ----------------------------------------------------------------
create policy "categories_select_public" on public.categories
  for select using (true);

create policy "categories_insert_admin" on public.categories
  for insert with check (public.is_admin());

create policy "categories_update_admin" on public.categories
  for update using (public.is_admin()) with check (public.is_admin());

create policy "categories_delete_admin" on public.categories
  for delete using (public.is_admin());

-- products ------------------------------------------------------------------
-- public sees active products only; drafts/archived are admin-visible.
create policy "products_select_active_or_admin" on public.products
  for select using (status = 'active' or public.is_admin());

create policy "products_insert_admin" on public.products
  for insert with check (public.is_admin());

create policy "products_update_admin" on public.products
  for update using (public.is_admin()) with check (public.is_admin());

create policy "products_delete_admin" on public.products
  for delete using (public.is_admin());

-- product satellites: visible when the parent product is publicly visible ----
create policy "product_images_select_public" on public.product_images
  for select using (
    public.is_admin() or exists (
      select 1 from public.products p
      where p.id = product_id and p.status = 'active'
    )
  );

create policy "product_images_insert_admin" on public.product_images
  for insert with check (public.is_admin());

create policy "product_images_update_admin" on public.product_images
  for update using (public.is_admin()) with check (public.is_admin());

create policy "product_images_delete_admin" on public.product_images
  for delete using (public.is_admin());

create policy "product_options_select_public" on public.product_options
  for select using (
    public.is_admin() or exists (
      select 1 from public.products p
      where p.id = product_id and p.status = 'active'
    )
  );

create policy "product_options_insert_admin" on public.product_options
  for insert with check (public.is_admin());

create policy "product_options_update_admin" on public.product_options
  for update using (public.is_admin()) with check (public.is_admin());

create policy "product_options_delete_admin" on public.product_options
  for delete using (public.is_admin());

create policy "product_option_values_select_public" on public.product_option_values
  for select using (
    public.is_admin() or exists (
      select 1
      from public.product_options o
      join public.products p on p.id = o.product_id
      where o.id = option_id and p.status = 'active'
    )
  );

create policy "product_option_values_insert_admin" on public.product_option_values
  for insert with check (public.is_admin());

create policy "product_option_values_update_admin" on public.product_option_values
  for update using (public.is_admin()) with check (public.is_admin());

create policy "product_option_values_delete_admin" on public.product_option_values
  for delete using (public.is_admin());

create policy "product_variants_select_public" on public.product_variants
  for select using (
    public.is_admin() or exists (
      select 1 from public.products p
      where p.id = product_id and p.status = 'active'
    )
  );

create policy "product_variants_insert_admin" on public.product_variants
  for insert with check (public.is_admin());

create policy "product_variants_update_admin" on public.product_variants
  for update using (public.is_admin()) with check (public.is_admin());

create policy "product_variants_delete_admin" on public.product_variants
  for delete using (public.is_admin());

create policy "product_variant_values_select_public" on public.product_variant_values
  for select using (
    public.is_admin() or exists (
      select 1
      from public.product_variants v
      join public.products p on p.id = v.product_id
      where v.id = variant_id and p.status = 'active'
    )
  );

create policy "product_variant_values_insert_admin" on public.product_variant_values
  for insert with check (public.is_admin());

create policy "product_variant_values_update_admin" on public.product_variant_values
  for update using (public.is_admin()) with check (public.is_admin());

create policy "product_variant_values_delete_admin" on public.product_variant_values
  for delete using (public.is_admin());

-- carts ---------------------------------------------------------------------
-- logged-in owners only; guest carts (session_token) are handled by server
-- routes with the service role.
create policy "carts_select_own_or_admin" on public.carts
  for select using (user_id = (select auth.uid()) or public.is_admin());

create policy "carts_insert_own" on public.carts
  for insert with check (user_id = (select auth.uid()));

create policy "carts_update_own" on public.carts
  for update using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "carts_delete_own" on public.carts
  for delete using (user_id = (select auth.uid()));

-- cart_items ----------------------------------------------------------------
create policy "cart_items_select_own_or_admin" on public.cart_items
  for select using (
    public.is_admin() or exists (
      select 1 from public.carts c
      where c.id = cart_id and c.user_id = (select auth.uid())
    )
  );

create policy "cart_items_insert_own" on public.cart_items
  for insert with check (
    exists (
      select 1 from public.carts c
      where c.id = cart_id and c.user_id = (select auth.uid())
    )
  );

create policy "cart_items_update_own" on public.cart_items
  for update using (
    exists (
      select 1 from public.carts c
      where c.id = cart_id and c.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.carts c
      where c.id = cart_id and c.user_id = (select auth.uid())
    )
  );

create policy "cart_items_delete_own" on public.cart_items
  for delete using (
    exists (
      select 1 from public.carts c
      where c.id = cart_id and c.user_id = (select auth.uid())
    )
  );

-- orders --------------------------------------------------------------------
-- created by the service role at checkout; customers read their own, admins manage.
create policy "orders_select_own_or_admin" on public.orders
  for select using (user_id = (select auth.uid()) or public.is_admin());

create policy "orders_update_admin" on public.orders
  for update using (public.is_admin()) with check (public.is_admin());

-- order_items ---------------------------------------------------------------
create policy "order_items_select_own_or_admin" on public.order_items
  for select using (
    public.is_admin() or exists (
      select 1 from public.orders o
      where o.id = order_id and o.user_id = (select auth.uid())
    )
  );

-- reviews -------------------------------------------------------------------
-- public reads approved reviews only; authors see their own regardless of status.
create policy "reviews_select_approved_or_own_or_admin" on public.reviews
  for select using (
    status = 'approved'
    or user_id = (select auth.uid())
    or public.is_admin()
  );

-- logged-in customers may review an item they actually bought, for the product
-- that order item points at. Guest reviews go through a server route.
create policy "reviews_insert_verified_purchase" on public.reviews
  for insert with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.product_variants v on v.id = oi.variant_id
      where oi.id = reviews.order_item_id
        and o.user_id = (select auth.uid())
        and v.product_id = reviews.product_id
    )
  );

create policy "reviews_update_admin" on public.reviews
  for update using (public.is_admin()) with check (public.is_admin());

create policy "reviews_delete_admin" on public.reviews
  for delete using (public.is_admin());

-- coupons -------------------------------------------------------------------
create policy "coupons_select_admin" on public.coupons
  for select using (public.is_admin());

create policy "coupons_insert_admin" on public.coupons
  for insert with check (public.is_admin());

create policy "coupons_update_admin" on public.coupons
  for update using (public.is_admin()) with check (public.is_admin());

create policy "coupons_delete_admin" on public.coupons
  for delete using (public.is_admin());

-- coupon_usages -------------------------------------------------------------
create policy "coupon_usages_select_admin" on public.coupon_usages
  for select using (public.is_admin());

-- returns -------------------------------------------------------------------
create policy "returns_select_own_or_admin" on public.returns
  for select using (
    public.is_admin() or exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      where oi.id = order_item_id and o.user_id = (select auth.uid())
    )
  );

create policy "returns_insert_own" on public.returns
  for insert with check (
    exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      where oi.id = returns.order_item_id and o.user_id = (select auth.uid())
    )
  );

create policy "returns_update_admin" on public.returns
  for update using (public.is_admin()) with check (public.is_admin());

create policy "returns_delete_admin" on public.returns
  for delete using (public.is_admin());

-- email_logs ----------------------------------------------------------------
create policy "email_logs_select_admin" on public.email_logs
  for select using (public.is_admin());
