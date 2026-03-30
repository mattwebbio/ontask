---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories']
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/ux-design-specification.md'
  - '_bmad-output/planning-artifacts/implementation-readiness-report-2026-03-29.md'
  - '_bmad-output/planning-artifacts/product-brief-ontask.md'
  - '_bmad-output/planning-artifacts/product-brief-ontask-distillate.md'
---

# On Task - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for On Task, decomposing the requirements from the PRD, UX Design Specification, and Architecture into implementable stories.

---

## Requirements Inventory

### Functional Requirements

**Task & List Management**
- FR1: Users can create tasks by directly entering a title and properties
- FR1b: Users can create tasks using natural language input, with the system parsing intent into structured task properties
- FR2: Users can organize tasks into lists, with infinitely nested sections and subtasks
- FR3: Users can set due dates on individual tasks; sections and lists can define default due dates inherited by tasks without specific dates
- FR4: Users can set time-of-day constraints on tasks (hard scheduling pins)
- FR5: Users can define energy and context availability preferences that constrain when different types of tasks are scheduled
- FR6: Users can view predicted completion dates for tasks, sections, and lists based on current workload
- FR7: Users can create one-off tasks and recurring tasks with equal feature parity
- FR8: Users can manually override a scheduled time slot for any task
- FR55: Users can mark a task complete without submitting proof
- FR56: Users can search and filter tasks across lists
- FR57: Users can manually reorder tasks within a section
- FR58: Users can edit task properties after creation
- FR59: Users can archive completed tasks
- FR68: Users can set task priority or urgency signals independent of due date
- FR69: Users can access a today/focus view showing tasks scheduled for the current day
- FR73: Users can define dependencies between tasks so the scheduler respects ordering constraints
- FR74: Users can perform bulk operations on multiple tasks (reschedule, complete, assign, delete)
- FR76: Users can explicitly begin a task, triggering relevant tracking or notifications
- FR78: Users can create, save, and apply list and section templates

**Intelligent Scheduling**
- FR9: The system automatically schedules tasks into available calendar time, respecting due dates, time constraints, energy preferences, and existing events
- FR10: The system reads the user's connected calendar to identify available time and avoid conflicts
- FR11: The system writes scheduled task blocks to the user's connected calendar
- FR12: The system automatically reschedules tasks when calendar events shift or tasks slip past their scheduled time
- FR13: Users can view an explanation of why a task was scheduled at a specific time
- FR14: Users can adjust scheduled tasks using natural language nudges
- FR79: The system maintains a visible, navigable relationship between tasks and their calendar blocks

**Shared Lists & Household Coordination**
- FR15: Users can share any list with named users via invitation
- FR16: Invited users can accept list membership and complete onboarding into the shared list
- FR17: The system assigns tasks in shared lists using configurable strategies: round-robin, least-busy, or AI-assisted balancing
- FR18: The system never assigns the same task to two users within the same due-date window
- FR19: Tasks assigned to a user in a shared list are automatically integrated into that user's personal schedule
- FR20: Accountability settings can be set at list or section level and cascade to all tasks within, with per-task overrides permitted
- FR21: Members of a shared list can view proof media attached to tasks completed by other members
- FR62: List owners can remove members from a shared list; members can leave a list
- FR75: List ownership can be shared among multiple members, with owners collectively holding administrative rights

**Commitment Contracts**
- FR22: Users can attach a financial stake to any task
- FR23: Users can set up a payment method via an external web-based flow
- FR24: The system charges the user's stored payment method if a staked task is not verified complete by its deadline
- FR25: On an unverified staked task, 50% of the stake is disbursed to the user's chosen charity and 50% retained by On Task
- FR26: Users can select a charity for their stakes from a catalog of nonprofits
- FR27: Users can view a lifetime impact dashboard showing total charitable contributions from their stakes
- FR28: The system provides in-app guidance to help users calibrate stake amounts appropriately
- FR29: Groups can create shared commitment arrangements where each member sets an individual stake, reviewed by all members, activating only upon unanimous approval
- FR30: Groups can opt into pool mode, where any member failing their assigned task results in charges for all members per their agreed stakes
- FR63: Users can cancel or modify a commitment stake before a defined pre-deadline window
- FR64: Users can manage (update or remove) a stored payment method
- FR65: Users can view billing history and past charges

**Proof & Verification**
- FR31: Users can submit photo or video proof captured in-app (camera capture only) for AI verification
- FR32: The system verifies submitted photo or video proof against the task description using AI
- FR33: Users can activate Watch Mode for passive camera-based monitoring during task work
- FR34: Watch Mode is available as a standalone focus mode without requiring a financial stake
- FR35: Tasks can be auto-verified via Apple HealthKit when connected health data confirms the task
- FR36: Users can submit screenshot or document proof for tasks with digital outputs
- FR37: Users can submit proof while offline; on reconnection, the system processes the proof and reverses any charges if the proof timestamp predates the deadline
- FR38: Users can choose whether submitted proof is retained as a completion record on the task
- FR39: Users can dispute an AI verification result via a no-proof-required review request
- FR40: Disputed verifications are escalated to human review with a defined resolution SLA
- FR41: Operators can approve or reject disputed verifications and trigger charge cancellation or confirmation
- FR66: Users can end a Watch Mode session manually or configure auto-stop conditions
- FR67: Users can view a Watch Mode session summary after a session ends

**Notifications & Communication**
- FR42: Users receive notifications for task reminders, approaching deadlines, commitment contract charge events, proof verification results, dispute outcomes, partner task completions, and schedule changes
- FR43: Users can configure notification preferences at three levels: globally, per device, and per task
- FR72: Users receive a distinct pre-deadline warning notification when a staked task deadline is approaching

**Platform Integrations & API**
- FR44: External systems can create, read, update, and schedule tasks via a versioned REST API with OpenAPI documentation
- FR45: AI assistants can create tasks, schedule them, and create commitment contracts via an MCP server with feature parity to the in-app experience
- FR46: The system performs bidirectional sync with Google Calendar
- FR47: The system reads Apple HealthKit data to auto-verify eligible tasks
- FR71: External systems can read commitment contract status via API
- FR80: API consumers can view rate limit status and current usage in API responses
- FR93: MCP server access requires OAuth authentication per the MCP specification, with per-client scoping and token revocation

**User Accounts, Subscriptions & Operator Tools**
- FR48: Users can authenticate via Apple Sign In, Google Sign In, or email and password
- FR49: Users can manage their subscription tier
- FR51: Operators can review and resolve disputed proof verifications via an internal dashboard
- FR52: Operators can reverse charges and issue refunds
- FR53: Operators can impersonate user accounts for troubleshooting, with all impersonation actions logged in an immutable audit trail
- FR54: Operators receive alerts for payment failures and pending disputed verifications
- FR60: Users can delete their account and all associated data
- FR61: New users can complete an onboarding flow covering calendar connection, energy preferences setup, and initial configuration
- FR77: Users can customize app appearance settings (theme, text size)
- FR81: Users can export their task and list data in CSV and Markdown formats
- FR82: New users receive 14 days of full-access free trial; after 14 days, all access is blocked until a paid subscription is activated
- FR83: Users can select and subscribe to a pricing tier (Individual, Couple, Family & Friends) during or after the trial period
- FR84: Users can upgrade or downgrade their subscription tier
- FR85: User data is retained for a defined period after trial expiry before deletion, allowing reactivation without data loss
- FR86: Invited users joining a shared list receive an independent trial or onboarding path if not already subscribed
- FR87: Users can view their remaining trial days and current subscription status at any time
- FR88: Users who reach trial expiry are presented with a designed paywall screen before access is blocked
- FR89: Users can cancel their subscription; active commitment contracts continue until their individual deadlines
- FR90: Users receive a grace period and notification when a subscription renewal payment fails before access is blocked
- FR91: Users can view active sessions and remotely revoke access from specific devices
- FR92: The system supports optional two-factor authentication
- FR94: The system applies a defined conflict resolution policy when offline changes sync against conflicting server state

**Total FRs: 93**

---

### Non-Functional Requirements

**Performance**
- NFR-P1: App cold launch completes within 2 seconds on supported devices
- NFR-P2: Task creation (direct input) completes and appears in the list within 500ms
- NFR-P3: NLP task parsing and scheduling completes within 3 seconds of submission
- NFR-P4: Single-user schedule recalculation within 5 seconds; shared list recalculation (≤10 members, 100 tasks) within 15 seconds
- NFR-P5: Scheduling explanation (FR13) loads within 1 second
- NFR-P6: REST API standard endpoints respond within 500ms at p95 under normal load
- NFR-P7: MCP server endpoints respond within 1 second at p95 under normal load
- NFR-P8: UI animations and transitions run at 60fps; no perceptible jank
- NFR-P9: Task list loads and search results return within 1 second for lists up to 500 tasks
- NFR-P10: iOS and macOS app bundle sizes remain within platform best-practice thresholds
- NFR-P11: All user-facing strings externalized into a localization layer; v1 ships English-only

**Security**
- NFR-S1: All data encrypted in transit (TLS 1.3 minimum) and at rest (AES-256)
- NFR-S2: On Task never stores raw payment card data; all payment handling delegated to Stripe (PCI DSS SAQ A)
- NFR-S3: Watch Mode frames processed in-flight and not persisted; no continuous video stored
- NFR-S4: Proof media stored in private object storage with access scoped to owning user and shared list members only
- NFR-S5: Authentication tokens are short-lived JWTs; refresh tokens rotated on use and revocable per session
- NFR-S6: All operator impersonation actions are immutably logged with timestamp, operator identity, and actions taken
- NFR-S7: Application relies on framework-level and infrastructure-level protections to mitigate OWASP Top 10 risks
- NFR-S8: 2FA applies to email/password accounts only; Apple/Google Sign In delegate security to their OAuth providers

**Reliability**
- NFR-R1: Stripe off-session charge processing < 0.1% failure rate; transient failures retried with exponential backoff and idempotency keys (exactly-once semantics)
- NFR-R2: Stripe webhook processing is idempotent; duplicate delivery does not result in duplicate charges
- NFR-R3: Human dispute review SLA: operator responds within 24 hours of filing; charge hold persists until resolution
- NFR-R4: Every.org disbursement failures queued and retried; funds never lost in transit
- NFR-R5: Offline proof submissions reliably queued and synced on reconnect with timestamp integrity; no proof silently dropped
- NFR-R6: Backend API targets 99.9% monthly uptime; maximum tolerable single-incident downtime 15 minutes
- NFR-R7: User data retained 30 days after trial expiry or account cancellation before permanent deletion
- NFR-R8: Proof media retained as completion records persists until parent task is permanently deleted

**Quality & Correctness**
- NFR-Q1: Scheduling engine produces deterministic output — identical inputs always produce identical scheduled outputs
- NFR-Q2: Payment charge logic and scheduling constraint resolution maintain minimum 90% unit test coverage; all edge cases have explicit tests

**Accessibility**
- NFR-A1: iOS and macOS apps conform to WCAG 2.1 AA standards
- NFR-A2: Full VoiceOver support on iOS and macOS; all interactive elements reachable and described
- NFR-A3: Dynamic Type supported throughout; no text hardcoded at a fixed size
- NFR-A4: Minimum contrast ratio 4.5:1 for body text and 3:1 for large text in all themes
- NFR-A5: App appearance settings include at minimum: light/dark/system theme and text size adjustment beyond system defaults
- NFR-A6: No interaction requires precise timing or rapid sequential input; accommodates users with motor and cognitive differences

**User Experience Quality**
- NFR-UX1: App clearly communicates offline status; queued offline actions display visible confirmation that they will sync on reconnect
- NFR-UX2: All user-facing error messages are plain-language, non-technical, and include a clear recovery action

**Integration Reliability**
- NFR-I1: Google Calendar changes propagate to scheduling engine within 60 seconds
- NFR-I2: On Task calendar block writes appear in Google Calendar within 10 seconds of task scheduling
- NFR-I3: Apple HealthKit data used for auto-verification read within 5-minute lag window; delayed data does not result in incorrect charges
- NFR-I4: Stripe webhook events processed within 30 seconds of receipt
- NFR-I5: Every.org disbursement attempted within 1 hour of confirmed charge; failures retried and logged
- NFR-I6: API rate limits defined, documented in OpenAPI spec, enforced, and communicated via response headers

**Business Intelligence**
- NFR-B1: Key business events (trial started, trial expired, subscription activated, subscription cancelled, task completed, stake set, charge fired) instrumented and queryable for analytics

**Total NFRs: 44**

---

### Additional Requirements (Architecture)

**Monorepo & Project Initialization**
- ARCH-1: Monorepo scaffold with pnpm workspaces; `tsconfig.base.json`; `.gitignore` must NOT ignore `*.g.dart` / `*.freezed.dart`
- ARCH-2: Flutter project initialized with `flutter create --org com.ontaskhq --platforms=ios,macos --project-name ontask`
- ARCH-3: Two Hono Workers initialized: `npm create hono@latest ontask-api -- --template cloudflare-workers` and `npm create hono@latest ontask-mcp -- --template cloudflare-workers`
- ARCH-4: Generated files (`*.g.dart`, `*.freezed.dart`) committed to repo — `build_runner` runs locally only, never in CI

**CI/CD**
- ARCH-5: GitHub Actions pipeline per PR: bundle size check (Wrangler dry-run, fail if > 8MB per Worker), Flutter unit + widget tests, scheduling engine tests (100% coverage), lint + type check
- ARCH-6: Neon ephemeral branch per PR — create on open/synchronize, delete on close/merge
- ARCH-7: Fastlane for TestFlight and App Store automation
- ARCH-8: Staging environments: `api.staging.ontaskhq.com`, `mcp.staging.ontaskhq.com`, `admin.staging.ontaskhq.com`

**Database**
- ARCH-9: `@neondatabase/serverless` with HTTP transport only (NOT `pg` or standard connection pooling — incompatible with Workers edge runtime)
- ARCH-10: Drizzle ORM with `casing: 'camelCase'` on every drizzle instance — no manual field mapping
- ARCH-11: All migrations via Drizzle Kit SQL files committed to repo; tables created in the story that first uses them (not upfront)

**API Standards**
- ARCH-12: Every Hono route must have a `@hono/zod-openapi` schema definition — no untyped routes
- ARCH-13: API response envelope: `{ "data": {...} }` for single objects, `{ "data": [...], "pagination": {...} }` for lists, `{ "error": { "code": "SCREAMING_SNAKE_CASE", "message": "...", "details": {} } }` for errors
- ARCH-14: Pagination is cursor-based only — no offset/limit; dates are ISO 8601 UTC strings; JSON field names are camelCase
- ARCH-15: CORS scoped only to `/admin/v1/*` and payment setup endpoints — not globally

**Flutter Architecture**
- ARCH-16: Feature-first clean architecture: `lib/features/{feature}/data/`, `domain/`, `presentation/`
- ARCH-17: All async Riverpod providers return `AsyncValue<T>` — never raw `Future<T>`
- ARCH-18: `ApiClient` injected via Riverpod — never instantiated as a singleton
- ARCH-19: `freezed` union types (sealed classes) in `domain/` — never in `data/`
- ARCH-20: 401 response handling: silent token refresh → retry once → force logout on second 401

**Scheduling Engine**
- ARCH-21: `/packages/scheduling` is a pure function: `schedule(input: ScheduleInput): ScheduleOutput` — no side effects, no external calls, no randomness; identical inputs always produce identical outputs
- ARCH-22: Test naming convention: `schedule_[constraint]_[condition]_[expected]` (e.g. `schedule_dueDate_taskOverdue_scheduledImmediately`)
- ARCH-23: 100% unit test coverage enforced in CI for `/packages/scheduling`

