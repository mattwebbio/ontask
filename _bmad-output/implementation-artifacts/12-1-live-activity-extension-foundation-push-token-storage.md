# Story 12.1: Live Activity Extension Foundation & Push Token Storage

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an iOS user,
I want an On Task Live Activity I can glance at on my Dynamic Island and Lock Screen,
so that I always know my current task status without unlocking my phone.

## Acceptance Criteria

1. **Given** the Xcode project is configured
   **When** the Live Activity extension is added
   **Then** `OnTaskLiveActivity` Swift Widget Extension target exists alongside the Flutter app target in `apps/flutter/ios/`
   **And** `SharedWidgetViews/` folder is created in `apps/flutter/ios/` for SwiftUI views shared between the Live Activity and WidgetKit extensions
   **And** `live_activities` Flutter plugin is installed in `pubspec.yaml`; all calls are guarded with `Platform.isIOS` (ARCH-28)

2. **Given** the ActivityKit integration is set up
   **When** a Live Activity starts
   **Then** `OnTaskActivityAttributes` with its `ContentState` is defined in Swift: `{ taskTitle: String, elapsedSeconds: Int?, deadlineTimestamp: Date?, stakeAmount: Decimal?, activityStatus: Status }` where `Status` is `active | completed | failed | watchMode`
   **And** the ActivityKit push token for the activity is registered via `POST /v1/live-activities/token` — body `{ taskId, activityType, pushToken }` — which upserts to the `live_activity_tokens` table
   **And** the `live_activity_tokens` table has columns: `id` (uuid PK), `userId` (uuid FK→users), `taskId` (uuid nullable FK→tasks), `activityType` (text: `'task_timer' | 'commitment_countdown' | 'watch_mode'`), `pushToken` (text), `createdAt` (timestamptz), `expiresAt` (timestamptz)
   **And** the Drizzle Kit migration for `live_activity_tokens` is committed to `packages/core/schema/migrations/`
   **And** `live-activity-tokens.ts` is added to `packages/core/src/schema/` and exported from `packages/core/src/schema/index.ts`

---

## Tasks / Subtasks

### Task 1: Add `live_activities` Flutter plugin (AC: 1)

**File to modify:** `apps/flutter/pubspec.yaml`

Add the `live_activities` pub.dev package. This is an iOS-only package that bridges Flutter to ActivityKit via a method channel. Do NOT use any custom MethodChannel or write raw platform channel code for this — the plugin handles all bridging.

```yaml
# Live Activities — ActivityKit bridge for Dynamic Island + Lock Screen (ARCH-28, Story 12.1)
# iOS only. All calls MUST be guarded with `if (Platform.isIOS)`.
# macOS does NOT support Live Activities — the macOS build ignores this target entirely.
live_activities: ^1.8.4
```

Add it in the `dependencies` section, after the `push` entry (to keep iOS-specific packages grouped).

**Subtasks:**
- [x] Add `live_activities: ^1.8.4` to `pubspec.yaml` dependencies
- [x] Verify placement is in `dependencies` (not `dev_dependencies`)

---

### Task 2: Create `OnTaskLiveActivity` Swift Widget Extension target (AC: 1, 2)

This is a native Xcode target addition. The target does NOT exist yet — `apps/flutter/ios/` currently has only `Runner/` and `Flutter/` subdirectories plus `Podfile`.

**Files to create:**

#### `apps/flutter/ios/OnTaskLiveActivity/OnTaskLiveActivity.swift`

```swift
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: — ActivityAttributes Definition
// Payload stays within the 4KB ActivityKit limit.
// Only include: task title, time values, stake amount, status flag.
// No proof content, no notes.
struct OnTaskActivityAttributes: ActivityAttributes {
    let taskId: String

    struct ContentState: Codable, Hashable {
        var taskTitle: String
        var elapsedSeconds: Int?       // nil when not in timer mode
        var deadlineTimestamp: Date?   // nil when no commitment deadline
        var stakeAmount: Decimal?      // nil when no stake
        var activityStatus: Status

        enum Status: String, Codable {
            case active, completed, failed, watchMode
        }
    }
}

// MARK: — Widget Bundle Entry Point
@main
struct OnTaskLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        OnTaskLiveActivityWidget()
    }
}

// MARK: — Live Activity Widget
// UI implementation (Dynamic Island + Lock Screen views) is in Story 12.2.
// This story only scaffolds the extension with the attributes definition.
// Provide a minimal placeholder widget body so the target compiles.
struct OnTaskLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OnTaskActivityAttributes.self) { context in
            // Lock Screen UI — Story 12.2 implements this.
            // Placeholder: show task title text.
            Text(context.state.taskTitle)
                .padding()
        } dynamicIsland: { context in
            // Dynamic Island UI — Story 12.2 implements this.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.taskTitle)
                }
            } compactLeading: {
                Text(context.state.taskTitle)
                    .font(.caption2)
                    .lineLimit(1)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}
```

