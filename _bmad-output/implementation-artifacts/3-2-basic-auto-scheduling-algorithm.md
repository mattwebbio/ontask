# Story 3.2: Basic Auto-Scheduling Algorithm

Status: review

## Story

As a user,
I want my tasks automatically scheduled into available time slots respecting all my constraints,
So that I don't have to manually figure out when to do everything.

## Acceptance Criteria

1. **Given** a user has tasks with due dates and a calendar **When** the scheduling engine runs **Then** tasks are placed in available time slots respecting: due dates, time-of-day constraints (FR4), energy preferences (FR5), and existing calendar events (FR9) **And** tasks with hard time-of-day constraints are pinned to their window; if no valid slot is available before the due date, the task is marked `isAtRisk = true`

2. **Given** a task has `lockedStartTime` set (FR8) **When** the engine runs **Then** that task is placed exactly at `lockedStartTime` with `isLocked = true`, overriding all other constraints **And** the engine does not move it when resolving other tasks

3. **Given** a schedule recalculation is triggered for a single user **When** it completes **Then** the result is available within 5 seconds (NFR-P4) — i.e., the engine itself must not be the bottleneck; it must complete in well under 1 second for typical task counts

4. **Given** the `schedule()` pure function is called **When** it runs **Then** `generatedAt` in the output is NOT set by the engine — it is set to `input.windowStart` as the safe stand-in, and the API service layer (`apps/api/src/services/scheduling.ts`) overwrites it with `new Date()` before returning to clients (NFR-Q1 determinism invariant)

5. **Given** the API service `apps/api/src/services/scheduling.ts` exists **When** the scheduling route calls it **Then** it loads the user's tasks and calendar events, calls `schedule()`, sets `generatedAt = new Date()`, and returns the `ScheduleOutput`

6. **Given** the API route `POST /v1/tasks/:id/schedule` exists **When** called **Then** it triggers the scheduling engine and returns the resulting scheduled time (FR44) using the standard `{ data: ... }` envelope

## Tasks / Subtasks

- [x] Implement `schedule()` algorithm in `packages/scheduling/src/scheduler.ts` (AC: 1, 2, 4)
  - [x] **Phase 1 — Candidate slot generation**: Generate candidate `ScheduledBlock` slots for each task across `[windowStart, windowEnd]`, broken into increments matching `estimatedDurationMinutes` (default 30 min if not set)
  - [x] **Phase 2 — Apply constraints pipeline**: For each task, run all 4 active constraint functions in order: `applyCalendarEventConstraint` → `applyTimeOfDayConstraint` → `applyEnergyPreferenceConstraint` → `applyDueDateConstraint`; also apply `applyDependencyConstraint` and `applySuggestedDateConstraint` where applicable
  - [x] **Phase 3 — Slot selection**: Pick the earliest remaining valid slot for each task (greedy-earliest strategy); tasks without a valid slot before their due date are marked `isAtRisk = true`; tasks that cannot be placed at all go into `unscheduledTaskIds`
  - [x] **Locked tasks**: Any task with `lockedStartTime` set bypasses the slot pipeline — place it directly at that time with `isLocked = true`
  - [x] Ensure `generatedAt` is still set from `input.windowStart` (unchanged from Story 3.1 stub — the engine never calls `new Date()`)

