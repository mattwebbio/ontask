# Story 7.9: Human Dispute Review & Operator Resolution

Status: review

## Story

As an operator,
I want to review disputed AI verification decisions and issue final rulings,
so that users have a fair appeal path and charges are only processed when warranted.

## Acceptance Criteria

1. **Given** a dispute has been filed
   **When** it appears in the operator queue
   **Then** the operator can view: task title, submitted proof media, the AI verification result and its reasoning, and user account context
   **And** the dispute SLA countdown is visible: amber at 18 hours remaining, red at 22 hours elapsed (2 hours remaining), showing time remaining (NFR-R3)

2. **Given** the operator reviews the dispute
   **When** they make a decision
   **Then** they can approve (verify complete → cancel charge) or reject (confirm charge → trigger Stripe processing)
   **And** a decision note (internal) is required before approving or rejecting

3. **Given** the operator decision is recorded
   **When** the resolution is applied
   **Then** the user receives a push notification with the outcome (Story 8.3)
   **And** the charge hold is released: cancelled if approved, processed if rejected
   **And** the resolution timestamp and operator identity are recorded (FR41)
   **And** `tasks.proof_dispute_pending` is set to `false`
   **And** `verification_disputes.status` is updated to `'approved'` or `'rejected'`
   **And** `verification_disputes.operator_note`, `resolved_at`, and `resolved_by_user_id` are populated

## Tasks / Subtasks

---

### Admin API: Bootstrap `apps/admin-api/` for Drizzle + OpenAPI (prerequisite)

The `apps/admin-api/src/index.ts` is a bare Hono stub (`Hello Hono!`). Before adding the disputes route, bootstrap it minimally.

- [x] Add `@hono/zod-openapi`, `drizzle-orm`, `@neondatabase/serverless`, `@ontask/core` as dependencies to `apps/admin-api/package.json`
- [x] Create `apps/admin-api/src/db/index.ts`:
  ```typescript
  import { drizzle } from 'drizzle-orm/neon-http'
  import { neon } from '@neondatabase/serverless'

  export function getDb(databaseUrl: string) {
    return drizzle(neon(databaseUrl), { casing: 'camelCase' })
  }
  ```
- [x] Update `apps/admin-api/src/index.ts` to use `OpenAPIHono` and mount the disputes router:
  ```typescript
  import { OpenAPIHono } from '@hono/zod-openapi'
  import { disputesRouter } from './routes/disputes.js'

  const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()
  app.route('/', disputesRouter)
  export default app
  ```
- [x] Update `apps/admin-api/wrangler.jsonc` to add DATABASE_URL binding comment and Neon binding:
  ```jsonc
  // "vars": {},
  // Workers Secrets (not committed): DATABASE_URL, ADMIN_JWT_SECRET
  ```

---

### Admin API: `GET /admin/v1/disputes` — list pending disputes (AC: 1)

- [x] Create `apps/admin-api/src/routes/disputes.ts`
  - [x] Add `DisputeItemSchema`:
    ```typescript
    const DisputeItemSchema = z.object({
      id: z.string(),
      taskId: z.string(),
      userId: z.string(),
      proofSubmissionId: z.string().nullable(),
      status: z.enum(['pending', 'approved', 'rejected']),
      filedAt: z.string(),
      hoursElapsed: z.number(),             // for SLA colour logic in admin SPA
      slaStatus: z.enum(['ok', 'amber', 'red']),  // ok <18h, amber 18-22h, red ≥22h
    })
    const DisputeListResponseSchema = z.object({ data: z.array(DisputeItemSchema) })
    ```
  - [x] Add `getDisputesRoute` using `createRoute`:
    ```typescript
    const getDisputesRoute = createRoute({
      method: 'get',
      path: '/admin/v1/disputes',
      tags: ['Disputes'],
      summary: 'List pending disputes for operator review',
      description:
        'Returns all verification_disputes with status=pending, ordered by filedAt asc (oldest first). ' +
        'Includes SLA countdown metadata (NFR-R3: 24-hour SLA). ' +
        'Stub implementation (Story 7.9) — real DB query deferred.',
      responses: {
        200: {
          content: { 'application/json': { schema: DisputeListResponseSchema } },
          description: 'List of pending disputes',
        },
      },
    })
    ```
  - [x] Add stub handler returning hardcoded example dispute (use valid RFC-4122 v4 UUID `'00000000-0000-4000-a000-000000000079'` for id):
    ```typescript
    app.openapi(getDisputesRoute, async (c) => {
      // TODO(impl): query verification_disputes WHERE status = 'pending' ORDER BY filed_at ASC
      // TODO(impl): join tasks for task title + proof media URL
      // TODO(impl): join users for user context
      const now = new Date()
      const filedAt = new Date(now.getTime() - 19 * 60 * 60 * 1000).toISOString() // 19h ago = amber
      return c.json(ok([{
        id: '00000000-0000-4000-a000-000000000079',
        taskId: '00000000-0000-4000-a000-000000000001',
        userId: '00000000-0000-4000-a000-000000000002',
        proofSubmissionId: null,
        status: 'pending' as const,
        filedAt,
        hoursElapsed: 19,
        slaStatus: 'amber' as const,
      }]))
    })
    ```

