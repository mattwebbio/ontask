# Story 5.4: Accountability Settings Cascade

Status: review

## Story

As a list owner,
I want to set proof requirements at list or section level,
So that every task in a section automatically has the right accountability without per-task configuration.

## Acceptance Criteria

1. **Given** a list owner opens a list or section's settings **When** they set a proof requirement **Then** all tasks within that list or section inherit the requirement: none, photo proof, Watch Mode, or HealthKit (FR20) **And** the inherited requirement is shown as a label on affected tasks

2. **Given** a task inherits an accountability setting **When** the user edits that specific task **Then** they can override the inherited setting with a per-task value **And** the override is shown with a distinct "custom" indicator so it is clear the task differs from the section default

## Tasks / Subtasks

### Backend: DB schema — add `proofRequirement` to `lists` and `sections` tables; add `proofMode`/`proofModeIsCustom` to `tasks`

- [x] Add `proofRequirement` column to `packages/core/src/schema/lists.ts` (AC: 1)
  - [x] Column: `proofRequirement: text()` — nullable, no default (null means no requirement / `'none'`)
  - [x] Valid values: `'none'` | `'photo'` | `'watchMode'` | `'healthKit'` | `null`
  - [x] Follow existing pattern: camelCase in schema, Drizzle generates snake_case DDL automatically

- [x] Add `proofRequirement` column to `packages/core/src/schema/sections.ts` (AC: 1)
  - [x] Column: `proofRequirement: text()` — nullable (null = inherit from parent list)
  - [x] Same valid values as list-level: `'none'` | `'photo'` | `'watchMode'` | `'healthKit'` | `null`

- [x] Add `proofMode` and `proofModeIsCustom` columns to `packages/core/src/schema/tasks.ts` (AC: 1, 2)
  - [x] `proofMode: text()` — nullable (null = derived from inherited requirement; `'standard'` means no proof)
  - [x] `proofModeIsCustom: boolean().default(false).notNull()` — true when the task's `proofMode` was explicitly set by the user, overriding the list/section default
  - [x] NOTE: `assignedToUserId` already exists — do NOT add it again (committed in Story 5.2 migration `0009_task_assignment_strategies.sql`)

- [x] Generate migration `packages/core/src/schema/migrations/0010_accountability_settings_cascade.sql` (AC: 1, 2)
  - [x] Run `pnpm drizzle-kit generate` from `packages/core/` to produce the migration file
  - [x] Migration must: ADD `proof_requirement` to `lists`, ADD `proof_requirement` to `sections`, ADD `proof_mode` to `tasks`, ADD `proof_mode_is_custom` to `tasks`
  - [x] Commit generated SQL, updated `meta/_journal.json`, and `meta/0010_snapshot.json`

### Backend: API — extend `listSchema` and `sectionSchema` in `apps/api/src/routes/lists.ts`

- [x] Add `proofRequirement` to `listSchema` in `apps/api/src/routes/lists.ts` (AC: 1)
  - [x] `proofRequirement: z.enum(['none', 'photo', 'watchMode', 'healthKit']).nullable()`
  - [x] Update `stubList()` to include `proofRequirement: null`
  - [x] Existing tests continue to pass — `proofRequirement: null` is the safe default (additive, non-breaking)

- [x] Add `proofRequirement` to `sectionSchema` in `apps/api/src/routes/lists.ts` (AC: 1)
  - [x] `proofRequirement: z.enum(['none', 'photo', 'watchMode', 'healthKit']).nullable()`
  - [x] Update any stub section fixtures to include `proofRequirement: null`

- [x] Add `PATCH /v1/lists/{id}/accountability` endpoint in `apps/api/src/routes/lists.ts` (AC: 1)
  - [x] Request body schema: `{ proofRequirement: z.enum(['none', 'photo', 'watchMode', 'healthKit']).nullable() }`
  - [x] Response 200: `{ data: <full listSchema with updated proofRequirement> }`
  - [x] Response 403: caller is not the list owner
  - [x] Response 404: list not found
  - [x] Response 422: invalid requirement value (Zod parse error)
  - [x] Stub: return 200 with `stubList({ proofRequirement: body.proofRequirement })`; add `TODO(impl): verify ownership from JWT, update lists table via Drizzle, cascade to tasks where proofModeIsCustom = false`
  - [x] Tag: `'Lists'`
  - [x] Register BEFORE the parameterized `PATCH /v1/lists/{id}` route (same rule as `PATCH /v1/lists/{id}/settings` — specific before parameterized)
  - [x] Use `@hono/zod-openapi` `createRoute` pattern — no untyped routes
  - [x] Use `.js` extensions for all local imports

