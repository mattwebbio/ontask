# Story 9.2: Paywall Screen

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user reaching trial expiry,
I want a clear paywall that makes subscribing easy,
so that the path to continuing feels like an obvious next step, not a wall.

## Acceptance Criteria

1. **Given** a user's trial has expired
   **When** they launch the app
   **Then** the Paywall Screen is the first thing shown — not a modal over app content (FR88)
   **And** the paywall shows the three subscription tiers with pricing and a brief feature comparison
   **And** a "Restore purchase" option is available for users who have previously subscribed

2. **Given** the paywall is shown
   **When** a user who has no payment history views it
   **Then** copy is inviting and benefit-focused — no dark patterns, no artificial urgency language
   **And** cancellation terms are clearly displayed alongside the subscribe CTA

## Tasks / Subtasks

---

### Task 1: Flutter — `PaywallScreen` widget (AC: 1, 2)

Create the paywall screen. It is a **full-screen route outside the `StatefulShellRoute`** (same as `/chapter-break`, `/onboarding`, `/auth/sign-in`) — no shell chrome, no tab bar. The screen must be the first thing shown when `status.isExpired` is true.

- [x] Create `apps/flutter/lib/features/subscriptions/presentation/paywall_screen.dart`:
  - `ConsumerWidget` (needs `ref.watch(subscriptionStatusProvider)` to confirm expired state)
  - Import `package:flutter_riverpod/flutter_riverpod.dart` for `ConsumerWidget`/`ConsumerStatefulWidget` (widget files use `flutter_riverpod`; provider files use `riverpod_annotation` only)
  - Import `package:flutter/cupertino.dart` — use Cupertino widgets throughout, consistent with all other screens
  - Import `package:go_router/go_router.dart` — for `context.go('/now')` after subscription activation (Story 9.3)
  - Import `'../../../core/l10n/strings.dart'`
  - Import `'subscriptions_provider.dart'`

  **Screen layout (scrollable — `ListView` or `SingleChildScrollView`):**
  ```
  ┌─────────────────────────────────────────────┐
  │  [Close / X button — top right, if pushed   │
  │   from settings; absent when forced on      │
  │   trial expiry and no back stack]           │
  │                                             │
  │  Headline: AppStrings.paywallHeadline       │
  │  Subheadline: AppStrings.paywallSubheadline │
  │                                             │
  │  ┌─────────────────────────────────────┐   │
  │  │  _TierCard(tier: SubscriptionTier.  │   │
  │  │           individual)               │   │
  │  └─────────────────────────────────────┘   │
  │  ┌─────────────────────────────────────┐   │
  │  │  _TierCard(tier: SubscriptionTier.  │   │
  │  │           couple)                   │   │
  │  └─────────────────────────────────────┘   │
  │  ┌─────────────────────────────────────┐   │
  │  │  _TierCard(tier: SubscriptionTier.  │   │
  │  │           familyAndFriends)         │   │
  │  └─────────────────────────────────────┘   │
  │                                             │
  │  [Cancellation terms copy]                 │
  │  [Restore purchase CTA]                    │
  └─────────────────────────────────────────────┘
  ```

- [x] Define `SubscriptionTier` enum **in `paywall_screen.dart`** (local to this file — not a domain model; tier display data is UI-only until Story 9.3 wires real Stripe Price IDs):
  ```dart
  enum SubscriptionTier {
    individual,
    couple,
    familyAndFriends;
  }
  ```

- [x] Create private `_TierCard` widget in the same file. Each card shows:
  - Tier name (from `AppStrings`)
  - Price string (from `AppStrings`)
  - One-line feature description (from `AppStrings`)
  - A "Subscribe" `CupertinoButton` (filled style)
    - `onPressed`: `impl(9.2): context.push` to `ontaskhq.com/subscribe?tier=...` via `url_launcher` — wire in Story 9.3 when Universal Links are live (Epic 13 Story 13.1)
    - For now the button is **enabled** but calls `impl(9.2):` stub (no-op or snackbar)

- [x] "Restore purchase" button — `CupertinoButton` (plain/borderless style, smaller text):
  - `onPressed`: `impl(9.2):` stub — no-op for now
  - Positioned below the tier cards, above cancellation terms

