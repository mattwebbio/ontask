# Story 11.4: User Impersonation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an operator,
I want to impersonate user accounts for troubleshooting with a full immutable audit trail,
So that support issues can be investigated without asking the user to walk me through their screen.

## Acceptance Criteria

1. **Given** an operator opens a user account in the Users section
   **When** they initiate impersonation
   **Then** the app view switches to show the user's account state (FR53)
   **And** a persistent banner is shown at the top of every screen: "Viewing as [user@email.com] — [operator@ontaskhq.com]"

2. **Given** impersonation is active
   **When** any action is taken
   **Then** every action is logged in an immutable audit trail with: timestamp, operator identity, user account, and action taken (NFR-S6)
   **And** the audit trail is append-only — entries cannot be modified or deleted

3. **Given** an impersonation session is running
   **When** 30 minutes have elapsed
   **Then** the session automatically ends and the operator is returned to their own account
   **And** a "session timeout" entry is appended to the audit log

## Tasks / Subtasks

---

### Task 1: Define `operator_impersonation_logs` DB schema in `@ontask/core` (AC: 2, 3)

The audit log must be append-only (no UPDATE or DELETE). This story creates the schema; real DB writes are gated by `DATABASE_URL` availability.

**New file:** `packages/core/src/schema/operator-impersonation-logs.ts`

```typescript
import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Operator impersonation log ─────────────────────────────────────────────────
// Immutable append-only audit log for all operator-initiated impersonation sessions
// and actions taken within them.
// Rows are NEVER updated or deleted (NFR-S6 immutable audit trail).

export const operatorImpersonationLogsTable = pgTable('operator_impersonation_logs', {
  id: uuid().primaryKey().defaultRandom(),
  sessionId: uuid().notNull(),              // groups all events for one impersonation session
  userId: uuid().notNull(),                 // the user being impersonated
  operatorEmail: text().notNull(),          // (c as any).get('operatorEmail') — email string
  // TODO(impl): operatorEmail stores text string — no operator UUID yet (same pattern as operator_refund_logs)
  actionType: text().notNull(),             // 'session_start' | 'session_end' | 'session_timeout' | 'action_taken'
  actionDetail: text(),                     // optional description of what action was taken
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  // NOTE: No updatedAt — row is intentionally immutable. Never add UPDATE logic to this table.
})
```

**Export from `packages/core/src/schema/index.ts`:**
Add: `export { operatorImpersonationLogsTable } from './operator-impersonation-logs.js'`

**Subtasks:**
- [x] Create `packages/core/src/schema/operator-impersonation-logs.ts`
- [x] Add export to `packages/core/src/schema/index.ts`

---

### Task 2: Add impersonation routes to `apps/admin-api` (AC: 1, 2, 3)

**New file:** `apps/admin-api/src/routes/impersonation.ts`

Model this file exactly after `apps/admin-api/src/routes/charges.ts` — same import pattern, same `OpenAPIHono`, same `ok()`/`err()` helpers, same stub-with-TODO structure.

#### Endpoints to implement

**`POST /admin/v1/users/:userId/impersonate`** — start an impersonation session

```typescript
// Request schema (no body required — userId comes from path param)
const StartImpersonationResponseSchema = z.object({
  data: z.object({
    sessionId: z.string(),         // UUID for this impersonation session
    userId: z.string(),            // the user being impersonated
    operatorEmail: z.string(),     // echoed back for banner display
    userEmail: z.string(),         // TODO(impl): fetch from users table once queryable
    expiresAt: z.string(),         // ISO timestamp: now + 30 minutes
    startedAt: z.string(),         // ISO timestamp
  }),
})

// DB flow (when DATABASE_URL available):
// 1. Guard: if (!operatorEmail) return 500 — same pattern as charges.ts
// 2. Generate sessionId = crypto.randomUUID()
// 3. Compute expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString()
// 4. TODO(impl): Fetch userEmail from users table WHERE id = :userId — return 404 USER_NOT_FOUND if missing
// 5. Insert into operator_impersonation_logs: { sessionId, userId, operatorEmail, actionType: 'session_start', actionDetail: null }
// 6. Return { sessionId, userId, operatorEmail, userEmail: 'TODO(impl)', expiresAt, startedAt }

// Stub fixture (no DATABASE_URL):
// Generate sessionId = crypto.randomUUID()
// Return stub response with userEmail: 'user@example.com' (TODO(impl) comment)
// expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString()
// TODO(impl): Replace stub userEmail with real users table lookup

// Error responses:
// 500 — operatorEmail not present (missing auth context)
```