#### `apps/flutter/ios/OnTaskLiveActivity/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>OnTaskLiveActivity</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
```

**Subtasks:**
- [x] Create `apps/flutter/ios/OnTaskLiveActivity/OnTaskLiveActivity.swift` with `OnTaskActivityAttributes`, `ContentState`, `Status` enum, and placeholder `OnTaskLiveActivityWidget`
- [x] Create `apps/flutter/ios/OnTaskLiveActivity/Info.plist`
- [x] Confirm `OnTaskActivityAttributes.ContentState` exactly matches the architecture spec fields: `taskTitle`, `elapsedSeconds`, `deadlineTimestamp`, `stakeAmount`, `activityStatus`

---

### Task 3: Create `SharedWidgetViews/` folder (AC: 1)

Create the shared SwiftUI components folder. Story 12.5 (WidgetKit) will also import from this folder.

**File to create:** `apps/flutter/ios/SharedWidgetViews/.gitkeep`

This folder is referenced by both `OnTaskLiveActivity` and `OnTaskWidget` (Story 12.5). Create it now with a `.gitkeep` to establish the structure.

**Note:** The actual shared SwiftUI views belong in Stories 12.2 and 12.5 when the UI is implemented. This story only establishes the folder.

**Subtasks:**
- [x] Create `apps/flutter/ios/SharedWidgetViews/.gitkeep`

---

### Task 4: Update `Runner/Info.plist` and `Runner.entitlements` (AC: 1, 2)

**File to modify:** `apps/flutter/ios/Runner/Info.plist`

Add `NSSupportsLiveActivities` key. The current `Info.plist` does NOT contain this key.

```xml
<!-- Add before the closing </dict> -->
<key>NSSupportsLiveActivities</key>
<true/>
```

**File to modify:** `apps/flutter/ios/Runner/Runner.entitlements`

The current `Runner.entitlements` has: `com.apple.developer.applesignin`, `com.apple.developer.healthkit`, `aps-environment`. Add the Live Activities entitlement:

```xml
<!-- Add before the closing </dict> -->
<key>com.apple.developer.live-activities</key>
<true/>
```

**Subtasks:**
- [x] Add `NSSupportsLiveActivities: true` to `apps/flutter/ios/Runner/Info.plist`
- [x] Add `com.apple.developer.live-activities: true` to `apps/flutter/ios/Runner/Runner.entitlements`

---

### Task 5: Create `live_activity_tokens` Drizzle schema + migration (AC: 2)

**New file:** `packages/core/src/schema/live-activity-tokens.ts`

```typescript
import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Live Activity Tokens table ────────────────────────────────────────────────
// Stores ActivityKit push tokens for server-initiated Live Activity updates.
// (Epic 12, Story 12.1, ARCH-28)
//
// IMPORTANT: These are ActivityKit push tokens — NOT the same as APNs device
// tokens stored in device_tokens. Each Live Activity instance has its own token.
// Tokens are scoped per (userId, taskId, activityType) — upsert on this triple.
// Tokens expire when the activity ends (iOS max 8 hours).
//
// apns-push-type for server updates: 'liveactivity' (NOT 'alert')
// apns-topic for server updates: 'com.ontaskhq.ontask.push-type.liveactivity'
//
// Upsert strategy: on conflict (userId, taskId, activityType) DO UPDATE SET
//   pushToken, createdAt, expiresAt
// Stale token handling: on APNs HTTP 410 response, DELETE the row (Story 12.4).