- [x] Cancellation terms copy — small grey text below the tier cards:
  ```dart
  Text(
    AppStrings.paywallCancellationTerms,
    style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
    textAlign: TextAlign.center,
  )
  ```

- [x] No `CupertinoNavigationBar` — the paywall is a standalone full-screen experience. Use top padding via `SafeArea` only.

**CRITICAL UX CONSTRAINT (FR88 / epic requirement):** The paywall must communicate value, not just gate access. Copy must be benefit-focused ("Continue doing your best work" not "Trial expired"). No countdown timers, no artificial urgency, no dark patterns. Cancellation terms must be clearly readable (not hidden in fine print).

**File to create:** `apps/flutter/lib/features/subscriptions/presentation/paywall_screen.dart`

---

### Task 2: Flutter — `AppStrings` additions for paywall copy (AC: 1, 2)

Add strings to `apps/flutter/lib/core/l10n/strings.dart`. Add at the **END** of the `AppStrings` class, after the existing subscription strings block (which ends around line 1290). Follow the same block-comment pattern.

- [x] Add at the end of the `AppStrings` class:
  ```dart
  // ── Subscriptions — Paywall Screen (FR88, Story 9.2) ─────────────────────────

  /// Main headline — benefit-focused, not urgency-driven.
  static const String paywallHeadline = 'Continue doing your best work';

  /// Subheadline — describes the value proposition briefly.
  static const String paywallSubheadline =
      'Choose a plan to keep full access to scheduling, shared lists, and commitment contracts.';

  /// Individual tier name.
  static const String paywallTierIndividualName = 'Individual';

  /// Individual tier price — approximate; exact price TBD at launch.
  static const String paywallTierIndividualPrice = '~\$10 / month';

  /// Individual tier one-line feature description.
  static const String paywallTierIndividualFeature =
      'Full access for one person';

  /// Couple tier name.
  static const String paywallTierCoupleName = 'Couple';

  /// Couple tier price — placeholder; exact pricing TBD.
  static const String paywallTierCouplePrice = 'Coming soon';

  /// Couple tier one-line feature description.
  static const String paywallTierCoupleFeature =
      'Shared lists and commitments for two';

  /// Family & Friends tier name.
  static const String paywallTierFamilyName = 'Family \u0026 Friends';

  /// Family & Friends tier price — placeholder; exact pricing TBD.
  static const String paywallTierFamilyPrice = 'Coming soon';

  /// Family & Friends tier one-line feature description.
  static const String paywallTierFamilyFeature =
      'Up to five people, shared accountability';

  /// "Subscribe" button label on tier cards.
  static const String paywallSubscribeCta = 'Subscribe';

  /// "Restore purchase" button label.
  static const String paywallRestorePurchase = 'Restore purchase';

  /// Cancellation terms shown below tier cards — honest and clear.
  static const String paywallCancellationTerms =
      'Cancel any time. Active commitment contracts continue until their individual deadlines regardless of subscription status.';
  ```

**File to modify:** `apps/flutter/lib/core/l10n/strings.dart`

---

### Task 3: Flutter — router redirect for expired trial (AC: 1)

The paywall must be **the first thing shown** when a trial has expired — not a modal over app content (FR88). This is implemented as a GoRouter redirect, identical to the pattern used for the onboarding gate.

- [x] Register the `/paywall` route as a **top-level route** (outside `StatefulShellRoute`) in `apps/flutter/lib/core/router/app_router.dart`:
  ```dart
  // Paywall route — top-level, no shell chrome (Epic 9, Story 9.2, FR88).
  // Shown as the first screen when trial has expired and no active subscription.
  GoRoute(
    path: '/paywall',
    builder: (context, state) => const PaywallScreen(),
  ),
  ```
  Place it alongside `/onboarding`, `/chapter-break`, `/farewell` — NOT inside the `StatefulShellRoute`.

- [x] Import `PaywallScreen` at the top of `app_router.dart`:
  ```dart
  import '../../features/subscriptions/presentation/paywall_screen.dart';
  ```

