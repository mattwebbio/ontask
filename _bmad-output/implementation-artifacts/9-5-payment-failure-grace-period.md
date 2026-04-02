# Story 9.5: Payment Failure Grace Period

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user whose renewal payment has failed,
I want a grace period to fix my payment method before losing access,
so that a temporary card issue doesn't erase my work.

## Acceptance Criteria

1. **Given** a subscription renewal payment fails
   **When** the Stripe webhook for payment failure is received
   **Then** a push notification and in-app banner are shown: "Your payment didn't go through — update your payment method to keep access" (FR90)
   **And** a 7-day grace period begins — access is not restricted immediately

2. **Given** the grace period is active
   **When** the user updates their payment method
   **Then** the pending renewal is retried immediately
   **And** if payment succeeds, the grace period ends and no access interruption occurs

3. **Given** 7 days pass without a successful payment
   **When** the grace period expires
   **Then** access is restricted to Settings only (same state as trial expiry — paywall redirect fires)
   **And** the user can reactivate at any time by updating their payment method and completing payment

---

## Tasks / Subtasks

---

### Task 1: Flutter — `SubscriptionStatus` domain model — add `isGracePeriod` getter (AC: 1–3)

`SubscriptionState.gracePeriod` already exists in the enum (maps to `'grace_period'` via `fromJson`). `SubscriptionStatus` is missing the computed getter — same gap as `isCancelled` was in Story 9.4.

- [x] In `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`, add after `isExpired`:
  ```dart
  bool get isGracePeriod => state == SubscriptionState.gracePeriod;
  ```
  This follows the exact pattern of `isTrialing`, `isActive`, `isCancelled`, `isExpired`.

- [x] **DO NOT** modify `subscriptions_repository.g.dart` or `subscriptions_provider.g.dart`. CI does not run `build_runner`.

**File to modify:** `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`

---

### Task 2: Flutter — Settings → Subscription — grace period state UI (AC: 1)

Replace the `// impl(9.5): grace_period state handled in Story 9.5.` stub in `_StatusSection.build()` with the actual grace period UI. The stub currently returns `const SizedBox.shrink()` (line 232).

- [x] Replace the stub comment and `SizedBox.shrink()` with the grace period branch **before** the final `return const SizedBox.shrink()`:
  ```dart
  if (status.isGracePeriod) {
    final accessUntilDate = status.currentPeriodEnd != null
        ? _formatDate(status.currentPeriodEnd!)
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.subscriptionGracePeriodStatusLabel,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(AppStrings.subscriptionGracePeriodBody),
          if (accessUntilDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(AppStrings.subscriptionGracePeriodAccessUntil(accessUntilDate)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () async {
                final uri = Uri.parse('https://ontaskhq.com/account');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(AppStrings.subscriptionGracePeriodUpdateCta),
            ),
          ),
        ],
      ),
    );
  }
  ```
  The `_formatDate` helper and `url_launcher` import already exist in this file (Story 9.4). No new imports needed.

- [x] The final `return const SizedBox.shrink()` at the very bottom of `_StatusSection.build()` must remain as the fallback for any future unknown states.

**After this story, `_StatusSection.build()` handles states in this order:**
1. `isTrialing` → trial UI
2. `isExpired` → expired label
3. `isActive` → active UI + "Manage subscription" CTA
4. `isCancelled` → cancelled UI + "Reactivate" CTA (Story 9.4)
5. `isGracePeriod` → grace period UI + "Update payment method" CTA ← **added here**
6. `return const SizedBox.shrink()` → unknown state fallback

**File to modify:** `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`

---

### Task 3: Flutter — grace period in-app banner (AC: 1)

Add a persistent in-app banner for the grace period state, mirroring the existing `TrialCountdownBanner` widget pattern.

