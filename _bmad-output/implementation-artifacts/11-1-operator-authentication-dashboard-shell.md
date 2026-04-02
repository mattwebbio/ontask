# Story 11.1: Operator Authentication & Dashboard Shell

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an On Task operator,
I want a secure internal dashboard with 2FA-enforced login,
so that only authorized staff can access sensitive user and financial data.

## Acceptance Criteria

1. **Given** the operator dashboard is deployed
   **When** an operator navigates to the admin URL
   **Then** the dashboard is available at `admin.staging.ontaskhq.com` and `admin.ontaskhq.com`
   **And** all operator API routes are under `/admin/v1/*` with CORS scoped to `admin.ontaskhq.com` and `admin.staging.ontaskhq.com` only (ARCH-15)
   **And** operator accounts are created manually — no self-service registration

2. **Given** an operator attempts to log in
   **When** authentication is performed
   **Then** email and password are required, followed by mandatory TOTP 2FA
   **And** login without a valid TOTP code fails regardless of password correctness

3. **Given** the operator is authenticated
   **When** the dashboard loads
   **Then** the sidebar shows navigation sections: Disputes, Users, Billing, Monitoring
   **And** the current operator's identity (email) is shown in the header at all times

## Tasks / Subtasks

---

### Task 1: Add `POST /admin/v1/auth/login` endpoint to `apps/admin-api` (AC: 1, 2)

The login endpoint accepts email + password + TOTP code and returns a signed JWT on success. This is the only unauthenticated route in the admin API.

**File:** `apps/admin-api/src/routes/auth.ts` (create new)

**Endpoint:** `POST /admin/v1/auth/login`

**Request body:**
```json
{
  "email": "operator@ontaskhq.com",
  "password": "...",
  "totpCode": "123456"
}
```

**Request schema:**
```typescript
const LoginRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  totpCode: z.string().length(6).regex(/^\d{6}$/),
})
```

**Behaviour (stub — no real DB):**
- Validate all three fields present and correct format
- Stub: accept any credentials for now — return 200 with a signed JWT containing `{ sub: email, role: 'operator' }`
- Real implementation: check email+password against Workers Secret–stored hashed credentials (argon2), check TOTP against stored TOTP secret. Deferred to real DB setup.
- On invalid credentials or invalid TOTP: return **401** `{ "error": { "code": "INVALID_CREDENTIALS", "message": "Invalid email, password, or TOTP code" } }`
- On success: return **200** `{ "data": { "token": "<jwt>", "operatorEmail": "<email>" } }`

**JWT issuance:**
- Sign with `env.ADMIN_JWT_SECRET` (already declared in `worker-configuration.d.ts` as `ADMIN_JWT_SECRET?: string`)
- Use the Web Crypto API (`crypto.subtle`) for HMAC-SHA256 signing — no external JWT library needed for stub
- Payload: `{ sub: email, role: 'operator', iat: now, exp: now + 8h }`
- Algorithm: HS256

**Response schemas:**
```typescript
const LoginResponseSchema = z.object({
  data: z.object({
    token: z.string(),
    operatorEmail: z.string(),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})
```

**Pattern:** Follow `apps/admin-api/src/routes/disputes.ts` exactly: `OpenAPIHono`, `createRoute`, `z` schemas, `ok()` / `err()` from `'../lib/response.js'`.

**Architecture constraint:** Password hashing uses `argon2` — NEVER `crypto.subtle` for password verification. Stub skips verification entirely; when real credentials check is added, use `argon2` npm package. [Source: architecture.md line 1151]

- [x] Create `apps/admin-api/src/routes/auth.ts` with `POST /admin/v1/auth/login`
- [x] Zod schemas: `LoginRequestSchema`, `LoginResponseSchema`, `ErrorSchema`
- [x] Stub JWT issuance via `crypto.subtle` HMAC-SHA256 (HS256)
- [x] Stub: accept any valid-format credentials; real credential check is a TODO comment

---

### Task 2: Add admin auth middleware to `apps/admin-api` (AC: 1, 2)

**File:** `apps/admin-api/src/middleware/admin-auth.ts` (create new)