**Payments & Queues**
- ARCH-24: Stripe idempotency keys required on all charge operations — exactly-once semantics
- ARCH-25: Queue message format: `{ type, idempotencyKey, payload, createdAt, retryCount }` — consumer functions named `{jobType}Consumer`
- ARCH-26: Flutter offline queue: `pending_operations` drift table; `clientTimestamp` set at operation creation, never at sync time; max 3 retries with exponential backoff; status → `failed` after 3 failures (never silently queue forever)

**Push & Live Activities**
- ARCH-27: APNs direct via `@fivesheepco/cloudflare-apns2` — no Firebase; APNs p8 key stored as `wrangler secret put APNS_KEY`; APNs integration tested against staging only (not local — wrangler dev does not support HTTP/2 outbound)
- ARCH-28: `live_activities` Flutter plugin bridges to `OnTaskLiveActivity` Swift Widget Extension; all calls guarded with `Platform.isIOS`; Live Activity push tokens stored in `live_activity_tokens` table; server pushes via APNs `apns-push-type: liveactivity`

**Clock Skew & Testing**
- ARCH-29: Commitment contract timestamp clock skew: accept up to 30 days; reject beyond; three boundary test cases required: accept exactly 30 days, reject 30 days + 1 second, accept current timestamp

**Analytics & Error Tracking**
- ARCH-30: PostHog for product analytics and feature flags (Flutter SDK + server-side events for NFR-B1)
- ARCH-31: GlitchTip (self-hosted, Sentry-compatible) for error tracking and crash reporting (`sentry_flutter` SDK)

**Watch Mode Implementation Detail**
- ARCH-32: Watch Mode AI frame polling rate: every 30–60 seconds (not continuous); frame processed in-flight and discarded; no frame stored at any point (NFR-S3)

**Rejected Approaches (Do Not Re-Propose)**
- ARCH-REJECT-1: Full AI scheduling — rejected; too expensive and non-deterministic; algorithm handles scheduling, AI handles language understanding only
- ARCH-REJECT-2: Enterprise/employer-employee tier — rejected; financial penalties don't fit employment relationships; small peer groups (roommates, freelance collectives) are fine
- ARCH-REJECT-3: "You will be judged" or sassy messaging on disputes — rejected; human friction is the mechanism; no explicit judgment language

---

### UX Design Requirements

**Design System & Tokens**
- UX-DR1: Implement design token system from Still Water direction — Clay theme (terracotta `#C4623A`, cream `#FDF6EE`, slate `#3D3D3D`, commitment purple, success green, warning amber) plus 4 named theme variants (Clay, Slate, Dusk, Monochrome); all tokens defined in `app_theme.dart`
- UX-DR2: New York serif font implementation — use `'.NewYorkFont'` platform string on iOS; bundle a compatible fallback serif (e.g. Playfair Display subset) for Android future-proofing; verify availability via platform channel before applying

**Navigation**
- UX-DR3: iOS four-tab bottom navigation — Now / Today / Add / Lists — Cupertino tab bar; Add tab is an action tab (opens to capture UI), not a navigation destination
- UX-DR4: macOS three-pane layout — sidebar (260pt fixed) / detail panel (320pt min) / main area; collapses to two-pane at ≤1100pt total width; minimum window 900×600pt; Add tab becomes "New Task" toolbar button on macOS

**Custom Components (15 required)**
- UX-DR5: Now Tab Task Card — host + 5 injected display variants (standard, committed photo proof, committed Watch Mode, committed HealthKit, calendar event); Dynamic Island padding zone; New York serif title; VoiceOver label includes title + attribution + stake + deadline + proof mode; timer announced on 60-second interval
- UX-DR6: Today Task Row — time label (40pt column) + task title + metadata; states: upcoming / current / overdue / completed / calendar event; swipe actions: complete (leading), reschedule (trailing)
- UX-DR7: Stake Slider — CupertinoSlider base with custom track painter; green/yellow/red zones with haptic pulses at threshold crossings; lock icon closes more firmly at higher values; inline calibration guidance in red zone; supports typed exact amount
- UX-DR8: Commitment Ceremony Card — full-screen commitment lock flow; charity selection; deadline display; past self / future self framing; satisfying micro-animation on lock confirmation ("vault door closing")
- UX-DR9: Schedule Health Strip — weekly health indicator (green/amber/red by load); tap any amber/red day to see at-risk tasks; displayed at top of Today tab
- UX-DR10: Watch Mode Overlay — minimal, non-distracting in-app session UI; camera indicator clearly visible; macOS omits Watch Mode with no broken affordances
- UX-DR11: Proof Capture Modal — 4 proof paths (photo/video, HealthKit auto, screenshot/document, offline queued); pulsing arc animation during AI verification; timeout at 10s → retry CTA
- UX-DR12: Timeline View — Spatial Timeline toggle on Today tab; toggle between list view and timeline view; scheduled task blocks with calendar events as immovable items
- UX-DR13: Chapter Break Screen — transition screen after significant milestones (task commitment, task completion, missed commitment recovery); "that one's done — what does your future self need now?" recovery framing
- UX-DR14: Empty States — list-specific and context-aware empty states; never generic; first empty state in Now tab is the onboarding "sample schedule magic moment"
- UX-DR15: Guided Chat Input — multi-turn LLM modal sheet (distinct from Quick capture single utterance); appears when user taps "Guided" in Add tab; conversational back-and-forth to build task properties
- UX-DR16: Overbooking Warning — inline banner when schedule is overloaded; at-risk vs. critical treatment; actions: reschedule / extend deadline / acknowledge / (for staked tasks) request deadline extension from partner
- UX-DR17: Predicted Completion Badge — inline date badge on task/section/list; tapping reveals forecast reasoning; updates in real time
- UX-DR18: Schedule Change Banner — in-app banner on Today tab when schedule regenerates mid-session; shows what changed and why
- UX-DR19: Impact Dashboard Cells — milestone/achievement display cells for the impact dashboard (FR27); "evidence of who you've become" framing; not a stats page; natural sharing moment

**Motion System**
- UX-DR20: Named motion tokens with reduced-motion variants: The vault close (commitment lock), The release (stake released on completion), The reveal (schedule generation animation — sequential task appearance, 50ms stagger), The chapter break (screen transition after milestone), The plan shifts (schedule change indication); all tokens must degrade gracefully when "Reduce Motion" is enabled

**Accessibility**
- UX-DR21: VoiceOver Semantics widget implementation for all 15 custom components — standard Cupertino components handle VoiceOver automatically; custom components require explicit `Semantics` widgets with full labels
- UX-DR22: Dynamic Type support throughout — all text uses theme text styles; no hardcoded sizes; test at all Dynamic Type sizes including accessibility sizes
- UX-DR23: macOS keyboard navigation — Tab between panes; arrow keys within lists; all shortcuts: ⌘N (new task), ⌘↩ (complete), Space (timer), ⌘K (command palette), ⌘1–4 (tab navigation), ⌘, (settings)
- UX-DR24: VoiceOver notifications for Live Activity state changes — `UIAccessibility.post(notification: .announcement, argument:)` called from Swift extension (not Flutter); native Swift responsibility

**Platform Features**
- UX-DR25: Live Activity extension — Dynamic Island (compact: task name + elapsed timer arc; expanded: full title + time + Done/Pause/Watch Mode; minimal: arc indicator) + Lock Screen variants (task timer, commitment deadline countdown, Watch Mode session); 3 activity types: `task_timer`, `commitment_countdown`, `watch_mode`
- UX-DR26: WidgetKit home screen widgets — Now widget (small): current task name + timer or next scheduled task; Today widget (medium): next 3 scheduled tasks + schedule health strip; both use active theme colour tokens

**Onboarding**
- UX-DR27: Onboarding sample schedule — pre-populated demo schedule shown before calendar access is requested (emotional hook: "this is what my day could look like"); implemented as static Flutter fixtures (`lib/core/fixtures/demo_schedule.dart`), no API call required before auth

**Loading & Async States**
- UX-DR28: Skeleton loading states — Today tab: 3–4 skeleton rows, shimmer sweep 1.2s loop, max 800ms before real content; Now tab card skeleton matching card proportions
- UX-DR29: LLM parse progressive display — interpreted field pills appear incrementally as LLM resolves each field; title within 300ms; duration/due date/list appear in sequence with 150ms stagger; low-confidence pills have dashed border
- UX-DR30: AI proof verification animation — pulsing arc around captured image preview; `color.accent.primary` stroke, 1.5s loop; "Reviewing your proof…" copy; timeout at 10s → error + retry
- UX-DR31: HealthKit pending badge — "Verifying" badge on Now tab HealthKit tasks; 30-minute buffer: if HealthKit data has not arrived within 30 minutes of task deadline, badge changes to "Verify manually" with dispute/photo-fallback CTA

**Copy System**
- UX-DR32: Past self / future self narrative voice system — consistent warm narrative voice throughout; all copy externalized in `l10n/app_en.arb`; key touchpoints: task creation, commitment flow, deadline reminders, completion screens, recovery screens, shared list collaborative framing (named-person: "What do [Name] and [Name] need from you today?")
- UX-DR36: Brand voice constraints — do NOT use "ADHD-specific" framing (a turn-off even for ADHD users); frame around "executive dysfunction" broadly; "mental load" is the resonant phrase for the couples segment; "calm, not clinical" tone throughout; tagline: "Stop planning. Start doing."; rejected tagline (do not use): "The task manager that holds you accountable."

**High-Priority Screens**
- UX-DR33: Dispute confirmation screen — must simultaneously communicate: (1) dispute received and being reviewed, (2) stake will not be charged during review, (3) response within 24 hours; failure on any of these three destroys trust in the commitment mechanic
- UX-DR34: Commitment lock flow (full design) — stake slider → charity selection → deadline confirmation → group approval flow (FR29, unanimous required) → pool mode opt-in (FR30, explicit from all members) → lock confirmation animation

**Responsive**
- UX-DR35: iPad V1 — phone layout renders acceptably centred on iPad screen; declared "supported but not optimised" in V1; V1.1 upgrade path: `LayoutBuilder` breakpoint at 600pt logical width → two-column layout (sidebar 240pt + content)

**Total UX-DRs: 35**

---

### Deployment & Launch Requirements

**TestFlight**
- DEPLOY-1: App deployed to TestFlight for internal testing; Fastlane lane configured for TestFlight builds (`fastlane beta`); build number auto-incremented on each upload
- DEPLOY-2: App signed with correct provisioning profiles for iOS and macOS (App Store distribution); entitlements verified: Push Notifications, Associated Domains, Live Activities, HealthKit, Sign In with Apple
- DEPLOY-3: App Store Connect app record created with bundle ID `com.ontaskhq.ontask`; TestFlight internal test group configured
- DEPLOY-4: `apns-environment: production` entitlement set for TestFlight/production builds; `apns-environment: development` for local debug

**Marketing Site**
- MKTG-1: Single-page marketing site at `ontaskhq.com` — deployed on Cloudflare Pages; static HTML/CSS (no framework required); mobile-responsive
- MKTG-2: Site content: hero section (tagline + one-line value proposition), three feature highlights (intelligent scheduling, shared lists, commitment contracts), pricing section (Individual/Couple/Family & Friends tiers with ~$10/mo anchor), primary CTA (App Store link — direct to app listing)
- MKTG-3: `apple-app-site-association` (AASA) file served at `ontaskhq.com/.well-known/apple-app-site-association` — required for Universal Links (Stripe payment return flow); `Content-Type: application/json`, no redirects; this file is a hard technical dependency for the commitment contract flow and must be in place before TestFlight deployment
- MKTG-4: Payment setup page at `ontaskhq.com/setup` — Stripe.js hosted page for Stripe SetupIntent (web-based payment method storage); required for commitment contract onboarding; deployed alongside marketing site
- MKTG-5: Privacy policy page at `ontaskhq.com/privacy` — required for App Store review; must cover Watch Mode camera data handling, proof media retention, HealthKit data usage, and payment data handling

---

### FR Coverage Map

| Epic | Functional Requirements | Additional Requirements |
|------|------------------------|------------------------|
| **1 · Foundation & User Accounts** | FR48, FR60, FR61, FR77, FR81, FR91, FR92, FR94 | ARCH-1–20, 30–31 · NFR-S1, S5, S7, S8 · UX-DR1–4, 14, 21–23, 27–28, 32, 36 |
| **2 · Task Capture & Daily Planning** | FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR55, FR56, FR57, FR58, FR59, FR68, FR69, FR73, FR74, FR76, FR78 | NFR-P1, P2, P8, P9, P10, P11 · NFR-UX1, UX2 · UX-DR5, 6, 9, 12, 13, 14, 17, 18, 28, 35 |
| **3 · Intelligent Scheduling & Calendar Sync** | FR9, FR10, FR11, FR12, FR13, FR14, FR46, FR79 | ARCH-21, 22, 23 · NFR-P3, P4, P5 · NFR-Q1, Q2 · NFR-I1, I2 · UX-DR16, 20 |
| **4 · AI-Powered Task Capture (NLP)** | FR1b, FR14 | UX-DR15, 29 |
| **5 · Shared Lists & Household Coordination** | FR15, FR16, FR17, FR18, FR19, FR20, FR21, FR62, FR75 | — |
| **6 · Commitment Contracts & Payments** | FR22, FR23, FR24, FR25, FR26, FR27, FR28, FR29, FR30, FR63, FR64, FR65, FR71 | ARCH-24, 25, 29 · NFR-S2 · NFR-R1, R2, R4 · NFR-I4, I5 · UX-DR7, 8, 19, 33, 34 · MKTG-3, 4 |
| **7 · Proof & Verification** | FR31, FR32, FR33, FR34, FR35, FR36, FR37, FR38, FR39, FR40, FR41, FR47, FR66, FR67 | ARCH-26, 32 · NFR-S3, S4 · NFR-R5 · NFR-I3 · UX-DR10, 11, 30, 31 |
| **8 · Notifications & Alerts** | FR42, FR43, FR72 | ARCH-27 · UX-DR16, 24 |
| **9 · Subscriptions & Billing** | FR49, FR82, FR83, FR84, FR85, FR86, FR87, FR88, FR89, FR90 | NFR-R7 · UX-DR14 |
| **10 · REST API & MCP Server** | FR44, FR45, FR71, FR80, FR93 | NFR-P6, P7 · NFR-I6 |
| **11 · Operator Dashboard** | FR51, FR52, FR53, FR54 | NFR-S6 · NFR-R3 · NFR-B1 |
| **12 · iOS Live Activities & Widgets** | *(platform feature — no FR number)* | ARCH-28 · DEPLOY-2, 4 · UX-DR24, 25, 26 |
| **13 · Marketing Site & Public Launch** | *(launch requirements — no FR number)* | DEPLOY-1, 2, 3, 4 · MKTG-1, 2, 3, 4, 5 |

**Coverage check**: All 93 FRs assigned. FR14 shared between Epic 3 (scheduling nudge backend) and Epic 4 (NLP capture UI). FR71 shared between Epic 6 (contract status) and Epic 10 (public API endpoint). MKTG-3 and MKTG-4 cross-listed in Epic 6 as hard dependencies.

---

## Epic List

### Epic 1: Foundation & User Accounts
**Goal**: Establish the monorepo, project scaffold, CI/CD, design system, authentication, and core user account management — the foundational layer every other epic builds on.

