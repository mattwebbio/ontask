---
stepsCompleted: ['step-01-document-discovery', 'step-02-prd-analysis', 'step-03-epic-coverage-validation', 'step-04-ux-alignment', 'step-05-epic-quality-review', 'step-06-final-assessment']
status: complete
project_name: ontask
date: '2026-03-29'
documentsAssessed:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/ux-design-specification.md'
documentsNotFound:
  - epics-and-stories
---

# Implementation Readiness Assessment Report

**Date:** 2026-03-29
**Project:** On Task

---

## Document Inventory

| Document | Path | Status |
|---|---|---|
| PRD | `_bmad-output/planning-artifacts/prd.md` | ✅ Found |
| Architecture | `_bmad-output/planning-artifacts/architecture.md` | ✅ Found |
| UX Design Spec | `_bmad-output/planning-artifacts/ux-design-specification.md` | ✅ Found |
| Epics & Stories | — | ⚠️ Not yet created |

---

## PRD Analysis

### Functional Requirements

**Task & List Management (20 FRs)**

- **FR1:** Users can create tasks by directly entering a title and properties
- **FR1b:** Users can create tasks using natural language input, with the system parsing intent into structured task properties
- **FR2:** Users can organize tasks into lists, with infinitely nested sections and subtasks
- **FR3:** Users can set due dates on individual tasks; sections and lists can define default due dates inherited by tasks without specific dates
- **FR4:** Users can set time-of-day constraints on tasks (hard scheduling pins)
- **FR5:** Users can define energy and context availability preferences that constrain when different types of tasks are scheduled
- **FR6:** Users can view predicted completion dates for tasks, sections, and lists based on current workload
- **FR7:** Users can create one-off tasks and recurring tasks with equal feature parity
- **FR8:** Users can manually override a scheduled time slot for any task
- **FR55:** Users can mark a task complete without submitting proof
- **FR56:** Users can search and filter tasks across lists
- **FR57:** Users can manually reorder tasks within a section
- **FR58:** Users can edit task properties after creation
- **FR59:** Users can archive completed tasks
- **FR68:** Users can set task priority or urgency signals independent of due date
- **FR69:** Users can access a today/focus view showing tasks scheduled for the current day
- **FR73:** Users can define dependencies between tasks so the scheduler respects ordering constraints
- **FR74:** Users can perform bulk operations on multiple tasks (reschedule, complete, assign, delete)
- **FR76:** Users can explicitly begin a task, triggering relevant tracking or notifications
- **FR78:** Users can create, save, and apply list and section templates

**Intelligent Scheduling (7 FRs)**

- **FR9:** The system automatically schedules tasks into available calendar time, respecting due dates, time constraints, energy preferences, and existing events
- **FR10:** The system reads the user's connected calendar to identify available time and avoid conflicts
- **FR11:** The system writes scheduled task blocks to the user's connected calendar
- **FR12:** The system automatically reschedules tasks when calendar events shift or tasks slip past their scheduled time
- **FR13:** Users can view an explanation of why a task was scheduled at a specific time
- **FR14:** Users can adjust scheduled tasks using natural language nudges
- **FR79:** The system maintains a visible, navigable relationship between tasks and their calendar blocks

**Shared Lists & Household Coordination (9 FRs)**

- **FR15:** Users can share any list with named users via invitation
- **FR16:** Invited users can accept list membership and complete onboarding into the shared list
- **FR17:** The system assigns tasks in shared lists using configurable strategies: round-robin, least-busy, or AI-assisted balancing
- **FR18:** The system never assigns the same task to two users within the same due-date window
- **FR19:** Tasks assigned to a user in a shared list are automatically integrated into that user's personal schedule
- **FR20:** Accountability settings can be set at list or section level and cascade to all tasks within, with per-task overrides permitted
- **FR21:** Members of a shared list can view proof media attached to tasks completed by other members
- **FR62:** List owners can remove members from a shared list; members can leave a list
- **FR75:** List ownership can be shared among multiple members, with owners collectively holding administrative rights over the list