---

### Admin API: `GET /admin/v1/disputes/:id` — dispute detail (AC: 1)

- [x] Add `DisputeDetailSchema` with additional task/proof context fields:
  ```typescript
  const DisputeDetailSchema = z.object({
    id: z.string(),
    taskId: z.string(),
    taskTitle: z.string(),
    userId: z.string(),
    proofSubmissionId: z.string().nullable(),
    proofMediaUrl: z.string().nullable(),
    aiVerificationResult: z.object({
      verified: z.boolean(),
      reason: z.string().nullable(),
    }).nullable(),
    status: z.enum(['pending', 'approved', 'rejected']),
    operatorNote: z.string().nullable(),
    filedAt: z.string(),
    resolvedAt: z.string().nullable(),
    resolvedByUserId: z.string().nullable(),
    hoursElapsed: z.number(),
    slaStatus: z.enum(['ok', 'amber', 'red']),
  })
  const DisputeDetailResponseSchema = z.object({ data: DisputeDetailSchema })
  ```
- [x] Add `getDisputeRoute` and stub handler:
  - Returns 404 with `err('DISPUTE_NOT_FOUND', 'Dispute not found')` when id unknown (for production readiness)
  - Stub returns hardcoded detail for the same example id
  - `// TODO(impl): SELECT from verification_disputes JOIN tasks JOIN proof_submissions WHERE id = ?`

---

### Admin API: `POST /admin/v1/disputes/:id/resolve` — approve or reject (AC: 2, 3)

- [x] Add `ResolveDisputeRequestSchema` and `ResolveDisputeResponseSchema`:
  ```typescript
  const ResolveDisputeRequestSchema = z.object({
    decision: z.enum(['approved', 'rejected']),
    operatorNote: z.string().min(1, 'Decision note is required'),  // required by AC2
  })
  const ResolveDisputeResponseSchema = z.object({
    data: z.object({
      id: z.string(),
      status: z.enum(['approved', 'rejected']),
      resolvedAt: z.string(),
    }),
  })
  ```
- [x] Add `resolveDisputeRoute` using `createRoute`:
  ```typescript
  const resolveDisputeRoute = createRoute({
    method: 'post',
    path: '/admin/v1/disputes/{id}/resolve',
    tags: ['Disputes'],
    summary: 'Approve or reject a pending dispute',
    description:
      'Records operator decision on a verification dispute (FR41). ' +
      'approved: stake charge cancelled, task marked verified complete. ' +
      'rejected: stake charge processed (Stripe), AI decision confirmed. ' +
      'operatorNote is required in both cases. ' +
      'Sets verification_disputes.status, operator_note, resolved_at, resolved_by_user_id. ' +
      'Sets tasks.proof_dispute_pending = false. ' +
      'Sends push notification to user (Story 8.3). ' +
      'Stub implementation (Story 7.9) — real DB writes and Stripe deferred.',
    request: {
      params: z.object({ id: z.string().min(1) }),
      body: { content: { 'application/json': { schema: ResolveDisputeRequestSchema } } },
    },
    responses: {
      200: {
        content: { 'application/json': { schema: ResolveDisputeResponseSchema } },
        description: 'Dispute resolved',
      },
      400: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Missing or invalid decision note',
      },
      404: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Dispute not found',
      },
      409: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Dispute already resolved',
      },
    },
  })
  ```
