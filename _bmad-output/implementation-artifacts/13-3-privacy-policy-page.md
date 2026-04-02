# Story 13.3: Privacy Policy Page

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an App Store reviewer and user,
I want a complete privacy policy that covers all the sensitive data On Task handles,
so that the app passes App Store review and users understand how their data is used.

## Acceptance Criteria

1. **Given** the privacy policy is deployed at `ontaskhq.com/privacy`
   **When** a user or reviewer reads it
   **Then** the policy explicitly covers: Watch Mode camera data (frames processed in-flight, not stored), proof media retention (retained until task deleted if user opted in), HealthKit data (read only, not shared, retained only for verification), payment data (PCI SAQ A — card data not stored by On Task), and account deletion/data retention (30-day retention before permanent deletion) (MKTG-5)
   **And** effective date and last-updated date are displayed at the top (value: 2026-04-02)
   **And** the policy covers all data types declared in the App Store Privacy Nutrition Label

2. **Given** the page is deployed
   **When** the `/privacy/` path is requested
   **Then** Cloudflare Pages serves the page with Cache-Control: public, max-age=300, stale-while-revalidate=3600 (same TTL as root page)

3. **Given** the page is live
   **When** the footer "Privacy Policy" link in `index.html` is followed
   **Then** it resolves to the privacy page without a 404

4. **Given** the page is viewed on mobile
   **When** the page renders
   **Then** it is mobile-responsive (works from 320px width), links the shared `style.css`, and contains no JavaScript

## Tasks / Subtasks

---

### Task 1: Create `apps/marketing/privacy/index.html` (AC: 1, 3, 4) ✓

Create the privacy policy as a static HTML page at `apps/marketing/privacy/index.html`. Cloudflare Pages automatically serves `privacy/index.html` when `/privacy` or `/privacy/` is requested — no redirect rule is needed.

**HEAD requirements:**
- `<meta charset="UTF-8" />`
- `<meta name="viewport" content="width=device-width, initial-scale=1.0" />`
- `<title>Privacy Policy — On Task</title>`
- `<meta name="robots" content="noindex" />` — privacy pages should not be indexed by search engines
- `<link rel="stylesheet" href="../style.css" />` — relative path up one directory to the shared stylesheet
- NO JavaScript — no `<script>` tags

**Page structure (in order):**

1. **`<header class="site-header">`** — reuse the same header pattern from `index.html`:
   ```html
   <header class="site-header">
     <div class="container">
       <a href="/" class="wordmark" style="text-decoration:none;">On Task</a>
     </div>
   </header>
   ```

2. **`<main>`** — Wrap all content in `<main>`.

3. **Privacy policy content** — Use a single `<div class="container">` wrapping a `<article class="prose">` element. The `.prose` class should be added to `style.css` (Task 2). Structure:

   ```
   <article class="prose">
     <h1>Privacy Policy</h1>
     <p class="prose-meta">Effective date: April 2, 2026 · Last updated: April 2, 2026</p>

     [Sections as <h2> headings with <p> body text and <ul> lists]

   </article>
   ```

**Required policy sections (exact headings and content coverage):**

**Section 1: Introduction**
- Who we are: "On Task" operated by [TODO(legal): insert legal entity name], contactable at privacy@ontaskhq.com
- Scope: covers the On Task iOS app and website ontaskhq.com
- Geographic scope: service is currently US-only

**Section 2: Information We Collect**
Subsections:
- **Account Information**: email address, display name (collected at registration)
- **Task and Schedule Data**: tasks, subtasks, sections, lists, due dates, priority, completion status, scheduling preferences — stored server-side to power intelligent scheduling
- **Calendar Data**: read/write access to calendars you grant (via EventKit / Google Calendar OAuth); calendar events are read to avoid scheduling conflicts and written when tasks are scheduled; calendar content is not retained beyond the scheduling operation
- **Commitment Contract Data**: stake amounts, charity selection, task deadlines, charge history — required to operate the commitment contract feature; payment method tokens (Stripe SetupIntent tokens) — On Task never stores raw card numbers (PCI SAQ A)
- **Proof Media** (photo/video): submitted proofs are processed by AI for task verification; if you select "Attach to completed task," the media is retained as a completion record for the lifetime of the task; if you do not select this, the media is purged immediately after verification
- **Watch Mode Camera Data**: individual video frames are processed in-flight by our AI model for focus session verification; frames are NOT stored; only session metadata is retained (start time, end time, task, verification result)
- **HealthKit Data**: if you grant HealthKit permission, On Task reads specific health metrics (e.g., activity data) solely for proof verification of health-related tasks; this data is not shared with third parties; it is not retained beyond the verification event
- **Usage Data**: app interaction logs, crash reports, and performance diagnostics (via standard iOS crash reporting); used to fix bugs and improve the app