- [x] Add `PATCH /v1/sections/{id}/accountability` endpoint in `apps/api/src/routes/lists.ts` (AC: 1)
  - [x] Request body schema: `{ proofRequirement: z.enum(['none', 'photo', 'watchMode', 'healthKit']).nullable() }`
  - [x] Response 200: `{ data: <sectionSchema with updated proofRequirement> }`
  - [x] Response 403: caller is not a list owner
  - [x] Response 404: section not found
  - [x] Stub: return 200 with the patched section; add `TODO(impl): verify caller is list owner via list_members, update sections table, cascade to tasks in this section where proofModeIsCustom = false`
  - [x] Tag: `'Lists'`
  - [x] Register BEFORE `PATCH /v1/sections/{id}` if that route exists, otherwise add after list-level accountability route
  - [x] Use `.js` extensions for all local imports

### Backend: API — extend `taskSchema` with `proofMode` and `proofModeIsCustom` in `apps/api/src/routes/tasks.ts`

- [x] Add `proofModeIsCustom` to `taskSchema` in `apps/api/src/routes/tasks.ts` (AC: 2)
  - [x] `proofModeIsCustom: z.boolean()` — false by default; true when this task's proofMode differs from its inherited list/section requirement
  - [x] `proofMode` already exists in `currentTaskSchema` (for the Now card) but is NOT yet on the general `taskSchema` — add it there: `proofMode: z.enum(['standard', 'photo', 'watchMode', 'healthKit', 'calendarEvent'])`
  - [x] Update `stubTask()` to include `proofMode: 'standard' as const` and `proofModeIsCustom: false`
  - [x] This is additive/non-breaking: existing callers receive `proofMode: 'standard'` and `proofModeIsCustom: false` as defaults

- [x] Add `PATCH /v1/tasks/{id}/proof-mode` endpoint in `apps/api/src/routes/tasks.ts` — per-task override (AC: 2)
  - [x] Request body schema: `{ proofMode: z.enum(['standard', 'photo', 'watchMode', 'healthKit']) }` (no `calendarEvent` — that is read-only from calendar integration)
  - [x] Response 200: `{ data: <taskSchema with updated proofMode and proofModeIsCustom: true> }`
  - [x] Response 404: task not found
  - [x] Stub: return 200 with `stubTask({ proofMode: body.proofMode, proofModeIsCustom: true })`; add `TODO(impl): set proofMode = body.proofMode, proofModeIsCustom = true in tasks table`
  - [x] Tag: `'Tasks'`
  - [x] Register BEFORE the parameterized `PATCH /v1/tasks/{id}` route
  - [x] Use `.js` extensions for all local imports

### Flutter: Domain models — extend `TaskList`, `Section`, and `Task`

- [x] Add `String? proofRequirement` to `apps/flutter/lib/features/lists/domain/task_list.dart` (AC: 1)
  - [x] Nullable, no `@Default` needed — null means no requirement configured at list level
  - [x] Valid values: `'none'` | `'photo'` | `'watchMode'` | `'healthKit'` | `null`
  - [x] Regenerate `task_list.freezed.dart` — commit generated file

- [x] Add `String? proofRequirement` to `apps/flutter/lib/features/lists/domain/section.dart` (AC: 1)
  - [x] Nullable, no `@Default` needed — null means inherit from parent list
  - [x] Regenerate `section.freezed.dart` — commit generated file

- [x] Add `ProofMode proofMode` and `bool proofModeIsCustom` to `apps/flutter/lib/features/tasks/domain/task.dart` (AC: 1, 2)
  - [x] `@Default(ProofMode.standard) ProofMode proofMode` — defaults to standard (no proof required)
  - [x] `@Default(false) bool proofModeIsCustom` — true when this task has a user-set override
  - [x] Import `ProofMode` from `'../../now/domain/proof_mode.dart'` — it already exists, do NOT create a duplicate
  - [x] Regenerate `task.freezed.dart` — commit generated file

### Flutter: DTOs — propagate new fields through `ListDto`, `SectionDto`, and `TaskDto`

- [x] Add `proofRequirement` to `apps/flutter/lib/features/lists/data/list_dto.dart` (AC: 1)
  - [x] `@JsonKey(defaultValue: null) String? proofRequirement`
  - [x] Extend `toDomain()` to pass `proofRequirement` through
  - [x] Regenerate `list_dto.freezed.dart` and `list_dto.g.dart` — commit both

- [x] Add `proofRequirement` to `apps/flutter/lib/features/lists/data/section_dto.dart` (AC: 1)
  - [x] `@JsonKey(defaultValue: null) String? proofRequirement`
  - [x] Extend `toDomain()` to pass `proofRequirement` through
  - [x] Regenerate `section_dto.freezed.dart` and `section_dto.g.dart` — commit both