**`POST /admin/v1/impersonation/:sessionId/end`** — end an impersonation session

```typescript
// Request schema: no body required
const EndImpersonationResponseSchema = z.object({
  data: z.object({
    sessionId: z.string(),
    endedAt: z.string(),
    reason: z.enum(['operator_ended', 'session_timeout']),
  }),
})

// DB flow (when DATABASE_URL available):
// 1. Guard: if (!operatorEmail) return 500
// 2. Insert into operator_impersonation_logs: { sessionId, userId (from session), operatorEmail, actionType: 'session_end', actionDetail: 'operator_ended' }
// 3. Return { sessionId, endedAt, reason: 'operator_ended' }
// NOTE: No session state is stored server-side in this story — sessionId is treated as opaque.
// TODO(impl): In a real implementation, maintain a sessions table to validate active sessions and enforce timeout.

// Stub fixture (no DATABASE_URL):
// Return { sessionId, endedAt: new Date().toISOString(), reason: 'operator_ended' }

// Error responses:
// 500 — operatorEmail not present
```

**`POST /admin/v1/impersonation/:sessionId/log-action`** — log an action taken during impersonation

```typescript
// Request schema:
const LogActionRequestSchema = z.object({
  actionDetail: z.string().min(1, 'Action detail is required'),
})

const LogActionResponseSchema = z.object({
  data: z.object({
    logId: z.string(),
    sessionId: z.string(),
    loggedAt: z.string(),
  }),
})

// DB flow (when DATABASE_URL available):
// 1. Guard: if (!operatorEmail) return 500
// 2. Insert into operator_impersonation_logs: { sessionId, userId: body.userId (TODO), operatorEmail, actionType: 'action_taken', actionDetail: body.actionDetail }
// 3. Return { logId, sessionId, loggedAt }
// NOTE: userId for the log — the admin SPA must pass it. Add userId to request body:
// const LogActionRequestSchema = z.object({
//   userId: z.string(),          // user being impersonated in this session
//   actionDetail: z.string().min(1, 'Action detail is required'),
// })
// TODO(impl): Once sessions table exists, look up userId from sessionId instead of requiring it in body.

// Stub fixture (no DATABASE_URL):
// Return { logId: crypto.randomUUID(), sessionId, loggedAt: new Date().toISOString() }

// Error responses:
// 400 — actionDetail is empty
// 500 — operatorEmail not present
```

**Subtasks:**
- [x] Create `apps/admin-api/src/routes/impersonation.ts` with all `createRoute` + `app.openapi()` definitions and Zod schemas
- [x] Import `operatorImpersonationLogsTable` from `@ontask/core`
- [x] Wire stub fixture fallback (no DATABASE_URL) for all endpoints with `TODO(impl)` markers
- [x] Guard missing `operatorEmail`: return 500 in all handlers if not present

---

### Task 3: Register routes and auth guard in `apps/admin-api/src/index.ts` (AC: 1, 2, 3)

**File to modify:** `apps/admin-api/src/index.ts`

Following the exact pattern of existing auth guards (currently lines 22–25):

```typescript
// Add after existing charge guards:
app.use('/admin/v1/impersonation/*', adminAuthMiddleware)

// Import and mount router (after chargesRouter):
import { impersonationRouter } from './routes/impersonation.js'
app.route('/', impersonationRouter)
```

The `/admin/v1/users/:userId/impersonate` path is already covered by the existing `/admin/v1/users/*` wildcard guard (line 24). The `/admin/v1/impersonation/*` guard covers the end-session and log-action endpoints.

**Subtasks:**
- [x] Add auth guard: `app.use('/admin/v1/impersonation/*', adminAuthMiddleware)`
- [x] Import `impersonationRouter` and mount with `app.route('/', impersonationRouter)`

---

### Task 4: Build impersonation UI in `apps/admin` (AC: 1, 2, 3)

#### 4a: Add "Impersonate" button to `apps/admin/src/pages/UsersPage.tsx`

**File to modify:** `apps/admin/src/pages/UsersPage.tsx`

The current `UsersPage.tsx` has a user-ID input form that navigates to `/users/:userId/charges`. Add a second button: "Impersonate User".

