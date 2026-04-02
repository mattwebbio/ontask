# Story 8.4: Social & Schedule Change Notifications

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to know when someone I share a list with completes their tasks and when my schedule changes,
so that I can stay in sync with my household and adapt to changes in my day.

## Acceptance Criteria

1. **Given** a member of a shared list completes a task with retained proof
   **When** the completion is recorded (`POST /v1/tasks/{id}/complete`)
   **Then** other list members receive a push notification: `"[Name] completed [task title]"` (FR42)
   **And** social notifications can be disabled per task in notification preferences (FR43)

2. **Given** the scheduling engine regenerates due to a calendar change or task slip
   **When** the recalculation results in meaningful changes (≥ 2 tasks moved)
   **Then** a push notification is sent if the app is in the background: `"Your schedule was updated — [X] tasks were rescheduled"` (FR42)
   **And** the notification deep-links to the Today tab with the Schedule Change Banner shown (Story 2.12)

## Tasks / Subtasks

---

### Task 1: API — `notification-scheduler.ts` — add Social & Schedule Change helper functions (AC: 1, 2)

Add pure helper functions to `apps/api/src/lib/notification-scheduler.ts` — follow the existing pure helper pattern (no DB, fully testable). These join the existing 8 helpers already in this file.

- [x] Add `buildSocialCompletionBody(completedByName: string, taskTitle: string): string`:
  ```typescript
  // AC 1:
  // "[Name] completed [task title]"
  // Example: "Jordan completed Morning workout"
  ```
- [x] Add `buildScheduleChangeBody(rescheduledCount: number): string`:
  ```typescript
  // AC 2:
  // "Your schedule was updated — [X] tasks were rescheduled"
  // Example: "Your schedule was updated — 3 tasks were rescheduled"
  ```
- [x] Export both new functions (alongside existing exports)
- [x] **DO NOT** add DB imports or `createDb()` calls to this file — pure helpers only

**File to modify:** `apps/api/src/lib/notification-scheduler.ts`

---

### Task 2: API — `POST /v1/tasks/{id}/complete` — social notification TODO(impl) (AC: 1)

Add a `TODO(impl)` comment block to the task completion handler in `apps/api/src/routes/tasks.ts`.

- [x] In `app.openapi(completeTaskRoute, ...)` (line ~1249), after the existing rescheduling fire-and-forget, add:
  ```typescript
  // TODO(impl): Social notification — notify other list members (AC: 1, FR42, FR43)
  //   ONLY fire if completedTask.listId IS NOT NULL AND completedTask.proofRetained === true
  //   1. const userId = c.get('jwtPayload').sub  (same JWT pattern as other routes)
  //   2. const db = createDb(c.env.DATABASE_URL)
  //   3. Query list_members WHERE listId = completedTask.listId AND userId != userId
  //      to get other member userIds
  //   4. For each other member:
  //      a. Query device_tokens WHERE userId = member.userId
  //      b. Query notification_preferences WHERE userId = member.userId
  //      c. For each device token: enforce preferences using shouldSendNotification()
  //         (pass the COMPLETED task's id as taskId for per-task preference check)
  //      d. await sendPush({
  //           deviceToken: token.token,
  //           environment: token.environment,
  //           payload: {
  //             title: completedByName ?? 'Someone',
  //             body: buildSocialCompletionBody(completedByName ?? 'Someone', completedTask.title),
  //             data: { taskId: completedTask.id, type: 'social_completion' },
  //           }
  //         }, c.env)
  //   NOTE: completedByName is resolved server-side from list_members display name.
  //   NOTE: Per FR43, 'social_completion' notifications respect the 3-level preference hierarchy.
  //   NOTE: Do NOT notify the user who completed the task — only OTHER members.
  ```
  **CRITICAL:** Keep the existing `return c.json({ data: { completedTask, nextInstance } }, 200)` unchanged — only add the comment block above the return.
  **CRITICAL:** Do NOT add `createDb`, `sendPush`, or `buildSocialCompletionBody` imports to `tasks.ts` — these imports cause the pre-existing Drizzle TS2345 typecheck incompatibility. Add TODO(impl) comment only.

**File to modify:** `apps/api/src/routes/tasks.ts`