- [x] Add `proofMode` and `proofModeIsCustom` to `apps/flutter/lib/features/tasks/data/task_dto.dart` (AC: 1, 2)
  - [x] `@JsonKey(defaultValue: 'standard') String proofMode` — raw string from API
  - [x] `@JsonKey(defaultValue: false) bool proofModeIsCustom`
  - [x] Extend `toDomain()`: convert `proofMode` via `ProofMode.fromJson(proofMode)`, pass `proofModeIsCustom` through
  - [x] Import `ProofMode` from the correct path: `'../../now/domain/proof_mode.dart'`
  - [x] Regenerate `task_dto.freezed.dart` and `task_dto.g.dart` — commit both

### Flutter: Repository methods — add accountability update methods

- [x] Add `updateListAccountability` to `apps/flutter/lib/features/lists/data/lists_repository.dart` (AC: 1)
  - [x] `Future<TaskList> updateListAccountability(String listId, String? proofRequirement)` — `PATCH /v1/lists/$listId/accountability`
  - [x] Request body: `{ 'proofRequirement': proofRequirement }`
  - [x] Parse `response.data!['data']` using `ListDto.fromJson(...)` → `.toDomain()`
  - [x] Regenerate `lists_repository.g.dart` if provider hash changes — commit

- [x] Add `updateSectionAccountability` to `apps/flutter/lib/features/lists/data/sections_repository.dart` (AC: 1)
  - [x] `Future<Section> updateSectionAccountability(String sectionId, String? proofRequirement)` — `PATCH /v1/sections/$sectionId/accountability`
  - [x] Request body: `{ 'proofRequirement': proofRequirement }`
  - [x] Parse `response.data!['data']` using `SectionDto.fromJson(...)` → `.toDomain()`
  - [x] Regenerate `sections_repository.g.dart` if provider hash changes — commit

- [x] Add `setTaskProofMode` to the tasks repository (or `SharingRepository`) — per-task override (AC: 2)
  - [x] Create method in `apps/flutter/lib/features/tasks/data/tasks_repository.dart` (tasks domain operation, not sharing): `Future<Task> setTaskProofMode(String taskId, String proofMode)` — `PATCH /v1/tasks/$taskId/proof-mode`
  - [x] Parse `response.data!['data']` using `TaskDto.fromJson(...)` → `.toDomain()`
  - [x] Regenerate `tasks_repository.g.dart` if provider hash changes — commit

### Flutter: List Settings screen — add accountability section (AC: 1)

- [x] Extend `apps/flutter/lib/features/lists/presentation/list_settings_screen.dart` with a new "Accountability" section below the assignment strategy section (AC: 1)
  - [x] Show four options as a `CupertinoListTile` radio-style list (same pattern as assignment strategy):
    - `null` → label: `AppStrings.accountabilityNone` (no requirement)
    - `'photo'` → label: `AppStrings.accountabilityPhoto`
    - `'watchMode'` → label: `AppStrings.accountabilityWatchMode`
    - `'healthKit'` → label: `AppStrings.accountabilityHealthKit`
  - [x] On selection change: calls `listsRepository.updateListAccountability(listId, newRequirement)` — show loading indicator; on success, `ref.invalidate(listsProvider)` so the list refreshes
  - [x] Section header: `AppStrings.accountabilitySettingsLabel`
  - [x] Error state: show `AppStrings.accountabilityUpdateError` on failure
  - [x] Background: `colors.surfacePrimary` (already set on the screen)
  - [x] `minimumSize: const Size(44, 44)` on any `CupertinoButton`

### Flutter: Section widget — section-level accountability setting (AC: 1)

- [x] Add an accountability picker to `apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart` (AC: 1)
  - [x] Section settings currently does not exist — add a trailing settings icon (`CupertinoIcons.ellipsis_circle`) to the section header row that opens a `CupertinoActionSheet`
  - [x] Action sheet options: Set proof requirement (opens bottom sheet or inline picker), Rename, Delete
  - [x] For "Set proof requirement": show the same four options (None / Photo / Watch Mode / HealthKit) as `CupertinoActionSheet` actions or a `showCupertinoModalPopup` picker
  - [x] On selection: call `sectionsRepository.updateSectionAccountability(section.id, newRequirement)` → `ref.invalidate(sectionsProvider(section.listId))`
  - [x] Only show the settings icon if the current user is a list owner (check `ListMember.role == 'owner'` from `listMembersProvider`) — fallback: show for all users in v1 since ownership is not yet wired in all views
  - [x] Error state: `AppStrings.accountabilityUpdateError`

