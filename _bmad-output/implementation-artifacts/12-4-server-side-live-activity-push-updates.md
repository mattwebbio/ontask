# Story 12.4: Server-Side Live Activity Push Updates

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an iOS user,
I want my Live Activity to update in real time based on server events,
so that the Dynamic Island reflects what's actually happening — not stale data.

## Acceptance Criteria

1. **Given** the server needs to update a Live Activity
   **When** the push is sent
   **Then** the API route `POST /internal/live-activities/update` is implemented in `apps/api/src/routes/internal.ts` (added to the existing internal router — same file as `GET /internal/mcp-tokens/validate`)
   **And** the `live-activity.ts` service (`apps/api/src/services/live-activity.ts`) reads the push token from `live_activity_tokens` and sends via APNs with headers: `apns-push-type: liveactivity`, `apns-topic: com.ontaskhq.ontask.push-type.liveactivity` (ARCH-28)
   **And** the push payload contains the updated ContentState

2. **Given** server-push triggers are implemented
   **When** any of the four events occurs
   **Then** a push is sent: (1) task nearing deadline (30 min — via scheduled cron), (2) stake charged (from charge-trigger-consumer.ts), (3) proof submitted (from proof.ts route), (4) Watch Mode AI detection event (from proof.ts route)

3. **Given** an APNs delivery failure returns HTTP 410
   **When** the response is received
   **Then** the expired push token is deleted from `live_activity_tokens` — stale tokens are not retried indefinitely

---

## Tasks / Subtasks

### Task 1: Implement `live-activity.ts` service (AC: 1, 3)

**File:** `apps/api/src/services/live-activity.ts` (new file — already referenced in `push.ts` comments but not yet created; architecture specifies this path, ARCH-28)

This service sends ActivityKit server pushes via APNs. It reuses the same `@fivesheepco/cloudflare-apns2` v13.0.0 package already used by `apps/api/src/services/push.ts`. Do NOT reinvent — extend the pattern.

**CRITICAL: APNs headers differ from regular push.** Live Activity pushes require:
- `apns-push-type: liveactivity` (NOT `alert`)
- `apns-topic: com.ontaskhq.ontask.push-type.liveactivity` (NOT `com.ontaskhq.ontask`)
- `apns-expiration`: Unix timestamp matching the token's `expiresAt`

**ActivityKit push payload format (from architecture spec):**
```json
{
  "aps": {
    "timestamp": 1711720000,
    "event": "update",
    "content-state": {
      "taskTitle": "Pay rent",
      "elapsedSeconds": 1842,
      "deadlineTimestamp": 1711723600,
      "stakeAmount": 50,
      "activityStatus": "active"
    },
    "dismissal-date": 1711723600
  }
}
```

For `end` events, set `"event": "end"` in the aps body.

**ContentState fields match the Swift struct defined in previous stories:**
- `taskTitle: String` — always present
- `elapsedSeconds: Int?` — nil when not in timer mode
- `deadlineTimestamp: Unix timestamp (number)?` — nil when no commitment deadline
- `stakeAmount: Decimal?` — nil when no stake
- `activityStatus: String` — `"active"` | `"completed"` | `"failed"` | `"watchMode"`

**Service interface to implement:**

```typescript
// apps/api/src/services/live-activity.ts

export interface LiveActivityContentState {
  taskTitle: string
  elapsedSeconds?: number
  deadlineTimestamp?: number  // Unix timestamp (seconds)
  stakeAmount?: number
  activityStatus: 'active' | 'completed' | 'failed' | 'watchMode'
}

export interface SendLiveActivityUpdateOptions {
  pushToken: string            // ActivityKit push token from live_activity_tokens.pushToken
  expiresAt: Date              // from live_activity_tokens.expiresAt
  event: 'update' | 'end'
  contentState: LiveActivityContentState
  dismissalDate?: number       // Unix timestamp — for commitment_countdown: deadline
}

export async function sendLiveActivityUpdate(
  options: SendLiveActivityUpdateOptions,
  env: CloudflareBindings
): Promise<{ success: boolean; tokenExpired: boolean }>
```

