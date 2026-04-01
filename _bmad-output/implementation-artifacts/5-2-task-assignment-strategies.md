# Story 5.2: Task Assignment Strategies

Status: review

## Story

As a list owner,
I want to configure how tasks are distributed among members,
so that work is balanced fairly without manual assignment overhead.

## Acceptance Criteria

1. **Given** a list owner opens List Settings **When** they choose an assignment strategy **Then** available options are: round-robin, least-busy, and AI-assisted balancing (FR17) **And** round-robin assigns tasks in rotation across active members in join order **And** least-busy assigns to the member with the fewest scheduled tasks in the current due-date window **And** AI-assisted balancing considers task duration, member workload, and declared energy preferences

2. **Given** any assignment strategy is active **When** a task is assigned **Then** the same task is never assigned to more than one member within the same due-date window (FR18)

## Tasks / Subtasks

### Backend: DB schema — add `assignmentStrategy` to `lists` table

- [x] Add `assignmentStrategy` column to `packages/core/src/schema/lists.ts` (AC: 1)
  - [x] Column: `assignmentStrategy: text()` — nullable, no default (null means no strategy configured)
  - [x] Valid values: `'round-robin'` | `'least-busy'` | `'ai-assisted'` | `null`
  - [x] Follow existing `lists.ts` pattern: camelCase column name, no FK, no enum type (use text with application-level validation)

- [x] Add `assignedToUserId` column to `packages/core/src/schema/tasks.ts` (AC: 1, 2)
  - [x] Column: `assignedToUserId: uuid()` — nullable (null = unassigned)
  - [x] No FK constraint — follow the established `userId` / `listId` pattern: `// TODO(story-TBD): FK to users table when users schema is finalized`
  - [x] This field records the result of assignment by any strategy

- [x] Add `roundRobinIndex` column to `packages/core/src/schema/list-members.ts` (AC: 1)
  - [x] Column: `roundRobinIndex: integer().default(0).notNull()` — tracks this member's position in the round-robin rotation sequence (0-based)
  - [x] Drizzle camelCase: write `roundRobinIndex`, DDL generates `round_robin_index`

- [x] Generate migration `packages/core/src/schema/migrations/0009_task_assignment_strategies.sql` (AC: 1, 2)
  - [x] Run `pnpm drizzle-kit generate` from `packages/core/` to produce the migration file
  - [x] Migration must: ADD `assignment_strategy` column to `lists`, ADD `assigned_to_user_id` column to `tasks`, ADD `round_robin_index` column to `list_members`
  - [x] Commit generated SQL file, updated `meta/_journal.json`, and `meta/0009_snapshot.json`

### Backend: API — List Settings endpoints in `apps/api/src/routes/lists.ts`

- [x] Extend `listSchema` in `apps/api/src/routes/lists.ts` with the new field (AC: 1)
  - [x] Add `assignmentStrategy: z.enum(['round-robin', 'least-busy', 'ai-assisted']).nullable()` to `listSchema`
  - [x] Update `stubList()` to include `assignmentStrategy: null`
  - [x] Existing tests that mock `listSchema` must continue to pass — `assignmentStrategy: null` is the safe default

- [x] Add `PATCH /v1/lists/{id}/settings` endpoint for updating assignment strategy (AC: 1)
  - [x] Request body schema: `{ assignmentStrategy: z.enum(['round-robin', 'least-busy', 'ai-assisted']).nullable() }`
  - [x] Response 200: `{ data: <full listSchema with updated assignmentStrategy> }`
  - [x] Response 403: caller is not the list owner
  - [x] Response 404: list not found
  - [x] Response 422: invalid strategy value (Zod parse error)
  - [x] Stub: return 200 with `stubList({ assignmentStrategy: body.assignmentStrategy })`; add `TODO(impl): verify ownership from JWT, update lists table via Drizzle`
  - [x] Tag: `'Lists'`
  - [x] Register BEFORE the parameterized `PATCH /v1/lists/{id}` route (which is catch-all for general list updates)
  - [x] Use `@hono/zod-openapi` `createRoute` pattern — no untyped routes

### Backend: API — Task assignment endpoints in `apps/api/src/routes/sharing.ts`

All new routes added to the existing `apps/api/src/routes/sharing.ts` file (exported as `sharingRouter`).

- [x] Extend `listMemberSchema` in `sharing.ts` to include `roundRobinIndex: z.number().int()` (AC: 1)
  - [x] This field is needed for the round-robin rotation display/logic

