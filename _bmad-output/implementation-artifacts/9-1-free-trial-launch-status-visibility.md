# Story 9.1: Free Trial — Launch Status & Visibility

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a new user,
I want a 14-day full-access free trial with clear visibility into how much time I have left,
so that I can experience the full product before being asked to pay.

## Acceptance Criteria

1. **Given** a new user completes authentication for the first time
   **When** their account is created
   **Then** a 14-day free trial period begins immediately (FR82)
   **And** the trial start timestamp is recorded server-side

2. **Given** the user opens Settings → Subscription
   **When** the subscription status is shown
   **Then** remaining trial days are displayed: "X days remaining in your free trial" (FR87)
   **And** in the final 3 days, a persistent trial countdown banner appears in the app

3. **Given** the trial expires
   **When** no subscription has been activated
   **Then** user data is retained server-side for 30 days before permanent deletion (FR85, NFR-R7)
   **And** re-authenticating within 30 days restores full access to their data

## Tasks / Subtasks

---

### Task 1: DB schema — `packages/core/src/schema/subscriptions.ts` (AC: 1, 3)

Create the new Drizzle schema file for subscription/trial state. Follow the exact conventions from existing schema files (e.g., `packages/core/src/schema/commitment-contracts.ts`).

- [x] Create `packages/core/src/schema/subscriptions.ts`:
  ```typescript
  import { pgTable, text, timestamp, integer } from 'drizzle-orm/pg-core'

  // Subscription / trial state for each user.
  // One row per user — upserted on account creation (trial) and on subscription activation.
  // FR82: trial starts at account creation; FR85: data retained 30 days post-trial expiry.
  export const subscriptionsTable = pgTable('subscriptions', {
    userId: text('user_id').primaryKey(),                            // FK to users (add FK when users table created)
    status: text('status').notNull(),                               // 'trialing' | 'active' | 'cancelled' | 'expired' | 'grace_period'
    trialStartedAt: timestamp('trial_started_at', { withTimezone: true }).notNull(),
    trialEndsAt: timestamp('trial_ends_at', { withTimezone: true }).notNull(),
    // Populated on subscription activation (Story 9.3):
    stripeSubscriptionId: text('stripe_subscription_id'),
    stripePriceId: text('stripe_price_id'),
    currentPeriodStart: timestamp('current_period_start', { withTimezone: true }),
    currentPeriodEnd: timestamp('current_period_end', { withTimezone: true }),
    cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
    // 30-day data retention window after trial expires (FR85):
    dataRetentionDeadline: timestamp('data_retention_deadline', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  })
  ```
  **Conventions to follow (ARCH):**
  - `casing: 'camelCase'` is set on the Drizzle instance — ORM maps DB `snake_case` columns to camelCase automatically. Do not do manual field mapping.
  - Table name: `snake_case`, plural → `subscriptions`
  - Export name: `subscriptionsTable` (matches `tasksTable`, `usersTable` pattern)
  - Every table has `created_at` + `updated_at`

- [x] Export from `packages/core/src/schema/index.ts` — add:
  ```typescript
  export * from './subscriptions.js'
  ```

**Files to create/modify:**
- CREATE: `packages/core/src/schema/subscriptions.ts`
- MODIFY: `packages/core/src/schema/index.ts`

---

### Task 2: API — `POST /v1/auth/*` trial initialisation (AC: 1)

The trial must start when a new user account is first created. The auth route (`apps/api/src/routes/auth.ts`) handles Apple Sign In, Google Sign In, and email registration. Each already has a `TODO(impl)` stub handler. Add the trial-start logic to the comment block in each auth creation path.

- [x] In `apps/api/src/routes/auth.ts`, update the stub comment blocks in the `app.openapi(appleRoute, ...)`, `app.openapi(googleRoute, ...)`, and `app.openapi(emailRoute, ...)` handlers to include the trial initialisation step:
  ```typescript
  // TODO(impl): On NEW user creation (not existing user sign-in):
  //   1. INSERT into users (id, email, createdAt, ...)
  //   2. INSERT into subscriptions:
  //      { userId, status: 'trialing',
  //        trialStartedAt: NOW(),
  //        trialEndsAt: NOW() + INTERVAL '14 days',
  //        dataRetentionDeadline: NOW() + INTERVAL '44 days'  // 14 trial + 30 retention
  //      }
  //   Note: dataRetentionDeadline = trialEndsAt + 30 days for post-trial data retention (FR85)
  ```
  **CRITICAL:** Do NOT add `createDb` or Drizzle imports to `auth.ts` — Drizzle TS2345 typecheck incompatibility causes CI failures. TODO(impl) comment only.