- [x] Add stub handler:
  ```typescript
  app.openapi(resolveDisputeRoute, async (c) => {
    const { id } = c.req.valid('param')
    const { decision, operatorNote } = c.req.valid('json')
    const resolvedAt = new Date().toISOString()
    // TODO(impl): UPDATE verification_disputes SET status=decision, operator_note=operatorNote,
    //   resolved_at=now(), resolved_by_user_id=operatorId FROM JWT WHERE id=id AND status='pending'
    // TODO(impl): if decision='approved': cancel Stripe PaymentIntent, set tasks.completed_at=now()
    // TODO(impl): if decision='rejected': confirm Stripe PaymentIntent charge
    // TODO(impl): in both cases: UPDATE tasks SET proof_dispute_pending=false WHERE id=taskId
    // TODO(impl): send push notification to user (Story 8.3 APNs integration)
    //   approved: "[Task] — dispute approved. Your stake is safe."
    //   rejected: "[Task] — dispute rejected. $[amount] charged."
    void operatorNote // used in TODO(impl)
    return c.json(ok({ id, status: decision, resolvedAt }))
  })
  ```
- [x] Export `disputesRouter` from `disputes.ts`:
  ```typescript
  export { app as disputesRouter }
  ```

---

### Admin API: `ok()` and `err()` response helpers

The `apps/admin-api` does NOT have `apps/api/src/lib/response.ts`. Add a local copy.

- [x] Create `apps/admin-api/src/lib/response.ts`:
  - Copy the `ok()` and `err()` functions from `apps/api/src/lib/response.ts` (same pattern — no complex logic to reuse via workspace package)
  - Add `ErrorSchema` const at top of `disputes.ts`:
    ```typescript
    const ErrorSchema = z.object({
      error: z.object({ code: z.string(), message: z.string() }),
    })
    ```

---

### Admin API: Tests (AC: 1, 2, 3)

- [x] Create `apps/admin-api/test/routes/disputes.test.ts`
  - [x] Use Vitest (same as `apps/api`) — import pattern: `const app = (await import('../../src/index.js')).default`
  - [x] **Minimum 5 tests:**
    1. `GET /admin/v1/disputes` returns 200 with array containing `status: 'pending'` items
    2. `GET /admin/v1/disputes/:id` returns 200 with dispute detail including `slaStatus` field
    3. `POST /admin/v1/disputes/:id/resolve` with `decision: 'approved'` and `operatorNote` returns 200 with `status: 'approved'`
    4. `POST /admin/v1/disputes/:id/resolve` with `decision: 'rejected'` and `operatorNote` returns 200 with `status: 'rejected'`
    5. `POST /admin/v1/disputes/:id/resolve` without `operatorNote` (or empty string) returns 400
  - [x] Add `"test": "vitest run"` to `apps/admin-api/package.json` scripts
  - [x] Add `vitest` to `apps/admin-api` devDependencies

---

### Flutter: Task card clears "Under review" badge after resolution (AC: 3)

When the operator resolves a dispute, `tasks.proof_dispute_pending` is set to `false` server-side. The Flutter task card already renders the badge based on `task.proofDisputePending`. No new Flutter UI is needed — the badge disappears on the next task list poll/refresh.

- [x] Verify `task_row.dart` already hides the "Under review" `_ProofBadge` when `task.proofDisputePending == false` — this was implemented in Story 7.8
- [x] No changes needed to `task_row.dart` if already correct

---

### Flutter: Dispute resolution push notification handling (AC: 3)

Push notifications are sent by the API at resolution time. Flutter receives them via APNs (Story 8.3). For Story 7.9, only the notification copy must be defined and wired to a task list refresh.