**APNs 410 handling (AC: 3):** The function MUST return `{ success: false, tokenExpired: true }` when APNs responds HTTP 410. The caller (internal route handler) is responsible for deleting the row from `live_activity_tokens`. Do NOT delete from within the service function — keep it side-effect-free for testability.

**Local dev constraint (CRITICAL — do not forget):**
`wrangler dev` does NOT support HTTP/2 outbound (open workerd bug). Live Activity APNs calls MUST be tested against staging only: `wrangler deploy --env staging`. Document this constraint with a comment in the service file.

**Subtasks:**
- [x] Create `apps/api/src/services/live-activity.ts` with `sendLiveActivityUpdate()` and `LiveActivityContentState` interface
- [x] Use `@fivesheepco/cloudflare-apns2` v13.0.0 — same as `push.ts` — do not install a different package
- [x] Set `apns-push-type: liveactivity` and `apns-topic: com.ontaskhq.ontask.push-type.liveactivity`
- [x] Set `apns-expiration` to `Math.floor(options.expiresAt.getTime() / 1000)` (Unix seconds)
- [x] Return `{ tokenExpired: true }` on APNs HTTP 410 response
- [x] Add comment: "CRITICAL: Test against staging only — wrangler dev does not support HTTP/2 outbound (ARCH-28)"

---

### Task 2: Add `POST /internal/live-activities/update` to internal router (AC: 1)

**File to modify:** `apps/api/src/routes/internal.ts`

The internal router (`internalRouter`) already handles `GET /internal/mcp-tokens/validate`. This story adds `POST /internal/live-activities/update` to the SAME file — do NOT create a new router or new file.

**Why internal?** The `/internal/` prefix is for server-to-server calls via Cloudflare Service Binding only — never exposed as a public `/v1/` API. This keeps the push dispatch off the authenticated user API surface. See the existing `internalRouter` pattern.

**Route: `POST /internal/live-activities/update`**

Request body:
```typescript
{
  userId: string          // UUID — used to look up the token
  taskId: string | null   // UUID or null (for watch_mode without a task)
  activityType: 'task_timer' | 'commitment_countdown' | 'watch_mode'
  event: 'update' | 'end'
  contentState: LiveActivityContentState
  dismissalDate?: number  // Unix timestamp (optional)
}
```

Handler logic:
1. Look up `live_activity_tokens` WHERE `userId = body.userId AND taskId = body.taskId AND activityType = body.activityType` — get `pushToken` and `expiresAt`
2. If no row found → return 200 `{ data: { sent: false, reason: 'no_token' } }` (activity may have already ended client-side — not an error)
3. Check if `expiresAt` is in the past → return 200 `{ data: { sent: false, reason: 'token_expired' } }` (skip APNs call, delete row)
4. Call `sendLiveActivityUpdate({ pushToken, expiresAt, event, contentState, dismissalDate }, env)`
5. If `tokenExpired: true` returned → DELETE the row from `live_activity_tokens`, return 200 `{ data: { sent: false, reason: 'token_expired' } }`
6. Return 200 `{ data: { sent: true } }`

**DB imports needed (not yet imported in internal.ts):**
```typescript
import { liveActivityTokensTable } from '@ontask/core'
import { and, isNull, eq } from 'drizzle-orm'
```

Note: `taskId` can be null (for `watch_mode` without an associated task). Use `isNull(liveActivityTokensTable.taskId)` vs `eq(liveActivityTokensTable.taskId, taskId)` based on whether `taskId` is null.