- [x] Add `POST /v1/lists/{id}/assign` — manually assign a specific task to a specific member (AC: 1, 2)
  - [x] Request body: `{ taskId: z.string().uuid(), assignedToUserId: z.string().uuid() }`
  - [x] Response 200: `{ data: { taskId, assignedToUserId, listId } }`
  - [x] Response 404: list or task not found
  - [x] Response 409: task already assigned to a different member in the same due-date window (FR18)
  - [x] Response 422: task does not belong to this list
  - [x] Stub: return 200 with static data; add `TODO(impl): verify membership, enforce FR18 uniqueness constraint, write assignedToUserId to tasks table`
  - [x] Tag: `'Sharing'`
  - [x] Register BEFORE `GET /v1/lists/{id}/members` in file (specific sub-paths before general ones)

- [x] Add `POST /v1/lists/{id}/auto-assign` — trigger strategy-based auto-assignment for all unassigned tasks in a list (AC: 1, 2)
  - [x] Request body: empty (`{}`)
  - [x] Response 200: `{ data: { assigned: number, strategy: string, assignments: [{ taskId, assignedToUserId }] } }`
  - [x] Response 400: no assignment strategy configured on this list
  - [x] Response 403: caller is not the list owner
  - [x] Response 404: list not found
  - [x] Stub: return 200 with static assignments using `stubMembers()`; add `TODO(impl): implement round-robin, least-busy, AI-assisted logic; enforce FR18 uniqueness`
  - [x] Tag: `'Sharing'`

### Backend: API — Task response extension in `apps/api/src/routes/tasks.ts`

- [x] Extend `taskSchema` in `apps/api/src/routes/tasks.ts` to include `assignedToUserId` (AC: 1, 2)
  - [x] Add `assignedToUserId: z.string().uuid().nullable()` to the existing `taskSchema`
  - [x] Update all `stubTask()` calls to include `assignedToUserId: null` as the default
  - [x] No breaking change: existing API consumers receive `null` for unassigned tasks

### Flutter: Domain model extension

- [x] Extend `Task` domain model in `apps/flutter/lib/features/tasks/domain/task.dart` (AC: 1, 2)
  - [x] Add `String? assignedToUserId` — nullable, no `@Default` needed (nullable fields default to null in Freezed)
  - [x] Regenerate `task.freezed.dart` — commit generated file

- [x] Extend `TaskList` domain model in `apps/flutter/lib/features/lists/domain/task_list.dart` (AC: 1)
  - [x] Add `String? assignmentStrategy` — nullable, no `@Default` needed
  - [x] Regenerate `task_list.freezed.dart` — commit generated file

- [x] Extend `ListMember` domain model in `apps/flutter/lib/features/lists/domain/list_member.dart` (AC: 1)
  - [x] Add `@Default(0) int roundRobinIndex` — Freezed `@Default` syntax, not nullable
  - [x] Regenerate `list_member.freezed.dart` — commit generated file

### Flutter: DTO extension

- [x] Extend `TaskDto` in `apps/flutter/lib/features/tasks/data/task_dto.dart` (AC: 1, 2)
  - [x] Add `@JsonKey(defaultValue: null) String? assignedToUserId`
  - [x] Extend `toDomain()` to pass `assignedToUserId` through
  - [x] Regenerate `task_dto.freezed.dart` and `task_dto.g.dart` — commit

- [x] Extend `ListDto` in `apps/flutter/lib/features/lists/data/list_dto.dart` (AC: 1)
  - [x] Add `@JsonKey(defaultValue: null) String? assignmentStrategy`
  - [x] Extend `toDomain()` to pass `assignmentStrategy` through
  - [x] Regenerate `list_dto.freezed.dart` and `list_dto.g.dart` — commit

- [x] Extend `ListMemberDto` in `apps/flutter/lib/features/lists/data/list_member_dto.dart` (AC: 1)
  - [x] Add `@JsonKey(defaultValue: 0) int roundRobinIndex` to the DTO
  - [x] Extend `toDomain()` to pass `roundRobinIndex` through
  - [x] Regenerate `list_member_dto.freezed.dart` and `list_member_dto.g.dart` — commit

### Flutter: Repository methods

