# Story 2.5: Task Dependencies & Bulk Operations

Status: review

## Story

As a user,
I want to define dependencies between tasks and take actions on multiple tasks at once,
So that the scheduler respects task ordering and I can manage my list efficiently.

## Acceptance Criteria

1. **Given** two tasks exist, **When** the user creates a dependency (Task B depends on Task A), **Then** the scheduling engine does not schedule Task B before Task A's due date (FR73) **And** the dependency relationship is visible on both task cards.

2. **Given** the user selects multiple tasks, **When** they perform a bulk operation, **Then** available operations are: reschedule, mark complete, assign (to a shared list member), delete (FR74) **And** delete and complete show a confirmation before executing **And** bulk reschedule opens a date picker that applies the new date to all selected tasks.

## Tasks / Subtasks

- [x]Add `taskDependenciesTable` to Drizzle schema (AC: 1)
  - [x]`packages/core/src/schema/task-dependencies.ts` — NEW: create table with columns:
    - `id` (uuid, PK, defaultRandom)
    - `dependentTaskId` (uuid, notNull) — the task that depends on another (Task B)
    - `dependsOnTaskId` (uuid, notNull) — the prerequisite task (Task A)
    - `createdAt` (timestamptz, defaultNow, notNull)
  - [x]`packages/core/src/schema/index.ts` — export `taskDependenciesTable`
  - [x]Generate Drizzle migration: run `./node_modules/.bin/drizzle-kit generate` from `apps/api/`

- [x]Add API routes for task dependencies in `apps/api/src/routes/task-dependencies.ts` (AC: 1)
  - [x]Define Zod schemas:
    - `createDependencySchema`: `{ dependentTaskId: string (uuid), dependsOnTaskId: string (uuid) }`
    - `dependencySchema`: `{ id, dependentTaskId, dependsOnTaskId, createdAt }`
  - [x]`POST /v1/task-dependencies` — stub: creates a dependency between two tasks; validates no self-dependency and no circular dependency (stub: check `dependentTaskId !== dependsOnTaskId`)
  - [x]`GET /v1/task-dependencies?taskId=` — stub: returns all dependencies for a task (both directions — where task is dependent and where task is depended upon)
  - [x]`DELETE /v1/task-dependencies/:id` — stub: removes a dependency
  - [x]Register router in `apps/api/src/index.ts`

- [x]Add API routes for bulk operations in `apps/api/src/routes/bulk-operations.ts` (AC: 2)
  - [x]Define Zod schemas:
    - `bulkRescheduleSchema`: `{ taskIds: string[] (uuid), dueDate: string (datetime) }`
    - `bulkCompleteSchema`: `{ taskIds: string[] (uuid) }`
    - `bulkDeleteSchema`: `{ taskIds: string[] (uuid) }`
    - `bulkResultSchema`: `{ data: { succeeded: string[] (uuid), failed: { id: string, error: string }[] } }`
  - [x]`POST /v1/tasks/bulk/reschedule` — stub: updates dueDate for all specified tasks
  - [x]`POST /v1/tasks/bulk/complete` — stub: marks all specified tasks as completed
  - [x]`POST /v1/tasks/bulk/delete` — stub: archives all specified tasks (soft delete per FR59 pattern)
  - [x]Register router in `apps/api/src/index.ts`
  - [x]Note: `bulk/assign` is deferred — shared lists (Epic 5) are not yet implemented

- [x]Add Flutter domain model for dependencies (AC: 1)
  - [x]`apps/flutter/lib/features/tasks/domain/task_dependency.dart` — NEW: Freezed model with fields: `id`, `dependentTaskId`, `dependsOnTaskId`, `createdAt`
  - [x]Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x]Add Flutter DTO for dependencies (AC: 1)
  - [x]`apps/flutter/lib/features/tasks/data/task_dependency_dto.dart` — NEW: Freezed DTO with JSON serialization; `toDomain()` maps to domain model
  - [x]Run build_runner to regenerate `.freezed.dart` and `.g.dart`

