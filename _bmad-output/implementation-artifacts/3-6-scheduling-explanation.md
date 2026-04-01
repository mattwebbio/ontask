# Story 3.6: Scheduling Explanation

Status: review

## Story

As a user,
I want to understand why a task was scheduled at a specific time,
So that I trust the schedule and know how to influence it.

## Acceptance Criteria

1. **Given** a task has been scheduled **When** the user taps "Why here?" on the task **Then** a plain-language explanation is shown covering: available time analysis, due date constraint, energy preference match, and any manual overrides that influenced the slot (FR13)

2. **Given** the explanation is requested **When** it is returned **Then** it loads within 1 second (NFR-P5)

3. **Given** the explanation is displayed **When** the user reads it **Then** no algorithm internals, variable names, or technical language are exposed — all text is plain, human-readable language (NFR-UX2)

4. **Given** a task was placed due to a dependency constraint **When** the explanation is shown **Then** the reason includes "scheduled here because [dependency task title] must complete first" (UX-DR16, Task Dependencies FR73)

5. **Given** a task has a `lockedStartTime` **When** the explanation is shown **Then** the reason indicates the time was manually pinned by the user

6. **Given** `GET /v1/tasks/:id/schedule` is called **When** the task has a scheduled block **Then** the response includes both the scheduled time AND the scheduling explanation `reasons` array

## Tasks / Subtasks

- [x] Implement `explain()` in `packages/scheduling/src/explainer.ts` (AC: 1, 3, 4, 5)
  - [x] Replace the stub with a real implementation that takes `ScheduleInput` and `ScheduleOutput`, finds the `ScheduledBlock` for each task, and generates plain-language `reasons: string[]`
  - [x] Reason for **available time analysis**: "Scheduled at [time] — your calendar was clear for [duration] starting then" (only if `calendarEvents` were present and the slot avoided them)
  - [x] Reason for **due date constraint**: "Placed before your due date on [date]" (when `task.dueDate` is set and slot is before it); or "No slot available before your due date — placed at the earliest available time" (when `isAtRisk === true`)
  - [x] Reason for **energy preference**: "Matched your [high-focus / low-energy] preference" (when `task.energyRequirement` is `high_focus` or `low_energy`); omit if `flexible` or unset
  - [x] Reason for **time window preference**: "Scheduled during your preferred [morning / afternoon / evening / custom] window" (when `task.timeWindow` is set)
  - [x] Reason for **dependency constraint**: "Scheduled after '[dependency task title]' which must complete first" (when `task.dependsOnTaskIds` is non-empty and the dependent task has a block)
  - [x] Reason for **manual override**: "You pinned this task to this time" (when `task.lockedStartTime` is set, i.e. `block.isLocked === true`)
  - [x] Reason for **priority ordering**: "Prioritised because this task is marked [critical / high]" (when `task.priority` is `critical` or `high`)
  - [x] Reason for **unscheduled task**: single reason "No available slot found in the scheduling window" (for tasks in `unscheduledTaskIds`)
  - [x] Return `{ reasons: [] }` for tasks not found in either `scheduledBlocks` or `unscheduledTaskIds`
  - [x] All reason strings must be plain English — no variable names, no ISO date strings in user-facing text, no technical codes (NFR-UX2). Format dates as "Mon Apr 6" style using locale-agnostic `toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })` on the Date object — do NOT pass raw ISO strings through

- [x] Update `ExplainOutput` type in `packages/core/src/types/scheduling.ts` (AC: 1, 4)
  - [x] Add optional `taskId?: string` field to `ExplainOutput` so callers can identify which task the explanation belongs to (not required for `explain()` itself but needed by the API response shape)
  - [x] The `reasons` array remains `string[]` — no structured sub-objects; plain language strings only