- [x] Add assignment methods to `apps/flutter/lib/features/lists/data/sharing_repository.dart` (AC: 1, 2)
  - [x] `Future<Map<String, dynamic>> assignTask(String listId, String taskId, String assignedToUserId)` — `POST /v1/lists/$listId/assign`
  - [x] `Future<Map<String, dynamic>> autoAssign(String listId)` — `POST /v1/lists/$listId/auto-assign`
  - [x] Parse `response.data!['data']` — return raw map (same pattern as existing `shareList()` and `acceptInvitation()`)
  - [x] `SharingRepository` is the correct repository for these — do NOT add to `lists_repository.dart` (see Project Structure Notes)

- [x] Add strategy update method to `apps/flutter/lib/features/lists/data/lists_repository.dart` (AC: 1)
  - [x] `Future<TaskList> updateAssignmentStrategy(String listId, String? strategy)` — `PATCH /v1/lists/$listId/settings`
  - [x] Parse `response.data!['data']` using `ListDto.fromJson(...)` → `.toDomain()`
  - [x] Regenerate `lists_repository.g.dart` if provider hash changes — commit

### Flutter: List Settings screen (new)

- [x] Create `apps/flutter/lib/features/lists/presentation/list_settings_screen.dart` (AC: 1)
  - [x] `ConsumerStatefulWidget` — receives `listId` via constructor param
  - [x] On mount: reads current list from `listsProvider` (already in scope via `ref.watch`) — no separate API call
  - [x] Shows three strategy options as a segmented or radio-style control using `CupertinoSlidingSegmentedControl` or `CupertinoListTile` rows with checkmarks:
    - `'round-robin'` → label: `AppStrings.assignmentStrategyRoundRobin`
    - `'least-busy'` → label: `AppStrings.assignmentStrategyLeastBusy`
    - `'ai-assisted'` → label: `AppStrings.assignmentStrategyAiAssisted`
    - `null` → label: `AppStrings.assignmentStrategyNone` (no strategy / off)
  - [x] On selection change: calls `listsRepository.updateAssignmentStrategy(listId, newStrategy)` — show loading indicator while in-flight; on success, invalidate `listsProvider` via `ref.invalidate(listsProvider)` so the list row updates
  - [x] "Auto-assign now" `CupertinoButton` (enabled only when strategy != null): calls `sharingRepository.autoAssign(listId)` — show snackbar/toast on completion with count of tasks assigned
  - [x] Uses `colors.surfacePrimary` as background
  - [x] `minimumSize: const Size(44, 44)` on any `CupertinoButton`
  - [x] Error states: show `AppStrings.assignmentStrategyUpdateError` on failure

- [x] Register `/lists/:id/settings` route in `apps/flutter/lib/core/router/app_router.dart` (AC: 1)
  - [x] Route path: `/lists/:id/settings`
  - [x] Builder: `ListSettingsScreen(listId: state.pathParameters['id']!)`
  - [x] Register BEFORE `/lists/:id` catch-all route (specific before parameterized — same rule as API)

- [x] Add "Settings" entry point to `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart` (AC: 1)
  - [x] Add a "Settings" `CupertinoButton` to the `CupertinoNavigationBar` trailing area (alongside the existing "Share" button)
  - [x] Only show when NOT in multi-select mode (`_isMultiSelectMode == false`)
  - [x] On tap: `context.push('/lists/${widget.listId}/settings')`
  - [x] Icon: `CupertinoIcons.settings` or text "Settings" — use icon to avoid crowding the nav bar with the existing "Share" text button

### Flutter: Assignment badge on task rows (AC: 1, 2 visibility)

- [x] Update `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` to show assignee badge when `task.assignedToUserId != null` (AC: 1, 2)
  - [x] Show a small avatar-initials circle (same style as shared indicator in `ListsScreen`) when `task.assignedToUserId` is set
  - [x] Derive initials: look up member from `ListMembersNotifier` by `userId` — if unavailable (not loaded or member not found), show a generic person icon (`CupertinoIcons.person`)
  - [x] Keep the badge lightweight — 20×20 circle, `colors.accentPrimary` background, white text
  - [x] This is display-only; tapping it does nothing in v1

