# Story 10.5: MCP Server — Commitment Contract Tools

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an AI assistant,
I want to create commitment contracts on behalf of users via MCP,
so that users can set up financial accountability through their AI assistant without opening the app.

## Acceptance Criteria

1. **Given** the MCP server includes contract tools
   **When** an AI assistant invokes them
   **Then** `create_contract` accepts: task ID, stake amount, charity ID, deadline; creates a commitment contract pending payment method confirmation
   **And** `get_contract_status` returns the contract status, stake amount, and charge timestamp if charged (FR45, FR71)
   **And** contract creation requires `contracts:write` scope on the MCP token

2. **Given** the user has no stored payment method
   **When** `create_contract` is invoked
   **Then** the tool returns a structured error with a `setupUrl` field pointing to `ontaskhq.com/setup` for the user to complete payment setup
   **And** the contract is not created until payment method setup is confirmed

## Tasks / Subtasks

---

### Task 1: Add `POST /v1/contracts` endpoint to the API Worker (AC: 1, 2)

No `POST /v1/contracts` endpoint exists yet — only `GET /v1/contracts/:id/status` (added in Story 6.9). The new endpoint creates a commitment contract.

**Endpoint:** `POST /v1/contracts`

**Request body:**
```json
{
  "taskId": "uuid",
  "stakeAmountCents": 2500,
  "charityId": "american-red-cross",
  "deadline": "2026-05-01T00:00:00.000Z"
}
```

**Behaviour:**
- Validate all four fields are present (`taskId` UUID, `stakeAmountCents` positive integer, `charityId` non-empty string, `deadline` ISO 8601 datetime)
- Check whether the authenticated user has a stored payment method — inspect via the same logic as `GET /v1/payment-method` (stub: always returns `hasPaymentMethod: false`)
- If no payment method: return **422** with `{ "error": { "code": "NO_PAYMENT_METHOD", "message": "Payment method required", "setupUrl": "https://ontaskhq.com/setup" } }` — **do NOT create the contract**
- If payment method present: create the contract (stub: insert into DB / return stub data), return **201** `{ "data": { "id": "uuid", "taskId": "...", "stakeAmountCents": 2500, "charityId": "...", "deadline": "...", "status": "active", "createdAt": "..." } }`

**Auth:** Uses the existing `x-user-id` stub header pattern (consistent with all existing API routes).

**File:** Add to `apps/api/src/routes/commitment-contracts.ts` — append before the `export` line. This file uses `OpenAPIHono` + `@hono/zod-openapi`. Follow the existing route patterns exactly (`createRoute`, `z` schemas, `ok()` helper from `../lib/response.js`).

**Zod schema to add:**
```typescript
const createContractRequestSchema = z.object({
  taskId: z.string().uuid(),
  stakeAmountCents: z.number().int().positive(),
  charityId: z.string().min(1),
  deadline: z.string().datetime(),
})

const contractSchema = z.object({
  id: z.string().uuid(),
  taskId: z.string().uuid(),
  stakeAmountCents: z.number().int(),
  charityId: z.string(),
  deadline: z.string().datetime(),
  status: z.enum(['active', 'charged', 'cancelled', 'disputed']),
  createdAt: z.string().datetime(),
})
```

**Note:** The `setupUrl` in the 422 error is a plain string in the error body, not part of the standard `ErrorSchema`. Use an inline Zod schema for the 422 response:
```typescript
const NoPaymentMethodErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string(), setupUrl: z.string() }),
})
```

- [x] Add `POST /v1/contracts` route to `apps/api/src/routes/commitment-contracts.ts`
- [x] Zod schemas: `createContractRequestSchema`, `contractSchema`, `NoPaymentMethodErrorSchema`, `CreateContractResponseSchema` (wraps `contractSchema` in `{ data: ... }`)
- [x] Stub: check payment method (always false for now) → return 422 with `setupUrl`; if true → return 201 with stub contract
- [x] No new file needed; no change to `apps/api/src/index.ts` (commitmentContractsRouter is already registered)