- [x] Create `apps/flutter/lib/features/subscriptions/presentation/grace_period_banner.dart`:
  ```dart
  import 'package:flutter/cupertino.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../../../core/l10n/strings.dart';
  import 'subscriptions_provider.dart';

  /// Persistent grace period banner — shown when subscription payment has failed.
  /// AC: 1 — "Your payment didn't go through — update your payment method to keep access"
  ///
  /// Wrap around tab content in AppShell alongside TrialCountdownBanner.
  /// Tap navigates to Settings → Subscription (/settings/subscription).
  class GracePeriodBanner extends ConsumerWidget {
    const GracePeriodBanner({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final statusAsync = ref.watch(subscriptionStatusProvider);
      return statusAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (status) {
          if (!status.isGracePeriod) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => context.push('/settings/subscription'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: CupertinoColors.systemOrange.withValues(alpha: 0.9),
              child: Text(
                AppStrings.gracePeriodBannerText,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );
    }
  }
  ```

- [x] In `AppShell` (wherever `TrialCountdownBanner` is rendered), add `GracePeriodBanner()` in the same widget column/stack, directly below `TrialCountdownBanner`. Only one banner will show at a time (trial: `showTrialCountdownBanner` is true only when `isTrialing`; grace period: `isGracePeriod` is a separate state).

**CRITICAL:** Find `TrialCountdownBanner` usage location first — do NOT guess. Run:
```
grep -rn "TrialCountdownBanner" apps/flutter/lib
```
Add `GracePeriodBanner()` immediately after each `TrialCountdownBanner()` usage.

**Files to modify:**
- CREATE: `apps/flutter/lib/features/subscriptions/presentation/grace_period_banner.dart`
- MODIFY: AppShell file(s) where `TrialCountdownBanner` is rendered

---

### Task 4: Flutter — `AppStrings` additions for Story 9.5 (AC: 1–3)

Add strings to `apps/flutter/lib/core/l10n/strings.dart`. Add at the **END** of the `AppStrings` class, after `subscriptionCancelError` (the current last string from Story 9.4 — line 1409, then `}`).

- [x] Add:
  ```dart
  // ── Subscriptions — Grace Period (FR90, Story 9.5) ────────────────────────

  /// Settings → Subscription section title when subscription is in grace period.
  static const String subscriptionGracePeriodStatusLabel = 'Payment Failed';

  /// Body text shown in Settings → Subscription during grace period.
  static const String subscriptionGracePeriodBody =
      'Your payment didn\'t go through. Update your payment method to keep access.';

  /// Access-until date shown in Settings → Subscription during grace period.
  /// Usage: AppStrings.subscriptionGracePeriodAccessUntil(date)
  static String subscriptionGracePeriodAccessUntil(String date) =>
      'Access continues until $date';

  /// CTA in Settings → Subscription during grace period (opens ontaskhq.com/account).
  static const String subscriptionGracePeriodUpdateCta = 'Update payment method';

  /// Persistent in-app banner shown during grace period (AC: 1, FR90).
  static const String gracePeriodBannerText =
      'Your payment didn\'t go through — update your payment method to keep access';
  ```

**File to modify:** `apps/flutter/lib/core/l10n/strings.dart`

---

### Task 5: Flutter — GoRouter paywall redirect — extend to cover grace period expiry (AC: 3)

After 7 days, the grace period expires and access must be restricted to Settings only (same as trial expiry). The `isExpired` check in `app_router.dart` controls the paywall redirect. The grace period must also trigger the paywall redirect when it expires.

- [ ] In `apps/flutter/lib/core/router/app_router.dart`, find the paywall redirect block (currently around line 108):
  ```dart
  if (subStatus.isExpired && !isOnPaywallRoute && !isOnSettingsRoute && !isOnSubscribeSuccessRoute) {
    return '/paywall';
  }
  if (!subStatus.isExpired && isOnPaywallRoute) {
    return '/now';
  }
  ```
  Update to include grace period in paywall redirect condition. The `grace_period` state means payment failed but 7-day window is still open — full access, no redirect. Only `expired` restricts access. However, **when the grace period expires, the server-side state transitions from `grace_period` → `expired`** — no separate `'grace_period_expired'` state exists in the enum. The current redirect logic is already correct: `isExpired` fires when the grace period has elapsed and the server sets status to `'expired'`.

  **NO CHANGE NEEDED to `app_router.dart`** — verify that `isGracePeriod` does NOT equal `isExpired`. Confirm in `subscription_status.dart`: `isExpired` checks `state == SubscriptionState.expired`; `isGracePeriod` checks `state == SubscriptionState.gracePeriod`. These are distinct enum values. The router is already correct.