**Subtasks:**
- [x] Import `liveActivityTokensTable` from `@ontask/core` in `internal.ts`
- [x] Import `sendLiveActivityUpdate` and `LiveActivityContentState` from `../services/live-activity.js`
- [x] Add `and`, `isNull`, `eq` to drizzle-orm imports (the file already imports `eq`)
- [x] Implement `POST /internal/live-activities/update` handler following the logic above
- [x] Use `Hono` (NOT `OpenAPIHono`) for the internal router — consistent with existing `internalRouter` (internal routes are NOT in the public OpenAPI spec)
- [x] Handle `taskId = null` with `isNull()` in the WHERE clause

---

### Task 3: Wire push triggers into existing event handlers (AC: 2)

Four trigger points. Each calls `POST /internal/live-activities/update` via Cloudflare Service Binding or directly imports and calls the service.

**IMPORTANT ARCHITECTURAL DECISION:** Since `live-activity.ts` is in the same Worker as the existing event handlers, call `sendLiveActivityUpdate()` directly — do NOT use a Service Binding or queue for same-Worker calls. Service Bindings are for Worker-to-Worker calls only.

#### Trigger 1: Task nearing deadline (30 min) — `apps/api/src/lib/notification-scheduler.ts`

Add a new exported function `triggerDeadlineLiveActivityUpdates(env)` following the same stub pattern as `triggerStakeWarningNotifications()`. This runs on the same cron (`*/5 * * * *`).

Query: tasks with a commitment deadline 25–35 minutes from now (5-minute cron window) that have an active `commitment_countdown` or `task_timer` live activity token.

```typescript
export async function triggerDeadlineLiveActivityUpdates(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): Query tasks WHERE:
  //   dueDate BETWEEN NOW() + INTERVAL '25 minutes' AND NOW() + INTERVAL '35 minutes'
  //   AND completedAt IS NULL
  //   JOIN live_activity_tokens lat ON lat.taskId = tasks.id
  //     AND lat.activityType IN ('task_timer', 'commitment_countdown')
  //     AND lat.expiresAt > NOW()
  //
  // TODO(impl): For each matching task + token:
  //   await sendLiveActivityUpdate({
  //     pushToken: lat.pushToken,
  //     expiresAt: lat.expiresAt,
  //     event: 'update',
  //     contentState: {
  //       taskTitle: task.title,
  //       deadlineTimestamp: Math.floor(task.dueDate.getTime() / 1000),
  //       stakeAmount: task.stakeAmountCents ? task.stakeAmountCents / 100 : undefined,
  //       activityStatus: 'active',
  //     },
  //     dismissalDate: Math.floor(task.dueDate.getTime() / 1000),
  //   }, env)
  //   If tokenExpired → DELETE FROM live_activity_tokens WHERE id = lat.id
  void env
}
```

Register this in `apps/api/src/index.ts` `scheduled()` handler:
```typescript
ctx.waitUntil(triggerDeadlineLiveActivityUpdates(env))
```

#### Trigger 2: Stake charged — `apps/api/src/queues/charge-trigger-consumer.ts`

After Step 6 (charge_events status='charged') in the consumer, add a Live Activity push:
```typescript
// TODO(impl): Send Live Activity 'end' push for stake charged
// await sendLiveActivityUpdate({
//   pushToken: ...,  // look up live_activity_tokens WHERE userId = payload.userId AND taskId = payload.taskId
//   event: 'end',
//   contentState: {
//     taskTitle: payload.taskTitle,  // NOTE: taskTitle must be added to ChargeTriggerPayload
//     stakeAmount: payload.stakeAmountCents / 100,
//     activityStatus: 'failed',
//   },
// }, env)
```

**Note:** `ChargeTriggerPayload` does not currently include `taskTitle`. Add `taskTitle: string` to the type. The charge-scheduler.ts enqueues messages — update `triggerOverdueCharges()` to include `taskTitle` in the queue message when implementing.

#### Trigger 3: Proof submitted — `apps/api/src/routes/proof.ts`

After successful proof verification, send `end` push with `activityStatus: 'completed'`:
```typescript
// TODO(impl): After proof verification succeeds:
// await sendLiveActivityUpdate({
//   pushToken: ...,  // look up live_activity_tokens WHERE userId AND taskId
//   event: 'end',
//   contentState: {
//     taskTitle: task.title,
//     activityStatus: 'completed',
//   },
// }, env)
```