- [x] Implement constraint functions replacing stubs in `packages/scheduling/src/constraints/` (AC: 1)
  - [x] `due-date.ts` — `applyDueDateConstraint(task, slots)`: remove any slot whose `endTime` is after `task.dueDate`; mark remaining slot as `isAtRisk = true` if no slot exists before due date (use `constraintNotes`)
  - [x] `calendar-events.ts` — `applyCalendarEventConstraint(events, slots)`: remove any slot that overlaps any `CalendarEvent`; overlap = slot.startTime < event.endTime && slot.endTime > event.startTime
  - [x] `time-of-day.ts` — `applyTimeOfDayConstraint(task, slots)`: filter slots to match `task.timeWindow`; morning = 06:00–12:00, afternoon = 12:00–17:00, evening = 17:00–21:00, custom = `task.timeWindowStart`–`task.timeWindowEnd`; if `timeWindow` is not set or undefined, pass all slots through unchanged
  - [x] `energy-preferences.ts` — `applyEnergyPreferenceConstraint(task, slots)`: for `high_focus` tasks, prefer slots in the first half of the day (before noon); for `low_energy`, prefer afternoon/evening; for `flexible` or unset, pass through unchanged — implement as a sort/reorder, NOT a filter, so no tasks are dropped
  - [x] `dependencies.ts` — `applyDependencyConstraint(task, scheduledBlocks, slots)`: remove any slot that starts before the latest `endTime` of all scheduled blocks for tasks in `task.dependsOnTaskIds`; if a dependency has not been scheduled yet, treat the constraint as unresolvable and return empty slots (task → `unscheduledTaskIds`)
  - [x] `suggested-dates.ts` — `applySuggestedDateConstraint(suggested, slots)`: if `suggested` is defined, reorder slots so those on or after `suggested` date appear first; do NOT filter out slots before suggested date — this is a soft nudge, not a hard constraint

- [x] Write/expand tests for `packages/scheduling/src/test/` achieving 100% coverage (AC: 1, 2, 3, 4)
  - [x] `test/scheduler.test.ts` — add tests for the real algorithm:
    - `schedule_singleTask_noConstraints_placedAtWindowStart` — task with no constraints lands at windowStart
    - `schedule_singleTask_calendarBlocked_placedAfterEvent` — calendar event blocks first slot; task placed after
    - `schedule_singleTask_dueDateBeforeWindow_markedAtRisk` — task due before windowStart has `isAtRisk = true`
    - `schedule_singleTask_lockedStartTime_placedExactly` — task with lockedStartTime is placed there with `isLocked = true`
    - `schedule_multipleTask_dependencyOrder_taskBAfterTaskA` — task B with dependsOnTaskIds=['A'] lands after A's endTime
    - `schedule_singleTask_morningWindow_slotsFilteredToMorning` — morning-window task placed only in 06:00–12:00
    - `schedule_singleTask_noSlotAvailable_inUnscheduledTaskIds` — task with fully blocked window ends up in `unscheduledTaskIds`
    - `schedule_determinism_sameInput_identicalOutput` — (already exists; verified still passes with real algorithm)
  - [x] `test/constraints/due-date.test.ts` — replace trivial stub test with real tests:
    - `schedule_dueDate_slotAfterDueDate_removed`
    - `schedule_dueDate_slotBeforeDueDate_retained`
    - `schedule_dueDate_noSlotBeforeDue_markedAtRisk`
  - [x] `test/constraints/calendar-events.test.ts` — real tests:
    - `schedule_calendarEvent_overlappingSlot_removed`
    - `schedule_calendarEvent_adjacentSlot_retained`
  - [x] `test/constraints/time-of-day.test.ts` — real tests:
    - `schedule_timeOfDay_morningWindow_filtersToMorning`
    - `schedule_timeOfDay_customWindow_filtersToRange`
    - `schedule_timeOfDay_noWindow_passesThrough`
  - [x] `test/constraints/energy-preferences.test.ts` — real tests:
    - `schedule_energyPreference_highFocus_sortsEarliestFirst`
    - `schedule_energyPreference_flexible_noReorder`
  - [x] `test/constraints/dependencies.test.ts` — real tests:
    - `schedule_dependency_dependencyScheduled_blockStartsAfter`
    - `schedule_dependency_dependencyUnscheduled_returnsEmpty`
  - [x] `test/constraints/suggested-dates.test.ts` — real tests:
    - `schedule_suggestedDate_defined_reordersToSuggestedFirst`
    - `schedule_suggestedDate_undefined_passesThrough`
  - [x] Verify `pnpm --filter @ontask/scheduling test --coverage` passes at 100% after all changes

- [x] Create API service `apps/api/src/services/scheduling.ts` (AC: 4, 5)
  - [x] Import `schedule` from `@ontask/scheduling`
  - [x] `runScheduleForUser(userId, env)` function: load tasks from DB (stub: return typed fixture tasks), load calendar events (stub: empty array), call `schedule()`, set `generatedAt = new Date()`, return `ScheduleOutput`
  - [x] This is the ONLY place in the codebase that calls `new Date()` for `generatedAt`

