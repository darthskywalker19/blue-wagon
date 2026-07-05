# BlueWagon_Blueprint.md

Source of truth for pages, database schema, and build order. Claude Code should check this file before starting any step, per `CLAUDE.md`.

---

## 1. Overview

- E-commerce store, physical products only, range spans e-bikes to stationery.
- USA-based, USD only, single currency/locale for v1.
- Stack: Next.js (App Router) + TypeScript, Tailwind CSS, Supabase (DB/auth/storage), Stripe + Stripe Tax, Shippo (shipping + returns), Resend (email), Vercel hosting.

---

## 2. Database Schema (Supabase / Postgres)

Notes: `uuid` PKs everywhere, `created_at`/`updated_at` on all tables, RLS enabled on all tables (public read where appropriate, owner/admin write).

**users** — extends `auth.users` via a `profiles` table (`id` = auth uid, `full_name`, `phone`, `default_address_id`).

**admin_roles** — `user_id`, `role` (`owner` | `manager` | `staff`). Absence of a row = regular customer.

**categories** — `id`, `parent_id` (self-referencing, nullable = top-level), `name`, `slug`, `sort_order`, `image_url`.

**products** — `id`, `slug`, `name`, `description`, `category_id`, `base_price`, `status` (`draft`|`active`|`archived`), `weight_oz`, `dimensions` (jsonb — for shipping calc), `requires_freight` (bool, see flags below).

**product_images** — `product_id`, `url`, `alt`, `sort_order`.

**product_options** — `product_id`, `name` (e.g. "Size", "Color", "Frame Size", "Battery"). Generic, not hardcoded to size/color — see flag #1.

**product_option_values** — `option_id`, `value` (e.g. "Large", "Red").

**product_variants** — `product_id`, `sku`, `price_override` (nullable, falls back to base_price), `stock_qty`, `image_url`.

**product_variant_values** — join table: `variant_id`, `option_value_id`. Lets a variant be defined by any combination of options.

**reviews** — `product_id`, `user_id` (nullable for guest? — decide: recommend requiring account or verified order), `rating` (1–5), `comment`, `verified_purchase` (bool), `status` (`pending`|`approved`|`rejected`).

**carts** — `id`, `user_id` (nullable), `session_token` (for guests), `status` (`active`|`converted`|`abandoned`).

**cart_items** — `cart_id`, `variant_id`, `qty`.

**orders** — `id`, `user_id` (nullable — guest orders), `guest_email`, `status` (`pending`|`paid`|`fulfilled`|`shipped`|`delivered`|`cancelled`), `subtotal`, `tax_total`, `shipping_total`, `discount_total`, `grand_total`, `shipping_address` (jsonb), `billing_address` (jsonb), `stripe_payment_intent_id`, `shippo_shipment_id`.

**order_items** — `order_id`, `variant_id`, `qty`, `unit_price_at_purchase`.

**coupons** — `code`, `discount_type` (`percent`|`fixed`), `discount_value`, `min_order_amount`, `usage_limit`, `usage_count`, `expires_at`, `active`.

**coupon_usages** — `coupon_id`, `order_id`, `user_id`/`guest_email`.

**addresses** — `user_id`, `label`, `line1`, `line2`, `city`, `state`, `zip`, `is_default`.

**returns** — `order_item_id`, `reason`, `status` (`requested`|`approved`|`label_sent`|`received`|`refunded`|`rejected`), `shippo_return_label_url`, `refund_amount`, `refund_stripe_id`.

**email_logs** — `type`, `recipient`, `order_id` (nullable), `resend_id`, `status`. Useful for debugging delivery issues later.

---

## 3. Pages / Routes