**File to modify:** `apps/api/src/routes/auth.ts`

---

### Task 3: API — `GET /v1/subscriptions/me` and `GET /v1/subscriptions/status` route stubs (AC: 2, 3)

Create the new `apps/api/src/routes/subscriptions.ts` route file. Architecture specifies this file at `apps/api/src/routes/subscriptions.ts` (FR49, FR82–84, FR86–90). This story creates the file with Story 9.1 endpoints only; Stories 9.2–9.6 will add remaining endpoints.

- [x] Create `apps/api/src/routes/subscriptions.ts`:
  ```typescript
  import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
  import { z } from 'zod'
  import { ok } from '../lib/response.js'

  // ── Subscriptions router ──────────────────────────────────────────────────────
  // Subscription lifecycle: trial, activation, management, payment failure.
  // (Epic 9, FR49, FR82-90)
  // DB integration deferred — TODO(impl) stubs only (Drizzle TS2345 incompatibility).

  const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

  // ── Schemas ───────────────────────────────────────────────────────────────────

  const SubscriptionStatusSchema = z.object({
    status: z.enum(['trialing', 'active', 'cancelled', 'expired', 'grace_period']),
    trialStartedAt: z.string().datetime().nullable(),
    trialEndsAt: z.string().datetime().nullable(),
    trialDaysRemaining: z.number().int().min(0).nullable(),  // null when not trialing
    dataRetentionDeadline: z.string().datetime().nullable(), // populated after trial expires (FR85)
    stripeSubscriptionId: z.string().nullable(),
    currentPeriodEnd: z.string().datetime().nullable(),
  })

  const SubscriptionStatusResponseSchema = z.object({
    data: SubscriptionStatusSchema,
  })

  const ErrorSchema = z.object({
    error: z.object({ code: z.string(), message: z.string() }),
  })
  ```

- [x] Add `GET /v1/subscriptions/me` route:
  ```typescript
  const getSubscriptionMeRoute = createRoute({
    method: 'get',
    path: '/v1/subscriptions/me',
    tags: ['Subscriptions'],
    summary: 'Get current user subscription status',
    description:
      'Returns the current subscription status for the authenticated user. ' +
      'During free trial: status=trialing, trialDaysRemaining is the days left (rounded down). ' +
      'trialDaysRemaining=0 means the trial expires today. ' +
      'After trial expiry without subscription: status=expired, dataRetentionDeadline is set (FR85). ' +
      'FR87: used to populate Settings → Subscription screen and trial countdown banner.',
    responses: {
      200: {
        content: { 'application/json': { schema: SubscriptionStatusResponseSchema } },
        description: 'Subscription status',
      },
      401: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Unauthenticated',
      },
    },
  })

  app.openapi(getSubscriptionMeRoute, async (_c) => {
    // TODO(impl): const db = createDb(c.env.DATABASE_URL)
    // TODO(impl): const jwtUserId = c.get('jwtPayload').sub
    // TODO(impl): Query subscriptions WHERE userId = jwtUserId
    // TODO(impl): Calculate trialDaysRemaining = Math.max(0, Math.floor((trialEndsAt - NOW()) / 86400000))
    //   Set trialDaysRemaining = null when status !== 'trialing'
    const stubTrialEndsAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString()
    const stubTrialStartedAt = new Date().toISOString()
    return _c.json(
      ok({
        status: 'trialing' as const,
        trialStartedAt: stubTrialStartedAt,
        trialEndsAt: stubTrialEndsAt,
        trialDaysRemaining: 14,
        dataRetentionDeadline: null,
        stripeSubscriptionId: null,
        currentPeriodEnd: null,
      }),
      200,
    )
  })
  ```

- [x] Add `export const subscriptionsRouter = app` at the bottom of the file.

- [x] Register the router in `apps/api/src/index.ts`:
  - Add import: `import { subscriptionsRouter } from './routes/subscriptions.js'`
  - Add route: `app.route('/', subscriptionsRouter)` — place it after `notificationsRouter`

**Files to create/modify:**
- CREATE: `apps/api/src/routes/subscriptions.ts`
- MODIFY: `apps/api/src/index.ts`

---

### Task 4: API — Tests for subscription status endpoint (AC: 2)

Add tests to `apps/api/test/routes/subscriptions.test.ts`. Follow the existing `describe/it/expect` pattern used in all other route test files.

- [x] Create `apps/api/test/routes/subscriptions.test.ts`:
  ```typescript
  import { describe, it, expect } from 'vitest'
  import app from '../../src/index.js'
  ```

