# Story 8.3: Commitment, Charge & Verification Notifications

Status: review

## Story

As a user,
I want to be notified immediately when charges, verifications, and disputes change status,
so that I always know the financial state of my commitments without having to check.

## Acceptance Criteria

1. **Given** a charge is successfully processed
   **When** the Stripe `payment_intent.succeeded` webhook is received and processed
   **Then** the user receives a push notification: `"[Task title] — $[amount] charged. [Charity] receives $[amount/2]. Thanks for trying."` (FR42)
   **And** copy is affirming even for a charge — no punitive language (UX-DR36)

2. **Given** a proof verification completes successfully (stake cancelled)
   **When** the verification result is processed (proof accepted)
   **Then** the user receives a push notification: `"[Task title] — proof accepted. Your $[amount] stake is safe."` (FR42)

3. **Given** a dispute is filed by the user
   **When** `POST /v1/tasks/{taskId}/disputes` confirms the dispute server-side
   **Then** the user receives a push notification confirming the dispute and that the stake is on hold

4. **Given** a dispute is resolved by an operator
   **When** the resolution is recorded (approved or rejected)
   **Then** the user receives a push notification with the outcome:
   - Approved: stake cancelled — affirming message
   - Rejected: charge processed — affirming, non-punitive message (UX-DR36)
   (FR42, Story 7.9)

## Tasks / Subtasks

---

### Task 1: API — Stripe webhook `payment_intent.succeeded` → push notification (AC: 1)

Add notification dispatch inside the existing Stripe webhook handler in `apps/api/src/routes/commitment-contracts.ts`.

- [x] Implement the `TODO(impl)` in `POST /v1/webhooks/stripe` — replace `void event` with event-type dispatch:
  ```typescript
  // Step 5: Handle event types
  if (event.type === 'payment_intent.succeeded') {
    // TODO(impl): Extract taskId, userId, amountCents, charityName from event.data.object.metadata
    // TODO(impl): const db = createDb(c.env.DATABASE_URL)
    // TODO(impl): Query charge_events WHERE stripePaymentIntentId = event.data.object.id LIMIT 1
    //             to retrieve charityName and charityAmountCents
    // TODO(impl): Query device_tokens WHERE userId = userId
    // TODO(impl): For each device token:
    //   1. Enforce preferences (global → task → device) using shouldSendNotification()
    //   2. await sendPush({
    //        deviceToken: token.token,
    //        environment: token.environment,
    //        payload: {
    //          title: taskTitle,
    //          body: buildChargeNotificationBody(taskTitle, amountCents, charityName, charityAmountCents),
    //          data: { taskId, type: 'charge_succeeded' },
    //        }
    //      }, c.env)
  }
  if (event.type === 'payment_intent.payment_failed') {
    // TODO(impl): update charge_events.status = 'failed', store stripeError
    // Notification for payment failure is NOT spec'd — do not add one
  }
  ```
  **CRITICAL:** Keep the `return c.json({ received: true }, 200)` at the end — must respond within 30s (NFR-I4).
  **CRITICAL:** `verifyWebhookSignature` is a stub returning `false` — the webhook handler currently returns 400 for ALL webhooks. Do NOT change this behaviour; keep the TODO(impl) guard in place. The notification stub inside is still wired correctly behind the guard.
  **CRITICAL:** Import `sendPush` from `'../services/push.js'`, `shouldSendNotification` and `buildChargeNotificationBody` from `'../lib/notification-scheduler.js'` (add new helper there — see Task 2).

---

### Task 2: API — `notification-scheduler.ts` — add Event-triggered notification helpers (AC: 1, 2, 3, 4)

Add pure helper functions to `apps/api/src/lib/notification-scheduler.ts` — follow the existing helper pattern (no DB, fully testable).