```typescript
// Add second action button alongside "View Charges":
// Button: "Impersonate User"
// On click: POST /admin/v1/users/:userId/impersonate
// On success (200): store session data in sessionStorage (not localStorage — clears on tab close)
//   key: 'impersonationSession'
//   value: JSON.stringify({ sessionId, userId, userEmail, operatorEmail, expiresAt })
//   Then navigate to /users/:userId/impersonate-view
// On 404: show "User not found"
// On 500: show "Failed to start impersonation session"
// setLoading(false) in ALL early-return error paths (Story 11.2 lesson)
```

#### 4b: New file `apps/admin/src/pages/ImpersonateUserPage.tsx`

This is the operator's view of the impersonated user account — read-only data view + session controls.

```typescript
// Route: /users/:userId/impersonate-view
// useParams() to extract :userId
// On mount: read impersonationSession from sessionStorage
//   If no session found: navigate('/users') immediately
//   If session.expiresAt < Date.now(): show "Session expired" message + auto-end + navigate('/users')

// ── Persistent impersonation banner ───────────────────────────────────────────
// Shown at top of page — always visible (AC1)
// "Viewing as [session.userEmail] — [session.operatorEmail]"
// Banner style: background #e74c3c (red), color #fff, padding '0.6rem 1.5rem', fontSize '0.9rem'
// Include: "Session expires at [time]" + "End Impersonation" button

// ── User data view ─────────────────────────────────────────────────────────────
// For this story, display a simple read-only view:
//   - User ID (from params)
//   - User Email (from session data)
//   - Session ID
//   - Session started / expires at
//   - Link back to charge history: navigate(`/users/${userId}/charges`)
// TODO(impl): Replace with full read-only user account data view once user data APIs are available

// ── Session timeout auto-end ───────────────────────────────────────────────────
// On mount: set an interval checking session expiry every 30 seconds
// When expired: POST /admin/v1/impersonation/:sessionId/end (body: none)
//   Append log note via POST /admin/v1/impersonation/:sessionId/log-action
//   { userId, actionDetail: 'Session timed out after 30 minutes' }
//   Clear sessionStorage key 'impersonationSession'
//   navigate('/users')
// Also clear interval in useEffect cleanup to prevent memory leaks

// ── End session button ─────────────────────────────────────────────────────────
// Button: "End Impersonation"
// On click: POST /admin/v1/impersonation/:sessionId/end
//   Then POST /admin/v1/impersonation/:sessionId/log-action
//   { userId, actionDetail: 'Operator ended session' }
//   Clear sessionStorage key 'impersonationSession'
//   navigate('/users')

// ── Auth pattern (identical to all other pages) ────────────────────────────────
const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'
// 401 → clearAuth() + navigate('/login')
```

**Styling:** Inline styles only. Arial/Helvetica, `#2c3e50`/`#34495e` palette. No CSS framework. Consistent with existing pages.

**Impersonation banner (required):**
```typescript
// Required banner styles (AC1):
const bannerStyle: React.CSSProperties = {
  background: '#e74c3c',
  color: '#fff',
  padding: '0.6rem 1.5rem',
  fontSize: '0.9rem',
  fontFamily: 'Arial, Helvetica, sans-serif',
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
}
// Banner text: `Viewing as ${session.userEmail} — ${session.operatorEmail}`
```

#### 4c: Update `apps/admin/src/pages/DashboardShell.tsx`

**File to modify:** `apps/admin/src/pages/DashboardShell.tsx`

Add route for the new impersonation view page. Do NOT modify sidebar, header, logout handler, or any existing routes.

```typescript
// Add import:
import ImpersonateUserPage from './ImpersonateUserPage'

// Add route inside <Routes>:
<Route path="/users/:userId/impersonate-view" element={<ImpersonateUserPage />} />
```

**Subtasks:**
- [x] Modify `apps/admin/src/pages/UsersPage.tsx`: add "Impersonate User" button with `POST /admin/v1/users/:userId/impersonate` call, store session in sessionStorage, navigate to `/users/:userId/impersonate-view`
- [x] Create `apps/admin/src/pages/ImpersonateUserPage.tsx`: persistent red banner, session expiry check + auto-end timer, "End Impersonation" button, audit log calls
- [x] Update `apps/admin/src/pages/DashboardShell.tsx`: add `ImpersonateUserPage` import and `/users/:userId/impersonate-view` route
- [x] Ensure 401 responses redirect to `/login` with `clearAuth()` in all fetch calls
- [x] `setLoading(false)` in ALL early-return paths (Story 11.2 lesson)

