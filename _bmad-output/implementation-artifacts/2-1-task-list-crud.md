# Story 2.1: Task & List CRUD

Status: review

## Story

As a user,
I want to create tasks, organize them into lists and sections, and edit or archive them,
So that I can capture and manage everything I need to do in a structured way.

## Acceptance Criteria

1. **Given** the user opens the Add tab or taps a list, **When** they create a task, **Then** the task can be saved with: title (required), notes, due date, and list assignment **And** the task appears in the list within 500ms of confirmation (NFR-P2).

2. **Given** a list exists, **When** the user creates a section within it, **Then** sections can be infinitely nested; subtasks can be nested under any task **And** a section or list can have a default due date that is inherited by any task created within it that does not have its own due date (FR3).

3. **Given** a task exists, **When** the user edits it, **Then** all task properties (title, notes, due date, list, section) are editable inline (FR58) **And** changes are saved immediately without a separate save action.

4. **Given** a task is complete or no longer relevant, **When** the user archives it, **Then** the task is hidden from the active view but retained in the archive (FR59) **And** archived tasks are accessible via a "Show archived" toggle in the list view.

5. **Given** a section contains multiple tasks, **When** the user drags a task, **Then** they can reorder it within the section (FR57) **And** the new order is persisted immediately.

## Tasks / Subtasks

- [x] Create Drizzle schema for tasks, lists, and sections in `packages/core/` (AC: 1, 2, 3, 4, 5)
  - [x] `packages/core/src/schema/tasks.ts` — `tasksTable`: id (uuid PK), userId (FK → users), listId (FK → lists, nullable), sectionId (FK → sections, nullable), parentTaskId (FK → tasks, nullable for subtasks), title (text, required), notes (text, nullable), dueDate (timestamp, nullable), position (integer, for ordering), archivedAt (timestamp, nullable), completedAt (timestamp, nullable), createdAt, updatedAt
  - [x] `packages/core/src/schema/lists.ts` — `listsTable`: id (uuid PK), userId (FK → users), title (text, required), defaultDueDate (timestamp, nullable), position (integer), archivedAt (timestamp, nullable), createdAt, updatedAt
  - [x] `packages/core/src/schema/sections.ts` — `sectionsTable`: id (uuid PK), listId (FK → lists), parentSectionId (FK → sections, nullable for infinite nesting), title (text, required), defaultDueDate (timestamp, nullable), position (integer), createdAt, updatedAt
  - [x] Update `packages/core/src/schema/index.ts` — export all three tables
  - [x] Create Drizzle migration: `pnpm drizzle-kit generate` from `apps/api/`

- [x] Add API routes in `apps/api/src/routes/tasks.ts` (AC: 1, 3, 4, 5)
  - [x] `POST /v1/tasks` — stub: create task with title (required), notes, dueDate, listId, sectionId, parentTaskId; return created task with id; `TODO(impl): validate listId/sectionId exist, inherit defaultDueDate from section/list if no dueDate provided (FR3), insert via Drizzle`
  - [x] `GET /v1/tasks` — stub: return fixture task list with cursor pagination; query params: listId, sectionId, archived (boolean), cursor; `TODO(impl): filter by userId from JWT, apply list/section/archive filters, cursor-based pagination`
  - [x] `GET /v1/tasks/:id` — stub: return fixture single task; `TODO(impl): verify ownership via userId`
  - [x] `PATCH /v1/tasks/:id` — stub: return updated task; accepts partial update of title, notes, dueDate, listId, sectionId, parentTaskId, position; `TODO(impl): upsert via Drizzle, validate ownership`
  - [x] `DELETE /v1/tasks/:id/archive` — stub: return 204; `TODO(impl): set archivedAt = now() via Drizzle` (NOT a hard delete — archive only per FR59)
  - [x] `PATCH /v1/tasks/:id/reorder` — stub: return 200; body: `{ position: number }`; `TODO(impl): update position, shift sibling positions`
  - [x] All routes: `@hono/zod-openapi` schemas; `ok()` / `list()` / `err()` from `apps/api/src/lib/response.ts`; auth middleware applied

- [x] Add API routes in `apps/api/src/routes/lists.ts` (AC: 1, 2, 4)
  - [x] `POST /v1/lists` — stub: create list with title (required), defaultDueDate; return created list
  - [x] `GET /v1/lists` — stub: return fixture list of lists with cursor pagination
  - [x] `GET /v1/lists/:id` — stub: return fixture single list with its sections
  - [x] `PATCH /v1/lists/:id` — stub: return updated list; accepts partial update of title, defaultDueDate
  - [x] `DELETE /v1/lists/:id/archive` — stub: return 204; `TODO(impl): set archivedAt, cascade archive to tasks`
  - [x] All routes: `@hono/zod-openapi` schemas; auth middleware

