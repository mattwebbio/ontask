# Story 11.5: Operator Alerts & Business Event Monitoring

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an operator,
I want real-time alerts for payment failures and disputes, and a dashboard of key business metrics,
so that I can respond quickly to issues and track the health of the business.

## Acceptance Criteria

1. **Given** the operator dashboard is open
   **When** a triggering event occurs
   **Then** in-dashboard alerts fire for: any user's payment failure, any new dispute filed, any dispute approaching its 24-hour SLA (FR54)
   **And** the unacknowledged alert count is shown as a badge in the sidebar navigation

2. **Given** the operator opens the Monitoring section
   **When** the dashboard loads
   **Then** business metrics are shown as time-series data queryable by date range: daily trial starts, trial-to-subscription conversions, subscription activations, subscription cancellations, total charges fired, total disbursed to charity (NFR-B1)
   **And** data is sourced from PostHog events configured in Story 1.12 — no separate analytics store required for v1

## Tasks / Subtasks

---

### Task 1: Add alert-polling endpoint to `apps/admin-api` (AC: 1)

**New file:** `apps/admin-api/src/routes/alerts.ts`

Model this file exactly after `apps/admin-api/src/routes/charges.ts` — same import pattern, same `OpenAPIHono`, same `ok()`/`err()` helpers, same stub-with-TODO structure.

#### Endpoint to implement

**`GET /admin/v1/alerts`** — fetch unacknowledged alerts for in-dashboard badge + list

```typescript
// Response schema:
const AlertItemSchema = z.object({
  id: z.string(),              // UUID — unique alert id
  type: z.enum([
    'payment_failure',         // any charge_events row with status = 'failed'
    'new_dispute',             // any dispute_reviews row with status = 'pending' filed in last poll window
    'dispute_sla_warning',     // dispute with hoursElapsed >= 18 (amber) and status = 'pending'
  ]),
  severity: z.enum(['info', 'warning', 'critical']),
  title: z.string(),           // short human-readable title, e.g. "Payment failed for user abc"
  detail: z.string().optional(),
  referenceId: z.string(),     // e.g. chargeId or disputeId for deep-link navigation
  referenceType: z.enum(['charge', 'dispute']),
  createdAt: z.string(),       // ISO timestamp
  acknowledged: z.boolean(),
})

const AlertsResponseSchema = z.object({
  data: z.object({
    alerts: z.array(AlertItemSchema),
    unacknowledgedCount: z.number(),
  }),
})

// DB flow (when DATABASE_URL available):
// 1. Guard: if (!operatorEmail) return 500
// 2. Query charge_events WHERE status = 'failed' — map to payment_failure alerts
// 3. Query dispute_reviews WHERE status = 'pending' — map to new_dispute (filed in last 24h) or dispute_sla_warning (hoursElapsed >= 18)
// 4. TODO(impl): Persistent acknowledgement state requires an operator_alert_acks table.
//    For v1, all alerts are returned as unacknowledged (acknowledged: false).
// 5. Return sorted array: critical first, then warning, then info; within each by createdAt desc
// 6. unacknowledgedCount = total count of returned alerts (all unacknowledged for v1)

// Stub fixture (no DATABASE_URL):
// Return 3 stub alerts:
//   { id: crypto.randomUUID(), type: 'payment_failure', severity: 'critical', title: 'Payment failed', detail: 'Charge ID stub', referenceId: '00000000-0000-4000-a000-000000000001', referenceType: 'charge', createdAt: new Date().toISOString(), acknowledged: false }
//   { id: crypto.randomUUID(), type: 'dispute_sla_warning', severity: 'warning', title: 'Dispute SLA warning', detail: 'Approaching 24h SLA', referenceId: '00000000-0000-4000-a000-000000000002', referenceType: 'dispute', createdAt: new Date().toISOString(), acknowledged: false }
//   { id: crypto.randomUUID(), type: 'new_dispute', severity: 'info', title: 'New dispute filed', detail: null, referenceId: '00000000-0000-4000-a000-000000000003', referenceType: 'dispute', createdAt: new Date().toISOString(), acknowledged: false }
// unacknowledgedCount: 3
// TODO(impl): Replace stub with real DB query when DATABASE_URL available

// Error responses:
// 500 — operatorEmail not present
```

**`POST /admin/v1/alerts/:alertId/acknowledge`** — acknowledge a single alert