- [x] Add l10n strings to `apps/flutter/lib/core/l10n/strings.dart` under a new section:
  ```dart
  // ── Dispute Resolution Notifications (FR41, FR42, Story 7.9) ────────────────

  /// Push notification body when a dispute is approved (stake cancelled).
  static const String disputeApprovedNotificationBody =
      'Your dispute was approved \u2014 your stake is safe.';

  /// Push notification body when a dispute is rejected (charge processed).
  static const String disputeRejectedNotificationBody =
      'Your dispute was reviewed \u2014 your stake has been charged.';
  ```
  - Note: The actual push sending is deferred to Story 8.3 (APNs infrastructure). These strings are defined now so the notification content is committed alongside the resolution logic.
- [x] No `DisputeRepository` or new data layer needed for this story — resolution is operator-only. The Flutter side is passive (receives push + refreshes task list on next app focus).

---

## Dev Notes

### CRITICAL: Two separate codebases — `apps/admin-api` vs `apps/api`

Story 7.9 lives entirely in `apps/admin-api/` (Hono Operator API Worker at `api.ontaskhq.com/admin/v1/*`) — NOT in `apps/api/`. Story 7.8 added `POST /v1/tasks/{taskId}/disputes` to `apps/api/src/routes/proof.ts` (user-facing). Story 7.9 adds resolution endpoints to `apps/admin-api/src/routes/disputes.ts` (operator-facing).

**Do NOT add dispute resolution routes to `apps/api/src/routes/disputes.ts`** — that file does not exist yet; the architecture lists it under `apps/api/src/routes/` for FR39-41 user-facing dispute filing (deferred real implementation). The operator resolution API lives in `apps/admin-api/`.

### CRITICAL: `apps/admin-api` is a bare stub — must be bootstrapped first

`apps/admin-api/src/index.ts` currently only has:
```typescript
import { Hono } from 'hono'
const app = new Hono()
app.get('/', (c) => { return c.text('Hello Hono!') })
export default app
```
`apps/admin-api/package.json` only has `hono` as a dependency. The bootstrap task above must be completed before the disputes route can be wired. Add `@hono/zod-openapi`, `drizzle-orm`, `@neondatabase/serverless`, `@ontask/core` as dependencies. Use `pnpm add` from the `apps/admin-api` directory.

### CRITICAL: `OpenAPIHono` not plain `Hono` for the disputes router

The `apps/api` uses `OpenAPIHono<{ Bindings: CloudflareBindings }>` with `createRoute` and `app.openapi()`. Use the same pattern in `apps/admin-api`. Plain `Hono` cannot use `createRoute`/`app.openapi()`.

### CRITICAL: `ok()` helper must be created locally in `apps/admin-api`

`apps/admin-api` cannot import from `apps/api`. The `ok()` and `err()` helpers must be duplicated in `apps/admin-api/src/lib/response.ts`. They are simple pure functions — copy them directly. Do NOT attempt a cross-app import.

### CRITICAL: `verificationDisputesTable` schema — columns already exist for Story 7.9

The `packages/core/src/schema/disputes.ts` created in Story 7.8 already includes all columns needed for resolution:
- `status: text().default('pending').notNull()` — update to `'approved'` or `'rejected'`
- `operatorNote: text()` — populate at resolution
- `resolvedAt: timestamp({ withTimezone: true })` — set to `now()`
- `resolvedByUserId: uuid()` — set to operator's userId from JWT

No schema changes needed for this story.

### CRITICAL: `tasks.proof_dispute_pending` already exists — update it on resolution

`packages/core/src/schema/tasks.ts` already has `proofDisputePending: boolean().default(false).notNull()` (Story 7.8). The stub handler comment must include `UPDATE tasks SET proof_dispute_pending=false`. Do NOT add a new column.

### CRITICAL: Stub handler must return valid RFC-4122 v4 UUIDs

Per deferred-work.md: `00000000-0000-0000-0000-...` UUIDs (with version nibble 0) fail RFC-4122. Use version-4 UUIDs: `00000000-0000-4000-a000-000000000079`. The version nibble must be 4.