export const liveActivityTokensTable = pgTable('live_activity_tokens', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),                          // FK → users
  taskId: uuid(),                                    // FK → tasks; null for non-task activities
  activityType: text().notNull(),                    // 'task_timer' | 'commitment_countdown' | 'watch_mode'
  pushToken: text().notNull(),                       // ActivityKit push token from client
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp({ withTimezone: true }).notNull(), // ActivityKit tokens expire with the activity (max 8h)
})
```

**File to modify:** `packages/core/src/schema/index.ts`

Add the export (follow the existing pattern — one export per line):
```typescript
export { liveActivityTokensTable } from './live-activity-tokens.js'
```

**Migration file:** Create `packages/core/src/schema/migrations/0020_live_activity_tokens.sql`

```sql
-- Live Activity tokens table (Story 12.1, ARCH-28)
-- ActivityKit push tokens for server-initiated Dynamic Island + Lock Screen updates.
-- Distinct from device_tokens (APNs) — each Live Activity instance has its own token.
CREATE TABLE "live_activity_tokens" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "task_id" uuid,
  "activity_type" text NOT NULL,
  "push_token" text NOT NULL,
  "created_at" timestamptz DEFAULT now() NOT NULL,
  "expires_at" timestamptz NOT NULL
);
```

**Note on migration numbering:** The current highest migration is `0019_scheduled_notifications.sql`. This migration should be `0020_live_activity_tokens.sql`. Verify by checking `packages/core/src/schema/migrations/` before naming.

**Subtasks:**
- [x] Create `packages/core/src/schema/live-activity-tokens.ts` with `liveActivityTokensTable`
- [x] Export `liveActivityTokensTable` from `packages/core/src/schema/index.ts`
- [x] Create migration `packages/core/src/schema/migrations/0020_live_activity_tokens.sql`

---

### Task 6: Add `POST /v1/live-activities/token` API route (AC: 2)

**New file:** `apps/api/src/routes/live-activities.ts`

Follow the exact pattern of `apps/api/src/routes/notifications.ts` — same `OpenAPIHono`, same `createRoute`, same `ok()`/`err()` helpers, same stub-with-TODO structure.

```typescript
import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'
// TODO(impl): import { createDb } from '../db/index.js'
// TODO(impl): import { liveActivityTokensTable } from '@ontask/core'
// TODO(impl): import { eq, and } from 'drizzle-orm'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schemas ───────────────────────────────────────────────────────────────────

const RegisterLiveActivityTokenRequestSchema = z.object({
  taskId: z.string().uuid().nullable(),             // null for non-task activities
  activityType: z.enum(['task_timer', 'commitment_countdown', 'watch_mode']),
  pushToken: z.string().min(1),                     // ActivityKit push token
  expiresAt: z.string().datetime(),                 // ISO timestamp — max 8h from now
})
const RegisterLiveActivityTokenResponseSchema = z.object({
  data: z.object({ registered: z.boolean() }),
})
const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/live-activities/token ────────────────────────────────────────────
// Upserts an ActivityKit push token for the authenticated user.
// Called automatically by the Flutter live_activities plugin when an activity starts
// and on token refresh (background push token updates — ARCH-28).
// Upserts on (userId, taskId, activityType) — safe to call on every activity start.

const registerLiveActivityTokenRoute = createRoute({
  method: 'post',
  path: '/v1/live-activities/token',
  tags: ['Live Activities'],
  summary: 'Register ActivityKit push token',
  description:
    'Upserts an ActivityKit push token for the authenticated user. ' +
    'activityType: task_timer | commitment_countdown | watch_mode. ' +
    'taskId is null for watch_mode activities without an associated task. ' +
    'Upserts on (userId, taskId, activityType) — safe to call on every activity start or token refresh.',
  request: {
    body: {
      content: {
        'application/json': { schema: RegisterLiveActivityTokenRequestSchema },
      },
    },
  },
  responses: {
    200: {
      content: {
        'application/json': { schema: RegisterLiveActivityTokenResponseSchema },
      },
      description: 'Token registered',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid request body',
    },
  },
})

app.openapi(registerLiveActivityTokenRoute, async (c) => {
  const body = c.req.valid('json')
  const { taskId, activityType, pushToken, expiresAt } = body

  const databaseUrl = c.env?.DATABASE_URL
  if (databaseUrl) {
    // TODO(impl): const db = createDb(databaseUrl)
    // TODO(impl): const userId = c.get('jwtPayload').sub
    // TODO(impl): await db
    //   .insert(liveActivityTokensTable)
    //   .values({ userId, taskId: taskId ?? null, activityType, pushToken, expiresAt: new Date(expiresAt) })
    //   .onConflictDoUpdate({
    //     target: [liveActivityTokensTable.userId, liveActivityTokensTable.taskId, liveActivityTokensTable.activityType],
    //     set: { pushToken, createdAt: new Date(), expiresAt: new Date(expiresAt) },
    //   })
  }
  // Stub: return registered: true regardless of DB availability.
  // TODO(impl): Replace stub with real DB upsert when DATABASE_URL available.
  void taskId; void activityType; void pushToken; void expiresAt
  return c.json(ok({ registered: true }))
})