```typescript
// Request: no body
// Response schema:
const AcknowledgeResponseSchema = z.object({
  data: z.object({
    alertId: z.string(),
    acknowledgedAt: z.string(),
  }),
})

// DB flow (when DATABASE_URL available):
// 1. Guard: if (!operatorEmail) return 500
// 2. TODO(impl): Insert into operator_alert_acks (alertId, operatorEmail, acknowledgedAt)
//    This table is not defined in this story — create it in a follow-up.
// 3. Return { alertId, acknowledgedAt }

// Stub fixture (no DATABASE_URL):
// return c.json(ok({ alertId: c.req.param('alertId'), acknowledgedAt: new Date().toISOString() }))

// Error responses:
// 500 — operatorEmail not present
```

**Subtasks:**
- [x] Create `apps/admin-api/src/routes/alerts.ts` with `GET /admin/v1/alerts` and `POST /admin/v1/alerts/:alertId/acknowledge`
- [x] Use `OpenAPIHono`, `createRoute`, `ok()`/`err()` helpers throughout
- [x] Stub fixture fallback for no DATABASE_URL (returns 3 stub alerts)
- [x] Guard missing `operatorEmail`: return 500 in all handlers

---

### Task 2: Register routes and auth guard in `apps/admin-api/src/index.ts` (AC: 1)

**File to modify:** `apps/admin-api/src/index.ts`

Following the exact pattern of existing auth guards (lines 23–27):

```typescript
// Add after existing impersonation guard:
app.use('/admin/v1/alerts/*', adminAuthMiddleware)
app.use('/admin/v1/alerts', adminAuthMiddleware)

// Import and mount router (after impersonationRouter):
import { alertsRouter } from './routes/alerts.js'
app.route('/', alertsRouter)
```

**Note:** Both `/admin/v1/alerts` (exact) and `/admin/v1/alerts/*` (sub-paths) need guards — follow the disputes pattern (lines 23–24) which covers both the list route and sub-routes.

**Subtasks:**
- [x] Add auth guard: `app.use('/admin/v1/alerts', adminAuthMiddleware)` and `app.use('/admin/v1/alerts/*', adminAuthMiddleware)`
- [x] Import `alertsRouter` and mount with `app.route('/', alertsRouter)`

---

### Task 3: Add PostHog metrics endpoint to `apps/admin-api` (AC: 2)

**New endpoint in `apps/admin-api/src/routes/alerts.ts`** (or a separate `monitoring.ts` — choose `alerts.ts` to keep Epic 11.5 changes minimal):

**`GET /admin/v1/monitoring/metrics`** — query PostHog for business event time-series data

```typescript
// Query params:
const MetricsQuerySchema = z.object({
  from: z.string(),    // ISO date string, e.g. '2026-01-01'
  to: z.string(),      // ISO date string, e.g. '2026-04-01'
})

// Response schema:
const MetricSeriesSchema = z.object({
  date: z.string(),    // 'YYYY-MM-DD'
  count: z.number(),
})

const MetricsResponseSchema = z.object({
  data: z.object({
    trialStarts: z.array(MetricSeriesSchema),
    trialToSubscriptionConversions: z.array(MetricSeriesSchema),
    subscriptionActivations: z.array(MetricSeriesSchema),
    subscriptionCancellations: z.array(MetricSeriesSchema),
    totalChargesFired: z.array(MetricSeriesSchema),
    totalDisbursedToCharity: z.array(MetricSeriesSchema),  // sum of charityAmountCents by day
    dateRange: z.object({ from: z.string(), to: z.string() }),
  }),
})

// DB/PostHog flow (when POSTHOG_API_KEY available — use c.env?.POSTHOG_API_KEY):
// 1. Guard: if (!operatorEmail) return 500
// 2. TODO(impl): Call PostHog Query API (https://posthog.com/docs/api/query) to aggregate events:
//    - 'trial_started' → trialStarts
//    - 'subscription_activated' → subscriptionActivations + trialToSubscriptionConversions
//      (trialToSubscriptionConversions = subscriptions where preceding 'trial_started' event exists)
//    - 'subscription_cancelled' → subscriptionCancellations
//    - 'charge_fired' → totalChargesFired
//    PostHog events are emitted by the Flutter SDK (ARCH-30, NFR-B1, Story 1.12)
// 3. For totalDisbursedToCharity: query charge_events table (DATABASE_URL) grouping charityAmountCents by day
//    since charity disbursement data lives in DB, not PostHog
// 4. Return time-series arrays bucketed by day

// Stub fixture (no POSTHOG_API_KEY or no DATABASE_URL):
// Return zero-count series for the requested date range
// Generate date array from `from` to `to` with count: 0 for each metric
// TODO(impl): Replace with real PostHog Query API call + DB query
const stubSeries = (from: string, to: string): MetricSeriesSchema[] => {
  // generate daily dates from from..to with count: 0
  // TODO(impl): implement date range generation
  return []
}

// Note: POSTHOG_API_KEY must be added as a Cloudflare Worker secret (same as ADMIN_JWT_SECRET pattern).
// Access via: c.env?.POSTHOG_API_KEY
// No POSTHOG_API_KEY → stub mode (same pattern as DATABASE_URL guard).

// Error responses:
// 400 — from or to is missing / invalid
// 500 — operatorEmail not present
```

