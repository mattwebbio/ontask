# Story 3.1: Scheduling Engine Foundation

Status: review

## Story

As a developer,
I want a pure, deterministic scheduling engine package with 100% test coverage enforced in CI,
So that scheduling logic is reliable, testable, and free of side effects from day one.

## Acceptance Criteria

1. **Given** `/packages/scheduling` is scaffolded **When** the package is complete **Then** the main export is `schedule(input: ScheduleInput): ScheduleOutput` — a pure function with no side effects, no external calls, and no randomness (ARCH-21)

2. **Given** the scheduling engine is called with any inputs **When** those exact inputs are provided again **Then** the output is bit-for-bit identical — determinism is an invariant, not a guideline (NFR-Q1)

3. **Given** a new test is added **When** the test naming convention is checked **Then** it follows the pattern `schedule_[constraint]_[condition]_[expected]` — e.g. `schedule_dueDate_taskOverdue_scheduledImmediately` (ARCH-22)

4. **Given** the CI pipeline runs `pnpm --filter @ontask/scheduling test --coverage` **When** line/function/branch/statement coverage for `src/**/*.ts` falls below 100% **Then** the build fails (ARCH-23) — this threshold is already configured in `vitest.config.ts`

## Tasks / Subtasks

- [x] Define `ScheduleInput` and `ScheduleOutput` types in `/packages/core` (AC: 1, 2)
  - [x] `packages/core/src/types/scheduling.ts` — NEW: define and export these types (see Dev Notes for full shape)
  - [x] `packages/core/src/types/index.ts` — MODIFY: re-export `ScheduleInput`, `ScheduleOutput`, `ScheduledBlock`, `CalendarEvent`, `TimeWindow`, `EnergyRequirement`

- [x] Scaffold the `packages/scheduling/src/` directory structure (AC: 1)
  - [x] `packages/scheduling/src/index.ts` — REPLACE stub export with real exports: `export { schedule } from './scheduler.js'` and `export { explain } from './explainer.js'`
  - [x] `packages/scheduling/src/scheduler.ts` — NEW: pure function `schedule(input: ScheduleInput): ScheduleOutput` — initially a minimal implementation that satisfies the type contract (may return empty `scheduledBlocks: []` for tasks with no slots available; logic added in Story 3.2)
  - [x] `packages/scheduling/src/explainer.ts` — NEW: `explain(input: ScheduleInput, output: ScheduleOutput): ExplainOutput` — stub returning empty `reasons: []` (full implementation in Story 3.6)
  - [x] `packages/scheduling/src/constraints/` — NEW directory with stub files:
    - `due-date.ts` — `applyDueDateConstraint(task, slots): slots` stub
    - `time-of-day.ts` — `applyTimeOfDayConstraint(task, slots): slots` stub
    - `energy-preferences.ts` — `applyEnergyPreferenceConstraint(task, slots): slots` stub
    - `calendar-events.ts` — `applyCalendarEventConstraint(events, slots): slots` stub
    - `dependencies.ts` — `applyDependencyConstraint(task, allTasks, slots): slots` stub (FR73)
    - `suggested-dates.ts` — `applySuggestedDateConstraint(suggested, slots): slots` stub (FR14)
  - [x] `packages/scheduling/src/strategies/` — NEW directory with stub files:
    - `round-robin.ts` — strategy stub (FR17)
    - `least-busy.ts` — strategy stub (FR17)
    - `ai-assisted.ts` — strategy stub (FR17)

- [x] Write tests achieving 100% coverage (AC: 3, 4)
  - [x] `packages/scheduling/src/test/scheduler.test.ts` — NEW: tests for `schedule()` covering:
    - `schedule_emptyInput_noTasks_returnsEmptyBlocks` — empty tasks array produces empty `scheduledBlocks`
    - `schedule_determinism_sameInput_identicalOutput` — call `schedule()` twice with identical input, assert deep equality
    - `schedule_dueDate_taskOverdue_scheduledImmediately` — task whose dueDate is in the past is included in output (not dropped)
    - At minimum one test per exported constraint file (can be trivial pass-through tests) — required to hit 100% branch/line coverage
  - [x] `packages/scheduling/src/test/explainer.test.ts` — NEW: tests for `explain()`:
    - `explain_emptyInput_returnsEmptyReasons` — stub returns `{ reasons: [] }`
  - [x] Remove the smoke-test placeholder in `packages/scheduling/src/index.test.ts` — move coverage to `src/test/` co-located tests (or rename `index.test.ts` to `test/index.test.ts`; see Dev Notes)
  - [x] Verify `pnpm --filter @ontask/scheduling test --coverage` passes locally before committing