---

### Task 2: Create `create-contract.ts` MCP tool (AC: 1, 2)

**File to create:** `apps/mcp/src/tools/create-contract.ts`

**Pattern:** Follow `apps/mcp/src/tools/complete-task.ts` exactly (simplest existing tool). Import `McpResult` from `./create-task.js`.

**Function signature** (after Story 10.4 OAuth pattern — userId is a required third param, not in input):
```typescript
export interface CreateContractInput {
  taskId: string
  stakeAmountCents: number
  charityId: string
  deadline: string  // ISO 8601 UTC
}

export async function createContract(
  input: CreateContractInput,
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<McpResult>
```

**API call:** `POST https://ontask-api-internal/v1/contracts` with body `{ taskId, stakeAmountCents, charityId, deadline }` and header `'x-user-id': userId`.

**Response handling:**
- If API returns 201: return `{ content: [{ type: 'text', text: JSON.stringify(json.data) }] }`
- If API returns 422 with `NO_PAYMENT_METHOD`: parse the error body; return `{ content: [{ type: 'text', text: JSON.stringify({ error: { code: 'NO_PAYMENT_METHOD', message: '...', setupUrl: 'https://ontaskhq.com/setup' } }) }], isError: true }` — **preserve the `setupUrl` field** so AI clients can surface it to users
- If API returns any other non-2xx: return UPSTREAM_ERROR in MCP content format
- Catch block: return UPSTREAM_ERROR

**Input validation** (before calling API):
- `taskId`, `charityId`, `deadline` are required strings
- `stakeAmountCents` must be a positive integer
- Return `MISSING_REQUIRED_FIELD` MCP error if validation fails

- [x] Create `apps/mcp/src/tools/create-contract.ts` with `CreateContractInput`, `createContract` function

---

### Task 3: Update `get-commitment-status.ts` to match Story 10.4 OAuth signature (AC: 1)

Story 10.4 changed all tool function signatures: `userId` is removed from the input interface and passed as a required third parameter. `get-commitment-status.ts` was in the list of files to update (Story 10.4 Task 4) but the completion notes confirm it was modified to add `userId: string` as a third parameter and pass `x-user-id` to the API.

**VERIFY before implementing:** Read `apps/mcp/src/tools/get-commitment-status.ts` to check current state. If the file still has the pre-10.4 signature (no `userId` third param, no `x-user-id` header), apply the 10.4 pattern now. If it already has `userId: string` as the third parameter, this task is done.

**Expected post-10.4 signature:**
```typescript
export async function getCommitmentStatus(
  input: GetCommitmentStatusInput,
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<GetCommitmentStatusOutput>
```

**Also verify** `apps/mcp/src/index.ts` route handler for `GET /tools/get-commitment-status` — after 10.4 it should extract `userId` from `c.get('mcpAuth')` and pass it as the third argument. If it still uses the pre-10.4 pattern, update it.

**Note:** `get-commitment-status` returns `GetCommitmentStatusOutput` directly (not `McpResult`). The route handler in `index.ts` wraps it in `{ data: result }`. This is the pre-existing pattern from Story 6.9 — **do NOT change it to the MCP content format** to avoid breaking existing behaviour (the story AC only asks for correct data).

- [x] Verify and (if needed) update `apps/mcp/src/tools/get-commitment-status.ts` to match 10.4 signature
- [x] Verify and (if needed) update `apps/mcp/src/index.ts` get-commitment-status handler to use OAuth context

---

### Task 4: Register `create_contract` tool in `apps/mcp/src/index.ts` (AC: 1)

Add the route handler for `POST /tools/create-contract` and add `create_contract` to the tool manifest (`GET /tools`).

**Import to add at top of `apps/mcp/src/index.ts`:**
```typescript
import { createContract } from './tools/create-contract.js'
```

