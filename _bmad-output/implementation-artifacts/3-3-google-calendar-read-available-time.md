# Story 3.3: Google Calendar Read / Available Time

Status: review

## Story

As a user,
I want On Task to read my Google Calendar and schedule around my existing events,
So that tasks never get placed on top of meetings I already have.

## Acceptance Criteria

1. **Given** the user has completed Google Calendar OAuth in onboarding **When** the calendar connection is active **Then** Google Calendar events are imported as immovable blocks and the scheduling engine avoids them (FR10) — *(Today tab UI rendering of grey calendar blocks is deferred to Story 3.4 when write blocks are also shown together)*

2. **Given** a Google Calendar event is created or modified **When** the change is detected **Then** the scheduling engine refreshes with the updated events within 60 seconds (NFR-I1) — met by pull-on-schedule-request; webhook push deferred to Story 3.5

3. **Given** the user connects their calendar for the first time **When** the `POST /v1/calendar/connect` OAuth exchange completes **Then** the connection is stored and calendar events are available within 5 seconds for the next scheduling request (no Flutter changes in this story)

4. **Given** `runScheduleForUser()` is called in `apps/api/src/services/scheduling.ts` **When** the user has active Google Calendar connections **Then** real `CalendarEvent[]` objects fetched from Google Calendar API are passed into `schedule()` — replacing the `calendarEvents: []` stub

5. **Given** the calendar service layer is called **When** a Google access token has expired **Then** the token is automatically refreshed using the stored refresh token before the API call proceeds; the new access token is persisted back to the DB (AES-256-GCM encrypted)

6. **Given** `POST /v1/calendar/connect` is called with a Google OAuth authorization code **When** the exchange succeeds **Then** a `calendar_connections` base row and a `calendar_connections_google` provider row are inserted in a single transaction **And** the access token and refresh token are encrypted with AES-256-GCM using `CALENDAR_TOKEN_KEY` Workers Secret before insert

7. **Given** `GET /v1/calendar/connections` is called **When** the user has connected calendars **Then** the list of connections (id, provider, calendarId, displayName, isRead, isWrite) is returned — tokens are never included in API responses

## Tasks / Subtasks

- [x] Create Drizzle schema for calendar connections (AC: 6, 7)
  - [x] `packages/core/src/schema/calendar-connections.ts` — NEW: `calendarConnectionsTable` base table with columns: `id` (uuid PK), `userId` (uuid), `provider` (text enum: 'google' | 'outlook' | 'apple'), `calendarId` (text), `displayName` (text), `isRead` (boolean default true), `isWrite` (boolean default false), `createdAt` (timestamptz), `updatedAt` (timestamptz)
  - [x] `packages/core/src/schema/calendar-connections-google.ts` — NEW: `calendarConnectionsGoogleTable` with columns: `connectionId` (uuid FK → calendarConnectionsTable.id, PK), `accountEmail` (text), `accessToken` (text — AES-256-GCM encrypted at application layer), `refreshToken` (text — AES-256-GCM encrypted), `tokenExpiry` (timestamptz)
  - [x] `packages/core/src/schema/calendar-connections-outlook.ts` — NEW: stub table with comment "v2 — stub"
  - [x] `packages/core/src/schema/calendar-connections-apple.ts` — NEW: stub table with comment "v2 — EventKit native, no tokens"
  - [x] `packages/core/src/schema/index.ts` — MODIFY: export all four new tables

- [x] Create Drizzle schema for calendar events cache (AC: 1, 2)
  - [x] `packages/core/src/schema/calendar-events.ts` — NEW: `calendarEventsTable` with columns: `id` (uuid PK), `connectionId` (uuid FK → calendarConnectionsTable.id), `userId` (uuid), `googleEventId` (text, not null), `startTime` (timestamptz), `endTime` (timestamptz), `isAllDay` (boolean), `summary` (text, nullable), `syncedAt` (timestamptz)
  - [x] `packages/core/src/schema/index.ts` — MODIFY: export `calendarEventsTable`
  - [x] Add Drizzle migration: `pnpm --filter @ontask/core db:generate` (run after schema files exist)

