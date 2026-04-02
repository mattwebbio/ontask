# Story 9.4: Subscription Management — Upgrade, Downgrade & Cancellation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to change my subscription tier or cancel without friction,
so that I stay in control of what I'm paying for.

## Acceptance Criteria

1. **Given** the user opens Settings → Subscription with an active subscription
   **When** they choose to change tier
   **Then** upgrade takes effect immediately with prorated billing (FR84)
   **And** downgrade takes effect at the start of the next billing cycle (FR84)

2. **Given** the user cancels their subscription (FR49, FR89)
   **When** cancellation is confirmed
   **Then** the subscription remains active until the end of the current paid period — access is not removed early
   **And** active commitment contracts continue to their individual deadlines regardless of cancellation status (FR89)
   **And** the remaining access period is displayed clearly: "Your subscription is active until [date]"

3. **Given** the user has a `cancelled` subscription (pending expiry)
   **When** they open Settings → Subscription
   **Then** the screen shows `"Your subscription is active until [date]"` instead of the standard renewal label
   **And** a "Reactivate" CTA is shown that opens `ontaskhq.com/account` via `url_launcher`

---

## Tasks / Subtasks

---

### Task 1: Flutter — `SubscriptionStatus` domain model — add `cancelled` state display support (AC: 2, 3)

The domain model already has `SubscriptionState.cancelled` but `SubscriptionStatus` lacks computed getters for it.

- [x] In `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`, add:
  ```dart
  bool get isCancelled => state == SubscriptionState.cancelled;
  ```
  This mirrors the existing `isActive`, `isExpired`, `isTrialing` getters.

- [x] Verify `SubscriptionState.fromJson` already handles `'cancelled'` → `cancelled` (it does — line 8 of the current file). No change needed there.

- [x] **DO NOT** add `isCancelled` or any new field to `subscriptions_repository.g.dart` or `subscriptions_provider.g.dart` — CI does not run `build_runner`, `.g.dart` files must not be modified.

**File to modify:** `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`

---

### Task 2: Flutter — Settings → Subscription — cancelled state UI (AC: 2, 3)

Add the cancelled state to `_StatusSection.build()` in `subscription_settings_screen.dart`. The cancelled state sits between `isActive` and the `impl(9.5): grace_period` stub.

- [x] Add a `cancelled` branch in `_StatusSection.build()` after the `isActive` block (line 90), before the `impl(9.5)` comment (line 122):
  ```dart
  if (status.isCancelled) {
    final accessUntilDate = status.currentPeriodEnd != null
        ? _formatDate(status.currentPeriodEnd!)
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.subscriptionCancelledStatusLabel,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          if (accessUntilDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(AppStrings.subscriptionActiveUntil(accessUntilDate)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () async {
                final uri = Uri.parse('https://ontaskhq.com/account');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(AppStrings.subscriptionReactivateCta),
            ),
          ),
        ],
      ),
    );
  }
  ```
  Note: `_formatDate` helper and `url_launcher` import already exist in this file from Story 9.3.

- [x] Replace the `impl(9.3): resolve tier name from status.tier` comment stub in the `isActive` block:
  ```dart
  // impl(9.3): resolve tier name from status.tier (add tier field in future story or use generic label)
  final tierName = ''; // impl(9.3): ...
  ```
  This stub is in the active block but the `tierName` variable is never used. Remove it entirely — the active UI does not currently display tier name and none is needed for this story either. Clean up the dead code.

**File to modify:** `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`

---

### Task 3: Flutter — `AppStrings` additions for Story 9.4 (AC: 2, 3)

Add strings to `apps/flutter/lib/core/l10n/strings.dart`. Add at the **END** of the `AppStrings` class, after the `subscriptionManageCta` constant (the current last string added in Story 9.3).