**Tool manifest entry** (add to `toolManifest.tools` array):
```typescript
{
  name: 'create_contract',
  description: 'Create a commitment contract for a task. Requires the user to have a stored payment method. Returns a setupUrl if payment method setup is needed.',
  inputSchema: {
    type: 'object',
    required: ['taskId', 'stakeAmountCents', 'charityId', 'deadline'],
    properties: {
      taskId: { type: 'string', description: 'UUID of the task to attach the contract to' },
      stakeAmountCents: { type: 'number', description: 'Stake amount in cents (positive integer, e.g. 2500 = $25.00)' },
      charityId: { type: 'string', description: 'Every.org charity slug or ID (e.g. "american-red-cross")' },
      deadline: { type: 'string', description: 'Contract deadline as ISO 8601 UTC datetime string' },
    },
  },
}
```

**Route handler** (after Story 10.4 OAuth pattern — scope enforcement before calling tool):
```typescript
app.post('/tools/create-contract', async (c) => {
  const { userId, scopes } = c.get('mcpAuth')
  if (!requireScope(scopes, 'contracts:write')) {
    return c.json({ content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'contracts:write scope required' } }) }], isError: true }, 403)
  }
  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json({ content: [{ type: 'text', text: JSON.stringify({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }) }], isError: true }, 503)
  }
  let body: any
  try { body = await c.req.json() } catch {
    return c.json({ content: [{ type: 'text', text: JSON.stringify({ error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' } }) }], isError: true }, 400)
  }
  const result = await createContract(body, apiBinding, userId)
  return c.json(result)
})
```

**Import `requireScope`** — this is already imported from `./middleware/oauth.js` after Story 10.4. Check `apps/mcp/src/index.ts` imports.

- [x] Add `import { createContract } from './tools/create-contract.js'` to index.ts
- [x] Add `create_contract` entry to `toolManifest.tools` array
- [x] Add `POST /tools/create-contract` route handler with `contracts:write` scope enforcement

---

### Task 5: Write tests for new tools (AC: 1, 2)

**Test file to create:** `apps/mcp/test/tools/mcp-tools-10-5.test.ts`

Use the exact same patterns as `apps/mcp/test/tools/mcp-tools-10-3.test.ts`:
- `import { describe, expect, it, vi } from 'vitest'`
- `makeMockApiBinding()` helper with `vi.fn().mockResolvedValue(responseObject)`
- Test tool functions directly (pure functions, no HTTP)
- No Cloudflare runtime needed

**Test cases for `create_contract`:**

```typescript
describe('create_contract', () => {
  it('with all required fields returns MCP content format on success (201)', async () => { ... })
  it('with missing payment method returns NO_PAYMENT_METHOD error with setupUrl', async () => {
    // Mock API to return 422 with { error: { code: 'NO_PAYMENT_METHOD', setupUrl: 'https://ontaskhq.com/setup' } }
    // Assert result.isError is true
    // Assert JSON.parse(result.content[0].text).error.code === 'NO_PAYMENT_METHOD'
    // Assert JSON.parse(result.content[0].text).error.setupUrl === 'https://ontaskhq.com/setup'
    // CRITICAL: setupUrl must be preserved in the MCP result
  })
  it('with missing required fields returns MISSING_REQUIRED_FIELD error without calling API', async () => { ... })
  it('when API is unavailable returns UPSTREAM_ERROR', async () => { ... })
  it('calls POST /v1/contracts with correct body and x-user-id header', async () => {
    // Assert fetch called with correct URL, method POST, and x-user-id header
  })
})
```

**Test cases for `get_commitment_status` (if signature was updated in Task 3):**

If `get-commitment-status.ts` was updated, add tests confirming the `userId` third parameter is passed as `x-user-id`:
```typescript
describe('get_commitment_status', () => {
  it('calls GET /v1/contracts/:id/status with correct userId header', async () => { ... })
  it('returns contract status data on success', async () => { ... })
  it('throws on non-2xx API response', async () => { ... })
})
```