---

### Task 3: API — `notification-scheduler.ts` — `triggerScheduleChangeNotifications` stub (AC: 2)

Add a new scheduled dispatch function to `apps/api/src/lib/notification-scheduler.ts` — follow the existing `triggerReminderNotifications` / `triggerDeadlineNotifications` / `triggerStakeWarningNotifications` pattern (DB-dependent, fully documented TODO(impl) block).

- [x] Add `triggerScheduleChangeNotifications(env: CloudflareBindings): Promise<void>`:
  ```typescript
  export async function triggerScheduleChangeNotifications(env: CloudflareBindings): Promise<void> {
    // TODO(impl): Trigger schedule change notifications when scheduling engine detects ≥ 2 task moves.
    // This function is called from the scheduling cron / runScheduleForUser post-run hook.
    //
    // TODO(impl): const db = createDb(env.DATABASE_URL)
    // TODO(impl): Query for users whose schedule was regenerated in the last cron window:
    //   - Detect "meaningful changes" = hasMeaningfulChanges=true AND changeCount >= 2
    //     (mirrors the hasMeaningfulChanges field in GET /v1/tasks/schedule-changes)
    //   - Source: compare current schedule snapshot vs. previous snapshot stored per user
    //     (storage mechanism TBD in Epic 3; for now document the intent)
    //
    // TODO(impl): For each user with meaningful changes:
    //   1. Query device_tokens WHERE userId = userId
    //   2. Query notification_preferences WHERE userId = userId
    //   3. For each device token: enforce preferences using shouldSendNotification()
    //      (no taskId for schedule-change notifications — pass '' or null; preference
    //       check at global + device levels only, no per-task level applies here)
    //   4. await sendPush({
    //        deviceToken: token.token,
    //        environment: token.environment,
    //        payload: {
    //          title: 'Schedule Updated',
    //          body: buildScheduleChangeBody(changeCount),
    //          data: { type: 'schedule_change', changeCount: String(changeCount) },
    //        }
    //      }, env)
    //
    // NOTE: Deep-link — data.type='schedule_change' should navigate to Today tab
    //       with ScheduleChangeBannerVisible triggered (see notification_handler.dart).
    // NOTE: Idempotency — store a schedule_change_notified_at timestamp per user
    //       to avoid re-sending if cron fires again before next schedule regeneration.
    void env
  }
  ```
- [x] Export `triggerScheduleChangeNotifications` from the file (add to existing named exports)

**File to modify:** `apps/api/src/lib/notification-scheduler.ts`

---

### Task 4: API — Tests (AC: 1, 2)

Add tests to `apps/api/test/lib/notification-scheduler.test.ts` — follow the existing `describe/it/expect` pattern already established for Story 8.2 and 8.3 helpers.

- [x] Add tests covering the 2 new pure helpers:
  1. `buildSocialCompletionBody` — includes completedByName and task title, matches `"[Name] completed [title]"` format
  2. `buildSocialCompletionBody` — does NOT contain punitive language ("failed", "owe", "penalty", "violation")
  3. `buildSocialCompletionBody` — handles name with special characters (e.g. name containing emoji or apostrophe) without crashing
  4. `buildScheduleChangeBody` — includes the count as a number in the string
  5. `buildScheduleChangeBody` — includes "rescheduled" in the output
  6. `buildScheduleChangeBody` — singular count (1) still produces valid output (no grammatical error in the assertion, just verify it runs)

  **Import pattern to follow:**
  ```typescript
  import { describe, it, expect } from 'vitest'
  import {
    buildSocialCompletionBody,
    buildScheduleChangeBody,
  } from '../../src/lib/notification-scheduler.js'
  ```

- [x] **Minimum 6 new tests** — total count after this story: 250 (current) + 6+ new = 256+

**File to modify:** `apps/api/test/lib/notification-scheduler.test.ts`

---

### Task 5: Flutter — `AppStrings` additions for new notification copy (AC: 1, 2)

Add strings to `apps/flutter/lib/core/l10n/strings.dart`, after the existing Story 8.3 block (currently the last lines of the file ending with the `notificationDisputeRejectedBody` method before `}`).