- [x] Add:
  ```dart
  // ── Subscriptions — Cancellation & Reactivation (FR49, FR89, Story 9.4) ──────

  /// Settings → Subscription section title when subscription is cancelled (pending expiry).
  static const String subscriptionCancelledStatusLabel = 'Subscription Cancelled';

  /// Message shown when subscription is cancelled — shows the access-until date.
  /// Usage: AppStrings.subscriptionActiveUntil(date)
  /// AC: 2, FR89: "Your subscription is active until [date]"
  static String subscriptionActiveUntil(String date) =>
      'Your subscription is active until $date';

  /// "Reactivate" CTA in Settings → Subscription when cancelled (opens ontaskhq.com/account).
  static const String subscriptionReactivateCta = 'Reactivate subscription';

  /// Cancellation confirmation dialog title.
  static const String subscriptionCancelConfirmTitle = 'Cancel Subscription?';

  /// Cancellation confirmation dialog body — reminds user of continued access.
  static const String subscriptionCancelConfirmBody =
      'You\'ll keep access until the end of your current billing period. Active commitment contracts will continue until their individual deadlines.';

  /// Cancellation confirmation dialog "Cancel Subscription" action label.
  static const String subscriptionCancelConfirmAction = 'Cancel Subscription';

  /// Cancellation confirmation dialog dismiss label.
  static const String subscriptionCancelConfirmDismiss = 'Keep Subscription';

  /// Error shown when cancellation fails.
  static const String subscriptionCancelError =
      'Couldn\u2019t cancel your subscription. Please try again or visit ontaskhq.com/account.';
  ```

**File to modify:** `apps/flutter/lib/core/l10n/strings.dart`

---

### Task 4: Flutter — Settings → Subscription — "Cancel subscription" CTA (AC: 2)

Add a cancel CTA to `SubscriptionSettingsScreen` shown only when `status.isActive`. The "Manage subscription" button opens `ontaskhq.com/account` (Stripe Customer Portal) where upgrade/downgrade is handled. The cancel flow runs natively in-app for a frictionless experience.

- [x] Convert `SubscriptionSettingsScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` to hold `_isCancelling` loading state.

  **Current signature:**
  ```dart
  class SubscriptionSettingsScreen extends ConsumerWidget {
    const SubscriptionSettingsScreen({super.key});
    @override
    Widget build(BuildContext context, WidgetRef ref) {
  ```
  **Replace with:**
  ```dart
  class SubscriptionSettingsScreen extends ConsumerStatefulWidget {
    const SubscriptionSettingsScreen({super.key});
    @override
    ConsumerState<SubscriptionSettingsScreen> createState() =>
        _SubscriptionSettingsScreenState();
  }

  class _SubscriptionSettingsScreenState
      extends ConsumerState<SubscriptionSettingsScreen> {
    bool _isCancelling = false;

    Future<void> _onCancelSubscription() async {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(AppStrings.subscriptionCancelConfirmTitle),
          content: Text(AppStrings.subscriptionCancelConfirmBody),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppStrings.subscriptionCancelConfirmAction),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.subscriptionCancelConfirmDismiss),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      setState(() => _isCancelling = true);
      try {
        final repo = ref.read(subscriptionsRepositoryProvider);
        await repo.cancelSubscription();
        ref.invalidate(subscriptionStatusProvider);
      } catch (_) {
        if (mounted) {
          await showCupertinoDialog<void>(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(AppStrings.subscriptionCancelError),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }

    @override
    Widget build(BuildContext context) {
  ```

- [x] In the `data:` branch of `statusAsync.when(...)`, add the cancel CTA below `_StatusSection` when `status.isActive`:
  ```dart
  if (status.isActive) ...[
    const SizedBox(height: 8),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isCancelling ? null : _onCancelSubscription,
          child: _isCancelling
              ? const CupertinoActivityIndicator()
              : Text(
                  AppStrings.subscriptionCancelConfirmAction,
                  style: const TextStyle(color: CupertinoColors.destructiveRed),
                ),
        ),
      ),
    ),
  ],
  ```
  This mirrors the "Restore purchase" button pattern in `paywall_screen.dart` (plain `CupertinoButton`, destructive red, loading indicator while in-flight).

**File to modify:** `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`

---

### Task 5: Flutter — `SubscriptionsRepository` — `cancelSubscription` method (AC: 2)

Add the cancellation method to the existing repository.

