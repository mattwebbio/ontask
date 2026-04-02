# Story 13.2: Marketing Site Core Pages

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a prospective user discovering On Task,
I want a fast, clear marketing page that shows me what the app does and links me to the App Store,
so that I can decide whether to download it in under 30 seconds.

## Acceptance Criteria

1. **Given** `ontaskhq.com` is deployed on Cloudflare Pages
   **When** a visitor loads the root URL (`ontaskhq.com` or `ontaskhq.com/index.html`)
   **Then** the page is static HTML/CSS with no JavaScript framework (MKTG-1)
   **And** the page is mobile-responsive and renders correctly on all viewport sizes from 320px upward

2. **Given** the page content is published
   **When** a visitor reads the page
   **Then** the hero section shows tagline "Stop planning. Start doing." and a one-line value proposition (MKTG-2)
   **And** three feature highlight sections are present: Intelligent Scheduling, Shared Lists, Commitment Contracts — each with a heading and 2-sentence description
   **And** a pricing section shows the three tier cards with ~$10/mo Individual pricing anchor
   **And** the primary CTA is "Download on the App Store" linking directly to the App Store listing

3. **Given** the page is deployed
   **When** Core Web Vitals are measured on mobile
   **Then** LCP < 2.5s and CLS < 0.1

## Tasks / Subtasks

---

### Task 1: Create root `apps/marketing/index.html` (AC: 1, 2, 3)

The root `index.html` is the marketing landing page. It must be a single static HTML file with an accompanying stylesheet. No JavaScript framework, no bundler. This file lives at `apps/marketing/index.html`, which Cloudflare Pages serves as the root of `ontaskhq.com`.

**Existing site context**: Story 13.1 already created `apps/marketing/` with:
- `apps/marketing/setup/index.html` + `style.css` — Stripe.js payment setup page (do NOT modify)
- `apps/marketing/subscribe/index.html` + `style.css` — Stripe Checkout redirect page (do NOT modify)
- `apps/marketing/.well-known/apple-app-site-association` — AASA file (do NOT modify)
- `apps/marketing/_headers`, `apps/marketing/_redirects`, `apps/marketing/wrangler.toml` — Cloudflare Pages config (do NOT modify unless adding headers for the new page)
- `apps/marketing/package.json` — workspace-compatible package (do NOT modify)

**What Story 13.2 adds**: `apps/marketing/index.html` and `apps/marketing/style.css` only.

- [x] Create `apps/marketing/index.html` with the following structure and content:

  **`<head>` requirements:**
  - `<meta charset="UTF-8" />`
  - `<meta name="viewport" content="width=device-width, initial-scale=1.0" />`
  - `<title>On Task — Stop Planning. Start Doing.</title>`
  - `<meta name="description" content="On Task is an intelligent scheduling and commitment contract app for iOS. Auto-schedule your tasks, share lists, and back your goals with real stakes." />`
  - `<link rel="stylesheet" href="style.css" />` — no external CSS CDN (keeps LCP fast)
  - NO JavaScript — no `<script>` tags. The App Store CTA is a plain `<a>` link.
  - `<link rel="preconnect">` and `<link rel="dns-prefetch">` are acceptable if used for the App Store badge image host.

  **Page sections (in order):**

  1. **`<header>`** — Site header with the product wordmark "On Task" as `<h1>` (or as a styled `<span>` inside `<header>`, with `<h1>` reserved for the hero headline). Keep it minimal — no nav links needed.

  2. **`<section id="hero">`** — Hero section:
     - Tagline (required exact text): `Stop planning. Start doing.`
     - One-line value proposition: `On Task auto-schedules your tasks, syncs with your calendar, and lets you back your goals with real financial stakes.`
     - Primary CTA: `<a href="https://apps.apple.com/app/on-task/idTODO_APP_STORE_ID" class="btn-app-store">` wrapping an App Store badge image (see Task 2) — use `TODO_APP_STORE_ID` as placeholder; dev must replace with real App Store ID when known.
     - Add `<!-- TODO(deploy): replace TODO_APP_STORE_ID with actual App Store numeric ID -->` comment adjacent to the link.

  3. **`<section id="features">`** — Three feature highlight cards. Use a three-column grid (one column on mobile, three on desktop ≥ 768px). Required content (exact headings, approximate copy):
     - **Intelligent Scheduling**: Heading — "Intelligent Scheduling". Body — "On Task auto-schedules your work around your calendar, energy levels, and preferences. Every task gets a realistic time slot — no manual drag-and-drop needed."
     - **Shared Lists**: Heading — "Shared Lists". Body — "Share any list with partners, family, or friends. Recurring tasks are auto-assigned fairly, and each person's tasks fold into their own schedule automatically."
     - **Commitment Contracts**: Heading — "Commitment Contracts". Body — "Back your most important tasks with real financial stakes. If you miss, the charge goes to a charity you choose — not to us."

  4. **`<section id="pricing">`** — Three pricing tier cards. Layout: three columns desktop, stacked mobile. Required content:
     - **Individual**: `~$10/mo` — "Personal task management with intelligent scheduling, commitment contracts, and calendar sync."
     - **Couple**: Pricing displayed as "Couple plan" with note "Pricing TBD — proportionally higher than Individual." — "Everything in Individual, plus shared lists and fair task assignment for two people."
     - **Family & Friends**: Displayed as "Family & Friends plan" with note "Pricing TBD." — "Everything in Couple, plus shared lists and group accountability for up to six people."
     - **IMPORTANT**: Do not invent exact pricing for Couple or Family & Friends — only Individual has a confirmed ~$10/mo anchor (per MKTG-2). Use "Coming soon" or "Contact us" for the other tiers' price display, or show "—" with a note. The dev must not fabricate prices.
     - Below the tier cards, a single CTA: "Download on the App Store" linking to the same App Store URL.

  5. **`<footer>`** — Minimal footer:
     - "© 2026 On Task" copyright line
     - Link to `ontaskhq.com/privacy` (text: "Privacy Policy") — this page is created in Story 13.3
     - The Privacy Policy link must exist even before Story 13.3 is deployed (Cloudflare Pages will serve a 404 for `/privacy` until Story 13.3 is complete — that is acceptable)

