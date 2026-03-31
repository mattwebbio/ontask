# Story 2.2: Task Properties — Scheduling Hints

Status: review

## Story

As a user,
I want to set time-of-day constraints, energy requirements, and priority on my tasks,
So that the scheduler places them in the right windows and I can signal what matters most.

## Acceptance Criteria

1. **Given** a task is being created or edited, **When** the user sets a time-of-day constraint, **Then** they can pin the task to a specific time window: morning, afternoon, evening, or a custom time range (FR4) **And** the constraint is stored and respected by the scheduling engine.

2. **Given** a user has configured energy availability preferences in onboarding or settings, **When** they set an energy requirement on a task, **Then** available options are: high focus, low energy, flexible **And** the scheduling engine places high-focus tasks only in the user's declared peak hours (FR5).

3. **Given** a task exists, **When** the user sets priority, **Then** they can assign urgency: normal, high, or critical — independent of due date (FR68) **And** higher-priority tasks are surfaced earlier in scheduling within available constraints.

## Tasks / Subtasks

- [x] Add scheduling hint columns to `tasksTable` Drizzle schema (AC: 1, 2, 3)
  - [x] `packages/core/src/schema/tasks.ts` — add three new columns to `tasksTable`:
    - `timeWindow` (text, nullable) — enum-like: `'morning'`, `'afternoon'`, `'evening'`, `'custom'`
    - `timeWindowStart` (text, nullable) — HH:mm format, only used when `timeWindow = 'custom'`
    - `timeWindowEnd` (text, nullable) — HH:mm format, only used when `timeWindow = 'custom'`
    - `energyRequirement` (text, nullable) — enum-like: `'high_focus'`, `'low_energy'`, `'flexible'`
    - `priority` (text, nullable) — enum-like: `'normal'`, `'high'`, `'critical'`; default `'normal'`
  - [x] Generate Drizzle migration: `pnpm drizzle-kit generate` from `apps/api/`

- [x] Update API schemas and stub responses in `apps/api/src/routes/tasks.ts` (AC: 1, 2, 3)
  - [x] Add `timeWindow`, `timeWindowStart`, `timeWindowEnd`, `energyRequirement`, `priority` to `createTaskSchema`, `updateTaskSchema`, and `taskSchema`
  - [x] Use `z.enum()` for the constrained values:
    - `timeWindow`: `z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable().optional()`
    - `energyRequirement`: `z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional()`
    - `priority`: `z.enum(['normal', 'high', 'critical']).nullable().optional()`
  - [x] Update `stubTask()` to include the new fields (all defaulting to `null` except priority defaults to `'normal'`)
  - [x] Stub handlers: echo submitted values back (same pattern as existing fields)