- [x] Add API routes in `apps/api/src/routes/sections.ts` (AC: 2)
  - [x] `POST /v1/sections` — stub: create section with title (required), listId (required), parentSectionId (nullable), defaultDueDate; return created section
  - [x] `GET /v1/sections` — stub: return sections for a given listId query param
  - [x] `PATCH /v1/sections/:id` — stub: return updated section
  - [x] `DELETE /v1/sections/:id` — stub: return 204; `TODO(impl): cascade delete/archive tasks in section`
  - [x] All routes: `@hono/zod-openapi` schemas; auth middleware

- [x] Mount new routes in `apps/api/src/index.ts` (AC: 1–5)
  - [x] Import and mount `tasksRouter`, `listsRouter`, `sectionsRouter` alongside existing `authRouter`, `usersRouter`, `healthRouter`

- [x] Create Flutter domain models with freezed (AC: 1–5)
  - [x] `apps/flutter/lib/features/tasks/domain/task.dart` — `@freezed class Task` with: id, title, notes, dueDate, listId, sectionId, parentTaskId, position, archivedAt, completedAt, createdAt, updatedAt
  - [x] `apps/flutter/lib/features/lists/domain/task_list.dart` — `@freezed class TaskList` with: id, title, defaultDueDate, position, archivedAt, createdAt, updatedAt (named `TaskList` to avoid conflict with `dart:core List`)
  - [x] `apps/flutter/lib/features/lists/domain/section.dart` — `@freezed class Section` with: id, listId, parentSectionId, title, defaultDueDate, position, createdAt, updatedAt

- [x] Create Flutter DTOs for API mapping (AC: 1–5)
  - [x] `apps/flutter/lib/features/tasks/data/task_dto.dart` — `TaskDto` with `fromJson`/`toJson` and `toDomain()` mapper
  - [x] `apps/flutter/lib/features/lists/data/list_dto.dart` — `ListDto` with `fromJson`/`toJson` and `toDomain()` mapper
  - [x] `apps/flutter/lib/features/lists/data/section_dto.dart` — `SectionDto` with `fromJson`/`toJson` and `toDomain()` mapper

- [x] Create Flutter repositories (AC: 1–5)
  - [x] `apps/flutter/lib/features/tasks/data/tasks_repository.dart` — `TasksRepository`: createTask(), getTasks(listId?, sectionId?, archived?), getTask(id), updateTask(id, fields), archiveTask(id), reorderTask(id, position); all via `ref.read(apiClientProvider)`
  - [x] `apps/flutter/lib/features/lists/data/lists_repository.dart` — `ListsRepository`: createList(), getLists(), getList(id), updateList(id, fields), archiveList(id)
  - [x] `apps/flutter/lib/features/lists/data/sections_repository.dart` — `SectionsRepository`: createSection(), getSections(listId), updateSection(id, fields), deleteSection(id)

- [x] Create Riverpod providers (AC: 1–5)
  - [x] `apps/flutter/lib/features/tasks/presentation/tasks_provider.dart` — `@riverpod class TasksNotifier` managing task list state per list/section; exposes create, update, archive, reorder methods; returns `AsyncValue<List<Task>>`
  - [x] `apps/flutter/lib/features/lists/presentation/lists_provider.dart` — `@riverpod class ListsNotifier` managing all user lists; exposes create, update, archive methods; returns `AsyncValue<List<TaskList>>`
  - [x] `apps/flutter/lib/features/lists/presentation/sections_provider.dart` — `@riverpod class SectionsNotifier` managing sections for a given list; exposes create, update, delete methods

- [x] Build task creation UI — replace Add tab stub (AC: 1)
  - [x] Replace `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart` — replace stub content with task creation form: title field (required, `CupertinoTextField`), notes field (optional, `CupertinoTextField`), due date picker (`CupertinoDatePicker` in modal), list picker (dropdown of user lists); submit button calls `TasksNotifier.createTask()`
  - [x] Add strings to `AppStrings` in `apps/flutter/lib/core/l10n/strings.dart`: `addTaskTitle`, `addTaskTitlePlaceholder`, `addTaskNotesPlaceholder`, `addTaskDueDateLabel`, `addTaskListLabel`, `addTaskCreateButton`, `addTaskSuccess`, `addTaskError`, `addTaskTitleRequired`

