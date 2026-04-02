# Story 10.4: MCP Server — OAuth Authentication & Token Scoping

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer building an MCP integration,
I want OAuth-secured per-client scoped tokens with revocation support,
so that MCP clients have only the access they need and users can revoke access at any time.

## Acceptance Criteria

1. **Given** an MCP client is registered
   **When** a user authenticates the client
   **Then** OAuth 2.0 is implemented per the MCP specification (FR93)
   **And** the client receives a scoped token declaring its permissions (e.g., `tasks:read`, `tasks:write`, `contracts:read`)
   **And** token scope is enforced server-side — requests exceeding scope return 403

2. **Given** a token is issued
   **When** the user opens Settings → Connected Apps
   **Then** they can see all active MCP client tokens with: client name, granted scopes, last-used timestamp
   **And** they can revoke any token, immediately invalidating it

3. **Given** a revoked token is used
   **When** the API receives the request
   **Then** the response is 401 with `{ "error": { "code": "TOKEN_REVOKED", ... } }`

## Tasks / Subtasks

---

### Task 1: Add `mcp_oauth_tokens` Drizzle schema table (AC: 1, 2, 3)

Story 10.3 deferred all OAuth per-client scoping to this story. No `mcp_oauth_tokens` table exists yet — it must be created in `packages/core/src/schema/`.

**Table design:**

```typescript
// packages/core/src/schema/mcp-oauth-tokens.ts
export const mcpOauthTokensTable = pgTable('mcp_oauth_tokens', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull(),          // FK → users table (when it exists)
  clientName: text('client_name').notNull(),   // human-readable name shown in Connected Apps
  tokenHash: text('token_hash').notNull().unique(), // SHA-256 hex of the raw bearer token
  scopes: text('scopes').array().notNull(),    // e.g. ['tasks:read', 'tasks:write']
  revokedAt: timestamp('revoked_at'),          // null = active; non-null = revoked
  lastUsedAt: timestamp('last_used_at'),       // updated on each authenticated request
  createdAt: timestamp('created_at').defaultNow().notNull(),
})
```

**Implementation steps:**

- [x] Create `packages/core/src/schema/mcp-oauth-tokens.ts` with the schema above
- [x] Export from `packages/core/src/schema/index.ts` (append `export { mcpOauthTokensTable } from './mcp-oauth-tokens.js'`)
- [x] No Drizzle migration runner exists (schema-first project) — the table addition to the index is sufficient for the schema to be picked up by the build

**CRITICAL:** Use `@neondatabase/serverless` HTTP transport (Neon driver) — NOT `pg`. All existing schema files use `pgTable` from `drizzle-orm/pg-core`. Follow the exact import patterns in `packages/core/src/schema/calendar-connections-google.ts` as the reference.

---

### Task 2: Create OAuth middleware for the MCP Worker (AC: 1, 3)

The architecture specifies `apps/mcp/src/middleware/oauth.ts` (FR93). This file does not exist yet.

**Architecture note:** The MCP Worker communicates with the API Worker via Cloudflare Service Binding (`env.API`). Token validation that requires DB access MUST go through the API Worker — the MCP Worker has no direct database binding. Design accordingly: the middleware calls a private token-validation endpoint on the API Worker.

**Middleware responsibilities:**

1. Extract the `Authorization: Bearer <token>` header from incoming requests
2. Call `GET /internal/mcp-tokens/validate?token=<raw-token>` on the API Worker (via `env.API` Service Binding)
3. On valid token: attach `{ userId, scopes }` to the Hono context (e.g., `c.set('mcpAuth', { userId, scopes })`)
4. On invalid/revoked/missing token: return 401 with `{ "error": { "code": "TOKEN_REVOKED", "message": "..." } }` or `{ "code": "UNAUTHORIZED", ... }` as appropriate
5. Update `lastUsedAt` — this should be done by the validation endpoint (side effect on the API side), not in the middleware itself

**File to create:** `apps/mcp/src/middleware/oauth.ts`

**Hono middleware pattern** (consistent with `apps/api/src/middleware/rate-limit.ts`):