- [x] In `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart`, add after `restoreSubscription`:
  ```dart
  /// Cancels the user's subscription at end of the current billing period.
  /// Called from Settings → Subscription cancel CTA (Story 9.4, FR49, FR89).
  /// Access continues until [SubscriptionStatus.currentPeriodEnd].
  /// Invalidate [subscriptionStatusProvider] after calling this.
  Future<void> cancelSubscription() async {
    await apiClient.dio.post<void>(
      '/v1/subscriptions/cancel',
    );
  }
  ```
  Follow the existing pattern: `void` return, `await`, no response data. Same pattern as `restoreSubscription()`.

- [x] **DO NOT** add `@riverpod` annotations or modify `.g.dart` files. CI does not run `build_runner`.

**File to modify:** `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart`

---

### Task 6: API — `POST /v1/subscriptions/cancel` stub endpoint (AC: 2)

Add the cancellation endpoint to `apps/api/src/routes/subscriptions.ts`.

- [x] Add schema and route after the existing `POST /v1/subscriptions/restore` route:

  **Schema (reuse existing `ActivateSubscriptionResponseSchema` — same shape):**
  No new schema needed. The cancel response returns updated subscription status using the existing `ActivateSubscriptionResponseSchema`.

  **Route:**
  ```typescript
  const cancelSubscriptionRoute = createRoute({
    method: 'post',
    path: '/v1/subscriptions/cancel',
    tags: ['Subscriptions'],
    summary: 'Cancel subscription at end of current billing period',
    description:
      'Cancels the subscription — access continues until currentPeriodEnd (FR49, FR89). ' +
      'Active commitment contracts are unaffected by cancellation. ' +
      'Story 9.4 stub — TODO(impl): call Stripe cancel_at_period_end, update DB status to cancelled.',
    responses: {
      200: {
        content: { 'application/json': { schema: ActivateSubscriptionResponseSchema } },
        description: 'Subscription cancelled (access continues until period end)',
      },
      401: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Unauthenticated',
      },
      404: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'No active subscription found',
      },
    },
  })

  app.openapi(cancelSubscriptionRoute, async (_c) => {
    // TODO(impl): const db = createDb(c.env.DATABASE_URL)
    // TODO(impl): const jwtUserId = c.get('jwtPayload').sub
    // TODO(impl): call Stripe API — stripe.subscriptions.update(subId, { cancel_at_period_end: true })
    // TODO(impl): update subscription record in DB — set status='cancelled', preserve currentPeriodEnd
    // TODO(impl): emit 'subscription_cancelled' analytics event (NFR-B1)
    // Stub: return cancelled status with a future access-until date for testing the client flow.
    const stubCurrentPeriodEnd = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    return _c.json(
      ok({
        status: 'cancelled' as const,
        stripeSubscriptionId: 'stub_sub_id',
        currentPeriodEnd: stubCurrentPeriodEnd,
      }),
      200,
    )
  })
  ```

  **CRITICAL:** Do NOT add `createDb` or Drizzle imports — pre-existing TS2345 `PgTableWithColumns` typecheck incompatibility causes CI failures. Stub only (same pattern as all other stubs in `subscriptions.ts`).

  **CRITICAL:** `ActivateSubscriptionResponseSchema` is already defined earlier in the file — do NOT redefine it. Reuse it for the cancel response.

**File to modify:** `apps/api/src/routes/subscriptions.ts`

---

### Task 7: API — Tests for cancellation endpoint (AC: 2)

Add tests to `apps/api/test/routes/subscriptions.test.ts`. Add after the existing tests for `POST /v1/subscriptions/restore` (currently at line 169).

- [x] Add `describe('POST /v1/subscriptions/cancel', ...)` block:
  ```typescript
  // Tests for POST /v1/subscriptions/cancel — Story 9.4 (FR49, FR89, AC: 2)
  // Handler is a stub (real Stripe cancellation deferred) — all valid requests return 200.

  describe('POST /v1/subscriptions/cancel', () => {
    it('returns 200', async () => {
      const res = await app.request('/v1/subscriptions/cancel', {
        method: 'POST',
      })
      expect(res.status).toBe(200)
    })

    it('response shape has data object', async () => {
      const res = await app.request('/v1/subscriptions/cancel', {
        method: 'POST',
      })
      const body = await res.json() as { data: { status: string } }
      expect(body).toHaveProperty('data')
    })

    it('response data.status is "cancelled"', async () => {
      const res = await app.request('/v1/subscriptions/cancel', {
        method: 'POST',
      })
      const body = await res.json() as { data: { status: string } }
      expect(body.data.status).toBe('cancelled')
    })

    it('response has data.currentPeriodEnd (non-null — access-until date)', async () => {
      const res = await app.request('/v1/subscriptions/cancel', {
        method: 'POST',
      })
      const body = await res.json() as { data: { currentPeriodEnd: string | null } }
      expect(body.data).toHaveProperty('currentPeriodEnd')
      expect(body.data.currentPeriodEnd).not.toBeNull()
    })

    it('response has data.stripeSubscriptionId', async () => {
      const res = await app.request('/v1/subscriptions/cancel', {
        method: 'POST',
      })
      const body = await res.json() as { data: { stripeSubscriptionId: string | null } }
      expect(body.data).toHaveProperty('stripeSubscriptionId')
    })
  })
  ```