---

### Task 5: Write tests for impersonation endpoints (AC: 1, 2, 3)

**New test file:** `apps/admin-api/test/routes/impersonation.test.ts`

Model after `apps/admin-api/test/routes/charges.test.ts` — same import pattern, same auth-bypass behaviour.

```typescript
import { describe, expect, it } from 'vitest'

const app = (await import('../../src/index.js')).default

const STUB_USER_ID = '00000000-0000-4000-a000-000000000010'
const STUB_SESSION_ID = '00000000-0000-4000-a000-000000000030'

describe('POST /admin/v1/users/:userId/impersonate', () => {
  it('returns 200 with sessionId, userId, operatorEmail, expiresAt on valid request', async () => { /* ... */ })
  it('expiresAt is approximately 30 minutes in the future', async () => { /* ... */ })
  it('returns a unique sessionId on each call', async () => { /* ... */ })
})

describe('POST /admin/v1/impersonation/:sessionId/end', () => {
  it('returns 200 with sessionId, endedAt, reason=operator_ended', async () => { /* ... */ })
})

describe('POST /admin/v1/impersonation/:sessionId/log-action', () => {
  it('returns 200 with logId, sessionId, loggedAt on valid actionDetail', async () => { /* ... */ })
  it('returns 400 when actionDetail is empty string', async () => { /* ... */ })
  it('returns 400 when actionDetail is absent', async () => { /* ... */ })
})
```

**Minimum test count after story:** 7 new impersonation tests + 25 existing = 32 total.

**Auth note:** `ADMIN_JWT_SECRET` is undefined in Vitest → `adminAuthMiddleware` bypasses auth. No `Authorization` header needed.

**Run:** `cd apps/admin-api && npm test` — all 32+ tests must pass.

**Subtasks:**
- [x] Create `apps/admin-api/test/routes/impersonation.test.ts` with at least 7 tests
- [x] Run `cd apps/admin-api && npm test` — all tests pass, count reported

---

## Dev Notes

### Critical Architecture Constraints (carry-forward from Stories 11.1–11.3)

**`apps/admin-api` is a separate Cloudflare Worker — NEVER import from `apps/api/src/`.**
Any shared helpers must be duplicated into `apps/admin-api/src/`. `@ontask/core` imports (DB schema tables) are always fine. [Source: architecture.md lines 774–797, 1070–1072]

**`OpenAPIHono` throughout — no plain `Hono`.**
Every route file uses `new OpenAPIHono<{ Bindings: CloudflareBindings }>()` and `createRoute`. All routes must use `app.openapi()` with full Zod schemas. Do NOT use `app.get()` / `app.post()`. [Source: charges.ts line 15, disputes.ts line 16]

**`ok()` and `err()` helpers — always import with `.js` extension:**
```typescript
import { ok, err } from '../lib/response.js'
import { getDb } from '../db/index.js'
```

**`c.env?.DATABASE_URL` uses optional chaining.**
`c.env` is `undefined` in Vitest (no Cloudflare runtime). Use `c.env?.DATABASE_URL` — never `c.env.DATABASE_URL`. Same for `c.env?.ADMIN_JWT_SECRET`. [Source: charges.ts, admin-auth.ts line 33]

**`(c as any).get('operatorEmail')` type cast — mandatory in every handler.**
OpenAPIHono route-level context does not carry the Variables type. Use `(c as any).get('operatorEmail') as string | undefined`. This is pre-existing in disputes.ts line 352 and charges.ts. Do NOT try to fix the typing.

**Guard missing operatorEmail — return 500 (Story 11.3 review finding).**
Every handler that needs operator identity must check:
```typescript
const operatorEmail = (c as any).get('operatorEmail') as string | undefined
if (!operatorEmail) return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)
```
Impersonation is especially audit-sensitive — never proceed without a valid operatorEmail.

**`getDb()` is real (neon-http driver).**
`apps/admin-api/src/db/index.ts` exports `getDb(databaseUrl: string)` using neon-http + camelCase casing. Call as `const db = getDb(databaseUrl)`. [Source: apps/admin-api/src/db/index.ts]

