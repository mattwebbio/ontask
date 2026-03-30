---
stepsCompleted: ['step-01-init', 'step-02-context', 'step-03-starter', 'step-04-decisions', 'step-05-patterns', 'step-06-structure', 'step-07-validation', 'step-08-complete']
status: 'complete'
completedAt: '2026-03-29'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/product-brief-ontask.md'
  - '_bmad-output/planning-artifacts/product-brief-ontask-distillate.md'
workflowType: 'architecture'
project_name: 'ontask'
user_name: 'Matt'
date: '2026-03-29'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements — 93 FRs across 8 areas:**

| Capability Area | FR Count | Architectural Implication |
|---|---|---|
| Task & List Management | 19 | Core data model; offline-capable CRUD |
| Intelligent Scheduling | 7 | Pure-function engine; TDD-first; explanation API |
| Shared Lists & Household | 8 | Multi-user permissions; assignment strategies |
| Commitment Contracts | 11 | Stripe off-session; idempotency; financial audit trail |
| Proof & Verification | 13 | AI pipeline; B2 media; offline queue; Watch Mode |
| Notifications & Communication | 3 | Push; 3-level configurability; per-device |
| Platform Integrations & API | 7 | REST + MCP (separate Worker); Google Calendar; HealthKit |
| Accounts, Subscriptions & Ops | 18 | Auth (3 providers); trial/billing; operator dashboard |

**Non-Functional Requirements — 30 NFRs across 8 categories:**

Critical architectural constraints:
- **NFR-P1–P11:** 2s cold launch; 500ms task creation; 3s NLP; 60fps animations
- **NFR-S1–S8:** TLS 1.3; AES-256 at rest; PCI SAQ A; short-lived JWTs + refresh rotation
- **NFR-R1–R8:** <0.1% Stripe failure rate; 24h dispute SLA; 99.9% API uptime; offline proof integrity
- **NFR-Q1–Q2:** Deterministic scheduling; 90% unit test coverage on payment + scheduling logic
- **NFR-I1–I6:** Google Calendar 60s propagation; calendar writes within 10s; Stripe webhooks within 30s
- **NFR-B1:** All key business events instrumented and queryable

**Scheduling engine — nudging:**
Nudging is a UI concern, not an NLP concern. The scheduling engine is a pure function that accepts an optional `suggestedDates` parameter alongside its standard inputs (tasks, constraints, calendar state). UI affordances ("Schedule for tomorrow", date pickers) set these suggestions directly. Natural language input (if exposed) is a pre-processing tool that resolves to structured suggested dates before reaching the engine — keeping the engine fully deterministic and NLP-agnostic.

**AI pipeline abstraction:**
All AI calls (proof verification, Watch Mode frame analysis, NLP task parsing, scheduling explanations) route through **Cloudflare AI Gateway** for proxy-level caching, cost/latency analytics, rate limiting, and provider failover. **Vercel AI SDK** provides the code-level unified interface across providers (OpenAI-compatible and Anthropic). These two together replace any custom abstraction layer. The underlying model remains swappable without application code changes.

### Technical Constraints & Dependencies

- **US-only v1** — geographic restriction due to financial penalty licensing risk; non-US must not be foreclosed architecturally
- **PCI SAQ A scope** — never touch raw card data; all via Stripe SetupIntent/PaymentIntent
- **App Store compliance** — commitment contracts via web-based payment setup (post-Epic v. Apple ruling)
- **GDPR/CCPA deferred** — architecture must not foreclose; data residency must be considered in schema design
- **Localization layer** — strings externalized v1; English-only but architecture supports future languages without code changes
- **AI model abstracted** — proof verification, Watch Mode, NLP parsing all behind Cloudflare AI Gateway + Vercel AI SDK; underlying model is swappable
- **Watch Mode constraint** — frames processed in-flight, never persisted; session metadata only

### Cross-Cutting Concerns Identified

1. **Authentication & authorization** — JWT (REST API), OAuth (MCP), Apple/Google Sign In, email+2FA, session revocation (FR91), operator impersonation with immutable audit log (NFR-S6)
2. **Idempotency** — Critical for Stripe webhooks, charge triggers, Every.org disbursement; must be designed into the queue consumer architecture
3. **Offline sync & conflict resolution** — FR94 defines a conflict resolution policy; proof submissions carry client-side timestamps; charge reversal on valid backdated proof
4. **AI pipeline abstraction** — Cloudflare AI Gateway + Vercel AI SDK; unified interface for all LLM calls across proof verification, Watch Mode, NLP parsing, scheduling explanations
5. **Analytics instrumentation** — NFR-B1 requires all key business events to be queryable; instrumentation strategy needed across all layers
6. **Rate limiting** — Applied at API and MCP layers; communicated via response headers; documented in OpenAPI spec
7. **Multi-user shared state** — Shared list membership, round-robin assignment state, pool mode stake tracking; requires careful transaction design
8. **Operator tooling isolation** — Internal dashboard is a separate deployment concern; operator endpoints require distinct auth path

### Scale & Complexity Assessment

- **Project complexity:** High — financial mechanics, AI verification pipeline, real-time calendar sync, multi-user shared state, offline replay
- **Primary technical domain:** Mobile (Flutter) + Edge API (Hono/Workers) + Serverless Postgres (Neon)
- **Estimated architectural components:** ~12 distinct services/subsystems (Flutter client, API layer, scheduling engine, AI pipeline, proof storage, calendar sync, push notifications, Stripe integration, Every.org disbursement, MCP server, operator dashboard, analytics)

## Starter Template Evaluation

### Primary Technology Domains

Dual-domain: Flutter (iOS/macOS client) + Hono on Cloudflare Workers (REST API + MCP server)

### Flutter Client

**Flutter 3.41 (stable)**

Standard `flutter create` with feature-first clean architecture. No third-party scaffolder (e.g. very_good_cli) needed — VGV tooling targets team-scale projects with flavors and multi-environment builds; overhead not warranted for a solo founder setup.

**Initialization:**
```bash
flutter create \
  --org com.ontaskhq \
  --platforms=ios,macos \
  --project-name ontask \
  ontask
```

Note: `--project-name` is the Dart package name (snake_case); `--org` sets the bundle ID prefix. Both are set independently.

**Package stack:**

| Category | Package | Notes |
|---|---|---|
| State management | `flutter_riverpod ^3.3.0` + `riverpod_generator` | Riverpod 3 with compile-time provider safety; `build_runner` in `dev_dependencies` |
| Navigation | `go_router` | Google-maintained, Navigator 2.0 |
| HTTP client | `dio` | Interceptors, cancellation, retries, offline queue support |
| Serialization | `freezed` + `json_serializable` | Immutable data classes via code gen |
| Local DB (offline tasks) | `drift` | SQLite with typed migrations and transaction support — preferred over `isar` for write-heavy offline sync with conflict resolution |
| Simple prefs | `shared_preferences` | Settings, auth token storage |
| Unit/widget testing | `mocktail` | Null-safe mocking |
| Integration testing | `patrol` | Deferred — add when E2E stories exist, not day-one |
| Live Activities | `live_activities` | ActivityKit bridge — Dynamic Island, Lock Screen, push token callbacks; **iOS only**; macOS guard required |

