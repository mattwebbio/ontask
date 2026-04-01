# Story 3.5: Auto-Rescheduling on Change

Status: review

## Story

As a user,
I want my schedule to automatically adjust when my calendar changes or tasks slip,
So that my plan always reflects reality without manual intervention.

## Acceptance Criteria

1. **Given** a Google Calendar event changes (time shift or deletion) **When** the change is detected via webhook **Then** the scheduling engine re-runs within 60 seconds and repositions any conflicting task blocks (FR12, NFR-I1)

2. **Given** a task is created, updated, or deleted **When** the mutation completes **Then** `runScheduleForUser()` is triggered asynchronously for that user's full schedule — completing within 30 seconds of the trigger (NFR-I3)

3. **Given** a task is deleted **When** `runScheduleForUser()` runs after the deletion **Then** any `taskCalendarBlocksTable` row for that task is removed **And** the corresponding Google Calendar event is deleted via `DELETE https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events/{eventId}`

4. **Given** a task passes its scheduled start time without being started **When** a scheduled check runs **Then** the task is automatically rescheduled to the next available slot (FR12)

5. **Given** a rescheduling run completes and tasks have shifted times **When** the user is in the Today tab **Then** the Schedule Change Banner can appear (UX-DR18) — the existing `POST /v1/schedule-changes` stub endpoint from Story 2.12 is the notification path; this story triggers it from the scheduling service when blocks change

## Tasks / Subtasks

- [x] Add `deleteTaskBlock()` to Google Calendar service (AC: 3)
  - [x] `apps/api/src/services/calendar/google.ts` — MODIFY: add `deleteTaskBlock(params: DeleteTaskBlockParams, env: CloudflareBindings): Promise<boolean>` — calls `DELETE https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events/{eventId}`, returns `true` on success (204) or event already gone (404), `false` on other errors; partial failure tolerant; follows the same `loadAndRefreshToken` + `CALENDAR_TOKEN_KEY` guard pattern already established

- [x]Add calendar block cleanup to scheduling service (AC: 3)
  - [x]`apps/api/src/services/calendar/index.ts` — MODIFY: add `removeStaleCalendarBlocks(userId, activeTaskIds, env)`:
    - Query `taskCalendarBlocksTable` WHERE `userId = userId` to get all blocks
    - For each block whose `taskId` is NOT in `activeTaskIds`: call `deleteTaskBlock()` then delete the DB row
    - Partial failure tolerant — catch per-block errors, log, continue

- [x]Wire task-mutation-triggered rescheduling (AC: 2)
  - [x]`apps/api/src/routes/tasks.ts` — MODIFY: after `POST /v1/tasks` (create), `PATCH /v1/tasks/:id` (update), `DELETE /v1/tasks/:id` (delete), and `POST /v1/tasks/:id/complete` (complete) route handlers succeed — call `runScheduleForUser(userId, c.env)` in a fire-and-forget pattern: `c.executionCtx.waitUntil(runScheduleForUser(userId, c.env))` so the HTTP response returns immediately but rescheduling completes within the Worker lifetime (satisfying NFR-I3)
  - [x]The `userId` for each task mutation comes from `c.req.header('x-user-id') ?? 'stub-user-id'` (consistent with all other routes)

- [x]Implement Google Calendar webhook receiver (AC: 1)
  - [x]`apps/api/src/routes/calendar.ts` — MODIFY: add `POST /v1/calendar/webhook` route:
    - Validates `X-Goog-Channel-Token` header against a stored secret (see Dev Notes: Webhook Channel Token)
    - Validates `X-Goog-Resource-State` header (`sync`, `exists`, `not_exists`)
    - On valid push notification: calls `c.executionCtx.waitUntil(runScheduleForUser(userId, c.env))`
    - Returns `200 OK` immediately (Google requires fast acknowledgment — do NOT await rescheduling)
    - On invalid token: returns `401 Unauthorized`; never exposes internal details
    - `X-Goog-Channel-Id` header carries the `connectionId` — use it to look up the `userId` from `calendarConnectionsTable`