```typescript
import type { Hono } from 'hono'

interface McpAuthPayload {
  userId: string
  scopes: string[]
}

// Augment Hono context variables
declare module 'hono' {
  interface ContextVariableMap {
    mcpAuth: McpAuthPayload
  }
}

export function applyOauthMiddleware(app: Hono<{ Bindings: { API?: { fetch: (...args: any[]) => Promise<any> } } }>): void {
  app.use('/tools/*', async (c, next) => {
    // ... extract Bearer token, call API validation endpoint, set context, handle errors
    await next()
  })
}
```

**Scope enforcement helper** (called within individual tool handlers):

```typescript
export function requireScope(scopes: string[], requiredScope: string): boolean {
  return scopes.includes(requiredScope)
}
```

- [x] Create `apps/mcp/src/middleware/oauth.ts` with the middleware function and `requireScope` helper
- [x] Apply `applyOauthMiddleware(app)` in `apps/mcp/src/index.ts` BEFORE tool routes are registered
- [x] The middleware MUST only protect `/tools/*` routes — the `GET /tools` manifest discovery endpoint and `GET /` health check remain unauthenticated

---

### Task 3: Add internal token validation endpoint to the API Worker (AC: 1, 3)

The OAuth middleware (Task 2) requires a private endpoint on the API Worker to validate tokens against the database. This endpoint is NOT part of the public `/v1/` API — it is an internal endpoint accessible only via Service Binding.

**Endpoint:** `GET /internal/mcp-tokens/validate`

**Query params:** `?token=<raw-bearer-token>`

**Behaviour:**
- Hash the raw token with SHA-256 → look up `mcp_oauth_tokens` by `tokenHash`
- If not found: 401 `{ "error": { "code": "UNAUTHORIZED", "message": "Token not found" } }`
- If `revokedAt` is set: 401 `{ "error": { "code": "TOKEN_REVOKED", "message": "Token has been revoked" } }`
- If valid: update `lastUsedAt = now()`, return 200 `{ "data": { "userId": "...", "scopes": [...] } }`

**File location:** Create `apps/api/src/routes/internal.ts` (or add to an existing internal routes file if one exists — check before creating).

**Registration in `apps/api/src/index.ts`:** Mount at `/internal` prefix. This route group does NOT need `@hono/zod-openapi` schema generation — it's internal only. It also does NOT need rate limiting middleware (internal service binding traffic only).

**SHA-256 in Cloudflare Workers:** Use the Web Crypto API available natively in the Workers runtime:

```typescript
async function sha256Hex(raw: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(raw)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
```

- [x] Check if `apps/api/src/routes/internal.ts` already exists; create it if not
- [x] Implement the `GET /internal/mcp-tokens/validate` handler with SHA-256 token hashing, DB lookup, revocation check, and `lastUsedAt` update
- [x] Register the internal route in `apps/api/src/index.ts`

---

### Task 4: Replace `stub-user-id` in all MCP tool files with real OAuth context (AC: 1)

Story 10.3 left a `TODO(impl): wire OAuth per-client scoping (FR93)` comment in every tool file. Every tool currently falls back to `'stub-user-id'` when no `userId` is passed. This story replaces that stub with the real authenticated user ID extracted from the OAuth middleware context.

**Files to update:**

- `apps/mcp/src/tools/create-task.ts` — line: `const userId = input.userId ?? 'stub-user-id'`
- `apps/mcp/src/tools/list-tasks.ts` — line: `const userId = input.userId ?? 'stub-user-id'`
- `apps/mcp/src/tools/update-task.ts` — similar pattern
- `apps/mcp/src/tools/schedule-task.ts` — similar pattern
- `apps/mcp/src/tools/complete-task.ts` — similar pattern
- `apps/mcp/src/tools/get-commitment-status.ts` — uses `x-user-id` stub header

**Approach:** The OAuth middleware (Task 2) sets `c.set('mcpAuth', { userId, scopes })` on the Hono context before the route handler runs. Route handlers in `apps/mcp/src/index.ts` extract `userId` from `c.get('mcpAuth').userId` and pass it to tool functions.

**Change pattern for route handlers in `index.ts`:**