- [x] Add paywall redirect logic inside the existing `redirect:` callback in `appRouter`. Add it **after the onboarding gate** (after line ~88 in the current file):
  ```dart
  // Paywall gate — expired trial blocks all authenticated routes (FR88).
  // Reads subscription status synchronously if cached; otherwise defers to
  // subscriptionStatusProvider loading state (no redirect until data available).
  // impl(9.2): Read subscriptionStatusProvider and redirect to /paywall
  //   when status.isExpired is true and current route is not /paywall.
  //   Use ref.read(subscriptionStatusProvider) — do NOT use ref.watch inside redirect.
  //   Guard: only redirect when subscriptionStatusProvider has data (AsyncData).
  //   Skip redirect for /settings/* so expired users can reach /settings/subscription.
  ```
  **IMPORTANT — STUB ONLY:** Do NOT implement the real redirect logic yet. The redirect requires `ref.read(subscriptionStatusProvider)` inside the GoRouter `redirect` callback. The provider is async (`AutoDisposeFutureProvider`) — the real implementation must handle the `AsyncLoading`/`AsyncError`/`AsyncData` states correctly. This is deferred because:
  1. The stub API always returns `trialing` (Story 9.1 stub) — a real redirect would never fire against the stub.
  2. The redirect architecture needs care to avoid redirect loops when the provider is still loading.
  Add the `impl(9.2):` comment block above so Story 9.3 can wire the real redirect when the API returns real data.

- [x] **Also** add `impl(9.2):` comment in `SubscriptionSettingsScreen._StatusSection.build()` where the expired state is shown, noting that Story 9.2 adds the paywall route and Story 9.3 wires the subscribe CTA:
  In `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`, update the `impl(9.1)` comment on the expired state:
  ```dart
  // impl(9.2): Add "Subscribe" CTA here (same tiers as PaywallScreen) — wire
  //   in Story 9.3 when ontaskhq.com/subscribe Universal Link is available.
  ```
  Remove the old `// impl(9.1): Add subscription tier selection CTA when Story 9.2 paywall lands.` comment and replace with this updated one.

**Files to modify:**
- MODIFY: `apps/flutter/lib/core/router/app_router.dart`
- MODIFY: `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`

---

### Task 4: Flutter — API stub — `GET /v1/subscriptions/paywall-config` (AC: 1)

Add a stub endpoint that will eventually return tier pricing. This story creates the stub only — real Stripe Price IDs come in Story 9.3.

- [x] In `apps/api/src/routes/subscriptions.ts`, add the `GET /v1/subscriptions/paywall-config` route after the existing `GET /v1/subscriptions/me` route:

  **Schema:**
  ```typescript
  const TierSchema = z.object({
    tier: z.enum(['individual', 'couple', 'family_and_friends']),
    displayName: z.string(),
    priceDisplay: z.string(),       // e.g. "~$10 / month" — localised display string
    stripePriceId: z.string().nullable(), // null until Story 9.3 wires real Price IDs
    available: z.boolean(),         // false = "coming soon" (couple, family for now)
  })

  const PaywallConfigResponseSchema = z.object({
    data: z.object({
      tiers: z.array(TierSchema),
    }),
  })
  ```

  **Route:**
  ```typescript
  const getPaywallConfigRoute = createRoute({
    method: 'get',
    path: '/v1/subscriptions/paywall-config',
    tags: ['Subscriptions'],
    summary: 'Get paywall tier configuration',
    description:
      'Returns tier display configuration for the paywall screen. ' +
      'stripePriceId is null until Story 9.3 wires real Stripe Price IDs. ' +
      'available=false means the tier is shown as "coming soon". ' +
      'FR88, FR83: used to populate PaywallScreen tier cards.',
    responses: {
      200: {
        content: { 'application/json': { schema: PaywallConfigResponseSchema } },
        description: 'Paywall tier configuration',
      },
    },
  })

  app.openapi(getPaywallConfigRoute, async (_c) => {
    // TODO(impl): In future, fetch dynamic pricing from Stripe or config store.
    // For now: static stub — exact prices TBD at launch per product brief (~$10/mo Individual).
    return _c.json(
      ok({
        tiers: [
          {
            tier: 'individual' as const,
            displayName: 'Individual',
            priceDisplay: '~$10 / month',
            stripePriceId: null,
            available: true,
          },
          {
            tier: 'couple' as const,
            displayName: 'Couple',
            priceDisplay: 'Coming soon',
            stripePriceId: null,
            available: false,
          },
          {
            tier: 'family_and_friends' as const,
            displayName: 'Family & Friends',
            priceDisplay: 'Coming soon',
            stripePriceId: null,
            available: false,
          },
        ],
      }),
      200,
    )
  })
  ```

  **CRITICAL:** Do NOT add `createDb` or Drizzle imports — Drizzle TS2345 typecheck incompatibility causes CI failures. Stub only.