- [x]Register Google Calendar webhook channel on connect (AC: 1)
  - [x]`apps/api/src/services/calendar/google.ts` — MODIFY: add `registerWebhookChannel(connectionId, userId, env): Promise<string | null>` — calls `POST https://www.googleapis.com/calendar/v3/calendars/primary/events/watch` with:
    ```json
    {
      "id": "<connectionId>",
      "type": "web_hook",
      "address": "https://api.ontaskhq.com/v1/calendar/webhook",
      "token": "<CALENDAR_WEBHOOK_SECRET>",
      "expiration": "<72 hours from now in ms>"
    }
    ```
    Returns the channel `resourceId` on success (needed for renewal), or `null` on failure. Token comes from `env.CALENDAR_WEBHOOK_SECRET` Workers Secret.
  - [x]`apps/api/src/routes/calendar.ts` — MODIFY: after the OAuth transaction insert in `POST /v1/calendar/connect`, call `registerWebhookChannel(connectionId, userId, env)` in a fire-and-forget (`c.executionCtx.waitUntil(...)`) — do NOT block the connect response on webhook registration

- [x]Store webhook channel metadata (AC: 1)
  - [x]`packages/core/src/schema/calendar-connections-google.ts` — MODIFY: add two nullable columns: `webhookChannelResourceId` (text, nullable) and `webhookChannelExpiry` (timestamptz, nullable) — needed for channel renewal tracking
  - [x]`packages/core/src/schema/migrations/` — ADD: new migration file `0007_google_webhook_channel.sql` with `ALTER TABLE calendar_connections_google ADD COLUMN webhook_channel_resource_id text; ALTER TABLE calendar_connections_google ADD COLUMN webhook_channel_expiry timestamptz;`
  - [x]`apps/api/src/services/calendar/google.ts` — MODIFY: after `registerWebhookChannel()` succeeds, store `webhookChannelResourceId` and `webhookChannelExpiry` in `calendarConnectionsGoogleTable` row

- [x]Add `CALENDAR_WEBHOOK_SECRET` Workers Secret (AC: 1)
  - [x]`apps/api/wrangler.jsonc` — MODIFY: add `"CALENDAR_WEBHOOK_SECRET": ""` placeholder in vars (set via `wrangler secret put CALENDAR_WEBHOOK_SECRET`)
  - [x]`apps/api/worker-configuration.d.ts` — ADD: `CALENDAR_WEBHOOK_SECRET: string` to `CloudflareBindings` interface

- [x]Write tests (AC: 1, 2, 3)
  - [x]`apps/api/test/routes/calendar.test.ts` — ADD: tests for `POST /v1/calendar/webhook`:
    - Valid push with correct channel token → 200, triggers rescheduling
    - Invalid/missing channel token → 401
    - `sync` resource state → 200 (acknowledged, no rescheduling triggered)
  - [x]`apps/api/test/services/calendar-write.test.ts` — ADD: tests for `deleteTaskBlock`:
    - `deleteTaskBlock_success_returns_true` — 204 response → true
    - `deleteTaskBlock_notFound_returns_true` — 404 response → true (already gone, not an error)
    - `deleteTaskBlock_serverError_returns_false` — 500 response → false
  - [x]`apps/api/test/routes/tasks.test.ts` (or existing task tests) — ADD: verify that task create/update/delete calls do not fail due to rescheduling trigger wiring (mock `runScheduleForUser`)

## Dev Notes

### CRITICAL: No googleapis npm package

Same constraint as Stories 3.3 and 3.4 — do NOT install `googleapis`. Use direct `fetch()`:
- Delete event: `DELETE https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events/{eventId}`
  - Header: `Authorization: Bearer {access_token}`
  - Success: `204 No Content`
  - Already gone: `404 Not Found` — treat as success (idempotent delete)
- Register watch channel: `POST https://www.googleapis.com/calendar/v3/calendars/primary/events/watch`
  - Header: `Authorization: Bearer {access_token}`, `Content-Type: application/json`
  - Body: `{ id, type, address, token, expiration }`
  - Success: `200 OK` with `{ kind, id, resourceId, resourceUri, expiration }`