**Auth guard:** Add `app.use('/admin/v1/monitoring/*', adminAuthMiddleware)` in `index.ts`.

**Subtasks:**
- [x] Add `GET /admin/v1/monitoring/metrics` endpoint with query param validation (`from`, `to`)
- [x] Stub fixture returns empty date-bucketed series for the requested range
- [x] Guard missing `operatorEmail`
- [x] Add `app.use('/admin/v1/monitoring/*', adminAuthMiddleware)` to `index.ts`

---

### Task 4: Replace `MonitoringPage` stub in `apps/admin/src/pages/DashboardShell.tsx` with real component (AC: 1, 2)

The current `DashboardShell.tsx` has an inline stub `MonitoringPage` function (lines 14–16). This story replaces it with a dedicated file and adds alert badge support to the sidebar.

#### 4a: New file `apps/admin/src/pages/MonitoringPage.tsx`

```typescript
// Route: /monitoring (already wired in DashboardShell.tsx line 135)
// On mount: fetch GET /admin/v1/monitoring/metrics?from=<30 days ago>&to=<today>
// Default date range: last 30 days

// ── Date range controls ────────────────────────────────────────────────────────
// Two date inputs: "From" and "To" (type="date")
// On change: re-fetch metrics for new range
// State: from (string), to (string), metrics (MetricsResponse | null), loading (boolean), error (string | null)

// ── Metrics display ────────────────────────────────────────────────────────────
// Show each metric as a simple table with columns: Date | Count
// Sections (each collapsible or simple heading + table):
//   - Trial Starts
//   - Trial-to-Subscription Conversions
//   - Subscription Activations
//   - Subscription Cancellations
//   - Total Charges Fired
//   - Total Disbursed to Charity (show in dollars: count / 100 — stored as cents)
// While loading: show "Loading metrics..." text
// On error: show error message in red

// ── Auth pattern ────────────────────────────────────────────────────────────────
const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'
// 401 → clearAuth() + navigate('/login')
// import { getToken, clearAuth } from '../lib/auth'

// ── Styling ────────────────────────────────────────────────────────────────────
// Inline styles only. Arial/Helvetica. #2c3e50/#34495e palette.
// Table style: width 100%, border-collapse collapse, fontSize '0.9rem'
// Header row: background '#34495e', color '#ecf0f1'
// Alternating rows: background '#f9f9f9' / '#fff'
// setLoading(false) in ALL early-return error paths (Story 11.2 lesson)
```

#### 4b: Alert badge support — polling component + sidebar badge

**File to modify:** `apps/admin/src/pages/DashboardShell.tsx`

Add alert polling and badge display:

```typescript
// ── Alert polling ──────────────────────────────────────────────────────────────
// Add state: unacknowledgedAlertCount (number), initialized to 0
// On DashboardShell mount: start setInterval polling GET /admin/v1/alerts every 60 seconds
// On each poll: update unacknowledgedAlertCount from response.data.unacknowledgedCount
// Clear interval in useEffect cleanup (prevent memory leaks — same as ImpersonateUserPage.tsx timeout pattern)
// 401 on poll → clearAuth() + navigate('/login')
// Non-401 errors: silently ignore (don't interrupt operator workflow)
// Auth: include Authorization: Bearer ${getToken()} header

// ── Sidebar badge on "Monitoring" NavLink ──────────────────────────────────────
// Wrap the "Monitoring" NavLink text to include a badge when unacknowledgedAlertCount > 0:
// <NavLink to="/monitoring" style={...}>
//   Monitoring
//   {unacknowledgedAlertCount > 0 && (
//     <span style={{
//       background: '#e74c3c',
//       color: '#fff',
//       borderRadius: '50%',
//       padding: '0.1rem 0.4rem',
//       fontSize: '0.7rem',
//       marginLeft: '0.4rem',
//       fontWeight: 'bold',
//     }}>
//       {unacknowledgedAlertCount}
//     </span>
//   )}
// </NavLink>

// IMPORTANT: Do NOT change sidebar structure, header, logout handler, or any existing routes.
// Do NOT modify BillingPage stub — it is out of scope for this story.
// Do NOT modify DisputesPage, UsersPage, ImpersonateUserPage, UserChargesPage imports.
```

**Also in DashboardShell.tsx:** Replace the inline `MonitoringPage` stub (lines 14–16) with an import:

```typescript
// Remove:
// function MonitoringPage() {
//   return <h2>Monitoring</h2>
// }

// Add import:
import MonitoringPage from './MonitoringPage'
```

**Subtasks:**
- [x] Create `apps/admin/src/pages/MonitoringPage.tsx`: date range controls, metrics fetch, table display per metric category
- [x] Modify `apps/admin/src/pages/DashboardShell.tsx`: add alert polling interval, badge on Monitoring nav item, replace inline `MonitoringPage` stub with import
- [x] Ensure 401 responses redirect to `/login` with `clearAuth()` in all fetch calls
- [x] `setLoading(false)` in ALL early-return paths

---

### Task 5: Write tests for alerts endpoint (AC: 1)

**New test file:** `apps/admin-api/test/routes/alerts.test.ts`

Model after `apps/admin-api/test/routes/charges.test.ts` — same import pattern, same auth-bypass behaviour.

```typescript
import { describe, expect, it } from 'vitest'

const app = (await import('../../src/index.js')).default

describe('GET /admin/v1/alerts', () => {
  it('returns 200 with alerts array and unacknowledgedCount', async () => { /* ... */ })
  it('returns array with at least one alert in stub mode', async () => { /* ... */ })
  it('unacknowledgedCount equals number of returned alerts in stub mode', async () => { /* ... */ })
  it('each alert has required fields: id, type, severity, title, referenceId, referenceType, createdAt, acknowledged', async () => { /* ... */ })
  it('severity values are one of: info, warning, critical', async () => { /* ... */ })
})

describe('POST /admin/v1/alerts/:alertId/acknowledge', () => {
  it('returns 200 with alertId and acknowledgedAt', async () => { /* ... */ })
  it('acknowledgedAt is a valid ISO timestamp', async () => { /* ... */ })
})

describe('GET /admin/v1/monitoring/metrics', () => {
  it('returns 200 with all metric categories present', async () => { /* ... */ })
  it('returns 400 when from query param is missing', async () => { /* ... */ })
  it('returns 400 when to query param is missing', async () => { /* ... */ })
})
```

**Minimum test count after story:** 10 new tests + 32 existing = 42 total.

**Auth note:** `ADMIN_JWT_SECRET` is undefined in Vitest → `adminAuthMiddleware` bypasses auth. No `Authorization` header needed in tests.

**Run:** `cd apps/admin-api && npm test` — all 42+ tests must pass.

**Subtasks:**
- [x] Create `apps/admin-api/test/routes/alerts.test.ts` with at least 10 tests
- [x] Run `cd apps/admin-api && npm test` — all tests pass, count reported

---

## Dev Notes

### Critical Architecture Constraints (carry-forward from Stories 11.1–11.4)

**`apps/admin-api` is a separate Cloudflare Worker — NEVER import from `apps/api/src/`.**
Any shared helpers must be duplicated or sourced from `@ontask/core`. [Source: architecture.md lines 774–797, 1070–1072]

**`OpenAPIHono` throughout — no plain `Hono`.**
Every route file uses `new OpenAPIHono<{ Bindings: CloudflareBindings }>()` and `createRoute`. All routes must use `app.openapi()` with full Zod schemas. Do NOT use `app.get()` / `app.post()`. [Source: charges.ts line 15]