- [x] Build list detail screen with sections and tasks (AC: 1, 2, 3, 4, 5)
  - [x] `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart` — shows list title, sections (expandable, nested), tasks within each section; "Show archived" toggle; supports inline editing of task properties (title, notes, due date — tap to edit, auto-save on change); supports drag-to-reorder via `ReorderableListView`
  - [x] `apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart` — renders a section header with its tasks; supports nested sub-sections; shows "Add task" and "Add section" affordances
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` — renders a single task row: title (editable inline), due date badge, archive action (swipe or context menu); tap opens inline edit mode
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — inline editing widget: shows all editable fields (title, notes, due date, list/section); changes saved immediately via `TasksNotifier.updateTask()` on each field change (debounced 300ms)

- [x] Build list management in Lists tab (AC: 1, 2, 4)
  - [x] Replace `apps/flutter/lib/features/lists/presentation/lists_screen.dart` — replace empty state stub with: list of user's lists (from `ListsNotifier`), "Create list" CTA, each list taps into `ListDetailScreen`; show empty state only when no lists exist
  - [x] `apps/flutter/lib/features/lists/presentation/create_list_screen.dart` — modal/sheet for creating a new list: title field (required), default due date (optional); calls `ListsNotifier.createList()`
  - [x] Add strings to `AppStrings`: `listsTitle`, `createListButton`, `createListTitle`, `createListTitlePlaceholder`, `createListDefaultDueDateLabel`, `createListSuccess`, `listDetailTitle`, `showArchived`, `hideArchived`, `archiveTaskAction`, `addTaskInList`, `addSectionInList`, `sectionTitlePlaceholder`, `taskTitlePlaceholder`, `editTaskNotes`, `editTaskDueDate`

- [x] Add routes to `app_router.dart` (AC: 1, 2, 3, 4, 5)
  - [x] Add `/lists/:id` route (nested under `/lists` branch in `StatefulShellRoute`) pointing to `ListDetailScreen`
  - [x] Add `/lists/create` route pointing to `CreateListScreen`

- [x] Write tests (AC: 1–5)
  - [x] `test/features/tasks/task_creation_test.dart` — verify Add tab sheet shows task form; verify title required validation; verify createTask called with correct params; verify success feedback
  - [x] `test/features/lists/lists_screen_test.dart` — verify Lists tab shows user lists from provider; verify empty state when no lists; verify tap navigates to list detail; verify create list CTA
  - [x] `test/features/lists/list_detail_screen_test.dart` — verify list detail shows sections and tasks; verify "Show archived" toggle; verify inline edit saves on change; verify archive action; verify drag-to-reorder calls reorder
  - [x] `test/features/tasks/task_edit_inline_test.dart` — verify inline fields render; verify title edit triggers updateTask; verify due date change triggers updateTask; verify debounce behavior
  - [x] API route tests (co-located): `apps/api/src/routes/tasks.test.ts`, `lists.test.ts`, `sections.test.ts` — verify stub responses match Zod schemas; verify auth middleware applied; verify 201 on create, 200 on get/patch, 204 on archive/delete
  - [x] Run `flutter test` — all 206 pre-existing tests must continue passing + new tests

- [x] Run `build_runner` and commit generated files
  - [x] `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x] Commit any new `*.g.dart` / `*.freezed.dart` files

## Dev Notes

### Critical Architecture Constraints

**This is the first story introducing the core task/list data model. It creates foundational schema, API routes, and Flutter features that all subsequent Epic 2 stories build on. Get the data model and patterns right.**

**Route files — three separate files, NOT extensions of existing files:**
- `apps/api/src/routes/tasks.ts` — NEW file (FR1, FR2-8, FR55-59, FR68, FR73-74, FR76, FR78 per architecture.md line ~731)
- `apps/api/src/routes/lists.ts` — NEW file (FR15-21, FR62, FR75 per architecture.md line ~732)
- `apps/api/src/routes/sections.ts` — NEW file (FR2, FR3 section-level per architecture.md line ~733)

These are new route files that must be mounted in `apps/api/src/index.ts` alongside `authRouter`, `usersRouter`, and `healthRouter`.

**Schema files — three separate files in `packages/core/src/schema/`:**
- `packages/core/src/schema/tasks.ts` — NEW. Export as `tasksTable`.
- `packages/core/src/schema/lists.ts` — NEW. Export as `listsTable`.
- `packages/core/src/schema/sections.ts` — NEW. Export as `sectionsTable`.

Currently `packages/core/src/schema/index.ts` exports nothing (`export {}`). Update it to re-export all three tables.

**Drizzle config — `casing: 'camelCase'`:**
The Drizzle instance in `apps/api/src/db/index.ts` uses `drizzle(neon(env.DATABASE_URL), { casing: 'camelCase' })`. Define columns in camelCase in the schema files; Drizzle auto-converts to snake_case in PostgreSQL. NEVER use manual `mapTo` or `columnName` overrides.