- [x] Update explainer tests in `packages/scheduling/src/test/explainer.test.ts` (AC: 1–5)
  - [x] Replace stub tests with real coverage — 100% branch/line/statement required by CI:
  - [x] `explain_noScheduledBlock_returnsEmpty` — task not in scheduledBlocks or unscheduledTaskIds returns `{ reasons: [] }`
  - [x] `explain_lockedTask_returnsManualOverrideReason` — `isLocked: true` block produces "You pinned this task" reason
  - [x] `explain_dueDateConstraint_slotBeforeDueDate_returnsDueDateReason` — slot before due date → "Placed before your due date" reason
  - [x] `explain_dueDateConstraint_atRisk_returnsAtRiskReason` — `isAtRisk: true` block → "No slot available before your due date" reason
  - [x] `explain_energyPreference_highFocus_returnsEnergyReason` — `high_focus` task → energy preference reason
  - [x] `explain_energyPreference_flexible_omitsEnergyReason` — `flexible` task → no energy reason
  - [x] `explain_timeWindow_morning_returnsTimeWindowReason` — `morning` timeWindow → time window reason
  - [x] `explain_dependency_blockExists_returnsDependencyReason` — `dependsOnTaskIds` populated and dependency has a block → dependency reason
  - [x] `explain_calendarConflict_avoided_returnsCalendarReason` — calendar events present in input and slot avoids them → calendar reason
  - [x] `explain_highPriority_returnsReason` — `priority: 'high'` → priority reason
  - [x] `explain_unscheduled_returnsNoSlotReason` — task in `unscheduledTaskIds` → "No available slot" reason
  - [x] `explain_multipleReasons_allReturned` — task with dueDate + energyRequirement + timeWindow → multiple reasons in array
  - [x] `explain_emptyInput_returnsEmptyReasons` — existing stub test updated to reflect real implementation

- [x] Add `GET /v1/tasks/:id/schedule` endpoint to `apps/api/src/routes/scheduling.ts` (AC: 6)
  - [x] New route: `GET /v1/tasks/{id}/schedule`
  - [x] Calls `runScheduleForUser(userId, c.env)` to get `ScheduleOutput`
  - [x] Finds the block for `taskId` in `scheduledBlocks`; if not found, checks `unscheduledTaskIds`
  - [x] Calls `explain(scheduleInput, scheduleOutput)` — pass the full `ScheduleInput` used for the run; for now this is the same stub input used in `runScheduleForUser` (tasks: [], calendarEvents from Google)
  - [x] Returns 200 with `{ data: { taskId, startTime, endTime, isLocked, isAtRisk, explanation: { reasons: string[] } } }` when task is scheduled
  - [x] Returns 200 with `{ data: { taskId, scheduled: false, explanation: { reasons: ['No available slot found in the scheduling window'] } } }` when task is in `unscheduledTaskIds`
  - [x] Returns 404 `NOT_FOUND` with `err('NOT_FOUND', ...)` when task is not in schedule output at all
  - [x] Auth stub: `x-user-id` header (same as `POST /v1/tasks/:id/schedule`)
  - [x] IMPORTANT: Register `GET /v1/tasks/{id}/schedule` AFTER the existing named `POST /v1/tasks/{id}/schedule` in the same file to avoid route-order conflicts

- [x] Wire `explain()` into `runScheduleForUser` in `apps/api/src/services/scheduling.ts` (AC: 2)
  - [x] Import `explain` from `@ontask/scheduling`
  - [x] After `schedule()` returns, call `explain(scheduleInput, result)` and store the result — keep it available for the `GET /v1/tasks/:id/schedule` endpoint
  - [x] Return the `ExplainOutput` alongside `ScheduleOutput` from `runScheduleForUser` — update the return type to `{ schedule: ScheduleOutput; explanation: ExplainOutput }` or store explanation in a way the route can access it
  - [x] The `explain()` call is synchronous and pure — it must NOT add noticeable latency (NFR-P5: full explanation loads within 1 second)