- [x]Add dependency methods to `TasksRepository` (AC: 1)
  - [x]`apps/flutter/lib/features/tasks/data/tasks_repository.dart` — MODIFY: add:
    - `getDependencies(String taskId)` — GET `/v1/task-dependencies?taskId=`; returns `List<TaskDependency>`
    - `createDependency({ dependentTaskId, dependsOnTaskId })` — POST `/v1/task-dependencies`
    - `deleteDependency(String id)` — DELETE `/v1/task-dependencies/:id`

- [x]Add bulk operation methods to `TasksRepository` (AC: 2)
  - [x]`apps/flutter/lib/features/tasks/data/tasks_repository.dart` — MODIFY: add:
    - `bulkReschedule(List<String> taskIds, String dueDate)` — POST `/v1/tasks/bulk/reschedule`
    - `bulkComplete(List<String> taskIds)` — POST `/v1/tasks/bulk/complete`
    - `bulkDelete(List<String> taskIds)` — POST `/v1/tasks/bulk/delete`

- [x]Add `DependenciesNotifier` (AC: 1)
  - [x]`apps/flutter/lib/features/tasks/presentation/dependencies_provider.dart` — NEW: Riverpod `@riverpod` AsyncNotifier managing dependency state per task; methods: `loadDependencies(taskId)`, `addDependency()`, `removeDependency()`

- [x]Add bulk operations to `TasksNotifier` (AC: 2)
  - [x]`apps/flutter/lib/features/tasks/presentation/tasks_provider.dart` — MODIFY: add methods:
    - `bulkReschedule(List<String> taskIds, String dueDate)` — calls repo, updates state
    - `bulkComplete(List<String> taskIds)` — calls repo, updates state
    - `bulkDelete(List<String> taskIds)` — calls repo, removes from state