- [x] Add `buildChargeNotificationBody(taskTitle: string, amountCents: number, charityName: string, charityAmountCents: number): string`:
  ```typescript
  // AC 1 (UX-DR36 — affirming, not punitive):
  // "[Task title] — $[amount] charged. [Charity] receives $[charity amount]. Thanks for trying."
  // Example: "Complete report — $20 charged. Red Cross receives $10. Thanks for trying."
  ```
- [x] Add `buildVerificationApprovedBody(taskTitle: string, amountCents: number): string`:
  ```typescript
  // AC 2:
  // "[Task title] — proof accepted. Your $[amount] stake is safe."
  ```
- [x] Add `buildDisputeFiledBody(taskTitle: string): string`:
  ```typescript
  // AC 3:
  // "[Task title] — dispute filed. Your stake is on hold while we review."
  ```
- [x] Add `buildDisputeResolvedBody(taskTitle: string, approved: boolean, amountCents: number, charityName: string, charityAmountCents: number): string`:
  ```typescript
  // AC 4 — affirming in both outcomes (UX-DR36):
  // approved:  "[Task title] — dispute approved. Your $[amount] stake has been cancelled."
  // rejected:  "[Task title] — dispute reviewed. $[amount] charged. [Charity] receives $[charity amount]. Thanks for trying."
  ```
- [x] Export all four new functions (alongside the existing exports)

---

### Task 3: API — Proof verification → push notification (AC: 2)

Add notification dispatch to the proof submission handler in `apps/api/src/routes/proof.ts`.

- [x] In the `POST /v1/tasks/{taskId}/proof` handler, add after the stub verification result:
  ```typescript
  // TODO(impl): When verified=true AND task has stakeAmountCents:
  //   1. const userId = c.get('jwtPayload').sub (same JWT pattern as other routes)
  //   2. const db = createDb(c.env.DATABASE_URL)
  //   3. Query tasks WHERE id = taskId to get title, stakeAmountCents
  //   4. If stakeAmountCents IS NOT NULL: cancel the stake
  //      - Update tasks.stakeAmountCents = null (or commitment_contracts.status = 'cancelled')
  //   5. Query device_tokens WHERE userId = userId
  //   6. For each token: enforce preferences + call sendPush({
  //        payload: {
  //          title: task.title,
  //          body: buildVerificationApprovedBody(task.title, task.stakeAmountCents),
  //          data: { taskId, type: 'verification_approved' },
  //        }
  //      }, c.env)
  //
  // NOTE: When verified=false (rejection), Story 8.3 does NOT send a push here.
  //       The user already sees the rejection in-app. Notification on rejection
  //       is only triggered after dispute resolution (AC 4).
  ```
  **CRITICAL:** The proof endpoint is a stub — keep the stub response. Only add the TODO(impl) comment block.
  **CRITICAL:** Do NOT import `createDb` or `shouldSendNotification` in proof.ts right now — these imports cause the pre-existing Drizzle TS2345 typecheck incompatibility. Add only the TODO(impl) comment. The actual wiring is deferred per the API stub pattern.

---

### Task 4: API — Dispute filed → push notification (AC: 3)

Add notification dispatch to the dispute filing handler in `apps/api/src/routes/proof.ts`.

- [x] In the `POST /v1/tasks/{taskId}/disputes` handler, add after the TODO(impl) block:
  ```typescript
  // TODO(impl): After inserting the dispute row and placing stake on hold:
  //   1. const userId = c.get('jwtPayload').sub
  //   2. Query device_tokens WHERE userId = userId
  //   3. Enforce preferences + for each token: call sendPush({
  //        payload: {
  //          title: taskTitle,
  //          body: buildDisputeFiledBody(taskTitle),
  //          data: { taskId, type: 'dispute_filed' },
  //        }
  //      }, c.env)
  ```
  **CRITICAL:** Same stub pattern — add TODO(impl) comment only, keep existing `return c.json(ok({...}), 201)` unchanged.

---

### Task 5: API — Dispute resolved → push notification (AC: 4)