**`ok()` and `err()` helpers — always import with `.js` extension:**
```typescript
import { ok, err } from '../lib/response.js'
import { getDb } from '../db/index.js'
```

**`c.env?.DATABASE_URL` uses optional chaining.**
`c.env` is `undefined` in Vitest (no Cloudflare runtime). Use `c.env?.DATABASE_URL` — never `c.env.DATABASE_URL`. Same for `c.env?.POSTHOG_API_KEY` (new env var this story). [Source: charges.ts, admin-auth.ts line 33]

**`(c as any).get('operatorEmail')` type cast — mandatory in every handler.**
OpenAPIHono route-level context does not carry the Variables type. Use `(c as any).get('operatorEmail') as string | undefined`. Do NOT try to fix the typing. [Source: disputes.ts line 352, charges.ts]

**Guard missing operatorEmail — return 500.**
Every handler must check:
```typescript
const operatorEmail = (c as any).get('operatorEmail') as string | undefined
if (!operatorEmail) return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)
```
[Source: Story 11.3 review finding, charges.ts, disputes.ts]

**Stub fixture fallback is mandatory when `DATABASE_URL` or `POSTHOG_API_KEY` undefined.**
Every handler must have a stub fallback that enables tests without external dependencies. Never remove the stub.

**`TODO(impl):` prefix for all stub comments.** Never use generic `TODO:`. [Source: charges.ts, disputes.ts]

**Auth guard in `index.ts` — follow exact existing pattern:**
```typescript
// Existing (DO NOT REMOVE):
app.use('/admin/v1/disputes/*', adminAuthMiddleware)
app.use('/admin/v1/disputes', adminAuthMiddleware)   // ← exact-match guard for list route
app.use('/admin/v1/users/*', adminAuthMiddleware)
app.use('/admin/v1/charges/*', adminAuthMiddleware)
app.use('/admin/v1/impersonation/*', adminAuthMiddleware)

// Add for new routes (this story):
app.use('/admin/v1/alerts', adminAuthMiddleware)      // exact match for GET /admin/v1/alerts
app.use('/admin/v1/alerts/*', adminAuthMiddleware)    // sub-paths: POST .../acknowledge
app.use('/admin/v1/monitoring/*', adminAuthMiddleware)
```

Note: The disputes router uses BOTH an exact guard and a wildcard guard. The `alerts` list endpoint (`GET /admin/v1/alerts`) is an exact path, not a sub-path, so it also needs the exact guard.

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
In every React component, any early return path (error, 404, auth failure, etc.) must call `setLoading(false)` before returning.

### MonitoringPage Stub Replacement

The existing `DashboardShell.tsx` has an inline stub (lines 14–16):
```typescript
function MonitoringPage() {
  return <h2>Monitoring</h2>
}
```
This story **removes** that inline stub and replaces it with a proper import of the new `MonitoringPage.tsx` file. The route in `<Routes>` (`<Route path="/monitoring" element={<MonitoringPage />} />` at line 135) does **not** need to change — only the component definition and import changes.

The `BillingPage` stub (lines 10–12) must remain untouched — it is not in scope for this story.

### Alert Polling Design (Admin SPA)

- Polling interval: 60 seconds (not faster — avoids hammering the API in an admin-only tool)
- Start polling in `useEffect` on DashboardShell mount (the shell is always mounted when logged in)
- Use `setInterval` with cleanup in `useEffect` return function — same pattern as `ImpersonateUserPage.tsx` timer
- Non-401 poll errors must be silently swallowed — never show a polling error to the operator
- 401 on poll → `clearAuth()` + `navigate('/login')` (session expired)

Badge styling spec:
```typescript
const badgeStyle: React.CSSProperties = {
  background: '#e74c3c',
  color: '#fff',
  borderRadius: '50%',
  padding: '0.1rem 0.4rem',
  fontSize: '0.7rem',
  marginLeft: '0.4rem',
  fontWeight: 'bold',
  display: 'inline-block',
}
```

### PostHog Integration Notes (AC: 2)