**Stub fixture fallback is mandatory when `DATABASE_URL` undefined.**
Every handler must have `if (databaseUrl) { /* real DB path */ }` with a stub fallback. Never remove the stub; it enables tests without DB.

**`TODO(impl):` prefix for all stub comments.** Never use generic `TODO:`. [Source: charges.ts, disputes.ts throughout]

**Auth guard in `index.ts` — follow exact existing pattern:**
```typescript
// Existing (DO NOT REMOVE):
app.use('/admin/v1/users/*', adminAuthMiddleware)   // already covers POST .../impersonate
app.use('/admin/v1/charges/*', adminAuthMiddleware)

// Add for new impersonation session endpoints:
app.use('/admin/v1/impersonation/*', adminAuthMiddleware)
```

**`apps/admin` has NO testing infrastructure.**
No Vitest in `apps/admin`. Only backend tests in `apps/admin-api`. Do not add frontend tests.

**React Router v7 — same hooks as v6.**
`useNavigate`, `useParams`, `NavLink`, `Route`, `Routes` from `react-router-dom`. [Source: apps/admin/package.json]

**Token + API base pattern in all SPA fetch calls (copy exactly):**
```typescript
const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'
const token = getToken()
// headers: { 'Authorization': `Bearer ${token}` }
// 401 → clearAuth() + navigate('/login')
```
Import: `import { getToken, clearAuth } from '../lib/auth'` [Source: DisputeDetailPage.tsx, UserChargesPage.tsx]

**`setLoading(false)` in ALL early-return paths — mandatory (Story 11.2 review finding).**
In `UsersPage.tsx` when adding the impersonate button, any early return path (error, 404, etc.) must call `setLoading(false)` before returning. [Source: Story 11.2 dev notes]

### DB Schema: `operator_impersonation_logs` table (new, to be created this story)

**File:** `packages/core/src/schema/operator-impersonation-logs.ts` (create new)

Design rules:
- Never add `updatedAt` — row is intentionally immutable (same as `operator_refund_logs`).
- Never add UPDATE or DELETE query logic.
- `operatorEmail` stores email string directly (no operator UUID yet — same pattern as `operator_refund_logs.operatorEmail`).
- `sessionId` groups related log entries — generated with `crypto.randomUUID()` on session start.
- `actionType` values: `'session_start'`, `'session_end'`, `'session_timeout'`, `'action_taken'`.

**Export from core index — append after `operatorRefundLogsTable` export:**
```typescript
export { operatorImpersonationLogsTable } from './operator-impersonation-logs.js'
```
[Source: `packages/core/src/schema/index.ts`]

### Session Storage Design (Admin SPA)

Impersonation session state is stored in `sessionStorage` (not `localStorage`) so it clears when the operator closes the tab. Key: `'impersonationSession'`.

Session object shape:
```typescript
interface ImpersonationSession {
  sessionId: string
  userId: string
  userEmail: string      // TODO(impl): from users table once queryable; stub uses 'user@example.com'
  operatorEmail: string
  expiresAt: string      // ISO timestamp, now + 30 min
  startedAt: string      // ISO timestamp
}
```

The 30-minute timeout is enforced client-side via `setInterval` checking `session.expiresAt`. On expiry, call both end-session and log-action APIs, clear sessionStorage, navigate back.

**No server-side session store in this story.** The `sessionId` is opaque to the server in stub mode. A sessions table for server-side validation is a `TODO(impl)` deferred item.

### What This Story Does NOT Include

- No real read-only view of user's task/commitment data — the impersonation page shows session metadata only; `TODO(impl)` for full user data view
- No server-side session validation (no sessions table) — client-side only for now; `TODO(impl)`
- No operator account management or auth changes
- No Flutter app changes — operator dashboard is web-only
- No `apps/api` changes — admin routes are entirely in `apps/admin-api`
- No DB migrations run in this story — `operator_impersonation_logs` schema is defined but migration execution is deferred; real DB path guarded by `c.env?.DATABASE_URL`
- No CSS framework — inline styles only
- No changes to existing routes: disputes, charges, auth
- The `BillingPage` and `MonitoringPage` stubs in `DashboardShell.tsx` remain inline — those are for Story 11.5

### File Locations