**File to modify:** `apps/api/src/routes/subscriptions.ts`

---

### Task 5: API — Tests for paywall config endpoint (AC: 1)

Add tests to the existing `apps/api/test/routes/subscriptions.test.ts`. Add after the existing 5 tests for `GET /v1/subscriptions/me`.

- [x] Add a new `describe` block:
  ```typescript
  describe('GET /v1/subscriptions/paywall-config', () => {
    it('returns 200', ...)
    it('response shape has data.tiers array', ...)
    it('data.tiers has exactly 3 entries', ...)
    it('all tiers have required fields: tier, displayName, priceDisplay, available', ...)
    it('individual tier available is true', ...)
    it('individual tier stripePriceId is null (stub phase)', ...)
  })
  ```

- [x] **Minimum 6 new tests** — total API test count after this story: 268 (current) + 6 = 274+
- [x] **Do not break existing 268 tests.** Run `pnpm test --filter apps/api` to verify.

**File to modify:** `apps/api/test/routes/subscriptions.test.ts`

---

### Task 6: Flutter — Widget tests for `PaywallScreen` (AC: 1, 2)

Add widget tests. Follow existing patterns in `apps/flutter/test/features/subscriptions/`.

- [x] Create `apps/flutter/test/features/subscriptions/paywall_screen_test.dart`:

  Setup pattern — follow `subscription_settings_screen_test.dart`:
  - Use `ProviderScope` with `overrides` to inject known `subscriptionStatusProvider` state
  - Use `SubscriptionStatus` with `state: SubscriptionState.expired` for the primary test scenario

  Tests to write:
  1. `PaywallScreen` renders without errors when subscription is expired
  2. Paywall headline text (`AppStrings.paywallHeadline`) is visible
  3. Individual tier name (`AppStrings.paywallTierIndividualName`) is visible
  4. Couple tier name (`AppStrings.paywallTierCoupleName`) is visible
  5. Family & Friends tier name (`AppStrings.paywallTierFamilyName`) is visible
  6. "Subscribe" button is present (at least one `AppStrings.paywallSubscribeCta` text found)
  7. "Restore purchase" button is present (`AppStrings.paywallRestorePurchase` text found)
  8. Cancellation terms text is visible (`AppStrings.paywallCancellationTerms`)
  9. Individual tier price text (`AppStrings.paywallTierIndividualPrice`) is visible
  10. Screen renders correctly when `subscriptionStatusProvider` is in `AsyncLoading` state (no crash)

- [x] Also add the **missing error-state test for `SubscriptionSettingsScreen`** (deferred from Story 9.1 code review — see `deferred-work.md`):
  In `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`, add test #5:
  - Error state shows `AppStrings.subscriptionSettingsLoadError` text
  - Use a `Completer` that calls `completeError(Exception('test error'))` to drive the provider into error state

- [x] **Minimum 11 new widget tests** (10 for `PaywallScreen` + 1 deferred from `SubscriptionSettingsScreen`):
  - Total Flutter test count after this story: 904 (current) + 11 = 915+
- [x] **Do not break existing 904 Flutter tests.** Run `flutter test` from `apps/flutter/` to verify.

**Files to create/modify:**
- CREATE: `apps/flutter/test/features/subscriptions/paywall_screen_test.dart`
- MODIFY: `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`

---

## Dev Notes

### Architecture Constraints — Must Follow

**API: Drizzle TS2345 stub pattern**
- All route handler implementations use `TODO(impl)` comment stubs. Do NOT add `createDb(c.env.DATABASE_URL)`, Drizzle imports, or any direct DB calls to route files. Pre-existing TS2345 `PgTableWithColumns` typecheck incompatibility causes CI failures.
- See `apps/api/src/routes/subscriptions.ts` (already exists from Story 9.1) — add the new endpoint in this same file following the existing pattern.