**Project structure (feature-first clean architecture):**
```
lib/
├── core/           # theme, constants, error handling, shared utils
├── features/
│   └── <feature>/
│       ├── data/         # repos, data sources, DTOs
│       ├── domain/       # models, use cases
│       └── presentation/ # widgets, screens, providers
└── main.dart
```

### Hono API + MCP Server

**Hono 4.12.9 · Two separate Cloudflare Workers**

Separated by auth model (JWT for REST API; OAuth for MCP) and consumer type. Neon is the shared integration point — not shared code deployment.

```bash
npm create hono@latest ontask-api -- --template cloudflare-workers
npm create hono@latest ontask-mcp -- --template cloudflare-workers
```

**OpenAPI:** `@hono/zod-openapi` (official Hono package). Zod is the intentional, explicit validation choice for the entire backend — Zod schemas serve as the single source of truth for types, validation, and OpenAPI spec generation.

**AI pipeline:**
```bash
npm install ai @ai-sdk/openai @ai-sdk/anthropic ai-gateway-provider
```
- `ai` (Vercel AI SDK v6) — unified LLM interface across all AI call types
- `ai-gateway-provider` — routes all calls through Cloudflare AI Gateway (caching, cost/latency observability, provider failover). Native Cloudflare Workers AI binding integration via `wrangler.toml`.

**Note:** Project initialization using these commands should be the first implementation stories.

## Core Architectural Decisions

### Repository Structure

**Decision: Monorepo**

```
/apps/flutter/          — Flutter iOS/macOS app (com.ontaskhq)
/apps/api/              — Hono REST API Worker
/apps/mcp/              — Hono MCP Worker
/apps/admin/            — Cloudflare Pages admin SPA
/packages/core/         — shared types, Drizzle schema, domain models
/packages/scheduling/   — scheduling engine (pure function — unit tested here)
/packages/ai/           — AI pipeline abstraction (Vercel AI SDK + ai-gateway-provider)
```

**Why separate Workers:** Cloudflare Workers have a 10MB compressed bundle size limit. The API Worker carries heavy dependencies (Stripe SDK, Google Calendar client, Drizzle, Vercel AI SDK, Zod). The MCP Worker is much lighter. Shared logic lives in `/packages/` as pure TypeScript, tree-shaken and bundled selectively into each Worker.

**Bundle size discipline:** CI runs `wrangler deploy --dry-run` on each Worker and fails the build if either Worker exceeds 8MB (leaving 2MB headroom). All new dependencies audited for bundle impact before merging.

### Database Driver

**`@neondatabase/serverless` with HTTP transport** — required for Cloudflare Workers. Do NOT use `pg` or standard connection pooling. The Drizzle config for Workers uses the Neon HTTP driver explicitly:

```typescript
import { neon } from '@neondatabase/serverless'
import { drizzle } from 'drizzle-orm/neon-http'

const sql = neon(env.DATABASE_URL)
const db = drizzle(sql)
```

This is not optional — standard `pg` connection pooling is incompatible with the Workers edge runtime.

### Offline Conflict Resolution Policy (FR94)

| Data Type | Policy |
|---|---|
| Task properties (title, notes, due date, priority) | Last-write-wins with client timestamp |
| Task completion status | Client timestamp preserved; server reverses charge if valid completion timestamp predates deadline |
| Proof submissions | Client timestamp preserved; server reverses charge if valid proof timestamp predates deadline |
| Commitment contract state | Client timestamp trusted and applied. Clock skew accepted up to **30 days**; beyond that, the server rejects the timestamp. Deliberate manipulation within that window is an accepted edge case. |
| Schedule / calendar blocks | Server-authoritative; scheduling engine runs server-side |

### Push Notifications Infrastructure

**Decision: Direct APNs — no Firebase**

| Layer | Package | Notes |
|---|---|---|
| Hono Worker | `@fivesheepco/cloudflare-apns2` v13.0.0 | Workers-native APNs client; uses `fetch()` + `crypto.subtle` for ES256 JWT signing; no Node.js `net`/`tls` required |
| Flutter (iOS + macOS) | `push` (pub.dev) | APNs-direct, no FCM dependency, covers both iOS and macOS |

**APNs p8 key storage:** `wrangler secret put APNS_KEY` — Workers Secret, not env var.

**Local dev constraint:** `wrangler dev` does NOT support HTTP/2 outbound (open workerd bug). APNs calls will fail locally. APNs integration must be tested against staging (`wrangler deploy --env staging`), not local.

**v2 Android path:** Extend push Worker to call FCM HTTP v1 API alongside APNs. The `push` Flutter package handles Android via FCM when configured — no backend architectural change required.

### Live Activities & WidgetKit

**Decision: `live_activities` Flutter plugin + native Swift Widget Extension targets**

Live Activities (Dynamic Island, Lock Screen) and WidgetKit home screen widgets require native Swift — Flutter cannot render these surfaces directly. The `live_activities` pub.dev package bridges Flutter to ActivityKit via a method channel, handling start/update/end calls and push token callbacks. UI views are written in SwiftUI inside native Widget Extension targets added to the Xcode project.

**iOS only.** macOS does not support Live Activities, Dynamic Island, or WidgetKit home screen widgets. All calls to the `live_activities` plugin must be guarded with `Platform.isIOS`. The macOS build ignores these targets entirely.

#### Native Extension Targets

Two Xcode Widget Extension targets in `apps/flutter/ios/`:

| Target | Type | Purpose |
|---|---|---|
| `OnTaskLiveActivity` | Widget Extension | Dynamic Island compact/expanded + Lock Screen Live Activities |
| `OnTaskWidget` | Widget Extension | Home screen widgets — Now (small), Today (medium) |

Both targets import SwiftUI view code from a shared group (`SharedWidgetViews/`). `ActivityAttributes` and `ContentState` definitions live in `OnTaskLiveActivity` and are referenced by the shared views.

`Info.plist` addition (Runner target):
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

Entitlement required in `Runner.entitlements`:
```
com.apple.developer.live-activities
```

#### ActivityKit Content State

```swift
// OnTaskLiveActivity/OnTaskLiveActivity.swift
struct OnTaskActivityAttributes: ActivityAttributes {
    let taskId: String

    struct ContentState: Codable, Hashable {
        var taskTitle: String
        var elapsedSeconds: Int?       // nil when not in timer mode
        var deadlineTimestamp: Date?   // nil when no commitment deadline
        var stakeAmount: Decimal?      // nil when no stake
        var activityStatus: Status

        enum Status: String, Codable {
            case active, completed, failed, watchMode
        }
    }
}
```