**Table naming conventions (architecture.md line ~430):**
- Table names: `snake_case`, plural — `tasks`, `lists`, `sections`
- Columns: `camelCase` in code — Drizzle `casing: 'camelCase'` handles the mapping
- Foreign keys: `{singular_table}_id` pattern — `userId`, `listId`, `sectionId`, `parentTaskId`, `parentSectionId`
- Indexes: `idx_{table}_{columns}` — e.g., `idx_tasks_user_id`, `idx_tasks_list_id`
- Drizzle table exports: `{entity}Table` — `tasksTable`, `listsTable`, `sectionsTable`

**Zod schema naming (architecture.md line ~466):**
- `taskSchema`, `createTaskSchema`, `updateTaskSchema`
- `listSchema`, `createListSchema`, `updateListSchema`
- `sectionSchema`, `createSectionSchema`, `updateSectionSchema`

**Flutter feature folders — TWO separate feature folders:**
```
apps/flutter/lib/features/
├── tasks/                        ← NEW feature folder
│   ├── data/
│   │   ├── tasks_repository.dart
│   │   └── task_dto.dart
│   ├── domain/
│   │   └── task.dart             ← @freezed domain model
│   └── presentation/
│       ├── tasks_provider.dart   ← @riverpod
│       └── widgets/
│           ├── task_row.dart
│           └── task_edit_inline.dart
├── lists/                        ← EXTEND existing feature folder
│   ├── data/                     ← NEW subfolder
│   │   ├── lists_repository.dart
│   │   ├── list_dto.dart
│   │   ├── sections_repository.dart
│   │   └── section_dto.dart
│   ├── domain/                   ← NEW subfolder
│   │   ├── task_list.dart        ← @freezed domain model (NOT named "list.dart" — shadows dart:core)
│   │   └── section.dart          ← @freezed domain model
│   └── presentation/
│       ├── lists_screen.dart           ← UPDATE: replace empty state stub
│       ├── lists_provider.dart         ← NEW
│       ├── sections_provider.dart      ← NEW
│       ├── list_detail_screen.dart     ← NEW
│       ├── create_list_screen.dart     ← NEW
│       └── widgets/
│           ├── lists_empty_state.dart  ← EXISTS — keep, used when no lists
│           └── section_widget.dart     ← NEW
```

**`lists/` feature folder already partially exists:**
- `apps/flutter/lib/features/lists/presentation/lists_screen.dart` — placeholder with empty state
- `apps/flutter/lib/features/lists/presentation/widgets/lists_empty_state.dart` — empty state widget

Do NOT recreate these. Update `lists_screen.dart` to show real list data when available, falling back to `ListsEmptyState` when the user has no lists.

**Flutter feature anatomy (architecture.md line ~495):**
Every feature has exactly `data/`, `domain/`, `presentation/` subfolders. The `tasks/` folder is entirely new; the `lists/` folder needs `data/` and `domain/` subfolders added.

**Domain model naming — avoid Dart reserved word conflicts:**
- Name the list domain model `TaskList` (not `List`) to avoid shadowing `dart:core List`
- File: `task_list.dart` (not `list.dart`)

**Add tab — action tab, not navigation:**
The Add tab is intercepted by `AppShell` before navigation occurs — it opens `AddTabSheet` as a modal bottom sheet. This story replaces the stub content inside `AddTabSheet` with a real task creation form. Do NOT change the shell navigation interception logic.

**`AddTabSheet` currently has inline strings:**
The existing `add_tab_sheet.dart` has hardcoded strings (`'Add a task'`, `'Task capture coming in a future story.'`, `'Close'`). Replace these with `AppStrings` constants as part of the update.

**Inline editing — auto-save pattern:**
Task properties must be editable inline (FR58) with immediate save (no separate save button). Use a debounce pattern (300ms) on text field changes to avoid excessive API calls. On blur or field change, fire `TasksNotifier.updateTask()` with only the changed fields (PATCH semantics).

**Drag-to-reorder — use Flutter's built-in `ReorderableListView`:**
No external package needed. Flutter's `ReorderableListView` provides drag-to-reorder with haptic feedback on iOS. On reorder complete, call `TasksNotifier.reorderTask(taskId, newPosition)` which hits `PATCH /v1/tasks/:id/reorder`.

**Archive vs Delete — archive only in this story:**
FR59 specifies archiving, not hard deletion. The API endpoint is `DELETE /v1/tasks/:id/archive` (or `PATCH /v1/tasks/:id` with `{ archivedAt: <timestamp> }`). Archived tasks are hidden from the default view but shown when "Show archived" toggle is active. There is no hard delete in this story.