**Customer-facing**
- `/` — home
- `/products` — all products, filters/sort
- `/category/[slug]` — nested category browse
- `/products/[slug]` — product detail (single DB-driven template)
- `/search`
- `/cart`
- `/checkout` → `/checkout/success`
- `/login`, `/signup`, `/forgot-password`
- `/account` — dashboard
- `/account/orders`, `/account/orders/[id]`
- `/account/returns` — initiate/track returns
- `/account/addresses`
- `/account/settings`
- `/returns-policy`, `/about`, `/contact` — static content pages

**Admin** (role-gated, under `app/admin/`)
- `/admin` — dashboard/overview
- `/admin/products`, `/admin/products/new`, `/admin/products/[id]/edit`
- `/admin/categories`
- `/admin/orders`, `/admin/orders/[id]`
- `/admin/customers`
- `/admin/coupons`
- `/admin/reviews` — moderation queue
- `/admin/returns` — process/approve, trigger label
- `/admin/users` — role management (Owner only)
- `/admin/settings`

---

## 4. Build Order

Build **one step at a time**, screenshot/compare per `CLAUDE.md` workflow, don't jump ahead.

1. Project scaffold — Next.js + TS + Tailwind config (brand colors, fonts), folder structure, light/dark theme provider
2. Supabase setup — schema migrations, RLS policies, auth config, storage buckets
3. Static layout — header, footer, nav (with nested category dropdown), mobile menu, theme toggle
4. Homepage — hero, featured categories, featured products (placeholder content)
5. Category & product listing pages, nested category nav, filters/sort
6. Product detail template — image gallery, option/variant selector, add to cart, reviews display
7. Cart — drawer + full page, guest cart via session token
8. Checkout — address form, live Shippo rates, Stripe payment + Stripe Tax
9. Order confirmation + Resend emails (confirmation, shipping update)
10. Auth — signup/login, guest-to-account cart/order merge, account dashboard
11. Reviews & ratings — submission, display, moderation
12. Returns flow — request, Shippo return label, Stripe refund
13. Coupons — validation + application at checkout
14. Admin panel — role gate, product/category CRUD, order management, coupon management, review moderation, returns processing
15. Search
16. Polish pass — responsive, dark mode audit, states (empty/loading/error), animations
17. SEO — sitemap, metadata, analytics
18. Pre-launch checklist — env vars, security review, backups

---

## 5. Integration Notes

- **Stripe**: Payment Intents; Stripe Tax for automatic sales tax; webhooks for order status sync.
- **Shippo**: live rates at checkout based on `weight_oz`/`dimensions`; return label generation on approved returns.
- **Resend**: order confirmation, shipping notification, return confirmation/refund notice, welcome email, password reset.
- **Supabase**: RLS is the main access-control layer; storage buckets for product images.

---

## 6. Open Questions / Flags (non-standard for typical e-commerce)

1. **Variant model needs to be generic, not fixed size/color.** E-bikes might vary by frame size + battery + color; stationery by color + pack size. Schema above uses a generic `product_options` / `product_option_values` / `product_variant_values` structure instead of hardcoded columns — confirm this is the direction you want before Step 2.

2. **E-bikes likely can't ship via Shippo's standard parcel carriers.** Large/heavy items often need LTL freight, which Shippo's core API doesn't fully cover. Decide now: exclude freight items from live-rate checkout (flat "contact us" shipping) or integrate a separate freight quoting step later. This affects the `requires_freight` flag and Step 8.

3. **Returns for large/freight items differ from small-parcel returns** (pickup scheduling vs. drop-off label). The `returns` table assumes a simple label-based flow — freight returns will need a different path.

4. **Guest checkout + returns**: guests have no account to log into, so returns need lookup by order number + email. Confirm this is acceptable, or require account creation for returns.

5. **Sales tax nexus**: Stripe Tax calculates automatically, but you're still responsible for registering in states where you have nexus. Not a code issue, but a compliance to-do before launch.

6. **Review eligibility**: schema allows guest reviews (`user_id` nullable) — recommend requiring a verified purchase (order lookup) at minimum, even without a full account, to reduce fake reviews. Confirm your preference.