### Flutter: Task row — show inherited proof requirement label (AC: 1)

- [x] Update `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` to show the proof requirement label when `task.proofMode != ProofMode.standard` (AC: 1)
  - [x] Show a `ProofModeIndicator` widget (already exists at `apps/flutter/lib/features/now/presentation/widgets/proof_mode_indicator.dart`) or a small inline label
  - [x] Use `colors.textSecondary`, SF Pro 13pt — consistent with attribution chip style from Story 5.3
  - [x] When `task.proofModeIsCustom == true`, show the indicator with a "custom" suffix badge (e.g., `AppStrings.accountabilityCustomBadge = 'Custom'`) so the user sees it differs from the section default
  - [x] When `task.proofModeIsCustom == false` and `task.proofMode != ProofMode.standard`, show the indicator with label only (e.g., "Photo proof") with no badge
  - [x] Display-only in v1 — tapping the indicator does nothing in the task row (tapping the full row opens `TaskEditInline`)

### Flutter: Task edit — per-task proof mode override (AC: 2)

- [x] Add a proof mode picker row to `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` (AC: 2)
  - [x] Add a new row below the energy requirement field: "Proof" → shows current `task.proofMode` display name
  - [x] Tapping opens a `CupertinoActionSheet` with options: Standard (no proof), Photo proof, Watch Mode, HealthKit
  - [x] On selection: call `tasksRepository.setTaskProofMode(task.id, selectedMode)` → `ref.invalidate(tasksProvider(task.listId))`
  - [x] When `task.proofModeIsCustom == true`, show the "Custom" badge next to the current value so the user knows they have an override
  - [x] When the user selects "Standard" AND the list/section has a non-null requirement, add a note: `AppStrings.accountabilityOverrideToStandardNote` (e.g., `'This overrides the section default'`)
  - [x] Error state: show inline error text `AppStrings.accountabilityUpdateError` on failure; do not dismiss the picker

### Flutter: l10n strings (AC: 1, 2)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Accountability settings cascade (FR20) ──` section (AC: 1, 2)
  - [x] `static const String accountabilitySettingsLabel = 'Proof requirement';` — section header in List Settings
  - [x] `static const String accountabilityNone = 'None';` — no proof required
  - [x] `static const String accountabilityPhoto = 'Photo proof';` — photo verification
  - [x] `static const String accountabilityWatchMode = 'Watch Mode';` — passive camera session
  - [x] `static const String accountabilityHealthKit = 'HealthKit';` — HealthKit data verification
  - [x] `static const String accountabilityNoneDesc = 'No proof required for tasks in this list.';`
  - [x] `static const String accountabilityPhotoDesc = 'Members must submit a photo when completing tasks.';`
  - [x] `static const String accountabilityWatchModeDesc = 'Tasks require a Watch Mode session to complete.';`
  - [x] `static const String accountabilityHealthKitDesc = 'Completion is verified via HealthKit data.';`
  - [x] `static const String accountabilityCustomBadge = 'Custom';` — shown on task row when proofModeIsCustom = true
  - [x] `static const String accountabilityInheritedLabel = 'Inherited';` — for accessibility labels on inherited indicators
  - [x] `static const String accountabilityUpdateError = 'Could not update proof requirement. Please try again.';`
  - [x] `static const String accountabilityOverrideToStandardNote = 'This overrides the section default.';` — shown when user overrides to None/standard
  - [x] NOTE: `AppStrings.nowCardProofPhoto`, `AppStrings.nowCardProofWatchMode`, `AppStrings.nowCardProofHealthKit` already exist (used by `ProofModeIndicator`) — do NOT duplicate them; reuse where appropriate

### Tests

- [x] Widget test for `ListSettingsScreen` accountability section in `apps/flutter/test/features/lists/list_settings_screen_test.dart` (AC: 1)
  - [x] Extend existing `list_settings_screen_test.dart` (created in Story 5.2)
  - [x] Test: accountability section renders all four options (None, Photo proof, Watch Mode, HealthKit)
  - [x] Test: tapping "Photo proof" calls `updateListAccountability(listId, 'photo')` — stub `listsRepository` with a `mocktail` mock
  - [x] Test: currently selected option shows a checkmark (consistent with assignment strategy UI pattern)
  - [x] Override `listsRepositoryProvider` AND `sharingRepositoryProvider` with stub notifiers — same `ProviderContainer` pattern as Story 5.2 tests