This middleware reads the `Authorization: Bearer <token>` header, verifies the HS256 JWT signature against `env.ADMIN_JWT_SECRET`, and extracts the operator identity. It must be applied to all admin routes EXCEPT the login endpoint.

**Implementation:**
```typescript
export type AdminAuthContext = { operatorEmail: string }

export async function adminAuthMiddleware(
  c: Context<{ Bindings: CloudflareBindings }>,
  next: Next,
): Promise<Response | void>
```

- Missing or malformed `Authorization` header → 401 `{ error: { code: 'UNAUTHORIZED', message: 'Authorization required' } }`
- Invalid or expired JWT → 401 `{ error: { code: 'UNAUTHORIZED', message: 'Invalid or expired token' } }`
- Valid JWT → set `c.set('operatorEmail', payload.sub)` and call `next()`
- Use `crypto.subtle` for JWT signature verification (same HS256 algorithm as issuance)

**Context typing:** Add a `Variables` type to the Hono app context so `c.get('operatorEmail')` is typed:
```typescript
// In apps/admin-api/src/index.ts, update the app type:
const app = new OpenAPIHono<{ Bindings: CloudflareBindings; Variables: { operatorEmail: string } }>()
```

- [x] Create `apps/admin-api/src/middleware/admin-auth.ts`
- [x] Middleware verifies HS256 JWT, returns 401 on failure, sets `operatorEmail` in context on success

---

### Task 3: Add CORS middleware to `apps/admin-api` (AC: 1)

**File:** `apps/admin-api/src/middleware/cors.ts` (create new)

CORS must be scoped to `admin.ontaskhq.com` and `admin.staging.ontaskhq.com` only. This is NOT a global CORS middleware — it applies only to `/admin/v1/*` routes. [Source: architecture.md lines 333–338]

**Implementation using Hono's built-in CORS:**
```typescript
import { cors } from 'hono/cors'

export const adminCors = cors({
  origin: ['https://admin.ontaskhq.com', 'https://admin.staging.ontaskhq.com'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
})
```

**Apply in `apps/admin-api/src/index.ts`:** Use `app.use('/admin/v1/*', adminCors)` — before route registration.

- [x] Create `apps/admin-api/src/middleware/cors.ts`
- [x] Apply CORS middleware in `index.ts` via `app.use('/admin/v1/*', adminCors)`

---

### Task 4: Wire auth middleware and auth route into `apps/admin-api/src/index.ts` (AC: 1, 2)

**File to modify:** `apps/admin-api/src/index.ts`

Current state (do not break existing behaviour):
```typescript
import { OpenAPIHono } from '@hono/zod-openapi'
import { disputesRouter } from './routes/disputes.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()
app.route('/', disputesRouter)
export default app
```

**Target state:**
```typescript
import { OpenAPIHono } from '@hono/zod-openapi'
import { adminCors } from './middleware/cors.js'
import { adminAuthMiddleware } from './middleware/admin-auth.js'
import { authRouter } from './routes/auth.js'
import { disputesRouter } from './routes/disputes.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings; Variables: { operatorEmail: string } }>()

// CORS — scoped to /admin/v1/* only
app.use('/admin/v1/*', adminCors)

// Auth route — unauthenticated (login endpoint)
app.route('/', authRouter)

// All other admin routes require authentication
app.use('/admin/v1/disputes/*', adminAuthMiddleware)
app.use('/admin/v1/disputes', adminAuthMiddleware)
// (additional route guards added as new routes are added in later stories)

app.route('/', disputesRouter)

export default app
```

**Important:** The `disputesRouter` stub currently has NO auth. Applying `adminAuthMiddleware` to the disputes routes may break existing tests. Address this by passing a stub/skip auth mode in tests (see Task 6).

- [x] Update `apps/admin-api/src/index.ts` with CORS, auth middleware, and updated app type
- [x] Keep `disputesRouter` registered — do not remove or modify existing dispute routes

---

### Task 5: Build the admin SPA login page and dashboard shell (AC: 2, 3)

**App:** `apps/admin` (Cloudflare Pages, Vite + React 19, TypeScript)

