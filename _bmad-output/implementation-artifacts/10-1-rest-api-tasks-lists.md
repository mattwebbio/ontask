# Story 10.1: REST API — Tasks & Lists

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an external developer,
I want to create, read, update, and delete tasks and lists via a typed REST API,
So that I can integrate On Task into my own tools and workflows.

## Acceptance Criteria

1. **Given** the REST API is implemented
   **When** a developer makes task or list requests
   **Then** all ten endpoints are available with full `@hono/zod-openapi` schemas:
   `GET /v1/tasks`, `POST /v1/tasks`, `GET /v1/tasks/:id`, `PATCH /v1/tasks/:id`, `DELETE /v1/tasks/:id`,
   `GET /v1/lists`, `POST /v1/lists`, `GET /v1/lists/:id`, `PATCH /v1/lists/:id`, `DELETE /v1/lists/:id` (FR44)
   **And** all endpoints respond within 500ms at p95 under normal load (NFR-P6)

2. **Given** the OpenAPI spec endpoint is implemented
   **When** a developer calls `GET /v1/openapi.json`
   **Then** the auto-generated OpenAPI spec is served at that URL (in addition to the existing `/v1/doc` endpoint)

3. **Given** a list endpoint is called
   **When** it returns multiple items
   **Then** pagination uses cursor-based format only — no offset/limit (ARCH-14)
   **And** rate limit headers are included on every response: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` (FR80, NFR-I6)

---

## Tasks / Subtasks

---

### Task 1: Audit existing tasks and lists endpoints against AC requirements (AC: 1)

`apps/api/src/routes/tasks.ts` and `apps/api/src/routes/lists.ts` already contain substantial stub implementations from earlier epics. This task audits what is already in place and identifies gaps.

**Endpoints already implemented in `tasks.ts`:**
- `POST /v1/tasks` — exists, returns 201
- `GET /v1/tasks` — exists, cursor pagination present
- `GET /v1/tasks/:id` — exists (registered as catch-all after named routes)
- `PATCH /v1/tasks/:id` — exists
- `DELETE /v1/tasks/:id` — exists (hard delete, returns 204)

**Endpoints already implemented in `lists.ts`:**
- `POST /v1/lists` — exists, returns 201
- `GET /v1/lists` — exists, cursor pagination present
- `GET /v1/lists/:id` — exists (returns list with sections)
- `PATCH /v1/lists/:id` — exists
- `DELETE /v1/lists/:id/archive` — exists but routes to `/archive` sub-path, NOT `DELETE /v1/lists/:id`

**Gap identified — `DELETE /v1/lists/:id` is missing.** The epic requires `DELETE /v1/lists/:id`. The existing `DELETE /v1/lists/{id}/archive` (soft delete) is a different endpoint. A new `DELETE /v1/lists/{id}` hard-delete route must be added.

- [x] Read `apps/api/src/routes/tasks.ts` and `apps/api/src/routes/lists.ts` end-to-end to confirm the above analysis
- [x] Confirm `DELETE /v1/tasks/:id` and `DELETE /v1/lists/:id` are both properly declared and accessible
- [x] Note the `DELETE /v1/lists/{id}` gap and proceed to Task 2

**Files to read:** `apps/api/src/routes/tasks.ts`, `apps/api/src/routes/lists.ts`

---

### Task 2: Add `DELETE /v1/lists/:id` hard-delete endpoint (AC: 1)

The existing lists router has `DELETE /v1/lists/{id}/archive` (soft delete) but no hard-delete at `DELETE /v1/lists/{id}`. Story 10.1 requires the latter.

**IMPORTANT — Route ordering:** Register `DELETE /v1/lists/{id}` AFTER `DELETE /v1/lists/{id}/archive` to prevent Hono from matching "archive" as a list ID. The architecture requires specific sub-resource routes before parameterised catch-alls.

- [x] In `apps/api/src/routes/lists.ts`, add the route definition AFTER the existing `archiveListRoute` registration block:

```typescript
// ── DELETE /v1/lists/:id ─────────────────────────────────────────────────────
// IMPORTANT: Registered AFTER DELETE /v1/lists/{id}/archive to prevent Hono
// from matching "archive" as a list ID (catch-all comes after specific paths).