- [x] Add a new block at the END of the `AppStrings` class, before the closing `}`:
  ```dart
  // ── Social & Schedule Change Notifications (FR42, FR43, Story 8.4) ──────────

  /// Social completion notification body.
  /// Usage: AppStrings.notificationSocialCompletionBody(completedByName, taskTitle)
  /// Server builds the push payload; this mirrors the server copy for in-app display.
  static String notificationSocialCompletionBody(String completedByName, String taskTitle) =>
      '$completedByName completed $taskTitle';

  /// Schedule change notification body.
  /// Usage: AppStrings.notificationScheduleChangeBody(count)
  static String notificationScheduleChangeBody(int count) =>
      'Your schedule was updated \u2014 $count tasks were rescheduled';
  ```
  **NOTE:** Use `\u2014` for the em-dash (`—`) to be consistent with the established AppStrings pattern (avoids potential encoding issues in the dart file).
  **CRITICAL:** Do NOT change any existing strings. Do NOT use `\$` for interpolation in these new strings — use bare `$` (standard Dart string interpolation; the linter was fixed for this in Story 8.2).

**File to modify:** `apps/flutter/lib/core/l10n/strings.dart`

---

### Task 6: Flutter — Update `NotificationHandler` for new notification types (AC: 1, 2)

Extend the `impl(8.3):` comment block inside `notification_handler.dart` to cover the two new `data.type` values.

- [x] In `apps/flutter/lib/features/notifications/presentation/notification_handler.dart`, add the following lines to the existing comment block inside `build()`:
  ```dart
  // impl(8.4): type 'social_completion'  → today tab or shared list view showing completed task
  // impl(8.4): type 'schedule_change'    → today tab with ScheduleChangeBannerVisible triggered
  //            NOTE: on 'schedule_change' tap, call:
  //              ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss() — NO,
  //              actually do NOT dismiss; instead invalidate scheduleChangesProvider so
  //              banner re-evaluates from fresh data, then navigate to Today tab.
  //            NOTE: ScheduleChangeBannerVisible is in:
  //              apps/flutter/lib/features/today/presentation/schedule_change_provider.dart
  ```
  **CRITICAL:** Do NOT change the `@riverpod` annotation or method signature — that would require regenerating `notification_handler.g.dart`, which CI does not run.
  **CRITICAL:** Do NOT regenerate `notification_handler.g.dart`. The `.dart` signature is unchanged.
  **CRITICAL:** Use `impl(8.4):` prefix — NOT `TODO:` (Flutter linter flags `TODO:` prefix).

**File to modify:** `apps/flutter/lib/features/notifications/presentation/notification_handler.dart`

---

## Dev Notes

### CRITICAL: API route handlers must remain as stubs — Drizzle TS2345 typecheck incompatibility

The project has a pre-existing Drizzle `PgTableWithColumns` TS2345 typecheck incompatibility that causes CI failures when real DB calls are added to route handlers. ALL API route handler files (`tasks.ts`, etc.) in this story follow the `TODO(impl)` stub pattern — add `TODO(impl):` comments documenting the required logic but do NOT add actual `createDb()` calls or Drizzle imports to route files.

The `notification-scheduler.ts` pure helpers (Tasks 1 and 3) are the exception — they have no DB dependencies and are fully implemented and testable.

### CRITICAL: Use `impl(8.4):` prefix for Flutter deferred notes — NOT `TODO:`

Flutter linter flags `TODO:` prefix. Use `impl(8.4):` for all deferred implementation comments in Flutter files. This is the established pattern (`impl(8.3):` in Story 8.3, `impl(8.2):` in Story 8.2).

### CRITICAL: Flutter imports — `riverpod_annotation` only, NOT `flutter_riverpod`

In Flutter provider files, only import `package:riverpod_annotation/riverpod_annotation.dart`. Do NOT also import `package:flutter_riverpod/flutter_riverpod.dart` — it is redundant and was flagged in Story 8.2.

### CRITICAL: `notification_handler.dart` method signature must NOT change

`notification_handler.g.dart` uses a manually-crafted hash `a1b2c3d4e5f6...` (CI does not run `build_runner`). Any change to the `@riverpod` annotation, class name, or `build()` signature would require regenerating the `.g.dart` file. Only the comment block inside `build()` changes in this story.