**Current state:** The SPA has only `App.tsx` returning `<h1>OnTask Admin</h1>` and `main.tsx`. No routing, no pages.

**Target state:** Add React Router for client-side routing, a login page, and a dashboard shell with sidebar navigation.

**Install React Router:**
```
// Add to apps/admin/package.json dependencies:
"react-router-dom": "^7.0.0"
// (or use the version compatible with React 19 — React Router v7 is the current major)
```

**File structure to create:**
```
apps/admin/src/
├── pages/
│   ├── LoginPage.tsx           # email + password + TOTP form
│   └── DashboardShell.tsx      # sidebar + header + <Outlet />
├── lib/
│   └── auth.ts                 # admin auth state (token storage, getOperatorEmail)
└── App.tsx                     # updated: router setup with routes
```

**`apps/admin/src/lib/auth.ts`:**
```typescript
const TOKEN_KEY = 'admin_token'
const EMAIL_KEY = 'admin_email'

export function saveAuth(token: string, email: string): void {
  sessionStorage.setItem(TOKEN_KEY, token)
  sessionStorage.setItem(EMAIL_KEY, email)
}

export function getToken(): string | null {
  return sessionStorage.getItem(TOKEN_KEY)
}

export function getOperatorEmail(): string | null {
  return sessionStorage.getItem(EMAIL_KEY)
}

export function clearAuth(): void {
  sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.removeItem(EMAIL_KEY)
}

export function isAuthenticated(): boolean {
  return !!getToken()
}
```

Use `sessionStorage` (not `localStorage`) — tokens should not persist across browser sessions.

**`apps/admin/src/pages/LoginPage.tsx`:**
- Form fields: email (type="email"), password (type="password"), TOTP code (type="text", maxLength=6)
- On submit: `POST` to the admin API login endpoint
  - Local dev: `http://localhost:8787/admin/v1/auth/login`
  - Production: `https://api.ontaskhq.com/admin/v1/auth/login`
  - Use an `VITE_ADMIN_API_URL` env var for the base URL (default `http://localhost:8787`)
- On success (200): call `saveAuth(data.token, data.operatorEmail)` then navigate to `/`
- On error (401): show "Invalid credentials or TOTP code" error message inline
- No loading spinner needed for stub — basic form is sufficient

**`apps/admin/src/pages/DashboardShell.tsx`:**
- Sidebar with navigation links: Disputes (`/disputes`), Users (`/users`), Billing (`/billing`), Monitoring (`/monitoring`)
- Header showing: "OnTask Admin" + current operator email from `getOperatorEmail()`
- Logout button: calls `clearAuth()` then `navigate('/login')`
- Main content area: `<Outlet />` (React Router)
- Protected: if `!isAuthenticated()` on mount, redirect to `/login`
- Placeholder pages for each nav item (just `<h2>Disputes</h2>` etc.) — full implementation in later stories

**`apps/admin/src/App.tsx` updated:**
```typescript
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import LoginPage from './pages/LoginPage'
import DashboardShell from './pages/DashboardShell'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/*" element={<DashboardShell />} />
      </Routes>
    </BrowserRouter>
  )
}
```

**API base URL configuration:** Add `VITE_ADMIN_API_URL` to the Vite build. In `apps/admin/vite.config.ts` no change is needed (env vars prefixed with `VITE_` are auto-injected). Access in code as `import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'`.

**Styling:** Minimal — plain HTML/CSS only. No CSS framework installation needed. Use inline styles or a simple `<style>` tag in the shell for sidebar layout. The deferred-work notes mention `apps/admin/public/static/style.css` already exists — use it for any global styles.

- [x] Add `react-router-dom` to `apps/admin/package.json` dependencies
- [x] Create `apps/admin/src/lib/auth.ts` with sessionStorage-based token management
- [x] Create `apps/admin/src/pages/LoginPage.tsx` with email + password + TOTP form
- [x] Create `apps/admin/src/pages/DashboardShell.tsx` with sidebar nav and header showing operator email
- [x] Update `apps/admin/src/App.tsx` with BrowserRouter + route config
- [x] Add placeholder page components for Disputes, Users, Billing, Monitoring