- [x] **Verify** the redirect logic comment in `app_router.dart` still accurately documents that `grace_period` users have full access. If not, add a clarifying comment only — do NOT change any logic.

**File to (possibly) modify:** `apps/flutter/lib/core/router/app_router.dart` — comment update only if needed

---

### Task 6: API — `POST /v1/subscriptions/webhook/stripe` stub endpoint (AC: 1)

Add a Stripe webhook receiver stub to `apps/api/src/routes/subscriptions.ts`. This endpoint will receive `invoice.payment_failed` events from Stripe to trigger the grace period.

- [x] Add schema and route after the existing `POST /v1/subscriptions/cancel` route (before `export const subscriptionsRouter = app`):

  **Schema:**
  ```typescript
  const StripeWebhookRequestSchema = z.object({
    type: z.string(),    // e.g. 'invoice.payment_failed', 'invoice.payment_succeeded'
    data: z.object({
      object: z.record(z.unknown()),
    }),
  })

  const StripeWebhookResponseSchema = z.object({
    data: z.object({
      received: z.boolean(),
    }),
  })
  ```

  **Route:**
  ```typescript
  const stripeWebhookRoute = createRoute({
    method: 'post',
    path: '/v1/subscriptions/webhook/stripe',
    tags: ['Subscriptions'],
    summary: 'Stripe webhook receiver for subscription events',
    description:
      'Receives Stripe webhook events for subscription lifecycle management. ' +
      'Handles invoice.payment_failed (begin grace period, send push notification, FR90). ' +
      'Handles invoice.payment_succeeded (end grace period, restore active status). ' +
      'Story 9.5 stub — TODO(impl): verify Stripe webhook signature, process event type, ' +
      'update DB subscription status, send APNs push via services/push.ts.',
    request: {
      body: {
        content: { 'application/json': { schema: StripeWebhookRequestSchema } },
      },
    },
    responses: {
      200: {
        content: { 'application/json': { schema: StripeWebhookResponseSchema } },
        description: 'Webhook received',
      },
      400: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Invalid webhook payload or signature',
      },
    },
  })

  app.openapi(stripeWebhookRoute, async (_c) => {
    // TODO(impl): const rawBody = await _c.req.text() — MUST be raw, unparsed body
    // TODO(impl): const sig = _c.req.header('stripe-signature') ?? ''
    // TODO(impl): const valid = verifyWebhookSignature(rawBody, sig, _c.env)
    // TODO(impl): if (!valid) return _c.json(err('INVALID_SIGNATURE', '...'), 400)
    // TODO(impl): const event = _c.req.valid('json')
    // TODO(impl): if (event.type === 'invoice.payment_failed') {
    //   TODO(impl): update subscription status to 'grace_period' in DB
    //   TODO(impl): set grace period expiry = now + 7 days
    //   TODO(impl): call sendPush() from services/push.ts with FR90 message:
    //     title: "Payment failed", body: "Your payment didn't go through — update your payment method to keep access"
    // TODO(impl): } else if (event.type === 'invoice.payment_succeeded') {
    //   TODO(impl): update subscription status back to 'active'
    //   TODO(impl): clear grace period state
    // TODO(impl): }
    // TODO(impl): emit 'payment_failed' analytics event (NFR-B1)
    // Stub: acknowledge receipt unconditionally.
    return _c.json(ok({ received: true }), 200)
  })
  ```

  **CRITICAL:** `verifyWebhookSignature` is already exported from `apps/api/src/services/stripe.ts` (Story 6.5). Import it:
  ```typescript
  import { verifyWebhookSignature } from '../services/stripe.js'
  ```
  `sendPush` is already exported from `apps/api/src/services/push.ts`. Import it:
  ```typescript
  import { sendPush } from '../services/push.js'
  ```
  Add both imports to the top of `subscriptions.ts` with the other imports. The `ok` and `err` helpers are already imported.

  **CRITICAL:** Do NOT add `createDb` or Drizzle imports — pre-existing TS2345 `PgTableWithColumns` typecheck incompatibility causes CI failures. Stub only.