- [x] **Minimum 5 new tests** — total API test count after this story: **282 + 5 = 287+**
- [x] **Do not break existing 282 tests.** Run `pnpm test --filter apps/api` to verify.

**File to modify:** `apps/api/test/routes/subscriptions.test.ts`

---

### Task 8: Flutter — Widget tests for Story 9.4 changes (AC: 1–3)

- [x] In `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`, add tests:

  **Cancelled state tests:**
  1. Cancelled state renders `AppStrings.subscriptionCancelledStatusLabel` text
  2. Cancelled state renders `AppStrings.subscriptionReactivateCta` button
  3. Cancelled state with `currentPeriodEnd` set shows formatted "active until" date text

  **Active state — cancel CTA:**
  4. Active state renders `AppStrings.subscriptionCancelConfirmAction` text button (the inline cancel CTA)
  5. Tapping cancel CTA shows confirmation dialog with `AppStrings.subscriptionCancelConfirmTitle`
  6. Dismissing confirmation dialog (tapping "Keep Subscription") does NOT call `cancelSubscription`

  ```dart
  const _cancelledStatus = SubscriptionStatus(
    state: SubscriptionState.cancelled,
    currentPeriodEnd: null,
  );

  // Test 1
  testWidgets('cancelled state renders subscriptionCancelledStatusLabel text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => _cancelledStatus),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.subscriptionCancelledStatusLabel), findsOneWidget);
  });

  // Test 2
  testWidgets('cancelled state renders subscriptionReactivateCta button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => _cancelledStatus),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.subscriptionReactivateCta), findsOneWidget);
  });

  // Test 3
  testWidgets('cancelled state with currentPeriodEnd shows formatted access-until date', (tester) async {
    final cancelledWithDate = SubscriptionStatus(
      state: SubscriptionState.cancelled,
      currentPeriodEnd: DateTime(2026, 6, 15),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith((_) async => cancelledWithDate),
        ],
        child: const CupertinoApp(home: SubscriptionSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.subscriptionActiveUntil('2026-06-15')),
      findsOneWidget,
    );
  });
  ```

  For tests 4–6: mock `subscriptionsRepositoryProvider` to track calls (use a `MockSubscriptionsRepository` or a simple `FakeSubscriptionsRepository` that records invocations — see `paywall_screen_test.dart` for existing repository mock pattern).

- [x] **Minimum 6 new widget tests** — total Flutter test count after this story: **924 + 6 = 930+**
- [x] **Do not break existing 924 Flutter tests.** Run `flutter test` from `apps/flutter/` to verify.

**Files to modify:**
- MODIFY: `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`

---

## Dev Notes

### Architecture Constraints — Must Follow

**API: Drizzle TS2345 stub pattern (CRITICAL — CI will fail if violated)**
- All route handler implementations use `TODO(impl)` comment stubs only.
- Do NOT add `createDb(c.env.DATABASE_URL)`, Drizzle imports, or any direct DB calls.
- See existing `subscriptions.ts` — all four existing routes follow this pattern exactly.
- The `ok()` helper is already imported from `'../lib/response.js'` — do not duplicate.
- `ActivateSubscriptionResponseSchema` is already defined in `subscriptions.ts` — reuse it for the cancel endpoint response; do not define a new schema with the same shape.