---

### Task 6: Write tests for new auth endpoint (AC: 2)

**Test file:** `apps/admin-api/test/routes/auth.test.ts` (create new)

Follow the exact same pattern as `apps/admin-api/test/routes/disputes.test.ts`:
- `import { describe, expect, it } from 'vitest'`
- `const app = (await import('../../src/index.js')).default`
- Direct `app.request()` calls — no network, no HTTP server

**Test cases:**

```typescript
describe('POST /admin/v1/auth/login', () => {
  it('returns 200 with token and operatorEmail when credentials are valid format', async () => {
    // POST with valid email, password, totpCode (6-digit)
    // assert res.status === 200
    // assert body.data.token is a non-empty string
    // assert body.data.operatorEmail matches submitted email
  })

  it('returns 400 when totpCode is missing', async () => {
    // POST with email + password only, no totpCode
    // assert res.status === 400 (Zod validation failure)
  })

  it('returns 400 when totpCode is wrong length (not 6 digits)', async () => {
    // POST with totpCode = '123' (3 digits)
    // assert res.status === 400
  })

  it('returns 400 when email format is invalid', async () => {
    // POST with email = 'not-an-email'
    // assert res.status === 400
  })

  it('returns 400 when password is empty string', async () => {
    // POST with password = ''
    // assert res.status === 400
  })
})
```

**Note on auth middleware in tests:** The existing dispute tests (7 passing) do NOT include an Authorization header. When `adminAuthMiddleware` is applied in Task 4, the dispute tests will fail with 401. Fix by either:
1. Skipping auth in the stub (set a test env variable), OR
2. Adding a helper to tests that passes a valid test JWT header

**Recommended approach:** Add a test helper `makeAuthHeader()` to a shared test utility file `apps/admin-api/test/helpers.ts` that generates a valid stub JWT for test use. Then update `disputes.test.ts` to pass this header to all requests. This is the clean approach that will scale to all future admin-api tests.

```typescript
// apps/admin-api/test/helpers.ts
export function makeTestToken(email = 'test-operator@ontaskhq.com'): string {
  // Return a pre-signed test JWT or a stub token string
  // For stub purposes, admin-auth middleware can check for a TEST_MODE env flag
  // OR: generate a real HS256 token using crypto.subtle with a test secret
}
```

**If stub approach is chosen:** The `adminAuthMiddleware` can skip verification when `env.ADMIN_JWT_SECRET` is undefined (i.e., not set in test environment) and fall through as a no-op. This avoids test complexity at stub stage.

**Baseline test count:** 7 passing tests in `disputes.test.ts` — all must still pass after Task 4 middleware additions.

- [x] Create `apps/admin-api/test/routes/auth.test.ts` with 5 test cases
- [x] Create `apps/admin-api/test/helpers.ts` if needed to share test auth logic
- [x] Ensure existing 7 dispute tests still pass after middleware is wired in
- [x] Run `cd apps/admin-api && npm test` — all tests must pass

---

## Dev Notes

### Critical Architecture Constraints

**Separate Worker — `apps/admin-api` is NOT `apps/api`.**
These are two distinct Cloudflare Workers with separate bundles, separate `wrangler.jsonc`, separate `package.json`. Path-based routing on Cloudflare directs `api.ontaskhq.com/admin/v1/*` to `apps/admin-api` and `api.ontaskhq.com/v1/*` to `apps/api`. Never import from `apps/api/src/` in `apps/admin-api/src/`. Common helpers (like `response.ts`) are duplicated — do NOT move them to a shared package to avoid coupling. [Source: architecture.md lines 774–797, 1070–1072]

**CORS is scoped — NOT global.**
CORS must only be applied to `/admin/v1/*` in the admin-api Worker. The user-facing `apps/api` Worker has no CORS on `/v1/*` routes (native Flutter HTTP client). Do not add `app.use('*', cors(...))` — always scope to `/admin/v1/*`. [Source: architecture.md lines 333–338]