**Flutter: `.g.dart` files — Riverpod 3.x class-based pattern**
- CI does not run `build_runner`. Manually-maintained `.g.dart` files use the **Riverpod 3.x `$FunctionalProvider` class-based pattern** — NOT the older `AutoDisposeProvider<T>.internal(...)` style.
- Story 9.1 established both patterns in the repo:
  - `subscriptions_provider.g.dart` → `$FunctionalProvider` with `$FutureModifier`/`$FutureProvider` (async)
  - `subscriptions_repository.g.dart` → `$FunctionalProvider` with `$Provider` (sync)
- This story adds NO new Riverpod providers — `subscriptionStatusProvider` from Story 9.1 is already available and sufficient. Do NOT create additional providers for the paywall.
- Hash strings use `impl(9.2):placeholder` format.

**Flutter: Riverpod import discipline**
- Only import `package:riverpod_annotation/riverpod_annotation.dart` in provider and repository files.
- Only import `package:flutter_riverpod/flutter_riverpod.dart` in widget files (`ConsumerWidget`, `ConsumerStatefulWidget`).
- `PaywallScreen` is a widget → use `flutter_riverpod`.

**Flutter: No new `.g.dart` files needed for this story**
- `PaywallScreen` reads from the existing `subscriptionStatusProvider` (already in `subscriptions_provider.dart`).
- No new `@riverpod` providers or repositories are introduced in this story.

**Flutter: Deferred implementation prefix**
- Use `impl(9.2):` for all deferred implementation notes in Dart files.
- The Flutter linter flags `TODO:` as a warning — never use `TODO:` prefix.

**GoRouter redirect — paywall gate is a stub only in this story**
- The real paywall redirect (`ref.read(subscriptionStatusProvider)` inside `redirect:`) is deferred. The stub API (Story 9.1) always returns `status: 'trialing'`, so a real redirect would never fire in the current environment.
- Add the `impl(9.2):` comment block in the router as a clear signal for Story 9.3 to implement the real redirect.
- The `/paywall` route must be registered now so Story 9.3's redirect can target it.

### Paywall Route Architecture

The paywall screen follows the **top-level route pattern** (same as `ChapterBreakScreen`, `OnboardingFlow`, `AuthScreen`):
- Registered OUTSIDE `StatefulShellRoute.indexedStack`
- No tab bar, no navigation bar chrome
- No `CupertinoNavigationBar` on the screen itself — full-screen focus experience
- Entry: redirect in `appRouter` when `status.isExpired` (Story 9.3 wires the redirect; this story registers the route)
- Exit: `context.go('/now')` after subscription activation (Story 9.3); not needed yet

The existing router redirect chain (lines ~50–92 of `app_router.dart`):
1. 2FA challenge → `/auth/2fa-verify`
2. Not authenticated → `/auth/sign-in`
3. Authenticated + onboarding not complete → `/onboarding`
4. **[Story 9.3 adds here]** Authenticated + trial expired + no subscription → `/paywall`

### Subscription Status Provider — Already Available

`subscriptionStatusProvider` is defined in `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.dart` (created in Story 9.1). Do not recreate it.

Available computed getters on `SubscriptionStatus`:
- `status.isExpired` → `state == SubscriptionState.expired`
- `status.isTrialing` → `state == SubscriptionState.trialing`
- `status.isActive` → `state == SubscriptionState.active`
- `status.showTrialCountdownBanner` → `isTrialing && trialDaysRemaining != null && trialDaysRemaining! <= 3`

### Subscription Settings Screen — Existing Stub to Update

`subscription_settings_screen.dart` has the comment `// impl(9.1): Add subscription tier selection CTA when Story 9.2 paywall lands.` (line 31). This story replaces that comment with an `impl(9.2):` forward reference to Story 9.3's subscribe CTA work.

### Tier Pricing Reference

Per product brief and MKTG-2:
- **Individual:** ~$10/month (anchor price — exact to be validated at launch)
- **Couple:** pricing TBD — show as "Coming soon" for now
- **Family & Friends:** pricing TBD — show as "Coming soon" for now

The `paywallTierCouplePrice` and `paywallTierFamilyPrice` strings are deliberately "Coming soon" — these tiers are part of the product vision but pricing has not been confirmed. Do not hardcode speculative pricing.