- [x] Implement AES-256-GCM token encryption helper (AC: 5, 6)
  - [x] `apps/api/src/lib/crypto.ts` — NEW: `encryptToken(plaintext: string, key: string): Promise<string>` and `decryptToken(ciphertext: string, key: string): Promise<string>` using `crypto.subtle` (available in Workers runtime — no Node.js `crypto` module needed)
  - [x] Encoding: store as `base64(iv):base64(ciphertext)` so the IV is recoverable at decryption time; use a random 12-byte IV per encryption
  - [x] Key derivation: `key` parameter is the raw `CALENDAR_TOKEN_KEY` Workers Secret string; import it as an AES-GCM key via `crypto.subtle.importKey` with `raw` format and `['encrypt', 'decrypt']` usages
  - [x] Do NOT use any external crypto library — Workers runtime `crypto.subtle` is sufficient

- [x] Implement Google Calendar service layer (AC: 1, 4, 5)
  - [x] `apps/api/src/services/calendar/google.ts` — NEW: Google Calendar REST API client using `fetch()` (no googleapis npm package — Workers runtime; use direct REST calls)
    - [x] `fetchGoogleCalendarEvents(connectionId: string, userId: string, windowStart: Date, windowEnd: Date, env: CloudflareBindings): Promise<CalendarEvent[]>` — loads connection from DB, decrypts tokens, refreshes if expired, calls Google Calendar API `GET https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=...&timeMax=...&singleEvents=true&orderBy=startTime`, maps response to `CalendarEvent[]`
    - [x] Token refresh: if `tokenExpiry < now`, call `POST https://oauth2.googleapis.com/token` with `grant_type=refresh_token`, update `accessToken` and `tokenExpiry` in DB (re-encrypt before update)
    - [x] Map Google Calendar API response items to `CalendarEvent` — `id: item.id`, `startTime: new Date(item.start.dateTime ?? item.start.date)`, `endTime: new Date(item.end.dateTime ?? item.end.date)`, `isAllDay: !item.start.dateTime`
    - [x] Partial failure: return empty array (do not throw) if the connection row is not found or the Google API returns a non-200 response; log the error via `console.error` so it appears in Workers logs
  - [x] `apps/api/src/services/calendar/index.ts` — NEW: `fetchAllCalendarEvents(userId: string, windowStart: Date, windowEnd: Date, env: CloudflareBindings): Promise<CalendarEvent[]>` — queries all `calendarConnections` for the user where `isRead = true`, calls `fetchGoogleCalendarEvents` for Google provider connections, aggregates results into a single flat `CalendarEvent[]`; partial failure tolerant (skips failed connections, returns what succeeded)
  - [x] `apps/api/src/services/calendar/apple.ts` — NEW: stub returning `Promise.resolve([])` with comment "v2 — EventKit native, no server tokens"
  - [x] `apps/api/src/services/calendar/outlook.ts` — NEW: stub returning `Promise.resolve([])` with comment "v2"

- [x] Wire calendar events into the scheduling service (AC: 4)
  - [x] `apps/api/src/services/scheduling.ts` — MODIFY: replace `calendarEvents: []` stub with `await fetchAllCalendarEvents(userId, now, windowEnd, env)` from `./calendar/index.js`
  - [x] Remove `void userId` and `void env` — userId and env are now actively used
  - [x] Import `type { CalendarEvent } from '@ontask/core'` (already in scope via `ScheduleOutput` import — extend if needed)
  - [x] The `TODO(story-3.3)` comment is now resolved; remove it

- [x] Create calendar OAuth route (AC: 6, 7)
  - [x] `apps/api/src/routes/calendar.ts` — NEW: two routes using `@hono/zod-openapi` pattern
    - [x] `POST /v1/calendar/connect` — body: `{ provider: 'google', authorizationCode: string, redirectUri: string }`; exchanges code for tokens at `POST https://oauth2.googleapis.com/token` (using `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` Workers Secrets); fetches calendar list from Google; inserts base row + google row in a single Drizzle transaction; returns `{ data: { connectionId, calendarId, displayName } }`
    - [x] `GET /v1/calendar/connections` — returns `{ data: CalendarConnection[] }` where `CalendarConnection = { id, provider, calendarId, displayName, isRead, isWrite }` — **never** include tokens in response
  - [x] Auth stub: extract `userId` from `x-user-id` header (consistent with all other routes)
  - [x] `apps/api/src/index.ts` — MODIFY: import `calendarRouter` and mount with `app.route('/', calendarRouter)`