### CRITICAL: Token Encryption Pattern (unchanged from Stories 3.3 and 3.4)

`loadAndRefreshToken` helper in `apps/api/src/services/calendar/google.ts` is already established. `deleteTaskBlock` and `registerWebhookChannel` MUST use the same pattern — call `loadAndRefreshToken(connectionId, userId, env, calendarTokenKey)` to get a valid `accessToken` and `calendarId`. Do NOT duplicate the token decrypt/refresh logic.

The `CALENDAR_TOKEN_KEY` guard pattern (check non-empty before calling decrypt/encrypt) is already established — follow the same pattern in new functions.

### CRITICAL: `c.executionCtx.waitUntil()` for Fire-and-Forget

Cloudflare Workers have a request lifetime. To trigger async work after the HTTP response is sent, use `c.executionCtx.waitUntil(promise)`. This is the correct pattern for all fire-and-forget scheduling triggers in this story:

```typescript
// In tasks route handler — after successful DB mutation:
const userId = c.req.header('x-user-id') ?? 'stub-user-id'
c.executionCtx.waitUntil(runScheduleForUser(userId, c.env))
return c.json(ok(result), 201)  // Returns immediately
```

Do NOT `await runScheduleForUser()` directly in the route handler — this would block the HTTP response for the entire scheduling duration.

### CRITICAL: Webhook Channel Token Validation

Google Calendar sends push notifications to `POST /v1/calendar/webhook`. The `token` field in the watch channel registration is echoed back in the `X-Goog-Channel-Token` header on every push. Use `env.CALENDAR_WEBHOOK_SECRET` as this token value.

Token validation:
```typescript
const channelToken = c.req.header('X-Goog-Channel-Token')
if (!channelToken || channelToken !== c.env.CALENDAR_WEBHOOK_SECRET) {
  return c.json(err('UNAUTHORIZED', 'Invalid channel token'), 401)
}
```

The `X-Goog-Channel-Id` header carries the `id` we passed at registration time — which is the `connectionId`. Use it to look up the user:
```typescript
const channelId = c.req.header('X-Goog-Channel-Id')  // = connectionId
// Query calendarConnectionsTable WHERE id = channelId → get userId
```

The `X-Goog-Resource-State` header values:
- `sync`: initial sync confirmation (no calendar change) — return 200, do NOT trigger rescheduling
- `exists`: calendar event was created or modified — trigger rescheduling
- `not_exists`: calendar event was deleted — trigger rescheduling

### CRITICAL: `deleteTaskBlock` — `DeleteTaskBlockParams` Type

```typescript
export interface DeleteTaskBlockParams {
  connectionId: string
  userId: string
  googleEventId: string
}
```

Add to `apps/api/src/services/calendar/google.ts` alongside existing `WriteTaskBlockParams` and `UpdateTaskBlockParams`.

### Task Mutation Hook Points in `tasks.ts`

The existing task routes are stubs (return stub fixtures). Adding `waitUntil` to them is the correct pattern even while they are stubs — it wires the integration now so when real DB mutations land, rescheduling is already triggered. The stub `runScheduleForUser` will simply run with `tasks: []` (existing behavior). No changes to stub data shapes needed.

Routes to hook (all in `apps/api/src/routes/tasks.ts`):
- `POST /v1/tasks` — create
- `PATCH /v1/tasks/:id` — update (properties change)
- `DELETE /v1/tasks/:id` — delete
- `POST /v1/tasks/:id/complete` — complete/uncomplete

For `DELETE /v1/tasks/:id` specifically: after triggering `runScheduleForUser`, the `removeStaleCalendarBlocks` called inside that function will clean up the calendar event. The scheduling trigger is the mechanism — no separate delete-specific cleanup call needed at the route level.

### `removeStaleCalendarBlocks` Integration in `runScheduleForUser`

The `removeStaleCalendarBlocks` function should be called from `runScheduleForUser` after `schedule()` runs, passing the current set of active task IDs:

```typescript
// In apps/api/src/services/scheduling.ts
const result = schedule({ tasks: [], calendarEvents, windowStart: now, windowEnd })

// Remove blocks for tasks no longer in the schedule (deleted/completed tasks)
// TODO(story-impl): pass real task IDs when task loading is wired
const activeTaskIds = result.scheduledBlocks.map(b => b.taskId)
await removeStaleCalendarBlocks(userId, activeTaskIds, env)

await syncScheduledBlocksToCalendar(userId, result.scheduledBlocks, [], env)
```

Import `removeStaleCalendarBlocks` from `./calendar/index.js`.

### Drizzle Pattern (unchanged)

All DB access via `createDb(env.DATABASE_URL ?? '')`. Drizzle ORM with `casing: 'camelCase'`. Use `and()`, `eq()`, `not()`, `inArray()` from `drizzle-orm` for queries. The `notInArray` operator from `drizzle-orm` can be used to find stale blocks:

```typescript
import { notInArray } from 'drizzle-orm'

// Find all blocks for user whose taskId is NOT in active set
const staleBlocks = await db.select()
  .from(taskCalendarBlocksTable)
  .where(
    and(
      eq(taskCalendarBlocksTable.userId, userId),
      activeTaskIds.length > 0
        ? notInArray(taskCalendarBlocksTable.taskId, activeTaskIds)
        : undefined  // if no active tasks, all blocks are stale
    )
  )
```

When `activeTaskIds` is empty (all tasks deleted), `notInArray` cannot be used with an empty array. Use a condition: if `activeTaskIds.length === 0`, query all blocks for the user without the `notInArray` filter.

### Schema: Migration File Naming

Story 3.4 created migration `0006_task_calendar_blocks.sql`. This story's migration must be `0007_google_webhook_channel.sql`. Check `packages/core/src/schema/migrations/meta/_journal.json` to confirm the next migration index is 7.

### API Route Pattern (established)

```typescript
const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()
const webhookRoute = createRoute({
  method: 'post',
  path: '/v1/calendar/webhook',
  // ...
})
// Auth stub: x-user-id header
// Response: c.json(ok({}), 200)
// Error: c.json(err('CODE', 'message'), 401)
```