const deleteListRoute = createRoute({
  method: 'delete',
  path: '/v1/lists/{id}',
  tags: ['Lists'],
  summary: 'Hard-delete a list (FR44)',
  description:
    'Permanently removes a list and cascade-deletes its tasks. ' +
    'Prefer DELETE /v1/lists/{id}/archive for soft-delete (reversible). ' +
    'Stub; real implementation cascades via Drizzle.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'List deleted' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'List not found' },
  },
})

app.openapi(deleteListRoute, async (c) => {
  // TODO(impl): hard-delete list and cascade to tasks via Drizzle; verify ownership from JWT
  return new Response(null, { status: 204 })
})
```

- [x] Insert this block immediately before `export { app as listsRouter }` at the bottom of the file

**File to modify:** `apps/api/src/routes/lists.ts`

---

### Task 3: Add `GET /v1/openapi.json` alias endpoint (AC: 2)

The existing API serves its OpenAPI spec at `GET /v1/doc` (configured in `apps/api/src/index.ts` line 83). Story 10.1 requires it to also be served at `GET /v1/openapi.json` per the acceptance criteria.

The simplest approach is to add a second `app.doc()` call in `index.ts` pointing to `/v1/openapi.json`:

- [x] In `apps/api/src/index.ts`, after the existing `app.doc('/v1/doc', ...)` block, add:

```typescript
// Alias: OpenAPI spec at /v1/openapi.json (Story 10.1 — FR44)
// The canonical doc endpoint /v1/doc remains unchanged.
app.doc('/v1/openapi.json', {
  openapi: '3.0.0',
  info: {
    title: 'OnTask API',
    version: '1.0.0',
    description: 'OnTask REST API — task management platform',
  },
})
```

**File to modify:** `apps/api/src/index.ts`

---

### Task 4: Add rate limit header middleware (AC: 3)

The architecture specifies a `rate-limit.ts` middleware file at `apps/api/src/middleware/rate-limit.ts` (see architecture.md line 745). This story requires rate limit headers (`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`) on every response (FR80, NFR-I6).

**Current state:** `apps/api/src/middleware/` only contains `cors.ts` — `rate-limit.ts` does not yet exist.

**Story 10.1 scope:** Add a stub rate limit middleware that injects the required headers on every response. The actual rate limit enforcement (429 responses, per-user counters) belongs to Story 10.2. This task only adds the header middleware.

- [x] Create `apps/api/src/middleware/rate-limit.ts`:

```typescript
import type { OpenAPIHono } from '@hono/zod-openapi'

// ── Rate limit header middleware (FR80, NFR-I6) ────────────────────────────
// Injects X-RateLimit-* headers on every response for Story 10.1.
// Actual enforcement (429 responses, per-user counters) comes in Story 10.2.
//
// Stub values: 1000 req/hr limit, resets at top of next hour.