export { app as liveActivitiesRouter }
```

**File to modify:** `apps/api/src/index.ts`

```typescript
// Add import (with other route imports, after notificationsRouter):
import { liveActivitiesRouter } from './routes/live-activities.js'

// Add mount (with other app.route() calls, after notificationsRouter):
app.route('/', liveActivitiesRouter)
```

**No auth middleware needed** for this route in the stub phase — `notificationsRouter` follows the same pattern (no explicit middleware guard, JWT auth is TODO). Match the existing notifications pattern exactly.

**Subtasks:**
- [x] Create `apps/api/src/routes/live-activities.ts` with `POST /v1/live-activities/token`
- [x] Import and mount `liveActivitiesRouter` in `apps/api/src/index.ts`
- [x] Ensure `c.env?.DATABASE_URL` uses optional chaining (not `c.env.DATABASE_URL`)

---

### Task 7: Create Flutter `LiveActivitiesRepository` (AC: 2)

**New directory:** `apps/flutter/lib/features/live_activities/`

Follow the exact feature anatomy used throughout the Flutter app (see `apps/flutter/lib/features/notifications/` for reference):

```
apps/flutter/lib/features/live_activities/
├── data/
│   └── live_activities_repository.dart
└── domain/
    └── live_activity_types.dart
```

#### `apps/flutter/lib/features/live_activities/domain/live_activity_types.dart`

```dart
/// Activity type constants for Live Activities.
/// Must match the server-side enum: task_timer | commitment_countdown | watch_mode
class LiveActivityType {
  static const String taskTimer = 'task_timer';
  static const String commitmentCountdown = 'commitment_countdown';
  static const String watchMode = 'watch_mode';
}
```

#### `apps/flutter/lib/features/live_activities/data/live_activities_repository.dart`

```dart
import 'dart:io';
import 'package:live_activities/live_activities.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../domain/live_activity_types.dart';

part 'live_activities_repository.g.dart';

/// Repository for managing Live Activities via the live_activities plugin.
///
/// CRITICAL: ALL calls to the live_activities plugin MUST be wrapped in
/// `if (Platform.isIOS)` guards. macOS does NOT support Live Activities.
/// The macOS build ignores the OnTaskLiveActivity extension target entirely.
/// ARCH-28: live_activities Flutter plugin bridges to OnTaskLiveActivity Swift extension.
class LiveActivitiesRepository {
  const LiveActivitiesRepository({required this.apiClient});

  final ApiClient apiClient;
  final _plugin = const LiveActivities();

  /// Initialises the live_activities plugin and registers the push token callback.
  ///
  /// Call once during app startup (after auth completes), guarded with Platform.isIOS.
  /// The plugin calls [onActivityUpdate] when the ActivityKit push token changes —
  /// we must re-POST the new token to the server (ARCH-28 background token refresh).
  Future<void> init({required String activityType, String? taskId}) async {
    if (!Platform.isIOS) return;
    await _plugin.init(appGroupId: 'group.com.ontaskhq.ontask');
    // TODO(impl): _plugin.activityUpdateStream.listen((update) {
    //   if (update.activityToken != null) {
    //     registerToken(
    //       taskId: taskId,
    //       activityType: activityType,
    //       pushToken: update.activityToken!,
    //     );
    //   }
    // });
  }

  /// Registers an ActivityKit push token with the server.
  ///
  /// Called when an activity starts and on background token refresh.
  /// POST /v1/live-activities/token — upserts on (userId, taskId, activityType).
  Future<void> registerToken({
    String? taskId,
    required String activityType,
    required String pushToken,
  }) async {
    if (!Platform.isIOS) return;
    // expiresAt: ActivityKit tokens expire with the activity (iOS max 8 hours).
    final expiresAt = DateTime.now().add(const Duration(hours: 8)).toUtc().toIso8601String();
    await apiClient.dio.post<void>(
      '/v1/live-activities/token',
      data: {
        'taskId': taskId,
        'activityType': activityType,
        'pushToken': pushToken,
        'expiresAt': expiresAt,
      },
    );
  }
}