**Commitment Contracts (12 FRs)**

- **FR22:** Users can attach a financial stake to any task
- **FR23:** Users can set up a payment method via an external web-based flow
- **FR24:** The system charges the user's stored payment method if a staked task is not verified complete by its deadline
- **FR25:** On an unverified staked task, 50% of the stake is disbursed to the user's chosen charity and 50% is retained by On Task
- **FR26:** Users can select a charity for their stakes from a catalog of nonprofits
- **FR27:** Users can view a lifetime impact dashboard showing total charitable contributions from their stakes
- **FR28:** The system provides in-app guidance to help users calibrate stake amounts appropriately
- **FR29:** Groups can create shared commitment arrangements where each member sets an individual stake, reviewed by all members, activating only upon unanimous approval
- **FR30:** Groups can opt into pool mode, where any member failing their assigned task results in charges for all members per their agreed stakes
- **FR63:** Users can cancel or modify a commitment stake before a defined pre-deadline window
- **FR64:** Users can manage (update or remove) a stored payment method
- **FR65:** Users can view billing history and past charges

**Proof & Verification (13 FRs)**

- **FR31:** Users can submit photo or video proof captured in-app (camera capture only) for AI verification
- **FR32:** The system verifies submitted photo or video proof against the task description using AI
- **FR33:** Users can activate Watch Mode for passive camera-based monitoring during task work
- **FR34:** Watch Mode is available as a standalone focus mode without requiring a financial stake
- **FR35:** Tasks can be auto-verified via Apple HealthKit when connected health data confirms the task
- **FR36:** Users can submit screenshot or document proof for tasks with digital outputs
- **FR37:** Users can submit proof while offline; on reconnection, the system processes the proof and reverses any charges if the proof timestamp predates the deadline
- **FR38:** Users can choose whether submitted proof is retained as a completion record on the task
- **FR39:** Users can dispute an AI verification result via a no-proof-required review request
- **FR40:** Disputed verifications are escalated to human review with a defined resolution SLA
- **FR41:** Operators can approve or reject disputed verifications and trigger charge cancellation or confirmation
- **FR66:** Users can end a Watch Mode session manually or configure auto-stop conditions
- **FR67:** Users can view a Watch Mode session summary after a session ends

**Notifications & Communication (3 FRs)**

- **FR42:** Users receive notifications for task reminders, approaching deadlines, commitment contract charge events, proof verification results, dispute outcomes, partner task completions, and schedule changes
- **FR43:** Users can configure notification preferences at three levels: globally, per device, and per task
- **FR72:** Users receive a distinct pre-deadline warning notification when a staked task deadline is approaching

**Platform Integrations & API (7 FRs)**

- **FR44:** External systems can create, read, update, and schedule tasks via a versioned REST API with OpenAPI documentation
- **FR45:** AI assistants can create tasks, schedule them, and create commitment contracts via an MCP server with feature parity to the in-app experience
- **FR46:** The system performs bidirectional sync with Google Calendar
- **FR47:** The system reads Apple HealthKit data to auto-verify eligible tasks
- **FR71:** External systems can read commitment contract status via API
- **FR80:** API consumers can view rate limit status and current usage in API responses
- **FR93:** MCP server access requires OAuth authentication per the MCP specification, with per-client scoping and token revocation

**User Accounts, Subscriptions & Operator Tools (22 FRs)**