Payload stays within the 4KB ActivityKit limit: task title, time values, stake amount, status flag only. No proof content, no notes.

#### ActivityKit Push Token Flow

The `live_activities` plugin delivers a push token per Live Activity via callback. This token is stored server-side to enable server-initiated updates (deadline countdown, stake outcome).

**API endpoint:** `POST /v1/live-activities/token` — body `{ taskId, activityType, pushToken }`. Upserts on `(user_id, task_id, activity_type)`. Called automatically by Flutter when an activity starts.

**DB table** (`packages/core/src/schema/live-activity-tokens.ts`):

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users |
| `task_id` | uuid (nullable) | FK → tasks; null for non-task activities |
| `activity_type` | text | `'task_timer'` \| `'commitment_countdown'` \| `'watch_mode'` |
| `push_token` | text | ActivityKit push token from client |
| `created_at` | timestamptz | |
| `expires_at` | timestamptz | ActivityKit tokens expire with the activity (max 8h) |

#### Server-Side Live Activity Updates

Uses the same `@fivesheepco/cloudflare-apns2` Worker already in place — additional headers required for the live activity push type:

| APNs Header | Value |
|---|---|
| `apns-push-type` | `liveactivity` |
| `apns-topic` | `com.ontaskhq.ontask.push-type.liveactivity` |
| `apns-expiration` | Unix timestamp matching `expires_at` |

**ActivityKit push payload:**
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

**Service:** `apps/api/src/services/live-activity.ts` — called by commitment contract and proof endpoints when relevant state changes occur.

Server-push triggers:

| Event | Push type | Notes |
|---|---|---|
| Commitment deadline within 1h | `update` | deadline urgency flag set |
| Task completed, proof submitted | `end` | `activityStatus: 'completed'` |
| Deadline passed, charge triggered | `end` | `activityStatus: 'failed'` |
| Watch Mode session ends | `end` | `activityStatus: 'completed'` |

#### Implementation Constraints

- **Watch Mode update rate:** ≤ 1 update/second to the Live Activity (Apple guideline); elapsed timer is driven by a client-side Swift `Timer.periodic`, not server pushes
- **8-hour hard limit:** iOS terminates Live Activities after 8 hours regardless of activity state; the app must restart the activity via the plugin if a task session continues
- **VoiceOver notifications:** `UIAccessibility.post(notification: .announcement, argument:)` must be called from Swift when activity state changes — Flutter cannot post UIAccessibility notifications across the extension boundary
- **Background push token updates:** ActivityKit push token refreshes are delivered to the app in background; the `live_activities` plugin forwards them via method channel — register `onActivityUpdate` in the Flutter layer and re-`POST /v1/live-activities/token` on token change
- **macOS guard:** Every call site in Flutter: `if (Platform.isIOS) { liveActivitiesPlugin... }`

### Operator Dashboard & Admin API

**API:** Admin endpoints at `/admin/v1/` — separate prefix from user-facing `/v1/`. Excluded from user-facing OpenAPI spec; separate admin spec generated if needed.

**UI:** Cloudflare Pages + Vite + React SPA at `admin.ontaskhq.com`

**CORS:** Mounted only on `/admin/v1/*` and payment setup endpoints — not globally.

| Route group | CORS needed | Allowed origins |
|---|---|---|
| `/v1/*` | No — native Flutter HTTP client | — |
| `/admin/v1/*` | Yes — browser SPA | `admin.ontaskhq.com`, `admin.staging.ontaskhq.com` |
| Payment setup endpoints | Yes — browser page | `ontaskhq.com` |
| `mcp.ontaskhq.com` | No — MCP clients are not browsers | — |

### Domains & Environments

**Production**

| Surface | URL | Deployed as |
|---|---|---|
| REST API | `api.ontaskhq.com/v1/` | Cloudflare Worker (`apps/api`) |
| Admin API | `api.ontaskhq.com/admin/v1/` | Cloudflare Worker (`apps/admin-api`) |
| MCP Server | `mcp.ontaskhq.com` | Cloudflare Worker (`apps/mcp`) |
| Admin SPA | `admin.ontaskhq.com` | Cloudflare Pages (`apps/admin`) |
| Stripe payment setup | `ontaskhq.com/setup` | Cloudflare Pages (static, Stripe.js) |

**Staging:** `api.staging.ontaskhq.com`, `mcp.staging.ontaskhq.com`, `admin.staging.ontaskhq.com`

**Local:** `localhost:8787` (Wrangler dev), `localhost:5173` (Vite admin)

### CI/CD

**Platform:** GitHub Actions

**Flutter releases:** Fastlane for TestFlight and App Store automation

**Pipeline per PR:**
- Bundle size check (`wrangler deploy --dry-run` — fail if > 8MB per Worker)
- `/packages/scheduling` unit tests (100% coverage enforced)
- Flutter unit + widget tests
- Integration tests against ephemeral Neon branch (see below)
- Generated files committed to repo — no `build_runner` step in CI
- Lint + type check

**Neon ephemeral branch pattern (per PR):**

On PR open/synchronize — create branch:
```yaml
- name: Create Neon branch
  run: |
    curl -X POST https://console.neon.tech/api/v1/projects/${{ secrets.NEON_PROJECT_ID }}/branches \
      -H "Authorization: Bearer ${{ secrets.NEON_API_KEY }}" \
      -d '{"name": "${{ github.head_ref }}"}'
```

On PR close/merge — delete branch:
```yaml
- name: Delete Neon branch
  run: |
    curl -X DELETE https://console.neon.tech/api/v1/projects/${{ secrets.NEON_PROJECT_ID }}/branches/${{ github.head_ref }} \
      -H "Authorization: Bearer ${{ secrets.NEON_API_KEY }}"
```

Each PR gets a copy-on-write snapshot of the staging branch — full realistic database, no manual data cloning. Migrations run against the ephemeral branch before tests; same migrations promoted to staging, then production.

Reference: https://neon.com/blog/adopting-neon-branching-in-ci-cd-pipelines-a-practical-story-by-shepherd

### Analytics & Error Tracking

**Product analytics + feature flags + user feedback:** PostHog
- Flutter SDK for in-app events and feature flags
- Server-side event ingestion from Hono Workers for business events (NFR-B1)
- EU data residency option for future GDPR path

**Error tracking + crash reporting:** GlitchTip (self-hosted, Sentry-compatible)
- `sentry_flutter` SDK — mature Dart crash reporting, stack traces, source maps
- Sentry-protocol events → GlitchTip receiver; zero vendor lock-in, zero cost

### Implementation Sequence