- [x] Add tests:
  1. `GET /v1/subscriptions/me` returns 200
  2. `GET /v1/subscriptions/me` response shape has `data.status` field
  3. `GET /v1/subscriptions/me` response `data.status` is a valid enum value (`trialing` | `active` | `cancelled` | `expired` | `grace_period`)
  4. `GET /v1/subscriptions/me` response `data.trialDaysRemaining` is null or a non-negative integer
  5. `GET /v1/subscriptions/me` stub response `data.trialDaysRemaining` equals 14

- [x] **Minimum 5 new tests** — total API test count after this story: 263 (current) + 5 = 268+
- [x] **Do not break existing 263 tests.** Run `pnpm test --filter apps/api` to verify.

**File to create:** `apps/api/test/routes/subscriptions.test.ts`

---

### Task 5: Flutter — `SubscriptionStatus` domain model (AC: 2, 3)

Create the domain model. Follow the plain-class pattern used throughout this project (e.g., `NotificationItem` in Story 8.5 — no freezed, no json_serializable).

- [x] Create `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`:
  ```dart
  // Domain model for user subscription / trial status.
  // Maps to GET /v1/subscriptions/me response.
  // No freezed — plain immutable class (consistent with notification_item.dart,
  // session_model.dart patterns for simple value objects).
  enum SubscriptionState {
    trialing,
    active,
    cancelled,
    expired,
    gracePeriod;  // maps to API 'grace_period'

    static SubscriptionState fromJson(String value) => switch (value) {
      'trialing' => trialing,
      'active' => active,
      'cancelled' => cancelled,
      'expired' => expired,
      'grace_period' => gracePeriod,
      _ => expired, // safe default — treat unknown as expired (no access assumption)
    };
  }

  class SubscriptionStatus {
    const SubscriptionStatus({
      required this.state,
      this.trialStartedAt,
      this.trialEndsAt,
      this.trialDaysRemaining,
      this.dataRetentionDeadline,
      this.stripeSubscriptionId,
      this.currentPeriodEnd,
    });

    final SubscriptionState state;
    final DateTime? trialStartedAt;
    final DateTime? trialEndsAt;
    final int? trialDaysRemaining;     // null when not trialing; 0 = expires today
    final DateTime? dataRetentionDeadline; // set after trial expires (FR85)
    final String? stripeSubscriptionId;
    final DateTime? currentPeriodEnd;

    bool get isTrialing => state == SubscriptionState.trialing;
    bool get isActive => state == SubscriptionState.active;
    bool get isExpired => state == SubscriptionState.expired;

    /// True when the trial countdown banner should be shown (final 3 days).
    bool get showTrialCountdownBanner =>
        isTrialing && trialDaysRemaining != null && trialDaysRemaining! <= 3;
  }
  ```

**File to create:** `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`

---

### Task 6: Flutter — `SubscriptionsRepository` (AC: 2, 3)

Create the data layer. Follow the `NotificationsRepository` pattern (Story 8.5): manual JSON parsing, `ApiClient` Dio, `@riverpod` provider at the bottom, `part` directive for `.g.dart`.