- **FR48:** Users can authenticate via Apple Sign In, Google Sign In, or email and password
- **FR49:** Users can manage their subscription tier
- **FR51:** Operators can review and resolve disputed proof verifications via an internal dashboard
- **FR52:** Operators can reverse charges and issue refunds
- **FR53:** Operators can impersonate user accounts for troubleshooting, with all impersonation actions logged in an audit trail
- **FR54:** Operators receive alerts for payment failures and pending disputed verifications
- **FR60:** Users can delete their account and all associated data
- **FR61:** New users can complete an onboarding flow covering calendar connection, energy preferences setup, and initial configuration
- **FR77:** Users can customize app appearance settings (theme, text size)
- **FR81:** Users can export their task and list data in CSV and Markdown formats
- **FR82:** New users receive 14 days of full-access free trial; after 14 days, all access is blocked until a paid subscription is activated
- **FR83:** Users can select and subscribe to a pricing tier (Individual, Couple, Family & Friends) during or after the trial period
- **FR84:** Users can upgrade or downgrade their subscription tier
- **FR85:** User data is retained for a defined period after trial expiry before deletion, allowing reactivation without data loss
- **FR86:** Invited users joining a shared list receive an independent trial or onboarding path if not already subscribed
- **FR87:** Users can view their remaining trial days and current subscription status at any time
- **FR88:** Users who reach trial expiry are presented with a designed paywall screen before access is blocked
- **FR89:** Users can cancel their subscription; active commitment contracts continue until their individual deadlines
- **FR90:** Users receive a grace period and notification when a subscription renewal payment fails before access is blocked
- **FR91:** Users can view active sessions and remotely revoke access from specific devices
- **FR92:** The system supports optional two-factor authentication
- **FR94:** The system applies a defined conflict resolution policy when offline changes sync against conflicting server state

**Total FRs: 93** (across 8 categories)

---

### Non-Functional Requirements

**Performance (11 NFRs)**
- NFR-P1: App cold launch completes within 2 seconds on supported devices
- NFR-P2: Task creation (direct input) completes and appears in the list within 500ms
- NFR-P3: NLP task parsing and scheduling completes within 3 seconds of submission
- NFR-P4: Single-user schedule recalculation completes within 5 seconds; shared list recalculation (up to 10 members, 100 tasks) completes within 15 seconds
- NFR-P5: Scheduling explanation (FR13) loads within 1 second
- NFR-P6: REST API standard endpoints respond within 500ms at p95 under normal load
- NFR-P7: MCP server endpoints respond within 1 second at p95 under normal load
- NFR-P8: UI animations and transitions run at 60fps on supported devices; no perceptible jank
- NFR-P9: Task list loads and search results return within 1 second for lists up to 500 tasks
- NFR-P10: iOS and macOS app bundle sizes remain within platform best-practice thresholds
- NFR-P11: All user-facing strings are externalized into a localization layer; v1 ships English-only

**Security (8 NFRs)**
- NFR-S1: All data encrypted in transit (TLS 1.3 minimum) and at rest (AES-256)
- NFR-S2: On Task never stores raw payment card data; all payment handling delegated to Stripe (PCI DSS SAQ A)
- NFR-S3: Watch Mode frames processed in-flight and not persisted; no continuous video stored
- NFR-S4: Proof media stored in private object storage with access scoped to owning user and shared list members
- NFR-S5: Authentication tokens are short-lived JWTs; refresh tokens rotated on use and revocable per session
- NFR-S6: All operator impersonation actions are immutably logged with timestamp, operator identity, and actions taken
- NFR-S7: Application relies on framework-level and infrastructure-level protections to mitigate OWASP Top 10 risks
- NFR-S8: 2FA applies to email/password accounts only; Apple/Google Sign In delegate security to their OAuth providers

**Reliability (8 NFRs)**
- NFR-R1: Stripe off-session charge processing < 0.1% failure rate; transient failures retried with exponential backoff and idempotency keys
- NFR-R2: Stripe webhook processing is idempotent; duplicate delivery does not result in duplicate charges
- NFR-R3: Human dispute review SLA: operator responds within 24 hours of filing; charge hold persists until resolution
- NFR-R4: Every.org disbursement failures queued and retried; funds never lost in transit
- NFR-R5: Offline proof submissions reliably queued and synced on reconnect with timestamp integrity; no proof silently dropped
- NFR-R6: Backend API targets 99.9% monthly uptime; maximum tolerable single-incident downtime 15 minutes
- NFR-R7: User data retained 30 days after trial expiry or account cancellation before permanent deletion
- NFR-R8: Proof media retained as completion records persists until parent task is permanently deleted