1. Monorepo scaffold + CI/CD (GitHub Actions, Neon branch automation)
2. `/packages/core` — Drizzle schema, `@neondatabase/serverless` config, shared types
3. Neon database setup + staging branch
4. Hono Worker skeletons — `apps/api/` (`/v1/` routing, CORS scoped to payment endpoints) + `apps/admin-api/` (`/admin/v1/` routing, CORS scoped to `admin.ontaskhq.com`)
5. Flutter app scaffold (Riverpod + go_router + drift; generated files committed)
6. Auth — JWT + Apple/Google Sign In (gates all user features)
7. APNs push (`@fivesheepco/cloudflare-apns2`; integration tested against staging only)
8. `/packages/scheduling` — TDD-first, pure function, 100% coverage
9. Stripe integration + commitment contract flow
10. Live Activities — `OnTaskLiveActivity` + `OnTaskWidget` Xcode targets; `live_activities` Flutter plugin; `live-activity.ts` service; `live_activity_tokens` table
11. `/packages/ai` — Vercel AI SDK + Cloudflare AI Gateway
12. MCP Worker
13. Admin SPA (Cloudflare Pages)

## Implementation Patterns & Consistency Rules

### Naming Conventions

**Database (Drizzle + Postgres)**

| Element | Convention | Example |
|---|---|---|
| Table names | `snake_case`, plural | `tasks`, `commitment_contracts`, `shared_lists` |
| Column names | `snake_case` | `user_id`, `created_at`, `is_complete` |
| Foreign keys | `{singular_table}_id` | `task_id`, `list_id`, `user_id` |
| Indexes | `idx_{table}_{columns}` | `idx_tasks_user_id` |
| Drizzle table exports | `{entity}Table` | `tasksTable`, `usersTable` |
| Timestamps | `created_at` + `updated_at` on every table | — |

**Drizzle instance configuration** — always use `casing: 'camelCase'` so the ORM transforms DB snake_case to camelCase automatically. Never do manual field mapping:

```typescript
import { neon } from '@neondatabase/serverless'
import { drizzle } from 'drizzle-orm/neon-http'

const sql = neon(env.DATABASE_URL)
const db = drizzle(sql, { casing: 'camelCase' })
```

**API endpoints (Hono REST)**

| Element | Convention | Example |
|---|---|---|
| Resources | Plural nouns | `/v1/tasks`, `/v1/lists`, `/v1/commitment-contracts` |
| Route params | `:id` (Hono style) | `/v1/tasks/:id` |
| Query params | `camelCase` | `?userId=`, `?includeCompleted=` |
| Multi-word resources | `kebab-case` | `/v1/commitment-contracts`, `/v1/watch-mode` |

**Every route must have a `@hono/zod-openapi` schema definition. No untyped routes.** The OpenAPI spec is the contract — it must be complete. Reference: https://hono.dev/examples/zod-openapi

**TypeScript (Hono Workers)**

| Element | Convention | Example |
|---|---|---|
| Files | `kebab-case.ts` | `task-routes.ts`, `auth-middleware.ts` |
| Functions | `camelCase` | `getTaskById`, `scheduleTask` |
| Types/interfaces | `PascalCase` | `Task`, `CommitmentContract` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_STAKE_AMOUNT`, `JWT_EXPIRY` |
| Zod schemas | `{entity}Schema` / `create{Entity}Schema` | `taskSchema`, `createTaskSchema` |

**Flutter/Dart**

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `task_card.dart`, `tasks_provider.dart` |
| Classes | `PascalCase` | `TaskCard`, `TasksNotifier` |
| Variables/functions | `camelCase` | `fetchTasks()`, `taskId` |
| Riverpod providers | `{entity}Provider` | `tasksProvider`, `taskDetailProvider` |
| Drift table classes | `{Entity}Table` | `TasksTable`, `UsersTable` |

### Project Structure

**Hono Worker route organization:**
```
src/
├── routes/          # one file per resource (tasks.ts, lists.ts, etc.)
├── middleware/      # auth.ts, cors.ts, rate-limit.ts
├── services/        # business logic calling /packages/*
├── db/              # Worker-local DB helpers (schema in /packages/core)
└── index.ts         # app entry, route mounting
```

**Test location:**
- Backend + packages: co-located `*.test.ts` alongside source
- Flutter: separate `test/` directory mirroring `lib/` structure
- `/packages/scheduling`: co-located tests, 100% coverage enforced in CI

**Flutter feature anatomy** — every feature has exactly this shape:
```
lib/features/{feature}/
├── data/
│   ├── {feature}_repository.dart     # implements domain interface
│   └── {feature}_dto.dart            # API ↔ domain mapping
├── domain/
│   ├── {feature}.dart                # domain model (freezed)
│   ├── {feature}_unions.dart         # freezed union/sealed types (domain concepts, not DTOs)
│   └── i_{feature}_repository.dart  # interface
└── presentation/
    ├── {feature}_screen.dart
    ├── {feature}_provider.dart       # Riverpod provider
    └── widgets/