The admin-api resolves disputes in `apps/admin-api/`. Story 7.9 added a dispute resolution endpoint there. Add the notification dispatch TODO there.

- [x] Find the dispute resolution endpoint in `apps/admin-api/src/` (look for `disputes.ts` or similar — Story 7.9 work):
  ```typescript
  // TODO(impl): After updating verification_disputes.status = 'approved'|'rejected':
  //   1. Look up the original dispute to get taskId, userId, stakeAmountCents, charityName
  //   2. Query device_tokens in main DB for userId
  //   3. For each token: call sendPush({
  //        payload: {
  //          title: task.title,
  //          body: buildDisputeResolvedBody(task.title, approved, amountCents, charityName, charityAmountCents),
  //          data: { taskId, type: approved ? 'dispute_approved' : 'dispute_rejected' },
  //        }
  //      }, env)
  //
  // NOTE: admin-api is a SEPARATE Cloudflare Worker (apps/admin-api/). It has its own
  //   wrangler config and does NOT import from apps/api/src/. Import sendPush from
  //   its own local copy or create apps/admin-api/src/services/push.ts mirroring
  //   the main API's push.ts (same TODO(impl) stub pattern).
  //   Import buildDisputeResolvedBody from a shared location or duplicate the pure helper.
  ```
  **CRITICAL:** admin-api is separate from apps/api — it cannot import from `apps/api/src/`. Either duplicate the `buildDisputeResolvedBody` helper or reference `notification-scheduler.ts` patterns.

---

### Task 6: API — Tests (AC: 1, 2, 3, 4)

- [x] Add tests to `apps/api/test/lib/notification-scheduler.test.ts` — follow existing describe/it pattern:
  - **Minimum 8 new tests covering the 4 new helpers:**
    1. `buildChargeNotificationBody` — includes task title, formatted charge amount, charity name, charity amount, "Thanks for trying"
    2. `buildChargeNotificationBody` — does NOT contain punitive language ("failed", "owe", "penalty")
    3. `buildVerificationApprovedBody` — includes task title, stake amount, "stake is safe"
    4. `buildVerificationApprovedBody` — does NOT contain punitive language
    5. `buildDisputeFiledBody` — includes task title, "dispute filed", "on hold"
    6. `buildDisputeResolvedBody` (approved=true) — includes task title, "cancelled", stake amount
    7. `buildDisputeResolvedBody` (approved=false) — includes task title, charge amount, charity name, "Thanks for trying"
    8. `buildDisputeResolvedBody` (approved=false) — does NOT contain punitive language
  - Total test count after this story: 242 (existing) + 8+ new = 250+

---

### Task 7: Flutter — `AppStrings` additions for notification copy (AC: 1, 2, 3, 4)

- [x] Add strings to `apps/flutter/lib/core/l10n/strings.dart`, after the existing Story 8.2 block (currently line 1197–1215):
  ```dart
  // ── Commitment, Charge & Verification Notifications (FR42, Story 8.3) ────────

  /// Charge notification body (UX-DR36 — affirming, not punitive).
  /// Usage: '${task.title} — ${AppStrings.notificationChargeBody(amount, charityName, charityAmount)}'
  static String notificationChargeBody(String amount, String charityName, String charityAmount) =>
      '— $amount charged. $charityName receives $charityAmount. Thanks for trying.';

  /// Verification approved notification body.
  /// Usage: '${task.title} ${AppStrings.notificationVerificationApprovedBody(amount)}'
  static String notificationVerificationApprovedBody(String amount) =>
      '— proof accepted. Your $amount stake is safe.';

  /// Dispute filed notification body.
  /// Usage: '${task.title} ${AppStrings.notificationDisputeFiledBody}'
  static const String notificationDisputeFiledBody =
      '— dispute filed. Your stake is on hold while we review.';

  /// Dispute approved notification body (stake cancelled).
  /// Usage: '${task.title} ${AppStrings.notificationDisputeApprovedBody(amount)}'
  static String notificationDisputeApprovedBody(String amount) =>
      '— dispute approved. Your $amount stake has been cancelled.';

  /// Dispute rejected notification body (charge processed, affirming).
  /// Usage: '${task.title} ${AppStrings.notificationDisputeRejectedBody(amount, charityName, charityAmount)}'
  static String notificationDisputeRejectedBody(String amount, String charityName, String charityAmount) =>
      '— dispute reviewed. $amount charged. $charityName receives $charityAmount. Thanks for trying.';
  ```