export function applyRateLimitHeaders(app: OpenAPIHono<{ Bindings: CloudflareBindings }>): void {
  app.use('*', async (c, next) => {
    await next()
    // Stub: fixed values until real counters land in Story 10.2
    const resetTs = Math.ceil(Date.now() / 3_600_000) * 3_600 // top of next hour (Unix seconds)
    c.res.headers.set('X-RateLimit-Limit', '1000')
    c.res.headers.set('X-RateLimit-Remaining', '999')
    c.res.headers.set('X-RateLimit-Reset', String(resetTs))
  })
}
```

- [x] In `apps/api/src/index.ts`, import and apply the middleware:

```typescript
import { applyRateLimitHeaders } from './middleware/rate-limit.js'
```

Call `applyRateLimitHeaders(app)` immediately after `applyScopedCors(app)` and before route mounting:

```typescript
// ── Rate limit headers (Story 10.1 — FR80, NFR-I6) ────────────────────────
applyRateLimitHeaders(app)
```

**IMPORTANT — Middleware ordering:** The `applyRateLimitHeaders` call MUST come after `applyScopedCors(app)` and BEFORE the route mounts. Hono processes middleware in registration order — if routes are registered first, the middleware will not intercept their responses correctly.

**Files to create/modify:**
- Create: `apps/api/src/middleware/rate-limit.ts`
- Modify: `apps/api/src/index.ts`

---

### Task 5: API tests for Story 10.1 additions (AC: 1, 2, 3)

Add tests covering: `DELETE /v1/lists/:id`, `GET /v1/openapi.json`, and rate limit headers. Existing tests for `GET/POST/PATCH /v1/tasks` and `GET/POST/PATCH /v1/lists` are already in place and must not be broken.

- [x] Add a new test file `apps/api/test/routes/rest-api-10-1.test.ts`:

```typescript
import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// Story 10.1: REST API — Tasks & Lists (FR44, FR80, NFR-I6, ARCH-14)

describe('Story 10.1 — DELETE /v1/lists/:id', () => {
  it('returns 204 for hard-delete of a list', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001', {
      method: 'DELETE',
    })
    expect(res.status).toBe(204)
  })

  it('hard-delete returns no body', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001', {
      method: 'DELETE',
    })
    const body = await res.text()
    expect(body).toBe('')
  })
})

describe('Story 10.1 — GET /v1/openapi.json', () => {
  it('serves OpenAPI spec at /v1/openapi.json', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    expect(res.status).toBe(200)
  })

  it('/v1/openapi.json response is valid JSON with openapi field', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    const body = await res.json() as Record<string, unknown>
    expect(body).toHaveProperty('openapi')
    expect(body.openapi).toBe('3.0.0')
  })

  it('/v1/openapi.json info.title matches expected value', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    const body = await res.json() as { info: { title: string } }
    expect(body.info.title).toBe('OnTask API')
  })
})

describe('Story 10.1 — X-RateLimit-* headers (FR80, NFR-I6)', () => {
  it('GET /v1/tasks includes X-RateLimit-Limit header', async () => {
    const res = await app.request('/v1/tasks', { method: 'GET' })
    expect(res.headers.get('X-RateLimit-Limit')).toBeTruthy()
  })

  it('GET /v1/lists includes X-RateLimit-Remaining header', async () => {
    const res = await app.request('/v1/lists', { method: 'GET' })
    expect(res.headers.get('X-RateLimit-Remaining')).toBeTruthy()
  })

  it('POST /v1/tasks includes X-RateLimit-Reset header', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Rate limit header test task' }),
    })
    expect(res.headers.get('X-RateLimit-Reset')).toBeTruthy()
  })

  it('rate limit header values are numeric strings', async () => {
    const res = await app.request('/v1/tasks', { method: 'GET' })
    const limit = res.headers.get('X-RateLimit-Limit')
    const remaining = res.headers.get('X-RateLimit-Remaining')
    const reset = res.headers.get('X-RateLimit-Reset')
    expect(Number(limit)).toBeGreaterThan(0)
    expect(Number(remaining)).toBeGreaterThanOrEqual(0)
    expect(Number(reset)).toBeGreaterThan(0)
  })
})
```

- [x] **Minimum 9 new tests** added in this file
- [x] **Do not break existing tests.** The `tasks.ts` test file requires a scheduling service mock; the new test file imports `app` directly without the scheduling mock since it doesn't exercise task mutation routes in isolation — if needed, add the same mock pattern at the top:

```typescript
import { vi } from 'vitest'
vi.mock('../../src/services/scheduling.js', () => ({
  runScheduleForUser: vi.fn().mockResolvedValue({}),
}))
```

Add this mock if the test runner complains about `runScheduleForUser` not being available.

- [x] Run `pnpm test --filter apps/api` to verify all tests pass

**File to create:** `apps/api/test/routes/rest-api-10-1.test.ts`

---

## Developer Context

### Critical Anti-Patterns to Avoid

1. **DO NOT** add Drizzle imports or `createDb` to any route file — the TS2345 `PgTableWithColumns` typecheck incompatibility causes CI failures. All DB work stays as `TODO(impl)` stubs. This is a project-wide constraint propagated from Story 9.6 and all prior API stories.

2. **DO NOT** modify `.g.dart` files — CI does not run `build_runner`. This story is API-only but the constraint applies globally.

3. **DO NOT** use `impl(X.Y)` prefix style in comments — use `TODO(impl):` as the standard stub comment prefix (see Story 9.6 review finding about incorrect prefix).

4. **DO NOT** add offset/limit pagination — cursor-based only per ARCH-14. Both existing `tasks.ts` and `lists.ts` correctly use `cursor + hasMore`; do not deviate.

5. **DO NOT** create custom response shapes — always use `ok()`, `list()`, `err()` from `apps/api/src/lib/response.ts`. This is enforced by the architecture.

6. **DO NOT** skip `@hono/zod-openapi` schema declaration on new routes — every route must use `createRoute()` before the handler. No untyped routes (architecture.md line 456).

7. **DO NOT** register new routes in the wrong order — Hono matches routes in registration order. Sub-resource paths (`/archive`, `/settings`, `/proof-mode`) must be registered BEFORE their parameterised parent catch-all (`/{id}`). See the extensive registration-order comments in both `tasks.ts` and `lists.ts`.

8. **DO NOT** register `applyRateLimitHeaders` after routes — middleware must be registered before routes in Hono.

### Architecture & Patterns

**Route file structure** (established pattern from `tasks.ts` and `lists.ts`):
```typescript
import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// Schema definitions (top of file)
// Stub fixture functions (stubTask, stubList pattern)
// Named/specific routes (registered BEFORE parameterised /{id} routes)
// Parameterised /{id} routes (catch-alls — registered LAST)