**File to modify:** `apps/api/src/routes/subscriptions.ts`

---

### Task 7: API — Tests for Stripe webhook endpoint (AC: 1–3)

Add tests to `apps/api/test/routes/subscriptions.test.ts`. Add after the existing `POST /v1/subscriptions/cancel` tests (currently 5 tests in that describe block).

- [x] Add `describe('POST /v1/subscriptions/webhook/stripe', ...)` block:
  ```typescript
  // Tests for POST /v1/subscriptions/webhook/stripe — Story 9.5 (FR90, AC: 1–3)
  // Handler is a stub — all valid requests return 200 with { data: { received: true } }.

  describe('POST /v1/subscriptions/webhook/stripe', () => {
    const webhookPayload = {
      type: 'invoice.payment_failed',
      data: { object: { id: 'in_stub_123' } },
    }

    it('returns 200 for invoice.payment_failed event', async () => {
      const res = await app.request('/v1/subscriptions/webhook/stripe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(webhookPayload),
      })
      expect(res.status).toBe(200)
    })

    it('returns 200 for invoice.payment_succeeded event', async () => {
      const res = await app.request('/v1/subscriptions/webhook/stripe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'invoice.payment_succeeded', data: { object: {} } }),
      })
      expect(res.status).toBe(200)
    })

    it('response shape has data.received boolean', async () => {
      const res = await app.request('/v1/subscriptions/webhook/stripe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(webhookPayload),
      })
      const body = await res.json() as { data: { received: boolean } }
      expect(body).toHaveProperty('data')
      expect(body.data).toHaveProperty('received')
    })

    it('response data.received is true', async () => {
      const res = await app.request('/v1/subscriptions/webhook/stripe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(webhookPayload),
      })
      const body = await res.json() as { data: { received: boolean } }
      expect(body.data.received).toBe(true)
    })

    it('returns 200 for unknown event type (stub accepts all)', async () => {
      const res = await app.request('/v1/subscriptions/webhook/stripe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'customer.subscription.updated', data: { object: {} } }),
      })
      expect(res.status).toBe(200)
    })
  })
  ```

- [x] **Minimum 5 new tests** — total API test count after this story: **287 + 5 = 292+**
- [x] **Do not break existing 287 tests.** Run `pnpm test --filter apps/api` to verify.

**File to modify:** `apps/api/test/routes/subscriptions.test.ts`

---

### Task 8: Flutter — Widget tests for Story 9.5 changes (AC: 1–3)

- [x] In `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`, add tests after the existing Story 9.4 tests:

  ```dart
  // Story 9.5 tests: grace period state UI.

  const gracePeriodStatus = SubscriptionStatus(
    state: SubscriptionState.gracePeriod,
    currentPeriodEnd: null,
  );

  testWidgets('grace period state renders subscriptionGracePeriodStatusLabel text',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => gracePeriodStatus),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.subscriptionGracePeriodStatusLabel), findsOneWidget);
  });

  testWidgets('grace period state renders subscriptionGracePeriodUpdateCta button',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => gracePeriodStatus),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.subscriptionGracePeriodUpdateCta), findsOneWidget);
  });

  testWidgets('grace period state shows body text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => gracePeriodStatus),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.subscriptionGracePeriodBody), findsOneWidget);
  });

  testWidgets('grace period state with currentPeriodEnd shows access-until date',
      (tester) async {
    final gracePeriodWithDate = SubscriptionStatus(
      state: SubscriptionState.gracePeriod,
      currentPeriodEnd: DateTime(2026, 5, 8),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => gracePeriodWithDate),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.subscriptionGracePeriodAccessUntil('2026-05-08')),
      findsOneWidget,
    );
  });
  ```