```
packages/core/src/schema/
├── operator-impersonation-logs.ts       ← CREATE: immutable audit log table definition
├── operator-refund-logs.ts              ← DO NOT MODIFY
├── index.ts                             ← MODIFY: add operatorImpersonationLogsTable export

apps/admin-api/
├── src/
│   ├── index.ts                         ← MODIFY: add auth guard + mount impersonationRouter
│   ├── routes/
│   │   ├── disputes.ts                  ← DO NOT MODIFY
│   │   ├── charges.ts                   ← DO NOT MODIFY
│   │   └── impersonation.ts             ← CREATE: start/end session + log-action endpoints
│   ├── middleware/
│   │   └── admin-auth.ts                ← DO NOT MODIFY
│   ├── lib/
│   │   └── response.ts                  ← DO NOT MODIFY
│   └── db/
│       └── index.ts                     ← DO NOT MODIFY
├── test/
│   └── routes/
│       ├── impersonation.test.ts        ← CREATE: ≥7 tests for impersonation endpoints
│       ├── charges.test.ts              ← DO NOT MODIFY (10 passing tests must remain green)
│       ├── disputes.test.ts             ← DO NOT MODIFY (10 passing tests must remain green)
│       └── auth.test.ts                 ← DO NOT MODIFY (5 passing tests)

apps/admin/src/pages/
├── DashboardShell.tsx                   ← MODIFY: add ImpersonateUserPage import + route
├── UsersPage.tsx                        ← MODIFY: add "Impersonate User" button
├── ImpersonateUserPage.tsx              ← CREATE: banner, session timer, end-session
├── UserChargesPage.tsx                  ← DO NOT MODIFY
├── DisputesPage.tsx                     ← DO NOT MODIFY
├── DisputeDetailPage.tsx                ← DO NOT MODIFY
├── LoginPage.tsx                        ← DO NOT MODIFY
```

### Existing Test Baseline

- **Current passing tests:** 25 total (10 disputes.test.ts + 5 auth.test.ts + 10 charges.test.ts)
- **After this story:** 32+ minimum (25 existing + 7 new impersonation.test.ts)
- Run: `cd apps/admin-api && npm test`
- Vitest config: `{ test: { globals: true } }` — no Cloudflare worker pool needed
- Auth bypass: `adminAuthMiddleware` skips when `ADMIN_JWT_SECRET` is undefined — impersonation tests do NOT need auth headers

### Stub Fixture Design

**`POST /admin/v1/users/:userId/impersonate` stub:**
```typescript
const sessionId = crypto.randomUUID()
const startedAt = new Date().toISOString()
const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString()
return c.json(ok({
  sessionId,
  userId: c.req.param('userId'),
  operatorEmail: operatorEmail,
  userEmail: 'user@example.com',  // TODO(impl): fetch from users table
  expiresAt,
  startedAt,
}))
```

**`POST /admin/v1/impersonation/:sessionId/end` stub:**
```typescript
return c.json(ok({
  sessionId: c.req.param('sessionId'),
  endedAt: new Date().toISOString(),
  reason: 'operator_ended' as const,
}))
```

**`POST /admin/v1/impersonation/:sessionId/log-action` stub:**
```typescript
// Zod validates actionDetail is non-empty
return c.json(ok({
  logId: crypto.randomUUID(),
  sessionId: c.req.param('sessionId'),
  loggedAt: new Date().toISOString(),
}))
```

### Previous Story Intelligence (from Stories 11.1–11.3)

- `c.env` is `undefined` in Vitest — always `c.env?.X` (optional chaining) for any env var
- `(c as any).get('operatorEmail')` is the required cast — do not attempt to fix or work around it
- `.returning({ id: table.id })` on UPDATE detects race conditions — use if any UPDATE is added later
- `operatorEmail` stores email string as `text().notNull()`, not UUID — same as `operator_refund_logs`
- Story 11.2 review finding: `setLoading(false)` must be called in ALL early-return paths
- Story 11.3 review finding: guard missing operatorEmail and return 500 (not silently proceed)
- `operator_refund_logs` is append-only — apply the same design principles to `operator_impersonation_logs`
- Total test count after Story 11.3: 25 (10 disputes + 5 auth + 10 charges) — do not reduce this
- Audit-sensitive operations MUST store operatorEmail (never null)

### References