export { app as <resource>Router }
```

**Stub fixture pattern** (from existing routes):
```typescript
function stubList(overrides: Partial<z.infer<typeof listSchema>> = {}): z.infer<typeof listSchema> {
  return { /* defaults */ ...overrides }
}
```

**Response helpers** (from `apps/api/src/lib/response.ts`):
- `ok(data)` → `{ data }`
- `list(items, cursor, hasMore)` → `{ data: [...], pagination: { cursor, hasMore } }`
- `err(code, message, details?)` → `{ error: { code, message } }`

**204 No Content pattern** (established in `deleteTaskRoute`, `archiveListRoute`):
```typescript
return new Response(null, { status: 204 })
```
Never return `c.json(null, 204)` — the existing pattern uses `new Response(null, { status: 204 })` consistently.

**Middleware registration pattern** (from `cors.ts` / `index.ts`):
```typescript
// In middleware file:
export function applyXxx(app: OpenAPIHono<{ Bindings: CloudflareBindings }>): void {
  app.use('*', async (c, next) => { await next(); /* mutate response */ })
}

// In index.ts:
import { applyXxx } from './middleware/xxx.js'
applyXxx(app)  // before routes
```
This is the exact pattern used by `applyScopedCors` — replicate it for `applyRateLimitHeaders`.

**OpenAPI spec endpoint** (from `index.ts` line 83–90):
```typescript
app.doc('/v1/doc', { openapi: '3.0.0', info: { title: '...', version: '...', ... } })
```
The new `/v1/openapi.json` endpoint uses the same `app.doc()` call — same spec, different URL.

**Hono route ordering (CRITICAL):**
The following pattern is established and must be followed:
```typescript
// index.ts — bulk routes before task routes (prevents /tasks/bulk/complete → id='bulk')
app.route('/', bulkOperationsRouter)  // BEFORE
app.route('/', tasksRouter)