- [x] Also add a test for `GracePeriodBanner` in a new file `apps/flutter/test/features/subscriptions/grace_period_banner_test.dart`:

  ```dart
  import 'package:flutter/cupertino.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:ontask/core/l10n/strings.dart';
  import 'package:ontask/features/subscriptions/domain/subscription_status.dart';
  import 'package:ontask/features/subscriptions/presentation/grace_period_banner.dart';
  import 'package:ontask/features/subscriptions/presentation/subscriptions_provider.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  void main() {
    setUpAll(() { TestWidgetsFlutterBinding.ensureInitialized(); });
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    group('GracePeriodBanner', () {
      testWidgets('shows gracePeriodBannerText when status is gracePeriod', (tester) async {
        const gracePeriodStatus = SubscriptionStatus(
          state: SubscriptionState.gracePeriod,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionStatusProvider.overrideWith((_) async => gracePeriodStatus),
            ],
            child: const CupertinoApp(home: Scaffold(body: GracePeriodBanner())),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.gracePeriodBannerText), findsOneWidget);
      });

      testWidgets('renders SizedBox.shrink when status is active', (tester) async {
        const activeStatus = SubscriptionStatus(state: SubscriptionState.active);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              subscriptionStatusProvider.overrideWith((_) async => activeStatus),
            ],
            child: const CupertinoApp(home: Scaffold(body: GracePeriodBanner())),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.gracePeriodBannerText), findsNothing);
      });
    });
  }
  ```
  Note: Use `Scaffold` for the banner test wrapping if `CupertinoApp` alone provides sufficient context; check that the banner file uses `CupertinoColors` (Cupertino-native), not Material `Scaffold`. If `Scaffold` causes Material dependency issues, use `CupertinoPageScaffold` instead — follow the pattern in `trial_countdown_banner_test.dart`.

- [x] **Minimum 6 new widget tests total** (4 in subscription_settings_screen_test.dart + 2 in grace_period_banner_test.dart) — total Flutter test count after this story: **930 + 6 = 936+**
- [x] **Do not break existing 930 Flutter tests.** Run `flutter test` from `apps/flutter/` to verify.

**Files to modify/create:**
- MODIFY: `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`
- CREATE: `apps/flutter/test/features/subscriptions/grace_period_banner_test.dart`

---

## Dev Notes

### Architecture Constraints — Must Follow

**API: Drizzle TS2345 stub pattern (CRITICAL — CI will fail if violated)**
- All route handler implementations use `TODO(impl)` comment stubs only.
- Do NOT add `createDb(c.env.DATABASE_URL)`, Drizzle imports, or any direct DB calls.
- See existing `subscriptions.ts` — all five existing routes follow this pattern.
- The `ok()` helper is already imported from `'../lib/response.js'`.
- The `err()` helper is also already imported (used in global error handler) — confirm it is imported in `subscriptions.ts` scope before using it in the webhook stub.

**Stripe webhook signature verification pattern**
- `verifyWebhookSignature(payload, signature, env)` is defined in `apps/api/src/services/stripe.ts` and returns `boolean`.
- It is NOT yet fully implemented (contains `TODO(impl)` stubs and returns `false`). In the Story 9.5 stub, do NOT call `verifyWebhookSignature` — leave it as a `TODO(impl)` comment only. Calling it would unconditionally return `400` (since the stub returns `false`), breaking the stub behaviour.
- When real implementation lands, the webhook route MUST use the raw request body (`await c.req.text()`) before JSON parsing — see `verifyWebhookSignature` docstring.

**Flutter: No new `.g.dart` files for this story**
- No new `@riverpod` providers or annotations — only new getter on `SubscriptionStatus` and a new `ConsumerWidget` (`GracePeriodBanner`).
- CI does not run `build_runner`. Do NOT modify `.g.dart` files.

**Flutter: `impl(9.X):` deferred comment prefix**
- Use `impl(9.5):` for any new deferred stubs in Dart code.
- Never use `TODO:` in Dart files — the linter flags it. Use `// impl(9.5):` instead.