- [x] Create API route `apps/api/src/routes/scheduling.ts` (AC: 6)
  - [x] `POST /v1/tasks/:id/schedule` — triggers scheduling engine for the task owner's full schedule, returns the `ScheduledBlock` for the requested task (or 404 if not in result)
  - [x] Use `@hono/zod-openapi` `createRoute` pattern (same as all other routes)
  - [x] Response schema: `{ data: { taskId, startTime, endTime, isLocked, isAtRisk } }` — standard envelope
  - [x] Auth middleware stub: extract userId from header `x-user-id` (consistent with other stub routes)

- [x] Register the scheduling router in `apps/api/src/index.ts` (AC: 6)
  - [x] `import { schedulingRouter } from './routes/scheduling.js'`
  - [x] `app.route('/', schedulingRouter)` — after bulkOperationsRouter, before or after tasksRouter

## Dev Notes

### Critical Architecture Rules — DO NOT VIOLATE

- **Engine is pure**: `packages/scheduling/src/scheduler.ts` must NEVER call `new Date()`, `Date.now()`, `Math.random()`, `fetch()`, or import from `apps/`. Violation breaks NFR-Q1 (determinism) and is caught by 100% test coverage gate.
- **`generatedAt` ownership**: The engine sets it to `input.windowStart` as a pure-function stand-in. The API service (`apps/api/src/services/scheduling.ts`) overwrites it with `new Date()` before returning to clients. This is the architectural boundary.
- **`.js` extensions**: All local imports in `packages/scheduling/` use `.js` extensions (NodeNext module resolution). E.g., `import { applyDueDateConstraint } from '../constraints/due-date.js'`. Wrong extensions cause runtime import failures.
- **Test naming**: ALL test descriptions must follow `schedule_[constraint]_[condition]_[expected]` (ARCH-22). No exceptions. This applies to constraint tests too.

### Existing File State (from Story 3.1)

All constraint and strategy files are stubs that pass slots through unchanged. The `scheduler.ts` returns `scheduledBlocks: []` and all tasks in `unscheduledTaskIds`. The 100% coverage gate is already passing with 34 tests. Story 3.2 replaces the stub bodies with real implementations — **do not create new files for constraints, they already exist**.

Current file state:
- `packages/scheduling/src/scheduler.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/due-date.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/calendar-events.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/time-of-day.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/energy-preferences.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/dependencies.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/suggested-dates.ts` — stub, REPLACE body
- `packages/scheduling/src/constraints/index.ts` — barrel file (EXISTS, not in original story file list — DO NOT delete)
- `packages/scheduling/src/strategies/round-robin.ts` — stub, leave as stub (FR17 shared list assignment, not personal scheduling)
- `packages/scheduling/src/strategies/least-busy.ts` — stub, leave as stub
- `packages/scheduling/src/strategies/ai-assisted.ts` — stub, leave as stub

### Algorithm Design — Greedy-Earliest

The Story 3.2 algorithm is intentionally simple: **greedy-earliest selection**. For each task (sorted by due date ascending, then by priority):
1. Generate candidate 30-min slots across the full `[windowStart, windowEnd]` window
2. Run the constraint pipeline to filter/sort candidate slots
3. Pick the first remaining slot
4. Mark that slot as "occupied" so subsequent tasks cannot use it

This is not an optimal scheduler — it is the foundation. The greedy approach is correct for V1. Do NOT implement backtracking, constraint satisfaction, or optimization passes in this story.

**Slot granularity**: 30-minute increments starting at `windowStart`. If `estimatedDurationMinutes` is set and > 30, the slot length equals `estimatedDurationMinutes`. Do not attempt sub-30-minute scheduling.

**Task ordering**: Sort tasks by `dueDate` ascending (null/undefined → end of list), then `priority` descending (critical > high > normal > undefined).

### Constraint Interaction Order