**Requirements covered**: FR48, FR60, FR61, FR77, FR81, FR91, FR92, FR94 · ARCH-1–20, 30–31 · NFR-S1, S5, S7, S8 · UX-DR1–4, 14, 21–23, 27–28, 32, 36

---

### Epic 2: Task Capture & Daily Planning
**Goal**: Enable users to create, manage, and view tasks and lists — Now tab, Today tab, all task-level CRUD, search, recurring tasks, templates, and bulk operations.

**Requirements covered**: FR1, FR2–8, FR55–59, FR68–69, FR73–74, FR76, FR78 · NFR-P1, P2, P8–11 · NFR-UX1, UX2 · UX-DR5, 6, 9, 12, 13, 14, 17, 18, 28, 35

---

### Epic 3: Intelligent Scheduling & Calendar Sync
**Goal**: Implement the deterministic scheduling engine and Google Calendar bidirectional sync — the core intelligence that differentiates On Task from a plain to-do app.

**Requirements covered**: FR9–14, FR46, FR79 · ARCH-21–23 · NFR-P3–5, Q1–2, I1–2 · UX-DR16, 20

---

### Epic 4: AI-Powered Task Capture (NLP)
**Goal**: Enable natural language task creation and guided conversational capture — both quick single-utterance capture and multi-turn Guided Chat mode.

**Requirements covered**: FR1b, FR14 · UX-DR15, 29

---

### Epic 5: Shared Lists & Household Coordination
**Goal**: Enable list sharing, member management, configurable task assignment strategies, and collaborative accountability between household or group members.

**Requirements covered**: FR15–21, FR62, FR75

---

### Epic 6: Commitment Contracts & Payments
**Goal**: Implement the full commitment contract mechanic — stake setting, payment method storage via web flow, automated charges, charity disbursement, group commitments, and the impact dashboard.

**Requirements covered**: FR22–30, FR63–65, FR71 · ARCH-24–25, 29 · NFR-S2, R1–2, R4, I4–5 · UX-DR7, 8, 19, 33, 34
**Cross-epic dependency**: MKTG-3 (AASA file) and MKTG-4 (payment setup page) from Epic 13 must be deployed before this epic can be tested end-to-end.

---

### Epic 7: Proof & Verification
**Goal**: Implement all proof submission modes (photo/video, Watch Mode, HealthKit, screenshot/document, offline queued), AI verification, dispute flow, and operator resolution.

**Requirements covered**: FR31–41, FR47, FR66–67 · ARCH-26, 32 · NFR-S3–4, R5, I3 · UX-DR10, 11, 30, 31

---

### Epic 8: Notifications & Alerts
**Goal**: Deliver contextual, configurable push notifications and in-app alerts across all key lifecycle events via APNs direct (no Firebase).

**Requirements covered**: FR42–43, FR72 · ARCH-27 · UX-DR16, 24

---

### Epic 9: Subscriptions & Billing
**Goal**: Implement the full subscription lifecycle — 14-day free trial, tier selection, paywall, upgrades/downgrades, cancellation grace periods, and invited-user onboarding paths.

**Requirements covered**: FR49, FR82–90 · NFR-R7 · UX-DR14

---

### Epic 10: REST API & MCP Server
**Goal**: Build the versioned public REST API and OAuth-secured MCP server, enabling external system integrations and AI assistant access with full task and scheduling feature parity.

**Requirements covered**: FR44–45, FR71, FR80, FR93 · NFR-P6–7, I6

---

### Epic 11: Operator Dashboard
**Goal**: Build internal operator tooling for dispute resolution, charge reversal, user impersonation (with immutable audit log), and business event monitoring.

**Requirements covered**: FR51–54 · NFR-S6, R3, B1

---

### Epic 12: iOS Live Activities & Widgets
**Goal**: Implement the native iOS Live Activities extension (Dynamic Island + Lock Screen) and WidgetKit home screen widgets for real-time task status outside the app.

**Requirements covered**: ARCH-28 · DEPLOY-2 (entitlements), DEPLOY-4 (APNs environment) · UX-DR24–26

---

### Epic 13: Marketing Site & Public Launch
**Goal**: Deploy the single-page marketing site at ontaskhq.com (including AASA file and payment setup page), configure TestFlight, and prepare all App Store submission requirements.

**Requirements covered**: DEPLOY-1–4 · MKTG-1–5
**Note**: MKTG-3 (AASA) and MKTG-4 (payment setup page) are hard dependencies for Epic 6 (Commitment Contracts). Prioritise these two items first within this epic.

---

## Epic 1: Foundation & User Accounts

**Goal**: Establish the monorepo, project scaffold, CI/CD, design system, authentication, and core user account management — the foundational layer every other epic builds on.

---

### Story 1.1: Monorepo & Project Scaffold

As a developer,
I want a complete monorepo scaffold with Flutter, API worker, and MCP worker initialized under pnpm workspaces,
So that all packages share consistent tooling, TypeScript config, and gitignore rules from day one.

**Acceptance Criteria:**

**Given** an empty repository
**When** the monorepo setup is complete
**Then** the workspace root contains `pnpm-workspace.yaml` listing `apps/*` and `packages/*`
**And** `tsconfig.base.json` exists at root with shared compiler options
**And** `apps/api/` contains a Hono worker scaffolded via `npm create hono@latest -- --template cloudflare-workers`
**And** `apps/mcp/` contains a Hono worker scaffolded via `npm create hono@latest -- --template cloudflare-workers`
**And** `apps/flutter/` contains a Flutter project created with `flutter create --org com.ontaskhq --platforms=ios,macos --project-name ontask`
**And** the root `.gitignore` does NOT include entries for `*.g.dart` or `*.freezed.dart`
**And** `pnpm install` from root succeeds with no errors

---

### Story 1.2: CI/CD Pipeline & Staging Environments

As a developer,
I want automated CI checks on every PR and ephemeral staging environments,
So that broken code is caught before merging and features can be tested against real infrastructure.

**Acceptance Criteria:**

**Given** a pull request is opened or synchronized
**When** the CI pipeline runs
**Then** a GitHub Actions workflow executes: Flutter unit + widget tests, scheduling engine tests with 100% coverage gate, lint + type check for all TypeScript packages, and a Wrangler dry-run bundle size check that fails if either Worker exceeds 8MB
**And** a Neon ephemeral database branch is created for the PR on open/synchronize
**And** the ephemeral branch is deleted when the PR is closed or merged

**Given** the monorepo exists
**When** staging environment configuration is complete
**Then** `wrangler.toml` in `apps/api/` defines a `staging` environment bound to `api.staging.ontaskhq.com`
**And** `wrangler.toml` in `apps/mcp/` defines a `staging` environment bound to `mcp.staging.ontaskhq.com`
**And** a Fastlane `Fastfile` exists in `apps/flutter/` with a `beta` lane that auto-increments build number and uploads to TestFlight

---

### Story 1.3: API Foundation — Database & Response Standards

As a developer,
I want a configured Drizzle ORM database layer and enforced API response standards,
So that all routes share a consistent schema, response envelope, and pagination contract.

**Acceptance Criteria:**

**Given** the API worker is initialized
**When** the database layer is configured
**Then** `@neondatabase/serverless` is installed using HTTP transport only — no `pg`, no connection pooling
**And** every Drizzle instance is initialized with `casing: 'camelCase'` — no manual field name mapping
**And** all schema migrations are Drizzle Kit SQL files committed to `packages/core/schema/migrations/`
**And** tables are created only in the story that first uses them — no upfront bulk schema

**Given** a Hono route returns a successful single-object response
**When** the response is received by the client
**Then** the body is `{ "data": { ... } }`

**Given** a Hono route returns a successful list response
**When** the response is received by the client
**Then** the body is `{ "data": [...], "pagination": { "cursor": "...", "hasMore": true } }` — cursor-based only, no offset/limit pagination anywhere

**Given** a Hono route encounters an error
**When** the error response is returned
**Then** the body is `{ "error": { "code": "SCREAMING_SNAKE_CASE", "message": "...", "details": {} } }`
**And** all date fields in any response are ISO 8601 UTC strings
**And** all JSON field names are camelCase
**And** CORS is scoped only to `/admin/v1/*` and payment setup endpoints — not global

**Given** a new Hono route is created
**When** the route is registered
**Then** it has a `@hono/zod-openapi` schema definition — no untyped routes are accepted

---

### Story 1.4: Flutter Architecture Foundation

As a developer,
I want a feature-first clean architecture scaffold with Riverpod, go_router, drift, and freezed configured,
So that all feature development follows consistent patterns across data, domain, and presentation layers.

**Acceptance Criteria:**

**Given** the Flutter project exists
**When** the architecture scaffold is complete
**Then** `lib/features/` contains an example feature folder with `data/`, `domain/`, and `presentation/` subdirectories and documented conventions
**And** `flutter_riverpod` and `riverpod_annotation` are installed; all async providers return `AsyncValue<T>` — never raw `Future<T>`
**And** `go_router` is installed and a root `AppRouter` provider is configured
**And** `drift` is installed for local SQLite storage
**And** `freezed` and `json_serializable` are installed; generated `*.g.dart` and `*.freezed.dart` files are committed to the repo
**And** `build_runner` is documented as a local-only dev command — it does not run in CI

**Given** the API client pattern is established
**When** any feature makes an API call
**Then** it uses a shared `ApiClient` class injected via a Riverpod provider — never instantiated directly as a singleton
**And** a global 401 interceptor in `ApiClient` silently refreshes the token and retries the request once; on a second consecutive 401 it forces a full sign-out

**Given** a domain model is created
**When** it uses a union or sealed type
**Then** `freezed` union types (sealed classes) live only in `domain/` — never in `data/`

---

### Story 1.5: Design System & Theme Implementation

As a user,
I want a visually distinctive app with the Clay colour palette, serif typography, and multiple theme options,
So that On Task feels warm, trustworthy, and personally comfortable from first launch.

**Acceptance Criteria:**

**Given** the Flutter project exists
**When** the design system is implemented
**Then** `lib/core/theme/app_theme.dart` defines all design tokens as named constants: Clay terracotta `#C4623A`, cream `#FDF6EE`, slate `#3D3D3D`, commitment purple, success green, warning amber, and all derived surface, text, and border tokens
**And** four named theme variants exist as `ThemeData` instances: Clay, Slate, Dusk, Monochrome
**And** light and dark variants exist for all four themes (8 total `ThemeData` instances)
**And** all themes pass WCAG 2.1 AA contrast: minimum 4.5:1 for body text, 3:1 for large text

**Given** the theme is applied
**When** the New York serif font is configured
**Then** the app uses the `.NewYorkFont` platform string on iOS
**And** a Playfair Display subset is bundled as a fallback serif for future Android support
**And** font availability is detected via platform channel before applying New York; the fallback is applied when unavailable

**Given** any text widget is rendered
**When** it uses the design system
**Then** no text size is hardcoded — all text styles reference theme text tokens
**And** all text scales correctly at all Dynamic Type sizes including the largest accessibility sizes (NFR-A3)

---

### Story 1.6: iOS Navigation Shell & Loading States

As an iOS user,
I want a four-tab navigation shell with skeleton loading and context-aware empty states,
So that the app structure is immediately familiar and loading never shows a blank screen.

**Acceptance Criteria:**

**Given** the app launches on iOS
**When** the main shell renders
**Then** a Cupertino tab bar displays four tabs in order: Now, Today, Add, Lists
**And** tapping the Add tab opens the task capture UI — it does not navigate to a persistent content tab
**And** tab bar items use the design system accent colour for the selected state

**Given** the Today tab is loading
**When** data has not resolved within the first render frame
**Then** 3–4 skeleton task rows display with a shimmer sweep animation (1.2s loop)
**And** the Now tab card area shows a skeleton matching approximate card proportions
**And** real content replaces skeletons as soon as data resolves, with no flash of empty state (NFR-P1)

**Given** a tab has no content to display
**When** the empty state renders
**Then** Now, Today, and Lists tabs each display a distinct empty state with unique copy and illustration per tab
**And** no empty state uses generic language; all copy follows the warm narrative voice (UX-DR32)

---

### Story 1.7: macOS Layout & Keyboard Navigation

As a macOS user,
I want a three-pane layout with keyboard shortcuts and a native toolbar,
So that On Task feels at home on desktop and I can navigate without lifting my hands from the keyboard.

**Acceptance Criteria:**

**Given** the app launches on macOS with window width ≥ 900pt
**When** the main layout renders
**Then** a three-pane layout is shown: sidebar at 260pt fixed width, detail panel at minimum 320pt, main content area filling the remaining space
**And** when total window width is ≤ 1100pt, the layout collapses to two-pane (sidebar + main content; detail panel hidden)
**And** the minimum window size is enforced at 900×600pt — the window cannot be resized smaller

**Given** the macOS layout is active
**When** the toolbar is rendered
**Then** a "New Task" button appears in the window toolbar replacing the Add tab concept
**And** the four navigation sections (Now, Today, Lists, Settings) appear as sidebar items — no bottom tab bar

**Given** the macOS app has focus
**When** the user presses a keyboard shortcut
**Then** ⌘N opens the new task creation flow
**And** ⌘↩ marks the focused task complete
**And** Space starts or stops the timer for the focused task
**And** ⌘K opens the command palette
**And** ⌘1–⌘4 navigate to the four main sidebar sections
**And** ⌘, opens the Settings pane
**And** Tab moves keyboard focus between the three panes (NFR-A2, UX-DR23)

---

### Story 1.8: User Authentication

As a user,
I want to sign in with Apple, Google, or email and password,
So that I can securely access my On Task account across all my devices.

**Acceptance Criteria:**

**Given** the app is launched for the first time or after sign-out
**When** the authentication screen is shown
**Then** Sign in with Apple, Sign in with Google, and email/password options are all visible
**And** Sign in with Apple is the topmost option on iOS per Apple HIG

**Given** a user successfully authenticates
**When** the server issues tokens
**Then** the access token is a short-lived JWT (≤ 15 minutes expiry)
**And** the refresh token is rotated on every use — the previous token is immediately invalidated (NFR-S5)
**And** both tokens are stored in the iOS Keychain — not in NSUserDefaults or unprotected storage

**Given** a user's access token has expired mid-session
**When** the app makes an API request
**Then** the 401 interceptor from Story 1.4 silently refreshes the token and retries once with no user-visible interruption

**Given** a user enters an incorrect email or password
**When** authentication fails
**Then** a plain-language error message is shown with a recovery action link to reset the password
**And** no technical error codes or internal identifiers are visible to the user (NFR-UX2)

**Given** any data is transmitted between app and API
**When** the connection is established
**Then** TLS 1.3 minimum is enforced (NFR-S1)

---

### Story 1.9: Onboarding Flow & Sample Schedule

As a new user,
I want to experience a demo schedule before connecting my calendar or creating any tasks,
So that I understand what On Task will feel like before committing time to setup.

**Acceptance Criteria:**

**Given** a user completes authentication for the first time
**When** onboarding begins
**Then** the Now tab displays a pre-populated sample schedule sourced from `lib/core/fixtures/demo_schedule.dart` — no API call is made before showing this (UX-DR27)
**And** the demo tasks use the "past self / future self" narrative voice and warm tone (UX-DR32, UX-DR36)
**And** no calendar permission or any system permission is requested before the user sees the sample schedule

