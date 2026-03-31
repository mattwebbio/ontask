# Story 2.3: Recurring Tasks

Status: review

## Story

As a user,
I want to create recurring tasks with full feature parity to one-off tasks,
So that I can track regular commitments — including staking money on habits — the same way I track everything else.

## Acceptance Criteria

1. **Given** the user creates a task, **When** they set a recurrence schedule, **Then** available options are: daily, weekly (with day-of-week selection), monthly, and custom interval (FR7) **And** completing a recurring task instance generates the next instance automatically.

2. **Given** a recurring task exists, **When** the user edits it, **Then** they are offered: edit this instance only, or edit this and all future instances **And** editing a single instance does not affect other instances.

3. **Given** a recurring task is staked, **When** the task recurs, **Then** each new instance carries the same stake, charity, and proof settings as the original (full feature parity) **And** each instance is independently charged or verified on its own deadline.

## Tasks / Subtasks

- [x] Add recurrence columns to `tasksTable` Drizzle schema (AC: 1, 2)
  - [x] `packages/core/src/schema/tasks.ts` — add columns:
    - `recurrenceRule` (text, nullable) — enum-like: `'daily'`, `'weekly'`, `'monthly'`, `'custom'`
    - `recurrenceInterval` (integer, nullable) — for custom interval: number of days between occurrences
    - `recurrenceDaysOfWeek` (text, nullable) — JSON array string of ISO day numbers `[1,2,5]` (Mon=1..Sun=7); used when `recurrenceRule = 'weekly'`
    - `recurrenceParentId` (uuid, nullable) — self-reference to the original recurring task (the "series parent"); null for the parent itself and for non-recurring tasks
  - [x] Generate Drizzle migration: run `./node_modules/.bin/drizzle-kit generate` from `apps/api/` (full path — drizzle-kit not on global PATH)

- [x] Update API schemas and stub responses in `apps/api/src/routes/tasks.ts` (AC: 1, 2, 3)
  - [x] Add `recurrenceRule`, `recurrenceInterval`, `recurrenceDaysOfWeek`, `recurrenceParentId` to `createTaskSchema`, `updateTaskSchema`, and `taskSchema`
  - [x] Use `z.enum()` for `recurrenceRule`: `z.enum(['daily', 'weekly', 'monthly', 'custom']).nullable().optional()`
  - [x] `recurrenceInterval`: `z.number().int().min(1).nullable().optional()`
  - [x] `recurrenceDaysOfWeek`: `z.string().nullable().optional()` (JSON array string; validated at application level)
  - [x] `recurrenceParentId`: `z.string().uuid().nullable().optional()`
  - [x] Update `stubTask()` to include all new fields defaulting to `null`
  - [x] Stub handlers: echo submitted recurrence values back (same pattern as scheduling hints)
  - [x] Add `POST /v1/tasks/:id/complete` route — stub that sets `completedAt = now()` and if `recurrenceRule` is set, returns both the completed task and the auto-generated next instance in the response
  - [x] Stub next-instance generation: copy all properties from completed task, compute next `dueDate` based on `recurrenceRule`/`recurrenceInterval`/`recurrenceDaysOfWeek`, set `recurrenceParentId` to the series parent, clear `completedAt`