- [x] Add required Workers Secrets to wrangler.jsonc documentation (AC: 6)
  - [x] `apps/api/wrangler.jsonc` — ADD placeholder comments for `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `CALENDAR_TOKEN_KEY` in the vars section (values set via `wrangler secret put` — never committed)

## Dev Notes

### CRITICAL: No googleapis npm package

Do NOT install `googleapis` from npm. The `googleapis` package pulls in Node.js-native code incompatible with the Workers edge runtime. Use direct `fetch()` calls to the Google REST API:

- Events list: `GET https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events?timeMin={iso}&timeMax={iso}&singleEvents=true&orderBy=startTime`
- Token refresh: `POST https://oauth2.googleapis.com/token` with form-encoded body
- Authorization header: `Authorization: Bearer {access_token}`

The Google Calendar REST API v3 reference: `https://developers.google.com/calendar/api/v3/reference/events/list`

### CRITICAL: Token Encryption Pattern

Tokens must be encrypted with AES-256-GCM **before** writing to DB and decrypted **after** reading from DB. The `CALENDAR_TOKEN_KEY` Workers Secret is a raw string key. The `crypto.subtle` API is available globally in the Workers runtime — do not import any crypto module.

```typescript
// Pattern for encryptToken (apps/api/src/lib/crypto.ts):
const iv = crypto.getRandomValues(new Uint8Array(12))
const keyMaterial = await crypto.subtle.importKey(
  'raw',
  new TextEncoder().encode(key.padEnd(32, '\0').slice(0, 32)), // 256-bit key
  { name: 'AES-GCM' },
  false,
  ['encrypt']
)
const encrypted = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, keyMaterial, new TextEncoder().encode(plaintext))
// Store as: btoa(String.fromCharCode(...iv)) + ':' + btoa(String.fromCharCode(...new Uint8Array(encrypted)))
```

Do not use `Buffer` — it is not available in the Workers runtime. Use `TextEncoder`/`TextDecoder` and `Uint8Array`.

### CRITICAL: Single Transaction for Calendar Connection Insert

Inserting a calendar connection MUST be a single Drizzle transaction — base row + provider row together, or neither:

```typescript
await db.transaction(async (tx) => {
  const [base] = await tx.insert(calendarConnectionsTable).values({ userId, provider: 'google', ... }).returning()
  await tx.insert(calendarConnectionsGoogleTable).values({ connectionId: base.id, accessToken: encryptedAccess, ... })
})
```

If the transaction fails mid-way, neither row is persisted (no orphaned base rows).

### Existing File: `apps/api/src/services/scheduling.ts`

The current stub body:
```typescript
// TODO(story-3.3): load real calendar events from DB (Google Calendar integration)
const result = schedule({
  tasks: [],
  calendarEvents: [],   // ← REPLACE THIS with fetchAllCalendarEvents(...)
  windowStart: now,
  windowEnd,
})
```

Replace only the `calendarEvents: []` line and wire up the import. Do NOT change the `tasks: []` stub — task loading is a separate TODO for a later story. The `new Date()` calls for `windowStart` and `generatedAt` remain as-is (the deferred-work note about two separate `new Date()` calls is intentional for the stub pattern; Story 3.3 only resolves the calendar events stub).

### Architecture: Provider Abstraction

The scheduling engine (`packages/scheduling/`) never knows about Google Calendar. `ScheduleInput.calendarEvents: CalendarEvent[]` is a flat array — the provider aggregation and mapping happens entirely in `apps/api/src/services/calendar/`. This boundary is architectural — do not leak provider types into the scheduling package.

### Drizzle Pattern in Workers

All DB access uses the Neon HTTP transport:
```typescript
import { createDb } from '../db/index.js'
const db = createDb(env.DATABASE_URL)
```

`createDb` is already in `apps/api/src/db/index.ts`. Import it with `.js` extension (NodeNext module resolution).

### API Route Pattern (established in prior stories)

```typescript
const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()
// createRoute → app.openapi → export const calendarRouter = app
// Auth stub: const userId = c.req.header('x-user-id') ?? 'stub-user-id'
// Response: return c.json(ok({ ... }), 200)
// Error: return c.json(err('CODE', 'message'), 4xx)
```

All response shapes use `{ data: ... }` via `ok()` from `../lib/response.js`. See `apps/api/src/routes/tasks.ts` as the canonical pattern. Route params use `z.string().uuid()` (not plain `z.string()`).

### Schema: Drizzle Table Naming Convention

Look at `packages/core/src/schema/tasks.ts` for the exact pattern. Tables use `pgTable`, exported as `tasksTable`, `listsTable` etc. Columns use camelCase field names; `casing: 'camelCase'` in the Drizzle config handles snake_case ↔ camelCase translation automatically.