**Section 3: How We Use Your Information**
- Operate and provide the On Task service (scheduling, task management, commitment contracts)
- Process commitment contract charges and disbursements to charities
- Verify task completion via AI-based proof review (photo, video, Watch Mode, HealthKit)
- Sync tasks with your calendar
- Communicate with you about your account and transactions
- Improve and debug the app

**Section 4: Third-Party Services**
Use a table or list:
- **Stripe**: payment processing and card tokenization. On Task uses Stripe for all financial transactions. Your payment data is governed by [Stripe's Privacy Policy](https://stripe.com/privacy). On Task never receives or stores raw card numbers.
- **Every.org**: charity disbursement. When a commitment contract penalty is triggered, 50% of the charge amount is disbursed to your chosen charity via Every.org. Disbursement data (amount, charity) is shared with Every.org.
- **Google Calendar** (optional): if you connect Google Calendar, On Task reads and writes to your calendar via OAuth. Your Google Calendar data is governed by [Google's Privacy Policy](https://policies.google.com/privacy). On Task does not retain calendar content beyond active scheduling operations.
- **Apple HealthKit** (optional): health data read via HealthKit for proof verification; not shared with any third party; not retained beyond the verification event.
- **Apple Watch** (optional): Watch Mode uses the Watch camera for passive focus session monitoring; frame data is processed in-flight and not stored.

**Section 5: Data Retention**
- Task and account data: retained for the lifetime of your account
- Proof media (attached): retained until the associated task is deleted
- Proof media (not attached): deleted immediately after AI verification
- Watch Mode frames: never stored; only session metadata is retained
- HealthKit data: not retained beyond verification event
- Payment tokens: managed by Stripe; On Task retains charge records (amount, date, task, charity) for legal and tax purposes
- After account deletion: all personal data is permanently deleted within 30 days, except where required to be retained by law (e.g., financial transaction records)

**Section 6: Your Rights**
- **Access**: you can view your data within the On Task app
- **Export**: you can request an export of your data by emailing privacy@ontaskhq.com
- **Deletion**: you can delete your account in Settings → Account → Delete Account. All personal data is permanently deleted within 30 days. Commitment contract charge records may be retained as required by law.
- **Correction**: contact privacy@ontaskhq.com to correct inaccurate personal data
- **California residents (CCPA)**: you have the right to know what personal information is collected, to request deletion, and to opt out of sale. On Task does not sell personal data.
- **GDPR (EU/UK users)**: On Task is currently a US-only service. If you are in the EU or UK, please be aware GDPR-specific protections are not yet implemented. Contact privacy@ontaskhq.com with any concerns.

**Section 7: Watch Mode & Camera — Special Disclosure**
- Explain plainly what Watch Mode does: the Apple Watch camera observes your work environment periodically during a focus session; individual frames are analyzed by AI to verify you are present and working; no video is recorded or stored
- "On Task uses your camera as a digital body double — ambient presence, not surveillance."
- This section must be present because App Store review specifically scrutinizes camera usage disclosures

**Section 8: HealthKit — Special Disclosure**
- On Task accesses HealthKit data only when you grant permission and only for the purpose of verifying completion of health-related tasks
- HealthKit data is not used for advertising and is not shared with third parties
- This section is required by App Store guidelines (HealthKit apps must have a privacy policy)

**Section 9: Children's Privacy**
- On Task is not directed at children under 13 and does not knowingly collect data from children under 13
- If you believe a child's data has been collected, contact privacy@ontaskhq.com

**Section 10: Changes to This Policy**
- We will post changes on this page and update the "Last updated" date
- For material changes, we will notify users via the app or email

**Section 11: Contact**
- Email: privacy@ontaskhq.com
- Include a `<a href="mailto:privacy@ontaskhq.com">` link

4. **`<footer class="site-footer">`** — Reuse footer pattern:
   ```html
   <footer class="site-footer">
     <div class="container">
       <p>© 2026 On Task &nbsp;·&nbsp; <a href="/privacy">Privacy Policy</a></p>
     </div>
   </footer>
   ```

**Files to create:** `apps/marketing/privacy/index.html`

---

### Task 2: Add `.prose` styles to `apps/marketing/style.css` (AC: 4) ✓

The privacy page needs a `.prose` class for readable long-form content. Append to the existing `style.css` — do NOT rewrite it.

**Add to end of `style.css`:**

```css
/* ─── Prose (Privacy Policy, Legal Pages) ───────────────────────── */
.prose {
  max-width: 720px;
  margin: 48px auto 80px;
  padding: 0 16px;
}

.prose h1 {
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.3px;
  margin-bottom: 8px;
  color: var(--text-primary);
}

.prose-meta {
  font-size: 14px;
  color: var(--text-secondary);
  margin-bottom: 40px;
}

.prose h2 {
  font-size: 20px;
  font-weight: 600;
  margin-top: 36px;
  margin-bottom: 12px;
  color: var(--text-primary);
}

.prose p {
  margin-bottom: 16px;
  color: var(--text-primary);
}

.prose ul {
  margin-bottom: 16px;
  padding-left: 20px;
}

.prose ul li {
  margin-bottom: 8px;
  line-height: 1.6;
}

.prose a {
  color: var(--accent);
}

.prose a:hover {
  color: var(--accent-dark);
}
```

**Files to modify:** `apps/marketing/style.css`

---

### Task 3: Update `apps/marketing/_headers` to add cache rule for `/privacy/` (AC: 2) ✓

Add a cache rule for the privacy page — same 5-minute TTL as the root page.

**Append to `apps/marketing/_headers`:**
```
/privacy/
  Cache-Control: public, max-age=300, stale-while-revalidate=3600
```

Do NOT change any existing header rules. The existing file has:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff

/.well-known/apple-app-site-association
  Content-Type: application/json
  Cache-Control: public, max-age=3600

/
  Cache-Control: public, max-age=300, stale-while-revalidate=3600
/index.html
  Cache-Control: public, max-age=300, stale-while-revalidate=3600

/style.css
  Cache-Control: public, max-age=31536000, immutable
```

Simply append the `/privacy/` block. Use exact Cloudflare Pages `_headers` syntax (two-space indentation).

**Files to modify:** `apps/marketing/_headers`

---

### Task 4: Smoke-test locally (AC: 1, 2, 3) ✓

- Run `npx wrangler pages dev . --port 8788` from `apps/marketing/`
- Verify:
  - `http://localhost:8788/privacy/` returns 200 with privacy page content
  - `http://localhost:8788/` (root) still loads correctly — regression check
  - `http://localhost:8788/setup/` still loads correctly — regression check
  - `http://localhost:8788/subscribe/` still loads correctly — regression check
  - `http://localhost:8788/.well-known/apple-app-site-association` still returns JSON — regression check
  - Footer "Privacy Policy" link on root page resolves to `/privacy` (navigating to `/privacy/` works)

**No files to create or modify** — verification task only.

---

## Dev Notes

### Project Structure

```
apps/marketing/                ← Cloudflare Pages root (pages_build_output_dir = ".")
├── index.html                 ← DO NOT MODIFY (Story 13.2)
├── style.css                  ← MODIFY: append .prose styles only
├── _headers                   ← MODIFY: append /privacy/ cache rule only
├── _redirects                 ← DO NOT MODIFY
├── wrangler.toml              ← DO NOT MODIFY
├── package.json               ← DO NOT MODIFY
├── .well-known/
│   └── apple-app-site-association  ← DO NOT MODIFY
├── setup/
│   ├── index.html             ← DO NOT MODIFY (Stripe.js payment setup)
│   └── style.css              ← DO NOT MODIFY
├── subscribe/
│   ├── index.html             ← DO NOT MODIFY (Stripe Checkout redirect)
│   └── style.css              ← DO NOT MODIFY
└── privacy/                   ← NEW (this story)
    └── index.html             ← NEW: privacy policy page
```

### Architecture Constraints

- **Static HTML only** — Same constraint as Stories 13.1 and 13.2. No JS, no build step. Cloudflare Pages serves `apps/marketing/` as-is.
- **Shared stylesheet** — The privacy page MUST use `<link rel="stylesheet" href="../style.css" />` (relative `../` path). Do NOT create a separate `privacy/style.css`. The `.prose` styles added to `style.css` are additive and affect only elements using that class.
- **Cloudflare Pages directory serving** — `privacy/index.html` is served at `/privacy/` and `/privacy` (Cloudflare Pages normalises trailing slash). No redirect rule is needed in `_redirects`.
- **`_headers` syntax** — Two-space indented headers under path block. One blank line between blocks. `/privacy/` matches the directory path as Cloudflare Pages normalizes it.

### Privacy Data Coverage — What On Task Collects (from PRD)

These must ALL be addressed in the policy to satisfy App Store Privacy Nutrition Label:

| Data Type | Collected? | Retained? | Shared with? |
|-----------|-----------|-----------|-------------|
| Email address | Yes | Account lifetime | None |
| Display name | Yes | Account lifetime | None |
| Task/schedule data | Yes | Account lifetime | None |
| Calendar data | Read/write | Not retained | Google (if connected) |
| Commitment contract data | Yes | Account lifetime | None |
| Stripe payment tokens | Yes (via Stripe) | Managed by Stripe | Stripe |
| Charge records | Yes | Legal/tax retention | Every.org (disbursement) |
| Proof photos/video | Conditional | Until task deleted if opted in | None |
| Watch Mode frames | Processed in-flight | NOT stored | None |
| HealthKit data | Optional | NOT retained | None |
| Usage/crash data | Yes | Limited period | None (Apple crash reporter) |

### Legal Placeholders

Use `TODO(legal)` comments for items requiring legal review before App Store submission:
- Legal entity name (Section 1)
- GDPR section may need expansion for EU launch (deferred to v2)

Use `privacy@ontaskhq.com` as the contact email (confirmed in user request).

### CSS Pattern — Reusing Shared Stylesheet

`style.css` already defines these reusable classes used by `index.html`:
- `.container` — `max-width: 1100px`, centred with padding
- `.site-header` — top nav bar with border-bottom
- `.wordmark` — terracotta brand name style
- `.site-footer` — bottom footer

The `.prose` class added by this story is the only new CSS needed. It narrows the max-width to 720px for comfortable reading of long-form legal text.

### Story 13.2 Learnings

- `_headers` file uses Cloudflare Pages syntax (not Netlify): two-space indented headers, blank lines between path blocks
- `wrangler pages dev` parsed 5 valid header rules after Story 13.2 — verify it parses the new block cleanly
- The `style.css` file was 6.1KB after Story 13.2; the prose addition will stay well under 10KB limit
- App Store badge SVG is inlined — no external image assets needed
- System font stack (`-apple-system, BlinkMacSystemFont, ...`) is used — no fonts to import

### App Store Review — Required Disclosures

The following must be present for App Store review to pass (MKTG-5):

1. **Camera usage (Watch Mode)** — must state frames are NOT stored; must explain purpose
2. **HealthKit usage** — must state data is NOT shared with third parties; must explain purpose
3. **Payment data** — must state PCI SAQ A scope (no raw card storage)
4. **Proof media retention** — must explain user choice at completion time
5. **Account deletion and data retention** — must state 30-day deletion window

### Deployment

No CI/CD changes needed. The `deploy-marketing` job deploys the entire `apps/marketing/` directory. Adding `privacy/index.html` is sufficient — it will be served at `/privacy/` automatically.

### References

- Epics file: `_bmad-output/planning-artifacts/epics.md` — MKTG-5, Story 13.3 AC
- PRD: `_bmad-output/planning-artifacts/prd.md` — §Privacy & Data Handling, §Payment & Financial Compliance
- Previous story: `_bmad-output/implementation-artifacts/13-2-marketing-site-core-pages.md` — establishes `style.css`, `_headers` patterns
- Story 13.1: `_bmad-output/implementation-artifacts/13-1-aasa-file-payment-setup-page.md` — establishes Cloudflare Pages structure

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation completed without issues.

### Completion Notes List

- Created `apps/marketing/privacy/index.html`: static HTML privacy policy page with all 11 required sections (Introduction, Information We Collect, How We Use, Third Parties, Data Retention, Your Rights, Watch Mode/Camera Disclosure, HealthKit Disclosure, Children's Privacy, Policy Changes, Contact). All 5 App Store required disclosures present: Watch Mode frames not stored, HealthKit not shared/retained, PCI SAQ A payment scope, proof media user choice, 30-day account deletion window. No JavaScript. Links to `../style.css`. Effective date and last-updated date set to April 2, 2026. TODO(legal) placeholder for legal entity name. CCPA and GDPR sections included.
- Appended `.prose` CSS block to `apps/marketing/style.css`: 8 new rules for long-form legal content. Max-width 720px, correct heading hierarchy, terracotta link colours using existing CSS custom properties. File size increased from 6.1KB to 7.1KB (well within 10KB limit). Existing marketing page styles fully preserved.
- Updated `apps/marketing/_headers`: appended `/privacy/` cache block (max-age=300, stale-while-revalidate=3600). All existing 5 header rules preserved. Wrangler now parses 6 valid header rules.
- Smoke-tested via `npx wrangler pages dev`: `/privacy/` 200 with all required content (Watch Mode, HealthKit, Stripe, April 2 2026 date); `/` 200 (no regression); `/setup/` 200 (no regression); `/subscribe/` 200 (no regression); `/.well-known/apple-app-site-association` Content-Type `application/json` (no regression).

### File List

- apps/marketing/privacy/index.html (created)
- apps/marketing/style.css (modified — appended .prose styles)
- apps/marketing/_headers (modified — appended /privacy/ cache rule)
- _bmad-output/implementation-artifacts/13-3-privacy-policy-page.md (story file updated)
- _bmad-output/implementation-artifacts/sprint-status.yaml (status updated)

### Change Log

- 2026-04-02: Story 13.3 implemented — created privacy policy page (privacy/index.html), added .prose CSS to style.css, added /privacy/ cache rule to _headers.