- Epic 11 goal: FR51–54, NFR-S6, NFR-R3 [Source: `_bmad-output/planning-artifacts/epics.md` line 2345]
- Story 11.4 AC: [Source: `_bmad-output/planning-artifacts/epics.md` lines 2426–2448]
- FR53 (operators impersonate user accounts): [Source: `_bmad-output/planning-artifacts/epics.md` line 114]
- NFR-S6 (immutable operator action audit log): [Source: `_bmad-output/planning-artifacts/epics.md` line 158]
- `operator_refund_logs` schema (model for new table): [Source: `packages/core/src/schema/operator-refund-logs.ts`]
- `@ontask/core` schema index: [Source: `packages/core/src/schema/index.ts`]
- `charges.ts` route pattern (OpenAPIHono, ok/err, stub structure, operatorEmail guard): [Source: `apps/admin-api/src/routes/charges.ts`]
- `disputes.ts` route pattern: [Source: `apps/admin-api/src/routes/disputes.ts`]
- `index.ts` auth guard and router mount pattern: [Source: `apps/admin-api/src/index.ts`]
- `getDb()` (neon-http driver, camelCase): [Source: `apps/admin-api/src/db/index.ts`]
- `ok()`/`err()` helpers: [Source: `apps/admin-api/src/lib/response.ts`]
- `adminAuthMiddleware` (bypass on missing secret, sets `c.var.operatorEmail`): [Source: `apps/admin-api/src/middleware/admin-auth.ts`]
- `DashboardShell.tsx` (sidebar navigation, route structure): [Source: `apps/admin/src/pages/DashboardShell.tsx`]
- `UsersPage.tsx` (current state — UUID input form, navigate to charges): [Source: `apps/admin/src/pages/UsersPage.tsx`]
- `UserChargesPage.tsx` (fetch pattern, auth header, 401 redirect, inline styles): [Source: `apps/admin/src/pages/UserChargesPage.tsx`]
- Auth helpers (`getToken`, `clearAuth`): [Source: `apps/admin/src/lib/auth.ts`]
- Story 11.3 dev notes (test baseline, patterns, constraints): [Source: `_bmad-output/implementation-artifacts/11-3-charge-reversal-refunds.md`]
- Worker separation constraint: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 774–797, 1070–1072]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed operatorEmail guard placement: initially placed before `if (databaseUrl)` block, causing 500 in tests since middleware sets no email without a secret. Moved guard inside `if (databaseUrl)` block (same pattern as charges.ts); stub path uses fallback email.

### Completion Notes List

- Task 1: Created `operator_impersonation_logs` DB schema (append-only, no updatedAt); exported from `@ontask/core` schema index after `operatorRefundLogsTable`.
- Task 2: Created `apps/admin-api/src/routes/impersonation.ts` with 3 endpoints (start/end/log-action) using `OpenAPIHono`, `createRoute`, `ok()`/`err()` helpers, stub fallback for no DATABASE_URL, and operatorEmail guard inside DB path.
- Task 3: Updated `apps/admin-api/src/index.ts` — added `/admin/v1/impersonation/*` auth guard and mounted `impersonationRouter`.
- Task 4: Updated `UsersPage.tsx` (Impersonate User button + POST call + sessionStorage + navigation), created `ImpersonateUserPage.tsx` (persistent red banner, 30-min timeout interval, end-session button with audit log calls, 401 → clearAuth), updated `DashboardShell.tsx` (new route).
- Task 5: Created 7 impersonation tests. All 32 tests pass (25 existing + 7 new). Test count confirmed.

### File List

- packages/core/src/schema/operator-impersonation-logs.ts (created)
- packages/core/src/schema/index.ts (modified)
- apps/admin-api/src/routes/impersonation.ts (created)
- apps/admin-api/src/index.ts (modified)
- apps/admin-api/test/routes/impersonation.test.ts (created)
- apps/admin/src/pages/UsersPage.tsx (modified)
- apps/admin/src/pages/ImpersonateUserPage.tsx (created)
- apps/admin/src/pages/DashboardShell.tsx (modified)
- _bmad-output/implementation-artifacts/11-4-user-impersonation.md (modified)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)

### Change Log

- 2026-04-02: Story 11.4 implemented — operator impersonation with immutable audit trail. Created DB schema, 3 API endpoints (start/end/log-action), admin SPA UI (persistent banner, 30-min timeout, audit log calls), 7 new tests. All 32 tests pass.