// Within route files — specific before parameterised:
// Correct order in tasks.ts:
// POST /v1/tasks/parse   (named)
// POST /v1/tasks/chat    (named)
// GET /v1/tasks/today    (named)
// GET /v1/tasks/search   (named)
// GET /v1/tasks/{id}/proof  (sub-resource)
// GET /v1/tasks/{id}     (catch-all LAST)
// PATCH /v1/tasks/{id}/proof-mode  (sub-resource before catch-all)
// PATCH /v1/tasks/{id}   (catch-all)
// DELETE /v1/tasks/{id}/archive  (sub-resource before catch-all)
// DELETE /v1/tasks/{id}  (catch-all)
```

### File Locations Summary

| File | Action | Purpose |
|---|---|---|
| `apps/api/src/routes/lists.ts` | Modify | Add `DELETE /v1/lists/{id}` hard-delete endpoint |
| `apps/api/src/index.ts` | Modify | Add `/v1/openapi.json` alias + import+apply rate-limit middleware |
| `apps/api/src/middleware/rate-limit.ts` | Create | Rate limit header injection middleware stub |
| `apps/api/test/routes/rest-api-10-1.test.ts` | Create | 9+ tests for Story 10.1 additions |

### Existing Infrastructure — What Is Already Done

These endpoints are fully implemented as stubs in `tasks.ts` and `lists.ts` and need NO modification for Story 10.1:

**tasks.ts (complete for Story 10.1):**
- `POST /v1/tasks` — 201, stub task, fire-and-forget rescheduling
- `GET /v1/tasks` — 200, cursor pagination, 3 stub tasks (including assigned + proof variants)
- `GET /v1/tasks/:id` — 200, single stub task
- `PATCH /v1/tasks/:id` — 200, partial update with rescheduling
- `DELETE /v1/tasks/:id` — 204, hard delete with rescheduling

**lists.ts (nearly complete — only missing `DELETE /v1/lists/:id`):**
- `POST /v1/lists` — 201, stub list
- `GET /v1/lists` — 200, cursor pagination
- `GET /v1/lists/:id` — 200, list with sections array
- `PATCH /v1/lists/:id` — 200, partial update
- `DELETE /v1/lists/:id/archive` — 204, soft delete (different from required hard-delete)

### Existing Test Infrastructure

**Test count before Story 10.1:** 202 tests across all API test files (counted 2026-04-01).

**Expected after Story 10.1:** 202 + 9 = 211+ tests.

**Test file patterns:**
- Import: `import app from '../../src/index.js'` (or `(await import('...')).default` when mocking)
- No auth headers required for stubs — consistent with all existing patterns
- `type AnyJson = any` pattern used in tasks.test.ts; prefer typed cast where possible
- Scheduling mock required for test files that exercise task mutation routes:
  ```typescript
  vi.mock('../../src/services/scheduling.js', () => ({
    runScheduleForUser: vi.fn().mockResolvedValue({}),
  }))
  const app = (await import('../../src/index.js')).default
  ```

**Existing test files for reference:**
- `apps/api/test/routes/tasks.test.ts` — 24 tests, covers all 5 task CRUD endpoints
- `apps/api/test/routes/lists.test.ts` — includes Story 9.6 tests at the bottom (296 total in file including 9.6 block)

### Cross-Story Context

- **Epic 10 overview:** Story 10.1 covers Tasks & Lists REST API. Story 10.2 covers scheduling endpoints + real rate limit enforcement (429 responses). Stories 10.3–10.5 cover the MCP server. Story 10.1 is intentionally scoped to the basic CRUD endpoints + stub rate limit headers; do NOT pre-implement Story 10.2 content.

- **Rate limit enforcement is Story 10.2 scope:** The `X-RateLimit-*` headers added here are stub values. The 429 response, per-user counters, and rate limit configuration in the OpenAPI spec are explicitly deferred to Story 10.2.

- **`rate-limit.ts` middleware file:** The architecture.md lists `rate-limit.ts` in the middleware folder as the implementation location for FR80/NFR-I6. This story creates the file as a stub; Story 10.2 will expand it with real enforcement.

- **`DELETE /v1/lists/:id` vs `/archive`:** The existing `DELETE /v1/lists/{id}/archive` is a soft delete (sets `archivedAt`). The new `DELETE /v1/lists/{id}` is a hard delete (cascade removes list and tasks). Both coexist — they serve different purposes and both are correct.

- **FR71 shared with Epic 10:** FR71 (contract status) is shared between Epic 6 (commitment contracts) and Epic 10 (public API endpoint). Story 10.1 does not touch contracts — that belongs to Story 10.5.

### API Spec / OpenAPI Notes

- The existing `/v1/doc` endpoint is served by `app.doc('/v1/doc', ...)` in `index.ts`. The new `/v1/openapi.json` is an additional alias to the same spec data — same `app.doc()` call with a different path.
- Both endpoints will be live simultaneously; neither replaces the other.
- `@hono/zod-openapi` auto-generates the spec from all `createRoute()` definitions registered on the app. No manual spec editing is needed.

### Drizzle TS2345 Stub Pattern (propagated from Story 9.6)

From Story 9.6 dev notes: **DO NOT add Drizzle imports or `createDb` to any route file.** The TS2345 `PgTableWithColumns` typecheck incompatibility causes CI failures. This constraint applies to ALL route files across the project. All DB access remains as `TODO(impl):` comments.

The correct stub pattern is:
```typescript
app.openapi(someRoute, async (c) => {
  // TODO(impl): real DB query via Drizzle once auth middleware is wired
  return c.json(ok(stubSomething({ id: c.req.valid('param').id })), 200)
})
```

### Test Run Commands

```bash
# Run all API tests
pnpm test --filter apps/api