**Also: add test for the API endpoint in `apps/api/test/routes/commitment-contracts.test.ts`** (or create if it doesn't exist):

```
// apps/api/test/routes/
// Check if commitment-contracts.test.ts already exists
```

Check with glob before creating. If the file exists, add tests. If not, create it.

**API test cases for `POST /v1/contracts`:**
```typescript
// Test: POST /v1/contracts with valid body → 422 NO_PAYMENT_METHOD (stub always has no payment method)
// Test: POST /v1/contracts with missing taskId → 422 validation error
// Test: POST /v1/contracts with negative stakeAmountCents → 422 validation error
```

- [x] Create `apps/mcp/test/tools/mcp-tools-10-5.test.ts`
- [x] Check for `apps/api/test/routes/commitment-contracts.test.ts`; create or extend it with `POST /v1/contracts` tests
- [x] All existing tests must still pass (run `npm test` in both `apps/mcp` and `apps/api`)

---

## Dev Notes

### Critical Architecture Constraints

**No MCP SDK — HTTP routing pattern is permanent.** `@modelcontextprotocol/sdk` is NOT installed and MUST NOT be added. Bundle size limit: 8MB compressed (CI fails over this). HTTP routing established in Story 10.3 is the permanent approach. [Source: `_bmad-output/planning-artifacts/architecture.md` lines 799–827]

**Service Binding is the ONLY MCP→API communication path.** Never call `api.ontaskhq.com` directly. Always use `env.API.fetch(...)`. This is a hard architectural rule enforced by Worker isolation.

**OAuth middleware from Story 10.4 is prerequisite.** Story 10.4 created `apps/mcp/src/middleware/oauth.ts` with `applyOauthMiddleware()` and `requireScope()`. This story relies on that middleware being in place. The `contracts:write` scope is in the canonical `VALID_SCOPES` list established in Story 10.4:
```typescript
const VALID_SCOPES = ['tasks:read', 'tasks:write', 'contracts:read', 'contracts:write'] as const
```

**`contracts:write` scope enforcement pattern** — identical to task tools. Route handler extracts `{ userId, scopes }` from `c.get('mcpAuth')`, calls `requireScope(scopes, 'contracts:write')`, returns 403 in MCP content envelope format on failure (NOT plain JSON):
```typescript
// CORRECT 403 format (MCP content envelope):
{ content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', ... } }) }], isError: true }

// WRONG (plain JSON — don't do this — see Story 10.4 Review Finding #1):
{ error: { code: 'FORBIDDEN', ... } }
```
The Story 10.4 review found that `get-commitment-status` used plain JSON for its 403 — this story must NOT repeat that mistake.

**`get_commitment_status` uses `contracts:read` scope (not `contracts:write`).** This is unchanged from Story 10.4. The new `create_contract` tool needs `contracts:write`.

### File Locations

```
apps/mcp/
├── src/
│   ├── index.ts                     ← MODIFY: add create_contract import, manifest entry, route handler
│   ├── middleware/
│   │   └── oauth.ts                 ← DO NOT MODIFY (Story 10.4 — already has requireScope)
│   └── tools/
│       ├── create-contract.ts       ← CREATE: new tool
│       └── get-commitment-status.ts ← VERIFY/MODIFY: check for 10.4 userId signature
├── test/
│   └── tools/
│       ├── mcp-tools-10-3.test.ts   ← DO NOT MODIFY (11 tests — must still pass)
│       └── mcp-tools-10-5.test.ts   ← CREATE: new tests

apps/api/src/routes/
│   └── commitment-contracts.ts      ← MODIFY: add POST /v1/contracts (append before export)

apps/api/test/routes/
│   └── commitment-contracts.test.ts ← CREATE or EXTEND: add POST /v1/contracts tests
```

### Existing Tool Pattern (established in Story 10.3, updated in Story 10.4)

After Story 10.4, ALL tool functions take `userId: string` as a required **third** parameter:

```typescript
// Story 10.4 pattern (required for ALL new tools in this story):
export async function createContract(
  input: CreateContractInput,   // userId NOT in input
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,               // always provided by OAuth middleware
): Promise<McpResult>
```

Route handler in `index.ts` extracts userId from OAuth context:
```typescript
const { userId, scopes } = c.get('mcpAuth')
const result = await createContract(body, apiBinding, userId)
```

The tool passes `userId` as `'x-user-id'` header to the API Worker (Service Binding).

### Commitment Contract API — Existing vs New

**Existing (DO NOT change):**
- `GET /v1/contracts/:id/status` — in `commitment-contracts.ts`, stub returns `{ id, status: 'active', stakeAmountCents: 2500, chargeTimestamp: null }`. Used by `get-commitment-status.ts` tool.
- `GET /v1/payment-method` — returns `{ hasPaymentMethod: false, paymentMethod: null, hasActiveStakes: false }` (always false stub)

**New (this story):**
- `POST /v1/contracts` — creates a contract. Stub checks payment method (always false) → 422 with `setupUrl`. Add to `commitment-contracts.ts` before `export { app as commitmentContractsRouter }`.

**No new file needed** — `commitmentContractsRouter` is already registered in `apps/api/src/index.ts`. Adding routes to the existing router file is sufficient.

### setupUrl Value

The `setupUrl` for payment method setup is `https://ontaskhq.com/setup`. This is the Stripe.js hosted page for SetupIntent (MKTG-4, referenced in Epic 6 notes). **Always use the exact string `https://ontaskhq.com/setup`** — no trailing slash, no staging URL variant.

### `commitment-contracts.ts` File Structure

The file uses `OpenAPIHono` with `createRoute`. Add `POST /v1/contracts` before the final export line. Follow this exact pattern from existing routes in the file:

```typescript
const createContractRoute = createRoute({
  method: 'post',
  path: '/v1/contracts',
  tags: ['Contracts'],
  summary: 'Create a commitment contract',
  description: '...',
  request: {
    body: { content: { 'application/json': { schema: createContractRequestSchema } }, required: true },
  },
  responses: {
    201: { content: { 'application/json': { schema: CreateContractResponseSchema } }, description: 'Contract created' },
    422: { content: { 'application/json': { schema: NoPaymentMethodErrorSchema } }, description: 'No payment method' },
  },
})

app.openapi(createContractRoute, async (c) => {
  const body = c.req.valid('json')
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  // TODO(impl): check stripePaymentMethodId for userId — if null, return 422 NO_PAYMENT_METHOD
  // Stub: always returns 422 (no payment methods in stub)
  return c.json(
    { error: { code: 'NO_PAYMENT_METHOD', message: 'Payment method required. Visit the URL to set up.', setupUrl: 'https://ontaskhq.com/setup' } },
    422,
  )
})
```

### MCP Result Format (never forget this)

All tool functions return `McpResult` (from `create-task.ts`):
```typescript
// Success:
{ content: [{ type: 'text', text: JSON.stringify(data) }] }

// Error:
{ content: [{ type: 'text', text: JSON.stringify({ error: { code, message, ...extras } }) }], isError: true }
```

`get-commitment-status.ts` is the ONE exception — it returns `GetCommitmentStatusOutput` directly (not `McpResult`). The `index.ts` handler wraps it in `{ data: result }`. Do not change this.

### Testing Stack

- Vitest 3.2.4 (both `apps/mcp` and `apps/api`)
- No `@cloudflare/vitest-pool-workers` — plain Vitest runs in Node.js
- Mock pattern: `vi.fn().mockResolvedValue(responseObject)`
- `apps/mcp/vitest.config.ts`: `{ test: { globals: true } }` (minimal config)
- Run tests: `cd apps/mcp && npm test` / `cd apps/api && npm test`
- **Baseline at start of story:** 23 MCP tests (11 tool + 12 OAuth middleware), 327 API tests — all must still pass

### Story 10.4 Review Findings to Address

Story 10.4 review found these issues (marked as patches — may or may not be applied yet):

1. `get-commitment-status` scope violation returns plain JSON envelope instead of MCP content format — **this story MUST NOT repeat this mistake** for `create_contract`. The fix to `get-commitment-status` scope 403 should also be applied if not already done.
2. `DELETE /v1/mcp-tokens/:id` UPDATE missing userId filter — not relevant to this story.
3. Missing 403 scope-enforcement integration test in `oauth.test.ts` — not relevant to this story.

### References

- Story 10.3: 5 core task tools in `apps/mcp/src/tools/` — established HTTP routing, MCP content format, Service Binding pattern
- Story 10.4: OAuth middleware, `requireScope()`, scope enforcement in route handlers, `userId` as third param
- Story 6.9: `get-commitment-status.ts` and `GET /v1/contracts/:id/status` added
- `apps/mcp/src/middleware/oauth.ts` — `requireScope()` helper and `applyOauthMiddleware()`
- `apps/api/src/routes/commitment-contracts.ts` — existing routes, `ErrorSchema`, `ok()` helper pattern
- Architecture: MCP Worker structure [Source: `_bmad-output/planning-artifacts/architecture.md` lines 799–827]
- Scope definitions: `VALID_SCOPES` includes `contracts:write` [Source: Story 10.4 Dev Notes]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Branched from `origin/story/10-4-mcp-server-oauth-authentication-token-scoping` (Story 10.4 was not yet merged to main).
- `get-commitment-status.ts` and `index.ts` already had the 10.4 three-param signature — Task 3 was a no-op verify.
- API test file `commitment-contracts.test.ts` did not exist before this story — created new.
- Sprint-status conflict from stash pop resolved by taking the stashed (more current) values.

### Completion Notes List

- Task 1: Added `POST /v1/contracts` to `apps/api/src/routes/commitment-contracts.ts` with full Zod schema validation. Stub always returns 422 `NO_PAYMENT_METHOD` with `setupUrl: https://ontaskhq.com/setup`. Four schemas added: `createContractRequestSchema`, `contractSchema`, `NoPaymentMethodErrorSchema`, `CreateContractResponseSchema`.
- Task 2: Created `apps/mcp/src/tools/create-contract.ts` with `(input, apiBinding, userId)` three-param signature. Handles 201 success, 422 NO_PAYMENT_METHOD (preserves setupUrl), other non-2xx (UPSTREAM_ERROR), and catch (UPSTREAM_ERROR). Input validation before API call.
- Task 3: Verified — `get-commitment-status.ts` already had the 10.4 three-param signature. `index.ts` handler already extracts `userId` from `c.get('mcpAuth')`. No changes needed.
- Task 4: Added `create_contract` import, tool manifest entry, and `POST /tools/create-contract` route handler with `contracts:write` scope enforcement using MCP content envelope format for 403.
- Task 5: Created 11 MCP tests in `mcp-tools-10-5.test.ts` (create_contract: 7 tests, get_commitment_status: 3 tests). Created 7 API tests in `commitment-contracts.test.ts` (POST /v1/contracts: valid body 422, 6 validation error cases).
- Final test counts: 34 MCP (23 baseline + 11 new), 334 API (327 baseline + 7 new). All passing.

### File List

- `apps/api/src/routes/commitment-contracts.ts` — modified: added POST /v1/contracts route + schemas
- `apps/mcp/src/tools/create-contract.ts` — created: new create_contract MCP tool
- `apps/mcp/src/index.ts` — modified: import + manifest entry + route handler for create_contract
- `apps/mcp/test/tools/mcp-tools-10-5.test.ts` — created: 11 MCP tool tests
- `apps/api/test/routes/commitment-contracts.test.ts` — created: 7 API route tests
- `_bmad-output/implementation-artifacts/10-5-mcp-server-commitment-contract-tools.md` — modified: task checkboxes, dev agent record, status
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified: status updated to review