- PostHog event names in use (from Story 1.12, ARCH-30): `trial_started`, `trial_expired`, `subscription_activated`, `subscription_cancelled`, `task_completed`, `stake_set`, `charge_fired`
- The metrics endpoint queries PostHog via its server-side Query API — the key is `POSTHOG_API_KEY` stored as a Cloudflare Worker secret
- `c.env?.POSTHOG_API_KEY` — same optional-chaining pattern as `c.env?.DATABASE_URL`
- No separate analytics store for v1 — PostHog is the single source of truth for behavioral events
- `totalDisbursedToCharity` is an exception: this data is only in the DB (`chargeEventsTable.charityAmountCents`), not in PostHog, so it requires a DB query
- For v1, if `POSTHOG_API_KEY` is absent (stub mode), return zero-count series — this is acceptable
- The `monitoring/metrics` endpoint is a stub in this story with `TODO(impl)` for the real PostHog Query API integration

### DB Tables in Scope (Read-Only Queries)

The alerts endpoint reads from existing tables — no new schema migrations in this story:

- `chargeEventsTable` — query `WHERE status = 'failed'` for payment failure alerts
- `disputeReviewsTable` — query `WHERE status = 'pending'` for dispute alerts and SLA warnings

Both tables already exist and are defined in `@ontask/core`. Import as:
```typescript
import { chargeEventsTable, disputeReviewsTable } from '@ontask/core'
```

No new schema tables are introduced in this story. The `operator_alert_acks` table (for persistent acknowledgement) is deferred with `TODO(impl)`.

### SLA Warning Thresholds (alerts endpoint)

Match the existing dispute SLA logic already implemented in disputes.ts:
- `hoursElapsed < 18` → `'ok'` (no alert)
- `hoursElapsed >= 18` → `dispute_sla_warning`, severity `'warning'`
- `hoursElapsed >= 22` → `dispute_sla_warning`, severity `'critical'` (consistent with existing amber/red threshold in DisputeDetailPage)

The `hoursElapsed` field is computed as `(Date.now() - dispute.filedAt) / 3_600_000`.

### What This Story Does NOT Include

- No new DB schema tables or migrations — all tables queried are pre-existing
- No `operator_alert_acks` table (persistent acknowledgement is `TODO(impl)`)
- No WebSocket or Server-Sent Events — polling only
- No Flutter app changes — operator dashboard is web-only
- No `apps/api` changes — all routes in `apps/admin-api`
- No changes to `BillingPage` stub — keep as-is
- No changes to DisputesPage, UsersPage, UserChargesPage, ImpersonateUserPage, LoginPage
- No real PostHog Query API call implementation — stub returns empty series, with `TODO(impl)` notes
- No CSS framework — inline styles only

### File Locations

```
apps/admin-api/
├── src/
│   ├── index.ts                         ← MODIFY: add auth guards + mount alertsRouter
│   └── routes/
│       ├── alerts.ts                    ← CREATE: GET /alerts, POST /alerts/:id/acknowledge, GET /monitoring/metrics
│       ├── impersonation.ts             ← DO NOT MODIFY
│       ├── disputes.ts                  ← DO NOT MODIFY
│       ├── charges.ts                   ← DO NOT MODIFY
│       └── auth.ts                      ← DO NOT MODIFY
├── test/
│   └── routes/
│       ├── alerts.test.ts               ← CREATE: ≥10 tests
│       ├── impersonation.test.ts        ← DO NOT MODIFY (7 passing tests)
│       ├── charges.test.ts              ← DO NOT MODIFY (10 passing tests)
│       ├── disputes.test.ts             ← DO NOT MODIFY (10 passing tests)
│       └── auth.test.ts                 ← DO NOT MODIFY (5 passing tests)

apps/admin/src/pages/
├── DashboardShell.tsx                   ← MODIFY: remove inline MonitoringPage, import MonitoringPage, add alert polling + badge
├── MonitoringPage.tsx                   ← CREATE: date range controls, PostHog metrics display
├── ImpersonateUserPage.tsx              ← DO NOT MODIFY
├── UsersPage.tsx                        ← DO NOT MODIFY
├── UserChargesPage.tsx                  ← DO NOT MODIFY
├── DisputesPage.tsx                     ← DO NOT MODIFY
├── DisputeDetailPage.tsx                ← DO NOT MODIFY
└── LoginPage.tsx                        ← DO NOT MODIFY
```

### Existing Test Baseline

- **Current passing tests:** 32 total (7 impersonation + 10 charges + 10 disputes + 5 auth)
- **After this story:** 42+ minimum (32 existing + 10 new alerts.test.ts)
- Run: `cd apps/admin-api && npm test`
- Vitest config: `{ test: { globals: true } }` — no Cloudflare worker pool needed
- Auth bypass: `adminAuthMiddleware` skips when `ADMIN_JWT_SECRET` is undefined — alert tests do NOT need auth headers