- [x] Update Flutter domain model (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/domain/task.dart` — add fields to `Task` freezed class:
    - `TimeWindow? timeWindow` (new enum)
    - `String? timeWindowStart` (HH:mm)
    - `String? timeWindowEnd` (HH:mm)
    - `EnergyRequirement? energyRequirement` (new enum)
    - `TaskPriority? priority` (new enum, defaults to `TaskPriority.normal`)
  - [x] Create `apps/flutter/lib/features/tasks/domain/time_window.dart` — `enum TimeWindow { morning, afternoon, evening, custom }` with `fromJson`/`toJson` helpers
  - [x] Create `apps/flutter/lib/features/tasks/domain/energy_requirement.dart` — `enum EnergyRequirement { highFocus, lowEnergy, flexible }` with `fromJson`/`toJson` helpers (JSON values: `high_focus`, `low_energy`, `flexible`)
  - [x] Create `apps/flutter/lib/features/tasks/domain/task_priority.dart` — `enum TaskPriority { normal, high, critical }` with `fromJson`/`toJson` helpers
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Update Flutter DTO (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/data/task_dto.dart` — add `timeWindow`, `timeWindowStart`, `timeWindowEnd`, `energyRequirement`, `priority` as nullable strings; update `toDomain()` to parse enums
  - [x] Run build_runner to regenerate `.freezed.dart` and `.g.dart`

- [x] Update `TasksRepository` (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/data/tasks_repository.dart` — add `timeWindow`, `timeWindowStart`, `timeWindowEnd`, `energyRequirement`, `priority` parameters to `createTask()` method; include in POST body when non-null

- [x] Update `TasksNotifier` (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart` — add the new parameters to `createTask()` and pass through to repository

- [x] Add scheduling hint pickers to Add Tab Sheet (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart` — add three new picker rows below the list picker:
    - **Time window picker**: icon `CupertinoIcons.clock`, shows `CupertinoActionSheet` with morning/afternoon/evening/custom options; if custom, show secondary time range picker
    - **Energy requirement picker**: icon `CupertinoIcons.bolt`, shows `CupertinoActionSheet` with high focus/low energy/flexible options
    - **Priority picker**: icon `CupertinoIcons.flag`, shows `CupertinoActionSheet` with normal/high/critical options
  - [x] Pass selected values to `TasksNotifier.createTask()`
  - [x] Add new state variables: `TimeWindow? _timeWindow`, `String? _timeWindowStart`, `String? _timeWindowEnd`, `EnergyRequirement? _energyRequirement`, `TaskPriority? _priority`

- [x] Add scheduling hint editing to inline editor (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — add three new picker rows below the due date row:
    - Time window picker (same UX as Add Tab)
    - Energy requirement picker (same UX as Add Tab)
    - Priority picker (same UX as Add Tab)
  - [x] Changes auto-save via debounced `_onFieldChanged()` (existing pattern)

- [x] Add scheduling hint display to task row (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` — show compact badges/icons for non-default scheduling hints:
    - Priority: show colored flag icon for high (amber) and critical (red); hide for normal
    - Time window: show clock icon with label if set
    - Energy: show bolt icon with label if set
  - [x] Badges should use theme text styles (Dynamic Type compliant, NFR-A3)

- [x] Add strings to `AppStrings` (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` — add all new string constants:
    - `taskTimeWindowLabel`, `taskTimeWindowMorning`, `taskTimeWindowAfternoon`, `taskTimeWindowEvening`, `taskTimeWindowCustom`
    - `taskTimeWindowCustomStart`, `taskTimeWindowCustomEnd`
    - `taskEnergyLabel`, `taskEnergyHighFocus`, `taskEnergyLowEnergy`, `taskEnergyFlexible`
    - `taskPriorityLabel`, `taskPriorityNormal`, `taskPriorityHigh`, `taskPriorityCritical`

- [x] Write tests (AC: 1, 2, 3)
  - [x] `apps/api/test/routes/tasks.test.ts` — update existing task tests:
    - POST /v1/tasks: verify new fields accepted and echoed back
    - PATCH /v1/tasks/:id: verify partial update of scheduling hint fields
    - GET /v1/tasks: verify response includes new fields
  - [x] `apps/flutter/test/features/tasks/task_scheduling_hints_test.dart` — new test file:
    - AddTabSheet: verify time window picker shows/selects options
    - AddTabSheet: verify energy requirement picker shows/selects options
    - AddTabSheet: verify priority picker shows/selects options
    - AddTabSheet: verify custom time range shows start/end pickers when custom selected
    - AddTabSheet: verify createTask called with scheduling hint params
    - TaskEditInline: verify scheduling hint pickers appear
    - TaskEditInline: verify updateTask called with changed hint fields
    - TaskRow: verify priority badge appears for high/critical, hidden for normal
    - TaskRow: verify time window badge appears when set
    - TaskRow: verify energy badge appears when set

### Review Findings

- [ ] [Review][Patch] Debounce bug: `_onFieldChanged` in TaskEditInline custom time range loses `timeWindowStart` — second call cancels first timer [apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart:170-171]
- [ ] [Review][Patch] Inline editor does not clear `timeWindowStart`/`timeWindowEnd` when switching away from custom time window [apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart:107,116]
- [ ] [Review][Patch] Custom time range labels missing explicit theme color (`copyWith(color: ...)`) unlike all other text in file [apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart:235,251] [apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart:181,196]
- [ ] [Review][Patch] Custom time range picker ignores existing task values — always initializes to 09:00-11:00 instead of reading `timeWindowStart`/`timeWindowEnd` [apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart:150-151]
- [x] [Review][Defer] `lists_provider.g.dart` hash changed without lists code changes — build_runner regeneration side-effect — deferred, pre-existing

## Dev Notes

### Enum Strategy — Text Columns with Application-Level Validation

Use text columns (not Postgres ENUM types) for `timeWindow`, `energyRequirement`, and `priority`. This matches the existing codebase pattern (no Postgres ENUMs used anywhere). Validation happens at three levels:
1. **API layer**: Zod `z.enum()` rejects invalid values at the request boundary
2. **Flutter layer**: Dart enums with `fromJson` factory methods
3. **Database**: Text columns — no migration needed when adding new enum values later

### Time Window — Preset vs Custom

The four preset windows (morning, afternoon, evening) are user-facing labels. The scheduling engine (Epic 3) will map them to concrete time ranges using the user's energy preferences. For this story, only store the constraint — the scheduling engine is not built yet.

Custom time ranges use `timeWindowStart` and `timeWindowEnd` as `HH:mm` strings (not full timestamps). These are stored as text. When `timeWindow = 'custom'`, both start and end must be provided. When `timeWindow` is a preset or null, start/end are ignored.

### Priority vs Due Date — Independent Dimensions

Priority (normal/high/critical) is independent of due date per FR68. A task with no due date can still be critical. A task due tomorrow can still be normal priority. The scheduling engine (Epic 3) uses priority as a tiebreaker when multiple tasks compete for the same time slot.

### Energy Requirement — Server-Side Matching Deferred

The energy requirement on a task (`high_focus`, `low_energy`, `flexible`) pairs with the user's energy availability preferences configured during onboarding (Story 1.9). The actual matching logic (placing high-focus tasks in peak hours) is the scheduling engine's job (Story 3.2). This story only stores the constraint on the task.

### Custom Time Range Picker UX

When the user selects "Custom" in the time window picker, show a secondary modal with two `CupertinoDatePicker` widgets in `CupertinoDatePickerMode.time` mode — one for start time, one for end time. Use the same modal popup pattern established in `_showDatePicker()`.

### API Field Naming Convention

The API uses `snake_case` for JSON field names matching the DB column naming convention. Dart/Flutter DTOs use `camelCase` and rely on `json_serializable` `@JsonKey(name: ...)` when the names differ. However, the existing codebase uses `camelCase` in JSON responses (see `taskSchema` — `dueDate`, `listId`, etc.). Follow this existing pattern: use `camelCase` in Zod schemas and API responses. The Drizzle `casing: 'camelCase'` config handles the DB-to-API mapping.

### Backwards Compatibility

All new fields are nullable/optional. Existing tasks will have `null` for all scheduling hint fields. Existing API consumers and Flutter code will continue to work — the new fields are additive only.

### Project Structure Notes

No new files except enums and test file. All changes extend existing files.

```
packages/
└── core/
    └── src/
        └── schema/
            └── tasks.ts                     ← MODIFY: add 5 new columns

apps/
├── api/
│   └── src/
│       └── routes/
│           └── tasks.ts                     ← MODIFY: update schemas and stubs
│   └── test/
│       └── routes/
│           └── tasks.test.ts                ← MODIFY: add scheduling hint test cases
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart             ← MODIFY: add scheduling hint strings
    │   └── features/
    │       └── tasks/
    │           ├── data/
    │           │   ├── task_dto.dart         ← MODIFY: add new fields
    │           │   ├── task_dto.freezed.dart ← REGENERATE
    │           │   ├── task_dto.g.dart       ← REGENERATE
    │           │   └── tasks_repository.dart ← MODIFY: add params to createTask()
    │           ├── domain/
    │           │   ├── task.dart             ← MODIFY: add scheduling hint fields
    │           │   ├── task.freezed.dart     ← REGENERATE
    │           │   ├── time_window.dart      ← NEW: TimeWindow enum
    │           │   ├── energy_requirement.dart ← NEW: EnergyRequirement enum
    │           │   └── task_priority.dart    ← NEW: TaskPriority enum
    │           └── presentation/
    │               ├── tasks_provider.dart   ← MODIFY: add params to createTask()
    │               ├── tasks_provider.g.dart ← REGENERATE
    │               └── widgets/
    │                   ├── task_row.dart          ← MODIFY: add badges
    │                   └── task_edit_inline.dart   ← MODIFY: add pickers
    └── test/
        └── features/
            └── tasks/
                └── task_scheduling_hints_test.dart ← NEW
```

### References

- Story 2.2 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` — Story 2.2, line ~854]
- FR4 (time-of-day constraints): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~29]
- FR5 (energy/context preferences): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~30]
- FR68 (task priority independent of due date): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~39]
- Architecture: scheduling engine constraints layout: [Source: `_bmad-output/planning-artifacts/architecture.md` — lines ~968–975]
- Architecture: task property conflict resolution: [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~188]
- UX: energy preferences in settings: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — lines ~276–278]
- UX: Add tab parameter slots (duration, due date, list, energy): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — lines ~826, ~848]
- Existing Drizzle schema: `packages/core/src/schema/tasks.ts`
- Existing API routes: `apps/api/src/routes/tasks.ts`
- Existing Flutter domain model: `apps/flutter/lib/features/tasks/domain/task.dart`
- Existing DTO: `apps/flutter/lib/features/tasks/data/task_dto.dart`
- Existing repository: `apps/flutter/lib/features/tasks/data/tasks_repository.dart`
- Existing provider: `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart`
- Existing task edit inline: `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart`
- Existing task row: `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`
- Existing Add tab sheet: `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart`
- Existing strings: `apps/flutter/lib/core/l10n/strings.dart`