**Flutter: No new `.g.dart` files needed for this story**
- `subscriptions_repository.g.dart` and `subscriptions_provider.g.dart` already exist.
- No new `@riverpod` providers or new `@riverpod` annotations in this story — only new methods on `SubscriptionsRepository` and a new getter on `SubscriptionStatus`.
- CI does not run `build_runner`. Do NOT modify `.g.dart` files.

**Flutter: Riverpod import discipline**
- Widget files: use `package:flutter_riverpod/flutter_riverpod.dart`
- Provider/repository files: use `package:riverpod_annotation/riverpod_annotation.dart` only
- `ref.invalidate(subscriptionStatusProvider)` after cancellation will trigger `_SubscriptionRefreshListenable` (added in Story 9.3), re-evaluating GoRouter redirect. After cancellation, `status.isCancelled == true` and `status.isExpired == false` — the paywall redirect guard will NOT fire. The user remains on Settings.

**Flutter: `impl(9.X):` deferred comment prefix**
- Use `impl(9.4):` for any new deferred stubs in Dart code.
- Never use `TODO:` in Dart files — the linter flags it. Use `// impl(9.4):` instead.
- Do NOT touch `// impl(9.5): grace_period state handled in Story 9.5.` — leave that stub exactly as-is.

**GoRouter paywall redirect — `isCancelled` is NOT `isExpired`**
- The existing redirect guard fires only when `subStatus.isExpired`. After cancellation, `status.state == SubscriptionState.cancelled` — `isExpired` is `false`, `isCancelled` is `true`.
- NEVER redirect `cancelled` users to the paywall — they still have access until `currentPeriodEnd`. This is already correct in the existing redirect code; do not change `app_router.dart` in this story.

**Upgrade/downgrade via Stripe Customer Portal**
- The AC specifies upgrade takes effect immediately (prorated) and downgrade at next cycle. Both are Stripe behaviours handled on `ontaskhq.com/account` (Stripe Customer Portal).
- Story 9.4 does NOT implement native in-app upgrade/downgrade screens. The "Manage subscription" CTA added in Story 9.3 (opens `ontaskhq.com/account`) already covers upgrade/downgrade. This story only adds the native **cancellation** flow and **cancelled state display**.
- The existing `AppStrings.subscriptionManageCta` ("Manage subscription") button in the active state in `subscription_settings_screen.dart` already handles upgrade/downgrade navigation. Do NOT add a separate upgrade/downgrade UI.

### Subscription State Transitions — Story Scope

| State | Handled By |
|-------|-----------|
| `trialing` | Story 9.1 |
| `active` | Story 9.3 |
| `cancelled` | **Story 9.4** (this story) |
| `expired` | Story 9.1/9.2 (paywall redirect) |
| `grace_period` | Story 9.5 (stub already in place) |

The `cancelled` state means: subscription will not renew, but `currentPeriodEnd` is still in the future — user has full access. The `expired` state means: `currentPeriodEnd` has passed with no active subscription.

### `_StatusSection` State Ordering

After this story, the full `_StatusSection.build()` method handles these states in order:

1. `isTrialing` → trial UI
2. `isExpired` → expired label
3. `isActive` → active UI + "Manage subscription" CTA
4. `isCancelled` → cancelled UI + "Reactivate" CTA  ← **added in this story**
5. `// impl(9.5): grace_period` → SizedBox.shrink() fallback

The ordering matters — `isCancelled` must come AFTER `isActive` and BEFORE the grace_period stub.

### ConsumerStatefulWidget Conversion Pattern

Follow the identical pattern used in `PaywallScreen` (Story 9.3):
```dart
class PaywallScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}
class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isRestoring = false;
  // ...
}
```
Apply the same structure to `SubscriptionSettingsScreen` / `_SubscriptionSettingsScreenState`.

### Cancellation UX — Confirmation Dialog Pattern

Follow `_onRestorePurchase` in `paywall_screen.dart` for the error dialog pattern.
For the confirmation dialog, follow `StakeSheetScreen._onRemoveStake` in `stake_sheet_screen.dart` — it uses `showCupertinoDialog` returning a `bool` for confirmed/dismissed. Destructive action goes first in dialog actions (Cupertino HIG).

### url_launcher Pattern (established in Story 6.1 and 9.3)

