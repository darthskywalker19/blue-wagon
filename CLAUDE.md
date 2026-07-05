@AGENTS.md

# CLAUDE.md — Blue Wagon E-Commerce Rules

## Project
Blue Wagon — e-commerce store, physical products (e-bikes to stationery), USA/USD.
Full spec, pages, database schema, and build order live in `BlueWagon_Blueprint.md` — check it before starting any step.

## Stack
- Next.js (App Router) + TypeScript
- Tailwind CSS — installed via npm/PostCSS, not CDN
- Supabase — database, auth, storage
- Stripe + Stripe Tax — payments
- Shippo — shipping rates + return labels
- Resend — transactional emails
- Vercel — hosting

## Always Do First
- **Invoke the `frontend-design` skill** before writing any frontend code, every session, no exceptions.
- Check `BlueWagon_Blueprint.md` for which build step this session covers. Build one step at a time — do not jump ahead to later steps unprompted.

## File Structure
- One folder/page per route (App Router conventions) — never one giant file.
- Products are **database-driven**: a single template at `app/products/[slug]/page.tsx` reads from Supabase. Never generate a new file per product.
- Shared UI (header, footer, product card, cart drawer, theme provider) in `components/`.
- Keep admin routes under `app/admin/`, role-gated.

## Reference Images
- If a reference image is provided: match layout, spacing, typography, and color exactly. Swap in placeholder content (images via `https://placehold.co/`, generic copy). Do not improve or add to the design.
- If no reference image: design from scratch with high craft (see guardrails below).
- Screenshot the output, compare against reference, fix mismatches, re-screenshot. At least 2 comparison rounds. Stop only when no visible differences remain or the user says so.

## Local Server
- Run the Next.js dev server: `npm run dev` (serves at `http://localhost:3000`)
- Always screenshot from localhost — never a `file:///` URL.
- If the server is already running, don't start a second instance.

## Screenshot Workflow
- Use Puppeteer to screenshot `http://localhost:3000` (and relevant sub-routes) after UI changes.
- Save screenshots to `./temporary screenshots/screenshot-N.png` (auto-incremented, never overwritten).
- Read the saved PNG back with the Read tool to visually check the result.
- When comparing, be specific: "heading is 32px but reference shows ~24px", "card gap is 16px but should be 24px".
- Check: spacing/padding, font size/weight/line-height, colors (exact hex), alignment, border-radius, shadows, image sizing, light AND dark mode.

## Brand
- Blue palette: navy `#0B3A8C`, blue `#1D5FE0`, teal accents. Do not invent new brand colors.
- Check `brand_assets/` for the logo and any style references before designing. Use real assets, not placeholders, where available.
- Theme: modern, not flat — soft shadows, subtle gradient/glass panels, rounded corners. Working light/dark toggle, persisted.

## Anti-Generic Guardrails
- **Colors:** Never default Tailwind palette (indigo-500, blue-600, etc.) — always the brand blues above.
- **Shadows:** Never flat `shadow-md`. Use layered, color-tinted shadows with low opacity.
- **Typography:** Never the same font for headings and body. Pair a display/sans with a clean body sans. Tight tracking (`-0.03em`) on large headings, generous line-height (`1.7`) on body.
- **Gradients:** Layer multiple radial gradients for depth where appropriate (hero sections, cards).
- **Animations:** Only animate `transform` and `opacity`. Never `transition-all`. Spring-style easing.
- **Interactive states:** Every clickable element needs hover, focus-visible, and active states. No exceptions.
- **Product images:** Consistent aspect ratio, subtle hover treatment.
- **Spacing:** Intentional, consistent spacing tokens — not random Tailwind steps.
- **Depth:** Layering system (base → elevated → floating), not everything on one plane.

## Hard Rules
- Do not add pages, features, or database tables not in `BlueWagon_Blueprint.md` without asking first.
- Do not skip ahead in the build order.
- Do not use `transition-all`.
- Do not use default Tailwind blue/indigo as primary color.
- Do not commit real API keys — use environment variables, confirm `.env.local` is gitignored.