The constraint pipeline runs in this fixed order per task:
```
applyCalendarEventConstraint → applyTimeOfDayConstraint → applyEnergyPreferenceConstraint → applyDueDateConstraint
```
Dependency and suggested-date constraints are applied before the pipeline for their respective tasks. `lockedStartTime` bypasses the pipeline entirely.

### Type Reference (from `packages/core/src/types/scheduling.ts`)

```typescript
export type TimeWindow = 'morning' | 'afternoon' | 'evening' | 'custom'
export type EnergyRequirement = 'high_focus' | 'low_energy' | 'flexible'

export interface ScheduleTask {
  id: string
  title: string
  dueDate?: Date
  estimatedDurationMinutes?: number
  timeWindow?: TimeWindow
  timeWindowStart?: string  // HH:mm
  timeWindowEnd?: string    // HH:mm
  energyRequirement?: EnergyRequirement
  priority?: 'normal' | 'high' | 'critical'
  dependsOnTaskIds?: string[]
  lockedStartTime?: Date
  suggestedDate?: Date
}

export interface CalendarEvent {
  id: string
  startTime: Date
  endTime: Date
  isAllDay: boolean
}

export interface ScheduleInput {
  tasks: ScheduleTask[]
  calendarEvents: CalendarEvent[]
  windowStart: Date
  windowEnd: Date
  suggestedDates?: Record<string, Date>  // taskId → suggested date (FR14)
}

export interface ScheduledBlock {
  taskId: string
  startTime: Date
  endTime: Date
  isLocked: boolean
  isAtRisk: boolean
  constraintNotes?: string
}

export interface ScheduleOutput {
  scheduledBlocks: ScheduledBlock[]
  unscheduledTaskIds: string[]
  generatedAt: Date  // set by API service layer, not engine
}
```

### API Route Pattern

All API routes use `@hono/zod-openapi`. See `apps/api/src/routes/tasks.ts` for the exact pattern:
- `const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()`
- `createRoute({ method, path, request: { params, body }, responses })`
- `app.openapi(route, handler)`
- Return `ok(data)`, `list(data, pagination)`, or `err(code, message)` from `../lib/response.js`
- All routes export a named `*Router` constant: `export const schedulingRouter = app`

The auth middleware is a stub — extract `x-user-id` from headers as `userId` (consistent with all other stub routes in this codebase).

### API Service Layer Pattern

`apps/api/src/services/scheduling.ts` is the ONLY file that calls `new Date()` for `generatedAt`. Pattern:
```typescript
import { schedule } from '@ontask/scheduling'
import type { ScheduleOutput } from '@ontask/core'

export async function runScheduleForUser(userId: string, env: CloudflareBindings): Promise<ScheduleOutput> {
  // TODO(story-3.3): load real calendar events from DB
  // TODO(story-impl): load real tasks from DB
  const result = schedule({ tasks: [], calendarEvents: [], windowStart: new Date(), windowEnd: new Date() })
  return { ...result, generatedAt: new Date() }
}
```

The `@ontask/scheduling` package is already a workspace dependency of `packages/scheduling` but NOT of `apps/api`. You will need to add `"@ontask/scheduling": "workspace:*"` to `apps/api/package.json` dependencies.

### Review Findings to Address from Story 3.1

- **`explain_` test naming** (Open decision from Story 3.1 review): The convention `schedule_[constraint]_[condition]_[expected]` is defined in ARCH-22. The reviewer noted a contradiction between AC3 (all tests) and the task spec (which listed `explain_emptyInput_returnsEmptyReasons`). **Resolution for Story 3.2**: Do not rename existing explainer tests in this story — that is out of scope. The `explain_` prefix is acceptable for explainer-specific tests as the arch doc's examples only reference `schedule_` prefixes for `schedule()` tests. Do not touch `explainer.test.ts` in this story.
- **Strategy param naming resolved in Story 3.1**: `_input` was renamed to `input` in all three strategy stubs. Story 3.2 leaves strategy stubs unchanged.

### 100% Coverage Gate