```dart
final uri = Uri.parse('https://ontaskhq.com/account');
await launchUrl(uri, mode: LaunchMode.externalApplication);
```
`url_launcher` is already imported in `subscription_settings_screen.dart` from Story 9.3 — no additional import needed.

### API: `'cancelled' as const` TypeScript casting

The `ActivateSubscriptionResponseSchema` status enum already includes `'cancelled'`:
```typescript
status: z.enum(['trialing', 'active', 'cancelled', 'expired', 'grace_period'])
```
This is confirmed in `subscriptions.ts` line 154 (the `ActivateSubscriptionResponseSchema`). Use `'cancelled' as const` in the stub handler return value, matching the existing pattern from the `activate` stub (`'active' as const`).

### Deferred Items from Story 9.3 to Track

From `_bmad-output/implementation-artifacts/deferred-work.md` (as of 2026-04-01):
- **`SubscribeSuccessScreen` error dialog has no Cancel/Dismiss option** — deferred to a future polish story. Do NOT implement it here.
- **`impl(9.1): Display trialEndsAt formatted date`** — stub at `subscription_settings_screen.dart:79`. This story does NOT resolve this stub — leave it as-is.

### File Locations

| File | Purpose |
|---|---|
| `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart` | Modify: add `isCancelled` getter |
| `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` | Modify: cancelled state UI, ConsumerStatefulWidget conversion, cancel CTA |
| `apps/flutter/lib/core/l10n/strings.dart` | Modify: add Story 9.4 strings at end of class |
| `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart` | Modify: add `cancelSubscription` method |
| `apps/api/src/routes/subscriptions.ts` | Modify: add `POST /v1/subscriptions/cancel` stub |
| `apps/api/test/routes/subscriptions.test.ts` | Modify: add 5 tests for cancel endpoint |
| `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` | Modify: add 6 tests for cancelled state + cancel CTA |

### Test Count Reference

- Current passing API tests before this story: **282** (after Story 9.3)
- After this story: **287+** (5 minimum new tests)
- Run: `pnpm test --filter apps/api`

- Current passing Flutter tests before this story: **924** (after Story 9.3)
- After this story: **930+** (6 minimum new tests)
- Run: `flutter test` from `apps/flutter/`

### Epic 9 Cross-Story Context

- **Story 9.3 → 9.4:** `subscription_settings_screen.dart` active state has a "Manage subscription" CTA that opens `ontaskhq.com/account` — this already handles upgrade/downgrade. Story 9.4 adds the native cancel CTA and cancelled-state display.
- **Story 9.4 → 9.5:** Story 9.5 handles the `grace_period` state. The `// impl(9.5):` stub at the bottom of `_StatusSection.build()` must remain untouched in this story.
- **Story 9.4 → 9.5:** The cancel flow in this story sets `status.state = 'cancelled'` (access continues). Story 9.5 handles `'grace_period'` (payment failed, 7-day window). These are separate Stripe-side triggers.
- **Hard dependency:** Epic 13 Story 13.1 (AASA + `ontaskhq.com/account` Stripe Customer Portal) must be deployed before upgrade/downgrade flows can be tested end-to-end. Cancellation via the native flow works independently once the API stub is in place.

### Review Finding Propagated from Story 9.3