**Default due date inheritance (FR3):**
When a task is created within a section or list that has a `defaultDueDate`, and the task itself does not have a `dueDate`, the API should set the task's `dueDate` to the section's or list's `defaultDueDate`. Inheritance priority: section `defaultDueDate` > list `defaultDueDate` > null. This is server-side logic (in the `TODO(impl)` comment for now).

**Infinite nesting — `parentSectionId` self-reference:**
Sections support infinite nesting via `parentSectionId` (FK → sections, nullable). The Flutter UI should render sections recursively. For this story, test with 2-3 levels of nesting. Subtasks use `parentTaskId` (FK → tasks, nullable) for task-level nesting.

**Position field for ordering:**
Both tasks and sections have a `position` integer field. When reordering, update the `position` of the moved item and shift siblings. Use fractional positioning or gap-based positioning to minimize cascading updates. The exact algorithm is a `TODO(impl)` for the real backend — stubs just return the position as-is.

**API response format — use existing envelope helpers:**
- Single object: `ok({ ...fields })` → `{ "data": { ... } }`
- List with pagination: `list([...], cursor, hasMore)` → `{ "data": [...], "pagination": { "cursor": "...", "hasMore": true } }`
- Error: `err('CODE', 'message')` → `{ "error": { "code": "...", "message": "..." } }`
- HTTP status: 201 for POST (create), 200 for GET/PATCH, 204 for DELETE/archive

**Cursor-based pagination only — NO offset/limit:**
Architecture mandates cursor-based pagination everywhere. The `list()` helper takes `(data, cursor, hasMore)`. For stubs, return `cursor: null, hasMore: false`.