### Stub Fixture Design

**`GET /admin/v1/alerts` stub (no DATABASE_URL):**
```typescript
const stubAlerts = [
  {
    id: crypto.randomUUID(),
    type: 'payment_failure' as const,
    severity: 'critical' as const,
    title: 'Payment failed',
    detail: 'TODO(impl): real charge detail',
    referenceId: '00000000-0000-4000-a000-000000000001',
    referenceType: 'charge' as const,
    createdAt: new Date().toISOString(),
    acknowledged: false,
  },
  {
    id: crypto.randomUUID(),
    type: 'dispute_sla_warning' as const,
    severity: 'warning' as const,
    title: 'Dispute SLA warning',
    detail: 'Approaching 24h SLA',
    referenceId: '00000000-0000-4000-a000-000000000002',
    referenceType: 'dispute' as const,
    createdAt: new Date().toISOString(),
    acknowledged: false,
  },
  {
    id: crypto.randomUUID(),
    type: 'new_dispute' as const,
    severity: 'info' as const,
    title: 'New dispute filed',
    detail: null,
    referenceId: '00000000-0000-4000-a000-000000000003',
    referenceType: 'dispute' as const,
    createdAt: new Date().toISOString(),
    acknowledged: false,
  },
]
return c.json(ok({ alerts: stubAlerts, unacknowledgedCount: stubAlerts.length }))
```

**`GET /admin/v1/monitoring/metrics` stub (no POSTHOG_API_KEY or DATABASE_URL):**
```typescript
const emptyMetrics = {
  trialStarts: [],
  trialToSubscriptionConversions: [],
  subscriptionActivations: [],
  subscriptionCancellations: [],
  totalChargesFired: [],
  totalDisbursedToCharity: [],
  dateRange: { from: from ?? '', to: to ?? '' },
}
return c.json(ok(emptyMetrics))
```

### Previous Story Intelligence (from Stories 11.1–11.4)

- `c.env` is `undefined` in Vitest — always `c.env?.X` (optional chaining) for any env var
- `(c as any).get('operatorEmail')` is the required cast — do not attempt to fix or work around it
- `operatorEmail` guard inside `if (databaseUrl)` block for DB-path — but guard ALSO needed before returning stub if any business logic uses it. In stub-only handlers that don't need operatorEmail for correctness (like metrics stub), operatorEmail guard is still required to maintain the security invariant.
- Story 11.2 review finding: `setLoading(false)` must be called in ALL early-return paths in React components
- Story 11.3 review finding: guard missing operatorEmail and return 500
- Story 11.4 pattern: `setInterval` cleanup in `useEffect` return — reuse this exact pattern for the 60-second alert polling in DashboardShell
- Total test count after Story 11.4: 32 (7 impersonation + 10 charges + 10 disputes + 5 auth) — do not reduce this
- `DashboardShell.tsx` has an inline stub `MonitoringPage` at lines 14–16 — this story removes it and adds an import

### References