### CRITICAL: `operatorNote` is required — zod `.min(1)` enforces it

AC2 requires a decision note before approving or rejecting. The `ResolveDisputeRequestSchema` uses `z.string().min(1, 'Decision note is required')`. An empty string `''` must return 400.

### CRITICAL: SLA colour logic for dispute queue UI (NFR-R3)

The `slaStatus` field on the dispute list/detail item drives the admin SPA colour display:
- `'ok'` — elapsed < 18 hours (normal)
- `'amber'` — elapsed 18–22 hours (approaching SLA breach)
- `'red'` — elapsed ≥ 22 hours (2 hours remaining, critical)

The stub handler computes `hoursElapsed` from `now - filedAt`. Real implementation will query the DB. The admin SPA (Story 11.2) consumes this field.

### CRITICAL: 409 Conflict for already-resolved disputes

The resolve endpoint must return 409 if `status != 'pending'`. The stub doesn't need to enforce this (it always accepts), but the `409` response schema must be declared in `createRoute` responses to document the contract for the real implementation.

### Architecture: `apps/admin-api` is a SEPARATE Cloudflare Worker

- Routes: `api.ontaskhq.com/admin/v1/*` (Cloudflare path-based routing)
- Bundle: lighter than `apps/api` — no AI SDK, no Calendar client, no APNs
- Only: Drizzle, Stripe (charge reversal), admin JWT middleware, CORS scoped to `admin.ontaskhq.com`
- CORS: do NOT add `admin.ontaskhq.com` CORS to `apps/api/src/middleware/cors.ts` — that belongs in `apps/admin-api/src/middleware/cors.ts`

The `apps/admin-api` does not yet have middleware/cors.ts or middleware/admin-auth.ts (those are Story 11.1). For this stub story, no auth middleware is needed.

### Architecture: `apps/admin/` admin SPA — stub only for this story

`apps/admin/src/App.tsx` is currently `<h1>OnTask Admin</h1>`. Story 7.9 does NOT build the admin SPA dispute UI — that is Story 11.2. This story only creates the API endpoints.

### Architecture: File locations

```
apps/admin-api/
├── package.json                        # MODIFY — add deps + vitest script
├── src/
│   ├── index.ts                        # MODIFY — OpenAPIHono, mount disputes router
│   ├── db/
│   │   └── index.ts                    # NEW — getDb(databaseUrl) Drizzle init
│   ├── lib/
│   │   └── response.ts                 # NEW — ok(), err() helpers (copy from apps/api)
│   └── routes/
│       └── disputes.ts                 # NEW — GET list, GET detail, POST resolve
└── test/
    └── routes/
        └── disputes.test.ts            # NEW — 5+ vitest tests

apps/flutter/lib/core/l10n/
└── strings.dart                        # MODIFY — add dispute resolution notification strings
```

### Architecture: DB write pattern for real implementation (TODO comments)

The stub handlers must include precise TODO comments so the real implementation (Story 11.2) doesn't need to rediscover the schema:

```typescript
// TODO(impl): db = getDb(c.env.DATABASE_URL)
// TODO(impl): await db.update(verificationDisputesTable)
//   .set({ status: decision, operatorNote, resolvedAt: new Date(), resolvedByUserId: operatorId })
//   .where(and(eq(verificationDisputesTable.id, id), eq(verificationDisputesTable.status, 'pending')))
// TODO(impl): await db.update(tasksTable)
//   .set({ proofDisputePending: false })
//   .where(eq(tasksTable.id, dispute.taskId))
```

Import `verificationDisputesTable` from `@ontask/core`.

### Architecture: Push notification copy (Story 8.3 dependency)

The push notification to the user is deferred to Story 8.3 (APNs infrastructure). The stub must include a `// TODO(impl): send push notification` comment with the copy defined by `AppStrings.disputeApprovedNotificationBody` / `disputeRejectedNotificationBody` added in this story. This ensures the notification copy is committed before the APNs infrastructure story.

### Architecture: Drizzle `casing: 'camelCase'`