# Run only new tests (faster iteration)
pnpm test --filter apps/api -- test/routes/rest-api-10-1.test.ts
```

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- Task 1: Audited `tasks.ts` and `lists.ts`. Confirmed all 5 task CRUD endpoints present. Identified gap: `DELETE /v1/lists/:id` hard-delete missing (only `DELETE /v1/lists/:id/archive` soft-delete existed).
- Task 2: Added `deleteListRoute` with `createRoute()` + `app.openapi()` handler in `lists.ts`, registered AFTER `archiveListRoute` per route-ordering requirement. Returns 204 with no body using `new Response(null, { status: 204 })` pattern.
- Task 3: Added `app.doc('/v1/openapi.json', ...)` alias in `index.ts` immediately after the existing `/v1/doc` registration. Both endpoints serve the same OpenAPI 3.0.0 spec simultaneously.
- Task 4: Created `apps/api/src/middleware/rate-limit.ts` with `applyRateLimitHeaders()` function using stub values (limit=1000, remaining=999, reset=top of next hour). Imported and applied in `index.ts` AFTER `applyScopedCors(app)` and BEFORE route mounts, per Hono middleware ordering requirements.
- Task 5: Created `apps/api/test/routes/rest-api-10-1.test.ts` with 9 tests covering DELETE /v1/lists/:id, GET /v1/openapi.json, and X-RateLimit-* header injection. All 305 tests pass (296 pre-existing + 9 new).

### File List

- `apps/api/src/routes/lists.ts` — modified: added `DELETE /v1/lists/{id}` hard-delete endpoint
- `apps/api/src/index.ts` — modified: added `/v1/openapi.json` alias, imported and applied rate-limit middleware
- `apps/api/src/middleware/rate-limit.ts` — created: rate limit header injection middleware stub
- `apps/api/test/routes/rest-api-10-1.test.ts` — created: 9 tests for Story 10.1 additions

### Review Findings

_to be filled by code review_

## Change Log

- 2026-04-01: Story 10.1 created — REST API Tasks & Lists. Audits existing task/list stubs, identifies missing `DELETE /v1/lists/:id` hard-delete, adds `GET /v1/openapi.json` alias endpoint, stubs `X-RateLimit-*` header middleware. Status → ready-for-dev.
- 2026-04-01: Story 10.1 implemented — Added `DELETE /v1/lists/{id}` hard-delete endpoint, `GET /v1/openapi.json` alias, rate-limit header middleware stub, and 9 new tests. All 305 tests pass. Status → review.