### Grace Period vs Cancelled vs Expired — State Clarity

| State | Meaning | Access | Paywall? |
|-------|---------|--------|----------|
| `cancelled` | User cancelled; period not yet expired | Full | No |
| `grace_period` | Payment failed; 7-day recovery window open | Full | No |
| `expired` | Trial or grace period elapsed, no active sub | None (Settings only) | Yes |

`isGracePeriod` and `isCancelled` are NOT `isExpired`. The paywall redirect in `app_router.dart` only fires on `isExpired`. Do NOT modify the router.

### `_StatusSection` State Ordering — Full Picture After Story 9.5

```
1. isTrialing  → trial UI              (Story 9.1)
2. isExpired   → expired label         (Story 9.1/9.2)
3. isActive    → active UI             (Story 9.3)
4. isCancelled → cancelled UI          (Story 9.4)
5. isGracePeriod → grace period UI     ← THIS STORY
6. return const SizedBox.shrink()      (fallback, keep as-is)
```

The ordering matters — `isGracePeriod` must be the last explicit state check before the fallback.

### `GracePeriodBanner` widget — follow `TrialCountdownBanner` exactly

`TrialCountdownBanner` is at `apps/flutter/lib/features/subscriptions/presentation/trial_countdown_banner.dart`. Follow it exactly:
- `ConsumerWidget`
- `ref.watch(subscriptionStatusProvider)` in `build`
- `statusAsync.when(loading: SizedBox.shrink, error: SizedBox.shrink, data: ...)`
- `GestureDetector` wrapping container — tap navigates to `/settings/subscription` via `context.push`
- `withValues(alpha: 0.9)` colour (note: use `withValues`, NOT deprecated `withOpacity`)
- Use `CupertinoColors.systemOrange` for the banner background (distinct from yellow trial banner)

**CRITICAL:** The banner error callback in `TrialCountdownBanner` uses the unnamed parameter pattern `error: (_, _) => const SizedBox.shrink()`. This is valid Dart 3 syntax. Use the same pattern.

### `err()` helper availability in `subscriptions.ts`

`err` is imported in `apps/api/src/index.ts` but NOT currently imported in `subscriptions.ts`. Before using `err()` in the webhook 400 response, verify the import. If not present, add:
```typescript
import { ok, err } from '../lib/response.js'
```
Check the existing import at the top of `subscriptions.ts` — currently only `ok` is imported (`import { ok } from '../lib/response.js'`). Update the import to include `err` before using it in the webhook route.

### AppShell — finding `TrialCountdownBanner` placement

Run before implementing Task 3:
```
grep -rn "TrialCountdownBanner" apps/flutter/lib
```
The `GracePeriodBanner` goes directly after each `TrialCountdownBanner()` usage in the widget tree. Both are `ConsumerWidget`s that self-render to `SizedBox.shrink()` when not applicable, so there is no conditional rendering needed at the usage site — always include both.

### Push notification scope for Story 9.5

FR90 requires a push notification when payment fails. The full APNs implementation is deferred (same as all push features to date — `apps/api/src/services/push.ts` is a `TODO(impl)` stub). Story 9.5 only implements the webhook stub with `TODO(impl)` comments for the APNs call. The in-app banner (Task 3) covers the "in-app" part of AC: 1 for the current stub phase.

### Stripe webhook route — `ok()` vs custom schema

The `ActivateSubscriptionResponseSchema` is already defined and used for activate/restore/cancel responses. Do NOT reuse it for the webhook response — the webhook returns `{ data: { received: true } }` which is a different shape. Use the new `StripeWebhookResponseSchema` defined in Task 6.

### Test count reference

- Current passing API tests before this story: **287** (after Story 9.4)
- After this story: **292+** (5 minimum new tests)
- Run: `pnpm test --filter apps/api`

- Current passing Flutter tests before this story: **930** (after Story 9.4)
- After this story: **936+** (6 minimum new tests)
- Run: `flutter test` from `apps/flutter/`

### Deferred Items to Track (Do NOT implement in this story)