#### Trigger 4: Watch Mode AI detection event — `apps/api/src/routes/proof.ts`

When `proofType=watchMode` and the AI detects completion, send the same `end` push as trigger 3.

**Subtasks:**
- [x] Add `triggerDeadlineLiveActivityUpdates()` to `notification-scheduler.ts` (exported, stub with `TODO(impl)`)
- [x] Register `triggerDeadlineLiveActivityUpdates` in `apps/api/src/index.ts` `scheduled()` handler
- [x] Import `sendLiveActivityUpdate` in `charge-trigger-consumer.ts` — add `TODO(impl)` stub after charge succeeds
- [x] Add `taskTitle: string` to `ChargeTriggerPayload` type in `charge-trigger-consumer.ts`
- [x] Import `sendLiveActivityUpdate` in `proof.ts` — add `TODO(impl)` stub after verification succeeds
- [x] All call sites are stubs with `TODO(impl)` — the DB query logic and live activity token lookup are deferred; real implementation follows the internal route handler pattern

---

### Task 4: Token cleanup — stale token deletion (AC: 3)

The 410 deletion is handled in Task 2 (internal route handler) and in each trigger's `tokenExpired` check. No separate cleanup task is needed.

However, add a scheduled cleanup function for tokens past their `expiresAt` (belt-and-suspenders, since client-side activity end should handle most cases):

**File to modify:** `apps/api/src/lib/notification-scheduler.ts`

Add:
```typescript
export async function cleanupExpiredLiveActivityTokens(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): DELETE FROM live_activity_tokens WHERE expiresAt < NOW()
  // ActivityKit tokens expire with the activity (max 8h iOS limit).
  // This cleanup runs on every cron tick to prune stale rows.
  void env
}
```

Register in `apps/api/src/index.ts` `scheduled()` handler:
```typescript
ctx.waitUntil(cleanupExpiredLiveActivityTokens(env))
```

**Subtasks:**
- [x] Add `cleanupExpiredLiveActivityTokens()` to `notification-scheduler.ts` (exported, stub with `TODO(impl)`)
- [x] Register `cleanupExpiredLiveActivityTokens` in `index.ts` `scheduled()` handler

---

### Task 5: Tests (AC: 1, 3)

**File to create:** `apps/api/test/routes/live-activities-internal.test.ts`

Test the internal route handler using the same test pattern as existing API tests (import default app, call `app.request()`).

**Test cases for `POST /internal/live-activities/update`:**
1. Returns `{ sent: false, reason: 'no_token' }` when no token exists in DB (stub — no DB in test env)
2. Returns 400 when request body is invalid (missing required fields)
3. Returns 200 with valid minimal body `{ userId, taskId, activityType, event, contentState }`

**File to create or modify:** `apps/api/test/routes/live-activities.test.ts`

The existing file tests `POST /v1/live-activities/token`. Since this story does NOT modify that route, do not change existing tests — add a new test file for the internal route.

**Unit tests for `live-activity.ts` service:**

**File:** `apps/api/src/services/live-activity.test.ts`

Test the pure logic: payload shape, 410 detection, `tokenExpired` return value. Use `vi.mock` to mock `@fivesheepco/cloudflare-apns2`.

**Subtasks:**
- [x] Create `apps/api/test/routes/live-activities-internal.test.ts` with route-level tests
- [x] Create `apps/api/src/services/live-activity.test.ts` with unit tests for `sendLiveActivityUpdate()`
- [x] Test that 410 APNs response → `tokenExpired: true` returned
- [x] Test that aps payload includes correct `event`, `content-state`, `apns-topic`, `apns-push-type` headers
- [x] Do NOT modify `test/routes/live-activities.test.ts` — those tests already pass and cover the token registration route

---

## Dev Notes

### Architecture References