```

`freezed` union types (sealed classes) live in `domain/` — they are domain concepts, not data transfer objects.

### API Response Format

All API responses use a consistent envelope. No custom shapes.

**Success (single object):**
```json
{ "data": { "id": "...", "title": "..." } }
```

**Success (list):**
```json
{
  "data": [...],
  "pagination": { "cursor": "...", "hasMore": true }
}
```

**Error:**
```json
{
  "error": {
    "code": "TASK_NOT_FOUND",
    "message": "Task not found",
    "details": {}
  }
}
```

**Rules:**
- JSON field names: `camelCase` in all API responses — handled automatically by `casing: 'camelCase'` Drizzle config
- Dates: ISO 8601 UTC strings (`2026-03-29T12:00:00Z`) — never Unix timestamps
- Pagination: cursor-based only — no offset/limit
- Error codes: `SCREAMING_SNAKE_CASE` strings — never numeric codes

**HTTP status codes:**

| Code | When |
|---|---|
| `200` | Successful GET, PATCH |
| `201` | Successful POST (resource created) |
| `204` | Successful DELETE (no body) |
| `400` | Validation failure (Zod parse error) |
| `401` | Missing or invalid auth token |
| `403` | Authenticated but insufficient permission |
| `404` | Resource not found |
| `409` | Conflict (duplicate, state violation) |
| `422` | Business logic error (e.g. deadline already passed) |
| `429` | Rate limit exceeded |
| `500` | Unexpected server error |

### Auth Pattern

- JWT in `Authorization: Bearer {token}` header — no cookies, no query params
- Access token lifetime: 15 minutes; refresh tokens rotated on every use, revocable per session
- All Flutter API calls go through a single `ApiClient` class — **injected via Riverpod, never instantiated as a singleton** (singleton breaks testability):

```dart
@riverpod
ApiClient apiClient(ApiClientRef ref) => ApiClient(baseUrl: AppConfig.apiUrl);
```

Every repository receives `ApiClient` from the ref — never constructs it directly.

- `401` response → silent token refresh → retry once → force logout on second `401`
- Operator routes (`/admin/v1/*`) require an additional admin-scoped JWT claim checked in middleware

### Scheduling Engine Interface

`/packages/scheduling` is a pure function. No exceptions.

```typescript
// The only public export
export function schedule(input: ScheduleInput): ScheduleOutput

// Types live in /packages/core to avoid circular dependencies
// No side effects. No external calls. No randomness.
// Identical inputs ALWAYS produce identical outputs (NFR-Q1)
```

Agents implementing features that touch scheduling **call `schedule()` and pass the result to the API layer** — they never modify engine internals.

**Scheduling test naming convention:** `schedule_[constraint]_[condition]_[expected]`
- e.g. `schedule_dueDate_taskOverdue_scheduledImmediately`
- e.g. `schedule_timeConstraint_morningPin_respectsPin`

### Queue Message Format (Cloudflare Queues)

```typescript
type QueueMessage<T> = {
  type: string           // e.g. 'PROOF_VERIFICATION', 'CHARGE_TRIGGER'
  idempotencyKey: string // prevents duplicate processing
  payload: T
  createdAt: string      // ISO 8601 UTC
  retryCount: number     // incremented by consumer on retry
}
```

Consumer functions named `{jobType}Consumer` — e.g. `proofVerificationConsumer`.

### Flutter Offline Queue (drift)

Pending offline operations stored in a `pending_operations` drift table:

```dart
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'COMPLETE_TASK', 'SUBMIT_PROOF', etc.
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get clientTimestamp => dateTime()(); // set at creation, never at sync time
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // status: 'pending' | 'failed'
}
```

- Processed FIFO on reconnect
- `clientTimestamp` always set at operation creation — never at sync time
- Max 3 retry attempts with exponential backoff
- After 3 failures: status → `failed`, surface user-visible error — never queue silently forever

### Error Handling

**Backend (Hono):**
- All route handlers wrapped in `try/catch`
- Unexpected errors logged to GlitchTip via Sentry SDK, return `500` with generic message
- Business logic errors throw typed exceptions → caught by middleware → `422` with `error.code`
- Never expose stack traces or internal details to API consumers

**Flutter:**
- All Riverpod providers return `AsyncValue<T>` — never raw `Future<T>`
- User-facing error strings live in `l10n` — never hardcoded in widgets
- Network errors → toast notification with retry action
- `401` → silent refresh → logout — user never sees auth errors directly

### Testing Patterns

**Riverpod unit tests:** All provider business logic tested with `ProviderContainer` and overrides — never `WidgetTester` alone for logic:

```dart
test('tasks load correctly', () async {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(mockApiClient)],
  );
  // test against container
});
```

**Clock skew boundary tests** — required for commitment contract timestamp validation:

```typescript
// These three cases must have explicit test coverage
test('accepts timestamp exactly 30 days old')    // boundary: accept
test('rejects timestamp 30 days + 1 second old') // boundary: reject
test('accepts current timestamp')                // baseline
```

### Enforcement

**All AI agents MUST:**
- Follow naming conventions above without deviation
- Configure Drizzle with `casing: 'camelCase'` — never manual field mapping
- Define `@hono/zod-openapi` schema for every route — no untyped routes
- Use the standard API response envelope — no custom shapes
- Pass all offline operations through `pending_operations` queue — no ad-hoc local state
- Inject `ApiClient` via Riverpod — never as a singleton
- Call the scheduling engine as a pure function — never modify internals
- Set `clientTimestamp` at operation creation time — never at sync time
- Use `AsyncValue<T>` for all async Riverpod providers
- Place `freezed` union types in `domain/` — never in `data/`

## Project Structure & Boundaries

### Complete Monorepo Directory Tree

```
ontask/
├── package.json                    # workspace root (pnpm workspaces)
├── pnpm-workspace.yaml
├── tsconfig.base.json              # base TS config extended by all packages
├── .gitignore                      # must NOT ignore *.g.dart / *.freezed.dart
├── README.md
├── .github/
│   └── workflows/
│       ├── ci.yml                  # PR: bundle check, tests, Neon branch lifecycle
│       ├── deploy-staging.yml
│       └── deploy-production.yml
│
├── apps/
│   ├── api/                        # Hono REST API Worker (api.ontaskhq.com/v1/*)
│   ├── admin-api/                  # Hono Operator API Worker (api.ontaskhq.com/admin/v1/*)
│   ├── mcp/                        # Hono MCP Worker (mcp.ontaskhq.com)
│   ├── flutter/                    # Flutter iOS/macOS app
│   └── admin/                      # Cloudflare Pages admin SPA (admin.ontaskhq.com)
│
└── packages/
    ├── core/                       # shared types + Drizzle schema
    ├── scheduling/                 # scheduling engine (pure function)
    └── ai/                         # AI pipeline abstraction
```

### `apps/api/` — Hono REST API Worker

Path-based routing — Cloudflare routes `api.ontaskhq.com/v1/*` to this Worker and `api.ontaskhq.com/admin/v1/*` to `apps/admin-api/` without a gateway Worker.

```
apps/api/
├── package.json
├── tsconfig.json
├── wrangler.toml                   # routes: api.ontaskhq.com/v1/* · bindings: Neon, KV, Queues, AI Gateway, Secrets
├── drizzle.config.ts               # Drizzle Kit migration config
├── migrations/                     # Drizzle Kit SQL migrations (committed to repo)
│   └── 0001_initial.sql
├── src/
│   ├── index.ts                    # app entry — mounts all routes
│   ├── routes/
│   │   ├── auth.ts                 # FR48, FR91, FR92
│   │   ├── users.ts                # FR60, FR61, FR64, FR65, FR81, FR85, FR87
│   │   ├── tasks.ts                # FR1, FR1b, FR2-8, FR55-59, FR68-69, FR73-74, FR76, FR78
│   │   ├── lists.ts                # FR15-21, FR62, FR75
│   │   ├── sections.ts             # FR2, FR3 (section-level)
│   │   ├── scheduling.ts           # FR9-14, FR79
│   │   ├── commitment-contracts.ts # FR22-30, FR63-65, FR71
│   │   ├── proof.ts                # FR31-41, FR66-67
│   │   ├── disputes.ts             # FR39-41
│   │   ├── notifications.ts        # FR42-43, FR72
│   │   ├── live-activities.ts      # ActivityKit push token registration; server-push update triggers (iOS only)
│   │   ├── subscriptions.ts        # FR49, FR82-84, FR86-90
│   │   └── calendar.ts             # FR46 — connect, list, webhook receiver
│   ├── middleware/
│   │   ├── auth.ts                 # JWT validation
│   │   ├── cors.ts                 # scoped: payment endpoints only (no admin routes here)
│   │   └── rate-limit.ts           # FR80, NFR-I6
│   ├── services/
│   │   ├── scheduling.ts           # calls /packages/scheduling
│   │   ├── proof-verification.ts   # calls /packages/ai, enqueues jobs
│   │   ├── stripe.ts               # SetupIntent, PaymentIntent, webhooks
│   │   ├── every-org.ts            # charity disbursement API
│   │   ├── calendar/               # Google Calendar bidirectional sync (broken out by provider)
│   │   │   ├── index.ts            # aggregates across all connections; partial failure tolerant
│   │   │   ├── google.ts           # Google Calendar API + webhook channel renewal
│   │   │   ├── apple.ts            # EventKit / CalDAV (v2 stub)
│   │   │   └── outlook.ts          # Microsoft Graph API (v2 stub)
│   │   ├── push.ts                 # APNs via @fivesheepco/cloudflare-apns2
│   │   ├── live-activity.ts        # ActivityKit server-push via APNs (apns-push-type: liveactivity)
│   │   └── analytics.ts            # PostHog server-side events (NFR-B1)
│   ├── queues/
│   │   ├── proof-verification-consumer.ts
│   │   ├── charge-trigger-consumer.ts
│   │   └── every-org-consumer.ts
│   ├── db/
│   │   └── index.ts                # drizzle(neon(env.DATABASE_URL), { casing: 'camelCase' })
│   └── lib/
│       ├── errors.ts               # typed error classes → 422 responses
│       ├── response.ts             # envelope helpers: ok(), list(), err()
│       └── jwt.ts                  # token sign/verify helpers
└── test/
    ├── routes/
    └── services/
```

### `apps/admin-api/` — Hono Operator API Worker

Separate Worker from `apps/api/` for bundle isolation and separation of concerns. No AI SDK, no Calendar client, no APNs — only Drizzle, Stripe (charge reversal), and admin JWT middleware.

```
apps/admin-api/
├── package.json
├── tsconfig.json
├── wrangler.toml                   # routes: api.ontaskhq.com/admin/v1/* · bindings: Neon, Stripe Secret
├── src/
│   ├── index.ts
│   ├── routes/
│   │   ├── auth.ts                 # POST /admin/v1/auth/login (argon2, Workers Secret creds)
│   │   ├── disputes.ts             # FR41, FR51 — review queue + approve/reject
│   │   ├── charges.ts              # FR52 — Stripe charge reversal + refund
│   │   └── users.ts                # FR53, FR54 — impersonation (audit logged) + alerts
│   ├── middleware/
│   │   ├── admin-auth.ts           # admin JWT claim check
│   │   └── cors.ts                 # admin.ontaskhq.com only
│   └── db/
│       └── index.ts                # drizzle(neon(env.DATABASE_URL), { casing: 'camelCase' })
└── test/
    └── routes/
```

### `apps/mcp/` — Hono MCP Worker

MCP Worker communicates with the API Worker via **Cloudflare Service Binding** — zero-latency in-process RPC, no HTTP round-trip, no public URL required.

`apps/mcp/wrangler.toml`:
```toml
[[services]]
binding = "API"
service = "ontask-api"
```

```
apps/mcp/
├── package.json
├── tsconfig.json
├── wrangler.toml                   # Service Binding to ontask-api; custom domain: mcp.ontaskhq.com
├── src/
│   ├── index.ts                    # MCP server entry, SSE transport
│   ├── tools/
│   │   ├── create-task.ts          # FR45 — NLP parse identical to in-app
│   │   ├── list-tasks.ts
│   │   ├── schedule-task.ts
│   │   ├── create-commitment.ts    # FR45 — requires saved payment method
│   │   └── get-commitment-status.ts # FR71
│   └── middleware/
│       └── oauth.ts                # FR93 — OAuth per MCP spec, per-client scoping
└── test/
    └── tools/
```

### `apps/flutter/` — Flutter iOS/macOS App

```
apps/flutter/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── l10n.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart          # env-based API URL, feature flags
│   │   ├── theme/
│   │   │   └── app_theme.dart           # NFR-A4, NFR-A5 — themes, Dynamic Type
│   │   ├── l10n/
│   │   │   └── app_en.arb               # NFR-P11 — all user-facing strings
│   │   ├── network/
│   │   │   ├── api_client.dart          # dio wrapper, Riverpod-injected
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart    # 401 → silent refresh → retry → logout
│   │   │       └── logging_interceptor.dart
│   │   ├── storage/
│   │   │   ├── database.dart            # drift instance
│   │   │   └── pending_operations.dart  # offline queue schema + FIFO processor
│   │   ├── sync/
│   │   │   └── sync_manager.dart        # FR94 — conflict resolution on reconnect
│   │   └── utils/
│   ├── features/
│   │   ├── auth/                        # FR48, FR82, FR87-88, FR91-92
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── tasks/                       # FR1-8, FR55-59, FR68-69, FR73-74, FR76-78
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       └── widgets/
│   │   ├── lists/                       # FR15-21, FR62, FR75
│   │   ├── scheduling/                  # FR9-14, FR79
│   │   ├── commitment_contracts/        # FR22-30, FR63-65
│   │   ├── proof/                       # FR31-32, FR35-38
│   │   ├── watch_mode/                  # FR33-34, FR66-67
│   │   ├── disputes/                    # FR39-40
│   │   ├── notifications/               # FR42-43, FR72
│   │   ├── subscriptions/               # FR49, FR82-90
│   │   └── settings/                   # FR60-61, FR77, FR81
│   └── generated/                       # build_runner output — committed to repo
│       ├── *.g.dart
│       └── *.freezed.dart
├── test/
│   ├── core/
│   │   └── sync/
│   │       └── sync_manager_test.dart   # conflict resolution + clock skew boundary tests
│   └── features/
│       ├── tasks/
│       ├── scheduling/
│       └── commitment_contracts/
├── ios/
│   ├── Runner/
│   │   ├── Info.plist                   # NSSupportsLiveActivities = YES; URL schemes; Associated Domains
│   │   └── Runner.entitlements          # Push notifications; Live Activities; Associated Domains
│   ├── OnTaskLiveActivity/              # Widget Extension — Dynamic Island + Lock Screen Live Activities
│   │   ├── OnTaskLiveActivity.swift     # ActivityAttributes, ContentState, WidgetBundle entry
│   │   ├── OnTaskLiveActivityLiveActivity.swift  # Dynamic Island (compact/expanded) + Lock Screen SwiftUI views
│   │   └── Info.plist
│   ├── OnTaskWidget/                    # WidgetKit — home screen widgets
│   │   ├── OnTaskWidget.swift           # Widget provider + timeline entry
│   │   ├── OnTaskWidgetViews.swift      # Now widget (small) + Today widget (medium) SwiftUI views
│   │   └── Info.plist
│   └── SharedWidgetViews/              # Shared SwiftUI components imported by both extensions
└── macos/
    └── Runner/                          # APNs entitlements (push package, no Firebase)
```

### `apps/admin/` — Cloudflare Pages Admin SPA

```
apps/admin/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── index.html
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── pages/
    │   ├── disputes/                    # FR41, FR51 — review queue
    │   ├── charges/                     # FR52, FR54 — reversal, refunds, alerts
    │   └── users/                       # FR53 — impersonation (audit logged)
    ├── components/
    ├── hooks/                           # custom React hooks (useDisputeQueue, etc.)
    ├── api/                             # fetch wrappers broken out by resource
    │   ├── disputes.ts
    │   ├── charges.ts
    │   └── users.ts
    └── lib/
        └── auth.ts                      # admin auth state
```

### `packages/core/` — Shared Types + Drizzle Schema

```
packages/core/
├── package.json
├── tsconfig.json
└── src/
    ├── index.ts
    ├── schema/
    │   ├── users.ts
    │   ├── tasks.ts
    │   ├── lists.ts
    │   ├── sections.ts
    │   ├── commitment-contracts.ts
    │   ├── proof.ts
    │   ├── disputes.ts
    │   ├── subscriptions.ts
    │   ├── calendar-connections.ts          # base table (provider enum, common fields)
    │   ├── calendar-connections-google.ts   # Google OAuth tokens (AES-256-GCM encrypted)
    │   ├── calendar-connections-outlook.ts  # stub (v2)
    │   ├── calendar-connections-apple.ts    # stub (v2, EventKit — no tokens)
    │   ├── live-activity-tokens.ts          # ActivityKit push tokens; scoped per user+task+type; expires with activity
    │   └── index.ts
    ├── types/
    │   ├── scheduling.ts                # ScheduleInput, ScheduleOutput
    │   ├── api.ts                       # shared API response types
    │   └── index.ts
    └── constants/
        └── index.ts                     # CLOCK_SKEW_MAX_DAYS = 30, etc.
```

### `packages/scheduling/` — Scheduling Engine

```
packages/scheduling/
├── package.json
├── tsconfig.json
└── src/
    ├── index.ts                         # exports schedule(), explain()
    ├── scheduler.ts                     # pure function: schedule(input) → output
    ├── constraints/
    │   ├── due-date.ts
    │   ├── time-of-day.ts
    │   ├── energy-preferences.ts
    │   ├── calendar-events.ts
    │   ├── dependencies.ts              # FR73
    │   └── suggested-dates.ts           # FR14 — UI nudge input
    ├── strategies/
    │   ├── round-robin.ts               # FR17
    │   ├── least-busy.ts                # FR17
    │   └── ai-assisted.ts              # FR17
    ├── explainer.ts                     # FR13 — why was this scheduled here?
    └── test/                            # co-located, 100% coverage enforced
        ├── scheduler.test.ts
        ├── constraints/
        └── strategies/
```

### `packages/ai/` — AI Pipeline Abstraction

```
packages/ai/
├── package.json
├── tsconfig.json
└── src/
    ├── index.ts
    ├── provider.ts                      # ai-gateway-provider + Cloudflare AI Gateway config
    ├── proof-verification.ts            # FR32
    ├── watch-mode.ts                    # FR33
    ├── nlp-parser.ts                    # FR1b
    └── test/
```

### Requirements → Structure Mapping

| FR Category | Primary locations |
|---|---|
| Task & List Management | `apps/api/src/routes/tasks.ts`, `lists.ts`, `sections.ts` · `apps/flutter/lib/features/tasks/`, `lists/` |
| Intelligent Scheduling | `packages/scheduling/` · `apps/api/src/routes/scheduling.ts` · `apps/flutter/lib/features/scheduling/` |
| Shared Lists | `apps/api/src/routes/lists.ts` · `apps/flutter/lib/features/lists/` |
| Commitment Contracts | `apps/api/src/routes/commitment-contracts.ts` · `services/stripe.ts` · `queues/charge-trigger-consumer.ts` |
| Proof & Verification | `packages/ai/` · `apps/api/src/routes/proof.ts` · `queues/proof-verification-consumer.ts` · `apps/flutter/lib/features/proof/`, `watch_mode/` |
| Notifications | `apps/api/src/services/push.ts` · `apps/flutter/lib/features/notifications/` |
| Integrations & API | `apps/mcp/` (via Service Binding) · `apps/api/src/services/calendar/` |
| Accounts & Subscriptions | `apps/api/src/routes/auth.ts`, `users.ts`, `subscriptions.ts` · `apps/flutter/lib/features/auth/`, `subscriptions/`, `settings/` |
| Operator Tools | `apps/admin-api/src/routes/` · `apps/admin/` |
| Offline Sync | `apps/flutter/lib/core/storage/pending_operations.dart` · `core/sync/sync_manager.dart` |
| Calendar Connections | `packages/core/src/schema/calendar-connections*.ts` · `apps/api/src/services/calendar/` · `apps/flutter/lib/features/scheduling/` |

## Architecture Validation Results

### Coherence Validation ✅

All stack choices confirmed compatible. Transformation chain (DB snake_case → Drizzle `casing: 'camelCase'` → API JSON → Flutter) cleanly documented. Three Workers (`apps/api`, `apps/admin-api`, `apps/mcp`) plus one Cloudflare Pages site (`apps/admin`) each have distinct concerns, distinct bundle contents, and path-based routing on the same domain without a gateway Worker.

### Gap Resolutions

**Gap 1 — Stripe SetupIntent return flow (FR23): RESOLVED**

Both Universal Links and custom URL scheme configured. Return URLs include `?sessionToken=xxx` — API generates a short-lived session token before redirecting to the Stripe setup page; app exchanges it on return to identify the pending commitment contract.

- Universal Link: `https://ontaskhq.com/payment-setup-complete?sessionToken=xxx` (primary; iOS best experience)
  - `apple-app-site-association` file at `ontaskhq.com/.well-known/` served by Cloudflare Pages
  - `_headers` file sets `Content-Type: application/json`, no redirects
  - Associated Domains entitlement in iOS + macOS Runner
- Custom URL scheme: `ontaskhq://payment-setup-complete?sessionToken=xxx` (fallback; macOS + edge cases)
- Both registered in `Info.plist`; same payment completion handler in the app

**Gap 2 — Multi-calendar support (FR46, FR61): RESOLVED**

Table-per-provider inheritance — adding a new provider is additive (new table only, no migration of existing tables):

```
calendar_connections          base table
├── id, user_id, provider, calendar_id, display_name, is_read, is_write, created_at, updated_at

calendar_connections_google   one-to-one; Google OAuth tokens
├── connection_id (FK), account_email, access_token*, refresh_token*, token_expiry
(* AES-256-GCM encrypted at application level before insert; key in Workers Secret)

calendar_connections_outlook  stub, v2
calendar_connections_apple    stub, v2 — EventKit native, no tokens
```

Calendar OAuth is a **separate flow** from Sign In (`POST /v1/calendar/connect`). Multiple read calendars aggregate free time for the scheduling engine. One or more write calendars configurable per list or globally. `ScheduleInput` receives a flat merged `calendarEvents[]` — engine never knows about providers.

Google Calendar webhook receiver at `POST /v1/calendar/webhook` validates `X-Goog-Channel-Token` header. Webhook channel renewal handled by `calendar-sync.ts`.

Calendar service layer broken out by provider:
```
apps/api/src/services/calendar/
├── index.ts       # aggregates across all connections; partial failure tolerant
├── google.ts      # Google Calendar API
├── apple.ts       # EventKit / CalDAV (v2)
└── outlook.ts     # Microsoft Graph API (v2)
```

**Gap 3 — Admin token issuance (FR53): RESOLVED**

`POST /admin/v1/auth/login` in `apps/admin-api/`. Credentials in Workers Secrets (v1 solo founder). Password hashed with `argon2` — not manual `crypto.subtle`.

**Admin API separation: RESOLVED**

`apps/admin-api/` is a separate Cloudflare Worker from `apps/api/`. Routes `api.ontaskhq.com/admin/v1/*` via Cloudflare path-based routing. Lighter bundle: no AI SDK, no Calendar client, no APNs. Contains only Drizzle, Stripe (charge reversal), admin JWT middleware, and CORS scoped to `admin.ontaskhq.com`.

**Minor — HealthKit iOS-only (FR35, FR47): NOTED**

HealthKit unavailable on macOS. `proof/` feature degrades gracefully on macOS (HealthKit proof type hidden). Implementation responsibility of the proof feature agent.

**Gap 4 — Live Activities & WidgetKit (UX spec §Responsive Design): RESOLVED**

Live Activities (Dynamic Island, Lock Screen) and WidgetKit home screen widgets require native Swift and cannot be rendered by Flutter. Resolution: `live_activities` pub.dev plugin bridges Flutter to ActivityKit; two native Widget Extension targets (`OnTaskLiveActivity`, `OnTaskWidget`) added to `apps/flutter/ios/`; server-side updates via APNs with `apns-push-type: liveactivity` from the existing `@fivesheepco/cloudflare-apns2` Worker; push tokens stored in `live_activity_tokens` table. Full specification in the `### Live Activities & WidgetKit` section above. iOS only — all calls guarded with `Platform.isIOS`.

### Additional Patterns from Validation

**Calendar token encryption:**
`access_token` and `refresh_token` in `calendar_connections_google` are encrypted at application level (AES-256-GCM) before insert, using `CALENDAR_TOKEN_KEY` Workers Secret. Neon disk-level encryption alone is insufficient — column-level encryption ensures tokens cannot be read with direct DB access.

**Provider-base row integrity:**
Inserting a calendar connection must be a single transaction — base row + provider row together or neither. The service layer (`calendar/google.ts`) owns this transaction; no agent should insert the base row alone.

### Requirements Coverage ✅

All 93 FRs have complete structural homes and implementation paths. All gaps resolved.

### NFR Coverage ✅

All NFR categories covered. NFR-I1 (60s propagation) handled by Google Calendar webhooks with channel token validation and renewal. Accessibility NFRs anchored by `app_theme.dart`, implemented per feature agent.

### Architecture Completeness Checklist

- [x] Project context + constraints analyzed
- [x] Technology stack fully specified with current versions
- [x] Offline conflict resolution policy (30-day clock skew)
- [x] Push notifications — direct APNs, no Firebase
- [x] CI/CD — GitHub Actions + Neon ephemeral branches
- [x] Bundle size discipline — 8MB hard fail per Worker
- [x] Monorepo with 5 apps + 3 packages; path-based routing (3 Workers + 1 Pages)
- [x] MCP → API via Cloudflare Service Binding
- [x] Admin API as separate Worker (bundle isolation)
- [x] Naming conventions + Drizzle `casing: 'camelCase'`
- [x] API response envelope + HTTP status codes
- [x] Scheduling engine pure function interface
- [x] Queue message format + idempotency
- [x] Flutter offline queue + retry strategy (max 3, exponential backoff)
- [x] Riverpod injection pattern + auth interceptor
- [x] Error handling (backend + Flutter)
- [x] Testing patterns + clock skew boundary tests + scheduling test naming
- [x] Complete directory tree for all apps + packages
- [x] FR → structure mapping
- [x] Stripe return flow (Universal Link + URL scheme + session token)
- [x] Multi-calendar support — table-per-provider, encrypted tokens, partial failure tolerant
- [x] Admin login endpoint (argon2, Workers Secret creds)
- [x] `apple-app-site-association` served from Cloudflare Pages with explicit `Content-Type`
- [x] Google Calendar webhook channel token validation
- [x] Live Activities & WidgetKit — `live_activities` plugin, Swift extension targets, ActivityKit push token flow, server-push via APNs liveactivity type, `live_activity_tokens` table, iOS-only guard

### Architecture Readiness Assessment

**Status: READY FOR IMPLEMENTATION**

**Key strengths:**
- Cloudflare-native throughout — Workers, KV, Queues, AI Gateway, Service Bindings, path-based routing
- Zero Firebase dependency
- Financial operations fully idempotent (Stripe + Every.org + queue consumers)
- Scheduling engine pure, TDD-ready, transparent (explain + nudge via `suggestedDates`)
- Offline conflict resolution policy explicit with financial edge cases covered
- Multi-calendar support designed in from the start — extensible by provider
- 3-Worker + 1 Cloudflare Pages architecture with clear bundle boundaries

### Implementation Handoff

**First story:** Monorepo scaffold — `pnpm init`, workspace config, `tsconfig.base.json`, GitHub Actions CI skeleton, Neon project + staging branch, Wrangler path-based routes configured for all Workers.

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented
- Naming conventions, response envelope, error codes — no deviation
- Every Hono route needs `@hono/zod-openapi` schema before the handler (ref: https://hono.dev/examples/zod-openapi)
- `@neondatabase/serverless` + `casing: 'camelCase'` — never `pg` or manual field mapping
- Calendar connection insert = single transaction (base + provider row together or neither)
- Calendar token encryption at application level before insert (`CALENDAR_TOKEN_KEY` secret)
- MCP Worker uses Service Binding (`env.API`) — never HTTP calls to the API Worker
- Admin auth uses `argon2` — never manual `crypto.subtle` for password hashing
- Generated Flutter files (`*.g.dart`, `*.freezed.dart`) are committed — `.gitignore` must not exclude them
- Scheduling engine (`packages/scheduling`) is pure — no side effects, no external imports