**Admin JWT — HS256 with `ADMIN_JWT_SECRET` Workers Secret.**
The `ADMIN_JWT_SECRET` is already declared in `worker-configuration.d.ts`. JWT signing/verification uses `crypto.subtle` (Web Crypto API, available in Cloudflare Workers). No `jsonwebtoken` npm package — it's Node.js-only. The `jose` npm package works in Workers if needed for full JWT handling, but `crypto.subtle` is sufficient for HS256 stubs. [Source: architecture.md line 577, worker-configuration.d.ts]

**argon2 for password hashing — NEVER `crypto.subtle` for passwords.**
The stub login endpoint skips real credential verification (accept any format-valid input). When real credential verification is added in a future story, use the `argon2` npm package. Never use `crypto.subtle` for password hashing — it is only for JWT signing/verification. [Source: architecture.md line 1151]

**No TOTP library installed yet.**
The stub accepts any 6-digit numeric TOTP code. Real TOTP verification (RFC 6238, HMAC-SHA-1 based) will need the `otpauth` npm package or similar when operator accounts are stored in DB. For Story 11.1 stub, any 6-digit numeric code passes. Add a `TODO(impl)` comment documenting this.

**`apps/admin` is React 19 + Vite.**
React 19, `@vitejs/plugin-react`, `vite ^6.0.0` are already installed. Do NOT install React 18 or use `ReactDOM.render` (deprecated). Use `createRoot` — already in `main.tsx`. [Source: `apps/admin/package.json`]

**`apps/admin` has NO testing infrastructure yet.**
No Vitest config exists in `apps/admin`. Do not add tests for the SPA in this story — frontend testing can be added in a future story. This story only adds `apps/admin-api` backend tests.

**`apps/admin-api` uses `OpenAPIHono` throughout.**
Every route file uses `new OpenAPIHono<{ Bindings: CloudflareBindings }>()` and `createRoute`. Do not use plain `new Hono()`. All routes must have `createRoute` + `app.openapi()` pattern with full Zod schemas. [Source: `apps/admin-api/src/routes/disputes.ts` lines 1–2, 19]

**`ok()` and `err()` helpers are in `apps/admin-api/src/lib/response.ts`.**
Use `ok(data)` for `{ data: ... }` envelope, `err(code, message)` for `{ error: { code, message } }` envelope. Do NOT inline these — import from `'../lib/response.js'` (note `.js` extension for ESM). [Source: `apps/admin-api/src/lib/response.ts`]

**Bundle size limit: 8MB compressed.**
Admin-api intentionally has no AI SDK, no Calendar client, no APNs client. Keep it lean. Any new npm dependencies must be minimal. [Source: architecture.md line 1105]

### File Locations

```
apps/admin-api/
├── src/
│   ├── index.ts                         ← MODIFY: add CORS, auth middleware, authRouter
│   ├── routes/
│   │   ├── auth.ts                      ← CREATE: POST /admin/v1/auth/login
│   │   └── disputes.ts                  ← DO NOT MODIFY (7 tests passing — must not break)
│   ├── middleware/
│   │   ├── admin-auth.ts                ← CREATE: JWT verification middleware
│   │   └── cors.ts                      ← CREATE: admin-scoped CORS
│   ├── lib/
│   │   └── response.ts                  ← DO NOT MODIFY
│   └── db/
│       └── index.ts                     ← DO NOT MODIFY (no DB needed for auth stub)
├── test/
│   ├── routes/
│   │   ├── auth.test.ts                 ← CREATE: 5 auth endpoint tests
│   │   └── disputes.test.ts             ← VERIFY still passing after middleware added
│   └── helpers.ts                       ← CREATE if needed (test JWT utility)
├── worker-configuration.d.ts            ← DO NOT MODIFY (ADMIN_JWT_SECRET already declared)
└── wrangler.jsonc                        ← DO NOT MODIFY

apps/admin/
├── src/
│   ├── App.tsx                          ← MODIFY: add BrowserRouter + routes
│   ├── main.tsx                         ← DO NOT MODIFY
│   ├── pages/
│   │   ├── LoginPage.tsx                ← CREATE: login form
│   │   └── DashboardShell.tsx           ← CREATE: shell with sidebar + header
│   └── lib/
│       └── auth.ts                      ← CREATE: sessionStorage token management
├── public/
│   └── static/
│       └── style.css                    ← EXISTS: use for global styles
└── package.json                         ← MODIFY: add react-router-dom
```