---

### Task 8: Flutter — Update `NotificationHandler` for new notification types (AC: 1, 2, 3, 4)

- [x] Update `apps/flutter/lib/features/notifications/presentation/notification_handler.dart` — extend the existing `impl(8.3):` stubs to cover new `type` values:
  ```dart
  // impl(8.3): subscribe to Push.instance.onNotificationTap
  // impl(8.3): on tap, extract data['taskId'] and data['type']
  // impl(8.3): use GoRouter or Navigator to push task detail route
  // impl(8.3): type 'stake_warning'     → task detail with stake section visible
  // impl(8.3): type 'charge_succeeded'  → task detail (show billing history or task card)
  // impl(8.3): type 'verification_approved' → task detail (proof accepted state)
  // impl(8.3): type 'dispute_filed'     → task detail (dispute pending state)
  // impl(8.3): type 'dispute_approved'  → task detail (stake cancelled state)
  // impl(8.3): type 'dispute_rejected'  → task detail or billing history
  ```
  **NOTE:** `notification_handler.g.dart` does NOT need regeneration — the `.dart` file signature is unchanged. Only the comment block inside `build()` changes.
  **CRITICAL:** Do NOT change the `@riverpod` annotation or method signature — that would require regenerating the `.g.dart` file, which the CI does not run.

---

## Dev Notes

### CRITICAL: API handlers must remain as stubs — Drizzle TS2345 typecheck incompatibility

The project has a pre-existing Drizzle `PgTableWithColumns` TS2345 typecheck incompatibility that causes CI failures when real DB calls are added to route handlers. All API route handlers in this story follow the `TODO(impl)` stub pattern — add `TODO(impl):` comments documenting the required logic but do NOT add actual `createDb()` calls or Drizzle imports to route files.

The `notification-scheduler.ts` pure helpers (Task 2) are the exception — they have no DB dependencies and can be fully implemented.

**The only file with real DB operations in this codebase** that works is `apps/api/src/queues/charge-trigger-consumer.ts` — queue consumers are exempt from the typecheck issue. Route handlers are NOT.

### CRITICAL: Use `impl(8.3):` prefix for Flutter deferred notes — NOT `TODO:`

Flutter linter flags `TODO:` prefix. Use `impl(8.3):` for all deferred implementation comments in Flutter files. This is the pattern already established in `notification_handler.dart` from Story 8.2.

### CRITICAL: Flutter imports — `riverpod_annotation` only, NOT `flutter_riverpod`

In Flutter provider files, only import `package:riverpod_annotation/riverpod_annotation.dart`. Do NOT also import `package:flutter_riverpod/flutter_riverpod.dart` — it is redundant and was flagged in Story 8.2.

### CRITICAL: Stripe webhook — `verifyWebhookSignature` is a stub returning `false`

`apps/api/src/services/stripe.ts`'s `verifyWebhookSignature` always returns `false` (deferred per `deferred-work.md`). The webhook handler will always return HTTP 400 for real Stripe events until this is implemented. This is intentional and must NOT be changed in this story. The notification TODO(impl) blocks inside the handler are still wired correctly for when the stub is eventually replaced.

### CRITICAL: admin-api is a separate Worker