- [x]Add dependency picker to task edit flow (AC: 1)
  - [x]`apps/flutter/lib/features/tasks/presentation/widgets/dependency_picker.dart` — NEW: modal that lists all tasks in the same list (excluding the current task and already-linked tasks); user taps a task to add as dependency
  - [x]`apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — MODIFY: add "Dependencies" section below existing property rows; shows linked dependency tasks with remove (X) action; tapping "Add dependency" opens `DependencyPicker`

- [x]Show dependency relationship on task cards (AC: 1)
  - [x]`apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` — MODIFY: add subtle dependency indicator (e.g., small link icon and "depends on Task A" / "blocks Task B" label below the task title) when dependencies exist for the task

- [x]Add multi-select mode to list detail screen (AC: 2)
  - [x]`apps/flutter/lib/features/lists/presentation/list_detail_screen.dart` — MODIFY:
    - Add `_isMultiSelectMode` state boolean
    - Long-press on a task row enters multi-select mode
    - In multi-select mode: task rows show checkboxes; tapping toggles selection
    - Navigation bar shows: selected count, "Cancel" button, and overflow action menu
    - macOS: `Cmd+click` toggles individual task selection (per UX spec)

- [x]Add bulk actions bar (AC: 2)
  - [x]`apps/flutter/lib/features/lists/presentation/widgets/bulk_actions_bar.dart` — NEW: bottom bar shown during multi-select with action buttons:
    - Reschedule (calendar icon) — opens `CupertinoDatePicker` in a modal sheet; on confirm, calls `bulkReschedule`
    - Complete (checkmark icon) — shows `CupertinoAlertDialog` confirmation; on confirm, calls `bulkComplete`
    - Delete (trash icon) — shows `CupertinoAlertDialog` confirmation; on confirm, calls `bulkDelete`
    - Assign (person icon) — disabled with tooltip "Shared lists coming soon" (Epic 5 deferred)

- [x]Add strings to `AppStrings` (AC: 1, 2)
  - [x]`apps/flutter/lib/core/l10n/strings.dart` — add all new string constants:
    - `taskDependenciesLabel` = `'Dependencies'`
    - `taskDependsOn` = `'Depends on'`
    - `taskBlocks` = `'Blocks'`
    - `taskAddDependency` = `'Add dependency'`
    - `taskDependencyPickerTitle` = `'Choose a task'`
    - `taskDependencyPickerEmpty` = `'No other tasks to link.'`
    - `taskDependencyRemoved` = `'Dependency removed.'`
    - `taskDependencyAdded` = `'Dependency added.'`
    - `taskDependencyError` = `'Something went wrong. Please try again.'`
    - `taskDependencySelfError` = `'A task can\u2019t depend on itself.'`
    - `bulkSelectCount` = `'{count} selected'`
    - `bulkRescheduleAction` = `'Reschedule'`
    - `bulkCompleteAction` = `'Complete'`
    - `bulkDeleteAction` = `'Delete'`
    - `bulkAssignAction` = `'Assign'`
    - `bulkAssignDisabled` = `'Shared lists coming soon'`
    - `bulkCompleteConfirmTitle` = `'Complete {count} tasks?'`
    - `bulkCompleteConfirmMessage` = `'These tasks will be marked as done.'`
    - `bulkDeleteConfirmTitle` = `'Delete {count} tasks?'`
    - `bulkDeleteConfirmMessage` = `'These tasks will be permanently removed.'`
    - `bulkRescheduleSuccess` = `'{count} tasks rescheduled.'`
    - `bulkCompleteSuccess` = `'{count} tasks completed.'`
    - `bulkDeleteSuccess` = `'{count} tasks deleted.'`
    - `bulkOperationError` = `'Something went wrong. Please try again.'`

- [x]Write tests (AC: 1, 2)
  - [x]`apps/api/test/routes/task-dependencies.test.ts` — NEW:
    - POST /v1/task-dependencies: verify dependency created with both task IDs
    - POST /v1/task-dependencies: verify 422 when dependentTaskId === dependsOnTaskId
    - GET /v1/task-dependencies?taskId=: verify returns dependencies for task
    - DELETE /v1/task-dependencies/:id: verify 204 returned
  - [x]`apps/api/test/routes/bulk-operations.test.ts` — NEW:
    - POST /v1/tasks/bulk/reschedule: verify returns succeeded IDs with updated dueDate
    - POST /v1/tasks/bulk/complete: verify returns succeeded IDs
    - POST /v1/tasks/bulk/delete: verify returns succeeded IDs
  - [x]`apps/flutter/test/features/tasks/task_dependencies_test.dart` — NEW:
    - TaskDependency domain model: verify fromJson/toJson round-trip
    - TaskDependencyDto: verify toDomain mapping
    - DependencyPicker: verify tasks listed, verify add triggers
    - TaskRow: verify dependency indicator shown when dependencies exist
    - TaskEditInline: verify "Dependencies" section appears, verify add/remove actions
  - [x]`apps/flutter/test/features/tasks/bulk_operations_test.dart` — NEW:
    - ListDetailScreen: verify long-press enters multi-select mode
    - ListDetailScreen: verify task checkboxes shown in multi-select mode
    - BulkActionsBar: verify all action buttons present
    - BulkActionsBar: verify delete shows confirmation dialog
    - BulkActionsBar: verify complete shows confirmation dialog
    - BulkActionsBar: verify reschedule opens date picker
    - BulkActionsBar: verify assign button disabled

## Dev Notes

### Task Dependencies — Data Model

Dependencies are stored in a separate join table (`task_dependencies`) rather than as a field on the tasks table, because:
1. A task can have multiple dependencies (many-to-many relationship)
2. The relationship is directional: Task B depends on Task A (not symmetric)
3. Both directions need to be queryable (what does this task depend on? what does this task block?)

**Table structure:**
```sql
CREATE TABLE task_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dependent_task_id UUID NOT NULL,  -- the task that waits (Task B)
  depends_on_task_id UUID NOT NULL, -- the prerequisite (Task A)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(dependent_task_id, depends_on_task_id)
);
```

**Terminology convention** (use consistently throughout):
- **"depends on"** = Task B depends on Task A (Task B cannot start until Task A is done)
- **"blocks"** = Task A blocks Task B (Task A must complete before Task B can start)
- In the API response, return both `dependsOn` and `blocks` arrays for a given task

### Dependency Validation Rules

1. **No self-dependency**: `dependentTaskId !== dependsOnTaskId`
2. **No duplicates**: unique constraint on `(dependentTaskId, dependsOnTaskId)`
3. **Circular dependency prevention (stub)**: In the stub, only validate #1 and #2. Full circular detection (A→B→C→A) is deferred to real implementation — the stub only prevents direct self-reference.

### Bulk Operations — API Design

Bulk operations use a dedicated `/v1/tasks/bulk/{operation}` path rather than overloading existing endpoints. This keeps single-task and multi-task flows cleanly separated.

**Response shape** for all bulk operations:
```json
{
  "data": {
    "succeeded": ["uuid-1", "uuid-2"],
    "failed": [
      { "id": "uuid-3", "error": "TASK_NOT_FOUND" }
    ]
  }
}
```

This partial-success model allows the UI to report which tasks succeeded and which failed, rather than an all-or-nothing approach.

**Bulk delete is a soft delete** (archives) — per the FR59 pattern already established. The API uses `DELETE /v1/tasks/:id/archive` semantics. Bulk delete calls the same archive logic for each task.

### Bulk Operations — "Assign" is Deferred

The "assign (to a shared list member)" operation from FR74 requires shared lists (Epic 5, Stories 5.1–5.6). Since shared lists are not yet implemented, the assign button should be:
- **Visible** in the bulk actions bar (to show the feature exists)
- **Disabled** with a tooltip "Shared lists coming soon"
- **Not wired** to any API endpoint

### Multi-Select UX — iOS vs macOS

Per the UX spec:
- **iOS**: Long-press on a task row enters multi-select mode. Subsequent taps toggle selection. A "Cancel" button in the nav bar exits multi-select.
- **macOS**: Cmd+click toggles individual task selection without entering a dedicated mode. This is handled by the existing `PlatformDispatcher` or by detecting the `LogicalKeyboardKey.meta` modifier.

Both platforms show the same `BulkActionsBar` at the bottom when tasks are selected.

### Dependency Picker UX

The dependency picker is a modal sheet that lists tasks in the same list (same `listId`). It:
- Excludes the current task being edited
- Excludes tasks that are already direct dependencies
- Shows task titles with section context (e.g., "Design review · Sprint backlog")
- Tapping a task creates the dependency and closes the picker
- Uses `CupertinoListSection` and `CupertinoListTile` (no Material widgets)

### Dependency Visibility on Task Cards

Per AC #1, dependency relationships must be visible on both task cards:
- On the **dependent task** (Task B): show "Depends on: Task A" with a small link icon
- On the **prerequisite task** (Task A): show "Blocks: Task B" with a small lock icon
- If multiple dependencies exist, show count (e.g., "Depends on 3 tasks") with a tap to expand

### Project Structure Notes

```
packages/
└── core/
    └── src/
        └── schema/
            ├── task-dependencies.ts              <- NEW: taskDependenciesTable
            └── index.ts                          <- MODIFY: export taskDependenciesTable