- [x] Wire `@ontask/scheduling` dependency on `@ontask/core` (AC: 1)
  - [x] `packages/scheduling/package.json` — MODIFY: add `"dependencies": { "@ontask/core": "workspace:*" }` so `ScheduleInput`/`ScheduleOutput` types can be imported from `@ontask/core`
  - [x] `packages/scheduling/tsconfig.json` — verify path resolution works (should be automatic via `workspace:*` with pnpm)

## Dev Notes

### What This Story IS and IS NOT

**This story is the TDD scaffold**: types, pure-function skeleton, constraint stubs, 100% test coverage infrastructure. The actual scheduling algorithm (filling real slots from real calendar data) is Story 3.2. Do not implement the algorithm here — just the contracts.

The architecture doc explicitly states: _"8. `/packages/scheduling` — TDD-first, pure function, 100% coverage"_ as an ordered build step before Stripe integration and live activities.

### Type Definitions — `ScheduleInput` and `ScheduleOutput`

Types live in `/packages/core/src/types/scheduling.ts` (not in the scheduling package itself) to avoid circular dependencies. The architecture doc states: _"Types live in /packages/core to avoid circular dependencies."_

Recommended shape (inferred from architecture + task schema + FR coverage):

```typescript
// packages/core/src/types/scheduling.ts

export type TimeWindow = 'morning' | 'afternoon' | 'evening' | 'custom'
export type EnergyRequirement = 'high_focus' | 'low_energy' | 'flexible'

export interface ScheduleTask {
  id: string
  title: string
  dueDate?: Date
  estimatedDurationMinutes?: number
  timeWindow?: TimeWindow
  timeWindowStart?: string  // HH:mm, when timeWindow === 'custom'
  timeWindowEnd?: string    // HH:mm, when timeWindow === 'custom'
  energyRequirement?: EnergyRequirement
  priority?: 'normal' | 'high' | 'critical'
  dependsOnTaskIds?: string[]      // FR73 — task dependency constraints
  lockedStartTime?: Date           // FR8 — user manually pinned this slot
  suggestedDate?: Date             // FR14 — UI nudge (date picker / NLP pre-resolved)
}

export interface CalendarEvent {
  id: string
  startTime: Date
  endTime: Date
  isAllDay: boolean
}

export interface ScheduleInput {
  tasks: ScheduleTask[]
  calendarEvents: CalendarEvent[]  // merged from all providers — engine never knows which provider
  windowStart: Date                // scheduling horizon start (typically now)
  windowEnd: Date                  // scheduling horizon end (typically +14 days)
  suggestedDates?: Record<string, Date>  // taskId → suggested date (FR14 nudging)
}

export interface ScheduledBlock {
  taskId: string
  startTime: Date
  endTime: Date
  isLocked: boolean        // FR8 — manual override flag
  isAtRisk: boolean        // true if no valid slot found before due date
  constraintNotes?: string // optional: which constraints shaped this slot (for explainer)
}

export interface ScheduleOutput {
  scheduledBlocks: ScheduledBlock[]
  unscheduledTaskIds: string[]  // tasks that could not be placed in the window
  generatedAt: Date             // for determinism auditing — always set by caller, not by engine
}
```

**Critical**: `generatedAt` in `ScheduleOutput` must be supplied by the caller (the API service layer), not generated inside `schedule()`. The engine itself must not call `new Date()` or `Date.now()` — that would break determinism. The service layer at `apps/api/src/services/scheduling.ts` supplies this.

### Pure Function Contract

The only public exports from `packages/scheduling/src/index.ts`:

```typescript
export function schedule(input: ScheduleInput): ScheduleOutput
export function explain(input: ScheduleInput, output: ScheduleOutput): ExplainOutput
```

**Absolute prohibitions** (enforced by architecture rule and 100% test coverage):
- No `Math.random()` or `crypto.randomUUID()` inside the engine
- No `new Date()` or `Date.now()` inside the engine (use `input.windowStart` as "now")
- No `fetch()`, no database calls, no Cloudflare KV/Queue access
- No imports from `apps/` — only from `@ontask/core` and local `src/`
- No `console.log` in production code paths (tests may use it)

Architecture doc rule: _"Scheduling engine (`packages/scheduling`) is pure — no side effects, no external imports"_

### Test Naming Convention — ARCH-22

Every test description MUST follow: `schedule_[constraint]_[condition]_[expected]`

Examples from architecture doc:
- `schedule_dueDate_taskOverdue_scheduledImmediately`
- `schedule_timeConstraint_morningPin_respectsPin`

The constraint segment identifies which constraint module is being tested. The condition segment is the specific scenario. The expected segment is the outcome. This is the test suite as specification.

### Test File Location

Tests are co-located alongside source (not in `apps/flutter/test/`). The architecture doc states: _"`/packages/scheduling`: co-located tests, 100% coverage enforced in CI"_