### File Locations

| File | Purpose |
|---|---|
| `apps/flutter/lib/features/subscriptions/presentation/paywall_screen.dart` | New: Paywall full-screen route |
| `apps/api/src/routes/subscriptions.ts` | Modify: Add `GET /v1/subscriptions/paywall-config` endpoint |
| `apps/api/test/routes/subscriptions.test.ts` | Modify: Add paywall-config tests |
| `apps/flutter/lib/core/l10n/strings.dart` | Modify: Add paywall string block at end of class |
| `apps/flutter/lib/core/router/app_router.dart` | Modify: Register `/paywall` route + impl(9.2) redirect stub |
| `apps/flutter/test/features/subscriptions/paywall_screen_test.dart` | New: Widget tests |
| `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` | Modify: Add deferred error-state test |

### Existing Files Modified

| File | Change |
|---|---|
| `apps/api/src/routes/subscriptions.ts` | Add `GET /v1/subscriptions/paywall-config` stub route |
| `apps/api/test/routes/subscriptions.test.ts` | Add 6 tests for new endpoint |
| `apps/flutter/lib/core/l10n/strings.dart` | New paywall string block at end of `AppStrings` class |
| `apps/flutter/lib/core/router/app_router.dart` | Import `PaywallScreen`; add `/paywall` top-level `GoRoute`; add `impl(9.2):` redirect comment |
| `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` | Update `impl(9.1)` stub comment to `impl(9.2)` |
| `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` | Add error-state test (deferred from Story 9.1 code review) |

### API Test Count Reference

- Current passing API tests before this story: **268** (after Story 9.1)
- After this story: **274+** (6 minimum new tests for `GET /v1/subscriptions/paywall-config`)
- Run: `pnpm test --filter apps/api`

### Flutter Test Count Reference

- Current passing Flutter tests before this story: **904** (after Story 9.1)
- After this story: **915+** (10 `PaywallScreen` tests + 1 deferred `SubscriptionSettingsScreen` error test)
- Run: `flutter test` from `apps/flutter/`

### Deferred Items from Prior Stories (relevant to this story)

From `deferred-work.md`:

- **Missing error-state widget test for `SubscriptionSettingsScreen`** — The error branch (showing `subscriptionSettingsLoadError`) is not covered. This story resolves it in Task 6 by adding the test in `subscription_settings_screen_test.dart`. [`apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`]

- `response.data!` null-assertion pattern (pre-existing from Story 8.5 / 9.1) — `subscriptions_repository.dart` follows this same pattern. Pre-existing; address when error-handling conventions are standardised.

### Story 9.3 Dependency Note

Story 9.3 (Tier Selection & Subscription Activation) **requires Epic 13 Story 13.1 (AASA + Universal Links) to be deployed** before it can be tested end-to-end. The `/paywall` route and tier cards created in this story are the UI entry point for Story 9.3's subscribe flow (`context.push` to `ontaskhq.com/subscribe?tier=...`). The subscribe button `onPressed` handlers are stubs (`impl(9.2):`) in this story.

### Epic 9 Cross-Story Context