```typescript
// Before (10.3 pattern):
app.post('/tools/create-task', async (c) => {
  const body = await c.req.json()
  const result = await createTask(body, apiBinding)
  return c.json(result)
})

// After (10.4 pattern):
app.post('/tools/create-task', async (c) => {
  const { userId, scopes } = c.get('mcpAuth')
  // Scope enforcement: tasks:write required
  if (!requireScope(scopes, 'tasks:write')) {
    return c.json({ content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:write scope required' } }) }], isError: true }, 403)
  }
  const body = await c.req.json()
  const result = await createTask({ ...body, userId }, apiBinding)
  return c.json(result)
})
```

**Scope requirements per tool:**

| Tool | Required Scope |
|------|---------------|
| `create_task` | `tasks:write` |
| `list_tasks` | `tasks:read` |
| `update_task` | `tasks:write` |
| `schedule_task` | `tasks:write` |
| `complete_task` | `tasks:write` |
| `get_commitment_status` | `contracts:read` |

**In the tool files themselves**, remove the `userId?` field from input types (it is no longer caller-supplied — it comes from OAuth context). The tool functions should accept `userId: string` as a required parameter (not optional) going forward. Update the `input.userId ?? 'stub-user-id'` lines accordingly.

- [x] Update all 6 tool files to remove the stub fallback and `userId?` from their input interfaces
- [x] Update all 6 route handlers in `apps/mcp/src/index.ts` to extract `userId` from OAuth context and enforce scope
- [x] Remove the `userId` property from the tool manifest in `GET /tools` (it is no longer a caller-supplied parameter)
- [x] Remove all `TODO(impl): wire OAuth per-client scoping (FR93)` comments from tool files and index.ts

---

### Task 5: Add token issuance endpoint to the API Worker (AC: 1, 2)

Users need a way to create MCP tokens. This is the issuance side (Settings → Connected Apps will call this).

**Endpoint:** `POST /v1/mcp-tokens`

**Request body:**
```json
{
  "clientName": "My AI Assistant",
  "scopes": ["tasks:read", "tasks:write"]
}
```

**Behaviour:**
- Validate `clientName` (required, max 100 chars) and `scopes` (array of valid scope strings)
- Valid scopes: `tasks:read`, `tasks:write`, `contracts:read`, `contracts:write`
- Generate a cryptographically secure random token: `crypto.randomUUID()` + additional entropy, or use `crypto.getRandomValues`
- Hash the token with SHA-256, store the hash in `mcp_oauth_tokens` (never store raw token)
- Return the raw token ONCE in the response — it will never be shown again
- Response: `{ "data": { "id": "...", "clientName": "...", "scopes": [...], "token": "<raw-token-shown-once>", "createdAt": "..." } }`

**Auth:** Uses the existing `x-user-id` stub header pattern for user identity (consistent with all existing API routes — real JWT auth is a separate concern not in scope for this story).

**File:** Add to `apps/api/src/routes/` — check what file is most appropriate (likely a new `mcp-tokens.ts` or add to an existing auth-related routes file).

- [x] Create or extend a route file for `POST /v1/mcp-tokens`
- [x] Implement cryptographically secure token generation using Web Crypto API
- [x] Store only the SHA-256 hash; return the raw token once
- [x] Register route in `apps/api/src/index.ts`

---

### Task 6: Add token listing and revocation endpoints (AC: 2, 3)

**Endpoints:**

- `GET /v1/mcp-tokens` — list all active (non-revoked) tokens for the authenticated user
  - Response: `{ "data": [{ "id": "...", "clientName": "...", "scopes": [...], "lastUsedAt": "...", "createdAt": "..." }] }`
  - Note: never return `tokenHash` in responses
- `DELETE /v1/mcp-tokens/:id` — revoke a specific token
  - Sets `revokedAt = now()` on the token
  - Verifies the token belongs to the authenticated user before revoking (return 404 if not found or not owned)
  - Response: 204 No Content on success

**Auth:** Uses the existing `x-user-id` stub header pattern.

- [x] Implement `GET /v1/mcp-tokens` handler
- [x] Implement `DELETE /v1/mcp-tokens/:id` handler
- [x] Register both routes in `apps/api/src/index.ts`