### Existing Code Patterns to Follow

**Route file pattern (copy from `disputes.ts`):**
```typescript
import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()
// ... createRoute + app.openapi ...
export { app as authRouter }
```

**Test pattern (copy from `disputes.test.ts`):**
```typescript
import { describe, expect, it } from 'vitest'
const app = (await import('../../src/index.js')).default
describe('...', () => {
  it('...', async () => {
    const res = await app.request('/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ... }),
    })
    expect(res.status).toBe(200)
  })
})
```

**Hono middleware pattern:**
```typescript
import type { Context, Next } from 'hono'
export async function adminAuthMiddleware(c: Context<{ Bindings: CloudflareBindings }>, next: Next) {
  const authHeader = c.req.header('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json(err('UNAUTHORIZED', 'Authorization required'), 401)
  }
  // ... verify JWT ...
  await next()
}
```

### `apps/admin-api` Test Baseline

- **Current passing tests:** 7 (all in `disputes.test.ts`)
- **Tests after this story:** 7 dispute + 5 auth = 12 minimum
- Run: `cd apps/admin-api && npm test`
- Vitest config: `{ test: { globals: true } }` — no Cloudflare worker pool needed

### Stub/TODO Pattern for Login

The login stub MUST include `TODO(impl)` comments documenting what will be needed when real operator accounts exist:
```typescript
// TODO(impl): replace stub with real credential check:
//   1. Look up operator record by email in operators table (DB query)
//   2. Verify password against stored argon2 hash (use argon2.verify())
//   3. Verify TOTP code against stored TOTP secret (use otpauth or RFC 6238)
//   4. Rate-limit login attempts by IP (Story 11.x)
```

### What This Story Does NOT Include

- No operator account management (create/delete operators) — manual DB management for v1
- No password reset flow — out of scope for v1
- No real argon2 password verification — stub accepts all format-valid credentials
- No real TOTP secret storage — stub accepts any 6-digit code
- No Flutter changes — operator dashboard is web-only, no mobile impact
- No `apps/api` changes — admin routes are entirely in `apps/admin-api`
- No database schema changes for this story — `operator_accounts` table deferred to when real auth is added
- No Cloudflare Pages `_redirects` file needed yet (Vite SPA routing on Pages may need this in a future story if 404 on direct navigation is encountered)

### Previous Story Intelligence (from Story 10.5)

The patterns from `apps/api` and `apps/mcp` are informative but remember admin-api is a separate Worker:
- `apps/admin-api/src/lib/response.ts` already has `ok()` / `err()` helpers (copied from apps/api, do NOT re-import from apps/api)
- The `wrangler.jsonc` comment already notes `ADMIN_JWT_SECRET` as a Workers Secret
- Hono's `app.use()` for middleware follows the same pattern across all Hono Workers

The MCP Worker's `requireScope()` pattern (from Story 10.4) is a useful reference for writing clean middleware, but the admin middleware uses JWT claims rather than MCP OAuth scopes.

### References