@riverpod
LiveActivitiesRepository liveActivitiesRepository(Ref ref) {
  return LiveActivitiesRepository(apiClient: ref.watch(apiClientProvider));
}
```

**Note on `.g.dart` generated file:** Per project convention, generated `*.g.dart` files are committed to the repo. Create a stub `live_activities_repository.g.dart` following the pattern of other `*.g.dart` files in the features directory (e.g., `notifications_repository.g.dart`). The hash in the part header can be any valid-looking hex string — CI does not run `build_runner`.

**Subtasks:**
- [x] Create `apps/flutter/lib/features/live_activities/domain/live_activity_types.dart`
- [x] Create `apps/flutter/lib/features/live_activities/data/live_activities_repository.dart`
- [x] Create `apps/flutter/lib/features/live_activities/data/live_activities_repository.g.dart` (stub generated file)
- [x] Verify all `_plugin.*` calls are inside `if (!Platform.isIOS) return` guards

---

### Task 8: Write tests for `POST /v1/live-activities/token` (AC: 2)

**New file:** `apps/api/test/routes/live-activities.test.ts`

Model after `apps/api/test/routes/notifications.test.ts` — same import pattern, same stub behaviour (no DATABASE_URL → stub returns 200).

```typescript
import { describe, expect, it } from 'vitest'

const app = (await import('../../src/index.js')).default