**Given** the user has seen the sample schedule
**When** they proceed through onboarding
**Then** they are guided through: calendar connection (Google Calendar OAuth), energy preference setup (peak hours, low-energy hours, wind-down time), and preferred working hours
**And** each step has a clearly labelled "Set this up later" affordance
**And** skipping any step does not block access to the app

**Given** a user completes or fully skips onboarding
**When** they arrive at the main app for real use
**Then** demo fixture data is replaced by their real tasks (or a fresh empty state)
**And** onboarding completion state is persisted server-side so re-launching the app never restarts the onboarding flow
**And** the Now tab empty state shown during the sample schedule phase uses the onboarding fixture (UX-DR27) — once onboarding is complete or skipped, the standard Now tab empty state renders instead

---

### Story 1.10: Account Settings & Session Management

As a user,
I want to manage my app appearance, view active sessions, and revoke device access remotely,
So that I have full control over how On Task looks and who can access my account.

**Acceptance Criteria:**

**Given** the user opens Settings → Appearance
**When** they adjust the theme
**Then** they can select from four themes: Clay, Slate, Dusk, Monochrome
**And** they can toggle light, dark, or system (automatic) mode
**And** they can adjust text size with at least three increments above the system default (NFR-A5)
**And** all changes apply immediately with no restart required (FR77)

**Given** the user opens Settings → Security → Active Sessions
**When** the sessions list loads
**Then** each session shows: device name, approximate location (city/country), and last-active timestamp
**And** the current session is labelled "This device"
**And** every other session has a "Sign out this device" action (FR91)

**Given** the user taps "Sign out this device" for a non-current session
**When** the action is confirmed
**Then** that session's refresh token is immediately invalidated server-side
**And** the signed-out device will receive a 401 on its next API call and be forced to re-authenticate

**Given** the user is offline and makes changes, then reconnects
**When** sync occurs and a conflict exists between offline and server-side changes to the same task
**Then** server state wins for structural properties (list membership, assignment)
**And** client state wins for content properties (title, notes) if the client timestamp is more recent than the server's last-modified timestamp
**And** resolved conflicts are communicated to the user in plain language (NFR-UX2, FR94)

---

### Story 1.11: Account Deletion, Data Export & Two-Factor Authentication

As a user,
I want to export my data, delete my account, and optionally add a second authentication factor,
So that I have full data portability and can secure my account beyond a password.

**Acceptance Criteria:**

**Given** the user opens Settings → Account → Export Data
**When** they request an export
**Then** a ZIP archive is generated containing tasks and lists in both CSV and Markdown formats (FR81)
**And** all task properties are included: title, notes, due date, scheduled time, completion status, list membership
**And** the archive is available for download within 60 seconds for typical account sizes

**Given** the user opens Settings → Account → Delete Account
**When** they initiate deletion
**Then** a confirmation screen clearly states: all data will be permanently deleted, active commitment contracts will continue to their deadlines, and the account cannot be recovered (FR60)
**And** deletion requires the user to type "delete my account" to confirm
**And** after successful deletion, the user is signed out and shown a farewell screen
**And** server-side, user data is queued for permanent deletion after 30 days — not immediately purged (NFR-R7)

**Given** the user has an email/password account and enables two-factor authentication in Settings
**When** they complete 2FA setup
**Then** they are guided through TOTP setup with a QR code for an authenticator app and a set of one-time backup codes (FR92)
**And** subsequent email/password logins require a valid TOTP code or backup code after password entry
**And** 2FA setup is not shown to Apple Sign In or Google Sign In users — those accounts delegate security to their OAuth providers (NFR-S8)

---

### Story 1.12: Observability & Error Tracking Bootstrap

As a developer and operator,
I want PostHog analytics and GlitchTip error tracking configured from app initialization,
So that crashes, errors, and key business events are captured before the first real user interaction.

**Acceptance Criteria:**

**Given** the Flutter app starts
**When** initialization runs
**Then** `sentry_flutter` SDK is initialized with the GlitchTip DSN as the first action before any app code runs (ARCH-31)
**And** unhandled Dart exceptions and Flutter framework errors are automatically captured and reported
**And** GlitchTip is configured for both iOS and macOS targets

**Given** the API worker handles a request
**When** an unhandled error is thrown
**Then** the error is reported to GlitchTip via the Sentry-compatible HTTP API with: Worker name, environment (production/staging), request path, and error message

**Given** the PostHog Flutter SDK is initialized
**When** a key business event occurs
**Then** the event is emitted to PostHog: `trial_started`, `trial_expired`, `subscription_activated`, `subscription_cancelled`, `task_completed`, `stake_set`, `charge_fired` (ARCH-30, NFR-B1)
**And** no personally identifiable information (name, email, payment details) is included in PostHog event properties
**And** PostHog feature flag evaluation is available via a `FeatureFlagProvider` Riverpod provider that any feature can inject

---

## Epic 2: Task Capture & Daily Planning

**Goal**: Enable users to create, manage, and view tasks and lists — Now tab, Today tab, all task-level CRUD, search, recurring tasks, templates, and bulk operations.

---

### Story 2.1: Task & List CRUD

As a user,
I want to create tasks, organize them into lists and sections, and edit or archive them,
So that I can capture and manage everything I need to do in a structured way.

**Acceptance Criteria:**

**Given** the user opens the Add tab or taps a list
**When** they create a task
**Then** the task can be saved with: title (required), notes, due date, and list assignment
**And** the task appears in the list within 500ms of confirmation (NFR-P2)

**Given** a list exists
**When** the user creates a section within it
**Then** sections can be infinitely nested; subtasks can be nested under any task
**And** a section or list can have a default due date that is inherited by any task created within it that does not have its own due date (FR3)

**Given** a task exists
**When** the user edits it
**Then** all task properties (title, notes, due date, list, section) are editable inline (FR58)
**And** changes are saved immediately without a separate save action

**Given** a task is complete or no longer relevant
**When** the user archives it
**Then** the task is hidden from the active view but retained in the archive (FR59)
**And** archived tasks are accessible via a "Show archived" toggle in the list view

**Given** a section contains multiple tasks
**When** the user drags a task
**Then** they can reorder it within the section (FR57)
**And** the new order is persisted immediately

---

### Story 2.2: Task Properties — Scheduling Hints

As a user,
I want to set time-of-day constraints, energy requirements, and priority on my tasks,
So that the scheduler places them in the right windows and I can signal what matters most.

**Acceptance Criteria:**

**Given** a task is being created or edited
**When** the user sets a time-of-day constraint
**Then** they can pin the task to a specific time window: morning, afternoon, evening, or a custom time range (FR4)
**And** the constraint is stored and respected by the scheduling engine

**Given** a user has configured energy availability preferences in onboarding or settings
**When** they set an energy requirement on a task
**Then** available options are: high focus, low energy, flexible
**And** the scheduling engine places high-focus tasks only in the user's declared peak hours (FR5)

**Given** a task exists
**When** the user sets priority
**Then** they can assign urgency: normal, high, or critical — independent of due date (FR68)
**And** higher-priority tasks are surfaced earlier in scheduling within available constraints

---

### Story 2.3: Recurring Tasks

As a user,
I want to create recurring tasks with full feature parity to one-off tasks,
So that I can track regular commitments — including staking money on habits — the same way I track everything else.

**Acceptance Criteria:**

**Given** the user creates a task
**When** they set a recurrence schedule
**Then** available options are: daily, weekly (with day-of-week selection), monthly, and custom interval (FR7)
**And** completing a recurring task instance generates the next instance automatically

**Given** a recurring task exists
**When** the user edits it
**Then** they are offered: edit this instance only, or edit this and all future instances
**And** editing a single instance does not affect other instances

**Given** a recurring task is staked
**When** the task recurs
**Then** each new instance carries the same stake, charity, and proof settings as the original (full feature parity)
**And** each instance is independently charged or verified on its own deadline

---

### Story 2.4: Task Templates

As a user,
I want to save lists and sections as templates and apply them to new work,
So that I don't have to rebuild the same structure from scratch for recurring projects.

**Acceptance Criteria:**

**Given** the user opens a list or section
**When** they choose "Save as template"
**Then** the template captures: all sections, all tasks, all task properties, and the section hierarchy (FR78)
**And** the template is saved and available in the template library

**Given** the user creates a new list or section
**When** they choose "Start from template"
**Then** they see their saved templates
**And** applying a template creates a copy of the structure with all tasks in a "not started" state
**And** due dates from the template can be offset by a user-specified number of days from today

---

### Story 2.5: Task Dependencies & Bulk Operations

As a user,
I want to define dependencies between tasks and take actions on multiple tasks at once,
So that the scheduler respects task ordering and I can manage my list efficiently.

**Acceptance Criteria:**

**Given** two tasks exist
**When** the user creates a dependency (Task B depends on Task A)
**Then** the scheduling engine does not schedule Task B before Task A's due date (FR73)
**And** the dependency relationship is visible on both task cards

**Given** the user selects multiple tasks
**When** they perform a bulk operation
**Then** available operations are: reschedule, mark complete, assign (to a shared list member), delete (FR74)
**And** delete and complete show a confirmation before executing
**And** bulk reschedule opens a date picker that applies the new date to all selected tasks

---

### Story 2.6: Today Tab & Schedule Health Strip

As a user,
I want a Today tab showing my tasks for the day with a weekly health indicator,
So that I always know what's on my plate and whether I'm on track for the week.

**Acceptance Criteria:**

**Given** the user opens the Today tab
**When** the tasks load
**Then** tasks scheduled for today are shown in chronological order with: time label (40pt column), task title, and status indicator (FR69, UX-DR6)
**And** task row states are visually distinct: upcoming, current (highlighted), overdue (amber), completed (muted), calendar event (grey)
**And** swipe right on a task row completes it; swipe left opens a reschedule picker

**Given** the Today tab is loading
**When** data has not yet resolved
**Then** 3–4 skeleton rows display with a shimmer sweep animation (1.2s loop); real content replaces them within 800ms (UX-DR28)

**Given** the Schedule Health Strip is rendered at the top of the Today tab
**When** the weekly health is calculated
**Then** each day chip is coloured: green (on track), amber (at risk — overloaded), or red (critical — tasks will miss deadlines) (UX-DR9)
**And** tapping an amber or red day shows a list of the at-risk tasks for that day

---

### Story 2.7: Now Tab Task Card

As a user,
I want the Now tab to show me a rich card for my current task with proof mode context,
So that I always know exactly what to do next and how to prove I did it.

**Acceptance Criteria:**

**Given** the Now tab loads
**When** a current task is active
**Then** the task card shows: task title (New York serif), attribution (shared list name + assignor if applicable), stake amount (if staked), deadline, and proof mode indicator (UX-DR5)

**Given** a task card is shown
**When** the proof mode is determined
**Then** the card renders one of five display variants: standard (no stake), committed + photo proof, committed + Watch Mode, committed + HealthKit, calendar event

**Given** the task card is rendered
**When** VoiceOver focus lands on it
**Then** the VoiceOver label reads: "[task title], from [list name], [stake amount] staked, due [deadline], [proof mode]" (UX-DR5, NFR-A2)
**And** if a timer is running, VoiceOver announces the elapsed time on a 60-second interval

**Given** the Dynamic Island is present on the device
**When** the task card renders
**Then** sufficient top padding is reserved to avoid the Dynamic Island zone

---

### Story 2.8: Timeline View

As a user,
I want to toggle between a list view and a visual timeline view on the Today tab,
So that I can see my day as a spatial schedule when that mental model works better for me.

**Acceptance Criteria:**

**Given** the user is on the Today tab
**When** they tap the timeline toggle
**Then** the view switches from the task row list to a time-blocked timeline view (UX-DR12)
**And** scheduled task blocks appear as time-proportional visual blocks
**And** calendar events appear as immovable grey blocks
**And** tapping any block opens the task detail or calendar event detail

**Given** the timeline view is active
**When** the user toggles back to list view
**Then** the list view is restored instantly with no loading state
**And** the user's preferred view (list or timeline) is persisted across sessions

---

### Story 2.9: Task Search & Filter

As a user,
I want to search all my tasks and filter by list, date, and status,
So that I can find any task quickly regardless of how many lists I have.

**Acceptance Criteria:**

**Given** the user opens search
**When** they type a query
**Then** results are returned across all lists and sections matching the task title or notes (FR56)
**And** results appear within 1 second for lists up to 500 tasks (NFR-P9)

**Given** the user applies filters
**When** multiple filters are combined
**Then** results show only tasks matching all active filters (AND logic)
**And** available filter dimensions: list, due date range, status (upcoming / overdue / completed), has stake
**And** active filters are displayed as removable chips

---

### Story 2.10: Explicit Task Begin & Timer

As a user,
I want to explicitly start a task and track how long I spend on it,
So that I have a conscious, intentional moment of beginning and can see where my time goes.

**Acceptance Criteria:**

**Given** a task is shown in the Now or Today tab
**When** the user taps "Start"
**Then** the task is marked as in-progress and an elapsed timer begins in the Now tab card (FR76)
**And** the timer persists correctly across app background and foreground transitions

**Given** a task timer is running
**When** the user pauses or stops it
**Then** the timer stops and the elapsed time is recorded on the task
**And** stopping the timer does not mark the task as complete — that requires a separate explicit complete action

**Given** a task is started
**When** notifications are configured for that task
**Then** any task-start triggered notifications (reminder, Watch Mode prompt) are sent at this moment

---

### Story 2.11: Predicted Completion Badge

As a user,
I want to see a predicted completion date on any task, section, or list,
So that I know whether my current workload is realistic before deadlines sneak up on me.

**Acceptance Criteria:**

**Given** a task, section, or list is shown
**When** the prediction is available
**Then** an inline date badge shows the predicted completion date (FR6, UX-DR17)
**And** the badge is green if the prediction is before the due date, amber if it's close, and red if it will miss the deadline

**Given** the user taps the Predicted Completion Badge
**When** the detail opens
**Then** the forecast reasoning is shown: tasks remaining, estimated durations, available time windows
**And** the reasoning loads within 1 second (NFR-P5)

**Given** tasks are completed or rescheduled
**When** the schedule is recalculated
**Then** the badge updates in real time without requiring a manual refresh

---

### Story 2.12: Schedule Change Banner & Overbooking Warning

As a user,
I want to be notified when my schedule regenerates and warned when I'm overloaded,
So that I can respond to changes before they become missed deadlines.

**Acceptance Criteria:**

**Given** the scheduling engine regenerates while the user is in the Today tab
**When** the new schedule differs meaningfully from the current view
**Then** an in-app banner appears at the top of the Today tab: "Your schedule has been updated" with a "See what changed" action and a dismiss action (UX-DR18)
**And** tapping "See what changed" shows a diff of moved/removed tasks

**Given** the Today tab loads
**When** the schedule is overloaded
**Then** an Overbooking Warning banner appears inline indicating the severity: amber for at-risk, red for critical (UX-DR16)
**And** available actions are: Reschedule, Extend deadline, Acknowledge
**And** if an overloaded task has a stake, an additional action is shown: "Request deadline extension from partner"

---

### Story 2.13: Chapter Break Screen & iPad Layout

As a user,
I want meaningful transition moments after milestones and an app that works acceptably on iPad,
So that completion feels celebrated and I can use On Task on any device I own.

**Acceptance Criteria:**

**Given** a significant milestone occurs (task commitment locked, task completed, missed commitment recovery)
**When** the transition screen is shown
**Then** the Chapter Break Screen displays with recovery framing: "that one's done — what does your future self need now?" (UX-DR13)
**And** "The chapter break" motion token plays on the transition (50ms fade + slight upward shift)
**And** when "Reduce Motion" is enabled, the transition is an instant cut with no animation