**Quality & Correctness (2 NFRs)**
- NFR-Q1: Scheduling engine produces deterministic output — identical inputs always produce identical scheduled outputs
- NFR-Q2: Payment charge logic and scheduling constraint resolution maintain minimum 90% unit test coverage

**Accessibility (6 NFRs)**
- NFR-A1: iOS and macOS apps conform to WCAG 2.1 AA standards
- NFR-A2: Full VoiceOver support on iOS and macOS; all interactive elements reachable and described
- NFR-A3: Dynamic Type supported throughout; no text hardcoded at a fixed size
- NFR-A4: Minimum contrast ratio 4.5:1 for body text and 3:1 for large text in all themes
- NFR-A5: App appearance settings include at minimum: light/dark/system theme and text size adjustment beyond system defaults
- NFR-A6: No interaction requires precise timing or rapid sequential input; accommodates users with motor and cognitive differences

**User Experience Quality (2 NFRs)**
- NFR-UX1: App clearly communicates offline status; queued offline actions display visible confirmation
- NFR-UX2: All user-facing error messages are plain-language, non-technical, and include a clear recovery action

**Integration Reliability (6 NFRs)**
- NFR-I1: Google Calendar changes propagate to scheduling engine within 60 seconds
- NFR-I2: On Task calendar block writes appear in Google Calendar within 10 seconds of task scheduling
- NFR-I3: Apple HealthKit data used for auto-verification read within 5-minute lag window; delayed data does not result in incorrect charges
- NFR-I4: Stripe webhook events processed within 30 seconds of receipt
- NFR-I5: Every.org disbursement attempted within 1 hour of confirmed charge; failures retried and logged
- NFR-I6: API rate limits defined, documented in OpenAPI spec, enforced, and communicated via response headers

**Business Intelligence (1 NFR)**
- NFR-B1: Key business events instrumented and queryable for analytics

**Total NFRs: 44** (across 8 categories)

---

### Additional Requirements & Constraints

- **Geographic restriction:** US-only v1; architecture must not foreclose future international expansion
- **Payment model:** Off-session Stripe charges; PCI SAQ A scope; web-based payment setup (Post-Epic v. Apple)
- **Tax treatment:** On Task is the charitable donor; no tax receipts to users; Every.org integration with queue-backed fallback
- **Proof media retention:** User-configurable at submission; privacy-first default (purge after verification unless user opts to retain)
- **Watch Mode:** Cloud processing (not on-device); frames processed and discarded; session metadata retained
- **Offline conflict resolution:** Defined policy per FR94; charge reversal on backdated valid proof
- **GDPR/CCPA:** Architecture must not foreclose compliance; full implementation deferred to v2
- **Subscription tiers:** Individual (~$10/mo), Couple, Family & Friends (pricing to be validated)
- **Dispute policy:** "No questions asked" — stated as a product and marketing commitment
- **V1 is non-negotiable minimum:** Founder daily-driver validation requires complete V1 scope

### PRD Completeness Assessment

The PRD is thorough, internally consistent, and unusually well-specified for a pre-implementation document. Requirements are numbered, clearly delineated as binding, and cover all six user journeys completely. Numbering gaps (FR50 absent, gap between FR49 and FR51) appear intentional or as an artefact of iterative editing — no missing requirements are implied. The innovation and risk sections are mature. Domain-specific sections (payment compliance, privacy, App Store) are production-grade.

One observation: FR53 (user impersonation) does not explicitly state a scope limit on what operators can do while impersonating — the architecture resolves this via the audit log, but the PRD could be more explicit about operator action boundaries.

---