- Epic 11 goal: FR51–54, NFR-S6, NFR-R3, NFR-B1 [Source: `_bmad-output/planning-artifacts/epics.md` line 2345]
- Story 11.5 AC: [Source: `_bmad-output/planning-artifacts/epics.md` lines 2457–2468]
- FR54 (operator alerts for payment failures and disputes): [Source: `_bmad-output/planning-artifacts/epics.md` line 115]
- NFR-B1 (key business events queryable for analytics): [Source: `_bmad-output/planning-artifacts/epics.md` line 197]
- ARCH-30 (PostHog for product analytics): [Source: `_bmad-output/planning-artifacts/epics.md` line 253]
- NFR-R3 (24-hour dispute SLA): [Source: `_bmad-output/planning-artifacts/epics.md` line 165]
- PostHog event names from Story 1.12: [Source: `_bmad-output/planning-artifacts/epics.md` line 807]
- `charges.ts` route pattern (model for alerts.ts): [Source: `apps/admin-api/src/routes/charges.ts`]
- `disputes.ts` route pattern + SLA threshold logic: [Source: `apps/admin-api/src/routes/disputes.ts`]
- `index.ts` auth guard and router mount pattern: [Source: `apps/admin-api/src/index.ts`]
- `getDb()` (neon-http driver, camelCase): [Source: `apps/admin-api/src/db/index.ts`]
- `ok()`/`err()` helpers: [Source: `apps/admin-api/src/lib/response.ts`]
- `adminAuthMiddleware` (bypass on missing secret): [Source: `apps/admin-api/src/middleware/admin-auth.ts`]
- `DashboardShell.tsx` (inline MonitoringPage stub lines 14–16, Monitoring route line 135): [Source: `apps/admin/src/pages/DashboardShell.tsx`]
- `ImpersonateUserPage.tsx` (setInterval cleanup pattern to reuse for polling): [Source: `apps/admin/src/pages/ImpersonateUserPage.tsx`]
- `DisputeDetailPage.tsx` (fetch pattern, auth header, 401 redirect, inline styles): [Source: `apps/admin/src/pages/DisputeDetailPage.tsx`]
- Auth helpers (`getToken`, `clearAuth`): [Source: `apps/admin/src/lib/auth.ts`]
- Worker separation constraint: [Source: `_bmad-output/planning-artifacts/architecture.md` lines 774–797, 1070–1072]
- PostHog server-side analytics service location: [Source: `_bmad-output/planning-artifacts/architecture.md` line 758]
- Story 11.4 dev notes (test baseline, patterns, constraints): [Source: `_bmad-output/implementation-artifacts/11-4-user-impersonation.md`]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `operatorEmail` guard placement: moved inside `if (databaseUrl)` block to match impersonation.ts pattern. When `ADMIN_JWT_SECRET` is absent in Vitest, middleware calls `next()` without setting `operatorEmail`, causing 500s if guard runs before databaseUrl check.

### Completion Notes List

- Created `apps/admin-api/src/routes/alerts.ts` with three endpoints: `GET /admin/v1/alerts` (stub returns 3 alerts: payment_failure/critical, dispute_sla_warning/warning, new_dispute/info), `POST /admin/v1/alerts/:alertId/acknowledge` (stub returns alertId+acknowledgedAt), and `GET /admin/v1/monitoring/metrics` (stub returns empty series arrays for all 6 metric categories with dateRange). All use OpenAPIHono + createRoute + ok()/err() helpers. DB path guards operatorEmail; stub path proceeds safely.
- Updated `apps/admin-api/src/index.ts`: added import for alertsRouter, auth guards for `/admin/v1/alerts`, `/admin/v1/alerts/*`, `/admin/v1/monitoring/*`, and mounted alertsRouter.
- Created `apps/admin/src/pages/MonitoringPage.tsx`: date range controls (type="date" inputs defaulting to last 30 days), fetches GET /admin/v1/monitoring/metrics on mount and on date change, displays 6 metric categories as tables (Date/Count columns), shows "Loading metrics..." while loading, error in red on failure, 401 redirects to /login. setLoading(false) in all error paths.
- Updated `apps/admin/src/pages/DashboardShell.tsx`: removed inline MonitoringPage stub, added import of MonitoringPage. Added useState for unacknowledgedAlertCount, useEffect polling GET /admin/v1/alerts every 60 seconds with setInterval cleanup, 401 redirect, silent non-401 error handling. Badge renders on Monitoring NavLink when count > 0.
- Created `apps/admin-api/test/routes/alerts.test.ts`: 10 tests covering GET /admin/v1/alerts (5), POST /admin/v1/alerts/:alertId/acknowledge (2), GET /admin/v1/monitoring/metrics (3). All 42 total tests pass.

### File List

- `apps/admin-api/src/routes/alerts.ts` (created)
- `apps/admin-api/src/index.ts` (modified)
- `apps/admin-api/test/routes/alerts.test.ts` (created)
- `apps/admin/src/pages/MonitoringPage.tsx` (created)
- `apps/admin/src/pages/DashboardShell.tsx` (modified)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified)

## Change Log

- 2026-04-02: Story 11.5 implemented — operator alerts polling endpoint (GET /admin/v1/alerts, POST /admin/v1/alerts/:alertId/acknowledge), business event monitoring endpoint (GET /admin/v1/monitoring/metrics), MonitoringPage.tsx with date range controls and metrics tables, DashboardShell.tsx alert polling with sidebar badge, 10 new tests (42 total passing).