**Given** the app is running on iPad
**When** the UI renders
**Then** the phone layout renders acceptably centred on iPad screen — no broken layouts, no clipped content (UX-DR35)
**And** the app does not crash or display blank screens on any iPad size
**And** a note in the codebase documents the V1.1 upgrade path: `LayoutBuilder` breakpoint at 600pt → two-column layout

---

## Epic 3: Intelligent Scheduling & Calendar Sync

**Goal**: Implement the deterministic scheduling engine and Google Calendar bidirectional sync — the core intelligence that differentiates On Task from a plain to-do app.

---

### Story 3.1: Scheduling Engine Foundation

As a developer,
I want a pure, deterministic scheduling engine package with 100% test coverage enforced in CI,
So that scheduling logic is reliable, testable, and free of side effects from day one.

**Acceptance Criteria:**

**Given** `/packages/scheduling` is scaffolded
**When** the package is complete
**Then** the main export is `schedule(input: ScheduleInput): ScheduleOutput` — a pure function with no side effects, no external calls, and no randomness (ARCH-21)
**And** identical inputs always produce identical outputs — determinism enforced (NFR-Q1)
**And** test naming convention is enforced: `schedule_[constraint]_[condition]_[expected]` (e.g. `schedule_dueDate_taskOverdue_scheduledImmediately`) (ARCH-22)
**And** the CI pipeline fails the build if unit test coverage for `/packages/scheduling` is below 100% (ARCH-23)

---

### Story 3.2: Basic Auto-Scheduling Algorithm

As a user,
I want my tasks automatically scheduled into available time respecting all my constraints,
So that I don't have to manually figure out when to do everything.

**Acceptance Criteria:**

**Given** a user has tasks with due dates and a calendar
**When** the scheduling engine runs
**Then** tasks are placed in available time slots respecting: due dates, time-of-day constraints (FR4), energy preferences (FR5), and existing calendar events (FR9)
**And** tasks with hard time-of-day constraints are pinned to their window; if no slot is available before the due date, the task is marked at-risk

**Given** a task is scheduled
**When** the user manually drags it to a specific time
**Then** the task is locked to that slot (FR8)
**And** the manual override does not affect other tasks' auto-scheduling
**And** the override is visible as a distinct indicator on the task card

**Given** a schedule recalculation is triggered for a single user
**When** it completes
**Then** the result is available within 5 seconds (NFR-P4)

---

### Story 3.3: Google Calendar Read & Available Time

As a user,
I want On Task to read my Google Calendar and schedule around my existing events,
So that tasks never get placed on top of meetings I already have.

**Acceptance Criteria:**

**Given** the user has completed Google Calendar OAuth in onboarding
**When** the calendar connection is active
**Then** Google Calendar events are imported as immovable blocks and the scheduling engine avoids them (FR10)
**And** calendar events appear in the Today tab timeline view as grey blocks alongside task blocks

**Given** a Google Calendar event is created or modified
**When** the change is detected
**Then** the scheduling engine refreshes with the updated events within 60 seconds (NFR-I1)

**Given** the user connects their calendar for the first time
**When** the initial read completes
**Then** events appear in the app within 5 seconds of authorization

---

### Story 3.4: Google Calendar Write & Task-Block Relationship

As a user,
I want my scheduled tasks to appear as blocks in my Google Calendar,
So that my task schedule and my calendar are always the same thing.

**Acceptance Criteria:**

**Given** a task is scheduled by the engine
**When** the task block is written
**Then** a Google Calendar event is created with the task title and a link back to the task (FR11)
**And** the event appears in the user's Google Calendar within 10 seconds of scheduling (NFR-I2)

**Given** a task is rescheduled
**When** the new time is applied
**Then** the Google Calendar event is updated to the new time within 10 seconds (NFR-I2)

**Given** a task has a calendar block
**When** the user taps the block in the Today tab timeline view
**Then** they are navigated to the associated task detail (FR79)

---

### Story 3.5: Auto-Rescheduling on Change

As a user,
I want my schedule to automatically adjust when my calendar changes or tasks slip,
So that my plan always reflects reality without manual intervention.

**Acceptance Criteria:**

**Given** a Google Calendar event changes (time shift or deletion)
**When** the change is detected
**Then** the scheduling engine re-runs within 60 seconds and repositions any conflicting task blocks (FR12, NFR-I1)

**Given** a task passes its scheduled start time without being started
**When** the engine detects the slip
**Then** the task is automatically rescheduled to the next available slot (FR12)
**And** if the user is in the Today tab, the Schedule Change Banner appears (UX-DR18, Story 2.12)

---

### Story 3.6: Scheduling Explanation

As a user,
I want to understand why a task was scheduled at a specific time,
So that I trust the schedule and know how to influence it.

**Acceptance Criteria:**

**Given** a task has been scheduled
**When** the user taps "Why here?" on the task
**Then** a plain-language explanation is shown covering: available time analysis, due date constraint, energy preference match, and any manual overrides that influenced the slot (FR13)
**And** the explanation loads within 1 second (NFR-P5)
**And** no algorithm internals, variable names, or technical language are exposed to the user (NFR-UX2)

---

### Story 3.7: Natural Language Scheduling Nudges & Motion Tokens

As a user,
I want to adjust my schedule using natural language and see smooth animations when it changes,
So that rescheduling feels conversational and changes are visually clear.

**Acceptance Criteria:**

**Given** a task is scheduled
**When** the user types or speaks a natural language nudge ("move my gym session to tomorrow morning")
**Then** the LLM interprets the nudge and proposes a new schedule for the affected task (FR14)
**And** the proposed change is shown to the user for confirmation before applying
**And** confirming updates the task schedule and the Google Calendar block

**Given** the schedule regenerates (any trigger)
**When** tasks are shown for the first time in the day view
**Then** "The reveal" motion token plays: tasks appear sequentially with a 50ms stagger (UX-DR20)
**And** when the schedule updates mid-session, "The plan shifts" motion token plays on the changed items

**Given** the device has "Reduce Motion" enabled
**When** any named motion token would play
**Then** the animation is replaced by an instant state change with no movement (UX-DR20)

---

## Epic 4: AI-Powered Task Capture (NLP)

**Goal**: Enable natural language task creation and guided conversational capture — both quick single-utterance capture and multi-turn Guided Chat mode.

---

### Story 4.1: Quick NLP Task Capture

As a user,
I want to create a task by typing or speaking a single natural language sentence,
So that I can capture ideas instantly without filling in form fields.

**Acceptance Criteria:**

**Given** the user opens the Add tab
**When** they type or speak a natural language utterance ("remind me to call the dentist Thursday at 2pm")
**Then** the LLM parses intent into structured task properties: title, due date, scheduled time, estimated duration, energy level, list assignment (FR1b)
**And** resolved fields appear as labelled pills incrementally as the LLM resolves them — title within 300ms, remaining fields with 150ms stagger (UX-DR29)
**And** low-confidence fields have a dashed border indicating the user should review them
**And** the user can edit any parsed field before confirming

**Given** the user confirms the parsed task
**When** the task is created
**Then** all resolved properties are applied and the task appears in the list within 500ms (NFR-P2, NFR-P3)

---

### Story 4.2: Guided Chat Task Capture

As a user,
I want a multi-turn conversation to help me build out a task when quick capture isn't enough,
So that I can think through complex tasks with the assistance of a patient conversational interface.

**Acceptance Criteria:**

**Given** the user taps "Guided" in the Add tab
**When** the Guided Chat modal opens
**Then** a multi-turn conversational UI appears distinct from the quick-capture interface (UX-DR15)
**And** the LLM conducts a back-and-forth conversation to elicit: task title, due date, time constraints, energy requirements, list assignment, and whether a stake should be attached
**And** the conversation adapts — it does not ask for information already clearly provided

**Given** a Guided Chat session is in progress
**When** the user closes the modal
**Then** the in-progress conversation is discarded and the modal closes cleanly

**Given** the user completes the Guided Chat conversation
**When** they confirm
**Then** the task is created with all collected properties applied

---

### Story 4.3: Natural Language Scheduling Adjustment

As a user,
I want to adjust my schedule for the current task using a natural language input,
So that rescheduling feels like talking to an assistant rather than filling in a form.

**Acceptance Criteria:**

**Given** a task is shown in the Now or Today tab
**When** the user opens the "Reschedule" input
**Then** they can type a natural language adjustment: "move this to after lunch", "I need 30 more minutes", "push this to tomorrow" (FR14)
**And** the system shows the proposed new slot for confirmation before applying it

**Given** the user confirms the adjustment
**When** the rescheduling is applied
**Then** the task's scheduled time is updated and the Google Calendar block is moved accordingly (Story 3.4)

---

## Epic 5: Shared Lists & Household Coordination

**Goal**: Enable list sharing, member management, configurable task assignment strategies, and collaborative accountability between household or group members.

---

### Story 5.1: List Sharing & Invitations

As a user,
I want to share any list with named people by email invitation,
So that my household or team can coordinate tasks in one place.

**Acceptance Criteria:**

**Given** the user opens a list and chooses "Share"
**When** they enter an email address
**Then** an invitation is sent to that address and the list is labelled "shared" with a member count (FR15)

**Given** an invitation is received
**When** the recipient opens the deep link from the email
**Then** they are shown the list name and the name of the person who invited them
**And** accepting adds them as a list member with full task visibility (FR16)
**And** if the recipient is not yet subscribed, they are routed through the independent trial onboarding path (FR86)

**Given** a user is a member of a shared list
**When** they view their Lists tab
**Then** the shared list appears with a shared indicator and member avatars

---

### Story 5.2: Task Assignment Strategies

As a list owner,
I want to configure how tasks are distributed among members,
So that work is balanced fairly without manual assignment overhead.

**Acceptance Criteria:**

**Given** a list owner opens List Settings
**When** they choose an assignment strategy
**Then** available options are: round-robin, least-busy, and AI-assisted balancing (FR17)
**And** round-robin assigns tasks in rotation across active members in join order
**And** least-busy assigns to the member with the fewest scheduled tasks in the current due-date window
**And** AI-assisted balancing considers task duration, member workload, and declared energy preferences

**Given** any assignment strategy is active
**When** a task is assigned
**Then** the same task is never assigned to more than one member within the same due-date window (FR18)

---

### Story 5.3: Shared Tasks in Personal Schedule

As a list member,
I want tasks assigned to me in a shared list to appear in my personal schedule,
So that I don't have to track work in two separate places.

**Acceptance Criteria:**

**Given** a task in a shared list is assigned to a member
**When** the assignment is made
**Then** the task automatically appears in that member's personal task list under the shared list (FR19)
**And** the scheduling engine includes it in their personal schedule recalculation

**Given** an assigned task is scheduled for a member
**When** the member views the Now tab card for that task
**Then** the card shows attribution: "from [List Name] · assigned by [Name]"

**Given** a task is unassigned or reassigned
**When** the change is applied
**Then** the task is removed from the previous assignee's personal schedule within 60 seconds

---

### Story 5.4: Accountability Settings Cascade

As a list owner,
I want to set proof requirements at list or section level,
So that every task in a section automatically has the right accountability without per-task configuration.

**Acceptance Criteria:**

**Given** a list owner opens a list or section's settings
**When** they set a proof requirement
**Then** all tasks within that list or section inherit the requirement: none, photo proof, Watch Mode, or HealthKit (FR20)
**And** the inherited requirement is shown as a label on affected tasks

**Given** a task inherits an accountability setting
**When** the user edits that specific task
**Then** they can override the inherited setting with a per-task value
**And** the override is shown with a distinct "custom" indicator so it is clear the task differs from the section default

---

### Story 5.5: Shared Proof Visibility

As a list member,
I want to view proof submitted by other members for tasks they completed,
So that we can all see the evidence and stay accountable to each other.

**Acceptance Criteria:**

**Given** a member completes a task with retained proof
**When** another member views that task in the shared list
**Then** they can access the submitted proof (photo, video, or document) from the task detail view (FR21)
**And** proof is scoped to members of the shared list only — inaccessible to anyone outside the list (NFR-S4)

**Given** a member submits proof for a shared list task
**When** the proof is retained and verified
**Then** other members receive a notification that the task was completed — notification delivery is implemented in Story 8.4 (not required to pass this story)

---

### Story 5.6: Member Management & Shared Ownership

As a list owner,
I want to remove members, manage shared ownership rights, and allow members to leave,
So that list membership stays accurate and administrative responsibility can be distributed.

**Acceptance Criteria:**

**Given** a list owner opens List Settings → Members
**When** they remove a member
**Then** the removed member loses access immediately and the list disappears from their Lists tab (FR62)
**And** the removed member's incomplete assigned tasks are unassigned

**Given** a list member opens List Settings
**When** they choose "Leave list"
**Then** they are removed from the list and their assigned tasks are unassigned
**And** they cannot rejoin without a new invitation

**Given** a list has an owner
**When** they grant owner rights to another member
**Then** that member gains full administrative rights: invite, remove, configure strategy, delete list (FR75)
**And** multiple owners can coexist; ownership is not exclusive

---

## Epic 6: Commitment Contracts & Payments

**Goal**: Implement the full commitment contract mechanic — stake setting, payment method storage via web flow, automated charges, charity disbursement, group commitments, and the impact dashboard.

---

### Story 6.1: Payment Method Setup

As a user,
I want to set up a payment method through a secure web flow,
So that On Task can charge me if I miss a commitment without ever handling my card details.

**Acceptance Criteria:**

**Given** a user initiates the commitment flow for the first time (or has no stored payment method)
**When** they are directed to the payment setup step
**Then** the app opens `ontaskhq.com/setup` via Universal Link using the associated domain `ontaskhq.com` (MKTG-3 is a prerequisite for this story)
**And** the setup page uses Stripe.js with a SetupIntent — raw card data never reaches On Task servers (NFR-S2, PCI SAQ A)
**And** on successful setup, the app receives the Universal Link callback and confirms to the user that a payment method is stored (FR23)

**Given** a payment method is stored
**When** the user opens Settings → Payments
**Then** they can view the stored method (last 4 digits and card type)
**And** they can update it (opens `ontaskhq.com/setup` again) or remove it (FR64)
**And** removing a payment method is blocked if there are active staked tasks

---

### Story 6.2: Stake Setting UI

As a user,
I want to set a financial stake on a task using a tactile slider with zone feedback,
So that I can calibrate exactly how much accountability pressure I need.

**Acceptance Criteria:**

**Given** the user opens a task and taps "Add stake"
**When** the Stake Slider is shown
**Then** the slider is built on a CupertinoSlider base with a custom track painter showing three colour zones: green (low), yellow (moderate), red (high) (UX-DR7)
**And** haptic feedback pulses when the thumb crosses a zone threshold
**And** the lock icon on the slider closes more firmly (visual tightening animation) at higher values

**Given** the slider is in the red zone
**When** the calibration guidance is shown
**Then** inline text reads: "This amount will cause real financial pain if missed. That's the point — but only if you're sure."

**Given** the user prefers an exact amount
**When** they tap the displayed amount
**Then** they can type an exact value directly instead of using the slider

**Given** no payment method is stored
**When** the user tries to set a stake
**Then** they are prompted to set up a payment method first (Story 6.1)

---

### Story 6.3: Charity Selection

As a user,
I want to choose where my missed stakes go from a catalog of nonprofits,
So that the consequence of missing a commitment supports a cause I actually care about.

**Acceptance Criteria:**