The 100% coverage requirement is enforced by `vitest.config.ts` thresholds. After replacing stub bodies with real implementations, every branch in every constraint function must have explicit test coverage. Specifically:
- `applyTimeOfDayConstraint`: must test morning, afternoon, evening, custom, and undefined branches
- `applyEnergyPreferenceConstraint`: must test high_focus, low_energy, flexible, and undefined
- `applyDueDateConstraint`: must test slot-before-due, slot-after-due, and no-valid-slots (isAtRisk) branches
- `applyCalendarEventConstraint`: must test overlapping and non-overlapping
- `applyDependencyConstraint`: must test dependency scheduled and dependency unscheduled
- `applySuggestedDateConstraint`: must test defined and undefined

Run `pnpm --filter @ontask/scheduling test --coverage` to verify before committing.

### What This Story Does NOT Include

- Google Calendar integration (Story 3.3) — calendar events are empty array stubs
- Real database queries for tasks/users (Story 3.3+) — use typed stub fixtures
- FR17 shared-list assignment strategies (round-robin, least-busy, ai-assisted) — those stubs remain stubs
- The `explain()` function (Story 3.6) — stub remains unchanged
- Flutter UI changes — no Flutter files are modified in this story
- Auto-rescheduling triggers (Story 3.5)

### Files to Create/Modify

**Modify (packages):**
- `packages/scheduling/src/scheduler.ts` — REPLACE stub body with real greedy algorithm
- `packages/scheduling/src/constraints/due-date.ts` — REPLACE stub with real implementation
- `packages/scheduling/src/constraints/calendar-events.ts` — REPLACE stub
- `packages/scheduling/src/constraints/time-of-day.ts` — REPLACE stub
- `packages/scheduling/src/constraints/energy-preferences.ts` — REPLACE stub
- `packages/scheduling/src/constraints/dependencies.ts` — REPLACE stub
- `packages/scheduling/src/constraints/suggested-dates.ts` — REPLACE stub

**Modify (tests):**
- `packages/scheduling/src/test/scheduler.test.ts` — ADD new algorithm tests
- `packages/scheduling/src/test/constraints/due-date.test.ts` — REPLACE trivial stub test
- `packages/scheduling/src/test/constraints/calendar-events.test.ts` — REPLACE trivial stub test
- `packages/scheduling/src/test/constraints/time-of-day.test.ts` — REPLACE trivial stub test
- `packages/scheduling/src/test/constraints/energy-preferences.test.ts` — REPLACE trivial stub test
- `packages/scheduling/src/test/constraints/dependencies.test.ts` — REPLACE trivial stub test
- `packages/scheduling/src/test/constraints/suggested-dates.test.ts` — REPLACE trivial stub test

**New (API):**
- `apps/api/src/services/scheduling.ts` — NEW: service layer calling `schedule()`
- `apps/api/src/routes/scheduling.ts` — NEW: `POST /v1/tasks/:id/schedule` route

**Modify (API wiring):**
- `apps/api/src/index.ts` — ADD scheduling router import and mount
- `apps/api/package.json` — ADD `@ontask/scheduling: workspace:*` dependency

### References

- Scheduling engine architecture: `_bmad-output/planning-artifacts/architecture.md` §"Scheduling Engine Interface"
- API route patterns: `apps/api/src/routes/tasks.ts` (canonical pattern)
- API service patterns: `apps/api/src/services/` directory
- Type definitions: `packages/core/src/types/scheduling.ts`
- Coverage configuration: `packages/scheduling/vitest.config.ts`
- FR4 (time-of-day constraints), FR5 (energy preferences), FR8 (locked slots), FR9 (calendar event avoidance), FR14 (nudging), FR44 (schedule trigger endpoint), FR73 (task dependencies), NFR-P4 (5-second schedule SLA), NFR-Q1 (determinism)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_None_

### Completion Notes List