All route responses use the standard `ok()` / `err()` envelope from `../lib/response.js`. The webhook route does NOT require an `x-user-id` header (it's called by Google, not the app client). The user is looked up from `X-Goog-Channel-Id`.

### NFR-I3 and NFR-I1 Compliance

- NFR-I3 (30s reschedule after task mutation): met by `waitUntil()` pattern — `runScheduleForUser` starts immediately after HTTP response, completes within the Worker's 30-second async lifetime.
- NFR-I1 (60s calendar propagation): met by Google Calendar push webhook → `POST /v1/calendar/webhook` → `waitUntil(runScheduleForUser)` chain. Google push notifications arrive within seconds of a calendar change.

### Webhook Channel Expiration

Google Calendar webhook channels expire after at most 7 days (TTL you set capped at 7 days). The `registerWebhookChannel` function should request `expiration` as 72 hours (`Date.now() + 72 * 60 * 60 * 1000`). Channel renewal (re-registration before expiry) is noted as `TODO(story-impl)` for a later hardening pass — do NOT implement channel auto-renewal in this story.

### Schedule Change Banner Signal

Story 2.12 introduced `GET /v1/schedule-changes` and `POST /v1/schedule-changes` stubs. The rescheduling service can signal a schedule change by writing to whatever state those stubs represent. For now: if `syncScheduledBlocksToCalendar` updates at least one block's times, that constitutes a schedule change. The integration with the banner is already handled client-side — the Flutter today tab polls `GET /v1/schedule-changes`. No additional Flutter changes are needed.

### Files to Create/Modify

**Modify (packages/core schema):**
- `packages/core/src/schema/calendar-connections-google.ts` — add `webhookChannelResourceId`, `webhookChannelExpiry` columns

**New (packages/core migrations):**
- `packages/core/src/schema/migrations/0007_google_webhook_channel.sql`
- `packages/core/src/schema/migrations/meta/0007_snapshot.json` (or equivalent snapshot)
- `packages/core/src/schema/migrations/meta/_journal.json` — add migration entry

**Modify (apps/api services):**
- `apps/api/src/services/calendar/google.ts` — add `deleteTaskBlock()`, `registerWebhookChannel()`
- `apps/api/src/services/calendar/index.ts` — add `removeStaleCalendarBlocks()`
- `apps/api/src/services/scheduling.ts` — call `removeStaleCalendarBlocks()` after `schedule()`

**Modify (apps/api routes):**
- `apps/api/src/routes/tasks.ts` — add `waitUntil(runScheduleForUser(...))` to task mutation handlers
- `apps/api/src/routes/calendar.ts` — add `POST /v1/calendar/webhook`; add `registerWebhookChannel()` call after `POST /v1/calendar/connect`

**Modify (apps/api config):**
- `apps/api/wrangler.jsonc` — add `CALENDAR_WEBHOOK_SECRET` placeholder
- `apps/api/worker-configuration.d.ts` — add `CALENDAR_WEBHOOK_SECRET: string`

**New/Modify (tests):**
- `apps/api/test/routes/calendar.test.ts` — webhook route tests
- `apps/api/test/services/calendar-write.test.ts` — `deleteTaskBlock` tests
- `apps/api/test/routes/tasks.test.ts` (if exists) or new test file — task mutation trigger tests

### Project Structure Notes

- `deleteTaskBlock` and `registerWebhookChannel` live in `apps/api/src/services/calendar/google.ts` — keep all Google-specific functions co-located
- `removeStaleCalendarBlocks` is an orchestrator and belongs in `apps/api/src/services/calendar/index.ts` — mirrors `syncScheduledBlocksToCalendar` pattern
- `POST /v1/calendar/webhook` goes in `apps/api/src/routes/calendar.ts` — not a new route file
- Task mutation triggers go in `apps/api/src/routes/tasks.ts` — no new files needed
- No Flutter changes expected — this is backend-only

### References

- FR12 (auto-rescheduling on change), NFR-I1 (60s calendar propagation), NFR-I3 (30s task mutation reschedule)
- Story 3.4 Dev Notes: token encryption, `loadAndRefreshToken` pattern, `writeTaskBlock`/`updateTaskBlock` patterns — all apply unchanged
- Story 3.3 Dev Notes: no googleapis, fetch() patterns, token guard pattern — all apply unchanged
- `apps/api/src/services/calendar/google.ts` — `loadAndRefreshToken`, `writeTaskBlock`, `updateTaskBlock` to mirror for `deleteTaskBlock`
- `apps/api/src/services/calendar/index.ts` — `syncScheduledBlocksToCalendar` pattern to mirror for `removeStaleCalendarBlocks`
- `apps/api/src/services/scheduling.ts` — `runScheduleForUser` orchestrator to modify
- `apps/api/src/routes/tasks.ts` — task mutation route handlers to add `waitUntil` hooks
- `apps/api/src/routes/calendar.ts` — existing calendar routes to add webhook receiver
- `apps/api/wrangler.jsonc` — Worker bindings and secrets pattern
- `packages/core/src/schema/calendar-connections-google.ts` — schema to extend
- `packages/core/src/schema/task-calendar-blocks.ts` — `taskCalendarBlocksTable` with `(taskId, connectionId)` unique constraint
- Architecture doc §"Queue Message Format" — `waitUntil` is the Workers-native async pattern for sub-queue work
- Architecture doc §`calendar.ts` — "FR46 — connect, list, webhook receiver" — `POST /v1/calendar/webhook` is documented
- Google Calendar REST API: `https://developers.google.com/calendar/api/v3/reference/events/delete`
- Google Calendar Push Notifications: `https://developers.google.com/calendar/api/guides/push`
  - Watch resource: `POST /calendars/{calendarId}/events/watch`
  - Notification headers: `X-Goog-Channel-Id`, `X-Goog-Channel-Token`, `X-Goog-Resource-State`

## Dev Agent Record

### Agent Model Used

_to be filled in_

### Debug Log References

_to be filled in_

### Completion Notes List

_to be filled in_

### File List

_to be filled in_

### Review Findings

_to be filled in_

## Change Log

- 2026-03-31: Story 3.5 created — Auto-Rescheduling on Change