- **Story 9.3 Review Finding [Review][Decision]:** Settings Subscribe CTA opens `ontaskhq.com/subscribe` without `?tier=` query param — confirmed as intentional (simpler alternative). The reactivate CTA in this story opens `ontaskhq.com/account` without params — same pattern, intentional. No tier selection in Settings.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` Epic 9, Story 9.4 — ACs, FR49, FR84, FR89]
- [Source: `_bmad-output/planning-artifacts/epics.md` Epic 9 goal — full subscription lifecycle]
- [Source: `_bmad-output/implementation-artifacts/9-3-tier-selection-subscription-activation.md` — ConsumerStatefulWidget pattern, stub API pattern, `impl(9.X):` comment convention, url_launcher pattern, no Drizzle imports constraint, test count references]
- [Source: `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart` — `SubscriptionState` enum (includes `cancelled`), `SubscriptionStatus` computed getter pattern]
- [Source: `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` — `_StatusSection.build()` ordering, existing `_formatDate`, existing `url_launcher` import, existing `impl` stubs]
- [Source: `apps/flutter/lib/features/subscriptions/presentation/paywall_screen.dart` — `ConsumerStatefulWidget` conversion pattern, `_onRestorePurchase` error dialog pattern]
- [Source: `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart` — `cancelSubscription` placement, `void` return pattern, no `@riverpod`]
- [Source: `apps/api/src/routes/subscriptions.ts` — `ActivateSubscriptionResponseSchema` reuse, `ok()` helper, stub-only constraint, `'cancelled' as const` pattern]
- [Source: `apps/flutter/lib/core/l10n/strings.dart` — add after `subscriptionManageCta` (current last string)]
- [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — deferred items not to implement here]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Task 1: Added `isCancelled` getter to `SubscriptionStatus` domain model. Confirmed `SubscriptionState.fromJson` already handles `'cancelled'`. No `.g.dart` files touched.
- Task 2: Added `isCancelled` branch to `_StatusSection.build()` after `isActive` and before `impl(9.5)` stub. Cancelled state renders `subscriptionCancelledStatusLabel`, optional `subscriptionActiveUntil(date)` text, and `subscriptionReactivateCta` filled button opening `ontaskhq.com/account`. Dead `tierName` stub (impl(9.3)) removed from active block — variable was declared but never used.
- Task 3: Added 8 new `AppStrings` constants/functions at end of class: `subscriptionCancelledStatusLabel`, `subscriptionActiveUntil`, `subscriptionReactivateCta`, `subscriptionCancelConfirmTitle`, `subscriptionCancelConfirmBody`, `subscriptionCancelConfirmAction`, `subscriptionCancelConfirmDismiss`, `subscriptionCancelError`.
- Task 4: Converted `SubscriptionSettingsScreen` from `ConsumerWidget` to `ConsumerStatefulWidget`. Added `_isCancelling` state flag, `_onCancelSubscription()` method with confirmation dialog (destructive action first per Cupertino HIG) and error dialog on failure. Added cancel CTA below `_StatusSection` when `status.isActive` — plain `CupertinoButton` with destructive red colour, disabled+spinner while in-flight. Added `subscriptions_repository.dart` import for `subscriptionsRepositoryProvider`.
- Task 5: Added `cancelSubscription()` method to `SubscriptionsRepository` after `restoreSubscription()`. Same void-return, await pattern. No `@riverpod` annotation. No `.g.dart` files touched.
- Task 6: Added `POST /v1/subscriptions/cancel` route to `apps/api/src/routes/subscriptions.ts` reusing `ActivateSubscriptionResponseSchema`. Stub returns `status: 'cancelled'` with `currentPeriodEnd` 30 days out. No Drizzle/`createDb` imports added.
- Task 7: Added 5 tests for `POST /v1/subscriptions/cancel` to `subscriptions.test.ts`. All 287 API tests pass.
- Task 8: Added 6 widget tests to `subscription_settings_screen_test.dart` covering cancelled state (label, reactivate CTA, access-until date) and active cancel CTA (renders, shows dialog on tap, does not call repo on dismiss). Used `_FakeSubscriptionsRepository` pattern with `overrideWithValue`. All 930 Flutter tests pass.

### File List

- apps/flutter/lib/features/subscriptions/domain/subscription_status.dart
- apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart
- apps/flutter/lib/core/l10n/strings.dart
- apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart
- apps/api/src/routes/subscriptions.ts
- apps/api/test/routes/subscriptions.test.ts
- apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart

## Change Log

- 2026-04-01: Story 9.4 created — Subscription Management (Upgrade/Downgrade/Cancellation). Adds cancelled state display in Settings → Subscription (cancelled label, access-until date, Reactivate CTA), ConsumerStatefulWidget conversion for cancel loading state, native cancel confirmation dialog + cancel CTA in active state, `cancelSubscription()` repo method, `POST /v1/subscriptions/cancel` API stub, 5 new API tests (287+ total), 6 new Flutter widget tests (930+ total). Upgrade/downgrade handled via existing "Manage subscription" → ontaskhq.com/account (Stripe Portal). `isCancelled` getter added to SubscriptionStatus domain model.
- 2026-04-01: Story 9.4 implemented. All tasks complete. API: 287 tests pass. Flutter: 930 tests pass. Status → review.