- [x] Widget test for `task_row.dart` proof mode label in `apps/flutter/test/features/tasks/task_row_test.dart` (AC: 1, 2)
  - [x] Create or extend `task_row_test.dart`
  - [x] Test: when `task.proofMode = ProofMode.photo` and `task.proofModeIsCustom = false`, the "Photo proof" label renders (no "Custom" badge)
  - [x] Test: when `task.proofMode = ProofMode.photo` and `task.proofModeIsCustom = true`, both the label and `AppStrings.accountabilityCustomBadge` render
  - [x] Test: when `task.proofMode = ProofMode.standard`, no proof indicator is rendered
  - [x] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

- [x] Unit test for `TaskDto.fromJson` handles `proofMode` and `proofModeIsCustom` in `apps/flutter/test/features/tasks/task_dto_test.dart` (AC: 1, 2)
  - [x] Extend existing `task_dto_test.dart` (created in Story 5.2, extended in Story 5.3)
  - [x] JSON with `proofMode: 'photo'` parses to `ProofMode.photo`
  - [x] JSON with `proofMode: 'watchMode'` parses to `ProofMode.watchMode`
  - [x] JSON WITHOUT `proofMode` (old API stub) parses to `ProofMode.standard` via `@JsonKey(defaultValue: 'standard')`
  - [x] JSON with `proofModeIsCustom: true` parses correctly; WITHOUT the field defaults to `false`

- [x] Unit test for `ListDto.fromJson` handles `proofRequirement` in `apps/flutter/test/features/lists/list_dto_test.dart` (AC: 1)
  - [x] Extend existing `list_dto_test.dart` (created in Story 5.1)
  - [x] JSON with `proofRequirement: 'photo'` parses correctly
  - [x] JSON WITHOUT `proofRequirement` parses to `null` via `@JsonKey(defaultValue: null)`

- [x] Unit test for `SectionDto.fromJson` handles `proofRequirement` in `apps/flutter/test/features/lists/section_dto_test.dart` (AC: 1)
  - [x] Create or extend `section_dto_test.dart`
  - [x] JSON with `proofRequirement: 'watchMode'` parses correctly
  - [x] JSON WITHOUT `proofRequirement` parses to `null`

## Dev Notes

### CRITICAL: `SharingRepository` is NOT used for accountability — use domain-specific repositories

Accountability updates are NOT sharing-domain operations. Route them to their domain repositories:
- **List-level**: `ListsRepository.updateListAccountability()` → `PATCH /v1/lists/{id}/accountability`
- **Section-level**: `SectionsRepository.updateSectionAccountability()` → `PATCH /v1/sections/{id}/accountability`
- **Task-level override**: `TasksRepository.setTaskProofMode()` → `PATCH /v1/tasks/{id}/proof-mode`

`SharingRepository` (`apps/flutter/lib/features/lists/data/sharing_repository.dart`) is for invite/accept/assign operations only.

### CRITICAL: `ProofMode` enum already exists — do NOT recreate it

`ProofMode` is defined at `apps/flutter/lib/features/now/domain/proof_mode.dart` and includes:
```dart
enum ProofMode { standard, photo, watchMode, healthKit, calendarEvent }
```
`ProofMode.fromJson(String? value)` already handles all cases including unknown-value fallback to `standard`.

When adding `proofMode` to `Task` domain model, import from the existing location:
```dart
import '../../now/domain/proof_mode.dart';
```
Do NOT copy or recreate the enum in the tasks feature folder.

### CRITICAL: `proofMode` already exists on `currentTaskSchema` / `NowTask` — no changes needed there

`proofMode` is already on `NowTask` (`apps/flutter/lib/features/now/domain/now_task.dart:24`) and in `currentTaskSchema` (`apps/api/src/routes/tasks.ts:503`). This story adds `proofMode` to the **general** `taskSchema` (line 64–91) and `Task` domain model — a separate path from the Now tab. Do NOT modify `NowTask`, `NowTaskDto`, or `now_task_card.dart`.

### CRITICAL: Migration numbering — next is `0010`

Last committed migration: `0009_task_assignment_strategies.sql`.
Next migration MUST be `0010_accountability_settings_cascade.sql`.
Verify in `packages/core/src/schema/migrations/meta/_journal.json` before generating.

### CRITICAL: Actual file and class names (carried forward from Stories 5.1–5.3)

| Spec name | Actual name | Location |
|---|---|---|
| `invitations.ts` route | `sharing.ts` route | `apps/api/src/routes/sharing.ts` |
| `sharingRouter` export | `sharingRouter` | `apps/api/src/routes/sharing.ts` |
| `InvitationsRepository` | `SharingRepository` | `apps/flutter/lib/features/lists/data/sharing_repository.dart` |
| `invitationsRepositoryProvider` | `sharingRepositoryProvider` | `sharing_repository.g.dart` |
| `InvitationAcceptScreen` | `AcceptInvitationScreen` | `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart` |