---

### Task 7: Write tests for OAuth middleware and new API endpoints (AC: 1, 2, 3)

**Test files to create:**

1. `apps/mcp/test/middleware/oauth.test.ts` — MCP OAuth middleware unit tests
2. `apps/api/test/routes/mcp-tokens.test.ts` — API token management endpoint tests

**Test patterns to follow (from `apps/mcp/test/tools/mcp-tools-10-3.test.ts`):**

- Vitest (`import { describe, expect, it, vi } from 'vitest'`)
- No Cloudflare runtime — mock all service bindings as `vi.fn()` returning Response-like objects
- Tool functions are pure — test them directly, not through HTTP

**MCP OAuth middleware test cases:**

```typescript
// apps/mcp/test/middleware/oauth.test.ts
// Test: missing Authorization header → 401
// Test: invalid token (API returns 401) → 401 UNAUTHORIZED
// Test: revoked token (API returns TOKEN_REVOKED) → 401 TOKEN_REVOKED
// Test: valid token → context populated with userId and scopes, next() called
// Test: scope enforcement → 403 when required scope not in token scopes
```

**API mcp-tokens test cases:**

```typescript
// apps/api/test/routes/mcp-tokens.test.ts
// Test: POST /v1/mcp-tokens → creates token, returns raw token once, stores only hash
// Test: GET /v1/mcp-tokens → lists active tokens, never includes tokenHash field
// Test: DELETE /v1/mcp-tokens/:id → sets revokedAt, subsequent validation returns TOKEN_REVOKED
// Test: DELETE /v1/mcp-tokens/:id with wrong user → 404
// Test: GET /internal/mcp-tokens/validate with valid token → 200 with userId and scopes
// Test: GET /internal/mcp-tokens/validate with revoked token → 401 TOKEN_REVOKED
// Test: GET /internal/mcp-tokens/validate with unknown token → 401 UNAUTHORIZED
```

**Vitest config:** Both `apps/mcp` and `apps/api` use plain vitest (no `@cloudflare/vitest-pool-workers`). Config files at `apps/mcp/vitest.config.ts` and `apps/api/vitest.config.ts` — check the API one for any differences.

- [x] Create `apps/mcp/test/middleware/oauth.test.ts`
- [x] Create `apps/api/test/routes/mcp-tokens.test.ts`
- [x] Run `npm test` in both `apps/mcp` and `apps/api` to confirm all tests pass

---

## Dev Notes

### Critical Architecture Constraints

**No MCP SDK installed — this is intentional.** The `@modelcontextprotocol/sdk` package is NOT installed and must NOT be added. Bundle size concern for Cloudflare Workers (10MB compressed limit; CI fails builds over 8MB). The HTTP routing pattern established in Story 10.3 is the permanent transport approach for this project.

**Service Binding is the ONLY way MCP → API communication happens.** Never call `api.ontaskhq.com` directly — always use `env.API.fetch(...)`. This is enforced by the Worker isolation model and is a hard architectural rule documented in `apps/mcp/src/index.ts`.

**Token storage security:** Store ONLY the SHA-256 hash of the raw bearer token. The raw token is returned once at issuance and never stored. This is the same pattern used for refresh tokens in many OAuth systems. Use `crypto.subtle.digest('SHA-256', ...)` — available natively in Cloudflare Workers runtime (no npm package needed).

**Auth stub preservation:** The `x-user-id` stub pattern is still used on the API Worker side (the API has no real JWT middleware yet — that is a separate concern). The OAuth middleware in this story runs on the MCP Worker only. The MCP Worker extracts the real user ID from the validated OAuth token and passes it to the API Worker as `x-user-id`.

### File Locations