- [x] Update Flutter domain model (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/domain/recurrence_rule.dart` — NEW: `enum RecurrenceRule { daily, weekly, monthly, custom }` with `fromJson`/`toJson` helpers (JSON values: `daily`, `weekly`, `monthly`, `custom`)
  - [x] `apps/flutter/lib/features/tasks/domain/task.dart` — add fields:
    - `RecurrenceRule? recurrenceRule`
    - `int? recurrenceInterval`
    - `List<int>? recurrenceDaysOfWeek` (parsed from JSON string)
    - `String? recurrenceParentId`
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Update Flutter DTO (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/data/task_dto.dart` — add `recurrenceRule`, `recurrenceInterval`, `recurrenceDaysOfWeek` (as nullable String — JSON array), `recurrenceParentId` as nullable strings; update `toDomain()` to parse `RecurrenceRule` enum and decode `recurrenceDaysOfWeek` JSON string to `List<int>`
  - [x] Run build_runner to regenerate `.freezed.dart` and `.g.dart`

- [x] Update `TasksRepository` (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/data/tasks_repository.dart` — add `recurrenceRule`, `recurrenceInterval`, `recurrenceDaysOfWeek`, `recurrenceParentId` parameters to `createTask()` method; include in POST body when non-null
  - [x] Add `completeTask(String id)` method: POST to `/v1/tasks/:id/complete`; parse response containing both completed task and (optionally) next instance; return `({Task completed, Task? nextInstance})`

- [x] Update `TasksNotifier` (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart` — add recurrence parameters to `createTask()` and pass through to repository
  - [x] Add `completeTask(String id)` method: call `repo.completeTask(id)`, update state — replace completed task with updated version, insert new next instance if returned

- [x] Add recurrence picker to Add Tab Sheet (AC: 1)
  - [x] `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart` — add recurrence picker row below existing pickers:
    - Icon `CupertinoIcons.repeat`, label from `AppStrings`
    - Tapping shows `CupertinoActionSheet` with: None, Daily, Weekly, Monthly, Custom
    - If Weekly selected: show secondary `CupertinoActionSheet` for day-of-week multi-select (Mon–Sun toggles)
    - If Custom selected: show number picker for interval (days)
  - [x] Add state variables: `RecurrenceRule? _recurrenceRule`, `int? _recurrenceInterval`, `List<int>? _recurrenceDaysOfWeek`
  - [x] Pass selected values to `TasksNotifier.createTask()`

- [x] Add recurrence picker to inline editor (AC: 1, 2)
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — add recurrence picker row below priority picker (same UX as Add Tab)
  - [x] Changes auto-save via debounced `_onFieldChanged()` (existing pattern)
  - [x] When editing a recurring task: show "Edit this instance" / "Edit this and all future" choice via `CupertinoActionSheet` before applying changes (AC #2)

- [x] Add recurrence badge to task row (AC: 1)
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` — show `CupertinoIcons.repeat` badge when `task.recurrenceRule != null`; display frequency label (Daily, Weekly, Monthly, Every N days)

- [x] Add task completion with next-instance generation (AC: 1, 3)
  - [x] Update the task completion flow (wherever the checkbox/swipe-to-complete action is wired): for recurring tasks, call `completeTask()` instead of `updateTask()` with `completedAt`; optimistically insert the next instance into the list

- [x] Add strings to `AppStrings` (AC: 1, 2)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` — add all new string constants:
    - `taskRecurrenceLabel` = `'Repeats'`
    - `taskRecurrenceDaily` = `'Daily'`
    - `taskRecurrenceWeekly` = `'Weekly'`
    - `taskRecurrenceMonthly` = `'Monthly'`
    - `taskRecurrenceCustom` = `'Custom interval'`
    - `taskRecurrenceCustomDaysLabel` = `'Every how many days?'`
    - `taskRecurrenceWeeklyDaysLabel` = `'Which days?'`
    - `taskRecurrenceEditThisInstance` = `'Edit this task only'`
    - `taskRecurrenceEditAllFuture` = `'Edit this and all future tasks'`
    - `taskRecurrenceEditChoiceTitle` = `'This is a recurring task'`
    - Day-of-week labels: `taskDayMonday` through `taskDaySunday`

- [x] Write tests (AC: 1, 2, 3)
  - [x] `apps/api/test/routes/tasks.test.ts` — update existing task tests:
    - POST /v1/tasks: verify recurrence fields accepted and echoed back
    - POST /v1/tasks/:id/complete: verify completedAt set, next instance returned for recurring task, no next instance for non-recurring task
    - PATCH /v1/tasks/:id: verify partial update of recurrence fields
    - GET /v1/tasks: verify response includes recurrence fields
  - [x] `apps/flutter/test/features/tasks/task_recurrence_test.dart` — new test file:
    - AddTabSheet: verify recurrence picker shows/selects options
    - AddTabSheet: verify weekly day-of-week picker appears when weekly selected
    - AddTabSheet: verify custom interval picker appears when custom selected
    - AddTabSheet: verify createTask called with recurrence params
    - TaskEditInline: verify recurrence picker appears
    - TaskEditInline: verify "edit this instance" / "edit all future" choice shown for recurring tasks
    - TaskRow: verify repeat badge appears when recurrenceRule set
    - TaskRow: verify repeat badge hidden when recurrenceRule is null
    - Complete task: verify next instance generated for recurring task
    - RecurrenceRule enum: verify fromJson/toJson round-trip

### Review Findings

(Populated during code review)

## Dev Notes

### Data Model Design — Series Parent Pattern

Recurring tasks use a **series parent** pattern:
- The first task created with a `recurrenceRule` is the **series parent** (`recurrenceParentId = null`, `recurrenceRule` is set).
- When a recurring task is completed, the system generates the **next instance**: a new task row with `recurrenceParentId` pointing to the series parent (or the same parent the completed task pointed to).
- Each instance is an independent row in `tasksTable` — it has its own `id`, `dueDate`, `completedAt`, etc.
- This design supports AC #2 (edit this instance only) naturally: each instance is a separate row. "Edit all future" requires finding tasks where `recurrenceParentId = series_parent_id AND completedAt IS NULL` and updating them (stub for now — real query in Epic 3).

### Recurrence Rule — Next Due Date Computation

The `POST /v1/tasks/:id/complete` stub computes the next due date:
- **daily**: `dueDate + 1 day`
- **weekly**: next occurrence of the earliest selected day-of-week on or after `dueDate + 1 day`
- **monthly**: `dueDate + 1 month` (same day-of-month; clamp to month end if needed)
- **custom**: `dueDate + recurrenceInterval days`

If the completed task has no `dueDate`, the next instance's `dueDate` is computed from `now()` using the same rules.

### Weekly Day-of-Week Selection

Use ISO 8601 day numbering: Monday = 1 through Sunday = 7. Store as a JSON array string in the DB (e.g., `"[1,3,5]"` for Mon/Wed/Fri). Parse in Flutter DTO's `toDomain()` using `jsonDecode()`.

The weekly picker UI should show all 7 days as toggleable options. At least one day must be selected when `recurrenceRule = 'weekly'`. Validate client-side before submission.

### Custom Interval Picker UX

When the user selects "Custom interval", show a secondary modal with a `CupertinoPicker` (number wheel) for selecting the interval in days (range: 2–365). Use the same modal popup pattern as the custom time range picker in Story 2.2. Default to 2 days.

### Edit This Instance vs. All Future (AC #2)

When the user taps any editable field on a recurring task in `TaskEditInline`:
1. Show a `CupertinoActionSheet` with two options: "Edit this task only" / "Edit this and all future tasks"
2. "Edit this task only" — proceed with normal `updateTask()` (PATCH to `/v1/tasks/:id`)
3. "Edit this and all future tasks" — **stub behavior for now**: same as "edit this task only" (real bulk-update logic deferred to scheduling engine implementation). The API should accept an optional `applyToFuture: true` query param on PATCH that the stub ignores but the real implementation will use.
4. Cache the user's choice for the duration of the edit session (don't ask again for every field change on the same task).

### Complete Task — Response Shape

The `POST /v1/tasks/:id/complete` response includes both the completed task and the next instance (if recurring):

```json
{
  "data": {
    "completedTask": { ...taskSchema },
    "nextInstance": { ...taskSchema } | null
  }
}
```

Non-recurring tasks return `nextInstance: null`.

### Stake / Commitment Parity (AC #3)

AC #3 references stakes, charity, and proof settings. These fields do not exist yet (Epic 6: Commitment Contracts, Epic 7: Proof). This story ensures the **architecture supports** future parity:
- Next instance generation copies ALL task properties from the completed task (except `id`, `completedAt`, `createdAt`, `updatedAt`, `dueDate`).
- When stake/proof columns are added in later epics, the copy logic will automatically carry them forward because it copies all non-excluded fields.
- No stake/proof UI or fields are added in this story — only the copy-all-properties pattern.

### Enum Strategy — Text Column (Existing Pattern)

Same as Story 2.2: use text column for `recurrenceRule` (not Postgres ENUM). Validation at API layer via `z.enum()`, Flutter layer via Dart enum with `fromJson`/`toJson`.

### API Field Naming Convention

Follow existing `camelCase` pattern in Zod schemas and API responses: `recurrenceRule`, `recurrenceInterval`, `recurrenceDaysOfWeek`, `recurrenceParentId`. Drizzle `casing: 'snake_case'` config handles DB column mapping.

### Backwards Compatibility

All new fields are nullable/optional. Existing tasks have `null` for all recurrence fields. Existing API consumers and Flutter code continue to work — new fields are additive only.

### Project Structure Notes

New files limited to one enum and one test file. All other changes extend existing files.

```
packages/
└── core/
    └── src/
        └── schema/
            └── tasks.ts                     <- MODIFY: add 4 new columns

apps/
├── api/
│   └── src/
│       └── routes/
│           └── tasks.ts                     <- MODIFY: update schemas, stubs, add complete route
│   └── test/
│       └── routes/
│           └── tasks.test.ts                <- MODIFY: add recurrence + complete test cases
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart             <- MODIFY: add recurrence strings
    │   └── features/
    │       └── tasks/
    │           ├── data/
    │           │   ├── task_dto.dart         <- MODIFY: add recurrence fields
    │           │   ├── task_dto.freezed.dart <- REGENERATE
    │           │   ├── task_dto.g.dart       <- REGENERATE
    │           │   └── tasks_repository.dart <- MODIFY: add recurrence params, completeTask()
    │           ├── domain/
    │           │   ├── task.dart             <- MODIFY: add recurrence fields
    │           │   ├── task.freezed.dart     <- REGENERATE
    │           │   └── recurrence_rule.dart  <- NEW: RecurrenceRule enum
    │           └── presentation/
    │               ├── tasks_provider.dart   <- MODIFY: add recurrence params, completeTask()
    │               ├── tasks_provider.g.dart <- REGENERATE
    │               └── widgets/
    │                   ├── task_row.dart          <- MODIFY: add recurrence badge
    │                   └── task_edit_inline.dart   <- MODIFY: add recurrence picker + edit choice
    └── test/
        └── features/
            └── tasks/
                └── task_recurrence_test.dart <- NEW
```

### References

- Story 2.3 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` — Story 2.3, line ~879]
- FR7 (recurring tasks with full feature parity): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~32]
- FR22-30 (commitment contracts — future parity): [Source: `_bmad-output/planning-artifacts/epics.md` — lines ~67-76]
- Architecture: task property copy pattern for recurrence: [Source: `_bmad-output/planning-artifacts/architecture.md` — scheduling engine section]
- PRD: recurring tasks first-class: [Source: `_bmad-output/planning-artifacts/prd.md` — line ~139]
- PRD: Morgan persona — recurring commitments: [Source: `_bmad-output/planning-artifacts/prd.md` — line ~185]
- Existing Drizzle schema: `packages/core/src/schema/tasks.ts`
- Existing API routes: `apps/api/src/routes/tasks.ts`
- Existing Flutter domain model: `apps/flutter/lib/features/tasks/domain/task.dart`
- Existing DTO: `apps/flutter/lib/features/tasks/data/task_dto.dart`
- Existing repository: `apps/flutter/lib/features/tasks/data/tasks_repository.dart`
- Existing provider: `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart`
- Existing inline editor: `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart`
- Existing task row: `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`
- Existing Add tab sheet: `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart`
- Existing strings: `apps/flutter/lib/core/l10n/strings.dart`

### Previous Story Learnings (from Stories 1.1-2.2)

- **`valueOrNull` vs `.value`**: Riverpod v3 uses `.value` on `AsyncValue`, NOT `.valueOrNull`. Use `ref.watch(provider).value ?? defaultValue` in widget builders.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests that touch any provider reading `SharedPreferences` or `FlutterSecureStorage` at build time.
- **`ProviderContainer` for unit testing providers**: Use `ProviderContainer` with `overrides` for provider logic tests. Never `WidgetTester` alone for business logic.
- **`ref.read(apiClientProvider)` — never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection.
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **`@Riverpod(keepAlive: true)` for long-lived notifiers**: Task/list notifiers should NOT use `keepAlive` — they are per-screen state.
- **Test baseline after Story 2.2**: 300 tests pass (34 API + 266 Flutter). All must continue passing.
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
- **Drizzle-kit not on PATH in pnpm workspace** — use full path via `packages/core/node_modules/.bin/drizzle-kit` or `./node_modules/.bin/drizzle-kit` from `apps/api/`.

### Debug Log References

(Carried forward from Story 2.2 — same codebase patterns apply)
- Zod v4 UUID validation requires RFC-4122 compliant UUIDs (variant bits must be [89ab] in position 1 of 4th group).
- Riverpod v4 generates provider names without "Notifier" suffix.
- `CupertinoSlidingSegmentedControl` generic type param cannot be nullable — use `CupertinoActionSheet`.
- Drizzle Kit requires `casing: 'snake_case'` in drizzle.config.ts.
- Drizzle-kit not on PATH — use full path via `./node_modules/.bin/drizzle-kit` from `apps/api/`.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| Recurrence options | daily, weekly (with day selection), monthly, custom interval | FR7, AC #1 |
| Full feature parity | Recurring tasks have all properties of one-off tasks | FR7, AC #3 |
| Edit scope choice | "This instance" vs "this and all future" | AC #2 |
| Auto-generate next instance | Completing a recurring task creates next occurrence | AC #1 |
| Stake inheritance | Next instance copies stake/charity/proof from parent (future-proofed) | AC #3 |
| Inline editing | Recurrence editable inline; auto-save, no save button | FR58 (from Story 2.1) |
| No Material widgets | Cupertino only | Stories 1.5-2.2 pattern |
| No inline strings | All copy in `AppStrings` | Stories 1.6-2.2 pattern |
| Dynamic Type | All text uses theme text styles; no hardcoded sizes | NFR-A3, UX-DR22 |
| Warm narrative voice | Copy follows "past self / future self" voice | UX-DR32, UX-DR36 |

### Scope Boundaries — What This Story Does NOT Include

- **Scheduling engine** — storing recurrence rules only; actual schedule placement is Epic 3
- **Stake/proof/charity fields** — not yet in DB; this story future-proofs the copy pattern for when they arrive (Epic 6, 7)
- **Bulk "edit all future" database query** — stubbed; real implementation when scheduling engine is built (Epic 3)
- **NLP/natural language task capture** (FR1b) — Story 4.1
- **Templates** (FR78) — Story 2.4
- **Dependencies** (FR73) — Story 2.5
- **Bulk operations** (FR74) — Story 2.5
- **Offline sync** — not wired in this story
- **Recurring task history/series view** — no UI for viewing past instances of a series

### Deferred Issues from Previous Stories

- **TimeOfDay formatting duplication** (from Story 1.9): If `_formatTime()` is needed, extract to `apps/flutter/lib/core/utils/time_format.dart` rather than duplicating.
- **Review findings from Story 2.2**: Debounce bug in custom time range, missing clear of custom time fields, missing theme colors on custom time labels, custom time range ignoring existing values — all marked for patch but not yet fixed. Do NOT regress on these; if touching the same code paths, apply the fixes.

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

- drizzle-kit not available via pnpm workspace commands; used `../../packages/core/node_modules/.bin/drizzle-kit` from `apps/api/` directory.

### Completion Notes List

- Added 4 recurrence columns (recurrenceRule, recurrenceInterval, recurrenceDaysOfWeek, recurrenceParentId) to Drizzle tasks schema with migration 0002.
- Updated all 3 Zod schemas (create, update, response) with recurrence fields; stubTask defaults all to null.
- Implemented `POST /v1/tasks/:id/complete` route with full next-due-date computation (daily, weekly with day-of-week, monthly with day clamping, custom interval).
- Created RecurrenceRule enum in Flutter domain layer with fromJson/toJson pattern matching existing enums.
- Updated Task domain model, TaskDto (with JSON string to List<int> parsing for daysOfWeek), TasksRepository (createTask + completeTask), and TasksNotifier with recurrence parameters.
- Added recurrence picker UI to AddTabSheet and TaskEditInline with weekly day-of-week multi-select and custom interval CupertinoPicker.
- Implemented edit scope choice (edit this instance / edit all future) for recurring tasks in TaskEditInline with per-session caching.
- Added recurrence repeat badge to TaskRow showing rule-specific labels.
- Added 17 string constants to AppStrings for recurrence UI.
- All 325 tests pass (42 API + 283 Flutter), zero regressions from baseline of 300.

### File List

- `packages/core/src/schema/tasks.ts` — MODIFIED (added 4 recurrence columns)
- `packages/core/src/schema/migrations/0002_square_purple_man.sql` — NEW (migration)
- `packages/core/src/schema/migrations/meta/0002_snapshot.json` — NEW (migration metadata)
- `apps/api/src/routes/tasks.ts` — MODIFIED (recurrence schemas, stubs, complete route)
- `apps/api/test/routes/tasks.test.ts` — MODIFIED (8 new recurrence test cases)
- `apps/flutter/lib/core/l10n/strings.dart` — MODIFIED (17 new recurrence strings)
- `apps/flutter/lib/features/tasks/domain/recurrence_rule.dart` — NEW (RecurrenceRule enum)
- `apps/flutter/lib/features/tasks/domain/task.dart` — MODIFIED (4 recurrence fields)
- `apps/flutter/lib/features/tasks/domain/task.freezed.dart` — REGENERATED
- `apps/flutter/lib/features/tasks/data/task_dto.dart` — MODIFIED (recurrence fields + toDomain parsing)
- `apps/flutter/lib/features/tasks/data/task_dto.freezed.dart` — REGENERATED
- `apps/flutter/lib/features/tasks/data/task_dto.g.dart` — REGENERATED
- `apps/flutter/lib/features/tasks/data/tasks_repository.dart` — MODIFIED (recurrence params + completeTask)
- `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart` — MODIFIED (recurrence params + completeTask)
- `apps/flutter/lib/features/tasks/presentation/tasks_provider.g.dart` — REGENERATED
- `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — MODIFIED (recurrence picker + edit scope choice)
- `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` — MODIFIED (recurrence badge)
- `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart` — MODIFIED (recurrence picker)
- `apps/flutter/test/features/tasks/task_recurrence_test.dart` — NEW (17 tests)

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-30 | 1.0 | claude-opus-4-6 | Story 2.3 created — recurring tasks with series parent pattern, recurrence rule storage, next-instance generation on completion, edit-scope choice UI. |
| 2026-03-30 | 1.1 | claude-opus-4-6 | Story 2.3 implemented — all 12 tasks complete, 25 new tests (8 API + 17 Flutter), zero regressions. |