**Given** the commitment flow reaches the charity selection step
**When** the catalog is shown
**Then** a searchable list of nonprofits is presented sourced from the Every.org API (FR26)
**And** nonprofits can be browsed by category and searched by name

**Given** the user selects a charity
**When** they confirm
**Then** the selection is persisted as their default charity for future stakes

**Given** the user has a default charity set
**When** they open a new commitment flow
**Then** their default charity is pre-selected, and they can change it

---

### Story 6.4: Impact Dashboard

As a user,
I want to see a visual record of what my kept (and missed) commitments have produced,
So that I have tangible evidence of growth rather than just a list of tasks completed.

**Acceptance Criteria:**

**Given** the user has had at least one staked task resolve (charged or verified complete)
**When** they open the Impact Dashboard
**Then** milestone cells are shown using the "evidence of who you've become" framing — not a raw stats list (FR27, UX-DR19)
**And** cells represent meaningful milestones: first donation, first commitment kept, $100 total donated, streak of kept commitments
**And** total amount donated and charity breakdown are accessible as secondary information

**Given** a milestone cell is tapped
**When** the detail expands
**Then** a natural sharing moment is presented: the user can share the milestone via native share sheet
**And** copy is affirming for both kept and missed commitments — no punitive language (UX-DR36)

---

### Story 6.5: Automated Charge Processing & Charity Disbursement

As a user who missed a commitment,
I want the charge and disbursement to happen automatically and reliably,
So that the accountability mechanism is credible and I can trust that the consequence is real.

**Acceptance Criteria:**

**Given** a staked task's deadline passes without verified completion
**When** the charge is initiated
**Then** a Stripe off-session charge is processed with an idempotency key — exactly-once semantics enforced (FR24, ARCH-24, NFR-R1)
**And** transient Stripe failures are retried with exponential backoff before marking the charge as failed

**Given** a charge succeeds
**When** the funds are split
**Then** 50% is disbursed to the user's chosen charity via Every.org within 1 hour (FR25, NFR-I5)
**And** 50% is retained by On Task
**And** Every.org disbursement failures are queued and retried — funds are never lost in transit (NFR-R4)

**Given** a Stripe webhook is received
**When** processing occurs
**Then** the webhook is processed within 30 seconds of receipt (NFR-I4)
**And** duplicate webhook delivery does not result in duplicate charges (NFR-R2)

**Given** a commitment contract timestamp is evaluated
**When** checking for clock skew
**Then** timestamps up to 30 days in the past are accepted; beyond 30 days are rejected (ARCH-29)
**And** three boundary tests are enforced in the test suite: accept exactly 30 days, reject 30 days + 1 second, accept current timestamp

---

### Story 6.6: Stake Modification & Cancellation

As a user,
I want to be able to cancel or reduce my stake before the deadline window closes,
So that I have a safety valve for genuine changes in circumstance — not procrastination.

**Acceptance Criteria:**

**Given** a task has an active stake
**When** the user views the task
**Then** the modification window deadline is displayed: "You can adjust or cancel this stake until [datetime]"

**Given** the modification window is open
**When** the user cancels or reduces the stake
**Then** the financial commitment is removed or reduced and no charge will occur for the cancelled amount (FR63)
**And** the task remains in the task list as a normal (unstaked) task

**Given** the modification window has closed (within the pre-deadline period)
**When** the user tries to modify the stake
**Then** the modification controls are disabled and a clear message explains why: "This stake is locked — the deadline is too close to change it"

---

### Story 6.7: Group Commitment Arrangements & Pool Mode

As a group member,
I want to enter a shared commitment where everyone has skin in the game,
So that we're all accountable to each other — not just ourselves.

**Acceptance Criteria:**

**Given** a shared list is active
**When** a member proposes a group commitment
**Then** each member can set their individual stake amount (FR29)
**And** all members can review the proposed stakes before activating
**And** the group commitment activates only when all members have explicitly approved (unanimous approval required)

**Given** a group commitment is being set up
**When** pool mode is offered
**Then** each member must explicitly opt into pool mode — it is not inherited from group commitment approval (FR30)
**And** members who opt in understand: any member failing their assigned task results in charges for all members per their individual stakes

**Given** a pool mode charge is triggered
**When** the charge is processed
**Then** all opted-in members are charged their individual pool stake using the same idempotency and retry mechanics as individual charges (Story 6.5)
**And** each charge is a separate Stripe operation with its own idempotency key

---

### Story 6.8: Full Commitment Lock Flow & Animation

As a user,
I want the commitment lock experience to feel ceremonial and irreversible,
So that I take the commitment seriously and feel the weight of the decision.

**Acceptance Criteria:**

**Given** the user has set a stake amount and selected a charity
**When** they reach the lock confirmation step
**Then** a full-screen Commitment Ceremony Card is shown with: task title, stake amount, charity name, and deadline displayed prominently (UX-DR8)
**And** copy uses the "past self / future self" framing: "Your future self is counting on you" (UX-DR32)
**And** "The vault close" motion token plays on confirmation — a satisfying vault-door-closing micro-animation (UX-DR20)
**And** "The vault close" degrades to an instant state change when "Reduce Motion" is enabled

**Given** a group commitment is being locked
**When** the full flow runs
**Then** the sequence is: Stake Slider → Charity Selection → Deadline Confirmation → Group Approval (unanimous) → Pool Mode opt-in → Lock Confirmation (UX-DR34)
**And** the flow cannot be skipped or reordered

**Given** the commitment is locked
**When** the user returns to the task
**Then** the Now Tab Task Card switches to the "committed" display variant showing stake amount and proof mode

---

### Story 6.9: Billing History & API Contract Status

As a user and API consumer,
I want to view my charge history in the app and read contract status from the API,
So that I have full visibility into my financial activity with On Task.

**Acceptance Criteria:**

**Given** the user opens Settings → Payments → Billing History
**When** the history loads
**Then** each entry shows: date, task name, amount charged, disbursement status (pending/completed/failed), and charity (FR65)
**And** cancelled stakes are listed separately as "cancelled — no charge"

**Given** an authenticated API consumer makes a request
**When** they call `GET /v1/contracts/:id/status`
**Then** the response includes: status (active / charged / cancelled / disputed), stake amount, and charge timestamp if charged (FR71)
**And** the endpoint is scoped to the authenticated user's contracts only — no cross-user access

---

## Epic 7: Proof & Verification

**Goal**: Implement all proof submission modes (photo/video, Watch Mode, HealthKit, screenshot/document, offline queued), AI verification, dispute flow, and operator resolution.

---

### Story 7.1: Proof Capture Modal Foundation

As a user,
I want a single, consistent entry point for submitting proof regardless of proof type,
So that verification feels streamlined rather than scattered across different flows.

**Acceptance Criteria:**

**Given** a user completes a task that requires proof or chooses to verify
**When** the Proof Capture Modal opens
**Then** the modal is a bottom sheet showing four proof path options: Photo/Video, HealthKit Auto, Screenshot/Document, Offline (offline option shown only when the device is offline) (UX-DR11)
**And** the user can navigate between proof paths and back out to the path selector
**And** dismissing the modal without submitting leaves the task in "pending completion" state — no proof is lost

**Given** the modal is rendered on macOS
**When** the proof paths are displayed
**Then** the HealthKit option is hidden with no broken affordances
**And** Watch Mode is not referenced in any macOS modal copy

---

### Story 7.2: Photo & Video Proof with AI Verification

As a user,
I want to capture proof with my camera and receive an AI verification result quickly,
So that completing committed tasks is frictionless and the verification feels instant.

**Acceptance Criteria:**

**Given** the user selects Photo/Video in the Proof Capture Modal
**When** they capture a photo or video
**Then** capture uses the in-app camera (no gallery import permitted) (FR31)
**And** the captured media is submitted to the API for AI verification against the task description

**Given** verification is in progress
**When** the modal is showing
**Then** a pulsing arc animation plays around the captured media preview: accent colour stroke, 1.5s loop (UX-DR30)
**And** copy reads "Reviewing your proof…"

**Given** verification completes successfully
**When** the result is returned
**Then** the task is marked complete and any pending charge is cancelled if the task was staked

**Given** verification fails
**When** the result is returned
**Then** the user receives a plain-language explanation of why verification failed
**And** they are offered: retry with a new capture, or submit for human review

**Given** verification takes longer than 10 seconds
**When** the timeout is reached
**Then** an error state is shown with a "Try again" CTA (UX-DR30)

---

### Story 7.3: Screenshot & Document Proof

As a user,
I want to submit a screenshot or document as proof for tasks with digital outputs,
So that completing tasks like "send the report" or "finish the design" can be verified.

**Acceptance Criteria:**

**Given** the user selects Screenshot/Document in the Proof Capture Modal
**When** they upload a file
**Then** supported formats are PNG, JPG, and PDF with a maximum size of 25MB (FR36)
**And** the file is stored in private Backblaze B2 storage scoped to the task owner (NFR-S4)

**Given** the file is submitted
**When** AI verification runs
**Then** the same verification pipeline and animation as Story 7.2 is used
**And** the user is shown the verification result with the same pass/fail/timeout flows

---

### Story 7.4: Watch Mode Session

As a user,
I want a passive camera-based focus mode that monitors whether I'm working,
So that I have an accountability presence during deep work without needing to remember to submit proof.

**Acceptance Criteria:**

**Given** the user activates Watch Mode from the Now tab card or task detail
**When** Watch Mode starts
**Then** Watch Mode is available for any task, staked or not (FR34)
**And** the Watch Mode Overlay is shown: minimal UI with camera indicator, task name, elapsed timer, End Session button (UX-DR10)

**Given** Watch Mode is active
**When** the polling interval fires
**Then** the camera captures a frame every 30–60 seconds (ARCH-32)
**And** each frame is processed in-flight by the AI model and immediately discarded — no frame is stored at any point (NFR-S3)

**Given** Watch Mode is running
**When** the user taps "End Session" or the configured auto-stop condition is met
**Then** Watch Mode ends and a session summary is shown: duration and detected activity percentage (FR66, FR67)
**And** if the session was for a staked task, the activity data is submitted as verification evidence

**Given** the app is running on macOS
**When** the user would otherwise see a Watch Mode option
**Then** Watch Mode is completely absent — no button shown, no affordance, no placeholder (UX-DR10)

---

### Story 7.5: HealthKit Auto-Verification

As a user,
I want tasks like workouts or meditation to be verified automatically from Apple Health,
So that I don't have to do anything after completing the activity — it just gets marked done.

**Acceptance Criteria:**

**Given** a task is tagged with a HealthKit-verifiable activity type
**When** the task deadline passes
**Then** the system reads HealthKit for relevant data in the 30-minute buffer window (FR35, FR47, NFR-I3)
**And** the Now tab shows a "Verifying" badge on the task during the buffer window (UX-DR31)

**Given** HealthKit data confirming the activity arrives within 30 minutes of the deadline
**When** the data is received
**Then** the task is automatically verified complete and any pending charge is cancelled

**Given** HealthKit data has not arrived within 30 minutes of the deadline
**When** the buffer expires
**Then** the badge changes to "Verify manually" with two CTAs: file a dispute or submit photo proof as fallback (UX-DR31)

**Given** HealthKit data arrives after the buffer window has expired and a charge has already been processed
**When** the late data is received
**Then** the charge is flagged for operator review rather than automatically reversed (NFR-I3 — delayed data does not result in silent incorrect charges)

**Given** HealthKit tasks are enabled
**When** the task is first created with a HealthKit activity type
**Then** HealthKit read permission is requested for that specific data type — permission is not requested globally on app launch

---

### Story 7.6: Offline Proof Queue

As a user,
I want to submit proof while offline and have it sync automatically when I reconnect,
So that I'm not charged just because I was somewhere without signal when I finished a task.

**Acceptance Criteria:**

**Given** the user submits proof while offline
**When** the proof is captured
**Then** it is queued in the local `pending_operations` drift table with `clientTimestamp` set at the moment of capture — not at sync time (FR37, ARCH-26)
**And** the app shows visible confirmation: "Proof saved — will sync when you're back online" (NFR-UX1)

**Given** the device reconnects to the network
**When** the offline queue is processed
**Then** queued proof is submitted with its original `clientTimestamp`
**And** if the `clientTimestamp` predates the task deadline, any pending charge is reversed

**Given** a sync attempt fails
**When** retries are exhausted
**Then** the operation is retried up to 3 times with exponential backoff (ARCH-26)
**And** after 3 failures, status is set to `failed` and the user is notified — the proof is never silently dropped (NFR-R5)

---

### Story 7.7: Proof Retention Settings

As a user,
I want control over whether my submitted proof is kept as a permanent record,
So that I can keep meaningful evidence without accumulating storage I don't want.

**Acceptance Criteria:**

**Given** the user is submitting proof
**When** the proof is being confirmed
**Then** they are offered: "Keep as completion record" or "Submit and discard" (FR38)
**And** the default can be changed globally in Settings → Privacy

**Given** the user chooses to retain proof
**When** verification succeeds
**Then** the proof is stored in private Backblaze B2 scoped to the task owner
**And** retained proof persists until the parent task is permanently deleted (NFR-R8)
**And** retained proof is accessible from task history and shared list proof view (FR21)

**Given** the user chooses to discard proof
**When** verification succeeds
**Then** the media is deleted from storage within 24 hours of successful processing

---

### Story 7.8: AI Verification Dispute Filing

As a user,
I want to challenge an AI verification result I believe was wrong,
So that I'm not charged for something I actually did just because the AI disagreed.

**Acceptance Criteria:**

**Given** an AI verification has returned a failed result
**When** the user chooses "Dispute this result"
**Then** a dispute is filed without requiring additional proof — it is a no-proof-required review request (FR39)
**And** the stake charge is placed on hold immediately — no charge is processed while the dispute is under review

**Given** the dispute is filed
**When** the confirmation screen is shown
**Then** it communicates all three trust-critical points: (1) dispute received and under review, (2) stake will not be charged during review, (3) operator responds within 24 hours (UX-DR33)
**And** the task shows status "Under review" in the task card

---

### Story 7.9: Human Dispute Review & Operator Resolution

As an operator,
I want to review disputed AI verification decisions and issue final rulings,
So that users have a fair appeal path and charges are only processed when warranted.

**Acceptance Criteria:**

**Given** a dispute has been filed
**When** it appears in the operator queue (Story 11.2)
**Then** the operator can view: task title, submitted proof media, the AI verification result and its reasoning, and user account context
**And** the dispute SLA countdown is visible: amber at 18 hours, red at 22 hours, showing time remaining (NFR-R3)

**Given** the operator reviews the dispute
**When** they make a decision
**Then** they can approve (verify complete → cancel charge) or reject (confirm charge → trigger Stripe processing)
**And** a decision note (internal) is required before approving or rejecting

**Given** the operator decision is recorded
**When** the resolution is applied
**Then** the user receives a push notification with the outcome (Story 8.3)
**And** the charge hold is released: cancelled if approved, processed if rejected
**And** the resolution timestamp and operator identity are recorded in the task audit trail (FR41)

---

## Epic 8: Notifications & Alerts

**Goal**: Deliver contextual, configurable push notifications and in-app alerts across all key lifecycle events via APNs direct (no Firebase).

---

### Story 8.1: APNs Infrastructure & Device Token Management

As a developer,
I want a direct APNs integration using a Cloudflare Worker with no Firebase dependency,
So that push notifications are delivered with full control over APNs headers and payload structure.

**Acceptance Criteria:**