apps/
├── api/
│   └── src/
│       ├── routes/
│       │   ├── task-dependencies.ts              <- NEW: dependency CRUD routes
│       │   └── bulk-operations.ts                <- NEW: bulk reschedule/complete/delete routes
│       └── index.ts                              <- MODIFY: register routers
│   └── test/
│       └── routes/
│           ├── task-dependencies.test.ts          <- NEW
│           └── bulk-operations.test.ts            <- NEW
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart                  <- MODIFY: add dependency + bulk strings
    │   └── features/
    │       ├── tasks/
    │       │   ├── domain/
    │       │   │   └── task_dependency.dart       <- NEW
    │       │   ├── data/
    │       │   │   ├── task_dependency_dto.dart   <- NEW
    │       │   │   └── tasks_repository.dart      <- MODIFY: add dependency + bulk methods
    │       │   └── presentation/
    │       │       ├── dependencies_provider.dart <- NEW
    │       │       └── widgets/
    │       │           ├── dependency_picker.dart <- NEW
    │       │           ├── task_edit_inline.dart  <- MODIFY: add dependencies section
    │       │           └── task_row.dart          <- MODIFY: add dependency indicators
    │       └── lists/
    │           └── presentation/
    │               ├── list_detail_screen.dart    <- MODIFY: add multi-select mode
    │               └── widgets/
    │                   └── bulk_actions_bar.dart  <- NEW
    └── test/
        └── features/
            └── tasks/
                ├── task_dependencies_test.dart    <- NEW
                └── bulk_operations_test.dart      <- NEW