- **Story 9.1 → 9.2:** `SubscriptionSettingsScreen` has `impl(9.1)` comment for the subscribe CTA. Update it to `impl(9.2)` pointing to Story 9.3.
- **Story 9.2 → 9.3:** Story 9.3 wires the subscribe button (opens `ontaskhq.com/subscribe?tier=...` via `url_launcher`), implements the GoRouter paywall redirect (when `subscriptionStatusProvider` returns `isExpired`), and invalidates `subscriptionStatusProvider` after successful subscription activation.
- **Story 9.3 → 9.4 / 9.5:** Active and grace_period subscription states in `SubscriptionSettingsScreen` are handled in Stories 9.3–9.5 (see `impl(9.1):` comment in `subscription_settings_screen.dart` line 71).

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` Epic 9, Story 9.2 — ACs, FR88, FR83]
- [Source: `_bmad-output/planning-artifacts/epics.md` Epic 13, Story 13.1 — `ontaskhq.com/subscribe` URL, tier query parameter, Universal Links dependency]
- [Source: `_bmad-output/planning-artifacts/epics.md` MKTG-2 — three tier names: Individual/Couple/Family & Friends, ~$10/mo anchor]
- [Source: `_bmad-output/planning-artifacts/prd.md` FR88, FR83 — paywall at trial expiry, tier selection]
- [Source: `_bmad-output/implementation-artifacts/9-1-free-trial-launch-status-visibility.md` — `SubscriptionStatus` domain model, `subscriptionStatusProvider`, `.g.dart` pattern, `impl(X.Y):` prefix, Drizzle TS2345 stub pattern]
- [Source: `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.g.dart` — Riverpod 3.x `$FunctionalProvider` class-based pattern (NOT `AutoDisposeProvider.internal`)]
- [Source: `apps/flutter/lib/core/router/app_router.dart` — top-level GoRoute pattern, redirect callback structure, onboarding gate as paywall gate model]
- [Source: `apps/flutter/lib/features/chapter_break/presentation/chapter_break_screen.dart` — full-screen no-shell route pattern]
- [Source: `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` — existing `impl(9.1)` stub to update, `SubscriptionStatus` computed getter usage]
- [Source: `apps/api/src/routes/subscriptions.ts` — existing subscription route file, schema patterns, `ok()` response helper]
- [Source: `apps/flutter/lib/core/l10n/strings.dart` — `AppStrings` addition pattern (end of class)]
- [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — missing error-state test for `SubscriptionSettingsScreen` (deferred from 9.1 review)]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Implemented `PaywallScreen` as a `ConsumerWidget` with scrollable `ListView` layout — headline, subheadline, three `_TierCard` widgets (Individual/Couple/Family & Friends), Restore purchase `CupertinoButton`, and cancellation terms. No `CupertinoNavigationBar`; `SafeArea` only.
- `SubscriptionTier` enum defined locally in `paywall_screen.dart` (UI-only, not a domain model).
- `_TierCard` shows tier name, price, feature line, and a filled `CupertinoButton.filled` Subscribe CTA. Subscribe and Restore purchase `onPressed` are `impl(9.2):` stubs per spec.
- Added full paywall string block (12 strings) to end of `AppStrings` class in `strings.dart`.
- Registered `/paywall` as a top-level `GoRoute` in `app_router.dart` (outside `StatefulShellRoute`), imported `PaywallScreen`, and added `impl(9.2):` redirect stub comment block after the onboarding gate.
- Updated `impl(9.1)` comment in `subscription_settings_screen.dart` to `impl(9.2)` per spec.
- Added `GET /v1/subscriptions/paywall-config` stub endpoint to `subscriptions.ts` with `TierSchema`, `PaywallConfigResponseSchema`, and `getPaywallConfigRoute`. No Drizzle imports (Drizzle TS2345 pattern maintained).
- Added 6 API tests for new endpoint in `subscriptions.test.ts` — total API tests: 274 (all pass).
- Created `paywall_screen_test.dart` with 10 widget tests. Two tests (Restore purchase / cancellation terms) use `scrollUntilVisible` since these items are below the initial viewport in the scrollable `ListView`. Total Flutter tests: 915 (all pass).
- Added deferred error-state test for `SubscriptionSettingsScreen` in `subscription_settings_screen_test.dart` (deferred from Story 9.1 code review). Uses a `Completer` driven to error state.

### File List

apps/flutter/lib/features/subscriptions/presentation/paywall_screen.dart (created)
apps/flutter/lib/core/l10n/strings.dart (modified)
apps/flutter/lib/core/router/app_router.dart (modified)
apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart (modified)
apps/api/src/routes/subscriptions.ts (modified)
apps/api/test/routes/subscriptions.test.ts (modified)
apps/flutter/test/features/subscriptions/paywall_screen_test.dart (created)
apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart (modified)
_bmad-output/implementation-artifacts/sprint-status.yaml (modified)

## Change Log

- 2026-04-01: Story 9.2 implemented — PaywallScreen widget, AppStrings paywall block, /paywall route registration, impl(9.2) redirect stub, GET /v1/subscriptions/paywall-config stub endpoint, 6 API tests (274 total), 11 Flutter widget tests (915 total), deferred SubscriptionSettingsScreen error-state test resolved.