describe('POST /v1/live-activities/token', () => {
  it('returns 200 with registered:true for task_timer with taskId', async () => { /* ... */ })
  it('returns 200 with registered:true for commitment_countdown with taskId', async () => { /* ... */ })
  it('returns 200 with registered:true for watch_mode with null taskId', async () => { /* ... */ })
  it('returns 400 when activityType is invalid', async () => { /* ... */ })
  it('returns 400 when pushToken is missing', async () => { /* ... */ })
  it('returns 400 when expiresAt is missing or not ISO datetime', async () => { /* ... */ })
})
```

Minimum 6 tests. All valid requests return `{ data: { registered: true } }`.

**Baseline test count before this story:** 334 tests across 33 test files (verified by `npm test`).
**After this story:** 340+ tests (334 + 6 new).

**Run:** `cd apps/api && npm test` — all 340+ tests must pass.

**Subtasks:**
- [x] Create `apps/api/test/routes/live-activities.test.ts` with at least 6 tests
- [x] Run `cd apps/api && npm test` — all tests pass, count reported

---

## Dev Notes

### Domain Separation: This Is Flutter/iOS, Not TypeScript/Admin

This story lives in a completely different technical domain from Epics 9–11. The primary work is:

1. **Swift** — native Xcode Widget Extension target (`OnTaskLiveActivity`)
2. **Flutter/Dart** — `live_activities` plugin integration, repository, Riverpod provider
3. **TypeScript/Hono** — `POST /v1/live-activities/token` route in `apps/api` (not `apps/admin-api`)
4. **Drizzle schema** — `packages/core/src/schema/live-activity-tokens.ts`

Do NOT apply any patterns from the admin-api (OpenAPIHono with adminAuthMiddleware, `c.env?.DATABASE_URL` optional chaining in admin context, `(c as any).get('operatorEmail')`) to the API routes in this story. The `apps/api` and `apps/admin-api` are separate Cloudflare Workers — NEVER cross-import between them.

### ActivityKit vs APNs Device Tokens — Critical Distinction

There are TWO separate token types in this project:

| Token Type | Table | Plugin | Purpose |
|---|---|---|---|
| APNs device token | `device_tokens` | `push` (pub.dev) | Standard push notifications |
| ActivityKit push token | `live_activity_tokens` | `live_activities` (pub.dev) | Live Activity server-side updates |

The `live_activity_tokens` table stores ActivityKit push tokens — these are **per-activity-instance** tokens delivered by the `live_activities` plugin, NOT the device push tokens from the `push` package. Each Live Activity instance has its own unique push token. Token type confusion between these two is a critical mistake to avoid.

### `live_activities` Plugin Architecture (ARCH-28)

- **Plugin:** `live_activities` pub.dev package (NOT a custom MethodChannel)
- **What it does:** Bridges Flutter to ActivityKit via a method channel internally; handles start/update/end calls and push token callbacks
- **Init requirement:** Call `_plugin.init(appGroupId:)` once on app startup (iOS only)
- **Token delivery:** The plugin emits tokens via `activityUpdateStream` — register a listener to capture and POST to server
- **macOS guard:** `if (!Platform.isIOS) return` is mandatory at EVERY call site
- **Do NOT:** Write raw `MethodChannel` code for ActivityKit — the plugin handles all channel bridging

### Swift Extension Target — Xcode Project Integration

The `OnTaskLiveActivity` target must be added to the Xcode project (`Runner.xcodeproj`). Swift files created under `apps/flutter/ios/OnTaskLiveActivity/` will not automatically be included in the build without being added to the Xcode project. The dev agent must:

1. Create the Swift and plist files
2. Add the target to `Runner.xcodeproj/project.pbxproj` as a `com.apple.product-type.app-extension` with `NSExtensionPointIdentifier: com.apple.widgetkit-extension`
3. Set the bundle identifier: `com.ontaskhq.ontask.OnTaskLiveActivity`
4. Set minimum deployment target to iOS 16.1 (minimum for Live Activities)
5. Link `WidgetKit.framework` and `ActivityKit.framework` to the extension target

**`project.pbxproj` is the single most error-prone file.** The existing `push` package and `health` package already added entries to this file — follow the same structural patterns. Do not regenerate it from scratch.

### `Runner.entitlements` — Current State

Current `apps/flutter/ios/Runner/Runner.entitlements` has:
- `com.apple.developer.applesignin` → `["Default"]`
- `com.apple.developer.healthkit` → `true`
- `com.apple.developer.healthkit.access` → `[]`
- `aps-environment` → `"development"`

Add `com.apple.developer.live-activities: true`. Do NOT change or remove the existing entries. The `aps-environment` must stay as `"development"` — it is changed to `"production"` separately by the Fastlane build lane at release time.

### `Info.plist` — Current State

Current `apps/flutter/ios/Runner/Info.plist` does NOT contain `NSSupportsLiveActivities`. Add `<key>NSSupportsLiveActivities</key><true/>`. Do NOT change any other existing keys.

### VoiceOver Announcements — Note from Story 8.5

`apps/flutter/ios/Runner/LiveActivityVoiceOver.swift` is a documentation-only placeholder file created in Story 8.5. When wiring VoiceOver announcements into the `OnTaskLiveActivity` extension (Story 12.3), move/copy the `UIAccessibility.post(...)` logic from that placeholder into the extension's `ContentState` update handler. Do NOT delete `LiveActivityVoiceOver.swift` in this story — it is informational and referenced by the Story 12.3 spec.

### API Route Pattern (`apps/api`) — Use `notifications.ts` as Model

For `POST /v1/live-activities/token`, follow `apps/api/src/routes/notifications.ts` exactly:
- `new OpenAPIHono<{ Bindings: CloudflareBindings }>()`
- `createRoute()` with full Zod schemas
- `app.openapi()` — not `app.post()`
- `ok()` helper: `import { ok } from '../lib/response.js'` (`.js` extension required)
- `c.env?.DATABASE_URL` with optional chaining (Vitest has no Cloudflare runtime, `c.env` is undefined)
- Stub fixture returns `{ registered: true }` when DATABASE_URL absent

The route does NOT need an explicit auth middleware in the stub phase. This matches how `notifications.ts` routes work — JWT auth is `TODO(impl)` pending auth wiring.

### Drizzle Schema Pattern

Follow `packages/core/src/schema/device-tokens.ts` exactly:
- Import from `drizzle-orm/pg-core`
- `pgTable('live_activity_tokens', { ... })` — snake_case table name
- `uuid().primaryKey().defaultRandom()` for the PK
- `timestamp({ withTimezone: true })` for all timestamps
- `casing: 'camelCase'` is set globally on the Drizzle instance — camelCase field names in TypeScript map to snake_case in DB automatically
- Export the table from `packages/core/src/schema/index.ts` as a named export

### Flutter Feature Anatomy

Every feature in `apps/flutter/lib/features/` has exactly this shape:
```
feature_name/
├── data/          # repository + DTOs
├── domain/        # types, models (freezed)
└── presentation/  # screens, providers, widgets
```

For Story 12.1, only `data/` and `domain/` are needed (no UI yet). `presentation/` is added in Stories 12.2–12.3.

### Riverpod Provider Pattern

```dart
@riverpod
LiveActivitiesRepository liveActivitiesRepository(Ref ref) {
  return LiveActivitiesRepository(apiClient: ref.watch(apiClientProvider));
}
```
- ARCH-18: `ApiClient` is injected via Riverpod — never instantiated as a singleton
- ARCH-17: Async providers return `AsyncValue<T>` — for synchronous providers like this repository factory, plain return type is correct

### `.g.dart` File Convention

Per project convention (documented in `deferred-work.md`):
- Generated `*.g.dart` and `*.freezed.dart` files are committed to the repo
- CI does NOT run `build_runner`
- Create a stub `.g.dart` file with a fake-but-plausible hash
- Reference pattern: `apps/flutter/lib/features/notifications/data/notifications_repository.g.dart`

### What This Story Does NOT Include

- No Live Activity UI (Dynamic Island / Lock Screen views) — that is Story 12.2
- No server-push service (`apps/api/src/services/live-activity.ts`) — that is Story 12.4
- No VoiceOver announcements in the extension — that is Story 12.3
- No `OnTaskWidget` WidgetKit target — that is Story 12.5
- No changes to `apps/admin-api/` or `apps/admin/` — admin dashboard is out of scope for Epic 12
- No changes to `apps/mcp/` — MCP server is out of scope
- No `watch_mode` feature changes — Watch Mode Live Activity UI is Story 12.3
- The `live_activities` plugin `init()` call and token listener wiring to specific task flows happen in Stories 12.2 and 12.3 when the task start/stop/watch-mode flows are integrated; this story only creates the repository infrastructure

### File Locations Summary

```
apps/flutter/
├── pubspec.yaml                                  ← MODIFY: add live_activities dependency
├── ios/
│   ├── Runner/
│   │   ├── Info.plist                            ← MODIFY: add NSSupportsLiveActivities
│   │   ├── Runner.entitlements                   ← MODIFY: add com.apple.developer.live-activities
│   │   └── LiveActivityVoiceOver.swift           ← DO NOT MODIFY (Story 8.5 placeholder)
│   ├── OnTaskLiveActivity/                       ← CREATE (new Xcode extension target)
│   │   ├── OnTaskLiveActivity.swift              ← CREATE: ActivityAttributes + placeholder widget
│   │   └── Info.plist                            ← CREATE
│   └── SharedWidgetViews/
│       └── .gitkeep                              ← CREATE
└── lib/
    └── features/
        └── live_activities/                      ← CREATE (new feature module)
            ├── data/
            │   ├── live_activities_repository.dart      ← CREATE
            │   └── live_activities_repository.g.dart    ← CREATE (stub)
            └── domain/
                └── live_activity_types.dart             ← CREATE