The Drizzle instance in `apps/admin-api/src/db/index.ts` MUST use `{ casing: 'camelCase' }`. This is the global project standard. DB column `proof_dispute_pending` → Drizzle field `proofDisputePending`. Missing this option causes silent field mapping failures.

### Context from Prior Stories

- **`verificationDisputesTable`** — defined at `packages/core/src/schema/disputes.ts` (Story 7.8). Exported from `packages/core/src/schema/index.ts`. Import as `import { verificationDisputesTable } from '@ontask/core'`.
- **`proofDisputePending`** — boolean on `tasks` table (`packages/core/src/schema/tasks.ts`) and Flutter `Task` domain model (`apps/flutter/lib/features/tasks/domain/task.dart`). Set to `true` by Story 7.8 dispute filing (TODO stub — not yet wired). Set back to `false` by this story's resolve endpoint.
- **`ok()` response envelope** — `{ data: ... }` shape. All admin API responses follow the same envelope as `apps/api`.
- **`err()` response envelope** — `{ error: { code: 'SCREAMING_SNAKE_CASE', message: '...' } }` shape.
- **Vitest test pattern** — see `apps/api/test/routes/proof.test.ts`: `const app = (await import('../../src/index.js')).default`, then `app.request(path, options)`.
- **`@hono/zod-openapi` version** — `^1.2.4` (same as `apps/api`). Use same version in `apps/admin-api`.
- **`zod` version** — `^4.3.6` (same as `apps/api`). Use same version.
- **`drizzle-orm` version** — `^0.45.2` (same as `apps/api`). Use same version.
- **`@neondatabase/serverless` version** — `^1.0.2` (same as `apps/api`). Use same version.
- **Flutter `DisputeConfirmationView`** — already created at `apps/flutter/lib/features/disputes/presentation/dispute_confirmation_view.dart` (Story 7.8). Story 7.9 does NOT modify it.
- **Flutter `task_row.dart` "Under review" badge** — already renders `_ProofBadge` when `task.proofDisputePending == true` (Story 7.8). No change needed.
- **`withValues(alpha:)` not `withOpacity()`** — consistent across all Flutter stories. Any new Flutter colour adjustments use `.withValues(alpha: value)`.
- **`minimumSize: const Size(44, 44)`** — on all new Flutter interactive elements. Not applicable for this story (no new Flutter UI widgets).

### Deferred Items for This Story

- **Real DB write for resolve** — stub returns 200 but does not update `verification_disputes` or `tasks` tables.
- **Stripe integration** — approved: cancel PaymentIntent; rejected: confirm charge. Deferred to Story 11.2 real implementation.
- **Admin JWT auth middleware** — `apps/admin-api/src/middleware/admin-auth.ts` is Story 11.1. This story's endpoints are unprotected stubs. Add auth middleware in Story 11.1 before production deploy.
- **CORS middleware** — `apps/admin-api/src/middleware/cors.ts` scoped to `admin.ontaskhq.com` is Story 11.1.
- **Admin SPA UI** — dispute review queue + approve/reject form at `apps/admin/src/pages/disputes/` is Story 11.2.
- **Push notification send** — `// TODO(impl): APNs send` in resolve handler. Story 8.3.
- **`POST /v1/tasks/{taskId}/disputes` stub DB write** — the user-facing filing endpoint (Story 7.8) does not yet write to `verification_disputes` or set `proofDisputePending = true`. Both deferred until Story 11.2 real implementation lands.

### Story Checklist