## Epic Coverage Validation

### Status: Epics Not Yet Created

No epics and stories document was found. This readiness check is being run **before** epic creation — the correct use: identify gaps in the planning artifacts so they can be resolved before story decomposition begins.

### Coverage Matrix

All 93 FRs are pre-epic at this stage. Coverage will be validated after `bmad-create-epics-and-stories` runs.

### Coverage Statistics

- Total PRD FRs: 93
- FRs covered in epics: 0 (epics not yet created — expected at this stage)

---

## UX Alignment Assessment

### UX Document Status

✅ **Found and complete** — `ux-design-specification.md`, all 14/14 steps completed, status: `complete`. The UX spec was authored with the PRD and Architecture as explicit input documents.

---

### UX ↔ PRD Alignment

**Overall: Strong alignment.** The UX spec carries explicit FR references throughout and was built directly from the PRD. All six user journeys are addressed.

| Area | PRD FRs | UX Coverage | Status |
|---|---|---|---|
| Task & List Management | FR1, FR1b, FR2–FR8, FR55–FR59, FR68–FR69, FR73–FR74, FR76, FR78 | Add tab (Smart Capture), Today tab (list view), task detail, bulk operations, templates | ✅ |
| Intelligent Scheduling | FR9–FR14, FR79 | Schedule health strip, Today tab ordering, schedule nudges, scheduling explanation on tap | ✅ |
| Shared Lists | FR15–FR21, FR62, FR75 | Lists tab, shared list management, named-person framing, round-robin assignment UX | ✅ |
| Commitment Contracts | FR22–FR30, FR63–FR65 | Stake slider component, commitment lock flow, group approval flow, pool mode, impact dashboard | ✅ |
| Proof & Verification | FR31–FR41, FR66–FR67 | Four proof paths (photo, HealthKit, screenshot, offline), Watch Mode overlay, dispute confirmation screen | ✅ |
| Notifications | FR42, FR43, FR72 | Type-specific notification design, three-level configurability, pre-deadline warning treatment | ✅ |
| Platform & API | FR44–FR47, FR71, FR80, FR93 | REST and MCP noted as background services; HealthKit and Watch Mode iOS-only degradation designed | ✅ |
| Accounts & Subscriptions | FR48–FR49, FR51–FR54, FR60–FR61, FR77, FR81–FR92, FR94 | Onboarding flow, subscription/paywall, session management, 2FA, data export, account deletion, offline status UI | ✅ |

**Minor observations (not gaps, but worth capturing in epics):**

1. **Guided capture mode** — UX expands FR1b into three explicit modes: Quick capture (single utterance → LLM), Guided (multi-turn LLM modal sheet), and Form (manual fields). The PRD only distinguishes "direct input" (FR1) vs. "natural language input" (FR1b). The Guided mode is implied but not explicit. Epic stories should name all three capture modes.

2. **"Chapter break" recovery screen** — UX specifies a distinct recovery UI after a missed commitment ("that one's done — what does your future self need now?"). This is implied by the PRD's non-punitive mandate but is not an explicit FR. It should be captured as a story in the commitment contract epic.

3. **Impact dashboard framing** — UX frames FR27 (lifetime impact dashboard) as "evidence of who you've become" — more prescriptive than the PRD's description. This constrains copy and design in implementation. Stories must preserve this intent.

---

### UX ↔ Architecture Alignment

**Overall: Strong alignment.** The architecture was an input document to the UX spec; they are mutually aware.