`apps/admin-api/` is a completely separate Cloudflare Worker from `apps/api/`. It has its own `package.json`, its own `wrangler.jsonc`, and its own source tree. It cannot import from `apps/api/src/`. For dispute resolution notifications (AC: 4):
- Either create `apps/admin-api/src/services/push.ts` mirroring `apps/api/src/services/push.ts` (same stub)
- Or duplicate the `buildDisputeResolvedBody` helper in admin-api

Check `apps/admin-api/src/` for the Story 7.9 dispute resolution endpoint before implementing.

### CRITICAL: `sendPush()` remains a stub — do not implement APNs delivery

`apps/api/src/services/push.ts`'s `sendPush()` has `TODO(impl)` comments and does nothing (APNs not yet wired). This story CALLS `sendPush()` from new code paths — it does NOT implement the APNs client. No push notifications will actually fire until a future story wires `@fivesheepco/cloudflare-apns2`.

### CRITICAL: Notification copy tone — UX-DR36

Story 8.3 introduces UX-DR36 (affirming tone for charge notifications). Both charge and dispute-rejected notifications must:
- Include "Thanks for trying." — explicitly affirming
- NOT use: "failed", "penalty", "owe", "you were charged", "violation"
- Mirror the warm tone of UX-DR32 from Story 8.2 stake warnings

### CRITICAL: `shouldSendNotification` preference enforcement

All new notification dispatch points must respect the 3-level preference hierarchy from Story 8.1/8.2:
1. `scope='global'` disabled → suppress all for user
2. `scope='task'` disabled → suppress for that task
3. `scope='device'` disabled → suppress for that device

`shouldSendNotification(preferences, taskId, deviceToken)` is already exported from `apps/api/src/lib/notification-scheduler.ts` — use it.

### Architecture: File locations for this story

```
apps/api/
├── src/
│   ├── lib/
│   │   └── notification-scheduler.ts     # MODIFY — add 4 new helper functions
│   └── routes/
│       ├── commitment-contracts.ts        # MODIFY — add notification TODO(impl) to webhook handler
│       └── proof.ts                       # MODIFY — add notification TODO(impl) to proof + dispute handlers
└── test/
    └── lib/
        └── notification-scheduler.test.ts # MODIFY — add 8+ tests for new helpers

apps/admin-api/src/
└── (find dispute resolution endpoint from Story 7.9 — likely routes/disputes.ts)
    # MODIFY — add notification TODO(impl) for dispute resolution outcome

apps/flutter/lib/
├── core/l10n/strings.dart                 # MODIFY — add 5 new notification string constants/methods
└── features/notifications/presentation/
    └── notification_handler.dart          # MODIFY — extend impl(8.3): stubs for new types
    # notification_handler.g.dart — DO NOT regenerate (signature unchanged)
```

### Notification types introduced in this story

| `data.type` value | Trigger | AC |
|---|---|---|
| `charge_succeeded` | Stripe webhook `payment_intent.succeeded` | AC 1 |
| `verification_approved` | Proof submission verified=true with stake | AC 2 |
| `dispute_filed` | `POST /v1/tasks/{taskId}/disputes` | AC 3 |
| `dispute_approved` | Admin resolves dispute → approved | AC 4 |
| `dispute_rejected` | Admin resolves dispute → rejected | AC 4 |

These join the existing types from Story 8.2: `reminder`, `deadline_today`, `deadline_tomorrow`, `stake_warning`.

### Drizzle migration — NOT required for this story

Story 8.2 already created `scheduled_notifications` table (migration `0019_scheduled_notifications.sql`). Story 8.3 notification triggers are event-driven (webhook/proof/dispute) and do NOT need idempotency rows in `scheduled_notifications` — they fire exactly once per event. No new migration is needed.

### Testing approach

Tests live in `apps/api/test/lib/notification-scheduler.test.ts` (Vitest). New tests use the same `describe/it/expect` pattern:
```typescript
import { describe, it, expect } from 'vitest'
import {
  buildChargeNotificationBody,
  buildVerificationApprovedBody,
  buildDisputeFiledBody,
  buildDisputeResolvedBody,
  formatDollars,  // reuse existing helper for amount formatting checks
} from '../../src/lib/notification-scheduler.js'
```