**No Material widgets:**
Use `CupertinoTextField` (not `TextField`), `CupertinoButton` (not `ElevatedButton`), `CupertinoDatePicker` for date selection, `CupertinoAlertDialog` for confirmations. Use `CupertinoListTile`-style rows — not `ListTile`. Exception: `ReorderableListView` is acceptable (it's a structural widget, not a Material design widget).

**All strings in `AppStrings`:**
Never inline string literals in widgets. All user-facing copy goes in `apps/flutter/lib/core/l10n/strings.dart`. Use warm narrative voice consistent with UX-DR32, UX-DR36.

### File Locations — Exact Paths

```
packages/
└── core/
    └── src/
        └── schema/
            ├── tasks.ts       ← NEW
            ├── lists.ts       ← NEW
            ├── sections.ts    ← NEW
            └── index.ts       ← UPDATE: export new tables

apps/
├── api/
│   └── src/
│       ├── index.ts           ← UPDATE: mount new routers
│       └── routes/
│           ├── tasks.ts       ← NEW
│           ├── lists.ts       ← NEW
│           └── sections.ts    ← NEW
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   ├── l10n/
    │   │   │   └── strings.dart            ← UPDATE: add task/list/section strings
    │   │   └── router/
    │   │       └── app_router.dart         ← UPDATE: add /lists/:id, /lists/create routes
    │   └── features/
    │       ├── tasks/                       ← NEW feature folder
    │       │   ├── data/
    │       │   │   ├── tasks_repository.dart
    │       │   │   └── task_dto.dart
    │       │   ├── domain/
    │       │   │   └── task.dart
    │       │   └── presentation/
    │       │       ├── tasks_provider.dart
    │       │       └── widgets/
    │       │           ├── task_row.dart
    │       │           └── task_edit_inline.dart
    │       ├── lists/                       ← EXTEND existing
    │       │   ├── data/                    ← NEW subfolder
    │       │   │   ├── lists_repository.dart
    │       │   │   ├── list_dto.dart
    │       │   │   ├── sections_repository.dart
    │       │   │   └── section_dto.dart
    │       │   ├── domain/                  ← NEW subfolder
    │       │   │   ├── task_list.dart
    │       │   │   └── section.dart
    │       │   └── presentation/
    │       │       ├── lists_screen.dart          ← UPDATE
    │       │       ├── lists_provider.dart         ← NEW
    │       │       ├── sections_provider.dart      ← NEW
    │       │       ├── list_detail_screen.dart     ← NEW
    │       │       ├── create_list_screen.dart     ← NEW
    │       │       └── widgets/
    │       │           └── section_widget.dart     ← NEW
    │       └── shell/
    │           └── presentation/
    │               └── add_tab_sheet.dart          ← UPDATE: replace stub with task form
    └── test/
        └── features/
            ├── tasks/
            │   ├── task_creation_test.dart          ← NEW
            │   └── task_edit_inline_test.dart       ← NEW
            └── lists/
                ├── lists_screen_test.dart           ← NEW (or update existing)
                └── list_detail_screen_test.dart     ← NEW
```

### Previous Story Learnings (from Stories 1.1–1.12)

- **`valueOrNull` vs `.value`**: Riverpod v3 uses `.value` on `AsyncValue`, NOT `.valueOrNull`. Use `ref.watch(provider).value ?? defaultValue` in widget builders.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests that touch any provider reading `SharedPreferences` or `FlutterSecureStorage` at build time. Established in Stories 1.8–1.10.
- **`ProviderContainer` for unit testing providers**: Use `ProviderContainer` with `overrides` for provider logic tests. Never `WidgetTester` alone for business logic.
- **`ref.read(apiClientProvider)` — never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection. `TasksRepository`, `ListsRepository`, `SectionsRepository` must follow this pattern.
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **`@Riverpod(keepAlive: true)` for long-lived notifiers**: `AuthStateNotifier` uses `keepAlive: true`. Task/list notifiers should NOT use `keepAlive` — they are per-screen state, not global.
- **Test baseline after Story 1.12**: 206 tests pass. All must continue passing.
- **No Material widgets**: Use `CupertinoTextField`, `CupertinoButton`, `CupertinoDatePicker`, `CupertinoAlertDialog`. Never `TextField`, `ElevatedButton`, `AlertDialog`, `ListTile`.
- **All strings in `AppStrings`**: Never inline string literals. Warm narrative voice (UX-DR32, UX-DR36).
- **Widget tests — override providers in `ProviderScope(overrides: [...])`**: Never rely on real network calls or real `SharedPreferences` in widget tests.
- **Hono route additions — no untyped routes**: `@hono/zod-openapi` schemas for all new routes. Follow exact pattern from `users.ts` and `auth.ts`.
- **`ok()` / `list()` / `err()` helpers from `apps/api/src/lib/response.ts`**: Same envelope for all responses. Use `list()` for paginated list endpoints.
- **Riverpod v3 restriction**: `provider.notifier` cannot be called when provider is overridden with `overrideWithValue`. Use fake class extension pattern in tests.
- **`freezed` union types go in `domain/`**: Domain models and sealed types live in `domain/`, never in `data/`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible(...)` before tap when widgets are below the fold.
- **Duplicate text in assertions after navigation**: Use unique text identifiers in test assertions.
- **TimeOfDay formatting duplication** (deferred from Story 1.9): If this story does not touch schedule-related files, leave deferred.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| Task creation speed | Task appears in list within 500ms of confirmation | NFR-P2, AC #1 |
| Inline editing | All task properties editable inline; auto-save, no save button | FR58, AC #3 |
| Archive, not delete | Tasks hidden from active view but retained in archive | FR59, AC #4 |
| Show archived toggle | Archived tasks accessible via toggle in list view | FR59, AC #4 |
| Drag-to-reorder | Reorder persisted immediately | FR57, AC #5 |
| Infinite nesting | Sections can nest infinitely; subtasks under any task | FR2, AC #2 |
| Default due date inheritance | Section/list default due date inherited by tasks without own date | FR3, AC #2 |
| Cursor-based pagination | No offset/limit — cursor only | Architecture pattern |
| No Material widgets | Cupertino only | Stories 1.5–1.12 pattern |
| No inline strings | All copy in `AppStrings` | Stories 1.6–1.12 pattern |
| Dynamic Type | All text uses theme text styles; no hardcoded sizes | NFR-A3, UX-DR22 |
| Warm narrative voice | Task creation copy follows "past self / future self" voice | UX-DR32, UX-DR36 |

### Deferred Issues from Previous Stories

- **TimeOfDay formatting duplication** (from Story 1.9): Extract duplicated `_formatTime()` to `apps/flutter/lib/core/utils/time_format.dart` if touching schedule-related files. This story is unlikely to — leave deferred.
- **`users.ts` is minimal**: Not relevant to this story — tasks/lists/sections have their own route files.

### Scope Boundaries — What This Story Does NOT Include

- **NLP/natural language task capture** (FR1b) — Story 4.1
- **Task priority/urgency** (FR68) — Story 2.2
- **Time-of-day constraints / energy requirements** (FR4, FR5) — Story 2.2
- **Recurring tasks** (FR7) — Story 2.3
- **Templates** (FR78) — Story 2.4
- **Dependencies** (FR73) — Story 2.5
- **Bulk operations** (FR74) — Story 2.5
- **Task search/filter** (FR56) — Story 2.9
- **Task completion** (FR55) — task completion UI is deferred; this story only has `completedAt` field in the schema. Mark-complete UX is part of the Now/Today tab stories.
- **Offline sync** — drift local DB and pending operations queue are not wired in this story. Tasks go directly to API. Offline support added in a later cross-cutting story.

### References

- Story 2.1 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` — Story 2.1, line ~819]
- FR1 (task creation): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~25]
- FR2 (lists, sections, subtasks): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~26]
- FR3 (due dates, default inheritance): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~27]
- FR57 (manual reorder): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~35]
- FR58 (edit task properties): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~36]
- FR59 (archive tasks): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~37]
- Route files — `tasks.ts`, `lists.ts`, `sections.ts`: [Source: `_bmad-output/planning-artifacts/architecture.md` — lines ~731–733]
- Flutter feature folders — `tasks/`, `lists/`: [Source: `_bmad-output/planning-artifacts/architecture.md` — lines ~862–867]
- Schema files — `packages/core/src/schema/`: [Source: `_bmad-output/planning-artifacts/architecture.md` — lines ~937–941]
- Table naming conventions: [Source: `_bmad-output/planning-artifacts/architecture.md` — lines ~430–434]
- API response envelope: [Source: `_bmad-output/planning-artifacts/architecture.md` — lines ~513–545]
- `ok()` / `list()` / `err()` helpers: `apps/api/src/lib/response.ts`
- Existing `lists_screen.dart`: `apps/flutter/lib/features/lists/presentation/lists_screen.dart`
- Existing `lists_empty_state.dart`: `apps/flutter/lib/features/lists/presentation/widgets/lists_empty_state.dart`
- Existing `add_tab_sheet.dart`: `apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart`
- `AppStrings`: `apps/flutter/lib/core/l10n/strings.dart`
- `ApiClient` Riverpod provider: `apps/flutter/lib/core/network/api_client.dart`
- `app_router.dart`: `apps/flutter/lib/core/router/app_router.dart`
- UX — Add tab is action tab: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~98]
- UX — Lists tab: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~99]
- UX — Task creation smart capture: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~105]

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