**Given** the API worker is configured
**When** APNs is set up
**Then** `@fivesheepco/cloudflare-apns2` is used for APNs delivery — no Firebase SDK (ARCH-27)
**And** the APNs p8 key is stored as `wrangler secret put APNS_KEY` — not committed to the repo
**And** APNs integration is tested against staging only (local `wrangler dev` does not support HTTP/2 outbound)

**Given** the app launches on iOS
**When** push permission is granted by the user
**Then** the device push token is registered and stored in a `device_tokens` table (columns: `userId`, `token`, `platform`, `environment`, `createdAt`)
**And** `apns-environment: development` is used for debug builds; `apns-environment: production` is used for TestFlight and App Store builds (DEPLOY-4)

**Given** a notification preference exists
**When** the user configures preferences
**Then** preferences can be set at three levels: globally (all notifications on/off), per device (this iPhone vs. this Mac), and per task (remind me / don't remind me) (FR43)

---

### Story 8.2: Task Reminder & Deadline Notifications

As a user,
I want timely reminders for my tasks and warnings when deadlines are approaching,
So that nothing sneaks up on me and I always have time to act.

**Acceptance Criteria:**

**Given** a task has a scheduled time
**When** the reminder window arrives
**Then** a push notification is sent: "[Task title] is coming up at [time]" (FR42)
**And** the reminder fires at user-configured lead time (default: 15 minutes before)

**Given** a task has a due date
**When** the due date is within the approaching-deadline window
**Then** a push notification is sent: "[Task title] is due [today/tomorrow]" (FR42)

**Given** a task has an active stake and the deadline is approaching
**When** the pre-deadline warning window arrives
**Then** a distinct, higher-priority push notification is sent: "⚠ [Task title] — $[amount] staked, deadline in [X hours]. [Charity] gets half if it's not done." (FR72)
**And** the pre-deadline warning window is configurable (default: 2 hours before deadline)
**And** copy follows the warm tone — not punitive — but with appropriate urgency (UX-DR32)

---

### Story 8.3: Commitment, Charge & Verification Notifications

As a user,
I want to be notified immediately when charges, verifications, and disputes change status,
So that I always know the financial state of my commitments without having to check.

**Acceptance Criteria:**

**Given** a charge is successfully processed
**When** the Stripe webhook is received and processed
**Then** the user receives a push notification: "[Task title] — $[amount] charged. [Charity] receives $[amount/2]. Thanks for trying." (FR42)
**And** copy is affirming even for a charge — no punitive language (UX-DR36)

**Given** a verification completes successfully (stake cancelled)
**When** the verification result is processed
**Then** the user receives a push notification: "[Task title] — proof accepted. Your $[amount] stake is safe." (FR42)

**Given** a dispute is filed
**When** the filing is confirmed server-side
**Then** the user receives a notification confirming the dispute and that the stake is on hold

**Given** a dispute is resolved by an operator
**When** the resolution is recorded
**Then** the user receives a notification with the outcome: approved (stake cancelled) or rejected (charge processed) (FR42, Story 7.9)

---

### Story 8.4: Social & Schedule Change Notifications

As a user,
I want to know when someone I share a list with completes their tasks and when my schedule changes,
So that I can stay in sync with my household and adapt to changes in my day.

**Acceptance Criteria:**

**Given** a member of a shared list completes a task with retained proof
**When** the completion is recorded
**Then** other list members receive a notification: "[Name] completed [task title]" (FR42)
**And** social notifications can be disabled per task in task settings (FR43)

**Given** the scheduling engine regenerates due to a calendar change or task slip
**When** the recalculation results in meaningful changes (≥ 2 tasks moved)
**Then** a push notification is sent if the app is in the background: "Your schedule was updated — [X] tasks were rescheduled" (FR42)
**And** the notification deep-links to the Today tab with the Schedule Change Banner shown (Story 2.12)

---

### Story 8.5: In-App Notification Centre & VoiceOver Live Activity Announcements

As a user,
I want an in-app notification centre and VoiceOver announcements for Live Activity state changes,
So that I can review past alerts and assistive technology users stay informed without visual checks.

**Acceptance Criteria:**

**Given** the user opens the notification centre
**When** it loads
**Then** recent notifications are shown in reverse chronological order with timestamp and type icon
**And** unread notifications are indicated with a badge count in the toolbar icon

**Given** a Live Activity changes state (task started, 30-min timer milestone, deadline approaching)
**When** the state change occurs in the native Swift extension
**Then** `UIAccessibility.post(notification: .announcement, argument:)` is called from the Swift extension code — not from Flutter (UX-DR24)
**And** announcement text is plain language: "Timer started for [task title]", "[Task title] — 30 minutes elapsed", "[Task title] deadline in 15 minutes"

---

## Epic 9: Subscriptions & Billing

**Goal**: Implement the full subscription lifecycle — 14-day free trial, tier selection, paywall, upgrades/downgrades, cancellation grace periods, and invited-user onboarding paths.

---

### Story 9.1: Free Trial Launch & Status Visibility

As a new user,
I want a 14-day full-access free trial with clear visibility into how much time I have left,
So that I can experience the full product before being asked to pay.

**Acceptance Criteria:**

**Given** a new user completes authentication for the first time
**When** their account is created
**Then** a 14-day free trial period begins immediately (FR82)
**And** the trial start timestamp is recorded server-side

**Given** the user opens Settings → Subscription
**When** the subscription status is shown
**Then** remaining trial days are displayed: "X days remaining in your free trial" (FR87)
**And** in the final 3 days, a persistent trial countdown banner appears in the app

**Given** the trial expires
**When** no subscription has been activated
**Then** user data is retained server-side for 30 days before permanent deletion (FR85, NFR-R7)
**And** re-authenticating within 30 days restores full access to their data

---

### Story 9.2: Paywall Screen

As a user reaching trial expiry,
I want a clear paywall that makes subscribing easy,
So that the path to continuing feels like an obvious next step, not a wall.

**Acceptance Criteria:**

**Given** a user's trial has expired
**When** they launch the app
**Then** the Paywall Screen is the first thing shown — not a modal over app content (FR88)
**And** the paywall shows the three subscription tiers with pricing and a brief feature comparison
**And** a "Restore purchase" option is available for users who have previously subscribed

**Given** the paywall is shown
**When** a user who has no payment history views it
**Then** copy is inviting and benefit-focused — no dark patterns, no artificial urgency language
**And** cancellation terms are clearly displayed alongside the subscribe CTA

---

### Story 9.3: Tier Selection & Subscription Activation

As a user,
I want to choose a subscription tier and have my access restored immediately,
So that there's no delay between paying and using the full app.

**Note**: Subscriptions are processed via Stripe Checkout on `ontaskhq.com/subscribe` (not Apple IAP). This mirrors the commitment contract payment setup pattern (Story 6.1) and is permitted under the Epic Games v. Apple ruling which allows apps to link out to external subscription purchase flows. No Apple IAP is used anywhere in On Task.

**Acceptance Criteria:**

**Given** the user selects a tier on the Paywall Screen or in Settings
**When** they tap "Subscribe"
**Then** the app opens `ontaskhq.com/subscribe?tier=[tier]` via Universal Link (same associated domain as MKTG-3) (FR83)
**And** the subscribe page uses Stripe Checkout with the selected tier pre-populated
**And** on successful payment, the page returns the user to the app via Universal Link

**Given** the Universal Link callback is received with a successful subscription confirmation
**When** the server confirms the Stripe subscription is active
**Then** the subscription is activated immediately and trial status is replaced with subscription status
**And** all app access is restored without requiring a restart

**Given** a subscription is activated
**When** the tier is confirmed
**Then** the subscription tier, start date, and renewal date are stored server-side and visible in Settings → Subscription

**Given** the Individual tier is selected
**When** pricing is displayed
**Then** the price shown is ~$10/mo (Couple and Family & Friends at proportionally higher prices per the product brief)

---

### Story 9.4: Subscription Management — Upgrade, Downgrade & Cancellation

As a user,
I want to change my subscription tier or cancel without friction,
So that I stay in control of what I'm paying for.

**Acceptance Criteria:**

**Given** the user opens Settings → Subscription
**When** they choose to change tier
**Then** upgrade takes effect immediately with prorated billing (FR84)
**And** downgrade takes effect at the start of the next billing cycle

**Given** the user cancels their subscription (FR49, FR89)
**When** cancellation is confirmed
**Then** the subscription remains active until the end of the current paid period — access is not removed early
**And** active commitment contracts continue to their individual deadlines regardless of cancellation status (FR89)
**And** the remaining access period is displayed clearly: "Your subscription is active until [date]"

---

### Story 9.5: Payment Failure Grace Period

As a user whose renewal payment has failed,
I want a grace period to fix my payment method before losing access,
So that a temporary card issue doesn't erase my work.

**Acceptance Criteria:**

**Given** a subscription renewal payment fails
**When** the Stripe webhook for payment failure is received
**Then** a push notification and in-app banner are shown: "Your payment didn't go through — update your payment method to keep access" (FR90)
**And** a 7-day grace period begins — access is not restricted immediately

**Given** the grace period is active
**When** the user updates their payment method
**Then** the pending renewal is retried immediately
**And** if payment succeeds, the grace period ends and no access interruption occurs

**Given** 7 days pass without a successful payment
**When** the grace period expires
**Then** access is restricted to Settings only (same state as trial expiry)
**And** the user can reactivate at any time by updating their payment method and completing payment

---

### Story 9.6: Invited User Onboarding Path

As a user who was invited to a shared list before subscribing,
I want my own independent trial so I can use the product fully before committing to a subscription,
So that being invited by a friend doesn't immediately gate me behind a paywall.

**Acceptance Criteria:**

**Given** a user receives a shared list invitation and has no On Task account
**When** they click the invitation link and complete sign-up
**Then** they receive a 14-day free trial starting from the moment of sign-up (FR86)
**And** the trial is independent of the inviting user's subscription

**Given** the invited user completes authentication
**When** onboarding begins
**Then** the shared list context is shown: "You've been invited to [List Name] by [Name]"
**And** the list is accessible immediately after accepting the invitation — no delay

---

## Epic 10: REST API & MCP Server

**Goal**: Build the versioned public REST API and OAuth-secured MCP server, enabling external system integrations and AI assistant access with full task and scheduling feature parity.

---

### Story 10.1: REST API — Tasks & Lists

As an external developer,
I want to create, read, update, and delete tasks and lists via a typed REST API,
So that I can integrate On Task into my own tools and workflows.

**Acceptance Criteria:**

**Given** the REST API is implemented
**When** a developer makes task or list requests
**Then** the following endpoints are available with full `@hono/zod-openapi` schemas: `GET /v1/tasks`, `POST /v1/tasks`, `GET /v1/tasks/:id`, `PATCH /v1/tasks/:id`, `DELETE /v1/tasks/:id`, `GET /v1/lists`, `POST /v1/lists`, `GET /v1/lists/:id`, `PATCH /v1/lists/:id`, `DELETE /v1/lists/:id` (FR44)
**And** all endpoints respond within 500ms at p95 under normal load (NFR-P6)
**And** the OpenAPI spec is auto-generated and served at `GET /v1/openapi.json`

**Given** a list endpoint is called
**When** it returns multiple items
**Then** pagination uses cursor-based format only — no offset/limit (ARCH-14)
**And** rate limit headers are included on every response: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` (FR80, NFR-I6)

---

### Story 10.2: REST API — Scheduling Operations & Rate Limit Enforcement

As an external developer,
I want to trigger scheduling and check rate limit status from the API,
So that I can build integrations that respect the system's capacity and scheduling intelligence.

**Acceptance Criteria:**

**Given** a developer calls the scheduling endpoint
**When** they submit scheduling parameters
**Then** `POST /v1/tasks/:id/schedule` triggers the scheduling engine and returns the resulting scheduled time (FR44)
**And** `GET /v1/tasks/:id/schedule` returns the current scheduled time and scheduling explanation

**Given** the rate limit is exceeded
**When** a request is made
**Then** the response is `429 Too Many Requests` with `{ "error": { "code": "RATE_LIMIT_EXCEEDED", "message": "...", "details": { "retryAfter": 60 } } }`
**And** rate limits are per authenticated user, not per IP
**And** rate limit configuration is documented in the OpenAPI spec: limit per window, window duration, and reset behaviour (NFR-I6)

---

### Story 10.3: MCP Server — Core Task Operations

As an AI assistant,
I want to create, list, update, schedule, and complete tasks via an MCP tool interface,
So that users can manage On Task hands-free through their favourite AI assistant.

**Acceptance Criteria:**

**Given** the MCP server is running
**When** an AI assistant connects
**Then** the following tools are exposed: `create_task`, `list_tasks`, `update_task`, `schedule_task`, `complete_task` (FR45)
**And** `create_task` accepts both structured properties and a natural language input field (parsed via LLM before creating)
**And** MCP server endpoints respond within 1 second at p95 (NFR-P7)

**Given** an MCP tool is invoked
**When** the response is returned
**Then** it follows the MCP specification structured result format
**And** all tools and their parameters are declared in the MCP tool manifest for discovery by AI clients

---

### Story 10.4: MCP Server — OAuth Authentication & Token Scoping

As a developer building an MCP integration,
I want OAuth-secured per-client scoped tokens with revocation support,
So that MCP clients have only the access they need and users can revoke access at any time.

**Acceptance Criteria:**

**Given** an MCP client is registered
**When** a user authenticates the client
**Then** OAuth 2.0 is implemented per the MCP specification (FR93)
**And** the client receives a scoped token declaring its permissions (e.g., `tasks:read`, `tasks:write`, `contracts:read`)
**And** token scope is enforced server-side — requests exceeding scope return 403

**Given** a token is issued
**When** the user opens Settings → Connected Apps
**Then** they can see all active MCP client tokens with: client name, granted scopes, last-used timestamp
**And** they can revoke any token, immediately invalidating it

**Given** a revoked token is used
**When** the API receives the request
**Then** the response is 401 with `{ "error": { "code": "TOKEN_REVOKED", ... } }`

---

### Story 10.5: MCP Server — Commitment Contract Tools

As an AI assistant,
I want to create commitment contracts on behalf of users via MCP,
So that users can set up financial accountability through their AI assistant without opening the app.

**Acceptance Criteria:**

**Given** the MCP server includes contract tools
**When** an AI assistant invokes them
**Then** `create_contract` accepts: task ID, stake amount, charity ID, deadline; creates a commitment contract pending payment method confirmation
**And** `get_contract_status` returns the contract status, stake amount, and charge timestamp if charged (FR45, FR71)
**And** contract creation requires `contracts:write` scope on the MCP token

**Given** the user has no stored payment method
**When** `create_contract` is invoked
**Then** the tool returns a structured error with a `setupUrl` field pointing to `ontaskhq.com/setup` for the user to complete payment setup
**And** the contract is not created until payment method setup is confirmed

---

## Epic 11: Operator Dashboard

**Goal**: Build internal operator tooling for dispute resolution, charge reversal, user impersonation (with immutable audit log), and business event monitoring.

---

### Story 11.1: Operator Authentication & Dashboard Shell

As an On Task operator,
I want a secure internal dashboard with 2FA-enforced login,
So that only authorized staff can access sensitive user and financial data.

**Acceptance Criteria:**

**Given** the operator dashboard is deployed
**When** an operator navigates to the admin URL
**Then** the dashboard is available at `admin.staging.ontaskhq.com` and `admin.ontaskhq.com`
**And** all operator API routes are under `/admin/v1/*` with CORS scoped accordingly (ARCH-15)
**And** operator accounts are created manually — no self-service registration

**Given** an operator attempts to log in
**When** authentication is performed
**Then** email and password are required, followed by mandatory TOTP 2FA
**And** login without a valid TOTP code fails regardless of password correctness

**Given** the operator is authenticated
**When** the dashboard loads
**Then** the sidebar shows navigation sections: Disputes, Users, Billing, Monitoring
**And** the current operator's identity is shown in the header at all times

---

### Story 11.2: Dispute Review & Resolution

As an operator,
I want to review disputed AI verification decisions and issue rulings within the SLA,
So that users have a fair appeal path and charges are processed or cancelled correctly.

**Acceptance Criteria:**

**Given** the operator opens the Disputes section
**When** the queue loads
**Then** disputes are shown in FIFO order with: task title, user email, time-since-filed, and an SLA countdown indicator
**And** disputes approaching 24 hours are shown in amber; disputes that have exceeded 24 hours are shown in red (NFR-R3)

**Given** an operator opens a dispute
**When** the detail view loads
**Then** they can see: task title, submitted proof media (inline preview), AI verification result and reasoning, and the user's account info (FR51)

**Given** the operator makes a decision
**When** they choose to approve or reject
**Then** a decision note (internal, not user-visible) is required before submitting
**And** approving the dispute cancels the stake charge and marks the task as verified complete
**And** rejecting the dispute triggers the Stripe charge processing
**And** the user receives a push notification with the outcome (Story 8.3) (FR41)

---

### Story 11.3: Charge Reversal & Refunds

As an operator,
I want to reverse any charge and issue full or partial refunds,
So that billing errors or exceptional circumstances can be resolved quickly.

**Acceptance Criteria:**

**Given** the operator opens the Users section and searches for a user
**When** they view charge history
**Then** all processed charges are listed with: date, task name, amount, and current refund status (FR52)

**Given** an operator selects a charge to refund
**When** they initiate a refund
**Then** they can issue a full or partial refund
**And** a refund reason (internal) must be entered before the refund is processed
**And** the refund is processed via Stripe API and the user receives a notification

**Given** a refund is processed
**When** the audit trail is updated
**Then** the refund action is logged with: timestamp, operator identity, user account, amount, and reason
**And** this log entry cannot be modified or deleted

---

### Story 11.4: User Impersonation

As an operator,
I want to impersonate user accounts for troubleshooting with a full immutable audit trail,
So that support issues can be investigated without asking the user to walk me through their screen.

**Acceptance Criteria:**

**Given** an operator opens a user account in the Users section
**When** they initiate impersonation
**Then** the app view switches to show the user's account state (FR53)
**And** a persistent banner is shown at the top of every screen: "Viewing as [user@email.com] — [operator@ontaskhq.com]"

**Given** impersonation is active
**When** any action is taken
**Then** every action is logged in an immutable audit trail with: timestamp, operator identity, user account, and action taken (NFR-S6)
**And** the audit trail is append-only — entries cannot be modified or deleted

**Given** an impersonation session is running
**When** 30 minutes have elapsed
**Then** the session automatically ends and the operator is returned to their own account
**And** a "session timeout" entry is appended to the audit log

---

### Story 11.5: Operator Alerts & Business Event Monitoring

As an operator,
I want real-time alerts for payment failures and disputes, and a dashboard of key business metrics,
So that I can respond quickly to issues and track the health of the business.

**Acceptance Criteria:**

**Given** the operator dashboard is open
**When** a triggering event occurs
**Then** in-dashboard alerts fire for: any user's payment failure, any new dispute filed, any dispute approaching its 24-hour SLA (FR54)
**And** the unacknowledged alert count is shown as a badge in the sidebar navigation

**Given** the operator opens the Monitoring section
**When** the dashboard loads
**Then** business metrics are shown as time-series data queryable by date range: daily trial starts, trial-to-subscription conversions, subscription activations, subscription cancellations, total charges fired, total disbursed to charity (NFR-B1)
**And** data is sourced from PostHog events configured in Story 1.12 — no separate analytics store required for v1

---

## Epic 12: iOS Live Activities & Widgets

**Goal**: Implement the native iOS Live Activities extension (Dynamic Island + Lock Screen) and WidgetKit home screen widgets for real-time task status outside the app.

---

### Story 12.1: Live Activity Extension Foundation & Push Token Storage

As an iOS user,
I want an On Task Live Activity I can glance at on my Dynamic Island and Lock Screen,
So that I always know my current task status without unlocking my phone.

**Acceptance Criteria:**

**Given** the Xcode project is configured
**When** the Live Activity extension is added
**Then** `OnTaskLiveActivity` Swift Widget Extension target is added alongside the Flutter app target
**And** `SharedWidgetViews/` folder is created for SwiftUI views shared between the Live Activity and WidgetKit extensions
**And** `live_activities` Flutter plugin is installed; all calls are guarded with `Platform.isIOS` (ARCH-28)

**Given** the ActivityKit integration is set up
**When** a Live Activity starts
**Then** `OnTaskActivityAttributes` ContentState is defined in Swift: `{ taskTitle: String, timerStart: Date, stakeAmount: Double?, deadlineDate: Date?, activityType: String }`
**And** the ActivityKit push token for the activity is stored in the `live_activity_tokens` table: `id`, `userId`, `activityId`, `pushToken`, `activityType`, `createdAt`, `expiresAt`
**And** the `live_activity_tokens` Drizzle Kit migration is committed to `packages/core/schema/migrations/`

---

### Story 12.2: Live Activity — Task Timer & Commitment Countdown

As an iOS user,
I want Live Activities for active tasks and approaching commitment deadlines,
So that I can see my task timer and stake countdown without leaving my current app.

**Acceptance Criteria:**

**Given** the user explicitly starts a task (Story 2.10)
**When** the Live Activity is launched
**Then** `task_timer` activity starts with Dynamic Island compact view: task name + elapsed timer arc; expanded view: full title + elapsed time + Done button + Pause button; Lock Screen: task title + running timer (UX-DR25)

**Given** a staked task deadline is within 2 hours
**When** the Live Activity is launched
**Then** `commitment_countdown` activity starts with Dynamic Island compact: stake amount + countdown arc; expanded: task title + stake amount + deadline countdown + Done/Watch Mode buttons; Lock Screen: deadline countdown (UX-DR25)

**Given** the user taps "Done" in the Live Activity
**When** the action is processed
**Then** the task is marked complete, the charge is cancelled if applicable, and the Live Activity ends

**Given** the Live Activity has been running for 8 hours
**When** the iOS 8-hour limit is reached
**Then** the activity ends automatically (iOS system limit)

---

### Story 12.3: Live Activity — Watch Mode & VoiceOver Announcements

As an iOS user who relies on VoiceOver,
I want Live Activity state changes announced to VoiceOver,
So that I can monitor my task session without looking at my screen.

**Acceptance Criteria:**

**Given** the user starts Watch Mode
**When** the Watch Mode Live Activity launches
**Then** `watch_mode` activity starts with Dynamic Island compact: camera indicator + session timer; expanded: "Watch Mode active" + task name + elapsed time + End Session button; Lock Screen: session status + elapsed time (UX-DR25)

**Given** a Live Activity state changes
**When** VoiceOver is active
**Then** the Swift extension calls `UIAccessibility.post(notification: .announcement, argument:)` for: activity started, 30-minute session milestone, deadline approaching (UX-DR24)
**And** announcements originate from the Swift extension code — never from Flutter

**Given** the user taps "End Session" in the Watch Mode Live Activity
**When** the action is processed
**Then** Watch Mode ends (same as Story 7.4) and the Live Activity is dismissed

---

### Story 12.4: Server-Side Live Activity Push Updates

As an iOS user,
I want my Live Activity to update in real time based on server events,
So that the Dynamic Island reflects what's actually happening — not stale data.

**Acceptance Criteria:**

**Given** the server needs to update a Live Activity
**When** the push is sent
**Then** the API route `POST /internal/live-activities/update` is called (implemented in `apps/api/routes/live-activities.ts`)
**And** the `live-activity.ts` service reads the push token from `live_activity_tokens` and sends via APNs with headers: `apns-push-type: liveactivity`, `apns-topic: com.ontaskhq.ontask.push-type.liveactivity` (ARCH-28)
**And** the push payload contains the updated ContentState

**Given** server-push triggers are implemented
**When** any of the four events occurs
**Then** a push is sent: (1) task nearing deadline (30 min), (2) stake charged, (3) proof submitted, (4) Watch Mode AI detection event

**Given** an APNs delivery failure returns HTTP 410
**When** the response is received
**Then** the expired push token is deleted from `live_activity_tokens` — stale tokens are not retried indefinitely

---

### Story 12.5: WidgetKit Home Screen Widgets

As an iOS user,
I want On Task widgets on my home screen showing my current task and today's plan,
So that I can see what to do next without opening the app.

**Acceptance Criteria:**

**Given** the WidgetKit extension is added to Xcode
**When** the widgets are implemented
**Then** `OnTaskWidget` WidgetKit extension target exists alongside the Live Activity extension
**And** SwiftUI views shared with `SharedWidgetViews/` are used where applicable (UX-DR26)

**Given** the user adds the Now widget (small size)
**When** it renders
**Then** it shows: current task name + elapsed timer if a task is active; or next scheduled task name + scheduled time if no task is active (UX-DR26)

**Given** the user adds the Today widget (medium size)
**When** it renders
**Then** it shows: next 3 scheduled tasks with their times + the Schedule Health Strip for today (green/amber/red) (UX-DR26)
**And** the health strip colour matches the design token colours from the active theme

**Given** a widget is displayed
**When** the timeline refreshes
**Then** data refreshes on a 15-minute WidgetKit timeline or on a task state change push notification
**And** the Push Notifications and Live Activities entitlements are verified in `Runner.entitlements` (DEPLOY-2)

---

## Epic 13: Marketing Site & Public Launch

**Goal**: Deploy the single-page marketing site at ontaskhq.com (including AASA file and payment setup page), configure TestFlight, and prepare all App Store submission requirements.

---

### Story 13.1: AASA File & Payment Setup Page

As the development team,
I want the Universal Links AASA file and Stripe payment setup page live at ontaskhq.com,
So that the commitment contract flow has its required technical infrastructure in place before Epic 6 is tested end-to-end.

**Note**: This story is a hard dependency for Epic 6 (Story 6.1) and Epic 9 (Story 9.3). It should be completed before either epic is tested end-to-end.

**Acceptance Criteria:**

**Given** the Cloudflare Pages deployment is configured
**When** the AASA file is deployed
**Then** `/.well-known/apple-app-site-association` is served at `ontaskhq.com` with `Content-Type: application/json` and no redirects on this URL path (MKTG-3)
**And** the AASA file associates bundle ID `com.ontaskhq.ontask` with `ontaskhq.com`
**And** Universal Links pattern covers `/setup`, `/setup/*`, and `/subscribe`, `/subscribe/*` paths

**Given** the payment setup page is deployed at `ontaskhq.com/setup`
**When** a user lands on the page from the app
**Then** the page shows a Stripe.js SetupIntent form — the Stripe publishable key is used, not the secret key (MKTG-4)
**And** the page serves only over HTTPS
**And** on successful setup, the page redirects back to the app via Universal Link with the `setup_intent_client_secret` in the URL fragment (not query string — fragments are not logged by servers)

**Given** the subscription checkout page is deployed at `ontaskhq.com/subscribe`
**When** a user arrives from the app paywall or settings
**Then** the page accepts a `?tier=individual|couple|family` query parameter and pre-selects the correct Stripe Price ID
**And** the page uses Stripe Checkout (hosted) — not a custom form
**And** on successful subscription creation, Stripe Checkout redirects back to the app via Universal Link with a `session_id` parameter
**And** the server validates the Stripe Checkout session and activates the subscription on callback

---

### Story 13.2: Marketing Site Core Pages

As a prospective user discovering On Task,
I want a fast, clear marketing page that shows me what the app does and links me to the App Store,
So that I can decide whether to download it in under 30 seconds.

**Acceptance Criteria:**

**Given** `ontaskhq.com` is deployed on Cloudflare Pages
**When** a visitor loads the page
**Then** the page is static HTML/CSS with no JavaScript framework (MKTG-1)
**And** the page is mobile-responsive and renders correctly on all viewport sizes from 320px upward

**Given** the page content is published
**When** a visitor reads the page
**Then** the hero section shows tagline "Stop planning. Start doing." and a one-line value proposition (MKTG-2)
**And** three feature highlight sections are present: Intelligent Scheduling, Shared Lists, Commitment Contracts — each with a heading and 2-sentence description
**And** a pricing section shows the three tier cards with ~$10/mo Individual pricing anchor
**And** the primary CTA is "Download on the App Store" linking directly to the App Store listing

**Given** the page is deployed
**When** Core Web Vitals are measured on mobile
**Then** LCP < 2.5s and CLS < 0.1

---

### Story 13.3: Privacy Policy Page

As an App Store reviewer and user,
I want a complete privacy policy that covers all the sensitive data On Task handles,
So that the app passes App Store review and users understand how their data is used.

**Acceptance Criteria:**

**Given** the privacy policy is deployed at `ontaskhq.com/privacy`
**When** a user or reviewer reads it
**Then** the policy explicitly covers: Watch Mode camera data (frames processed in-flight, not stored), proof media retention (retained until task deleted if user opted in), HealthKit data (read only, not shared, retained only for verification), payment data (PCI SAQ A — card data not stored by On Task), and account deletion/data retention (30-day retention before permanent deletion) (MKTG-5)
**And** effective date and last-updated date are displayed at the top
**And** the policy covers all data types declared in the App Store Privacy Nutrition Label

---

### Story 13.4: App Store Connect & Provisioning Configuration

As the development team,
I want App Store Connect records, provisioning profiles, and entitlements correctly configured,
So that the app can be signed, submitted, and tested via TestFlight without provisioning errors.

**Acceptance Criteria:**

**Given** App Store Connect is configured
**When** the records are created
**Then** an iOS App Store Connect app record exists with bundle ID `com.ontaskhq.ontask` (DEPLOY-3)
**And** a macOS Mac App Store record exists with the same bundle ID
**And** a TestFlight internal test group is configured with at least the developer account as a tester

**Given** provisioning profiles are created
**When** they are applied
**Then** iOS and macOS App Store distribution profiles are created and installed locally (DEPLOY-2)
**And** `Runner.entitlements` contains all required entitlements: Push Notifications, Associated Domains (`applinks:ontaskhq.com`), Live Activities, HealthKit, Sign In with Apple
**And** `apns-environment: production` is set in the release/TestFlight configuration; `apns-environment: development` in the debug configuration (DEPLOY-4)

---

### Story 13.5: TestFlight First Build

As the development team,
I want a successful end-to-end TestFlight build delivered to internal testers,
So that we can validate the full app on physical devices before any external testing.

**Acceptance Criteria:**

**Given** the Fastlane `beta` lane from Story 1.2 is configured
**When** the lane is run
**Then** the build number auto-increments, the iOS and macOS targets are built, and the build is uploaded to App Store Connect (DEPLOY-1, ARCH-7)
**And** the build appears in TestFlight and is available to the internal test group

**Given** the TestFlight build is installed on a physical iPhone
**When** key flows are exercised
**Then** the app launches without crashes
**And** push notification delivery is confirmed on the TestFlight build (APNs production environment)
**And** Universal Links from `ontaskhq.com` resolve to the app correctly
**And** HealthKit data access is functional
**And** Sign In with Apple completes successfully on device