### CRITICAL: TypeScript NodeNext — `.js` extensions in all local imports

Any new TypeScript code in `lists.ts`, `tasks.ts`, or any new API file must use `.js` extensions:
```typescript
import { ok, err } from '../lib/response.js'
```

### CRITICAL: `z.record()` requires two arguments

If any Zod schema uses `z.record(...)`, use `z.record(z.string(), valueType)`. This Zod version requires both key AND value type args. Pre-existing pattern from Story 5.2.

### CRITICAL: Committed generated files

Run after any Dart model/provider changes:
```
dart run build_runner build --delete-conflicting-outputs
```

Files that need regeneration in this story:
- `task_list.freezed.dart` — `TaskList` gets `proofRequirement`
- `section.freezed.dart` — `Section` gets `proofRequirement`
- `task.freezed.dart` — `Task` gets `proofMode` and `proofModeIsCustom`
- `list_dto.freezed.dart`, `list_dto.g.dart` — `ListDto` gets `proofRequirement`
- `section_dto.freezed.dart`, `section_dto.g.dart` — `SectionDto` gets `proofRequirement`
- `task_dto.freezed.dart`, `task_dto.g.dart` — `TaskDto` gets `proofMode`, `proofModeIsCustom`
- `lists_repository.g.dart` — new method added (provider hash may change)
- `sections_repository.g.dart` — new method added (provider hash may change)
- `tasks_repository.g.dart` — new method added (provider hash may change — if using `@riverpod` annotation)

Commit ALL regenerated files. No build_runner in CI.

### CRITICAL: Drizzle `casing: 'camelCase'`

Write Drizzle schema columns in camelCase:
- `proofRequirement` → generates `proof_requirement` in DDL
- `proofModeIsCustom` → generates `proof_mode_is_custom` in DDL

Never add manual name mappings — Drizzle handles this automatically via the global `casing: 'camelCase'` config.

### CRITICAL: Widget tests need Riverpod overrides

Any test that touches `ConsumerWidget` or `ConsumerStatefulWidget` MUST override providers:
```dart
final container = ProviderContainer(
  overrides: [
    listsRepositoryProvider.overrideWithValue(FakeListsRepository()),
    sectionsRepositoryProvider.overrideWithValue(FakeSectionsRepository()),
  ],
);
```
Pattern established in Stories 4.1/4.2, 5.1, 5.2.

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

Use `colors.surfacePrimary` for screen/sheet backgrounds. Applies to any new sheets opened from the section widget.

### CRITICAL: `minimumSize: const Size(44, 44)` on `CupertinoButton`

Use `minimumSize: const Size(44, 44)`, NOT the deprecated `minSize`. Consistent pattern across all stories from 3.7 onwards.

### Route registration order in `lists.ts` — specific before parameterized

Current route order in `apps/api/src/routes/lists.ts` (as of Story 5.2):
1. `POST /v1/lists`
2. `GET /v1/lists`
3. `GET /v1/lists/{id}/prediction`
4. `PATCH /v1/lists/{id}/settings` ← added Story 5.2
5. `GET /v1/lists/{id}`
6. `PATCH /v1/lists/{id}`
7. `DELETE /v1/lists/{id}/archive`

Add `PATCH /v1/lists/{id}/accountability` BEFORE `PATCH /v1/lists/{id}` (item 6) — otherwise the parameterized route catches it first. Recommended insertion point: after `PATCH /v1/lists/{id}/settings`.

Add `PATCH /v1/sections/{id}/accountability` — check whether a generic `PATCH /v1/sections/{id}` exists first. If it does, register the accountability endpoint before it.

### Cascade behavior — stub semantics vs. real implementation

**In the stub (this story):** `PATCH /v1/lists/{id}/accountability` returns the updated list with the new `proofRequirement`. It does NOT update individual task rows in the stub (no DB). The Flutter client should trigger a `ref.invalidate(tasksProvider(...))` after a successful list-level update so the task list re-fetches. In production, the API will cascade the update server-side to all tasks in the list where `proofModeIsCustom = false`.

**For display purposes:** The Flutter task row computes its displayed `proofMode` from `task.proofMode` directly (as returned by the API). The server is responsible for propagating the inherited value at query time (or via update cascade). In v1 stub, individual task stubs can return `proofMode: 'standard'` — that's acceptable since stub tasks don't know about list settings.