Pure helper functions only — no DB, no app import needed for these tests.

### Story 8.2 deferred patches that must remain intact

Two patches were applied in Story 8.2 review that must not be reverted:
- `scheduledNotificationsTable` has Drizzle-level `unique()` constraint (not just SQL migration)
- `notificationStakeWarningBody` in `strings.dart` uses unescaped `$stakeAmount` interpolation (not `\$stakeAmount`)

If these are missing in the current codebase, patch them as part of this story.

### Previous story learnings (Story 8.2)

- `notification_handler.g.dart` uses a manually-crafted hash `a1b2c3d4e5f6...` — CI does not run `build_runner`. Do NOT regenerate the `.g.dart` file unless the `.dart` signature changes.
- Notification strings live in `apps/flutter/lib/core/l10n/strings.dart` — end of file after the `// ── Task Reminder & Deadline Notifications` block (currently line 1197).
- `notification-scheduler.ts` pattern: pure helpers are exported and unit-tested; DB-dependent trigger functions use `TODO(impl)` with full query documentation.
- JWT auth pattern: `c.get('jwtPayload').sub` — check `apps/api/src/routes/tasks.ts` or `commitment-contracts.ts` for reference. Stub pattern used in route handlers: `'stub_user_id'`.
- `triggerOverdueCharges` in `scheduled` export must NOT be removed — it is an existing stub.
- `createDb(env.DATABASE_URL)` is the Drizzle helper — `casing: 'camelCase'` means DB column `user_id` maps to `userId`.
- `hoursUntil` test boundary flake at exactly 2h is deferred (in `deferred-work.md`).

### Deferred items from previous stories relevant to Story 8.3

From `deferred-work.md`:
- **`stakeAmountCents` absent from `TaskDto` and `toDomain()`** — `Task` domain model declares `int? stakeAmountCents` but `TaskDto` does not map the field. This means stake amount is not available in Flutter from API deserialization. Notification bodies that display stake amount in Flutter deep-link views cannot show real values until this is fixed. For Story 8.3 this is only relevant for the Flutter tap handler deep-link — the push payloads are built server-side where the DB value is available. Address in `apps/flutter/lib/features/tasks/data/task_dto.dart` if needed for the deep-link view.
- **`POST /v1/webhooks/stripe` webhook event routing incomplete** — `verifyWebhookSignature` stub returns `false`; all webhook processing is deferred. Story 8.3 adds the notification dispatch TODO(impl) inside the handler but does NOT implement the webhook routing.
- **`charge-scheduler.ts` query is a stub** — `triggerOverdueCharges()` is a no-op. Unrelated to Story 8.3 but must remain in `scheduled` export.

### References

- Epic 8 / Story 8.3 AC: `_bmad-output/planning-artifacts/epics.md` lines 2012–2036
- Story 8.2 dev notes (scheduler pattern, sendPush, idempotency): `_bmad-output/implementation-artifacts/8-2-task-reminder-deadline-notifications.md`
- Stripe webhook handler: `apps/api/src/routes/commitment-contracts.ts` lines 792–841
- Proof submission + dispute handler: `apps/api/src/routes/proof.ts`
- `sendPush()` stub: `apps/api/src/services/push.ts`
- `notification-scheduler.ts` (existing helpers): `apps/api/src/lib/notification-scheduler.ts`
- `shouldSendNotification()`: `apps/api/src/lib/notification-scheduler.ts:101`
- Existing notification tests: `apps/api/test/lib/notification-scheduler.test.ts`
- AppStrings notification block: `apps/flutter/lib/core/l10n/strings.dart` lines 1197–1215
- `notification_handler.dart`: `apps/flutter/lib/features/notifications/presentation/notification_handler.dart`
- Architecture ARCH-27 (APNs direct): `_bmad-output/planning-artifacts/architecture.md`
- FR42 (push notifications), UX-DR36 (affirming charge tone): `_bmad-output/planning-artifacts/epics.md`
- Deferred work: `_bmad-output/implementation-artifacts/deferred-work.md`