### Previous Story Learnings (from Stories 1.1–2.1)

- **`valueOrNull` vs `.value`**: Riverpod v3 uses `.value` on `AsyncValue`, NOT `.valueOrNull`. Use `ref.watch(provider).value ?? defaultValue` in widget builders.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests that touch any provider reading `SharedPreferences` or `FlutterSecureStorage` at build time.
- **`ProviderContainer` for unit testing providers**: Use `ProviderContainer` with `overrides` for provider logic tests. Never `WidgetTester` alone for business logic.
- **`ref.read(apiClientProvider)` — never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection.
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **`@Riverpod(keepAlive: true)` for long-lived notifiers**: Task/list notifiers should NOT use `keepAlive` — they are per-screen state.
- **Test baseline after Story 2.1**: 244 Flutter tests + 28 API tests pass. All must continue passing.
- **No Material widgets**: Use `CupertinoTextField`, `CupertinoButton`, `CupertinoDatePicker`, `CupertinoAlertDialog`. Never `TextField`, `ElevatedButton`, `AlertDialog`, `ListTile`.
- **All strings in `AppStrings`**: Never inline string literals. Warm narrative voice (UX-DR32, UX-DR36).
- **Widget tests — override providers in `ProviderScope(overrides: [...])`**: Never rely on real network calls or real `SharedPreferences` in widget tests.
- **Hono route additions — no untyped routes**: `@hono/zod-openapi` schemas for all new routes.
- **`ok()` / `list()` / `err()` helpers from `apps/api/src/lib/response.ts`**: Same envelope for all responses.
- **Riverpod v3 restriction**: `provider.notifier` cannot be called when provider is overridden with `overrideWithValue`. Use fake class extension pattern in tests.
- **`freezed` union types go in `domain/`**: Domain models and sealed types live in `domain/`, never in `data/`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible(...)` before tap when widgets are below the fold.
- **Zod v4 UUID validation requires RFC-4122 compliant UUIDs** (variant bits must be [89ab] in position 1 of 4th group). Use `a0000000-0000-4000-8000-000000000001` style in test fixtures.
- **Riverpod v4 generates provider names without "Notifier" suffix** (e.g., `tasksProvider` not `tasksNotifierProvider`).
- **`CupertinoSlidingSegmentedControl` generic type param cannot be nullable** — use `CupertinoActionSheet` for option pickers instead.
- **Drizzle Kit requires `casing: 'snake_case'`** in drizzle.config.ts to generate snake_case SQL columns from camelCase TS schema fields.

### Debug Log References

(Carried forward from Story 2.1 — same codebase patterns apply)
- Zod v4 UUID validation requires RFC-4122 compliant UUIDs (variant bits must be [89ab] in position 1 of 4th group).
- Riverpod v4 generates provider names without "Notifier" suffix.
- `CupertinoSlidingSegmentedControl` generic type param cannot be nullable — use `CupertinoActionSheet`.
- Drizzle Kit requires `casing: 'snake_case'` in drizzle.config.ts.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| Time-of-day constraint options | morning, afternoon, evening, custom (with time range) | FR4, AC #1 |
| Energy requirement options | high focus, low energy, flexible | FR5, AC #2 |
| Priority options | normal, high, critical | FR68, AC #3 |
| Priority independent of due date | Priority is not derived from due date — separate dimension | FR68, AC #3 |
| Inline editing | All new properties editable inline; auto-save, no save button | FR58 (from Story 2.1) |
| No Material widgets | Cupertino only | Stories 1.5–2.1 pattern |
| No inline strings | All copy in `AppStrings` | Stories 1.6–2.1 pattern |
| Dynamic Type | All text uses theme text styles; no hardcoded sizes | NFR-A3, UX-DR22 |
| Warm narrative voice | Copy follows "past self / future self" voice | UX-DR32, UX-DR36 |

### Scope Boundaries — What This Story Does NOT Include

- **Scheduling engine** — storing constraints only; no scheduling logic (Epic 3)
- **Energy preferences setup/management in settings** — configured in onboarding (Story 1.9); this story reads them for context but does not add settings UI
- **NLP/natural language task capture** (FR1b) — Story 4.1
- **Recurring tasks** (FR7) — Story 2.3
- **Templates** (FR78) — Story 2.4
- **Dependencies** (FR73) — Story 2.5
- **Bulk operations** (FR74) — Story 2.5
- **Task search/filter** (FR56) — Story 2.9
- **Offline sync** — not wired in this story

### Deferred Issues from Previous Stories

- **TimeOfDay formatting duplication** (from Story 1.9): This story introduces custom time range pickers. If the `_formatTime()` pattern is needed, extract to `apps/flutter/lib/core/utils/time_format.dart` rather than duplicating.

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

- Drizzle-kit not on PATH in pnpm workspace — used full path via `packages/core/node_modules/.bin/drizzle-kit`

### Completion Notes List

- Added 5 new columns to Drizzle schema: timeWindow, timeWindowStart, timeWindowEnd, energyRequirement, priority
- Generated migration 0001_yummy_randall_flagg.sql with snake_case columns via `casing: 'snake_case'` config
- Updated all 3 Zod schemas (create/update/task) with z.enum() validation for constrained values
- Updated stubTask() to include new fields; POST handler echoes submitted scheduling hints
- Created 3 new Flutter enums: TimeWindow, EnergyRequirement, TaskPriority with fromJson/toJson helpers
- Updated Task freezed class, TaskDto, toDomain() mapping
- Updated TasksRepository.createTask() and TasksNotifier.createTask() with new parameters
- Added 3 CupertinoActionSheet pickers to AddTabSheet (time window, energy, priority) with Custom time range sub-picker
- Added 3 CupertinoActionSheet pickers to TaskEditInline with debounced auto-save
- Added scheduling hint badges to TaskRow: colored flag for high/critical priority, clock for time window, bolt for energy
- Added 16 new string constants to AppStrings
- 6 new API tests, 22 new Flutter tests — all pass
- Full regression suite: 34 API tests + 266 Flutter tests = 300 total, 0 failures

### File List

- packages/core/src/schema/tasks.ts (MODIFIED)
- packages/core/src/schema/migrations/0001_yummy_randall_flagg.sql (NEW)
- apps/api/src/routes/tasks.ts (MODIFIED)
- apps/api/test/routes/tasks.test.ts (MODIFIED)
- apps/flutter/lib/features/tasks/domain/time_window.dart (NEW)
- apps/flutter/lib/features/tasks/domain/energy_requirement.dart (NEW)
- apps/flutter/lib/features/tasks/domain/task_priority.dart (NEW)
- apps/flutter/lib/features/tasks/domain/task.dart (MODIFIED)
- apps/flutter/lib/features/tasks/domain/task.freezed.dart (REGENERATED)
- apps/flutter/lib/features/tasks/data/task_dto.dart (MODIFIED)
- apps/flutter/lib/features/tasks/data/task_dto.freezed.dart (REGENERATED)
- apps/flutter/lib/features/tasks/data/task_dto.g.dart (REGENERATED)
- apps/flutter/lib/features/tasks/data/tasks_repository.dart (MODIFIED)
- apps/flutter/lib/features/tasks/presentation/tasks_provider.dart (MODIFIED)
- apps/flutter/lib/features/tasks/presentation/tasks_provider.g.dart (REGENERATED)
- apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart (MODIFIED)
- apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart (MODIFIED)
- apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart (MODIFIED)
- apps/flutter/lib/core/l10n/strings.dart (MODIFIED)
- apps/flutter/test/features/tasks/task_scheduling_hints_test.dart (NEW)

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-30 | 1.0 | claude-opus-4-6 | Story 2.2 created — scheduling hints (time-of-day, energy, priority) added to task model across Drizzle schema, API routes, Flutter domain/DTO/repository/provider, creation and inline editing UI, task row badges. |
| 2026-03-30 | 1.1 | claude-opus-4-6 | Story 2.2 implemented — all tasks complete, 6 API tests + 22 Flutter tests added, full regression pass (300 tests). |