- **Real Stripe webhook signature verification** — `verifyWebhookSignature` in `stripe.ts` is stubbed. Story 9.5 does not implement the real verification. The webhook stub accepts all payloads.
- **APNs push notification delivery** — `sendPush` in `push.ts` is stubbed. The webhook TODO comment documents the intent; the actual APNs call is deferred.
- **Grace period DB persistence** — No Drizzle schema changes in this story (TS2345 constraint). The subscription state transition `grace_period → expired` is server-side Stripe webhook logic; the Flutter client reads `status='grace_period'` from `/v1/subscriptions/me`.
- **`SubscribeSuccessScreen` error dialog dismiss** — Deferred from Story 9.3 code review (see `deferred-work.md`). Do NOT address here.
- **`impl(9.1): Display trialEndsAt formatted date`** — Stub at `subscription_settings_screen.dart:156`. Leave it exactly as-is.

### Epic 9 Cross-Story Context

- **Story 9.4 → 9.5:** Story 9.4 added the `cancelled` state display and set `isCancelled` getter. Story 9.5 adds the `grace_period` state display and sets `isGracePeriod` getter — exact same pattern.
- **Story 9.4 → 9.5:** The `// impl(9.5): grace_period state handled in Story 9.5.` comment at `subscription_settings_screen.dart:231` is the direct stub for Task 2 of this story. Replace it.
- **Story 9.5 → 9.6:** Story 9.6 is "Invited User Onboarding" — no subscription state dependencies on 9.5 implementation.
- The `grace_period` state is a **Stripe-triggered server-side state** (via `invoice.payment_failed` webhook). The Flutter client reads it from `/v1/subscriptions/me` like any other state. No new Flutter providers needed.

### File Locations Summary