### Project Structure Notes

- All new `apps/api/src/lib/notification-scheduler.ts` exports are pure functions — no DB imports
- Route handler files (`commitment-contracts.ts`, `proof.ts`) receive only TODO(impl) comment additions
- Flutter `.g.dart` files are committed; CI does not run `build_runner`
- `riverpod_annotation` only in Flutter providers — never `flutter_riverpod` alongside it
- Notification string constants follow the `notificationXxx` naming convention in `AppStrings`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No debug issues encountered. Pre-existing Drizzle TS2345 typecheck errors in `charge-trigger-consumer.ts` and `calendar.ts` are not related to this story and remain unchanged.

### Completion Notes List

- Task 1: Added `TODO(impl)` comment block to `POST /v1/webhooks/stripe` in `commitment-contracts.ts` documenting `payment_intent.succeeded` dispatch logic including DB queries, preference enforcement, and `buildChargeNotificationBody` usage. `void event` kept intact; stub guard preserved.
- Task 2: Implemented 4 pure helper functions in `notification-scheduler.ts`: `buildChargeNotificationBody`, `buildVerificationApprovedBody`, `buildDisputeFiledBody`, `buildDisputeResolvedBody`. All use `formatDollars()` for amount formatting and follow UX-DR36 affirming tone (no punitive language in charge/dispute-rejected paths).
- Task 3: Added `TODO(impl)` comment block in `POST /v1/tasks/{taskId}/proof` handler documenting verification-approved notification dispatch; stub response kept intact; no imports added per Drizzle typecheck constraint.
- Task 4: Added `TODO(impl)` comment block in `POST /v1/tasks/{taskId}/disputes` handler documenting dispute-filed notification dispatch; stub `return` kept intact.
- Task 5: Added `TODO(impl)` comment block in `POST /admin/v1/disputes/{id}/resolve` handler in `apps/admin-api/src/routes/disputes.ts` documenting dispute-resolved notification dispatch (both approved and rejected outcomes), including note that admin-api must use its own push.ts copy.
- Task 6: Added 8 new tests (plus 1 extra for buildDisputeResolvedBody approved path = 9 tests) to `notification-scheduler.test.ts`. Total test count: 250 (242 + 8 new). All 250 tests pass.
- Task 7: Added 5 new `AppStrings` methods/constants to `strings.dart`: `notificationChargeBody`, `notificationVerificationApprovedBody`, `notificationDisputeFiledBody`, `notificationDisputeApprovedBody`, `notificationDisputeRejectedBody`. Flutter analyzer passes clean.
- Task 8: Extended `notification_handler.dart` `build()` comment block to include all 5 new `data.type` values: `charge_succeeded`, `verification_approved`, `dispute_filed`, `dispute_approved`, `dispute_rejected`. Method signature unchanged; `.g.dart` not regenerated.

### File List

apps/api/src/lib/notification-scheduler.ts
apps/api/src/routes/commitment-contracts.ts
apps/api/src/routes/proof.ts
apps/api/test/lib/notification-scheduler.test.ts
apps/admin-api/src/routes/disputes.ts
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/lib/features/notifications/presentation/notification_handler.dart
_bmad-output/implementation-artifacts/8-3-commitment-charge-verification-notifications.md
_bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

| Date | Change | Author |
|---|---|---|
| 2026-04-01 | Implemented Story 8.3: 4 pure notification helper functions (notification-scheduler.ts), TODO(impl) dispatch blocks in webhook/proof/dispute handlers, 8 new unit tests (250 total), 5 AppStrings constants, NotificationHandler type coverage expanded | claude-sonnet-4-6 |