### Flutter: l10n strings

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Task assignment strategies (FR17-18) ──` section (AC: 1)
  - [x] `static const String listSettingsTitle = 'List Settings';` — screen title
  - [x] `static const String assignmentStrategyLabel = 'Assignment strategy';` — section heading
  - [x] `static const String assignmentStrategyNone = 'None';` — no strategy configured
  - [x] `static const String assignmentStrategyRoundRobin = 'Round-robin';` — rotate through members
  - [x] `static const String assignmentStrategyLeastBusy = 'Least busy';` — fewest tasks in window
  - [x] `static const String assignmentStrategyAiAssisted = 'AI-assisted';` — considers duration + energy
  - [x] `static const String assignmentStrategyRoundRobinDesc = 'Tasks rotate through members in join order.';`
  - [x] `static const String assignmentStrategyLeastBusyDesc = 'Assigns to the member with fewest tasks in the due-date window.';`
  - [x] `static const String assignmentStrategyAiAssistedDesc = 'Considers task duration, workload, and energy preferences.';`
  - [x] `static const String assignmentAutoAssignButton = 'Auto-assign now';` — CTA
  - [x] `static const String assignmentAutoAssignSuccess = '{count} tasks assigned.';` — feedback
  - [x] `static const String assignmentStrategyUpdateError = 'Could not update strategy. Please try again.';`
  - [x] `static const String taskAssignedToLabel = 'Assigned';` — accessibility label for assignment badge

### Tests

- [x] Widget test for `ListSettingsScreen` in `apps/flutter/test/features/lists/list_settings_screen_test.dart` (AC: 1)
  - [x] Screen renders all four strategy options (None, Round-robin, Least busy, AI-assisted)
  - [x] Tapping "Round-robin" calls `updateAssignmentStrategy(listId, 'round-robin')` — stub `listsRepository` with a `mocktail` mock
  - [x] "Auto-assign now" button is disabled when strategy is `null`; enabled when strategy is set
  - [x] Override `listsRepositoryProvider` AND `sharingRepositoryProvider` with stub notifiers — same `ProviderContainer` override pattern as Story 5.1 tests
  - [x] Do NOT mount with real `Dio` — override prevents real network calls

- [x] Unit test for `ListDto.fromJson` handles `assignmentStrategy` in `apps/flutter/test/features/lists/list_dto_test.dart` (AC: 1)
  - [x] Add to existing `list_dto_test.dart` created in Story 5.1 (or create it if not committed yet)
  - [x] JSON with `assignmentStrategy: 'round-robin'` parses correctly
  - [x] JSON WITHOUT `assignmentStrategy` field (old API stub) parses to `null` via `@JsonKey(defaultValue: null)`

- [x] Unit test for `TaskDto.fromJson` handles `assignedToUserId` in `apps/flutter/test/features/tasks/task_dto_test.dart` (AC: 2)
  - [x] Create `apps/flutter/test/features/tasks/task_dto_test.dart` if it does not exist
  - [x] JSON with `assignedToUserId: 'some-uuid'` parses correctly
  - [x] JSON WITHOUT `assignedToUserId` parses to `null`

## Dev Notes

### CRITICAL: Route registration order in `lists.ts`

The current `lists.ts` route order is:
1. `POST /v1/lists`
2. `GET /v1/lists`
3. `GET /v1/lists/{id}/prediction` ← specific before `{id}`
4. `GET /v1/lists/{id}`
5. `PATCH /v1/lists/{id}`
6. `DELETE /v1/lists/{id}/archive`

New endpoint `PATCH /v1/lists/{id}/settings` MUST be registered BEFORE `PATCH /v1/lists/{id}` — otherwise Hono's `PATCH /v1/lists/:id` catches the request first. Add it after `GET /v1/lists/{id}/prediction` and before `GET /v1/lists/{id}`.

### CRITICAL: GoRouter `/lists/:id/settings` before `/lists/:id`

Same rule applies in GoRouter. Register `/lists/:id/settings` (specific) BEFORE `/lists/:id` (parameterized) in `app_router.dart`. The router already has `/lists/:id` for `ListDetailScreen` — add the new settings route above it.

### CRITICAL: `SharingRepository` is the correct repository for assignment

Story 5.1 created `apps/flutter/lib/features/lists/data/sharing_repository.dart` (named `SharingRepository`, provider: `sharingRepositoryProvider`). This is the right place for `assignTask()` and `autoAssign()` — these are sharing-domain operations. Do NOT add them to `lists_repository.dart`.

### CRITICAL: Story 5.1 deviation — actual file/class names differ from spec

Story 5.1's implementation deviated from the spec in several ways that remain unresolved. Use actual names:

| Spec name | Actual name | Where |
|---|---|---|
| `invitations.ts` route | `sharing.ts` route | `apps/api/src/routes/sharing.ts` |
| `invitationsRouter` export | `sharingRouter` export | `apps/api/src/routes/sharing.ts` |
| `invitations_repository.dart` | `sharing_repository.dart` | `apps/flutter/lib/features/lists/data/` |
| `InvitationsRepository` class | `SharingRepository` class | same file |
| `invitationsRepositoryProvider` | `sharingRepositoryProvider` | `sharing_repository.g.dart` |
| `InvitationAcceptScreen` | `AcceptInvitationScreen` | `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart` |
| `/invitation/:token` GoRouter path | `/invitation/:token` | `app_router.dart` line 130 — confirmed correct |

For this story: add new sharing-related routes to `apps/api/src/routes/sharing.ts` (not a new file); use `SharingRepository` / `sharingRepositoryProvider` in Flutter.

### CRITICAL: Migration numbering

Last migration committed is `0008_list_sharing.sql`. Next migration MUST be `0009_task_assignment_strategies.sql`. Verify in `packages/core/src/schema/migrations/meta/_journal.json` before generating.

### CRITICAL: Drizzle `casing: 'camelCase'`

Write Drizzle schema columns in camelCase — `assignmentStrategy`, `assignedToUserId`, `roundRobinIndex`. Drizzle generates `assignment_strategy`, `assigned_to_user_id`, `round_robin_index` in the DDL automatically. Never add manual name mapping.

### CRITICAL: TypeScript NodeNext — `.js` extensions in all local imports

Every new `import` in `sharing.ts`, `lists.ts`, or any new API file must use `.js` extension for local files:
```typescript
import { ok, err } from '../lib/response.js'
import { sharingRouter } from './routes/sharing.js'
```

### CRITICAL: `z.record()` requires two arguments

If any Zod schema needs `z.record(...)`, use `z.record(z.string(), z.string())`. This Zod version requires both key AND value type args.

### CRITICAL: Freezed — use `@Default` for new fields with defaults on existing models

When adding `roundRobinIndex` to `ListMember` (existing Freezed class), use `@Default(0) int roundRobinIndex` — NOT `int? roundRobinIndex`. This keeps the API clean and avoids null-checks downstream.

For nullable new fields on existing Freezed classes (`assignedToUserId` on `Task`, `assignmentStrategy` on `TaskList`), use `String? fieldName` — no `@Default` needed. Freezed treats nullable fields as implicitly `@Default(null)`.

### CRITICAL: Committed generated files

All `.freezed.dart` and `.g.dart` files MUST be committed. Run:
```
dart run build_runner build --delete-conflicting-outputs
```
after any Dart model/provider changes. Commit ALL regenerated files, including:
- `task.freezed.dart` (modified — `Task` extended)
- `task_list.freezed.dart` (modified — `TaskList` extended)
- `list_member.freezed.dart` (modified — `ListMember` extended)
- `task_dto.freezed.dart`, `task_dto.g.dart` (modified)
- `list_dto.freezed.dart`, `list_dto.g.dart` (modified)
- `list_member_dto.freezed.dart`, `list_member_dto.g.dart` (modified)
- `lists_repository.g.dart` (may regenerate due to provider hash)
- `sharing_repository.g.dart` (new methods added — provider hash may change)

### CRITICAL: Widget tests need Riverpod overrides

Any test that touches `ConsumerWidget` or `ConsumerStatefulWidget` MUST override providers:
```dart
final container = ProviderContainer(
  overrides: [
    listsRepositoryProvider.overrideWithValue(FakeListsRepository()),
    sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
  ],
);
```
Pattern established in Stories 4.1/4.2 and used in Story 5.1 tests.

### CRITICAL: `surfacePrimary` not `backgroundPrimary`

`OnTaskColors` has `surfacePrimary`, NOT `backgroundPrimary`. Use `colors.surfacePrimary` for screen/sheet backgrounds in `ListSettingsScreen`. Established across Stories 3.6, 4.1, 4.2, 4.3, 5.1.

### CRITICAL: `minimumSize: const Size(44, 44)` on CupertinoButton

Use `minimumSize: const Size(44, 44)`, NOT `minSize`. Consistent with Stories 3.7, 4.1, 4.2, 4.3, 5.1.

### AI-assisted strategy: stub only in v1

The AI-assisted balancing strategy (FR17) uses `task.energyRequirement`, member workload counts, and `task.durationMinutes` as inputs for AI scoring. In this story, `ai-assisted` is a valid selectable option with full API stub — but the actual AI call (Vercel AI SDK via Cloudflare AI Gateway) is deferred with a `TODO(impl)`. The Flutter UI fully supports selecting AI-assisted; `autoAssign` returns static stub assignments when `ai-assisted` is the active strategy. No `packages/ai` changes required in this story.

### Deferred work carried forward from Story 5.1

One open item from the Story 5.1 review is relevant here:
- **`SharingRepository.getInvitationDetails` field name `inviterName` vs `invitedByName`** — This is a known inconsistency in `sharing_repository.dart` line 43. Do NOT fix it in this story; it is tracked in `deferred-work.md`. Touching it would be out of scope and could require regenerating files unnecessarily.

### API: `PATCH /v1/lists/{id}/settings` structure

```typescript
// In apps/api/src/routes/lists.ts
const updateListSettingsSchema = z.object({
  assignmentStrategy: z.enum(['round-robin', 'least-busy', 'ai-assisted']).nullable(),
})