Recommended layout:
```
packages/scheduling/src/
├── index.ts
├── scheduler.ts
├── explainer.ts
├── constraints/
│   ├── due-date.ts
│   ├── time-of-day.ts
│   ├── energy-preferences.ts
│   ├── calendar-events.ts
│   ├── dependencies.ts
│   └── suggested-dates.ts
├── strategies/
│   ├── round-robin.ts
│   ├── least-busy.ts
│   └── ai-assisted.ts
└── test/
    ├── scheduler.test.ts
    ├── explainer.test.ts
    ├── constraints/
    │   ├── due-date.test.ts
    │   ├── time-of-day.test.ts
    │   ├── energy-preferences.test.ts
    │   ├── calendar-events.test.ts
    │   ├── dependencies.test.ts
    │   └── suggested-dates.test.ts
    └── strategies/
        ├── round-robin.test.ts
        ├── least-busy.test.ts
        └── ai-assisted.test.ts
```

The current `src/index.test.ts` (smoke test) should either be moved to `src/test/index.test.ts` or deleted and replaced with proper tests. Do not leave it as a parallel file — vitest will include it in coverage.

### Coverage Gate — Already Configured

`vitest.config.ts` already has 100% thresholds set:
```typescript
thresholds: { lines: 100, functions: 100, branches: 100, statements: 100 }
```

CI job `scheduling-tests` runs `pnpm --filter @ontask/scheduling test --coverage`. The build will fail if coverage drops below 100%. **This means every stub file must have at least one test that exercises every branch.**

For stub files that export a pass-through function, a trivial test is acceptable:
```typescript
// constraints/due-date.test.ts
describe('applyDueDateConstraint', () => {
  it('schedule_dueDate_noSlots_returnsEmpty', () => {
    expect(applyDueDateConstraint({} as ScheduleTask, [])).toEqual([])
  })
})
```

### `packages/scheduling` Dependency on `@ontask/core`

After adding `@ontask/core` as a dependency, import types as:
```typescript
import type { ScheduleInput, ScheduleOutput } from '@ontask/core'
```

The `workspace:*` protocol in pnpm resolves this to the local package without publishing. No version pinning needed.

### Vitest Version

`vitest` is `^3.0.0` (already in `package.json`). Use vitest v3 API — notably:
- `describe`, `it`, `expect` from `'vitest'`
- `vi.fn()` for mocks (not `jest.fn()`)
- No `@jest/globals` import needed

### TypeScript Module Resolution

Root `tsconfig.base.json` uses `"module": "NodeNext"` and `"moduleResolution": "NodeNext"`. This requires `.js` extensions in all local imports even though the source files are `.ts`:

```typescript
// CORRECT
import { schedule } from './scheduler.js'

// WRONG — will cause import resolution errors
import { schedule } from './scheduler'
```

This is consistent with all other packages in the monorepo (`@ontask/core` uses `.js` extensions throughout).

### Nudging Architecture Note

The `suggestedDates` field in `ScheduleInput` is the engine's nudging interface (FR14). Architecture doc: _"Nudging is a UI concern, not an NLP concern. The scheduling engine is a pure function that accepts an optional `suggestedDates` parameter alongside its standard inputs."_ NLP pre-processing resolves natural language to structured dates before they reach the engine — the engine never sees text.

### Project Structure — No Flutter Changes

This story is entirely in the TypeScript monorepo packages. No Flutter files are modified. No Hono API routes are modified. The API service `apps/api/src/services/scheduling.ts` that calls `schedule()` is created in Story 3.2.

```
packages/
├── core/
│   └── src/
│       └── types/
│           └── scheduling.ts    ← NEW: ScheduleInput, ScheduleOutput types
└── scheduling/
    ├── package.json             ← MODIFY: add @ontask/core dependency
    └── src/
        ├── index.ts             ← REPLACE stub with real exports
        ├── scheduler.ts         ← NEW: schedule() pure function
        ├── explainer.ts         ← NEW: explain() stub
        ├── constraints/         ← NEW: 6 constraint stub files
        ├── strategies/          ← NEW: 3 strategy stub files
        └── test/                ← NEW: co-located test files
```

### References

- Scheduling engine architecture: `_bmad-output/planning-artifacts/architecture.md` §"Scheduling Engine Interface"
- Package layout: `_bmad-output/planning-artifacts/architecture.md` §"`packages/scheduling/` — Scheduling Engine"
- NFR-Q1 (determinism): `_bmad-output/planning-artifacts/prd.md` §"Quality & Correctness"
- ARCH-21/22/23: Epic 3 story requirements, `_bmad-output/planning-artifacts/epics.md` §"Story 3.1"
- CI coverage gate: `.github/workflows/ci.yml` job `scheduling-tests`
- Coverage thresholds: `packages/scheduling/vitest.config.ts`
- Task schema (for ScheduleTask field names): `packages/core/src/schema/tasks.ts`
- Existing core type exports: `packages/core/src/types/index.ts`
- Monorepo root tooling: `package.json` (pnpm 10.33.0, node >=20)
- tsconfig base: `tsconfig.base.json` (NodeNext module resolution — use `.js` extensions in imports)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_No blocking issues encountered._