- [x] Create `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart`:
  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../../core/network/api_client.dart';
  import '../domain/subscription_status.dart';

  part 'subscriptions_repository.g.dart';

  class SubscriptionsRepository {
    SubscriptionsRepository({required this.apiClient});
    final ApiClient apiClient;

    /// Fetches the current user's subscription status.
    /// AC: 2 — feeds SubscriptionSettingsScreen and trial countdown banner.
    Future<SubscriptionStatus> getSubscriptionStatus() async {
      final response = await apiClient.dio.get<Map<String, dynamic>>(
        '/v1/subscriptions/me',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return SubscriptionStatus(
        state: SubscriptionState.fromJson(data['status'] as String),
        trialStartedAt: data['trialStartedAt'] != null
            ? DateTime.parse(data['trialStartedAt'] as String)
            : null,
        trialEndsAt: data['trialEndsAt'] != null
            ? DateTime.parse(data['trialEndsAt'] as String)
            : null,
        trialDaysRemaining: data['trialDaysRemaining'] as int?,
        dataRetentionDeadline: data['dataRetentionDeadline'] != null
            ? DateTime.parse(data['dataRetentionDeadline'] as String)
            : null,
        stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
        currentPeriodEnd: data['currentPeriodEnd'] != null
            ? DateTime.parse(data['currentPeriodEnd'] as String)
            : null,
      );
    }
  }

  @riverpod
  SubscriptionsRepository subscriptionsRepository(Ref ref) {
    return SubscriptionsRepository(apiClient: ref.read(apiClientProvider));
  }
  ```
  **CRITICAL:** Import only `package:riverpod_annotation/riverpod_annotation.dart` — NOT `package:flutter_riverpod/flutter_riverpod.dart`. This matches the pattern in `notifications_repository.dart`, `settings_repository.dart`, etc.

- [x] Create `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.g.dart` — manually-maintained `.g.dart` block (CI does not run `build_runner`):
  ```dart
  // GENERATED CODE - DO NOT MODIFY BY HAND

  part of 'subscriptions_repository.dart';

  // **************************************************************************
  // RiverpodGenerator
  // **************************************************************************

  String _$subscriptionsRepositoryHash() => r'impl(9.1):placeholder';

  /// See also [subscriptionsRepository].
  @ProviderFor(subscriptionsRepository)
  final subscriptionsRepositoryProvider =
      AutoDisposeProvider<SubscriptionsRepository>.internal(
    subscriptionsRepository,
    name: r'subscriptionsRepositoryProvider',
    debugGetCreateSourceHash:
        const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$subscriptionsRepositoryHash,
    dependencies: null,
    allTransitiveDependencies: null,
  );

  typedef SubscriptionsRepositoryRef
      = AutoDisposeProviderRef<SubscriptionsRepository>;
  ```
  **NOTE:** The hash `impl(9.1):placeholder` follows the established project convention (same as `notification_handler.g.dart` fake hash). Local `build_runner` will regenerate with a real hash, producing a dirty tree — this is acceptable per project convention.

**Files to create:**
- CREATE: `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart`
- CREATE: `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.g.dart`

---

### Task 7: Flutter — `subscriptionStatusProvider` Riverpod provider (AC: 2, 3)

Add the async provider. Follow the `notificationHistoryProvider` pattern from Story 8.5.

- [x] Create `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.dart`:
  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../data/subscriptions_repository.dart';
  import '../domain/subscription_status.dart';

  part 'subscriptions_provider.g.dart';

  /// Fetches the current user's subscription status.
  /// Async provider — callers use AsyncValue pattern.
  /// Invalidate when subscription state might have changed (post-payment callback in Story 9.3).
  @riverpod
  Future<SubscriptionStatus> subscriptionStatus(Ref ref) async {
    final repo = ref.read(subscriptionsRepositoryProvider);
    return repo.getSubscriptionStatus();
  }
  ```
  **CRITICAL:** `riverpod_annotation` only — NOT `flutter_riverpod`.

- [x] Create `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.g.dart`:
  ```dart
  // GENERATED CODE - DO NOT MODIFY BY HAND

  part of 'subscriptions_provider.dart';

  // **************************************************************************
  // RiverpodGenerator
  // **************************************************************************

  String _$subscriptionStatusHash() => r'impl(9.1):placeholder';

  /// See also [subscriptionStatus].
  @ProviderFor(subscriptionStatus)
  final subscriptionStatusProvider =
      AutoDisposeFutureProvider<SubscriptionStatus>.internal(
    subscriptionStatus,
    name: r'subscriptionStatusProvider',
    debugGetCreateSourceHash:
        const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$subscriptionStatusHash,
    dependencies: null,
    allTransitiveDependencies: null,
  );

  typedef SubscriptionStatusRef
      = AutoDisposeFutureProviderRef<SubscriptionStatus>;
  ```

**Files to create:**
- CREATE: `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.dart`
- CREATE: `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.g.dart`

---

### Task 8: Flutter — `SubscriptionSettingsScreen` (AC: 2)

Create the Settings → Subscription screen. This is the primary destination referenced in the ACs: "X days remaining in your free trial". Follow existing settings screens (`AccountSettingsScreen`, `AppearanceSettingsScreen`) as patterns.

- [x] Create `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`:
  ```dart
  import 'package:flutter/cupertino.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/l10n/strings.dart';
  import 'subscriptions_provider.dart';

  /// Settings → Subscription screen.
  /// Shows trial status or active subscription details.
  /// AC: 2 — FR87: "X days remaining in your free trial"
  class SubscriptionSettingsScreen extends ConsumerWidget {
    const SubscriptionSettingsScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final statusAsync = ref.watch(subscriptionStatusProvider);
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(AppStrings.subscriptionSettingsTitle),
        ),
        child: SafeArea(
          child: statusAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(
              child: Text(AppStrings.subscriptionSettingsLoadError),
            ),
            data: (status) => ListView(
              children: [
                const SizedBox(height: 16),
                _StatusSection(status: status),
                // impl(9.1): Add subscription tier selection CTA when Story 9.2 paywall lands.
              ],
            ),
          ),
        ),
      );
    }
  }

  class _StatusSection extends StatelessWidget {
    const _StatusSection({required this.status});
    final subscription_status.SubscriptionStatus status;  // import as needed

    @override
    Widget build(BuildContext context) {
      if (status.isTrialing) {
        final days = status.trialDaysRemaining ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.subscriptionTrialStatusLabel,
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(AppStrings.subscriptionTrialDaysRemaining(days)),
              const SizedBox(height: 4),
              // impl(9.1): Display trialEndsAt formatted date for clarity.
            ],
          ),
        );
      }
      if (status.isExpired) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(AppStrings.subscriptionExpiredLabel),
        );
      }
      // impl(9.1): active / grace_period states handled in Stories 9.3–9.5.
      return const SizedBox.shrink();
    }
  }
  ```
  **NOTE:** `impl(9.1):` prefix for all deferred notes — NOT `TODO:` (Flutter linter flags `TODO:`).

**File to create:** `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`

---

### Task 9: Flutter — `TrialCountdownBanner` widget (AC: 2)

Create the persistent banner shown in the final 3 days of trial. This banner sits above the tab bar content in `AppShell` — it is a persistent overlay, not a modal. It must not block tab navigation.

- [x] Create `apps/flutter/lib/features/subscriptions/presentation/trial_countdown_banner.dart`:
  ```dart
  import 'package:flutter/cupertino.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';

  import '../../../core/l10n/strings.dart';
  import 'subscriptions_provider.dart';

  /// Persistent trial countdown banner — shown in the final 3 days of trial.
  /// AC: 2 — "in the final 3 days, a persistent trial countdown banner appears in the app"
  ///
  /// Wrap around tab content in AppShell. Conditionally visible — renders
  /// empty SizedBox when not in final 3-day window.
  ///
  /// impl(9.1): Tap navigates to Settings → Subscription (/settings/subscription).
  class TrialCountdownBanner extends ConsumerWidget {
    const TrialCountdownBanner({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final statusAsync = ref.watch(subscriptionStatusProvider);
      return statusAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (status) {
          if (!status.showTrialCountdownBanner) return const SizedBox.shrink();
          final days = status.trialDaysRemaining ?? 0;
          return GestureDetector(
            onTap: () {
              // impl(9.1): context.push('/settings/subscription') when route is registered.
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: CupertinoColors.systemYellow.withOpacity(0.85),
              child: Text(
                AppStrings.trialCountdownBannerText(days),
                style: const TextStyle(
                  color: CupertinoColors.black,
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

- [x] Integrate `TrialCountdownBanner` into `apps/flutter/lib/features/shell/presentation/app_shell.dart`:
  - Import `trial_countdown_banner.dart`
  - Wrap the `CupertinoTabScaffold` in a `Column` that places `TrialCountdownBanner()` above the scaffold:
    ```dart
    Column(
      children: [
        const TrialCountdownBanner(),
        Expanded(child: CupertinoTabScaffold(...)),
      ],
    )
    ```
  - This ensures the banner is visible across all tabs without disrupting tab navigation.

**Files to create/modify:**
- CREATE: `apps/flutter/lib/features/subscriptions/presentation/trial_countdown_banner.dart`
- MODIFY: `apps/flutter/lib/features/shell/presentation/app_shell.dart`

---

### Task 10: Flutter — `AppStrings` additions for subscription copy (AC: 2, 3)

Add strings to `apps/flutter/lib/core/l10n/strings.dart`. Add a new block at the **END** of the `AppStrings` class, before the closing `}`. Follow the pattern of existing Story blocks.

- [x] Add at the end of the `AppStrings` class:
  ```dart
  // ── Subscriptions — Trial Status & Settings (FR82, FR87, Story 9.1) ─────────

  /// Navigation bar title for subscription settings screen.
  static const String subscriptionSettingsTitle = 'Subscription';

  /// Shown when subscription settings fail to load.
  static const String subscriptionSettingsLoadError = 'Couldn\u2019t load subscription status';

  /// Section label for trial status.
  static const String subscriptionTrialStatusLabel = 'Free Trial';

  /// Trial days remaining message — AC: 2, FR87.
  /// Usage: AppStrings.subscriptionTrialDaysRemaining(days)
  static String subscriptionTrialDaysRemaining(int days) =>
      days == 1
          ? '1 day remaining in your free trial'
          : '$days days remaining in your free trial';

  /// Shown when trial has expired and no subscription active.
  static const String subscriptionExpiredLabel = 'Your free trial has ended';

  /// Persistent trial countdown banner text (final 3 days).
  /// Usage: AppStrings.trialCountdownBannerText(days)
  static String trialCountdownBannerText(int days) =>
      days == 1
          ? 'Your free trial ends today \u2014 subscribe to keep access'
          : '$days days left in your free trial \u2014 subscribe to keep access';
  ```

**File to modify:** `apps/flutter/lib/core/l10n/strings.dart`

---

### Task 11: Flutter — `SettingsScreen` subscription tile + router entry (AC: 2)

Add a "Subscription" tile to the settings screen and register the route. Follow the existing tile pattern (e.g., the Payments tile added in Epic 6).

- [x] In `apps/flutter/lib/features/settings/presentation/settings_screen.dart`:
  - Import `SubscriptionSettingsScreen`
  - Add a `_SettingsTile` after the Impact tile (or after Payments — keep it grouped near billing):
    ```dart
    // ── Subscription (Epic 9, Story 9.1) ───────────────────────────────
    _SettingsTile(
      label: AppStrings.subscriptionSettingsTitle,
      icon: CupertinoIcons.calendar_badge_plus,
      onTap: () => context.push('/settings/subscription'),
    ),
    ```

- [x] In `apps/flutter/lib/core/router/app_router.dart`:
  - Import `SubscriptionSettingsScreen`
  - Add a `GoRoute` inside the `/settings` routes block, after the `impact` route:
    ```dart
    // Subscription settings sub-screen (Epic 9, Story 9.1).
    GoRoute(
      path: 'subscription',
      builder: (context, state) => const SubscriptionSettingsScreen(),
    ),
    ```

**Files to modify:**
- MODIFY: `apps/flutter/lib/features/settings/presentation/settings_screen.dart`
- MODIFY: `apps/flutter/lib/core/router/app_router.dart`

---

### Task 12: Flutter — Widget tests (AC: 2)

Add widget tests for the new screens and banner. Follow existing test patterns in `apps/flutter/test/features/`.

- [x] Create `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`:
  1. Loading state shows `CupertinoActivityIndicator`
  2. Trialing state shows `subscriptionTrialDaysRemaining(14)` text
  3. Trialing state with `trialDaysRemaining=1` shows singular "1 day remaining" text
  4. Expired state shows `subscriptionExpiredLabel` text

- [x] Create `apps/flutter/test/features/subscriptions/trial_countdown_banner_test.dart`:
  1. Banner is not visible when `trialDaysRemaining = 14` (outside 3-day window)
  2. Banner is visible when `trialDaysRemaining = 3`
  3. Banner is visible when `trialDaysRemaining = 1`
  4. Banner shows correct text from `trialCountdownBannerText(2)` when `trialDaysRemaining = 2`
  5. Banner is not visible when subscription state is `active`
  6. Banner is not visible when `subscriptionStatusProvider` is in error state

- [x] **Minimum 10 new widget tests** — total Flutter test count after this story: 894 (current) + 10 = 904+
- [x] **Do not break existing 894 Flutter tests.** Run `flutter test` to verify.

**Files to create:**
- CREATE: `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`
- CREATE: `apps/flutter/test/features/subscriptions/trial_countdown_banner_test.dart`

---

## Dev Notes

### Architecture Constraints — Must Follow

**API: Drizzle TS2345 stub pattern**
- All route handler implementations use `TODO(impl)` comment stubs. Do NOT add `createDb(c.env.DATABASE_URL)`, Drizzle imports, or any direct DB calls to route files. This is a pre-existing typecheck incompatibility (`PgTableWithColumns` TS2345) that causes CI failures.
- The schema file in `packages/core/src/schema/subscriptions.ts` is the correct place to define the Drizzle table shape. The route file consumes it only via type inference in future real implementations.
- Pattern established in Stories 6.x, 7.x, 8.x — see `apps/api/src/routes/notifications.ts` for exact stub format.

**Flutter: `.g.dart` files are manually maintained**
- CI does not run `build_runner`. All `.g.dart` files must be manually created with placeholder hashes using `impl(9.1):placeholder` as the hash string.
- The `impl(9.1):` prefix is required for all deferred implementation notes in Dart files — the Flutter linter flags `TODO:` as a warning.
- Use `AutoDisposeProvider<T>` for synchronous providers and `AutoDisposeFutureProvider<T>` for async providers — match types used in similar providers.

**Flutter: Riverpod import discipline**
- Only import `package:riverpod_annotation/riverpod_annotation.dart` in provider and repository files.
- Do NOT import `package:flutter_riverpod/flutter_riverpod.dart` in those files.
- `flutter_riverpod` is only imported in widget files (`ConsumerWidget`, `ConsumerStatefulWidget`).

**Flutter: No freezed / no json_serializable for new domain models in this story**
- `SubscriptionStatus` is a plain Dart class — consistent with `NotificationItem` (Story 8.5), `SessionModel`, and other simple domain models.

### File Locations

| File | Purpose |
|---|---|
| `packages/core/src/schema/subscriptions.ts` | New Drizzle schema — subscription/trial state |
| `apps/api/src/routes/subscriptions.ts` | New API route file (FR49, FR82–90) |
| `apps/api/test/routes/subscriptions.test.ts` | API route tests |
| `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart` | Domain model |
| `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart` | Data layer |
| `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.g.dart` | Manual `.g.dart` |
| `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.dart` | Riverpod provider |
| `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.g.dart` | Manual `.g.dart` |
| `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart` | Settings → Subscription screen |
| `apps/flutter/lib/features/subscriptions/presentation/trial_countdown_banner.dart` | Persistent 3-day banner |
| `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart` | Widget tests |
| `apps/flutter/test/features/subscriptions/trial_countdown_banner_test.dart` | Widget tests |

### Existing Files Modified

| File | Change |
|---|---|
| `packages/core/src/schema/index.ts` | Add `export * from './subscriptions.js'` |
| `apps/api/src/routes/auth.ts` | Add TODO(impl) trial-start comment to stub handlers |
| `apps/api/src/index.ts` | Import + register `subscriptionsRouter` |
| `apps/flutter/lib/core/l10n/strings.dart` | New subscription string block at end of class |
| `apps/flutter/lib/features/settings/presentation/settings_screen.dart` | Add Subscription tile |
| `apps/flutter/lib/core/router/app_router.dart` | Register `/settings/subscription` route |
| `apps/flutter/lib/features/shell/presentation/app_shell.dart` | Wrap with `TrialCountdownBanner` |

### Settings Screen Pattern

The `SettingsScreen` (`apps/flutter/lib/features/settings/presentation/settings_screen.dart`) uses `_SettingsTile` private widgets, imports `go_router`, and uses `context.push('/settings/...')` for named sub-routes. Follow this exact pattern — not `Navigator.of(context).push(CupertinoPageRoute(...))`.

The existing router defines a `/settings` `StatefulShellBranch` at line ~225 of `app_router.dart`. New sub-routes are added as nested `GoRoute` children inside the `/settings` route's `routes:` list. Follow the existing `account` and `impact` sub-routes as the model.

### Trial Countdown Banner Integration

The banner is integrated in `AppShell` (not at the router level). The `AppShell` already uses a `CupertinoTabScaffold` — wrap it in a `Column` with `TrialCountdownBanner()` above the `Expanded(child: CupertinoTabScaffold(...))`. This ensures the banner persists across tab switches.

`TrialCountdownBanner` uses `ref.watch(subscriptionStatusProvider)` and renders `SizedBox.shrink()` unless `status.showTrialCountdownBanner` is true — this avoids layout shifts on most app sessions.

### API Test Count Reference

- Current passing API tests before this story: **263**
- After this story: **268+** (5 minimum new tests)
- Run: `pnpm test --filter apps/api`

### Flutter Test Count Reference

- Current passing Flutter tests before this story: **894**
- After this story: **904+** (10 minimum new widget tests)
- Run: `flutter test` from `apps/flutter/`

### Deferred Items from Prior Stories (relevant to this story)

From `deferred-work.md` — no items directly block this story. Noting for awareness:
- `response.data!` null-assertion pattern (Story 8.5 `notifications_repository.dart`) — this story follows the same pattern in `subscriptions_repository.dart`. Pre-existing; address when error-handling conventions are standardised.

### Epic 9 Cross-Story Dependencies

- **Story 9.3 dependency**: Epic 13 Story 13.1 (AASA + Universal Links) must be deployed before Story 9.3 can be tested end-to-end. Noted in `sprint-status.yaml` comment block. This story (9.1) has no dependency on Story 13.1.
- **Story 9.2 (Paywall)**: `SubscriptionSettingsScreen` includes an `impl(9.1):` stub comment for the subscribe CTA — Story 9.2 will add the real CTA.
- **Story 9.3 (Subscription Activation)**: When a subscription is activated, `subscriptionStatusProvider` must be invalidated (`ref.invalidate(subscriptionStatusProvider)`) to refresh the settings screen and hide the trial banner. This invalidation is Story 9.3's responsibility.
- The `subscriptions.ts` route file created in this story becomes the home for all subsequent Epic 9 API endpoints.

### Project Structure Notes

- Alignment with architecture: `apps/flutter/lib/features/subscriptions/` is the authoritative feature directory per ARCH (`apps/flutter/lib/features/subscriptions/` → FR49, FR82–90).
- The API route `apps/api/src/routes/subscriptions.ts` is the authoritative location per ARCH tree (`subscriptions.ts — FR49, FR82-84, FR86-90`).
- Schema: `packages/core/src/schema/subscriptions.ts` follows the existing schema file naming convention.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` Epic 9, Story 9.1 — ACs and FRs]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — Flutter feature directory layout, API route tree, DB schema conventions, Drizzle casing config]
- [Source: `_bmad-output/implementation-artifacts/8-5-in-app-notification-centre-voiceover-live-activity-announcements.md` — TODO(impl) pattern, .g.dart manual block format, impl(X.Y) deferred note prefix, `riverpod_annotation` import discipline]
- [Source: `apps/api/src/routes/notifications.ts` — createRoute + OpenAPIHono stub handler pattern]
- [Source: `apps/flutter/lib/features/settings/presentation/settings_screen.dart` — _SettingsTile pattern, context.push navigation]
- [Source: `apps/flutter/lib/core/router/app_router.dart` — /settings GoRoute nested structure]
- [Source: `apps/flutter/lib/features/shell/presentation/app_shell.dart` — CupertinoTabScaffold structure for banner integration]
- [Source: `apps/flutter/lib/core/l10n/strings.dart` — AppStrings addition pattern (end of class)]
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml` — Epic 9 note re Story 13.1 dependency for Story 9.3]
- [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — response.data! null-assertion pre-existing pattern]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Implemented all 12 tasks for Story 9.1 across API (TypeScript) and Flutter (Dart) layers.
- Created `subscriptionsTable` Drizzle schema with trial, retention, and Stripe fields; exported from schema index.
- Added `TODO(impl)` trial-start comment blocks to all three auth handlers (Apple, Google, email) without Drizzle imports (respecting TS2345 constraint).
- Created `apps/api/src/routes/subscriptions.ts` with `GET /v1/subscriptions/me` stub returning trialing status with 14 days remaining; registered router in `index.ts`.
- 5 new API tests added (268 total, 0 regressions).
- Created Flutter subscriptions feature: domain model (`SubscriptionStatus`/`SubscriptionState`), `SubscriptionsRepository`, `subscriptionStatusProvider`, `SubscriptionSettingsScreen`, `TrialCountdownBanner`.
- Manually authored `.g.dart` files using the `$FunctionalProvider`/`$FutureProvider` pattern matching the actual riverpod version in the project (not the older `AutoDisposeProvider.internal` pattern in the story spec).
- Integrated `TrialCountdownBanner` into `AppShell` via `Column` + `Expanded(child: CupertinoTabScaffold(...))`.
- Added subscription strings block to `AppStrings`, Subscription tile to `SettingsScreen`, and `/settings/subscription` GoRoute to `app_router.dart`.
- 10 new widget tests added (904 total, 0 regressions).

### File List

**Created:**
- `packages/core/src/schema/subscriptions.ts`
- `apps/api/src/routes/subscriptions.ts`
- `apps/api/test/routes/subscriptions.test.ts`
- `apps/flutter/lib/features/subscriptions/domain/subscription_status.dart`
- `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.dart`
- `apps/flutter/lib/features/subscriptions/data/subscriptions_repository.g.dart`
- `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.dart`
- `apps/flutter/lib/features/subscriptions/presentation/subscriptions_provider.g.dart`
- `apps/flutter/lib/features/subscriptions/presentation/subscription_settings_screen.dart`
- `apps/flutter/lib/features/subscriptions/presentation/trial_countdown_banner.dart`
- `apps/flutter/test/features/subscriptions/subscription_settings_screen_test.dart`
- `apps/flutter/test/features/subscriptions/trial_countdown_banner_test.dart`

**Modified:**
- `packages/core/src/schema/index.ts`
- `apps/api/src/routes/auth.ts`
- `apps/api/src/index.ts`
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/flutter/lib/features/settings/presentation/settings_screen.dart`
- `apps/flutter/lib/core/router/app_router.dart`
- `apps/flutter/lib/features/shell/presentation/app_shell.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-04-01: Story 9.1 implemented — Drizzle subscription schema, API stub route for GET /v1/subscriptions/me, Flutter subscriptions feature layer (domain model, repository, provider, settings screen, trial countdown banner), AppStrings additions, Settings tile + router entry. 268 API tests / 904 Flutter tests passing.