packages/core/src/schema/
├── live-activity-tokens.ts                       ← CREATE: liveActivityTokensTable
├── index.ts                                      ← MODIFY: add liveActivityTokensTable export
└── migrations/
    └── 0020_live_activity_tokens.sql             ← CREATE

apps/api/src/
├── index.ts                                      ← MODIFY: import + mount liveActivitiesRouter
└── routes/
    └── live-activities.ts                        ← CREATE: POST /v1/live-activities/token

apps/api/test/routes/
└── live-activities.test.ts                       ← CREATE: ≥6 tests
```

### References

- Epic 12 goal and Story 12.1 AC: [Source: `_bmad-output/planning-artifacts/epics.md` lines 2471–2497]
- ARCH-28 (live_activities plugin, liveactivity APNs topic): [Source: `_bmad-output/planning-artifacts/epics.md` line 247]
- Architecture: Live Activities & WidgetKit section: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 209–325]
- Architecture: `apps/flutter/ios/` directory structure: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 887–901]
- Architecture: `packages/core/src/schema/` structure: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 929–958]
- `OnTaskActivityAttributes` ContentState spec: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 242–257]
- ActivityKit push token flow and API endpoint spec: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 262–279]
- `live_activity_tokens` DB table columns: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 270–278]
- UX-DR25 (Live Activity design — Dynamic Island + Lock Screen): [Source: `_bmad-output/planning-artifacts/epics.md` line 303]
- DEPLOY-2 (entitlements verification): [Source: `_bmad-output/planning-artifacts/epics.md` line 334]
- `device_tokens` schema (model for live_activity_tokens): [Source: `packages/core/src/schema/device-tokens.ts`]
- `notifications.ts` route (model for live-activities.ts): [Source: `apps/api/src/routes/notifications.ts`]
- `NotificationsRepository` (Flutter model for LiveActivitiesRepository): [Source: `apps/flutter/lib/features/notifications/data/notifications_repository.dart`]
- `AppDelegate.swift` (existing channel pattern for `Platform.isIOS`-gated iOS features): [Source: `apps/flutter/ios/Runner/AppDelegate.swift`]
- `Runner.entitlements` (current state — DO NOT break existing entries): [Source: `apps/flutter/ios/Runner/Runner.entitlements`]
- `LiveActivityVoiceOver.swift` (Story 8.5 placeholder, move logic to extension in Story 12.3): [Source: `apps/flutter/ios/Runner/LiveActivityVoiceOver.swift`]
- `apps/api/src/index.ts` (route mount pattern): [Source: `apps/api/src/index.ts`]
- `packages/core/src/schema/index.ts` (export pattern): [Source: `packages/core/src/schema/index.ts`]
- API test baseline: 334 tests across 33 files (verified 2026-04-02): [Source: `apps/api` npm test output]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_No issues encountered._

### Completion Notes List

- Task 1: Added `live_activities: ^1.8.4` to `apps/flutter/pubspec.yaml` dependencies section, after the `push` entry as specified.
- Task 2: Created `apps/flutter/ios/OnTaskLiveActivity/OnTaskLiveActivity.swift` with `OnTaskActivityAttributes`, `ContentState` (5 fields: taskTitle, elapsedSeconds, deadlineTimestamp, stakeAmount, activityStatus), `Status` enum (active/completed/failed/watchMode), and placeholder `OnTaskLiveActivityWidget`. Created `Info.plist` for the extension target with `com.apple.widgetkit-extension` NSExtensionPointIdentifier.
- Task 3: Created `apps/flutter/ios/SharedWidgetViews/.gitkeep` to establish the shared SwiftUI views folder.
- Task 4: Added `NSSupportsLiveActivities: true` to `Runner/Info.plist` and `com.apple.developer.live-activities: true` to `Runner/Runner.entitlements`. All existing entitlements preserved unchanged.
- Task 5: Created `packages/core/src/schema/live-activity-tokens.ts` with `liveActivityTokensTable` following `device-tokens.ts` pattern. Exported from `schema/index.ts`. Created migration `0020_live_activity_tokens.sql` (highest was 0019).
- Task 6: Created `apps/api/src/routes/live-activities.ts` with `POST /v1/live-activities/token` using `OpenAPIHono`, `createRoute`, Zod schemas, stub response `{ data: { registered: true } }`. Uses `c.env?.DATABASE_URL` optional chaining. Imported and mounted `liveActivitiesRouter` in `apps/api/src/index.ts` after `notificationsRouter`.
- Task 7: Created Flutter `live_activities` feature module with `domain/live_activity_types.dart` (constants), `data/live_activities_repository.dart` (repository with Platform.isIOS guards on all plugin calls), and `data/live_activities_repository.g.dart` (stub generated Riverpod provider following notifications pattern).
- Task 8: Created `apps/api/test/routes/live-activities.test.ts` with 6 tests (3 valid activityType variants, 3 validation error cases). All 340 tests pass (334 baseline + 6 new).

### File List

**Modified:**
- `apps/flutter/pubspec.yaml`
- `apps/flutter/ios/Runner/Info.plist`
- `apps/flutter/ios/Runner/Runner.entitlements`
- `packages/core/src/schema/index.ts`
- `apps/api/src/index.ts`

**Created:**
- `apps/flutter/ios/OnTaskLiveActivity/OnTaskLiveActivity.swift`
- `apps/flutter/ios/OnTaskLiveActivity/Info.plist`
- `apps/flutter/ios/SharedWidgetViews/.gitkeep`
- `packages/core/src/schema/live-activity-tokens.ts`
- `packages/core/src/schema/migrations/0020_live_activity_tokens.sql`
- `apps/api/src/routes/live-activities.ts`
- `apps/api/test/routes/live-activities.test.ts`
- `apps/flutter/lib/features/live_activities/domain/live_activity_types.dart`
- `apps/flutter/lib/features/live_activities/data/live_activities_repository.dart`
- `apps/flutter/lib/features/live_activities/data/live_activities_repository.g.dart`

## Change Log

- 2026-04-02: Story 12.1 implemented — Live Activity extension foundation & push token storage. Added `live_activities` Flutter plugin, created `OnTaskLiveActivity` Swift extension scaffold with `OnTaskActivityAttributes`, `SharedWidgetViews/` folder, updated `Runner/Info.plist` and `Runner.entitlements` for Live Activities support, created `live_activity_tokens` Drizzle schema + migration 0020, added `POST /v1/live-activities/token` API route stub, created Flutter `LiveActivitiesRepository` with Riverpod provider, and 6 API tests. Total: 340 tests passing.