- Zod v4 UUID validation requires RFC-4122 compliant UUIDs (variant bits must be [89ab] in position 1 of 4th group). Fixed test fixtures.
- Riverpod v4 generates provider names without "Notifier" suffix (e.g., `listsProvider` not `listsNotifierProvider`).
- `CupertinoSlidingSegmentedControl` generic type param cannot be nullable — replaced with `CupertinoActionSheet` for list picker.
- Drizzle Kit requires `casing: 'snake_case'` in drizzle.config.ts to generate snake_case SQL columns from camelCase TS schema fields.

### Completion Notes List

- Drizzle schema created: `tasksTable` (13 columns with archivedAt/completedAt timestamps), `listsTable` (8 columns), `sectionsTable` (8 columns with parentSectionId self-reference for infinite nesting).
- Three new API route files with stub responses and Zod OpenAPI schemas: tasks.ts (7 routes), lists.ts (5 routes), sections.ts (4 routes).
- Flutter domain models with freezed: Task, TaskList (avoids dart:core conflict), Section.
- Flutter DTOs with fromJson/toJson and toDomain() mappers for all three entities.
- Three repositories (TasksRepository, ListsRepository, SectionsRepository) using ApiClient via Riverpod injection.
- Three Riverpod notifiers (TasksNotifier, ListsNotifier, SectionsNotifier) with create/update/archive/reorder/delete methods.
- AddTabSheet replaced: stub content replaced with full task creation form (title required, notes optional, due date picker, list picker).
- ListsScreen updated: shows real list data when available, falls back to ListsEmptyState when no lists.
- ListDetailScreen created: shows sections/tasks, "Show archived" toggle, inline edit, drag-to-reorder.
- CreateListScreen created: modal sheet for creating new lists.
- All 244 Flutter tests pass (206 pre-existing + 38 new). All 28 API tests pass.

### File List