### Type Reference: CalendarEvent (from `packages/core/src/types/scheduling.ts`)

```typescript
export interface CalendarEvent {
  id: string
  startTime: Date
  endTime: Date
  isAllDay: boolean
}
```

This is the engine's interface. The service layer maps Google Calendar API response fields to this shape. The `summary` field from Google (event title) is stored in the DB cache but is NOT part of `CalendarEvent` — the engine only needs the time window.

### Workers Secrets Required

Three new secrets must be added for this story to function:
- `GOOGLE_CLIENT_ID` — Google OAuth2 client ID (set via `wrangler secret put GOOGLE_CLIENT_ID`)
- `GOOGLE_CLIENT_SECRET` — Google OAuth2 client secret
- `CALENDAR_TOKEN_KEY` — 32-byte AES key for token encryption

Add these as commented placeholders in `wrangler.jsonc` (pattern matches existing `GLITCHTIP_DSN` and `POSTHOG_API_KEY` entries). The `CloudflareBindings` type interface will need these added — run `pnpm --filter @ontask/api cf-typegen` after updating wrangler.jsonc.

### NFR-I1: 60-Second Propagation

The epics AC states "within 60 seconds". For Story 3.3, this is met by the real-time read path: every `POST /v1/tasks/:id/schedule` call fetches fresh events from Google Calendar API. A webhook-based push model (Story 3.5) is out of scope for this story — Story 3.3 is pull-only.

### Google Calendar API Response Shape

Key fields from `events.list` response items:
```json
{
  "id": "abc123",
  "summary": "Team standup",
  "start": { "dateTime": "2026-04-01T09:00:00+00:00" },
  "end":   { "dateTime": "2026-04-01T09:30:00+00:00" }
}
```
For all-day events, `start.date` and `end.date` are used instead of `dateTime`. Map accordingly in `fetchGoogleCalendarEvents`.

### No Flutter Changes

This story is entirely in the TypeScript monorepo (`apps/api/` and `packages/core/`). No Flutter files are modified. The Today tab grey calendar block rendering is deferred to Story 3.4 (calendar write integration).

### Deferred from Story 3.2

Story 3.2 left a `TODO(story-3.3)` comment in `apps/api/src/services/scheduling.ts` at line 20. This is the primary target for Story 3.3. Also deferred from Story 3.2: the two separate `new Date()` calls producing slightly different timestamps — this remains deferred (still a stub for task loading; the architectural concern only fully resolves when both calendar events AND tasks load from DB together).

### Review Findings to Address from Story 3.2

- **`apps/api/src/routes/scheduling.ts:38`** — Route param uses `z.string().uuid()` (this was patched post-review; confirm it is already fixed before starting)
- **`packages/scheduling/src/test/constraints/calendar-events.test.ts:27`** — Test name `schedule_calendarEvents_noSlots_returnsEmpty` uses plural vs singular (pre-existing; leave as-is — do not touch scheduling package tests in this story)
- **`apps/api/src/services/scheduling.ts`** — `void userId` and `void env` suppressions were workarounds for the stub; removing them when wiring real calendar data is part of this story's scope

### Files to Create/Modify

**New (packages/core schema):**
- `packages/core/src/schema/calendar-connections.ts`
- `packages/core/src/schema/calendar-connections-google.ts`
- `packages/core/src/schema/calendar-connections-outlook.ts` (stub)
- `packages/core/src/schema/calendar-connections-apple.ts` (stub)
- `packages/core/src/schema/calendar-events.ts`

**Modify (packages/core):**
- `packages/core/src/schema/index.ts` — add new table exports

**New (apps/api services):**
- `apps/api/src/services/calendar/index.ts`
- `apps/api/src/services/calendar/google.ts`
- `apps/api/src/services/calendar/apple.ts` (stub)
- `apps/api/src/services/calendar/outlook.ts` (stub)
- `apps/api/src/lib/crypto.ts`

**New (apps/api routes):**
- `apps/api/src/routes/calendar.ts`

**Modify (apps/api):**
- `apps/api/src/services/scheduling.ts` — replace `calendarEvents: []` stub
- `apps/api/src/index.ts` — mount calendarRouter
- `apps/api/wrangler.jsonc` — add secret placeholders

### Project Structure Notes