**Per-task override logic:** When `proofModeIsCustom = true`, the task's own `proofMode` takes precedence and is displayed with the "Custom" badge. When `proofModeIsCustom = false`, the task inherits from its section/list (the API resolves this). In the stub, returning `proofModeIsCustom: false` for all stub tasks is correct.

### `ProofMode.calendarEvent` is read-only

Do NOT include `calendarEvent` as a selectable option in the accountability picker UI. It is set only by calendar integration (Epic 3) and is read-only from the user's perspective. The picker for `PATCH /v1/tasks/{id}/proof-mode` and the task edit UI should only expose: `standard`, `photo`, `watchMode`, `healthKit`.

### API: Accountability update response structures

```typescript
// List-level accountability update
const updateListAccountabilitySchema = z.object({
  proofRequirement: z.enum(['none', 'photo', 'watchMode', 'healthKit']).nullable(),
})

// Section-level accountability update
const updateSectionAccountabilitySchema = z.object({
  proofRequirement: z.enum(['none', 'photo', 'watchMode', 'healthKit']).nullable(),
})

// Task-level proof mode override
const setTaskProofModeSchema = z.object({
  proofMode: z.enum(['standard', 'photo', 'watchMode', 'healthKit']),
  // Note: 'calendarEvent' is NOT accepted here — read-only from calendar
})
```

### `Task` domain model — `proofMode` import path

The `Task` model (`apps/flutter/lib/features/tasks/domain/task.dart`) is in the `tasks` feature. `ProofMode` lives in the `now` feature. Import is cross-feature:
```dart
import '../../now/domain/proof_mode.dart';
```
This cross-feature import is intentional and already established — `NowTask` uses `ProofMode` from the same location, so the enum is the shared source of truth.

### Deferred work carried forward

- **`SharingRepository.getInvitationDetails` field name `inviterName` vs `invitedByName`** — Tracked in `deferred-work.md`. Do NOT fix in this story.
- **`console.log` in stub handlers** — Pre-existing pattern. Leave as-is.
- **Fake test repos instantiate real `ApiClient`** — Pre-existing pattern from 5.1/5.2. Keep consistent.
- **`TaskList.assignmentStrategy` is `String?` not an enum** — Tracked in `deferred-work.md`. Same approach: `proofRequirement` should be `String?` in the domain model (not a sealed type / enum). Zod validates at API boundary.

### UX spec references

From `ux-design-specification.md` (FR20 accountability cascade):
- Proof requirements cascade silently to tasks; tasks display the inherited badge in the metadata row
- The "Custom" indicator on a task signals user intent to deviate from the group standard
- AC1 label on affected tasks: small badge in task row metadata, same visual weight as the assignment badge added in Story 5.2

### Files to Modify

**`packages/core/src/schema/lists.ts`:**
- Add `proofRequirement: text()`

**`packages/core/src/schema/sections.ts`:**
- Add `proofRequirement: text()`

**`packages/core/src/schema/tasks.ts`:**
- Add `proofMode: text()`
- Add `proofModeIsCustom: boolean().default(false).notNull()`

**`apps/api/src/routes/lists.ts`:**
- Add `proofRequirement` to `listSchema` and `sectionSchema`
- Update `stubList()` to include `proofRequirement: null`
- Add `PATCH /v1/lists/{id}/accountability` endpoint
- Add `PATCH /v1/sections/{id}/accountability` endpoint

**`apps/api/src/routes/tasks.ts`:**
- Add `proofMode` and `proofModeIsCustom` to `taskSchema`
- Update `stubTask()` to include `proofMode: 'standard' as const` and `proofModeIsCustom: false`
- Add `PATCH /v1/tasks/{id}/proof-mode` endpoint

**`apps/flutter/lib/features/lists/domain/task_list.dart`:**
- Add `String? proofRequirement`

**`apps/flutter/lib/features/lists/domain/section.dart`:**
- Add `String? proofRequirement`

**`apps/flutter/lib/features/tasks/domain/task.dart`:**
- Add `@Default(ProofMode.standard) ProofMode proofMode`
- Add `@Default(false) bool proofModeIsCustom`

**`apps/flutter/lib/features/lists/data/list_dto.dart`:**
- Add `String? proofRequirement` with `@JsonKey(defaultValue: null)`

**`apps/flutter/lib/features/lists/data/section_dto.dart`:**
- Add `String? proofRequirement` with `@JsonKey(defaultValue: null)`

**`apps/flutter/lib/features/tasks/data/task_dto.dart`:**
- Add `@JsonKey(defaultValue: 'standard') String proofMode`
- Add `@JsonKey(defaultValue: false) bool proofModeIsCustom`

**`apps/flutter/lib/features/lists/data/lists_repository.dart`:**
- Add `updateListAccountability(String listId, String? proofRequirement)`