- [x] Story title matches epic definition
- [x] User story statement present (As a / I want / So that)
- [x] Acceptance criteria are testable and complete
- [x] All file paths are absolute/fully qualified
- [x] `apps/admin-api` bootstrap prerequisite task is first
- [x] `ok()` and `err()` helpers created locally (no cross-app import)
- [x] `OpenAPIHono` not plain `Hono` noted
- [x] `verificationDisputesTable` schema already complete — no new columns needed
- [x] `tasks.proof_dispute_pending` already exists — set to `false` on resolve
- [x] Valid RFC-4122 v4 UUIDs in stub data
- [x] `operatorNote` required (min(1)) enforced
- [x] SLA status logic (`ok`/`amber`/`red`) defined
- [x] 409 response for already-resolved disputes in route definition
- [x] `casing: 'camelCase'` on Drizzle init noted
- [x] No admin SPA UI built this story (Story 11.2)
- [x] No admin auth middleware this story (Story 11.1)
- [x] Flutter task card badge clears automatically (no new code)
- [x] Push notification copy defined; send deferred to Story 8.3
- [x] Deferred items documented
- [x] Status set to ready-for-dev

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Added `zod@^4.3.6` to `apps/admin-api` dependencies — was missing from the initial dep list in the story but required since `@hono/zod-openapi` re-exports from it.
- Created `apps/admin-api/worker-configuration.d.ts` with minimal `CloudflareBindings` type — required for `OpenAPIHono<{ Bindings: CloudflareBindings }>` to compile; not generated by wrangler until secrets are configured.
- Created `apps/admin-api/vitest.config.ts` (same pattern as `apps/api`) — required for `pnpm test` to work correctly.

### Completion Notes List

- Bootstrapped `apps/admin-api` with `OpenAPIHono`, Drizzle, and Neon dependencies; replaced bare Hono stub.
- Created `apps/admin-api/src/db/index.ts` with `getDb()` using `casing: 'camelCase'`.
- Created `apps/admin-api/src/lib/response.ts` with `ok()` and `err()` helpers (local copy; no cross-app import).
- Created `apps/admin-api/src/routes/disputes.ts` with three OpenAPI routes: `GET /admin/v1/disputes`, `GET /admin/v1/disputes/{id}`, `POST /admin/v1/disputes/{id}/resolve`.
- Stub handlers return hardcoded RFC-4122 v4 UUID `00000000-0000-4000-a000-000000000079`; all real DB writes, Stripe, and push notification deferred per story spec.
- `operatorNote` enforced as required via `z.string().min(1)` — empty string returns 400.
- SLA status `amber` at 19h elapsed demonstrated in stub data (NFR-R3).
- 409 response declared in `resolveDisputeRoute` responses for contract documentation.
- Flutter `task_row.dart` verified — already hides "Under review" badge when `proofDisputePending == false` (Story 7.8 implementation confirmed at line 370).
- Added `disputeApprovedNotificationBody` and `disputeRejectedNotificationBody` to `apps/flutter/lib/core/l10n/strings.dart`.
- 8 Vitest tests pass (including 5+ required); 195 existing `apps/api` tests pass with no regressions.

### File List

- `apps/admin-api/package.json` — added `@hono/zod-openapi`, `drizzle-orm`, `@neondatabase/serverless`, `@ontask/core`, `zod` deps; `vitest` dev dep; `test` script
- `apps/admin-api/wrangler.jsonc` — added DATABASE_URL / ADMIN_JWT_SECRET comment
- `apps/admin-api/worker-configuration.d.ts` — NEW: minimal CloudflareBindings type declaration
- `apps/admin-api/vitest.config.ts` — NEW: vitest config (matches apps/api pattern)
- `apps/admin-api/src/index.ts` — replaced bare Hono stub with OpenAPIHono + disputes router mount
- `apps/admin-api/src/db/index.ts` — NEW: getDb() Drizzle/Neon init with camelCase casing
- `apps/admin-api/src/lib/response.ts` — NEW: ok() and err() response helpers (local copy)
- `apps/admin-api/src/routes/disputes.ts` — NEW: GET list, GET detail, POST resolve with full OpenAPI schemas
- `apps/admin-api/test/routes/disputes.test.ts` — NEW: 8 Vitest tests covering all 5 required scenarios + extras
- `apps/flutter/lib/core/l10n/strings.dart` — added disputeApprovedNotificationBody and disputeRejectedNotificationBody

### Change Log

- 2026-04-01: Story 7.9 implemented — bootstrapped apps/admin-api with OpenAPIHono + Drizzle; added GET/GET/POST dispute resolution stub endpoints with SLA metadata and required operatorNote validation; added Flutter dispute resolution notification strings.