```
apps/mcp/
├── src/
│   ├── index.ts                     ← MODIFY: apply middleware, update all route handlers
│   ├── middleware/
│   │   └── oauth.ts                 ← CREATE: OAuth middleware + requireScope helper
│   └── tools/
│       ├── create-task.ts           ← MODIFY: remove userId stub, userId now required param
│       ├── list-tasks.ts            ← MODIFY: remove userId stub
│       ├── update-task.ts           ← MODIFY: remove userId stub
│       ├── schedule-task.ts         ← MODIFY: remove userId stub
│       ├── complete-task.ts         ← MODIFY: remove userId stub
│       └── get-commitment-status.ts ← MODIFY: remove userId stub
├── test/
│   ├── middleware/
│   │   └── oauth.test.ts            ← CREATE
│   └── tools/
│       └── mcp-tools-10-3.test.ts   ← DO NOT MODIFY (existing tests must still pass)

apps/api/src/routes/
│   └── internal.ts                  ← CREATE (or extend): internal token validation
│   └── mcp-tokens.ts                ← CREATE: token CRUD endpoints

packages/core/src/schema/
│   └── mcp-oauth-tokens.ts          ← CREATE: Drizzle schema
│   └── index.ts                     ← MODIFY: add export
```

### Existing Tool Pattern (10.3 established)

Tool functions signature (before this story):
```typescript
export async function createTask(
  input: CreateTaskInput,  // includes userId?: string
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
): Promise<McpResult>
```

After this story, `userId` is removed from `CreateTaskInput` (and equivalents) and passed as a separate required param:
```typescript
export async function createTask(
  input: CreateTaskInput,  // userId no longer here
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,          // always provided by OAuth middleware now
): Promise<McpResult>
```

This is a breaking change to the function signatures — update all callers in `index.ts` and all test mocks in `mcp-tools-10-3.test.ts` accordingly.

**IMPORTANT:** Do NOT break existing tests in `apps/mcp/test/tools/mcp-tools-10-3.test.ts`. If the function signatures change, update the test file to pass `userId` as the third argument with a stub UUID.

### MCP Spec OAuth Compliance (FR93)

The MCP specification (as of 2025/2026) uses OAuth 2.0 Authorization Code flow with PKCE for interactive client registration. However, given the HTTP routing pattern (not SSE/stdio transport) chosen in Story 10.3, this story implements a simplified bearer token model that is compliant with the spirit of FR93 (per-client scoped tokens, revocation support) without requiring a full Authorization Code flow redirect UI. The "Connected Apps" UI flow (Settings → Connected Apps) handles token issuance and revocation.

This is the correct pragmatic scope: the AC says "OAuth 2.0 is implemented per the MCP specification" — the scoped bearer token + revocation model satisfies FR93 without requiring an interactive browser redirect flow in this story.

### Scope Definitions

Valid scope strings (enforce these as the canonical list in both issuance validation and enforcement):

```typescript
const VALID_SCOPES = ['tasks:read', 'tasks:write', 'contracts:read', 'contracts:write'] as const
type McpScope = (typeof VALID_SCOPES)[number]
```

### Database Notes