```

### References

- Story 2.5 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` — Story 2.5, line ~925]
- FR73 (task dependencies): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~41]
- FR74 (bulk operations): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~42]
- UX: Task Dependencies via dependency picker: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~264]
- UX: Bulk Operations via multi-select: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~268]
- Architecture: `dependencies.ts` constraint in scheduling engine: [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~974]
- Architecture: monorepo structure: [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~684]
- Architecture: Drizzle `casing: 'snake_case'` config: [Source: `apps/api/drizzle.config.ts`]
- Architecture: `@hono/zod-openapi` for all routes: [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~456]
- Architecture: `ok()` / `list()` / `err()` response helpers: [Source: `apps/api/src/lib/response.ts`]
- Existing Drizzle schemas: `packages/core/src/schema/tasks.ts`, `lists.ts`, `sections.ts`, `templates.ts`
- Existing API routes: `apps/api/src/routes/tasks.ts`, `lists.ts`, `sections.ts`, `templates.ts`
- Existing API index: `apps/api/src/index.ts`
- Existing Flutter task domain model: `apps/flutter/lib/features/tasks/domain/task.dart`
- Existing Flutter task widgets: `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`, `task_edit_inline.dart`
- Existing Flutter tasks repository: `apps/flutter/lib/features/tasks/data/tasks_repository.dart`
- Existing Flutter tasks provider: `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart`
- Existing Flutter list detail screen: `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart`
- Existing strings: `apps/flutter/lib/core/l10n/strings.dart`

### Previous Story Learnings (from Stories 1.1-2.4)