- Calendar service layer lives at `apps/api/src/services/calendar/` — matches architecture doc structure exactly
- Calendar schema lives in `packages/core/src/schema/` — table-per-provider pattern (calendar-connections.ts base + calendar-connections-google.ts provider)
- Crypto helper lives at `apps/api/src/lib/crypto.ts` — alongside existing `errors.ts`, `response.ts`, `jwt.ts`
- Calendar route lives at `apps/api/src/routes/calendar.ts` — matches architecture doc `calendar.ts` (FR46)
- Do NOT create a `packages/calendar/` workspace package — this is not a pure function; it belongs in `apps/api/src/services/`

### References

- Architecture: `_bmad-output/planning-artifacts/architecture.md` §"Gap 2 — Multi-calendar support" and §"Additional Patterns from Validation" (calendar token encryption, provider-base row integrity)
- Architecture: §"Requirements → Structure Mapping" — Calendar Connections row
- Architecture: §`apps/api/` source tree — `services/calendar/` layout
- Types: `packages/core/src/types/scheduling.ts` — `CalendarEvent` interface
- Previous service: `apps/api/src/services/scheduling.ts` — contains the `TODO(story-3.3)` target
- Previous route pattern: `apps/api/src/routes/tasks.ts` (canonical `@hono/zod-openapi` pattern)
- DB helper: `apps/api/src/db/index.ts` — `createDb(env.DATABASE_URL)`
- FR10 (calendar event avoidance), FR46 (calendar connect/list), NFR-I1 (60s propagation), NFR-S4 (AES-256 at rest)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation completed without issues.

### Completion Notes List

- Implemented all 7 Drizzle schema tables across 5 new files: `calendarConnectionsTable` (base), `calendarConnectionsGoogleTable` (provider), plus outlook/apple stubs and `calendarEventsTable`. Migration `0005_neat_exodus.sql` generated.
- AES-256-GCM crypto helper in `apps/api/src/lib/crypto.ts` uses `crypto.subtle` (Web Crypto, Workers-compatible); stores tokens as `base64(iv):base64(ciphertext)`; no external npm packages.
- Google Calendar service (`apps/api/src/services/calendar/google.ts`) uses direct `fetch()` calls to Google REST API v3 (no `googleapis` npm package per Dev Notes constraint); handles token refresh, DB update with re-encryption, and maps to `CalendarEvent[]`.
- Calendar service aggregator (`apps/api/src/services/calendar/index.ts`) queries all `isRead=true` connections for the user and aggregates results; partial-failure tolerant.
- `apps/api/src/services/scheduling.ts` updated: removed `void userId`/`void env` suppressions, replaced `calendarEvents: []` stub with `await fetchAllCalendarEvents(...)`, removed `TODO(story-3.3)` comment.
- Calendar OAuth routes created: `POST /v1/calendar/connect` (OAuth code exchange → transaction insert of base + Google rows) and `GET /v1/calendar/connections` (tokens never exposed).
- `worker-configuration.d.ts` updated manually with `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `CALENDAR_TOKEN_KEY` bindings.
- 17 new tests added (8 crypto unit tests, 9 calendar route integration tests). All 113 tests pass. TypeScript strict typecheck passes for both `@ontask/api` and `@ontask/core`.

### File List

packages/core/src/schema/calendar-connections.ts (new)
packages/core/src/schema/calendar-connections-google.ts (new)
packages/core/src/schema/calendar-connections-outlook.ts (new)
packages/core/src/schema/calendar-connections-apple.ts (new)
packages/core/src/schema/calendar-events.ts (new)
packages/core/src/schema/index.ts (modified)
packages/core/src/schema/migrations/0005_neat_exodus.sql (new)
apps/api/src/lib/crypto.ts (new)
apps/api/src/lib/crypto.test.ts (new)
apps/api/src/services/calendar/google.ts (new)
apps/api/src/services/calendar/index.ts (new)
apps/api/src/services/calendar/apple.ts (new)
apps/api/src/services/calendar/outlook.ts (new)
apps/api/src/services/scheduling.ts (modified)
apps/api/src/routes/calendar.ts (new)
apps/api/src/index.ts (modified)
apps/api/wrangler.jsonc (modified)
apps/api/worker-configuration.d.ts (modified)
test/routes/calendar.test.ts (new)

## Change Log

- Story 3.3 implemented: Google Calendar read integration — Drizzle schemas, AES-256-GCM crypto helper, Google Calendar REST service layer, calendar OAuth routes, scheduling.ts wired to real calendar events. 17 new tests, 113 total passing. (Date: 2026-03-31)