const updateListSettingsRoute = createRoute({
  method: 'patch',
  path: '/v1/lists/{id}/settings',
  tags: ['Lists'],
  // ...
})
```

### API: Assignment response structure

```typescript
const assignTaskResponseSchema = z.object({
  taskId: z.string().uuid(),
  assignedToUserId: z.string().uuid(),
  listId: z.string().uuid(),
})

const autoAssignResponseSchema = z.object({
  assigned: z.number().int(),
  strategy: z.string(),
  assignments: z.array(z.object({
    taskId: z.string().uuid(),
    assignedToUserId: z.string().uuid(),
  })),
})
```

### Files to Create

**`apps/flutter/lib/features/lists/presentation/`:**
- `list_settings_screen.dart` (new)

**`apps/flutter/test/features/lists/`:**
- `list_settings_screen_test.dart` (new)

**`apps/flutter/test/features/tasks/`:**
- `task_dto_test.dart` (new — or add to existing if created)

**`packages/core/src/schema/migrations/`:**
- `0009_task_assignment_strategies.sql` (generated by `drizzle-kit generate`)
- `meta/0009_snapshot.json` (generated)
- `meta/_journal.json` (updated by generator)

### Files to Modify

**`packages/core/src/schema/`:**
- `lists.ts` — add `assignmentStrategy` column
- `tasks.ts` — add `assignedToUserId` column
- `list-members.ts` — add `roundRobinIndex` column

**`apps/api/src/routes/`:**
- `lists.ts` — add `assignmentStrategy` to `listSchema` + `stubList()`, add `PATCH /v1/lists/{id}/settings`
- `sharing.ts` — extend `listMemberSchema` with `roundRobinIndex`, add `POST /v1/lists/{id}/assign`, `POST /v1/lists/{id}/auto-assign`
- `tasks.ts` — add `assignedToUserId` to `taskSchema` + `stubTask()`

**`apps/flutter/lib/features/tasks/domain/`:**
- `task.dart` — add `assignedToUserId`
- `task.freezed.dart` — regenerated

**`apps/flutter/lib/features/lists/domain/`:**
- `task_list.dart` — add `assignmentStrategy`
- `task_list.freezed.dart` — regenerated
- `list_member.dart` — add `roundRobinIndex`
- `list_member.freezed.dart` — regenerated

**`apps/flutter/lib/features/tasks/data/`:**
- `task_dto.dart` — add `assignedToUserId`
- `task_dto.freezed.dart` — regenerated
- `task_dto.g.dart` — regenerated

**`apps/flutter/lib/features/lists/data/`:**
- `list_dto.dart` — add `assignmentStrategy`
- `list_dto.freezed.dart` — regenerated
- `list_dto.g.dart` — regenerated
- `list_member_dto.dart` — add `roundRobinIndex`
- `list_member_dto.freezed.dart` — regenerated
- `list_member_dto.g.dart` — regenerated
- `lists_repository.dart` — add `updateAssignmentStrategy()`
- `lists_repository.g.dart` — regenerated (provider hash update)
- `sharing_repository.dart` — add `assignTask()`, `autoAssign()`
- `sharing_repository.g.dart` — regenerated (provider hash update)

**`apps/flutter/lib/features/tasks/presentation/widgets/`:**
- `task_row.dart` — add assignee badge when `task.assignedToUserId != null`

**`apps/flutter/lib/features/lists/presentation/`:**
- `list_detail_screen.dart` — add "Settings" nav bar button

**`apps/flutter/lib/core/l10n/strings.dart`** — add assignment strategy strings section

**`apps/flutter/lib/core/router/app_router.dart`** — add `/lists/:id/settings` route

### Project Structure Notes

- No new top-level feature directories needed — assignment stays within `lists/` and `tasks/` features
- `list_settings_screen.dart` lives in `lists/presentation/` — consistent with `list_detail_screen.dart`
- All assignment API routes (both manual and auto-assign) go in `sharing.ts`, not `lists.ts` — they are member-coordination operations, not list-management operations
- Strategy configuration (`PATCH /v1/lists/{id}/settings`) goes in `lists.ts` — it modifies the list entity itself
- No changes to `packages/scheduling/`, `packages/ai/`, `apps/mcp/`, or `apps/admin/`
- 100% test coverage NOT enforced for `apps/api` or `apps/flutter` (only `packages/ai` and `packages/scheduling`)

### References

- FR17: Task assignment strategies — [Source: `_bmad-output/planning-artifacts/epics.md#Story-5.2`]
- FR18: No duplicate assignment in same due-date window — [Source: `_bmad-output/planning-artifacts/epics.md#Story-5.2`]
- `SharingRepository` / `sharingRouter` naming — [Source: Story 5.1 implementation; `apps/flutter/lib/features/lists/data/sharing_repository.dart`; `apps/api/src/routes/sharing.ts`]
- `casing: 'camelCase'` Drizzle config — [Source: `_bmad-output/planning-artifacts/architecture.md#Database Driver`]
- Route registration (specific before parameterized) — [Source: Story 5.1 Dev Notes; `apps/api/src/routes/lists.ts`]
- Migration numbering: last is `0008_list_sharing.sql` → next is `0009_task_assignment_strategies.sql` — [Source: `packages/core/src/schema/migrations/meta/_journal.json`]
- `z.record()` two-argument requirement — [Source: Stories 4.1, 5.1 Dev Notes]
- `.js` extensions in TS imports — [Source: Stories 4.1, 5.1 Dev Notes]
- `surfacePrimary` not `backgroundPrimary` — [Source: Stories 3.6, 4.1, 4.2, 4.3, 5.1 Dev Notes]
- `minimumSize: const Size(44, 44)` — [Source: Stories 3.7, 4.1, 4.2, 4.3, 5.1 Dev Notes]
- Generated `.freezed.dart` and `.g.dart` committed — [Source: `_bmad-output/planning-artifacts/architecture.md#CI/CD`]
- Widget tests with Riverpod stub overrides — [Source: Stories 4.1, 4.2, 5.1 Dev Notes]
- `Task.energyRequirement` field for AI-assisted input — [Source: `packages/core/src/schema/tasks.ts:24`; `apps/flutter/lib/features/tasks/domain/task.dart`]
- `Task.durationMinutes` field for AI-assisted input — [Source: `apps/flutter/lib/features/tasks/domain/task.dart:40`]
- `@Default(0) int roundRobinIndex` Freezed syntax — [Source: Story 5.1 Dev Notes; `apps/flutter/lib/features/lists/domain/task_list.dart`]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation completed without blockers.