**`apps/flutter/lib/features/lists/data/sections_repository.dart`:**
- Add `updateSectionAccountability(String sectionId, String? proofRequirement)`

**`apps/flutter/lib/features/tasks/data/tasks_repository.dart`:**
- Add `setTaskProofMode(String taskId, String proofMode)`

**`apps/flutter/lib/features/lists/presentation/list_settings_screen.dart`:**
- Add accountability section below assignment strategy section

**`apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart`:**
- Add settings icon and accountability picker

**`apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`:**
- Show `ProofModeIndicator` + optional "Custom" badge when `task.proofMode != ProofMode.standard`

**`apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart`:**
- Add proof mode picker row

**`apps/flutter/lib/core/l10n/strings.dart`:**
- Add FR20 strings section

### Files to Create (Tests)

**`apps/flutter/test/features/tasks/task_row_test.dart`** (new or extend if exists)

**`apps/flutter/test/features/lists/section_dto_test.dart`** (new or extend if exists)

### Generated files to commit (after `dart run build_runner build --delete-conflicting-outputs`)

- `task_list.freezed.dart`
- `section.freezed.dart`
- `task.freezed.dart`
- `list_dto.freezed.dart`, `list_dto.g.dart`
- `section_dto.freezed.dart`, `section_dto.g.dart`
- `task_dto.freezed.dart`, `task_dto.g.dart`
- `lists_repository.g.dart` (if provider hash changes)
- `sections_repository.g.dart` (if provider hash changes)
- `tasks_repository.g.dart` (if provider hash changes)

### Review Findings

_(None yet — populated during code review)_

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- All backend schema changes, migration, and API stub endpoints implemented as stubs with `TODO(impl)` markers.
- `drizzle-kit generate` was run from `apps/api/`; generated migration was renamed from the random name to `0010_accountability_settings_cascade.sql` and `_journal.json` updated.
- `SectionWidget` converted from `StatefulWidget` to `ConsumerStatefulWidget` to support Riverpod-based repo access for the accountability picker.
- `AppStrings.accountabilityNone = 'None'` collides with `AppStrings.assignmentStrategyNone = 'None'` in tests; resolved by using `findsAtLeastNWidgets(1)`.
- Auto-assign button tests required `tester.drag` scroll of 400px before accessing the button because the new accountability section pushed the button below the test viewport (600px default).
- All 639 Flutter tests pass with no regressions.

### File List

**Backend (packages/core):**
- `packages/core/src/schema/lists.ts`
- `packages/core/src/schema/sections.ts`
- `packages/core/src/schema/tasks.ts`
- `packages/core/src/schema/migrations/0010_accountability_settings_cascade.sql` (new)
- `packages/core/src/schema/migrations/meta/_journal.json`
- `packages/core/src/schema/migrations/meta/0010_snapshot.json` (new)

**Backend (apps/api):**
- `apps/api/src/routes/lists.ts`
- `apps/api/src/routes/tasks.ts`

**Flutter (domain/DTOs/repositories):**
- `apps/flutter/lib/features/lists/domain/task_list.dart`
- `apps/flutter/lib/features/lists/domain/section.dart`
- `apps/flutter/lib/features/tasks/domain/task.dart`
- `apps/flutter/lib/features/lists/data/list_dto.dart`
- `apps/flutter/lib/features/lists/data/section_dto.dart`
- `apps/flutter/lib/features/tasks/data/task_dto.dart`
- `apps/flutter/lib/features/lists/data/lists_repository.dart`
- `apps/flutter/lib/features/lists/data/sections_repository.dart`
- `apps/flutter/lib/features/tasks/data/tasks_repository.dart`
- Generated: `task_list.freezed.dart`, `section.freezed.dart`, `task.freezed.dart`, `list_dto.freezed.dart`, `list_dto.g.dart`, `section_dto.freezed.dart`, `section_dto.g.dart`, `task_dto.freezed.dart`, `task_dto.g.dart`

**Flutter (presentation):**
- `apps/flutter/lib/features/lists/presentation/list_settings_screen.dart`
- `apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart`
- `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`
- `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart`
- `apps/flutter/lib/core/l10n/strings.dart`

**Flutter (tests):**
- `apps/flutter/test/features/lists/list_settings_screen_test.dart` (extended)
- `apps/flutter/test/features/lists/list_dto_test.dart` (extended)
- `apps/flutter/test/features/lists/section_dto_test.dart` (new)
- `apps/flutter/test/features/tasks/task_dto_test.dart` (extended)
- `apps/flutter/test/features/tasks/task_row_test.dart` (new)