- **APNs package:** `@fivesheepco/cloudflare-apns2` v13.0.0 — Workers-native, uses `fetch()` + `crypto.subtle` for ES256 JWT signing. Already used in `push.ts`. [Source: architecture.md#Push Notifications Infrastructure]
- **Live Activity APNs headers:** `apns-push-type: liveactivity` + `apns-topic: com.ontaskhq.ontask.push-type.liveactivity`. These are DIFFERENT from the regular push headers. [Source: architecture.md#Server-Side Live Activity Updates]
- **APNs secrets in Workers:** `APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID` — set via `wrangler secret put`. Already declared in `worker-configuration.d.ts` and used by `push.ts`. [Source: architecture.md#Push Notifications Infrastructure]
- **Local dev constraint:** `wrangler dev` does NOT support HTTP/2 outbound. APNs must be tested against staging: `wrangler deploy --env staging`. [Source: architecture.md#Push Notifications Infrastructure]

### File Locations

| File | Action | Notes |
|---|---|---|
| `apps/api/src/services/live-activity.ts` | CREATE | New service — ARCH-28 specifies this exact path |
| `apps/api/src/routes/internal.ts` | MODIFY | Add `POST /internal/live-activities/update` to existing `internalRouter` |
| `apps/api/src/lib/notification-scheduler.ts` | MODIFY | Add `triggerDeadlineLiveActivityUpdates()` and `cleanupExpiredLiveActivityTokens()` |
| `apps/api/src/index.ts` | MODIFY | Register two new cron functions in `scheduled()` |
| `apps/api/src/queues/charge-trigger-consumer.ts` | MODIFY | Add `taskTitle` to payload type; add TODO(impl) stub for live activity push |
| `apps/api/src/routes/proof.ts` | MODIFY | Add TODO(impl) stub for live activity push on proof verified |
| `apps/api/src/services/live-activity.test.ts` | CREATE | Unit tests for service |
| `apps/api/test/routes/live-activities-internal.test.ts` | CREATE | Route-level tests |

### Database

The `live_activity_tokens` table is in `packages/core/src/schema/live-activity-tokens.ts`. Schema:
```typescript
{
  id: uuid (PK),
  userId: uuid NOT NULL,
  taskId: uuid (nullable — null for watch_mode without a task),
  activityType: text NOT NULL  // 'task_timer' | 'commitment_countdown' | 'watch_mode'
  pushToken: text NOT NULL,
  createdAt: timestamptz,
  expiresAt: timestamptz NOT NULL
}
```

UNIQUE constraint: `(userId, taskId, activityType)` — enforced at application level (upsert in Story 12.1 token registration). No DB-level unique index exists in the schema definition above.

**Query pattern for token lookup:**
```typescript
// taskId is NOT NULL:
db.select().from(liveActivityTokensTable)
  .where(and(
    eq(liveActivityTokensTable.userId, userId),
    eq(liveActivityTokensTable.taskId, taskId),
    eq(liveActivityTokensTable.activityType, activityType),
  ))

// taskId IS NULL (watch_mode without task):
db.select().from(liveActivityTokensTable)
  .where(and(
    eq(liveActivityTokensTable.userId, userId),
    isNull(liveActivityTokensTable.taskId),
    eq(liveActivityTokensTable.activityType, activityType),
  ))
```

### Existing Code Patterns to Follow

- **Internal router pattern:** `apps/api/src/routes/internal.ts` uses `Hono` (not `OpenAPIHono`), imports `createDb`, uses `eq` from drizzle-orm, returns JSON directly (not `ok()` wrapper). Check the existing `GET /internal/mcp-tokens/validate` handler for exact style.
- **Push service pattern:** `apps/api/src/services/push.ts` — note the `TODO(impl)` stub pattern. The `live-activity.ts` service should follow the same structure but with the real implementation (not a stub) since this story delivers it.
- **Notification-scheduler stub pattern:** All `triggerXxx()` functions in `notification-scheduler.ts` follow the same structure: exported async function, `void env`, all DB logic in `TODO(impl)` comments. New functions in this story follow the same pattern.
- **Scheduled handler in index.ts:** `ctx.waitUntil(...)` pattern — all scheduled functions are fire-and-forget via `waitUntil`. Add new calls after existing ones.

### ContentState Mapping: Swift → TypeScript

The Swift `ContentState` struct (defined in `OnTaskLiveActivity/OnTaskLiveActivity.swift` from Story 12.1):

| Swift field | TypeScript field in payload | Notes |
|---|---|---|
| `taskTitle: String` | `"taskTitle": string` | Always present |
| `elapsedSeconds: Int?` | `"elapsedSeconds": number \| undefined` | Timer mode only |
| `deadlineTimestamp: Date?` | `"deadlineTimestamp": Unix number \| undefined` | Use `.getTime()/1000` |
| `stakeAmount: Decimal?` | `"stakeAmount": number \| undefined` | Dollars (not cents) |
| `activityStatus: Status` | `"activityStatus": "active"\|"completed"\|"failed"\|"watchMode"` | Enum raw value |

**CRITICAL:** `stakeAmount` in the payload is in **dollars** (e.g., `50.00`), not cents. The DB stores `stakeAmountCents`. Convert: `stakeAmountCents / 100`.

**CRITICAL:** `deadlineTimestamp` in the payload is a **Unix timestamp in seconds** (not milliseconds). Convert: `Math.floor(date.getTime() / 1000)`.

### Push Triggers Summary

| Trigger | Push event | activityStatus | Source file |
|---|---|---|---|
| Commitment deadline within 30 min | `update` | `active` | `notification-scheduler.ts` (new cron function) |
| Stake charged (task failed) | `end` | `failed` | `charge-trigger-consumer.ts` (after Stripe charge) |
| Proof submitted & verified | `end` | `completed` | `proof.ts` (after AI verification) |
| Watch Mode AI detection complete | `end` | `completed` | `proof.ts` (watchMode proof path) |

### Anti-Pattern Prevention

- **Do NOT** modify `POST /v1/live-activities/token` — that route from Story 12.1 is complete and working. This story adds the server-push capability, not the token registration.
- **Do NOT** use `OpenAPIHono` in `internal.ts` — the internal router uses plain `Hono`. Internal routes are NOT included in the public OpenAPI spec.
- **Do NOT** use a Cloudflare Queue for same-Worker live activity push dispatch. Queues are for cross-Worker or deferred work (charge-trigger-queue, every-org-queue). Direct function calls within the same Worker are correct here.
- **Do NOT** push regular APNs notifications via the live activity service. `sendLiveActivityUpdate()` is exclusively for ActivityKit push tokens — different token type, different APNs topic.
- **Do NOT** send `elapsedSeconds` in server pushes. Elapsed timer is driven client-side by Swift `Timer.periodic`. Server pushes should only update `deadlineTimestamp`, `stakeAmount`, `activityStatus`.

### Previous Story Intelligence

From Stories 12.1–12.3:
- `live_activity_tokens` table Drizzle schema: `packages/core/src/schema/live-activity-tokens.ts` — already committed, import from `@ontask/core`
- `POST /v1/live-activities/token` route: `apps/api/src/routes/live-activities.ts` — already implemented (stub with TODO(impl) for DB); do NOT modify
- The `activityStatus` Swift enum: `active`, `completed`, `failed`, `watchMode` (camelCase in Swift, maps to same camelCase in JSON)
- `apps/flutter/ios/OnTaskLiveActivity/OnTaskLiveActivity.swift` — the `OnTaskActivityAttributes` definition — defines `ContentState` fields server must match exactly
- From Story 12.3: `startWatchModeActivity()` added to `LiveActivitiesRepository` — Watch Mode activities have `taskId` that may be null
- Pattern: all new Swift/Flutter work was completed in Stories 12.1–12.3. Story 12.4 is entirely server-side TypeScript — no Swift or Flutter changes required.

### References

- Architecture: APNs infrastructure and headers — [Source: `_bmad-output/planning-artifacts/architecture.md#Push Notifications Infrastructure`]
- Architecture: Live Activity ContentState and push payload format — [Source: `_bmad-output/planning-artifacts/architecture.md#ActivityKit Content State`]
- Architecture: Server-side push triggers table — [Source: `_bmad-output/planning-artifacts/architecture.md#Server-Side Live Activity Updates`]
- Architecture: Service file path `apps/api/src/services/live-activity.ts` — [Source: `_bmad-output/planning-artifacts/architecture.md#apps/api/ file tree`]
- Schema: `packages/core/src/schema/live-activity-tokens.ts`
- Existing push service: `apps/api/src/services/push.ts`
- Existing internal router: `apps/api/src/routes/internal.ts`
- Epic AC: `_bmad-output/planning-artifacts/epics.md#Story 12.4`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

Fixed esbuild parse error caused by `*/5 * * * *` cron expression in JSDoc comments — replaced with plain English "every 5 minutes".

### Completion Notes List

- Task 1: Created `apps/api/src/services/live-activity.ts` — real implementation (not a stub) using `@fivesheepco/cloudflare-apns2` v13.0.0. Uses `PushType.liveactivity`, topic `com.ontaskhq.ontask.push-type.liveactivity`, sets `apns-expiration` from `expiresAt`. Returns `{ tokenExpired: true }` on `ApnsError` with `statusCode === 410`. Intentionally omits `elapsedSeconds` from the payload (client-driven timer per ARCH-28 spec).
- Task 2: Added `POST /internal/live-activities/update` to existing `internalRouter` in `apps/api/src/routes/internal.ts`. Uses plain `Hono` (not OpenAPIHono). Handles `taskId = null` with `isNull()` from drizzle-orm. Deletes stale token rows on both local expiry check and APNs 410 response. Returns `{ sent: false, reason: 'no_token' }` when no row exists.
- Task 3: Added `triggerDeadlineLiveActivityUpdates()` stub to `notification-scheduler.ts`; registered in `index.ts` `scheduled()`. Added `taskTitle: string` to `ChargeTriggerPayload` in `charge-trigger-consumer.ts` with `TODO(impl)` stub for the Live Activity push. Added `TODO(impl)` stubs in `proof.ts` for proof-verified and watch-mode triggers (Triggers 3 and 4).
- Task 4: Added `cleanupExpiredLiveActivityTokens()` stub to `notification-scheduler.ts`; registered in `index.ts` `scheduled()`.
- Task 5: Created `apps/api/src/services/live-activity.test.ts` (12 unit tests) covering payload shape, 410 detection, `elapsedSeconds` exclusion, `dismissal-date` inclusion, `PushType.liveactivity`, correct topic. Created `apps/api/test/routes/live-activities-internal.test.ts` (8 route-level tests) covering `no_token`, `token_expired` (both local expiry and APNs 410), valid success path, missing fields validation, null taskId. All 361 tests pass, no regressions.

### File List

- `apps/api/src/services/live-activity.ts` (CREATED)
- `apps/api/src/services/live-activity.test.ts` (CREATED)
- `apps/api/src/routes/internal.ts` (MODIFIED)
- `apps/api/src/lib/notification-scheduler.ts` (MODIFIED)
- `apps/api/src/index.ts` (MODIFIED)
- `apps/api/src/queues/charge-trigger-consumer.ts` (MODIFIED)
- `apps/api/src/routes/proof.ts` (MODIFIED)
- `apps/api/test/routes/live-activities-internal.test.ts` (CREATED)

## Change Log

| Date | Description |
|---|---|
| 2026-04-02 | Story 12.4 implemented: live-activity.ts service, POST /internal/live-activities/update route, cron stubs, trigger points, 20 new tests (12 unit + 8 route-level). All 361 tests pass. |