### Completion Notes List

- Added `assignmentStrategy` (text, nullable) to `lists` schema; `assignedToUserId` (uuid, nullable) to `tasks` schema; `roundRobinIndex` (integer, default 0) to `list_members` schema. Drizzle camelCase naming applied throughout.
- Generated migration `0009_task_assignment_strategies.sql` using drizzle-kit from `apps/api/` (where `drizzle.config.ts` lives). Migration is a clean ALTER TABLE — not a CREATE TABLE, because the snapshot correctly reflects the pre-existing state from migration 0008.
- API: `PATCH /v1/lists/{id}/settings` added to `lists.ts`, registered before `GET /v1/lists/{id}` as required. `POST /v1/lists/{id}/assign` and `POST /v1/lists/{id}/auto-assign` added to `sharing.ts`, registered before `GET /v1/lists/{id}/members`. All endpoints use `createRoute` / `@hono/zod-openapi` pattern with full response schemas.
- `listSchema` extended with `assignmentStrategy: z.enum([...]).nullable()`. `taskSchema` extended with `assignedToUserId`. `listMemberSchema` extended with `roundRobinIndex`. `stubList()`, `stubTask()`, `stubMembers()` all updated with safe defaults.
- Flutter domain models (`Task`, `TaskList`, `ListMember`) extended. All DTOs (`TaskDto`, `ListDto`, `ListMemberDto`) extended with `@JsonKey(defaultValue:...)` for backward compatibility. All Freezed/json_serializable files regenerated.
- `SharingRepository.assignTask()` and `SharingRepository.autoAssign()` added. `ListsRepository.updateAssignmentStrategy()` added.
- `ListSettingsScreen` created as `ConsumerStatefulWidget` with radio-style strategy selection (CupertinoListTile rows with checkmarks), "Auto-assign now" CupertinoButton (disabled when strategy null), `surfacePrimary` background, `minimumSize: const Size(44, 44)`.
- GoRouter: `/lists/:id/settings` route added BEFORE `/lists/:id` in the `StatefulShellBranch` routes.
- `ListDetailScreen` trailing area: `CupertinoIcons.settings` button added (not in multi-select mode), navigates to `/lists/$listId/settings`.
- `TaskRow`: `_AssigneeBadge` widget added — 20x20 circle with `accentPrimary` background showing member initials or generic person icon. Optional `listMembers` parameter added.
- 13 l10n strings added to `AppStrings` under `// ── Task assignment strategies (FR17-18) ──` section.
- Tests: 5 widget tests for `ListSettingsScreen`, 4 new unit tests for `ListDto` (assignmentStrategy), 5 unit tests for `TaskDto` (assignedToUserId). All 612 Flutter tests pass, 0 regressions.
- Note: `inviterName` vs `invitedByName` inconsistency in `SharingRepository.getInvitationDetails` left untouched per Dev Notes (tracked in deferred-work.md).