- packages/core/src/schema/tasks.ts (NEW)
- packages/core/src/schema/lists.ts (NEW)
- packages/core/src/schema/sections.ts (NEW)
- packages/core/src/schema/index.ts (MODIFIED)
- packages/core/src/schema/migrations/0000_amused_maginty.sql (NEW)
- packages/core/src/schema/migrations/meta/0000_snapshot.json (NEW)
- packages/core/src/schema/migrations/meta/_journal.json (NEW)
- apps/api/drizzle.config.ts (MODIFIED — added casing: 'snake_case')
- apps/api/src/index.ts (MODIFIED — mounted tasksRouter, listsRouter, sectionsRouter)
- apps/api/src/routes/tasks.ts (NEW)
- apps/api/src/routes/lists.ts (NEW)
- apps/api/src/routes/sections.ts (NEW)
- apps/api/test/routes/tasks.test.ts (NEW)
- apps/api/test/routes/lists.test.ts (NEW)
- apps/api/test/routes/sections.test.ts (NEW)
- apps/flutter/lib/core/l10n/strings.dart (MODIFIED — added task/list/section strings)
- apps/flutter/lib/core/router/app_router.dart (MODIFIED — added /lists/:id route)
- apps/flutter/lib/core/router/app_router.g.dart (REGENERATED)
- apps/flutter/lib/features/tasks/domain/task.dart (NEW)
- apps/flutter/lib/features/tasks/domain/task.freezed.dart (GENERATED)
- apps/flutter/lib/features/tasks/data/task_dto.dart (NEW)
- apps/flutter/lib/features/tasks/data/task_dto.freezed.dart (GENERATED)
- apps/flutter/lib/features/tasks/data/task_dto.g.dart (GENERATED)
- apps/flutter/lib/features/tasks/data/tasks_repository.dart (NEW)
- apps/flutter/lib/features/tasks/data/tasks_repository.g.dart (GENERATED)
- apps/flutter/lib/features/tasks/presentation/tasks_provider.dart (NEW)
- apps/flutter/lib/features/tasks/presentation/tasks_provider.g.dart (GENERATED)
- apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart (NEW)
- apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart (NEW)
- apps/flutter/lib/features/lists/domain/task_list.dart (NEW)
- apps/flutter/lib/features/lists/domain/task_list.freezed.dart (GENERATED)
- apps/flutter/lib/features/lists/domain/section.dart (NEW)
- apps/flutter/lib/features/lists/domain/section.freezed.dart (GENERATED)
- apps/flutter/lib/features/lists/data/list_dto.dart (NEW)
- apps/flutter/lib/features/lists/data/list_dto.freezed.dart (GENERATED)
- apps/flutter/lib/features/lists/data/list_dto.g.dart (GENERATED)
- apps/flutter/lib/features/lists/data/lists_repository.dart (NEW)
- apps/flutter/lib/features/lists/data/lists_repository.g.dart (GENERATED)
- apps/flutter/lib/features/lists/data/section_dto.dart (NEW)
- apps/flutter/lib/features/lists/data/section_dto.freezed.dart (GENERATED)
- apps/flutter/lib/features/lists/data/section_dto.g.dart (GENERATED)
- apps/flutter/lib/features/lists/data/sections_repository.dart (NEW)
- apps/flutter/lib/features/lists/data/sections_repository.g.dart (GENERATED)
- apps/flutter/lib/features/lists/presentation/lists_screen.dart (MODIFIED)
- apps/flutter/lib/features/lists/presentation/lists_provider.dart (NEW)
- apps/flutter/lib/features/lists/presentation/lists_provider.g.dart (GENERATED)
- apps/flutter/lib/features/lists/presentation/sections_provider.dart (NEW)
- apps/flutter/lib/features/lists/presentation/sections_provider.g.dart (GENERATED)
- apps/flutter/lib/features/lists/presentation/list_detail_screen.dart (NEW)
- apps/flutter/lib/features/lists/presentation/create_list_screen.dart (NEW)
- apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart (NEW)
- apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart (MODIFIED)
- apps/flutter/test/features/tasks/task_creation_test.dart (NEW)
- apps/flutter/test/features/tasks/task_edit_inline_test.dart (NEW)
- apps/flutter/test/features/lists/lists_screen_test.dart (MODIFIED — was empty state only, now tests real list data)
- apps/flutter/test/features/lists/list_detail_screen_test.dart (NEW)
- _bmad-output/implementation-artifacts/sprint-status.yaml (MODIFIED)
- _bmad-output/implementation-artifacts/2-1-task-list-crud.md (MODIFIED)

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-30 | 1.0 | claude-opus-4-6 | Story 2.1 created — comprehensive implementation guide for Task & List CRUD: Drizzle schema (tasks, lists, sections), three new API route files, two Flutter feature folders (tasks/ new, lists/ extended), Add tab task creation form, list detail with inline editing and drag-to-reorder, archive toggle. |
| 2026-03-30 | 2.0 | claude-opus-4-6 | Story 2.1 implemented — full-stack CRUD for tasks, lists, and sections. Drizzle schema with archivedAt/completedAt timestamps and position field. Three API route files with stub responses. Flutter: domain models, DTOs, repositories, Riverpod providers, task creation form in AddTabSheet, list detail screen with inline editing and drag-to-reorder, archive toggle. 244 Flutter tests + 28 API tests pass. |