### CRITICAL: `sendPush()` remains a stub — do not implement APNs delivery

`apps/api/src/services/push.ts`'s `sendPush()` has `TODO(impl)` comments and does nothing (APNs not yet wired). This story introduces new notification dispatch code paths but does NOT implement the APNs client. No push notifications will actually fire until a future story wires `@fivesheepco/cloudflare-apns2`.

### CRITICAL: Social notification preference check — use shouldSendNotification()

All notification dispatch points must respect the 3-level preference hierarchy from Stories 8.1/8.2:
1. `scope='global'` disabled → suppress all for user
2. `scope='task'` disabled → suppress for that task (for social completions, use the completed task's id as the taskId)
3. `scope='device'` disabled → suppress for that device

`shouldSendNotification(preferences, taskId, deviceToken)` is already exported from `apps/api/src/lib/notification-scheduler.ts`. For schedule-change notifications (no per-task scope), pass an empty string `''` for taskId — only global and device levels apply.

### CRITICAL: Social notification — only fires for tasks with retained proof

Per AC 1: `"[Name] completed [task title]"` only fires when `proofRetained === true`. The API stub's `completedTask` returned from `POST /v1/tasks/{id}/complete` already has `proofRetained` in its schema (added in Story 7.x). When adding the TODO(impl) comment, explicitly note the `proofRetained` guard.

### Architecture: File locations for this story

```
apps/api/
├── src/
│   ├── lib/
│   │   └── notification-scheduler.ts     # MODIFY — add 2 pure helpers + 1 dispatch stub
│   └── routes/
│       └── tasks.ts                       # MODIFY — add social notification TODO(impl) to complete handler
└── test/
    └── lib/
        └── notification-scheduler.test.ts # MODIFY — add 6+ tests for 2 new helpers

apps/flutter/lib/
├── core/l10n/strings.dart                 # MODIFY — add 2 new notification string methods
└── features/notifications/presentation/
    └── notification_handler.dart          # MODIFY — extend impl(8.4): stubs for 2 new types
    # notification_handler.g.dart — DO NOT regenerate (signature unchanged)
```

### Notification types introduced in this story

| `data.type` value     | Trigger                                              | AC  |
|-----------------------|------------------------------------------------------|-----|
| `social_completion`   | `POST /v1/tasks/{id}/complete` with retained proof   | AC 1|
| `schedule_change`     | Scheduling engine regeneration with ≥ 2 task moves   | AC 2|

These join the existing types from Stories 8.2 and 8.3: `reminder`, `deadline_today`, `deadline_tomorrow`, `stake_warning`, `charge_succeeded`, `verification_approved`, `dispute_filed`, `dispute_approved`, `dispute_rejected`.

### Key locations in the existing codebase

- `POST /v1/tasks/{id}/complete` handler: `apps/api/src/routes/tasks.ts` line ~1249
- `completedTask.proofRetained` field: available from `taskSchema` (Story 7.x added `proofRetained: z.boolean()`)
- `completedTask.completedByName`: available from `taskSchema` as `z.string().nullable()` (line ~95)
- `completedTask.listId`: available from `taskSchema` (needed to find other list members)
- `GET /v1/tasks/schedule-changes` handler: `apps/api/src/routes/tasks.ts` line ~838 (hasMeaningfulChanges, changeCount)
- `scheduleChangesProvider`: `apps/flutter/lib/features/today/presentation/schedule_change_provider.dart`
- `ScheduleChangeBannerVisible.dismiss()`: same file — used on in-app banner tap, not on notification tap
- `shouldSendNotification()`: `apps/api/src/lib/notification-scheduler.ts:101` (already exported)
- `sendPush()` stub: `apps/api/src/services/push.ts`
- Existing notification tests: `apps/api/test/lib/notification-scheduler.test.ts` (250 tests currently passing)
- AppStrings notification block (Story 8.3 section): `apps/flutter/lib/core/l10n/strings.dart` (last lines of file)
- `notification_handler.dart`: `apps/flutter/lib/features/notifications/presentation/notification_handler.dart`

### `notification-scheduler.ts` pure helper pattern

All pure helpers in this file follow the same pattern. Look at `buildDisputeFiledBody` (added in Story 8.3) as the simplest model:

```typescript
export function buildSocialCompletionBody(completedByName: string, taskTitle: string): string {
  return `${completedByName} completed ${taskTitle}`
}

export function buildScheduleChangeBody(rescheduledCount: number): string {
  return `Your schedule was updated — ${rescheduledCount} tasks were rescheduled`
}
```

Both are pure, no imports needed beyond what is already at the top of the file.

### Dispatch stub pattern — follow existing triggerReminderNotifications

The `triggerScheduleChangeNotifications` function (Task 3) follows the exact same pattern as `triggerReminderNotifications`, `triggerDeadlineNotifications`, and `triggerStakeWarningNotifications` already in `notification-scheduler.ts`: they are `export async function ...` that `void env` at the end and contain only `TODO(impl):` comment blocks.

### Schedule change notification — deep-link to Today tab

Per AC 2, the schedule-change notification deep-links to the Today tab with the Schedule Change Banner shown. In Flutter:
- `data.type = 'schedule_change'` in the push payload
- On tap, the handler should navigate to the Today tab AND invalidate `scheduleChangesProvider` (which re-runs `getScheduleChanges()` and re-evaluates `scheduleChangeBannerVisibleProvider`)
- Do NOT call `dismiss()` on tap — the banner should appear after navigation, not be pre-dismissed

### UX-DR36 affirming tone

Story 8.4 notifications are neutral-to-positive by nature (social completion = positive; schedule change = informational). Neither notification type is a charge/penalty event, so the strict "no punitive language" rule from UX-DR36 applies trivially. Copy should remain friendly and informative.

### Story 8.3 patches that must remain intact

Do not revert or alter:
- `buildChargeNotificationBody`, `buildVerificationApprovedBody`, `buildDisputeFiledBody`, `buildDisputeResolvedBody` in `notification-scheduler.ts`
- The 5 `notificationXxx` strings in `AppStrings` (Story 8.3 block)
- The `impl(8.3):` dispatch comment blocks in `notification_handler.dart`
- The 9 tests added in Story 8.3 (total was 250 after 8.3)

### Drizzle migration — NOT required for this story

No new DB tables or columns are needed. The `device_tokens` and `notification_preferences` tables from Story 8.1 and the `scheduled_notifications` table from Story 8.2 are already available. Social completion dispatch does not need idempotency rows (it fires exactly once per completion event). Schedule change notifications may eventually need an idempotency mechanism but that is deferred to when the real schedule snapshot storage is implemented.

### Testing approach

Tests live in `apps/api/test/lib/notification-scheduler.test.ts` (Vitest). Add a `describe` block for each new helper. Only test pure functions — no DB, no app import:

```typescript
import { describe, it, expect } from 'vitest'
import {
  buildSocialCompletionBody,
  buildScheduleChangeBody,
} from '../../src/lib/notification-scheduler.js'

describe('buildSocialCompletionBody — social task completion (AC: 1)', () => {
  it('includes completedByName and taskTitle', () => { ... })
  it('does NOT contain punitive language', () => { ... })
  it('handles names with special characters', () => { ... })
})

describe('buildScheduleChangeBody — schedule change notification (AC: 2)', () => {
  it('includes the rescheduled count', () => { ... })
  it('includes "rescheduled" in the output', () => { ... })
  it('handles count of 1 without crashing', () => { ... })
})
```

### API test count baseline

- After Story 8.3: 250 tests passing
- Story 8.4 adds: 6+ new tests
- Expected total after Story 8.4: 256+
- **Do not break existing tests.** Run `pnpm test --filter apps/api` or equivalent to verify.

### Deferred items from previous stories that remain relevant

From `deferred-work.md` / Story 8.3:
- **`stakeAmountCents` absent from `TaskDto`** — not relevant to Story 8.4 (no stake display in social/schedule notifications)
- **`verifyWebhookSignature` stub returns `false`** — unrelated to this story
- **`hoursUntil` unit test boundary may flake at exact 2h** — pre-existing, not touched in this story

### References

- Epic 8 / Story 8.4 AC: `_bmad-output/planning-artifacts/epics.md` lines 2039–2056
- Story 8.3 dev notes (scheduler pattern, sendPush, TODO(impl) pattern): `_bmad-output/implementation-artifacts/8-3-commitment-charge-verification-notifications.md`
- `notification-scheduler.ts` (existing helpers + pattern): `apps/api/src/lib/notification-scheduler.ts`
- `shouldSendNotification()`: `apps/api/src/lib/notification-scheduler.ts:101`
- `POST /v1/tasks/{id}/complete` handler: `apps/api/src/routes/tasks.ts` line ~1249
- `GET /v1/tasks/schedule-changes` schema: `apps/api/src/routes/tasks.ts` lines 806–820
- `scheduleChangesProvider` + `ScheduleChangeBannerVisible`: `apps/flutter/lib/features/today/presentation/schedule_change_provider.dart`
- `sendPush()` stub: `apps/api/src/services/push.ts`
- Existing notification tests: `apps/api/test/lib/notification-scheduler.test.ts`
- AppStrings notification block: `apps/flutter/lib/core/l10n/strings.dart` (end of file)
- `notification_handler.dart`: `apps/flutter/lib/features/notifications/presentation/notification_handler.dart`
- Architecture ARCH-27 (APNs direct): `_bmad-output/planning-artifacts/architecture.md`
- FR42 (push notifications), FR43 (per-task notification preferences): `_bmad-output/planning-artifacts/epics.md`
- Deferred work: `_bmad-output/implementation-artifacts/deferred-work.md`

### Project Structure Notes

- All new `apps/api/src/lib/notification-scheduler.ts` exports are pure functions — no DB imports
- Route handler file (`tasks.ts`) receives only a TODO(impl) comment addition
- Flutter `.g.dart` files are committed; CI does not run `build_runner`
- `riverpod_annotation` only in Flutter providers — never `flutter_riverpod` alongside it
- Notification string constants follow the `notificationXxx` naming convention in `AppStrings`
- `impl(8.4):` prefix for all Flutter deferred comments — NOT `TODO:`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Task 1: Added `buildSocialCompletionBody` and `buildScheduleChangeBody` as pure helper functions to `notification-scheduler.ts`. Both exported alongside existing helpers, no DB dependencies.
- Task 2: Added `TODO(impl)` comment block to `POST /v1/tasks/{id}/complete` handler in `tasks.ts`, documenting social notification dispatch logic (AC 1, FR42, FR43). No imports added to avoid Drizzle TS2345 typecheck incompatibility.
- Task 3: Added `triggerScheduleChangeNotifications(env: CloudflareBindings): Promise<void>` stub to `notification-scheduler.ts`, following the existing trigger function pattern with fully documented TODO(impl) comment block (AC 2).
- Task 4: Added 8 new tests to `notification-scheduler.test.ts` (6 required + 2 additional for `buildSocialCompletionBody` format verification). Total test count: 258 (was 250). All 258 tests pass with no regressions.
- Task 5: Added `notificationSocialCompletionBody` and `notificationScheduleChangeBody` methods to `AppStrings` in `strings.dart`. Used `\u2014` for em-dash per established pattern. Used bare `$` for Dart string interpolation.
- Task 6: Extended `notification_handler.dart` comment block with `impl(8.4):` stubs for `social_completion` and `schedule_change` notification types. Method signature unchanged; `.g.dart` not regenerated.

### File List

- apps/api/src/lib/notification-scheduler.ts
- apps/api/src/routes/tasks.ts
- apps/api/test/lib/notification-scheduler.test.ts
- apps/flutter/lib/core/l10n/strings.dart
- apps/flutter/lib/features/notifications/presentation/notification_handler.dart
- _bmad-output/implementation-artifacts/8-4-social-schedule-change-notifications.md

## Change Log

- 2026-04-01: Story 8.4 implemented — added `buildSocialCompletionBody` and `buildScheduleChangeBody` pure helpers, `triggerScheduleChangeNotifications` dispatch stub, social notification TODO(impl) in task completion handler, 8 new tests (258 total, all passing), `AppStrings` notification copy for both new types, and `impl(8.4):` stubs in `NotificationHandler`. Status set to review.