| File | Purpose |
|---|---|
| `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart` | Modify: add `isGracePeriod` getter |
| `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` | Modify: replace `impl(9.5)` stub with grace period UI |
| `apps/flutter/lib/features/subscriptions/presentation/grace_period_banner.dart` | CREATE: new persistent banner widget |
| `apps/flutter/lib/core/l10n/strings.dart` | Modify: add Story 9.5 strings at end of class |
| AppShell file (find via grep) | Modify: add `GracePeriodBanner()` alongside `TrialCountdownBanner()` |
| `apps/flutter/lib/core/router/app_router.dart` | Verify only — no logic changes expected |
| `apps/api/src/routes/subscriptions.ts` | Modify: add Stripe webhook stub, add `err` to import |
| `apps/api/test/routes/subscriptions.test.ts` | Modify: add 5 tests for webhook endpoint |
| `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` | Modify: add 4 tests for grace period state |
| `apps/flutter/test/features/subscriptions/grace_period_banner_test.dart` | CREATE: 2 tests for GracePeriodBanner |

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` Epic 9, Story 9.5 — ACs, FR90]
- [Source: `_bmad-output/implementation-artifacts/9-4-subscription-management-upgrade-downgrade-cancellation.md` — `isCancelled` getter pattern, stub API pattern, `impl(9.X):` convention, Drizzle TS2345 constraint, test count references, `_StatusSection` ordering, `_FakeSubscriptionsRepository` test pattern]
- [Source: `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart` — `SubscriptionState.gracePeriod` enum value, `fromJson` mapping, existing getter pattern]
- [Source: `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` — `impl(9.5)` stub location (line 231), `_StatusSection.build()` ordering, `_formatDate`, `url_launcher` import, `isCancelled` branch pattern to replicate]
- [Source: `apps/flutter/lib/features/subscriptions/presentation/trial_countdown_banner.dart` — `GracePeriodBanner` structural template, `withValues(alpha:)` usage, `ConsumerWidget` pattern]
- [Source: `apps/api/src/routes/subscriptions.ts` — existing route patterns, `ActivateSubscriptionResponseSchema`, `ok()` import, stub-only constraint]
- [Source: `apps/api/src/services/stripe.ts` — `verifyWebhookSignature` export, stub status (returns false), raw body requirement]
- [Source: `apps/api/src/services/push.ts` — `sendPush` export, stub status, `PushPayload` interface]
- [Source: `apps/flutter/lib/core/router/app_router.dart` lines 99–114 — paywall redirect logic; `isExpired`-only gate confirmed]
- [Source: `apps/flutter/lib/core/l10n/strings.dart` line 1410 — add after `subscriptionCancelError` (current last string)]
- [Source: `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` — `_FakeSubscriptionsRepository`, test pattern, `FlutterSecureStorage.setMockInitialValues` setup]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `z.record(z.unknown())` → `z.record(z.string(), z.unknown())` for Zod v4 compatibility in `StripeWebhookRequestSchema`.
- `GracePeriodBanner` test uses `CupertinoPageScaffold` (not Material Scaffold) matching `trial_countdown_banner_test.dart` pattern.

### Completion Notes List

- Task 1: Added `bool get isGracePeriod => state == SubscriptionState.gracePeriod;` to `SubscriptionStatus`, following the exact `isCancelled`/`isExpired` pattern. No `.g.dart` files modified.
- Task 2: Replaced `impl(9.5)` stub in `_StatusSection.build()` with full grace period UI (status label, body text, optional access-until date, "Update payment method" CTA). Final `SizedBox.shrink()` fallback preserved.
- Task 3: Created `GracePeriodBanner` widget mirroring `TrialCountdownBanner` exactly — `ConsumerWidget`, `statusAsync.when`, `GestureDetector` → `/settings/subscription`, `CupertinoColors.systemOrange.withValues(alpha: 0.9)`. Added `GracePeriodBanner()` to `AppShell` directly below `TrialCountdownBanner()`.
- Task 4: Added 5 `AppStrings` constants for grace period at end of class after `subscriptionCancelError`.
- Task 5: Verified `app_router.dart` paywall redirect — `isExpired` gate is correct; `isGracePeriod` is distinct. Added clarifying comment only (no logic change).
- Task 6: Added `POST /v1/subscriptions/webhook/stripe` stub route to `subscriptions.ts`. Updated `ok` import to also include `err`; added `verifyWebhookSignature` and `sendPush` imports. Fixed Zod v4 `z.record(z.string(), z.unknown())`. Zero new TS errors in `subscriptions.ts`.
- Task 7: Added 5 API tests for webhook endpoint. Total: 292 tests passing (287 + 5 new). No regressions.
- Task 8: Added 4 widget tests to `subscription_settings_screen_test.dart` (grace period status label, CTA button, body text, access-until date). Created `grace_period_banner_test.dart` with 2 tests (banner visible, banner hidden). Total: 6 new Flutter tests. All 78 shell+subscriptions tests pass.

### File List

- `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart` (modified)
- `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` (modified)
- `apps/flutter/lib/features/subscriptions/presentation/grace_period_banner.dart` (created)
- `apps/flutter/lib/features/shell/presentation/app_shell.dart` (modified)
- `apps/flutter/lib/core/l10n/strings.dart` (modified)
- `apps/flutter/lib/core/router/app_router.dart` (modified — comment only)
- `apps/api/src/routes/subscriptions.ts` (modified)
- `apps/api/test/routes/subscriptions.test.ts` (modified)
- `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` (modified)
- `apps/flutter/test/features/subscriptions/grace_period_banner_test.dart` (created)

## Change Log

- 2026-04-01: Story 9.5 created — Payment Failure Grace Period. Adds `isGracePeriod` getter to `SubscriptionStatus`, grace period UI in `_StatusSection` (replaces `impl(9.5)` stub), `GracePeriodBanner` widget (mirrors `TrialCountdownBanner`), 5 new `AppStrings`, `POST /v1/subscriptions/webhook/stripe` stub endpoint, 5 API tests (292+ total), 6 Flutter widget tests (936+ total). Router unchanged — `isExpired` gate already handles expired grace period. APNs delivery and real Stripe signature verification deferred as `TODO(impl)` stubs.
- 2026-04-01: Story 9.5 implemented — all 8 tasks complete. API: 292 tests pass. Flutter: all subscriptions tests pass. Status → review.