| UX Requirement | Architecture Support | Status |
|---|---|---|
| Flutter / Cupertino design system | Flutter 3.41, `flutter_riverpod`, `go_router`, Cupertino widgets | ✅ |
| Live Activities (Dynamic Island, Lock Screen) | `### Live Activities & WidgetKit` section — `live_activities` plugin, native Swift extensions, APNs push token flow | ✅ |
| Watch Mode (iOS only, graceful degradation on macOS) | `apps/flutter/lib/features/watch_mode/`; macOS degradation noted in arch | ✅ |
| HealthKit auto-verify (iOS only, macOS graceful) | FR35/FR47; HealthKit unavailable on macOS documented; NFR-I3 covers data lag | ✅ |
| macOS three-pane layout (900×600pt min, collapses at 1100pt) | Flutter `LayoutBuilder` breakpoints match UX spec exactly (900/1100pt) | ✅ |
| Design token system (colors, typography, spacing) | `apps/flutter/lib/core/theme/app_theme.dart` | ✅ |
| Copy / voice system (past self / future self language) | `l10n.yaml` + `app_en.arb` — all strings externalized per NFR-P11 | ✅ |
| Proof media retention (user-configurable) | Backblaze B2 + retention policy per NFR-R8; FR38 user opt-in | ✅ |
| Push notifications (type-specific treatment) | APNs via `@fivesheepco/cloudflare-apns2`; `push` Flutter package | ✅ |
| Offline capability ("never feel unavailable") | `drift` offline queue, `sync_manager.dart`, `pending_operations.dart`; NFR-UX1 | ✅ |
| New York serif font (`.NewYorkFont` platform string) | Noted as implementation risk in UX spec; not addressed in architecture | ⚠️ |
| Onboarding sample schedule (demo data before calendar access) | Not addressed in architecture | ⚠️ |
| HealthKit 30-min buffer before deadline charge | Implied by NFR-I3; specific buffer value not in architecture | ⚠️ |

---

### Warnings

**⚠️ W1 — Onboarding demo data strategy not architecturally specified**
The UX spec requires showing a pre-populated sample schedule in onboarding before the user grants calendar access. This requires either static fixture data bundled in the Flutter app, or a seed/demo API endpoint. Architecture is silent on this. The relevant onboarding epic story must define the approach (recommend static Flutter fixtures to avoid an API call before auth).

**⚠️ W2 — New York serif font bundling not addressed in architecture**
The UX spec uses `'.NewYorkFont'` (system font, iOS 13+) and requires a bundled fallback for future Android support. Architecture doesn't specify a font asset bundling strategy. The theme epic should address fallback font bundling (`pubspec.yaml` `fonts:` declaration).

**⚠️ W3 — HealthKit 30-minute deadline buffer not specified in architecture**
UX flow decisions include a 30-minute buffer: if HealthKit data has not arrived within 30 minutes of deadline, the Now tab card should surface a "Verify manually" fallback. This is implementation detail implied by NFR-I3, but the specific 30-minute value and the fallback CTA logic should be explicitly captured in the proof/HealthKit epic story. Without explicit documentation, implementers may choose an incorrect window.

---

### UX Alignment Summary

- **UX ↔ PRD:** All 93 FRs are addressed in the UX spec. Three minor elaboration items (Guided capture mode, chapter break screen, impact dashboard framing) should be explicitly named in epics.
- **UX ↔ Architecture:** Strong mutual awareness. Three implementation-level gaps flagged (demo data, font bundling, HealthKit buffer) — none are blockers, all are epic/story-level decisions.

---

## Epic Quality Review

### Status: Pre-Epic — Standards Established for Epic Creation

No epics document exists. This step establishes the quality standards and structural requirements that `bmad-create-epics-and-stories` must satisfy.

### Required Quality Standards for On Task Epics

#### Epic Structure Requirements

Each epic must:
- **Deliver user-visible value** — an end user must be meaningfully better off at the conclusion of each epic. "Setup database" is not an epic.
- **Be independently releasable** — Epic N must function without Epic N+1 features
- **Map to traceable FRs** — every epic must list which FRs it implements
- **Be user-centric in title** — "Users can capture and schedule tasks" not "Task CRUD and scheduling engine"

#### Greenfield Project Sequence — Required