- Implemented greedy-earliest scheduling algorithm in `packages/scheduling/src/scheduler.ts`. Replaces stub that returned all tasks as unscheduled. Engine generates 30-min candidate slots across the window, runs all 6 constraints per task, picks first valid slot. Locked tasks bypass the pipeline entirely.
- Replaced all 6 constraint stubs with real implementations. Note: `applyDependencyConstraint` signature changed from `(task, allTasks: ScheduleTask[], slots)` to `(task, scheduledBlocks: ScheduledBlock[], slots)` — the second parameter now receives already-scheduled blocks (accumulated by the scheduler), enabling the dependency check.
- `applyEnergyPreferenceConstraint` implemented as sort/reorder only (no filtering) per spec. Uses group-based sort keys to avoid V8 branch coverage issues with conditional short-circuit evaluation.
- `applyDueDateConstraint`: when all slots are after the due date, returns them marked `isAtRisk=true` so the scheduler can place the task but flag it. When some slots are before the due date, only those are returned (normal case).
- Created `apps/api/src/services/scheduling.ts` — the sole location in the codebase that sets `generatedAt = new Date()` before returning to clients. The `schedule()` engine uses `windowStart` as stand-in (NFR-Q1 determinism).
- Created `apps/api/src/routes/scheduling.ts` — `POST /v1/tasks/:id/schedule` using `@hono/zod-openapi` `createRoute` pattern, standard `{ data: ... }` envelope, x-user-id header auth stub.
- Added `@ontask/scheduling: workspace:*` to `apps/api/package.json` dependencies.
- Registered `schedulingRouter` in `apps/api/src/index.ts` after `taskDependenciesRouter`.
- All 73 scheduling package tests pass at 100% coverage (statements/branches/functions/lines). All 96 API tests pass with no regressions.

### File List

packages/scheduling/src/scheduler.ts
packages/scheduling/src/constraints/due-date.ts
packages/scheduling/src/constraints/calendar-events.ts
packages/scheduling/src/constraints/time-of-day.ts
packages/scheduling/src/constraints/energy-preferences.ts
packages/scheduling/src/constraints/dependencies.ts
packages/scheduling/src/constraints/suggested-dates.ts
packages/scheduling/src/test/scheduler.test.ts
packages/scheduling/src/test/constraints/due-date.test.ts
packages/scheduling/src/test/constraints/calendar-events.test.ts
packages/scheduling/src/test/constraints/time-of-day.test.ts
packages/scheduling/src/test/constraints/energy-preferences.test.ts
packages/scheduling/src/test/constraints/dependencies.test.ts
packages/scheduling/src/test/constraints/suggested-dates.test.ts
apps/api/src/services/scheduling.ts
apps/api/src/routes/scheduling.ts
apps/api/src/index.ts
apps/api/package.json
_bmad-output/implementation-artifacts/3-2-basic-auto-scheduling-algorithm.md
_bmad-output/implementation-artifacts/sprint-status.yaml

### Review Findings

- [ ] [Review][Patch] Misleading comment contradicts actual behavior at isAtRisk branch [`packages/scheduling/src/scheduler.ts:94-96`]
- [ ] [Review][Patch] Route param `:id` uses `z.string()` instead of `z.string().uuid()` — inconsistent with all other routes [`apps/api/src/routes/scheduling.ts:38`]
- [ ] [Review][Patch] Test name inconsistency: `schedule_calendarEvents_noSlots_returnsEmpty` uses plural `calendarEvents` vs singular `calendarEvent` in all other tests in the file [`packages/scheduling/src/test/constraints/calendar-events.test.ts:27`]
- [x] [Review][Defer] No unit tests for `apps/api/src/services/scheduling.ts` [`apps/api/src/services/scheduling.ts`] — deferred, pre-existing pattern (no API service unit tests in codebase; story only requires 100% coverage for `packages/scheduling`)
- [x] [Review][Defer] Two separate `new Date()` calls in service layer (for `windowStart` and for `generatedAt`) produce slightly different timestamps [`apps/api/src/services/scheduling.ts:22,31`] — deferred, by-design stub pattern per dev notes; will be addressed in Story 3.3 when real DB data is wired
- [x] [Review][Defer] No integration test for morning-window + past-due-date intersection (both constraints active simultaneously) — deferred, 100% branch coverage confirmed; would be an enhancement not a gap

## Change Log

- 2026-03-31: Story 3.2 created — ready for dev
- 2026-03-31: Story 3.2 implemented — greedy-earliest algorithm, all 6 constraints, API service + route, 100% test coverage, status → review