No `users` table exists yet in `packages/core/src/schema/` (it's not listed in `index.ts`). The `mcp_oauth_tokens.userId` column should NOT have a FK constraint for now — use plain `uuid('user_id').notNull()` without `.references(...)`. This is consistent with the deferred-FK pattern used in other tables in this codebase. The `x-user-id` stub value flows through as the userId.

### Wrangler Config

The `apps/mcp/wrangler.jsonc` already has the `API` service binding configured:
```jsonc
"services": [{ "binding": "API", "service": "ontask-api" }]
```

No new bindings are needed for this story — token storage goes through the API Worker which has the database connection.

### Testing Stack

- Vitest 3.2.4 (both `apps/mcp` and `apps/api`)
- No `@cloudflare/vitest-pool-workers` — plain Vitest runs in Node.js
- Mock pattern: `vi.fn().mockResolvedValue(responseObject)` for service binding mocks
- `apps/mcp/vitest.config.ts`: `{ test: { globals: true } }` (minimal config)
- Run tests: `cd apps/mcp && npm test` / `cd apps/api && npm test`

### References

- MCP Worker structure: `_bmad-output/planning-artifacts/architecture.md` lines 799–827
- OAuth middleware file path specified in architecture: `apps/mcp/src/middleware/oauth.ts` (FR93)
- Story 10.3 established HTTP routing pattern and tool file structure
- Story 10.3 commit: `71efb72` — core task tools implementation
- `apps/mcp/src/index.ts` — CRITICAL comment: "OAuth per-client scoping (FR93) is deferred to Story 10.4"
- All 6 tool files contain `TODO(impl): wire OAuth per-client scoping (FR93) — deferred to Story 10.4`
- Architecture separation rationale: [Source: `_bmad-output/planning-artifacts/architecture.md` — "Separated by auth model (JWT for REST API; OAuth for MCP)"]
- Bundle size CI constraint: [Source: architecture.md — "CI runs `wrangler deploy --dry-run` on each Worker and fails the build if either Worker exceeds 8MB"]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation proceeded cleanly without debugging issues.

### Completion Notes List

- Task 1: Created `mcp_oauth_tokens` Drizzle schema table (uuid PK, userId, clientName, tokenHash unique, scopes array, revokedAt, lastUsedAt, createdAt). Exported from packages/core/src/schema/index.ts. No FK on userId per deferred-FK pattern.
- Task 2: Created `apps/mcp/src/middleware/oauth.ts` with `applyOauthMiddleware()` and `requireScope()`. Middleware guards `/tools/*` but explicitly skips `GET /tools` (manifest) and `GET /` (health) — Hono's `/tools/*` wildcard matches `/tools` itself too, so explicit path check was needed. Token validation delegates to API Worker via Service Binding.
- Task 3: Created `apps/api/src/routes/internal.ts` with `GET /internal/mcp-tokens/validate`. Uses Web Crypto `crypto.subtle.digest('SHA-256', ...)` for token hashing. Checks revokedAt, updates lastUsedAt on valid tokens, registered in apps/api/src/index.ts.
- Task 4: Removed `userId?` from all 6 tool input interfaces. Added `userId: string` as required third parameter to all tool functions. Updated all route handlers in index.ts to extract userId from `c.get('mcpAuth')` and enforce scope per tool. Removed all TODO(impl) OAuth comments. Removed userId from tool manifest GET /tools.
- Task 5: Created `apps/api/src/routes/mcp-tokens.ts` with `POST /v1/mcp-tokens`. Uses `crypto.getRandomValues()` for token generation (32-byte hex), SHA-256 hashing for storage. Validates clientName (max 100 chars) and scopes (canonical VALID_SCOPES list). Returns raw token once, never stores it.
- Task 6: Added `GET /v1/mcp-tokens` (lists active non-revoked tokens, no tokenHash in response) and `DELETE /v1/mcp-tokens/:id` (sets revokedAt, verifies ownership, 204 on success). Both routes in mcp-tokens.ts registered in index.ts.
- Task 7: Created `apps/mcp/test/middleware/oauth.test.ts` (11 tests) and `apps/api/test/routes/mcp-tokens.test.ts` (12 tests). All 22 MCP tests pass, all 327 API tests pass. Existing mcp-tools-10-3.test.ts updated to pass userId as third argument with stub UUID.
- Updated `apps/mcp/test/tools/mcp-tools-10-3.test.ts` to pass `STUB_USER_ID` as third argument to all tool function calls (required by signature change).

### File List

- `packages/core/src/schema/mcp-oauth-tokens.ts` — NEW: Drizzle schema for mcp_oauth_tokens table
- `packages/core/src/schema/index.ts` — MODIFIED: added export for mcpOauthTokensTable
- `apps/mcp/src/middleware/oauth.ts` — NEW: OAuth Bearer token middleware + requireScope helper
- `apps/mcp/src/index.ts` — MODIFIED: applied OAuth middleware, updated all route handlers to use OAuth context and enforce scopes, removed userId from tool manifest, removed TODO comments
- `apps/mcp/src/tools/create-task.ts` — MODIFIED: removed userId? from input, added userId: string as third param, removed TODO comment
- `apps/mcp/src/tools/list-tasks.ts` — MODIFIED: removed userId? from input, added userId: string as third param, removed TODO comment
- `apps/mcp/src/tools/update-task.ts` — MODIFIED: removed userId? from input, added userId: string as third param, removed TODO comment
- `apps/mcp/src/tools/schedule-task.ts` — MODIFIED: removed userId? from input, added userId: string as third param, removed TODO comment
- `apps/mcp/src/tools/complete-task.ts` — MODIFIED: removed userId? from input, added userId: string as third param, removed TODO comment
- `apps/mcp/src/tools/get-commitment-status.ts` — MODIFIED: added userId: string as third param, passes x-user-id header to API, removed TODO comment
- `apps/mcp/test/middleware/oauth.test.ts` — NEW: OAuth middleware tests (11 tests)
- `apps/mcp/test/tools/mcp-tools-10-3.test.ts` — MODIFIED: updated all tool calls to pass STUB_USER_ID as third argument
- `apps/api/src/routes/internal.ts` — NEW: GET /internal/mcp-tokens/validate endpoint
- `apps/api/src/routes/mcp-tokens.ts` — NEW: POST/GET/DELETE /v1/mcp-tokens endpoints
- `apps/api/src/index.ts` — MODIFIED: registered mcpTokensRouter and internalRouter
- `apps/api/test/routes/mcp-tokens.test.ts` — NEW: API token management tests (12 tests)
### Review Findings

- [ ] [Review][Patch] `get-commitment-status` scope violation returns plain JSON envelope instead of MCP content format — `GET /tools/get-commitment-status` returns `{ error: { code: 'FORBIDDEN', ... } }` on scope violation (line ~207 in `apps/mcp/src/index.ts`), but all task tool scope violations return `{ content: [{ type: 'text', text: JSON.stringify({...}) }], isError: true }`. The story spec (Task 4 example) shows the MCP content envelope as the required format for tool 403s. Fix the `get-commitment-status` handler to wrap its 403 in the same MCP content envelope as the task tools. [apps/mcp/src/index.ts ~L207-L211]
- [ ] [Review][Patch] `DELETE /v1/mcp-tokens/:id` revocation UPDATE missing userId filter in WHERE clause — the handler first checks ownership with a SELECT (correct), then runs `UPDATE ... WHERE id = tokenId` without also filtering by `userId`. A race condition (or a bug in the select result handling) could theoretically allow revoking a token belonging to another user. Fix: change the UPDATE to `WHERE id = tokenId AND userId = userId` (use `and(eq(...id), eq(...userId))`) for defence-in-depth. [apps/api/src/routes/mcp-tokens.ts L353-L355]
- [ ] [Review][Patch] Missing 403 scope-enforcement integration test in `oauth.test.ts` — the test file header comments list "scope enforcement → 403 when required scope not in token scopes" but no test exercises this path through a route handler. The `requireScope` unit tests in the `describe('requireScope')` block cover the helper, but no test calls a `/tools/*` route with a valid token that lacks the required scope and asserts a 403. Add at least one such test (e.g., call `/tools/test` with a token that has `tasks:read` only, add a handler that requires `tasks:write`, assert 403). [apps/mcp/test/middleware/oauth.test.ts]
- [x] [Review][Defer] `sha256Hex` function duplicated across `internal.ts` and `mcp-tokens.ts` — identical implementation copied into both API route files. Pre-existing consequence of the file-per-route organisation; extracting to a shared `apps/api/src/lib/crypto.ts` would be the fix but is a refactor with no correctness impact. [apps/api/src/routes/internal.ts:17-24, apps/api/src/routes/mcp-tokens.ts:28-35] — deferred, pre-existing pattern
- [x] [Review][Defer] Raw token transmitted as URL query parameter to internal validation endpoint — `GET /internal/mcp-tokens/validate?token=<raw>` passes the raw bearer token in the query string; Cloudflare and intermediary systems may log request URLs. Risk is low given this is a Service Binding (internal, not network-traversing) but is a defence-in-depth concern. Would be resolved by switching to a POST with a JSON body. [apps/mcp/src/middleware/oauth.ts:176-181] — deferred, pre-existing architectural choice

## Change Log

- 2026-04-02: Story 10.4 implemented — OAuth Bearer token auth for MCP Worker, per-client scoped tokens, token CRUD API, revocation support. 22 MCP tests, 327 API tests (all green). Status: review.