This is a greenfield project (solo founder, monorepo). Epic 1 must include:
- Monorepo scaffold (pnpm workspaces, tsconfig.base.json)
- CI/CD pipeline (GitHub Actions, Neon ephemeral branch automation)
- Flutter project initialization (`flutter create --org com.ontaskhq --platforms=ios,macos`)
- `/packages/core` Drizzle schema and Neon connection
- Basic staging environment

Epic 1 Story 1 must be: "Set up monorepo, CI/CD, and development environment."

#### Dependency Ordering — Known Constraints

The architecture defines an explicit implementation sequence that epics must honour:

| Must come before | The following epic |
|---|---|
| Auth (JWT, Apple/Google Sign In) | All user-facing epics |
| APNs push infrastructure | Any notifications story |
| `/packages/scheduling` | Any scheduling story |
| Stripe integration | Commitment contracts epic |
| `/packages/ai` (Vercel AI SDK) | Proof verification, Watch Mode, NLP parsing |
| Live Activities Swift extension | Now tab timer, commitment countdown stories |

#### High-Risk Areas Requiring Extra Story Detail

The following features have implementation complexity that demands unusually detailed acceptance criteria:

1. **Scheduling engine** (`/packages/scheduling`) — pure function, TDD-first, 100% coverage enforced in CI. Story must specify test naming convention: `schedule_[constraint]_[condition]_[expected]`.
2. **Stripe off-session charges** — idempotency keys required; exactly-once semantics. Stories must specify idempotency key strategy.
3. **Offline proof with backdated timestamp** (FR37) — `clientTimestamp` set at creation, not sync time. Story must specify the `pending_operations` table schema and FIFO processor behaviour.
4. **Commitment contract clock skew** — 30-day maximum accepted; boundary tests required. Stories must specify the three boundary test cases.
5. **Watch Mode** — frames processed in-flight, never stored (NFR-S3). Story must explicitly verify no frame persistence in acceptance criteria.
6. **Live Activities** — 8h expiry, ≤1 update/sec for Watch Mode, push token refresh handling. Stories must cover all three constraints.
7. **Operator impersonation** (FR53) — immutable audit log required (NFR-S6). Story must specify what is logged and where.

#### Story Sizing Guidance

Given solo founder + AI agents as implementation model:
- Stories should be completable in one AI agent session (roughly one day of work)
- Each story should produce a testable, mergeable increment
- Database tables should be created in the story that first uses them — not upfront in a "setup models" story
- Generated files (`*.g.dart`, `*.freezed.dart`) must be committed to repo — no `build_runner` step in CI

### Epic Quality Checklist (to apply when epics are created)

- [ ] Each epic delivers user-visible value
- [ ] Epic 1 includes monorepo scaffold, CI/CD, Flutter initialization
- [ ] Auth epic precedes all user-facing epics
- [ ] Scheduling epic precedes any epic with scheduled tasks
- [ ] Stripe epic precedes commitment contracts epic
- [ ] AI pipeline epic precedes proof verification, Watch Mode, and NLP parsing
- [ ] Live Activities story is downstream of commitment contracts (requires deadline data)
- [ ] All 93 FRs traceable to at least one epic
- [ ] Three UX elaboration items captured as explicit stories (Guided capture, chapter break screen, impact dashboard voice)
- [ ] Three UX/Architecture gaps resolved in stories (demo data, font bundling, HealthKit 30-min buffer)
- [ ] Scheduling engine stories specify TDD-first approach and naming convention
- [ ] Stripe stories specify idempotency key requirements
- [ ] Watch Mode story explicitly verifies no frame persistence
- [ ] Operator impersonation story specifies audit log structure

---

## Summary and Recommendations

### Overall Readiness Status

**✅ READY TO CREATE EPICS**

All three planning artifacts (PRD, Architecture, UX Design Specification) are complete, internally consistent, and mutually aligned. No blocking issues were found. The planning stack is production-grade for a solo founder + AI agents implementation model.