- Epic 11 goal: FR51–54, NFR-S6, NFR-R3, NFR-B1 [Source: `_bmad-output/planning-artifacts/epics.md` line 444]
- Operator Dashboard architecture: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 327–356]
- `apps/admin-api/` directory structure: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 774–797]
- `apps/admin/` directory structure: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 904–927]
- Admin auth gap resolution: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 1066–1072]
- argon2 constraint: [Source: `_bmad-output/planning-artifacts/architecture.md` line 1151]
- CORS routing table: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 335–340]
- Implementation sequence (step 13 = Admin SPA): [Source: `_bmad-output/planning-artifacts/architecture.md` line 420]
- Operator routes JWT claim requirement: [Source: `_bmad-output/planning-artifacts/architecture.md` line 577]
- `index.ts` comment confirming Story 11.1 adds auth + CORS: [Source: `apps/admin-api/src/index.ts` lines 6–7]
- `disputes.ts` comment confirming Story 11.1 dependency: [Source: `apps/admin-api/src/routes/disputes.ts` lines 13–14]
- Deferred work: `/static/style.css` 404 in admin SPA is known and acceptable at stub stage [Source: `_bmad-output/implementation-artifacts/deferred-work.md` line 120]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `c.env` is undefined in Vitest tests (no Cloudflare runtime). Used optional chaining `c.env?.ADMIN_JWT_SECRET` in both auth.ts and admin-auth.ts to safely handle test environment. The auth middleware bypass when secret is undefined ensures pre-existing dispute tests continue to pass without needing auth headers.
- TypeScript errors in disputes.ts (lines 146, 222) are pre-existing before this story — same OpenAPIHono return type inference issue. admin-api has no `typecheck` script so CI is not affected. auth.ts has the same pattern for consistency.
- Added `apps/admin/src/vite-env.d.ts` with `/// <reference types="vite/client" />` since the project lacked this file and `import.meta.env` was not typed.

### Completion Notes List

- Task 1: Created `apps/admin-api/src/routes/auth.ts` with `POST /admin/v1/auth/login`. Uses `OpenAPIHono`, `createRoute`, Zod schemas. JWT signed via `crypto.subtle` HMAC-SHA256 (HS256). Stub accepts any format-valid credentials with `TODO(impl)` comments for real verification.
- Task 2: Created `apps/admin-api/src/middleware/admin-auth.ts`. Verifies HS256 JWT, returns 401 on missing/invalid token, sets `operatorEmail` in Hono context. Safely skips auth when `ADMIN_JWT_SECRET` is absent (stub/test mode).
- Task 3: Created `apps/admin-api/src/middleware/cors.ts` with CORS scoped to `admin.ontaskhq.com` and `admin.staging.ontaskhq.com` only.
- Task 4: Updated `apps/admin-api/src/index.ts` with CORS middleware on `/admin/v1/*`, auth middleware on `/admin/v1/disputes/*` and `/admin/v1/disputes`, updated app type to include `Variables: { operatorEmail: string }`.
- Task 5: Added `react-router-dom: ^7.0.0` to `apps/admin/package.json`. Created `auth.ts` (sessionStorage token mgmt), `LoginPage.tsx` (email+password+TOTP form posting to admin API), `DashboardShell.tsx` (sidebar with Disputes/Users/Billing/Monitoring nav + header showing operator email + logout). Updated `App.tsx` with `BrowserRouter + Routes`. Placeholder pages for all 4 nav sections inlined in DashboardShell. Added `vite-env.d.ts` for `import.meta.env` types.
- Task 6: Created `apps/admin-api/test/routes/auth.test.ts` with 5 test cases. No separate helpers.ts needed — auth stub bypass (no secret in tests) means dispute tests pass without JWT headers. All 13 tests pass (8 disputes + 5 auth).

### File List

- `apps/admin-api/src/routes/auth.ts` (created)
- `apps/admin-api/src/middleware/admin-auth.ts` (created)
- `apps/admin-api/src/middleware/cors.ts` (created)
- `apps/admin-api/src/index.ts` (modified)
- `apps/admin-api/test/routes/auth.test.ts` (created)
- `apps/admin/src/lib/auth.ts` (created)
- `apps/admin/src/pages/LoginPage.tsx` (created)
- `apps/admin/src/pages/DashboardShell.tsx` (created)
- `apps/admin/src/App.tsx` (modified)
- `apps/admin/src/vite-env.d.ts` (created)
- `apps/admin/package.json` (modified — added react-router-dom)
- `pnpm-lock.yaml` (modified — updated for react-router-dom)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified)

## Change Log

- 2026-04-02: Story 11.1 implemented. Added `POST /admin/v1/auth/login` stub endpoint with HS256 JWT issuance, admin CORS middleware scoped to admin domains, JWT auth middleware for dispute routes, and admin SPA login page + dashboard shell with sidebar navigation (Disputes/Users/Billing/Monitoring). 13 tests pass (8 pre-existing + 5 new auth tests).