### Completion Notes List

- Created `packages/core/src/types/scheduling.ts` with full type definitions: `TimeWindow`, `EnergyRequirement`, `ScheduleTask`, `CalendarEvent`, `ScheduleInput`, `ScheduledBlock`, `ScheduleOutput`, `ExplainOutput`. All types follow the recommended shape from Dev Notes exactly.
- Updated `packages/core/src/types/index.ts` to re-export all 8 new scheduling types.
- Replaced the stub `packages/scheduling/src/index.ts` with real exports for `schedule` and `explain` using `.js` extensions (NodeNext module resolution).
- Created `packages/scheduling/src/scheduler.ts`: pure function returning empty `scheduledBlocks` and all task IDs in `unscheduledTaskIds`. `generatedAt` is set from `input.windowStart` — engine never calls `new Date()`, preserving determinism.
- Created `packages/scheduling/src/explainer.ts`: stub returning `{ reasons: [] }`.
- Created 6 constraint stubs under `packages/scheduling/src/constraints/`: `due-date.ts`, `time-of-day.ts`, `energy-preferences.ts`, `calendar-events.ts`, `dependencies.ts`, `suggested-dates.ts`. All are pure pass-through functions.
- Created 3 strategy stubs under `packages/scheduling/src/strategies/`: `round-robin.ts`, `least-busy.ts`, `ai-assisted.ts`.
- Deleted old smoke-test `packages/scheduling/src/index.test.ts` and replaced with a structured test suite under `src/test/`.
- Created 12 test files (28 tests total) covering all source files, achieving 100% line/function/branch/statement coverage.
- Added `@ontask/core: workspace:*` dependency to `packages/scheduling/package.json`. TypeScript resolution verified via `pnpm typecheck` (no errors).
- `pnpm --filter @ontask/scheduling test --coverage` passes: 12 test files, 28 tests, 100% coverage across all metrics.

### File List

- `packages/core/src/types/scheduling.ts` — NEW
- `packages/core/src/types/index.ts` — MODIFIED
- `packages/scheduling/package.json` — MODIFIED
- `packages/scheduling/src/index.ts` — MODIFIED
- `packages/scheduling/src/scheduler.ts` — NEW
- `packages/scheduling/src/explainer.ts` — NEW
- `packages/scheduling/src/constraints/due-date.ts` — NEW
- `packages/scheduling/src/constraints/time-of-day.ts` — NEW
- `packages/scheduling/src/constraints/energy-preferences.ts` — NEW
- `packages/scheduling/src/constraints/calendar-events.ts` — NEW
- `packages/scheduling/src/constraints/dependencies.ts` — NEW
- `packages/scheduling/src/constraints/suggested-dates.ts` — NEW
- `packages/scheduling/src/strategies/round-robin.ts` — NEW
- `packages/scheduling/src/strategies/least-busy.ts` — NEW
- `packages/scheduling/src/strategies/ai-assisted.ts` — NEW
- `packages/scheduling/src/index.test.ts` — DELETED
- `packages/scheduling/src/test/index.test.ts` — NEW
- `packages/scheduling/src/test/scheduler.test.ts` — NEW
- `packages/scheduling/src/test/explainer.test.ts` — NEW
- `packages/scheduling/src/test/constraints/due-date.test.ts` — NEW
- `packages/scheduling/src/test/constraints/time-of-day.test.ts` — NEW
- `packages/scheduling/src/test/constraints/energy-preferences.test.ts` — NEW
- `packages/scheduling/src/test/constraints/calendar-events.test.ts` — NEW
- `packages/scheduling/src/test/constraints/dependencies.test.ts` — NEW
- `packages/scheduling/src/test/constraints/suggested-dates.test.ts` — NEW
- `packages/scheduling/src/test/strategies/round-robin.test.ts` — NEW
- `packages/scheduling/src/test/strategies/least-busy.test.ts` — NEW
- `packages/scheduling/src/test/strategies/ai-assisted.test.ts` — NEW

## Change Log

- 2026-03-31: Story 3.1 implemented — scheduling engine foundation scaffolded with types in @ontask/core, pure function schedule()/explain() stubs, 6 constraint stubs, 3 strategy stubs, 12 test files achieving 100% coverage, @ontask/core workspace dependency wired.
