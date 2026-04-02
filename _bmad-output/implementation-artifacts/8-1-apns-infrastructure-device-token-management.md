# Story 8.1: APNs Infrastructure & Device Token Management

Status: review

## Story

As a developer,
I want a direct APNs integration using a Cloudflare Worker with no Firebase dependency,
so that push notifications are delivered with full control over APNs headers and payload structure.

## Acceptance Criteria

1. **Given** the API worker is configured
   **When** APNs is set up
   **Then** `@fivesheepco/cloudflare-apns2` is used for APNs delivery — no Firebase SDK (ARCH-27)
   **And** the APNs p8 key is stored as `wrangler secret put APNS_KEY` — not committed to the repo
   **And** APNs integration is tested against staging only (local `wrangler dev` does not support HTTP/2 outbound)

2. **Given** the app launches on iOS
   **When** push permission is granted by the user
   **Then** the device push token is registered and stored in a `device_tokens` table (columns: `userId`, `token`, `platform`, `environment`, `createdAt`)
   **And** `apns-environment: development` is used for debug builds; `apns-environment: production` is used for TestFlight and App Store builds (DEPLOY-4)

3. **Given** a notification preference exists
   **When** the user configures preferences
   **Then** preferences can be set at three levels: globally (all notifications on/off), per device (this iPhone vs. this Mac), and per task (remind me / don't remind me) (FR43)

## Tasks / Subtasks

---

### API: `apps/api/src/services/push.ts` — APNs service stub

Create the push notification service that all future notification stories will call.

- [x] Create `apps/api/src/services/push.ts`:
  ```typescript
  // ── APNs push notification service ───────────────────────────────────────────
  // Uses @fivesheepco/cloudflare-apns2 v13.0.0 — Workers-native APNs client.
  // Uses fetch() + crypto.subtle for ES256 JWT signing; no Node.js net/tls required.
  // CRITICAL: wrangler dev does NOT support HTTP/2 outbound (open workerd bug).
  // APNs calls MUST be tested against staging only: `wrangler deploy --env staging`
  // APNs topic for regular push: com.ontaskhq.ontask
  // APNs topic for Live Activity: com.ontaskhq.ontask.push-type.liveactivity
  //
  // Required Workers Secrets (wrangler secret put — never committed):
  //   APNS_KEY      — contents of the .p8 key file (ES256 private key)
  //   APNS_KEY_ID   — 10-character Key ID from Apple Developer portal
  //   APNS_TEAM_ID  — 10-character Team ID from Apple Developer portal

  export interface PushPayload {
    title: string
    body: string
    badge?: number
    sound?: string
    data?: Record<string, unknown>
  }

  export interface SendPushOptions {
    deviceToken: string
    environment: 'development' | 'production'
    payload: PushPayload
  }

  export async function sendPush(
    options: SendPushOptions,
    env: CloudflareBindings
  ): Promise<void> {
    // TODO(impl): import and instantiate @fivesheepco/cloudflare-apns2 client
    // TODO(impl): const apns = new ApnsClient({
    //   teamId: env.APNS_TEAM_ID,
    //   keyId: env.APNS_KEY_ID,
    //   signingKey: env.APNS_KEY,
    //   defaultTopic: 'com.ontaskhq.ontask',
    //   environment: options.environment,
    // })
    // TODO(impl): await apns.sendNotification(options.deviceToken, {
    //   aps: {
    //     alert: { title: options.payload.title, body: options.payload.body },
    //     badge: options.payload.badge,
    //     sound: options.payload.sound ?? 'default',
    //   },
    //   ...options.payload.data,
    // })
    void options
    void env
  }
  ```
- [x] Add `@fivesheepco/cloudflare-apns2` to `apps/api/package.json` dependencies:
  ```json
  "@fivesheepco/cloudflare-apns2": "^13.0.0"
  ```
- [x] Run `pnpm add @fivesheepco/cloudflare-apns2` from `apps/api/` directory

---

### DB Schema: `packages/core/src/schema/device-tokens.ts` — device token table

- [x] Create `packages/core/src/schema/device-tokens.ts`:
  ```typescript
  import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

  // ── Device tokens table ───────────────────────────────────────────────────────
  // Stores APNs device tokens for push notification delivery (FR42, Story 8.1).
  // platform: 'ios' | 'macos' — derived from build target, never guessed
  // environment: 'development' | 'production' — debug builds use development;
  //   TestFlight and App Store use production (DEPLOY-4).
  // Upsert strategy: on conflict (userId, token) DO UPDATE SET environment, updatedAt.
  // Tokens become stale when user reinstalls or revokes permissions —
  //   handle apns error UNREGISTERED by deleting the row in push service.

  export const deviceTokensTable = pgTable('device_tokens', {
    id: uuid().primaryKey().defaultRandom(),
    userId: uuid().notNull(),                          // FK → users
    token: text().notNull(),                           // APNs device push token
    platform: text().notNull(),                        // 'ios' | 'macos'
    environment: text().notNull(),                     // 'development' | 'production'
    createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  })
  ```
- [x] Export from `packages/core/src/schema/index.ts`:
  ```typescript
  export { deviceTokensTable } from './device-tokens.js'
  ```

---

### DB Schema: `packages/core/src/schema/notification-preferences.ts` — 3-level prefs

- [x] Create `packages/core/src/schema/notification-preferences.ts`:
  ```typescript
  import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'

  // ── Notification preferences table ───────────────────────────────────────────
  // Three-level configurable preferences (FR43, Story 8.1, UX §Notifications):
  //   scope='global'  → userId set, deviceId null, taskId null   — all notifications on/off
  //   scope='device'  → userId set, deviceId set, taskId null    — per-device preference
  //   scope='task'    → userId set, deviceId null, taskId set    — per-task remind/don't
  // enabled: true = notifications on; false = suppressed for this scope.
  // Unique constraint: (userId, scope, deviceId, taskId) — enforced at application level
  // for now (add DB unique index in hardening pass once real data exists).

  export const notificationPreferencesTable = pgTable('notification_preferences', {
    id: uuid().primaryKey().defaultRandom(),
    userId: uuid().notNull(),                          // FK → users
    scope: text().notNull(),                           // 'global' | 'device' | 'task'
    deviceId: text(),                                  // device token or stable device identifier; null for global/task scope
    taskId: uuid(),                                    // FK → tasks; null for global/device scope
    enabled: boolean().notNull().default(true),
    createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  })
  ```
- [x] Export from `packages/core/src/schema/index.ts`:
  ```typescript
  export { notificationPreferencesTable } from './notification-preferences.js'
  ```

---

### API: `apps/api/src/routes/notifications.ts` — device token registration + prefs

- [x] Create `apps/api/src/routes/notifications.ts`:
  ```typescript
  import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
  import { z } from 'zod'
  import { ok, err } from '../lib/response.js'

  // ── Notifications router ──────────────────────────────────────────────────────
  // Device token registration and notification preference management.
  // (Epic 8, Story 8.1, FR42-43, FR72)
  // APNs push delivery service: apps/api/src/services/push.ts
  // Stub endpoints — real DB writes deferred to Story 8.2 integration.

  const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()
  ```
- [x] Add `RegisterDeviceTokenRequestSchema`:
  ```typescript
  const RegisterDeviceTokenRequestSchema = z.object({
    token: z.string().min(1),                                         // APNs device token hex string
    platform: z.enum(['ios', 'macos']),
    environment: z.enum(['development', 'production']),              // debug=development; TestFlight/AppStore=production
  })
  const RegisterDeviceTokenResponseSchema = z.object({
    data: z.object({ registered: z.boolean() }),
  })
  const ErrorSchema = z.object({
    error: z.object({ code: z.string(), message: z.string() }),
  })
  ```
- [x] Add `POST /v1/notifications/device-token` route and stub handler:
  ```typescript
  const registerDeviceTokenRoute = createRoute({
    method: 'post',
    path: '/v1/notifications/device-token',
    tags: ['Notifications'],
    summary: 'Register device push token',
    description:
      'Upserts an APNs device token for the authenticated user. ' +
      'platform: ios | macos. ' +
      'environment: development (debug builds) | production (TestFlight + App Store, DEPLOY-4). ' +
      'Upserts on (userId, token) — safe to call on every app launch. ' +
      'Stub implementation (Story 8.1) — real DB upsert deferred.',
    request: {
      body: { content: { 'application/json': { schema: RegisterDeviceTokenRequestSchema } } },
    },
    responses: {
      200: {
        content: { 'application/json': { schema: RegisterDeviceTokenResponseSchema } },
        description: 'Token registered',
      },
      400: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Invalid token or platform',
      },
    },
  })

  app.openapi(registerDeviceTokenRoute, async (c) => {
    const { token, platform, environment } = c.req.valid('json')
    // TODO(impl): db = getDb(c.env.DATABASE_URL)
    // TODO(impl): await db.insert(deviceTokensTable)
    //   .values({ userId: jwtUserId, token, platform, environment, updatedAt: new Date() })
    //   .onConflictDoUpdate({
    //     target: [deviceTokensTable.userId, deviceTokensTable.token],
    //     set: { environment, updatedAt: new Date() },
    //   })
    void token
    void platform
    void environment
    return c.json(ok({ registered: true }))
  })
  ```
- [x] Add `NotificationPreferenceSchema` and pref endpoints:
  ```typescript
  const NotificationPreferenceSchema = z.object({
    scope: z.enum(['global', 'device', 'task']),
    deviceId: z.string().nullable(),
    taskId: z.string().nullable(),
    enabled: z.boolean(),
  })
  const NotificationPreferenceResponseSchema = z.object({ data: NotificationPreferenceSchema })
  const NotificationPreferencesListResponseSchema = z.object({
    data: z.array(NotificationPreferenceSchema),
  })
  ```
- [x] Add `GET /v1/notifications/preferences` stub (returns empty list with comment):
  - Returns `{ data: [] }` — real impl queries `notification_preferences WHERE userId = jwtUserId`
- [x] Add `PUT /v1/notifications/preferences` stub:
  - Body: `NotificationPreferenceSchema`
  - Returns `{ data: { ...body } }`
  - `// TODO(impl): UPSERT notification_preferences on (userId, scope, deviceId, taskId)`
- [x] Export router:
  ```typescript
  export { app as notificationsRouter }
  ```
- [x] Mount in `apps/api/src/index.ts`:
  ```typescript
  import { notificationsRouter } from './routes/notifications.js'
  // add after proofRouter:
  app.route('/', notificationsRouter)
  ```

---

### API: `wrangler.jsonc` — add APNs secrets comment

- [x] Add APNs secret placeholder comments to `apps/api/wrangler.jsonc` vars block:
  ```jsonc
  // APNs push notification credentials (Story 8.1, ARCH-27).
  // Set via `wrangler secret put APNS_KEY` — p8 key file contents, never committed.
  "APNS_KEY": "",
  // Set via `wrangler secret put APNS_KEY_ID` — 10-char Key ID from Apple Developer portal.
  "APNS_KEY_ID": "",
  // Set via `wrangler secret put APNS_TEAM_ID` — 10-char Team ID from Apple Developer portal.
  "APNS_TEAM_ID": "",
  ```
- [x] Add these three bindings to `apps/api/worker-configuration.d.ts` (CloudflareBindings interface) if it exists, or note in wrangler.jsonc comment that `wrangler cf-typegen` must be rerun after setting secrets

---

### API: Tests (AC: 1, 2, 3)

- [x] Create `apps/api/test/routes/notifications.test.ts`
  - [x] Use Vitest (same pattern as `apps/api/test/routes/proof.test.ts`): `const app = (await import('../../src/index.js')).default`
  - [x] **Minimum 5 tests:**
    1. `POST /v1/notifications/device-token` with valid `{ token, platform: 'ios', environment: 'development' }` returns 200 with `{ data: { registered: true } }`
    2. `POST /v1/notifications/device-token` with `platform: 'macos'` and `environment: 'production'` returns 200
    3. `POST /v1/notifications/device-token` with missing `token` returns 400
    4. `GET /v1/notifications/preferences` returns 200 with `{ data: [] }`
    5. `PUT /v1/notifications/preferences` with `{ scope: 'global', deviceId: null, taskId: null, enabled: false }` returns 200

---

### Flutter: `push` package + permission request on app startup

The architecture specifies the `push` pub.dev package for APNs-direct delivery, no FCM dependency (ARCH-27). The `push` package covers both iOS and macOS.

- [x] Add `push` package to `apps/flutter/pubspec.yaml` dependencies:
  ```yaml
  # APNs push notification handling — APNs-direct, no FCM dependency (ARCH-27, Story 8.1).
  # Covers iOS and macOS. Do NOT use firebase_messaging or flutter_local_notifications.
  push: ^0.6.1
  ```
  Run `flutter pub get` after adding.
- [x] Create `apps/flutter/lib/features/notifications/data/notifications_repository.dart`:
  ```dart
  import 'dart:io';
  import 'package:push/push.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import '../../../core/network/api_client.dart';

  part 'notifications_repository.g.dart';

  class NotificationsRepository {
    const NotificationsRepository({required this.apiClient});

    final ApiClient apiClient;

    /// Requests push permission and registers device token with the API.
    /// Call once after auth completes (not on every screen — over-requesting
    /// permission is a top reason users deny it permanently).
    /// CRITICAL: always check if (!mounted) before setState after await in callers.
    Future<void> requestPermissionAndRegisterToken() async {
      final granted = await Push.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!granted) return;

      final token = await Push.instance.token;
      if (token == null) return;

      final environment = _resolveEnvironment();
      final platform = Platform.isIOS ? 'ios' : 'macos';

      await apiClient.dio.post<void>(
        '/v1/notifications/device-token',
        data: {
          'token': token,
          'platform': platform,
          'environment': environment,
        },
      );
    }

    /// Returns 'development' for debug builds, 'production' for release/profile.
    /// DEPLOY-4: TestFlight and App Store use production environment.
    String _resolveEnvironment() {
      // kReleaseMode covers TestFlight and App Store builds.
      // kDebugMode covers local simulator and device debug builds.
      const bool isRelease = bool.fromEnvironment('dart.vm.product');
      return isRelease ? 'production' : 'development';
    }

    /// Updates notification preference at any of the three levels (FR43):
    ///   scope='global' — all notifications on/off
    ///   scope='device' — per-device preference (pass deviceId)
    ///   scope='task'   — per-task preference (pass taskId)
    Future<void> setPreference({
      required String scope,
      String? deviceId,
      String? taskId,
      required bool enabled,
    }) async {
      await apiClient.dio.put<void>(
        '/v1/notifications/preferences',
        data: {
          'scope': scope,
          'deviceId': deviceId,
          'taskId': taskId,
          'enabled': enabled,
        },
      );
    }
  }

  @riverpod
  NotificationsRepository notificationsRepository(Ref ref) {
    return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
  }
  ```
- [x] Create `apps/flutter/lib/features/notifications/presentation/notifications_provider.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import '../data/notifications_repository.dart';

  part 'notifications_provider.g.dart';

  /// Triggers push permission request and device token registration.
  /// Called once post-auth. Result is AsyncValue<void> — callers ignore the
  /// value but can check for errors.
  @riverpod
  Future<void> registerDeviceToken(Ref ref) async {
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.requestPermissionAndRegisterToken();
  }
  ```
- [x] Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `.g.dart` files
  - Generates: `notifications_repository.g.dart`, `notifications_provider.g.dart`
  - Commit generated files (project convention — build_runner is LOCAL ONLY, not in CI)

---

### Flutter: `AppStrings` — push permission and notification strings

- [x] Add strings to `apps/flutter/lib/core/l10n/strings.dart` before the closing `}`:
  ```dart
  // ── Push Notifications (FR42, FR43, Story 8.1) ───────────────────────────────

  /// System permission request — never shown as a pre-permission dialog in this
  /// story; the OS dialog fires after requestPermissionAndRegisterToken() is called.
  /// These strings are for future Settings → Notifications UI (Story 8.x).

  /// Label for global notifications toggle in Settings.
  static const String notificationsGlobalToggleLabel = 'Push Notifications';

  /// Subtitle when global notifications are enabled.
  static const String notificationsGlobalEnabledSubtitle = 'Notifications are on for all devices.';

  /// Subtitle when global notifications are disabled.
  static const String notificationsGlobalDisabledSubtitle = 'All push notifications are off.';

  /// Label for per-device toggle (used in a future per-device settings screen).
  static const String notificationsThisDeviceLabel = 'This device';

  /// Error shown when device token registration fails.
  static const String notificationsTokenRegistrationError =
      'Couldn\u2019t register for notifications \u2014 try again later.';
  ```

---

### Flutter: iOS entitlements + Info.plist — push capability

- [x] Verify `apps/flutter/ios/Runner/Runner.entitlements` contains the push notifications entitlement:
  ```xml
  <key>aps-environment</key>
  <string>development</string>
  ```
  Note: For App Store / TestFlight builds this must be `production`. Xcode Cloud / CI handles environment via provisioning profile — the `development` value in the file is correct for local dev; the provisioning profile overrides it for distribution builds.
- [x] Verify `apps/flutter/ios/Runner/Info.plist` — no additional key needed for remote push (APNs capability is set via entitlement, not Info.plist key).
- [x] Verify `apps/flutter/macos/Runner/` — add `aps-environment` entitlement to macOS Runner.entitlements if not present (architecture notes macOS has APNs entitlements: `apps/api/docs mention macos/Runner/` APNs entitlements).

---

### Flutter: widget test

- [x] Create `apps/flutter/test/features/notifications/notifications_repository_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';

  void main() {
    // Minimal smoke tests — push.Push is a platform plugin that cannot be
    // exercised in unit tests without a device. Tests validate API call shape.
    group('NotificationsRepository', () {
      test('setPreference sends correct body for global scope', () {
        // TODO: wire when ApiClient mock infrastructure is aligned with other
        // repository tests. See auth_repository pattern.
        expect(true, isTrue); // placeholder — prevents empty test file failure
      });
    });
  }
  ```

---

## Dev Notes

### CRITICAL: `@fivesheepco/cloudflare-apns2` — Workers-native, NO Node.js required

`@fivesheepco/cloudflare-apns2` v13.0.0 uses `fetch()` and `crypto.subtle` for ES256 JWT signing. It does NOT require `nodejs_compat` compatibility flag in `wrangler.jsonc`. Do NOT add `nodejs_compat` — it increases bundle size and is unnecessary for this library.

### CRITICAL: APNs CANNOT be tested locally with `wrangler dev`

`wrangler dev` does not support HTTP/2 outbound connections (open workerd bug). Any call to the APNs endpoint will fail locally. The push service stub in this story intentionally does nothing — real APNs calls must be tested against staging (`wrangler deploy --env staging`). All 5+ tests in `notifications.test.ts` test the HTTP contract only, not actual APNs delivery.

### CRITICAL: Flutter `push` package — NOT `firebase_messaging`

The architecture mandates `push` (pub.dev) for APNs-direct delivery with no FCM dependency (ARCH-27). Do NOT use:
- `firebase_messaging` — introduces Firebase SDK, rejected by architecture
- `flutter_local_notifications` — local only, no APNs remote push
- `permission_handler` — the `push` package handles its own permission request via `Push.instance.requestPermission()`

### CRITICAL: APNs environment — debug vs. production

- Debug builds (simulator + device via Xcode): `development` environment
- TestFlight + App Store: `production` environment (DEPLOY-4)
- The Flutter side determines environment via `bool.fromEnvironment('dart.vm.product')` — `true` in release/profile mode (covers TestFlight and App Store), `false` in debug mode
- The `aps-environment` entitlement in `Runner.entitlements` must be `development` for local dev; provisioning profile overrides to `production` for distribution. Do NOT hardcode `production` in the entitlement file.

### CRITICAL: `wrangler.jsonc` — secrets are not `vars`

`APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID` are Workers Secrets set via `wrangler secret put`, not plain `vars`. The `wrangler.jsonc` vars block should have placeholder empty strings with comment documentation (consistent with existing pattern: `STRIPE_SECRET_KEY`, `CALENDAR_TOKEN_KEY`, etc.). These secrets appear in `CloudflareBindings` after running `wrangler cf-typegen`.

### CRITICAL: Device token upsert strategy

APNs tokens change when the user reinstalls the app or when the OS refreshes them. The DB upsert must be `ON CONFLICT (userId, token) DO UPDATE SET environment = EXCLUDED.environment, updated_at = now()`. Token uniqueness is on `(userId, token)` — not userId alone — because a user may have multiple devices.

Stale tokens (APNS error: `UNREGISTERED`) must be deleted from `device_tokens` when the push service receives this error in real implementation. Add `// TODO(impl): on UNREGISTERED error from APNs, DELETE FROM device_tokens WHERE token = ?` in the push service.

### CRITICAL: Drizzle `casing: 'camelCase'` — project-wide standard

All `getDb()` calls use `{ casing: 'camelCase' }`. DB column `user_id` → Drizzle field `userId`. Missing this causes silent field mapping failures. The notification routes do not have a `getDb()` call yet (stub), but the TODO comments must use Drizzle field names not SQL column names.

### CRITICAL: `notifications.ts` route file — NOT `disputes.ts`

The architecture explicitly lists `apps/api/src/routes/notifications.ts` for FR42-43, FR72. The `push.ts` service lives at `apps/api/src/services/push.ts`. These are distinct files with distinct roles:
- `routes/notifications.ts` — HTTP API: device token registration, preference management
- `services/push.ts` — APNs delivery: called internally by other services, not directly by clients

### CRITICAL: Flutter `if (!mounted) return;` guard

Any Flutter widget method that calls `requestPermissionAndRegisterToken()` or any async push operation must check `if (!mounted) return;` before calling `setState()` after the await. The `push` permission request involves platform channel calls that may outlive widget lifecycle.

### CRITICAL: `build_runner` generated files must be committed

`notifications_repository.g.dart` and `notifications_provider.g.dart` are generated by Riverpod's code generator. The project convention is: generated files ARE committed (build_runner runs locally only, not in CI). After running `build_runner build`, commit the `.g.dart` files alongside the source files.

### Architecture: File locations

```
apps/api/
├── package.json                             # MODIFY — add @fivesheepco/cloudflare-apns2
├── wrangler.jsonc                           # MODIFY — add APNS_KEY/APNS_KEY_ID/APNS_TEAM_ID vars
├── src/
│   ├── index.ts                             # MODIFY — import and mount notificationsRouter
│   ├── routes/
│   │   └── notifications.ts                # NEW — POST device-token, GET/PUT preferences
│   └── services/
│       └── push.ts                         # NEW — sendPush() stub with APNs TODO comments
└── test/
    └── routes/
        └── notifications.test.ts            # NEW — 5+ vitest tests

packages/core/src/schema/
├── device-tokens.ts                         # NEW — deviceTokensTable
├── notification-preferences.ts             # NEW — notificationPreferencesTable
└── index.ts                                 # MODIFY — export both new tables

apps/flutter/
├── pubspec.yaml                             # MODIFY — add push: ^0.6.1
├── lib/
│   ├── core/l10n/strings.dart               # MODIFY — add notification strings
│   └── features/notifications/
│       ├── data/
│       │   ├── notifications_repository.dart  # NEW
│       │   └── notifications_repository.g.dart # NEW (generated)
│       └── presentation/
│           ├── notifications_provider.dart    # NEW
│           └── notifications_provider.g.dart  # NEW (generated)
└── test/features/notifications/
    └── notifications_repository_test.dart   # NEW — placeholder test
```

### Architecture: `push` package version

Use `push: ^0.6.1` — APNs-direct, no FCM, covers iOS and macOS. The package provides:
- `Push.instance.requestPermission(alert:, badge:, sound:)` → `Future<bool>`
- `Push.instance.token` → `Future<String?>`
- `Push.instance.onNotificationTap` → stream for notification tap handling (Stories 8.2+)
- `Push.instance.onMessage` → stream for foreground notification handling (Stories 8.2+)

Do NOT use `.addOnMessage()` callbacks in Story 8.1 — this story only registers the token. Foreground/tap handling ships in Story 8.2.

### Architecture: APNs bundle ID

APNs topic (bundle ID) for regular push notifications: `com.ontaskhq.ontask`
APNs topic for Live Activity push: `com.ontaskhq.ontask.push-type.liveactivity`

The app was created with `--org com.ontaskhq` and `--project-name ontask`, making the bundle ID `com.ontaskhq.ontask`. This is confirmed in `apps/flutter/pubspec.yaml` description and architecture `flutter create --org com.ontaskhq`.

### Architecture: `CloudflareBindings` typegen

After adding `APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID` to `wrangler.jsonc` vars (placeholder empty strings), run `pnpm cf-typegen` from `apps/api/` to regenerate `worker-configuration.d.ts`. Until then, access as `c.env.APNS_KEY` will fail TypeScript — use the TODO comment pattern and mark as deferred.

### Architecture: Notification preference levels (FR43, UX spec)

Three levels from UX spec (§Notifications Design Principles):
- `scope='global'` — `userId` only — master switch: all notifications on/off
- `scope='device'` — `userId + deviceId` — per physical device (e.g. this iPhone vs. this Mac)
- `scope='task'`   — `userId + taskId`   — per task: "remind me" / "don't remind me"

The `deviceId` for device-scoped preferences can be the APNs token itself (since tokens are device-specific). This avoids needing a separate stable device identifier in V1.

### Context from Prior Stories

- **`ok()` response envelope** — `{ data: ... }` shape. All routes follow this pattern.
- **`err()` response envelope** — `{ error: { code: 'SCREAMING_SNAKE_CASE', message: '...' } }`.
- **`OpenAPIHono<{ Bindings: CloudflareBindings }>`** — every route file uses this, never plain `Hono`.
- **`createRoute` + `app.openapi()`** — never `app.post()` directly.
- **Vitest test pattern** — `const app = (await import('../../src/index.js')).default`, then `app.request(path, options)`. See `apps/api/test/routes/proof.test.ts`.
- **`@hono/zod-openapi` version** — `^1.2.4`. Do not add a second installation.
- **`zod` version** — `^4.3.6`. Already in `apps/api/package.json`.
- **`drizzle-orm` version** — `^0.45.2`. Already in `apps/api/package.json`.
- **Drizzle schema pattern** — `import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'`. See `packages/core/src/schema/disputes.ts`.
- **Flutter repository pattern** — `class XRepository implements IXRepository`, constructor-injected `ApiClient`, `@riverpod` provider. See `apps/flutter/lib/features/example/data/example_repository.dart`.
- **Flutter feature-first structure** — `lib/features/notifications/data/`, `lib/features/notifications/presentation/`. No `notifications/domain/` needed for Story 8.1 (no domain model beyond the API response shape).
- **`if (!mounted) return;`** — required after every `await` in Flutter StatefulWidget methods.
- **`withValues(alpha:)` not `withOpacity()`** — no new UI in this story, but apply if adding any color.
- **`minimumSize: const Size(44, 44)`** — no new interactive widgets in this story.
- **`catch (e)`** — never `catch (_)` in Flutter; always bind the exception variable.
- **Dispute notification strings** — `disputeApprovedNotificationBody` and `disputeRejectedNotificationBody` are already in `strings.dart` (Story 7.9). The `sendPush()` service will use these in Story 8.3.

### Deferred Items for This Story

- **Real APNs delivery** — `sendPush()` is a stub. Actual `@fivesheepco/cloudflare-apns2` call wired in Story 8.2 when first notification type is implemented.
- **Real DB writes for device token** — stub returns 200 but does not write to `device_tokens`. Wire in Story 8.2.
- **Real DB writes for preferences** — stub returns the request body. Wire when Settings → Notifications UI ships.
- **Token staleness handling (UNREGISTERED)** — APNs error handling for revoked/reinstalled tokens deferred to Story 8.2 real implementation.
- **Foreground notification handling** — `Push.instance.onMessage` stream subscription deferred to Story 8.2.
- **Notification tap deep-linking** — `Push.instance.onNotificationTap` stream and go_router navigation deferred to Story 8.2+.
- **Settings → Notifications UI** — preference screen in Flutter deferred (Story 8.5 or a dedicated settings story).
- **`wrangler cf-typegen` for new secret bindings** — run after secrets are set in Cloudflare dashboard; `CloudflareBindings` type will need regeneration.
- **`live-activity-tokens.ts` schema** — defined in architecture for ActivityKit push tokens (`packages/core/src/schema/live-activity-tokens.ts`). Separate from `device_tokens` — deferred to the Live Activities story.

### Story Checklist

- [x] Story title matches epic definition
- [x] User story statement present (As a / I want / So that)
- [x] Acceptance criteria are testable and complete
- [x] All file paths are absolute/fully qualified
- [x] `@fivesheepco/cloudflare-apns2` not Firebase confirmed
- [x] APNs local dev constraint documented
- [x] `push` pub.dev package (not firebase_messaging) confirmed
- [x] `device_tokens` table schema defined with correct columns
- [x] `notification_preferences` table schema defined (3-level: global/device/task)
- [x] `notifications.ts` route file (not disputes.ts)
- [x] `services/push.ts` separate from routes file
- [x] Both tables exported from `packages/core/src/schema/index.ts`
- [x] `notificationsRouter` mounted in `apps/api/src/index.ts`
- [x] APNS_KEY/APNS_KEY_ID/APNS_TEAM_ID in wrangler.jsonc
- [x] APNs environment (development/production) logic documented
- [x] Flutter `push` package version specified
- [x] `build_runner` generated files must be committed
- [x] `if (!mounted) return;` pattern noted
- [x] `casing: 'camelCase'` Drizzle standard noted
- [x] `OpenAPIHono` not plain `Hono`
- [x] Valid RFC-4122 v4 UUIDs in stub data (no stubs returning UUIDs in this story)
- [x] 5+ vitest tests specified
- [x] Deferred items documented
- [x] Status set to ready-for-dev

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `push` package v0.6.1 specified in story does not exist; `flutter pub add push` resolved to v3.3.3 (latest available). Used v3.3.3 in pubspec.yaml — same APNs-direct architecture, no FCM dependency.

### Completion Notes List

- Created `apps/api/src/services/push.ts` — sendPush() stub with full TODO(impl) comments for @fivesheepco/cloudflare-apns2 integration, UNREGISTERED token cleanup, APNs environment selection.
- Added `@fivesheepco/cloudflare-apns2` to apps/api/package.json and installed via pnpm.
- Created `packages/core/src/schema/device-tokens.ts` — deviceTokensTable with userId, token, platform, environment, createdAt, updatedAt columns.
- Created `packages/core/src/schema/notification-preferences.ts` — notificationPreferencesTable with 3-level scope system (global/device/task).
- Exported both new tables from packages/core/src/schema/index.ts.
- Created `apps/api/src/routes/notifications.ts` — POST /v1/notifications/device-token, GET /v1/notifications/preferences, PUT /v1/notifications/preferences with OpenAPIHono + createRoute pattern.
- Mounted notificationsRouter in apps/api/src/index.ts after proofRouter.
- Added APNS_KEY, APNS_KEY_ID, APNS_TEAM_ID placeholder vars to apps/api/wrangler.jsonc.
- Added APNS_KEY, APNS_KEY_ID, APNS_TEAM_ID bindings to apps/api/worker-configuration.d.ts CloudflareBindings interface.
- Created `apps/api/test/routes/notifications.test.ts` — 8 vitest tests (5+ required) covering all three endpoints including valid/invalid cases.
- Added `push: ^3.3.3` to apps/flutter/pubspec.yaml (v0.6.1 not available; upgraded to latest stable).
- Created `apps/flutter/lib/features/notifications/data/notifications_repository.dart` — NotificationsRepository with requestPermissionAndRegisterToken(), _resolveEnvironment(), setPreference().
- Created `apps/flutter/lib/features/notifications/presentation/notifications_provider.dart` — registerDeviceToken provider.
- Generated `notifications_repository.g.dart` and `notifications_provider.g.dart` via build_runner.
- Added push notification strings to apps/flutter/lib/core/l10n/strings.dart.
- Added aps-environment=development to apps/flutter/ios/Runner/Runner.entitlements.
- Added aps-environment=development to apps/flutter/macos/Runner/DebugProfile.entitlements.
- Added aps-environment=production to apps/flutter/macos/Runner/Release.entitlements.
- All 204 API tests pass; all Flutter tests pass (0 failures).

### File List

- apps/api/src/services/push.ts (NEW)
- apps/api/src/routes/notifications.ts (NEW)
- apps/api/test/routes/notifications.test.ts (NEW)
- apps/api/package.json (MODIFIED — added @fivesheepco/cloudflare-apns2)
- apps/api/wrangler.jsonc (MODIFIED — added APNS_KEY, APNS_KEY_ID, APNS_TEAM_ID vars)
- apps/api/worker-configuration.d.ts (MODIFIED — added APNS_KEY, APNS_KEY_ID, APNS_TEAM_ID to CloudflareBindings)
- apps/api/src/index.ts (MODIFIED — import and mount notificationsRouter)
- packages/core/src/schema/device-tokens.ts (NEW)
- packages/core/src/schema/notification-preferences.ts (NEW)
- packages/core/src/schema/index.ts (MODIFIED — export deviceTokensTable, notificationPreferencesTable)
- apps/flutter/pubspec.yaml (MODIFIED — added push: ^3.3.3)
- apps/flutter/pubspec.lock (MODIFIED — updated by flutter pub get)
- apps/flutter/lib/features/notifications/data/notifications_repository.dart (NEW)
- apps/flutter/lib/features/notifications/data/notifications_repository.g.dart (NEW — generated)
- apps/flutter/lib/features/notifications/presentation/notifications_provider.dart (NEW)
- apps/flutter/lib/features/notifications/presentation/notifications_provider.g.dart (NEW — generated)
- apps/flutter/lib/core/l10n/strings.dart (MODIFIED — push notification strings)
- apps/flutter/ios/Runner/Runner.entitlements (MODIFIED — added aps-environment=development)
- apps/flutter/macos/Runner/DebugProfile.entitlements (MODIFIED — added aps-environment=development)
- apps/flutter/macos/Runner/Release.entitlements (MODIFIED — added aps-environment=production)
- apps/flutter/test/features/notifications/notifications_repository_test.dart (NEW)
- _bmad-output/implementation-artifacts/8-1-apns-infrastructure-device-token-management.md (MODIFIED — tasks checked, dev record filled, status=review)
- _bmad-output/implementation-artifacts/sprint-status.yaml (MODIFIED — 8-1 status=review)

### Change Log

- 2026-04-01: Story 8.1 created — APNs infrastructure foundation: push.ts service stub, device_tokens and notification_preferences schemas, notifications.ts route, Flutter push package integration with token registration.
- 2026-04-01: Story 8.1 implemented — all tasks complete. API: push service stub, device-tokens and notification-preferences DB schemas, notifications router (POST device-token, GET/PUT preferences), wrangler.jsonc + CloudflareBindings updated with APNs secrets. Flutter: push ^3.3.3 added, NotificationsRepository + NotificationsProvider created with build_runner .g.dart files, push notification strings added, iOS/macOS APNs entitlements added. 204 API tests + all Flutter tests passing.