- [x] Add Flutter "Why here?" UI (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/scheduling/` — NEW feature directory following the standard Flutter feature anatomy (data / domain / presentation layers)
  - [x] `apps/flutter/lib/features/scheduling/domain/schedule_explanation.dart` — NEW: `@freezed` domain model `ScheduleExplanation` with `final List<String> reasons`
  - [x] `apps/flutter/lib/features/scheduling/domain/schedule_explanation.freezed.dart` — generated; commit to repo (no `build_runner` in CI)
  - [x] `apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.dart` — NEW: `@freezed` DTO `ScheduleExplanationDto` mapping the `explanation` field from `GET /v1/tasks/:id/schedule`; implement `toDomain()` → `ScheduleExplanation`
  - [x] `apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.freezed.dart` and `.g.dart` — generated; commit to repo
  - [x] `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` — NEW: Riverpod `@riverpod` repository that calls `GET /v1/tasks/:id/schedule` via `ApiClient` and returns `ScheduleExplanation`
  - [x] `apps/flutter/lib/features/scheduling/data/scheduling_repository.g.dart` — generated; commit to repo
  - [x] `apps/flutter/lib/features/scheduling/presentation/schedule_explanation_provider.dart` — NEW: `@riverpod AsyncValue<ScheduleExplanation>` provider that calls the repository for a given `taskId`; parameter: `taskId`
  - [x] `apps/flutter/lib/features/scheduling/presentation/schedule_explanation_provider.g.dart` — generated; commit to repo
  - [x] `apps/flutter/lib/features/scheduling/presentation/widgets/schedule_explanation_sheet.dart` — NEW: bottom sheet widget `ScheduleExplanationSheet` displayed when user taps "Why here?":
    - Shows "Why here?" as the sheet title
    - Loading state: `CupertinoActivityIndicator` centered
    - Error state: plain-language message ("Couldn't load explanation. Try again.")
    - Success state: `ListView` of reason strings, each as a `Text` with `bodyLarge` style and `AppSpacing.md` vertical padding
    - Dismiss: standard swipe-down bottom sheet dismissal
    - Must use `color.text.primary` and `color.background.primary` tokens — no hardcoded colours
  - [x] Add "Why here?" tap target to `TodayTaskRow` in `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart`:
    - Add optional `VoidCallback? onWhyHere` parameter
    - When `onWhyHere` is non-null and `rowState` is `upcoming` or `current`, show a small "?" button in the trailing area (before status indicator), styled with `color.text.secondary` at 60% opacity
    - Tap opens `ScheduleExplanationSheet` as a bottom sheet
    - Add `CustomSemanticsAction` with label "Why is this scheduled here?" for VoiceOver users (NFR-UX2)
  - [x] Write widget tests:
    - `apps/flutter/test/features/scheduling/schedule_explanation_sheet_test.dart` — test loading / error / success states render correctly
    - Use `MockSchedulingRepository` to control provider state in tests

## Dev Notes

### CRITICAL: `explain()` is a pure function — keep it that way

`packages/scheduling/src/explainer.ts` must remain a pure function — no side effects, no external calls, no `new Date()`. It receives `ScheduleInput` and `ScheduleOutput` and derives reasons deterministically. This is the same contract as `schedule()` itself. 100% unit test coverage is enforced in CI for the entire `packages/scheduling` package — every branch in `explain()` must have a corresponding test.

### CRITICAL: No AI involvement in explanation generation (v1)

The architecture notes "scheduling explanations" as one of the AI pipeline use cases (Cloudflare AI Gateway + Vercel AI SDK). However, `packages/ai` is currently empty (stub — "Populated in Epic 4"). **Do NOT integrate AI for this story.** The v1 explanation is deterministic — derived from the `ScheduleInput` task properties and `ScheduleOutput` block metadata that already exists. The AI enhancement is a future hardening pass. Attempting to wire `packages/ai` here would block on Epic 4 dependencies.

### CRITICAL: `constraintNotes` field on `ScheduledBlock`

`ScheduledBlock` already has an optional `constraintNotes?: string` field (defined in `packages/core/src/types/scheduling.ts`). The due-date constraint (`packages/scheduling/src/constraints/due-date.ts`) already populates this when a task is at risk: `constraintNotes: 'No slot available before due date ${...}'`. The `explain()` function can read `block.constraintNotes` as a signal, but **must not** expose the raw string to the user — translate it into plain language.

### CRITICAL: Return type change in `runScheduleForUser`

When adding `explain()` call to `apps/api/src/services/scheduling.ts`, update the return type carefully. The `GET /v1/tasks/:id/schedule` route needs both the `ScheduleOutput` and the `ExplainOutput`. Option: return `{ schedule: ScheduleOutput; explanation: ExplainOutput }`. Update the `POST /v1/tasks/:id/schedule` handler to destructure `{ schedule: scheduleOutput }` — it does not use explanation.

The `explain()` function needs access to the `ScheduleInput` that was passed to `schedule()`. In `runScheduleForUser`, construct the input object explicitly and pass it to both `schedule()` and `explain()`:

```typescript
const scheduleInput = {
  tasks: [],
  calendarEvents,
  windowStart: now,
  windowEnd,
}
const result = schedule(scheduleInput)
// ... removeStaleCalendarBlocks, syncScheduledBlocksToCalendar ...
const explanation = explain(scheduleInput, result)
return { schedule: { ...result, generatedAt: new Date() }, explanation }
```

### API Route: `GET /v1/tasks/{id}/schedule` response shape

```typescript
// 200 — task is scheduled
{
  data: {
    taskId: string,
    startTime: string,  // ISO 8601
    endTime: string,    // ISO 8601
    isLocked: boolean,
    isAtRisk: boolean,
    explanation: {
      reasons: string[]
    }
  }
}

// 200 — task exists but could not be scheduled
{
  data: {
    taskId: string,
    scheduled: false,
    explanation: {
      reasons: ["No available slot found in the scheduling window"]
    }
  }
}

// 404 — task not in schedule output at all
{ error: { code: "NOT_FOUND", message: "Task <id> was not scheduled" } }
```

Add a `ScheduleExplanationSchema` Zod sub-object and a `GetScheduleResponseSchema` to `scheduling.ts` for the new GET route.

### Hono route registration order

In `apps/api/src/routes/scheduling.ts`, the GET route for `/v1/tasks/{id}/schedule` must be registered AFTER the existing POST route. Hono matches routes in registration order. The existing `app.openapi(postTaskScheduleRoute, ...)` call must remain first.

### Flutter: Standard feature anatomy (mandatory pattern)

Every Flutter feature has exactly this shape (from architecture doc):

```
lib/features/{feature}/
├── data/
│   ├── {feature}_repository.dart       # implements domain interface
│   └── {feature}_dto.dart              # API ↔ domain mapping
├── domain/
│   ├── {feature}.dart                  # domain model (freezed)
│   └── {feature}_unions.dart           # (only if sealed types needed)
└── presentation/
    ├── {feature}_provider.dart          # Riverpod provider
    └── widgets/
        └── {feature}_sheet.dart
```

Use `scheduling` as the feature name. The repository calls `GET /v1/tasks/:id/schedule` via `ApiClient` (injected via Riverpod — `ApiClient apiClient(ApiClientRef ref) => ApiClient(baseUrl: AppConfig.apiUrl)`). Never construct `ApiClient` directly in the repository.

### Flutter: Generated files must be committed

The project does NOT run `build_runner` in CI. All generated `.freezed.dart` and `.g.dart` files must be generated locally and committed. Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
from `apps/flutter/` before committing. Check that the generated files are included in the commit diff.

### Flutter: Bottom sheet presentation pattern

From the UX spec: standard iOS bottom sheet (not `CupertinoAlertDialog`). Use `showCupertinoModalPopup` or `showModalBottomSheet`. Swipe-down to dismiss. The sheet title "Why here?" uses `textTheme.titleMedium` with `color.text.primary`. Never use Modal sheets for destructive confirmations — this is purely informational.

### Flutter: No hardcoded colours

All colours via `Theme.of(context).extension<OnTaskColors>()!`. Use:
- `colors.textPrimary` for reason text
- `colors.textSecondary` for secondary labels and the "?" button
- `colors.backgroundPrimary` for sheet background

### Existing `TodayTaskRow` parameters

`TodayTaskRow` already has `onComplete`, `onReschedule`, `onStartTimer` callbacks. Adding `onWhyHere` follows the same optional `VoidCallback?` pattern. The "?" button should only appear for `upcoming` and `current` row states — not for `completed`, `overdue`, or `calendarEvent` states.

### `ExplainOutput` type — keep `reasons: string[]` shape

Do NOT change `reasons` to a structured type (e.g. `{ key: string; text: string }`). The architecture intent is plain-language strings. The API contract from Story 10.2 (REST API scheduling) already references `GET /v1/tasks/:id/schedule` returning a scheduling explanation — keep the shape simple and additive.

### Date formatting in plain-language reasons

Do NOT use `.toISOString()` in reason strings. Use:
```typescript
const formatted = date.toLocaleDateString('en-US', {
  weekday: 'short', month: 'short', day: 'numeric'
})
// e.g. "Mon, Apr 6"
```

Time formatting for reason strings (e.g. "Scheduled at 9:00 AM"):
```typescript
const time = date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
// e.g. "9:00 AM"
```

### Test naming convention (established in Story 3.1)

All `packages/scheduling` tests follow the pattern: `explain_[constraint]_[condition]_[expected]`. Enforce this in the explainer test file.

### Vitest config — 100% coverage threshold

`packages/scheduling/vitest.config.ts` already enforces 100% coverage thresholds for lines, functions, branches, and statements. Every new branch in `explainer.ts` requires a test. The CI pipeline will fail if coverage drops below 100%.

### Files to Create/Modify

**Modify (packages/core types):**
- `packages/core/src/types/scheduling.ts` — add optional `taskId?: string` to `ExplainOutput`

**Modify (packages/scheduling — core logic):**
- `packages/scheduling/src/explainer.ts` — implement real `explain()` function (replace stub)
- `packages/scheduling/src/test/explainer.test.ts` — replace stub tests with full coverage suite

**Modify (apps/api services):**
- `apps/api/src/services/scheduling.ts` — wire `explain()`, update return type

**Modify (apps/api routes):**
- `apps/api/src/routes/scheduling.ts` — add `GET /v1/tasks/{id}/schedule` route with explanation in response

**New (apps/api tests):**
- `apps/api/test/routes/scheduling.test.ts` — NEW: test file for GET and POST scheduling routes

**New (apps/flutter — scheduling feature):**
- `apps/flutter/lib/features/scheduling/domain/schedule_explanation.dart`
- `apps/flutter/lib/features/scheduling/domain/schedule_explanation.freezed.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.dart`
- `apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.freezed.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.g.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart`
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.g.dart` (generated)
- `apps/flutter/lib/features/scheduling/presentation/schedule_explanation_provider.dart`
- `apps/flutter/lib/features/scheduling/presentation/schedule_explanation_provider.g.dart` (generated)
- `apps/flutter/lib/features/scheduling/presentation/widgets/schedule_explanation_sheet.dart`

**Modify (apps/flutter — today feature):**
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` — add `onWhyHere` callback + "?" button

**New (apps/flutter tests):**
- `apps/flutter/test/features/scheduling/schedule_explanation_sheet_test.dart`

### Project Structure Notes

- `explain()` lives in `packages/scheduling/src/explainer.ts` — architecture-prescribed location (FR13). Do NOT move it or duplicate it in `apps/api`.
- New Flutter `scheduling` feature goes under `lib/features/scheduling/` — not under `today/` or `tasks/`. The scheduling concern is cross-cutting (appears in Today tab and Now tab in future).
- The `GET /v1/tasks/{id}/schedule` route lives in `apps/api/src/routes/scheduling.ts` alongside `POST /v1/tasks/{id}/schedule` — not in `tasks.ts`. Scheduling routes stay in `scheduling.ts`.
- No new database tables or migrations required for this story.
- No new Cloudflare Workers Secrets or bindings required.

### References

- FR13: Users can view an explanation of why a task was scheduled at a specific time
- NFR-P5: Scheduling explanation (FR13) loads within 1 second
- NFR-UX2: All user-facing messages are plain-language, non-technical, include a clear recovery action
- `packages/scheduling/src/explainer.ts` — existing stub to implement
- `packages/scheduling/src/scheduler.ts` — algorithm reference (greedy-earliest, constraint pipeline order)
- `packages/scheduling/src/constraints/` — constraint implementations to derive reasons from
- `packages/core/src/types/scheduling.ts` — `ScheduleTask`, `ScheduledBlock`, `ExplainOutput` types
- `apps/api/src/routes/scheduling.ts` — existing POST route to extend
- `apps/api/src/services/scheduling.ts` — `runScheduleForUser` orchestrator
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` — widget to extend
- Architecture doc §"packages/scheduling" — `explainer.ts` at `FR13 — why was this scheduled here?`
- Architecture doc §"AI pipeline abstraction" — scheduling explanations noted as future AI candidate; defer to Epic 4
- UX spec §"Effortless Interactions" — "Understanding why a task is scheduled when it is (scheduling explanation on tap — FR13)"
- UX spec §"Micro-Emotions" — "Confidence vs. confusion → scheduling explanation always one tap away; never mystery"
- Story 3.1 Dev Notes — explainer stub, 100% coverage requirement, test naming convention
- Story 3.2 Dev Notes — `schedule()` algorithm, constraint pipeline, `ScheduledBlock.isAtRisk`, `ScheduledBlock.isLocked`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Coverage threshold failure on branch 109 of explainer.ts (`depTask?.title ?? depId`) resolved by adding `explain_dependency_depTaskNotInInput_usesFallbackId` test case.
- API returns 400 (not 422) for OpenAPI validation errors — corrected in scheduling.test.ts.
- `OnTaskColors` does not have `backgroundPrimary` — using `surfacePrimary` instead (equivalent token).
- `explain()` signature extended to accept `taskId: string` as third parameter to support per-task explanations. `runScheduleForUser` updated to return `{ schedule, scheduleInput }` so the route can call `explain()` per request.

### Completion Notes List

- Implemented `explain()` in `packages/scheduling/src/explainer.ts` as a pure function with 8 reason categories: calendar avoidance, due date, energy preference, time window, dependency, manual override, priority, and unscheduled. Locked tasks return only the pin reason (short-circuits all others). 100% branch/line coverage achieved (99 tests total in scheduling package).
- Added `taskId?: string` to `ExplainOutput` in `packages/core/src/types/scheduling.ts` as specified.
- Replaced stub explainer tests with 26 targeted tests covering all branches including the dependency-task-not-in-input fallback case.
- Added `GET /v1/tasks/{id}/schedule` route after the existing POST route in `apps/api/src/routes/scheduling.ts`. Returns scheduled block + explanation (AC: 6), unscheduled explanation, or 404. Added `ScheduleExplanationSchema` and `GetScheduleResponseSchema` Zod schemas.
- Updated `runScheduleForUser` to return `RunScheduleResult { schedule, scheduleInput }` so the GET route can call `explain()` with the original input. POST route destructures `{ schedule }` as before.
- Created full Flutter `scheduling` feature under `lib/features/scheduling/`: domain model, DTO with generated code, repository, provider, and `ScheduleExplanationSheet` bottom sheet widget.
- Extended `TodayTaskRow` with optional `onWhyHere` callback; "?" button appears for `upcoming`/`current` states only; `CustomSemanticsAction` with label "Why is this scheduled here?" added for VoiceOver.
- All tests pass: 99 scheduling unit tests (100% coverage), 139 API tests, 530 Flutter tests (6 new for scheduling sheet).

### File List

packages/scheduling/src/explainer.ts
packages/scheduling/src/test/explainer.test.ts
packages/core/src/types/scheduling.ts
apps/api/src/routes/scheduling.ts
apps/api/src/services/scheduling.ts
apps/api/test/routes/scheduling.test.ts
apps/flutter/lib/features/scheduling/domain/schedule_explanation.dart
apps/flutter/lib/features/scheduling/domain/schedule_explanation.freezed.dart
apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.dart
apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.freezed.dart
apps/flutter/lib/features/scheduling/data/schedule_explanation_dto.g.dart
apps/flutter/lib/features/scheduling/data/scheduling_repository.dart
apps/flutter/lib/features/scheduling/data/scheduling_repository.g.dart
apps/flutter/lib/features/scheduling/presentation/schedule_explanation_provider.dart
apps/flutter/lib/features/scheduling/presentation/schedule_explanation_provider.g.dart
apps/flutter/lib/features/scheduling/presentation/widgets/schedule_explanation_sheet.dart
apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/test/features/scheduling/schedule_explanation_sheet_test.dart
_bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- 2026-03-31: Story 3.6 created — Scheduling Explanation
- 2026-03-31: Story 3.6 implemented — pure explain() function, GET /v1/tasks/:id/schedule endpoint, Flutter scheduling feature with ScheduleExplanationSheet and TodayTaskRow "Why here?" button