This readiness check was run **before** epic creation — which is the ideal moment. The findings below are input to `bmad-create-epics-and-stories`, not remediation items for existing epics.

---

### Document Readiness Summary

| Document | Status | Notes |
|---|---|---|
| PRD | ✅ Complete | 93 FRs, 44 NFRs, all six journeys covered; unusually thorough for pre-implementation |
| Architecture | ✅ Complete | All gaps resolved including Live Activities (filled this session); implementation sequence, naming conventions, testing patterns all specified |
| UX Design Spec | ✅ Complete | 14/14 steps; explicitly references FRs; all journeys designed; accessibility as mission-critical |
| Epics & Stories | ⚠️ Not created | Expected — this assessment runs before epic creation |

---

### Issues Requiring Attention in Epics

No blocking issues. All items below are story-level decisions to make explicit during epic creation.

#### 🟡 W1 — Onboarding demo data strategy
**Finding:** UX spec requires a pre-populated sample schedule in onboarding before calendar access. Architecture is silent on the data source.
**Required action in epics:** Onboarding epic story must define approach — recommend static Flutter fixtures bundled in the app (`lib/core/fixtures/demo_schedule.dart`). This avoids an API call before auth and keeps onboarding fast.

#### 🟡 W2 — New York serif font bundling
**Finding:** UX spec uses `'.NewYorkFont'` (iOS system font) with a bundled fallback required for future Android. Architecture doesn't address font asset strategy.
**Required action in epics:** Theme/design system story must add the fallback font to `pubspec.yaml` `fonts:` declaration and verify `'.NewYorkFont'` availability via platform channel.

#### 🟡 W3 — HealthKit 30-minute deadline buffer
**Finding:** UX flow decisions specify a 30-minute buffer: if HealthKit data has not arrived within 30 minutes of task deadline, the Now tab card surfaces a "Verify manually" fallback. This specific value and fallback behaviour are not in the architecture.
**Required action in epics:** HealthKit proof epic story must specify the 30-minute window, the fallback CTA, and verify NFR-I3 (5-minute lag) doesn't conflict with this UX decision.

#### 🟡 UX elaboration items to capture as explicit stories
Three UX design decisions elaborate beyond the PRD and must be explicitly named in stories to ensure they are not lost:
1. **Guided capture mode** — multi-turn LLM modal sheet as a distinct input mode (separate from Quick capture and Form)
2. **"Chapter break" recovery screen** — the post-missed-commitment recovery UI ("that one's done — what does your future self need now?")
3. **Impact dashboard narrative voice** — "evidence of who you've become" framing, not a stats page

#### 🟡 PRD minor observation (no action required)
FR53 (operator impersonation) does not explicitly scope what operators can do while impersonating. The architecture resolves this via the immutable audit log (NFR-S6). No story action needed — documented here for completeness.

---

### Recommended Next Steps

1. **Run `bmad-create-epics-and-stories`** — all three planning documents are ready. Use this readiness report as input alongside the PRD, Architecture, and UX spec. The Epic Quality Review section (above) contains structural requirements and quality standards to apply during creation.

2. **Address W1, W2, W3 in their respective epic stories** — these are story-level decisions, not document rewrites. They should appear as explicit acceptance criteria.

3. **Capture the three UX elaboration items as named stories** — ensure the Guided capture mode, chapter break screen, and impact dashboard voice are each owned by a specific story so they are not treated as implicit requirements.

4. **Do not revise PRD or Architecture before epic creation** — all gaps have been resolved or are story-level. Adding more planning artifacts now delays implementation without improving quality.

---

### Final Note

This assessment evaluated 3 planning documents containing 93 functional requirements, 44 non-functional requirements, and a complete 14-step UX design specification. **6 items were flagged** — all at warning severity, none blocking. The planning stack is coherent, complete, and ready for story decomposition.

**Assessment date:** 2026-03-29
**Assessor:** Implementation Readiness workflow (bmad-check-implementation-readiness)

---