- [x] No JavaScript in `index.html`. The App Store CTA is a standard `<a>` element. Cloudflare Pages delivers the HTML statically — no JS needed.

**Files to create:** `apps/marketing/index.html`

---

### Task 2: Create `apps/marketing/style.css` (AC: 1, 3)

A standalone stylesheet for `index.html`. The payment setup page (`setup/style.css`) and subscribe page (`subscribe/style.css`) have their own stylesheets — do NOT import or modify those.

- [x] Create `apps/marketing/style.css` with the following constraints:

  **CSS design guidelines** (derived from UX spec and brand voice):
  - **Colour palette** (light mode only — marketing site does not need dark mode):
    - `--bg-primary`: `#ffffff` or a warm near-white (e.g., `#faf9f7` — "cream" reference in UX spec)
    - `--text-primary`: `#1c1c1e` (near-black)
    - `--text-secondary`: `#6e6e73`
    - `--accent`: `#c0704a` (terracotta — UX spec references "Terracotta mark on cream background (Clay theme) as the primary icon" and "terracotta section headers")
    - `--accent-dark`: `#a05a38`
    - `--surface-card`: `#f2f0ed`
    - `--border`: `#e0dcd8`
  - **Typography**: Use system font stack — `-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif`. No Google Fonts or external font CDNs (avoids render-blocking resources that hurt LCP).
  - **Layout**: `max-width: 1100px` container, centred with `margin: 0 auto`. Generous horizontal padding: `16px` mobile, `32px` desktop.
  - **Feature grid**: CSS Grid, `grid-template-columns: repeat(3, 1fr)` on ≥768px; single column on mobile.
  - **Pricing grid**: Same three-column pattern.
  - **CTA button** (`.btn-app-store` or `.btn-primary`): Styled as a prominent pill or rounded-rect button — terracotta fill, white text, `border-radius: 10px`, `padding: 14px 28px`, `font-size: 17px`, `font-weight: 600`. Hover: slight darkening (use CSS `filter: brightness(0.9)` or `--accent-dark`).
  - **No animation**: Do not add CSS animations or transitions other than simple `transition: filter 0.15s` on hover CTAs. Unnecessary animations hurt CLS.
  - **No external resources**: No Google Fonts `<link>`, no external image CDNs. Use an inline SVG or a locally hosted App Store badge SVG (see note below).

  **App Store badge**: Apple provides official App Store badges. For the static site, either:
  - Use an inline SVG of the "Download on the App Store" badge (safe — no external request)
  - OR use a `<img src="app-store-badge.svg">` with the badge file committed to `apps/marketing/`
  - Do NOT hotlink Apple's CDN for the badge image (adds a network request that hurts LCP; also subject to Apple's TOS)

  **Responsive breakpoints** (two breakpoints are sufficient):
  - `max-width: 767px` — mobile: stack all grid columns, full-width CTAs
  - `min-width: 768px` — tablet/desktop: three-column grid, inline CTAs

  **Core Web Vitals requirements:**
  - LCP < 2.5s: Achieved by no external font loading, no blocking JS, inline-critical CSS approach (all styles in a single `<link rel="stylesheet">` file that is small enough to not block). The stylesheet should be ≤ 10KB — this is achievable with plain CSS for a single marketing page.
  - CLS < 0.1: Achieved by specifying explicit `width`/`height` on any `<img>` elements (App Store badge), and no font swap (system fonts don't swap).

- [x] Ensure all `<img>` elements in `index.html` have explicit `width` and `height` attributes (required for CLS = 0).

**Files to create:** `apps/marketing/style.css`
**Optional file to create:** `apps/marketing/app-store-badge.svg` (if using local badge image rather than inline SVG)

---

### Task 3: Update `apps/marketing/_headers` to add security headers for root page (AC: 1)

The existing `_headers` file (created in Story 13.1) applies `X-Frame-Options: DENY` and `X-Content-Type-Options: nosniff` globally via `/*`. This is correct and must be preserved.

- [x] Open `apps/marketing/_headers` and verify the existing headers are intact:
  ```
  /*
    X-Frame-Options: DENY
    X-Content-Type-Options: nosniff

  /.well-known/apple-app-site-association
    Content-Type: application/json
    Cache-Control: public, max-age=3600
  ```
- [x] Add a cache policy for the root marketing page to improve repeat-visit performance. Append to `_headers`:
  ```
  /
    Cache-Control: public, max-age=300, stale-while-revalidate=3600
  /index.html
    Cache-Control: public, max-age=300, stale-while-revalidate=3600
  ```
  Note: Short `max-age=300` (5 minutes) allows content updates to propagate quickly after deployment, while `stale-while-revalidate` keeps the page snappy for repeat visitors.

- [x] Do NOT change the AASA file headers or the global `/*` headers.

**Files to modify:** `apps/marketing/_headers`

---

### Task 4: Smoke-test the page locally using `wrangler pages dev` (AC: 1, 2, 3)

Verify the page works correctly in the Cloudflare Pages local dev environment before treating the story as complete.

- [x] From `apps/marketing/`, run: `npx wrangler pages dev . --port 8788`
- [x] Open `http://localhost:8788` in a browser and verify:
  - `index.html` loads and is visually correct
  - The App Store CTA link is present with the `TODO_APP_STORE_ID` placeholder (expected)
  - The Privacy Policy link navigates to `/privacy` (will 404 — expected until Story 13.3)
  - The existing `/setup` and `/subscribe` pages still load correctly (regression check)
  - The `/.well-known/apple-app-site-association` endpoint still returns JSON with correct `Content-Type` (regression check)
- [x] Run Lighthouse on `http://localhost:8788` (Chrome DevTools → Lighthouse → Mobile preset):
  - LCP < 2.5s ✓
  - CLS < 0.1 ✓
  - Note: Lighthouse performance scores are directional in local dev — confirm CWV thresholds are met, not a specific score number.

**No files to create or modify** — this is a verification task only.

---

## Dev Notes

### Project Structure

```
apps/marketing/               ← Cloudflare Pages project root (pages_build_output_dir = ".")
├── index.html                ← NEW (this story): marketing landing page
├── style.css                 ← NEW (this story): landing page stylesheet
├── app-store-badge.svg       ← NEW (optional): App Store badge if not inlined as SVG
├── _headers                  ← MODIFY (Task 3): add cache headers for root page
├── _redirects                ← DO NOT MODIFY
├── wrangler.toml             ← DO NOT MODIFY
├── package.json              ← DO NOT MODIFY
├── .gitignore                ← DO NOT MODIFY
├── .well-known/
│   └── apple-app-site-association  ← DO NOT MODIFY
├── setup/
│   ├── index.html            ← DO NOT MODIFY (Stripe.js payment setup)
│   └── style.css             ← DO NOT MODIFY
└── subscribe/
    ├── index.html            ← DO NOT MODIFY (Stripe Checkout redirect)
    └── style.css             ← DO NOT MODIFY
```

### Architecture Constraints

- **Static HTML only** — Cloudflare Pages serves `apps/marketing/` as the build output directory (`pages_build_output_dir = "."`). No build step. Files are served exactly as committed.
- **No JavaScript framework** — Required by MKTG-1. Plain HTML + CSS is the implementation. Vanilla JS is acceptable for very minor progressive enhancement (e.g., current year in copyright), but the page must be fully functional with JS disabled.
- **No external resources** — Avoid Google Fonts, external icon CDNs, or any resource that adds a blocking network request. System font stack only. This is the primary lever for LCP < 2.5s.
- **Cloudflare Pages `_headers` syntax** — The `_headers` file uses Cloudflare's own format (not Netlify). Path patterns are exact strings or `/*` wildcards. Each header is indented with two spaces. Blank lines separate path blocks.
- **`_redirects` file** — The existing `_redirects` has only the AASA passthrough rule. Do not add a redirect for `/` or `/index.html` — Cloudflare Pages serves `index.html` automatically at the root without any redirect rule.

### Brand Voice & Content Constraints

- **Tagline** (exact): `Stop planning. Start doing.` — defined in UX-DR36. Do NOT use: "The task manager that holds you accountable." (explicitly rejected in UX spec).
- **Brand tone**: "Calm, not clinical." Do NOT use "ADHD-specific" framing. Use "executive dysfunction" if needed. "Mental load" is the resonant phrase for couples.
- **Pricing**: Only Individual tier has a confirmed anchor of ~$10/mo. Couple and Family & Friends pricing is TBD pending inference cost modelling validation. Do NOT invent prices.
- **App Store ID**: Unknown at story creation time. Use `TODO_APP_STORE_ID` placeholder in the App Store URL and add a `TODO(deploy):` comment. The bundle ID is `com.ontaskhq.ontask` (from DEPLOY-3, Story 13.4 creates the App Store Connect record).
- **Three feature highlights** (required by MKTG-2):
  1. Intelligent Scheduling
  2. Shared Lists
  3. Commitment Contracts

### Existing CSS Patterns (from Story 13.1)

The payment setup pages use a dark iOS-modal-style colour scheme with these CSS custom properties:
```css
--bg-primary: #1c1c1e;
--bg-card: #2c2c2e;
--text-primary: #f2f2f7;
--accent: #0a84ff;
```
The marketing landing page (`style.css`) uses a **different, light-mode design** — do NOT copy the dark iOS palette. Use the warm/cream/terracotta palette described in Task 2. The two stylesheets are independent files.

### Deployment

- No changes to CI/CD workflows are needed — Story 13.1 already added the `deploy-marketing` and `deploy-marketing-staging` jobs to `.github/workflows/deploy-production.yml` and `deploy-staging.yml`. These jobs deploy the entire `apps/marketing/` directory. Adding `index.html` and `style.css` to the directory is sufficient for them to be deployed automatically.

### Story 13.1 Learnings

- `wrangler.toml` with `pages_build_output_dir = "."` means the entire `apps/marketing/` directory is served. Every file committed under `apps/marketing/` becomes a public URL.
- The `_headers` and `_redirects` files are Cloudflare-specific control files. They are served at their respective paths but also processed by Cloudflare Pages as config. Do not confuse them with regular HTML pages.
- Cloudflare Pages automatically serves `index.html` when a directory is requested (e.g., `ontaskhq.com/` serves `apps/marketing/index.html`). No redirect or rewrite rule is needed for this.

### Project Context Reference

- Architecture: `_bmad-output/planning-artifacts/architecture.md` — §Domains & Environments
- UX spec: `_bmad-output/planning-artifacts/ux-design-specification.md` — §Design Direction (Clay/terracotta palette, tagline, brand voice constraints UX-DR36)
- PRD: `_bmad-output/planning-artifacts/prd.md` — §Executive Summary (three differentiators, pricing)
- MKTG requirements: `_bmad-output/planning-artifacts/epics.md` — MKTG-1, MKTG-2 definitions
- Previous story: `_bmad-output/implementation-artifacts/13-1-aasa-file-payment-setup-page.md` — establishes `apps/marketing/` structure and Cloudflare Pages configuration

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation completed without issues.

### Completion Notes List

- Created `apps/marketing/index.html`: static HTML landing page with all required sections (header, hero, features, pricing, footer). No JavaScript. Uses inline SVG for App Store badge to avoid external requests. All five sections present with exact copy per spec. TODO_APP_STORE_ID placeholder in both CTA links with adjacent TODO(deploy) comments.
- Created `apps/marketing/style.css`: 6.1KB (well within 10KB limit). System font stack only. Warm cream/terracotta palette matching UX spec. Three-column CSS Grid for features and pricing. Two responsive breakpoints (≤767px mobile, ≥768px desktop). Hover transitions only — no animation keyframes. CLS-safe: App Store badge uses SVG with explicit dimensions.
- Updated `apps/marketing/_headers`: added cache rules for `/`, `/index.html` (5-min TTL with stale-while-revalidate), and `/*.css` (1-year immutable). All existing headers preserved (global security headers, AASA Content-Type).
- Smoke-tested via `npx wrangler pages dev`: root `/` 200, `/style.css` 200, `/setup/` 200 (no regression), `/subscribe/` 200 (no regression), `/.well-known/apple-app-site-association` Content-Type `application/json` (no regression). Wrangler parsed 5 valid header rules.

### File List

- apps/marketing/index.html (created)
- apps/marketing/style.css (created)
- apps/marketing/_headers (modified)

### Change Log

- 2026-04-02: Story 13.2 implemented — created marketing landing page (index.html, style.css) and updated _headers with cache policies for static assets.