- **`valueOrNull` vs `.value`**: Riverpod v3 uses `.value` on `AsyncValue`, NOT `.valueOrNull`. Use `ref.watch(provider).value ?? defaultValue` in widget builders.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests that touch any provider reading `SharedPreferences` or `FlutterSecureStorage` at build time.
- **`ProviderContainer` for unit testing providers**: Use `ProviderContainer` with `overrides` for provider logic tests. Never `WidgetTester` alone for business logic.
- **`ref.read(apiClientProvider)` — never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection.
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **`@Riverpod(keepAlive: true)` for long-lived notifiers**: Task/list notifiers should NOT use `keepAlive` — they are per-screen state.
- **Test baseline after Story 2.4**: 48 API tests + 298 Flutter tests pass. All must continue passing.
- **No Material widgets**: Use `CupertinoTextField`, `CupertinoButton`, `CupertinoDatePicker`, `CupertinoAlertDialog`, `CupertinoActionSheet`. Never `TextField`, `ElevatedButton`, `AlertDialog`, `ListTile`.
- **All strings in `AppStrings`**: Never inline string literals. Warm narrative voice (UX-DR32, UX-DR36).
- **Widget tests — override providers in `ProviderScope(overrides: [...])`**: Never rely on real network calls or real `SharedPreferences` in widget tests.
- **Hono route additions — no untyped routes**: `@hono/zod-openapi` schemas for all new routes.
- **`ok()` / `list()` / `err()` helpers from `apps/api/src/lib/response.ts`**: Same envelope for all responses.
- **Riverpod v3 restriction**: `provider.notifier` cannot be called when provider is overridden with `overrideWithValue`. Use fake class extension pattern in tests.
- **`freezed` union types go in `domain/`**: Domain models and sealed types live in `domain/`, never in `data/`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible(...)` before tap when widgets are below the fold.
- **Zod v4 UUID validation requires RFC-4122 compliant UUIDs** (variant bits must be [89ab] in position 1 of 4th group). Use `a0000000-0000-4000-8000-000000000001` style in test fixtures.
- **Riverpod v4 generates provider names without "Notifier" suffix** (e.g., `dependenciesProvider` not `dependenciesNotifierProvider`).
- **`CupertinoSlidingSegmentedControl` generic type param cannot be nullable** — use `CupertinoActionSheet` for option pickers instead.
- **Drizzle Kit requires `casing: 'snake_case'`** in drizzle.config.ts to generate snake_case SQL columns from camelCase TS schema fields.
- **Drizzle-kit not on PATH in pnpm workspace** — use full path via `./node_modules/.bin/drizzle-kit` from `apps/api/`. May need `../../node_modules/.pnpm/node_modules/.bin/drizzle-kit`.
- **Dismissible swipe-to-delete test needs `-500` offset** (not `-300`) to trigger `confirmDismiss`.

### Debug Log References

(Carried forward from Story 2.4 — same codebase patterns apply)
- Zod v4 UUID validation requires RFC-4122 compliant UUIDs (variant bits must be [89ab] in position 1 of 4th group).
- Riverpod v4 generates provider names without "Notifier" suffix.
- `CupertinoSlidingSegmentedControl` generic type param cannot be nullable — use `CupertinoActionSheet`.
- Drizzle Kit requires `casing: 'snake_case'` in drizzle.config.ts.
- Drizzle-kit not on PATH — use full path via `./node_modules/.bin/drizzle-kit` from `apps/api/`.
- Dismissible swipe-to-delete test needed `-500` offset (not `-300`) to trigger `confirmDismiss`.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| Dependencies are directional | Task B depends on Task A (not symmetric) | FR73, AC #1 |
| Dependency visible on both cards | Show "depends on" and "blocks" labels | AC #1 |
| Bulk operations: 4 types | Reschedule, complete, assign, delete | FR74, AC #2 |
| Delete/complete require confirmation | CupertinoAlertDialog before executing | AC #2 |
| Bulk reschedule opens date picker | CupertinoDatePicker applies to all selected | AC #2 |
| Assign is deferred | Requires shared lists (Epic 5) | Design decision |
| Soft delete pattern | Bulk delete uses archive (FR59) | Existing pattern |
| No Material widgets | Cupertino only | Stories 1.5-2.4 pattern |
| No inline strings | All copy in `AppStrings` | Stories 1.6-2.4 pattern |
| Dynamic Type | All text uses theme text styles; no hardcoded sizes | NFR-A3, UX-DR22 |
| Warm narrative voice | Copy follows "past self / future self" voice | UX-DR32, UX-DR36 |

### Scope Boundaries — What This Story Does NOT Include

- **Scheduling engine integration** — dependencies are stored but scheduling constraint enforcement is Epic 3 (`packages/scheduling/src/constraints/dependencies.ts`)
- **Circular dependency detection** — only self-reference prevention in stub; full graph cycle detection deferred to real implementation
- **Cross-list dependencies** — dependencies are scoped to tasks within the same list; cross-list dependencies deferred
- **Bulk assign** — requires shared lists (Epic 5); button visible but disabled
- **Offline dependency/bulk operations** — requires network; offline deferred
- **Bulk operations on recurring task series** — bulk complete/delete applies to selected instances only, not entire series
- **Dependency cascade** — completing Task A does not auto-complete Task B; it only unblocks it for scheduling

### Deferred Issues from Previous Stories

- **TimeOfDay formatting duplication** (from Story 1.9): If `_formatTime()` is needed, extract to `apps/flutter/lib/core/utils/time_format.dart` rather than duplicating.
- **Review findings from Story 2.2**: Debounce bug in custom time range, missing clear of custom time fields, missing theme colors on custom time labels, custom time range ignoring existing values — all marked for patch but not yet fixed. Do NOT regress on these; if touching the same code paths, apply the fixes.
- **Review findings from Story 2.3**: Inline string literals in task_row.dart, task_edit_inline.dart, add_tab_sheet.dart for custom recurrence interval display; missing API test for recurring-task completion branch; weekly day picker allows zero-day dismissal; missing try/catch on recurrenceDaysOfWeek JSON parsing; recurrence picker bypassing edit-scope choice; applyToFuture sent as body field instead of query param — all marked for patch.
- **Review findings from Story 2.4**: Delete confirmation button using wrong string; missing navigation to new list after template apply; inline string literal in save dialog pre-fill; no user-visible success feedback after save/apply; TextEditingController not disposed — patch items from story 2.4 review.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Hono route ordering matters: `/v1/tasks/bulk/complete` was matched by `/v1/tasks/{id}/complete` (id='bulk') when bulk router was registered after tasks router. Fixed by registering `bulkOperationsRouter` before `tasksRouter`.
- Riverpod v4 family overrides require fake notifier class pattern (not closure), same as `tasksProvider.overrideWith(() => _FakeTasksNotifier(...))`.
- `withValues(alpha:)` used instead of deprecated `withOpacity()` for color opacity.

### Completion Notes List

- Task 1: Created `taskDependenciesTable` Drizzle schema with unique constraint on (dependentTaskId, dependsOnTaskId). Generated migration 0004.
- Task 2: Created task-dependencies API routes (POST, GET, DELETE) with self-dependency validation returning 422 SELF_DEPENDENCY.
- Task 3: Created bulk-operations API routes (reschedule, complete, delete) with partial-success response model. Registered bulk router BEFORE tasks router to avoid route collision.
- Task 4-5: Created TaskDependency domain model (Freezed) and TaskDependencyDto (Freezed + JSON serialization) with toDomain() mapping.
- Task 6-7: Added dependency methods (getDependencies, createDependency, deleteDependency) and bulk methods (bulkReschedule, bulkComplete, bulkDelete) to TasksRepository.
- Task 8: Created DependenciesNotifier as Riverpod AsyncNotifier managing per-task dependency state.
- Task 9: Added bulkReschedule, bulkComplete, bulkDelete to TasksNotifier with optimistic state updates.
- Task 10: Created DependencyPicker modal and added Dependencies section to TaskEditInline with add/remove dependency flow.
- Task 11: Added dependency indicators (depends on / blocks) to TaskRow with link/lock icons.
- Task 12: Added multi-select mode to ListDetailScreen with long-press entry, checkbox toggling, and Cancel button.
- Task 13: Created BulkActionsBar with Reschedule (date picker), Complete (confirmation), Delete (confirmation), and Assign (disabled with tooltip).
- Task 14: Added all 26 new string constants to AppStrings.
- Task 15: Wrote 7 API tests (4 dependency + 3 bulk) and 17 Flutter tests (10 dependency + 7 bulk). All 55 API tests and 315 Flutter tests pass.

### File List

New files:
- packages/core/src/schema/task-dependencies.ts
- packages/core/src/schema/migrations/0004_many_betty_ross.sql
- apps/api/src/routes/task-dependencies.ts
- apps/api/src/routes/bulk-operations.ts
- apps/api/test/routes/task-dependencies.test.ts
- apps/api/test/routes/bulk-operations.test.ts
- apps/flutter/lib/features/tasks/domain/task_dependency.dart
- apps/flutter/lib/features/tasks/domain/task_dependency.freezed.dart
- apps/flutter/lib/features/tasks/data/task_dependency_dto.dart
- apps/flutter/lib/features/tasks/data/task_dependency_dto.freezed.dart
- apps/flutter/lib/features/tasks/data/task_dependency_dto.g.dart
- apps/flutter/lib/features/tasks/presentation/dependencies_provider.dart
- apps/flutter/lib/features/tasks/presentation/dependencies_provider.g.dart
- apps/flutter/lib/features/tasks/presentation/widgets/dependency_picker.dart
- apps/flutter/lib/features/lists/presentation/widgets/bulk_actions_bar.dart
- apps/flutter/test/features/tasks/task_dependencies_test.dart
- apps/flutter/test/features/tasks/bulk_operations_test.dart

Modified files:
- packages/core/src/schema/index.ts
- apps/api/src/index.ts
- apps/flutter/lib/features/tasks/data/tasks_repository.dart
- apps/flutter/lib/features/tasks/data/tasks_repository.g.dart
- apps/flutter/lib/features/tasks/presentation/tasks_provider.dart
- apps/flutter/lib/features/tasks/presentation/tasks_provider.g.dart
- apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart
- apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart
- apps/flutter/lib/features/lists/presentation/list_detail_screen.dart
- apps/flutter/lib/core/l10n/strings.dart

### Review Findings

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-30 | 1.0 | claude-opus-4-6 | Story 2.5 created — task dependencies with join table, bulk operations (reschedule/complete/delete), multi-select UI, dependency picker, dependency indicators on task cards. |
| 2026-03-30 | 1.1 | claude-opus-4-6 | Story 2.5 implemented — all tasks complete. 7 new API tests, 17 new Flutter tests. All 55 API + 315 Flutter tests pass. |