### File List

**New files:**
- `packages/core/src/schema/migrations/0009_task_assignment_strategies.sql`
- `packages/core/src/schema/migrations/meta/0009_snapshot.json`
- `apps/flutter/lib/features/lists/presentation/list_settings_screen.dart`
- `apps/flutter/test/features/lists/list_settings_screen_test.dart`
- `apps/flutter/test/features/tasks/task_dto_test.dart`

**Modified files:**
- `packages/core/src/schema/migrations/meta/_journal.json`
- `packages/core/src/schema/lists.ts`
- `packages/core/src/schema/tasks.ts`
- `packages/core/src/schema/list-members.ts`
- `apps/api/src/routes/lists.ts`
- `apps/api/src/routes/sharing.ts`
- `apps/api/src/routes/tasks.ts`
- `apps/flutter/lib/features/tasks/domain/task.dart`
- `apps/flutter/lib/features/tasks/domain/task.freezed.dart`
- `apps/flutter/lib/features/lists/domain/task_list.dart`
- `apps/flutter/lib/features/lists/domain/task_list.freezed.dart`
- `apps/flutter/lib/features/lists/domain/list_member.dart`
- `apps/flutter/lib/features/lists/domain/list_member.freezed.dart`
- `apps/flutter/lib/features/tasks/data/task_dto.dart`
- `apps/flutter/lib/features/tasks/data/task_dto.freezed.dart`
- `apps/flutter/lib/features/tasks/data/task_dto.g.dart`
- `apps/flutter/lib/features/lists/data/list_dto.dart`
- `apps/flutter/lib/features/lists/data/list_dto.freezed.dart`
- `apps/flutter/lib/features/lists/data/list_dto.g.dart`
- `apps/flutter/lib/features/lists/data/list_member_dto.dart`
- `apps/flutter/lib/features/lists/data/list_member_dto.freezed.dart`
- `apps/flutter/lib/features/lists/data/list_member_dto.g.dart`
- `apps/flutter/lib/features/lists/data/lists_repository.dart`
- `apps/flutter/lib/features/lists/data/lists_repository.g.dart`
- `apps/flutter/lib/features/lists/data/sharing_repository.dart`
- `apps/flutter/lib/features/lists/data/sharing_repository.g.dart`
- `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`
- `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart`
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/flutter/lib/core/router/app_router.dart`
- `apps/flutter/lib/core/router/app_router.g.dart`
- `apps/flutter/test/features/lists/list_dto_test.dart`


## Change Log

- 2026-04-01: Story 5.2 implemented — DB schema (3 new columns), API (3 new endpoints + 3 schema extensions), Flutter domain models + DTOs + repositories + ListSettingsScreen + assignee badge + l10n strings + router. All 612 tests pass.
