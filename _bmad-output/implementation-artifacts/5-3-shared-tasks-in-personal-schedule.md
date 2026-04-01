# Story 5.3: Shared Tasks in Personal Schedule

Status: ready-for-dev

## Story

As a list member,
I want tasks assigned to me in a shared list to appear in my personal schedule,
so that I don't have to track work in two separate places.

## Acceptance Criteria

1. **Given** a task in a shared list is assigned to a member **When** the assignment is made **Then** the task automatically appears in that member's personal task list under the shared list (FR19) **And** the scheduling engine includes it in their personal schedule recalculation

2. **Given** an assigned task is scheduled for a member **When** the member views the Now tab card for that task **Then** the card shows attribution: "from [List Name] · assigned by [Name]"

3. **Given** a task is unassigned or reassigned **When** the change is applied **Then** the task is removed from the previous assignee's personal schedule within 60 seconds

## Tasks / Subtasks

### Backend: Extend `GET /v1/tasks` to include assigned tasks from shared lists (AC: 1)

- [ ] Update `GET /v1/tasks` stub in `apps/api/src/routes/tasks.ts` to include tasks where `assignedToUserId` matches the caller (AC: 1)
  - [ ] Add stub tasks that simulate assigned tasks from a shared list: include a `stubTask()` entry with `assignedToUserId: '<some-uuid>'`, `listId: '<shared-list-id>'`, and a `listName` field
  - [ ] Add `listName: z.string().nullable()` to `taskSchema` in `tasks.ts` — the caller needs to know which list the task belongs to for display purposes
  - [ ] Update `stubTask()` helper to include `listName: null` as the default (non-breaking)
  - [ ] Add `TODO(impl): query tasks WHERE assignedToUserId = jwt.sub UNION tasks WHERE userId = jwt.sub; join lists table for listName`
  - [ ] No change to route registration order needed — this extends the existing `GET /v1/tasks` handler

- [ ] Update `GET /v1/tasks/current` stub to demonstrate assigned-task attribution (AC: 2)
  - [ ] `currentTaskSchema` already extends `taskSchema` with `listName` and `assignorName` — verify both are present (they are — see existing schema at line 490–495 of `tasks.ts`)
  - [ ] Update stub handler to periodically return a task with `listName: 'Household'` and `assignorName: 'Jordan'` to exercise the attribution path
  - [ ] Alternatively: add a second stub response toggled by a query param `?demo=assigned` so tests can exercise it deterministically
  - [ ] Add `TODO(impl): look up assignorName from list_members where userId = task.assignedToUserId; resolve listName from lists table`

### Backend: Unassign endpoint — remove task from previous assignee's schedule (AC: 3)

- [ ] Add `DELETE /v1/lists/{id}/tasks/{taskId}/assignment` endpoint in `apps/api/src/routes/sharing.ts` (AC: 3)
  - [ ] Request: no body
  - [ ] Response 200: `{ data: { taskId, listId, previousAssigneeId: string | null } }`
  - [ ] Response 404: list or task not found
  - [ ] Response 422: task does not belong to this list
  - [ ] Stub: return 200 with `{ taskId, listId, previousAssigneeId: 'some-uuid' }`; add `TODO(impl): read current assignedToUserId, set to NULL, trigger schedule recalculation for previousAssigneeId`
  - [ ] Tag: `'Sharing'`
  - [ ] Register BEFORE any catch-all parameterized routes in `sharing.ts`
  - [ ] Route path: `/v1/lists/{id}/tasks/{taskId}/assignment` — nested resource deletion pattern

### Flutter: Domain model — add `listName` to `Task` (AC: 1)

- [ ] Add `String? listName` to `apps/flutter/lib/features/tasks/domain/task.dart` (AC: 1)
  - [ ] Nullable, no `@Default` needed — Freezed treats nullable as implicitly `@Default(null)`
  - [ ] Regenerate `task.freezed.dart` — commit generated file
  - [ ] This is display-only metadata; the field is populated when fetched from the API and is not user-editable

### Flutter: DTO — propagate `listName` through `TaskDto` (AC: 1)

- [ ] Extend `TaskDto` in `apps/flutter/lib/features/tasks/data/task_dto.dart` (AC: 1)
  - [ ] Add `@JsonKey(defaultValue: null) String? listName`
  - [ ] Extend `toDomain()` to pass `listName` through
  - [ ] Regenerate `task_dto.freezed.dart` and `task_dto.g.dart` — commit both

### Flutter: Repository — unassign task method in `SharingRepository` (AC: 3)

- [ ] Add `unassignTask` method to `apps/flutter/lib/features/lists/data/sharing_repository.dart` (AC: 3)
  - [ ] `Future<Map<String, dynamic>> unassignTask(String listId, String taskId)` — `DELETE /v1/lists/$listId/tasks/$taskId/assignment`
  - [ ] Parse `response.data!['data']` — return raw map (same pattern as existing `shareList()`, `acceptInvitation()`, `assignTask()`)
  - [ ] Use `_client.dio.delete(...)` — Dio supports DELETE with no body
  - [ ] Regenerate `sharing_repository.g.dart` if provider hash changes — commit

### Flutter: Today tab task row — show list attribution for assigned tasks (AC: 1)

- [ ] Update `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` to show list attribution when `task.listName != null` (AC: 1)
  - [ ] Check the existing `today_task_row.dart` for how it currently handles `task.listId` or `task.listName` — add a small chip or inline text showing the list name below/beside the task title when `task.listName != null`
  - [ ] Style: `colors.textSecondary`, SF Pro 13pt — consistent with `UX-DS` spec for Today row attribution
  - [ ] Use `AppStrings.taskFromListLabel` (new string — see l10n section below) for the chip/label
  - [ ] This is display-only; no tap action required in v1

### Flutter: Now tab — attribution already implemented; verify correct strings fire (AC: 2)

- [ ] Verify `now_task_card.dart` `_buildAttribution()` already handles `listName + assignorName` case (AC: 2)
  - [ ] CONFIRMED: `_buildAttribution()` at line 426–437 already returns `AppStrings.nowCardAttributionFromListAndAssignor` when both `listName` and `assignorName` are non-null — format: `"from [List Name] · assigned by [Name]"`
  - [ ] CONFIRMED: `AppStrings.nowCardAttributionFromListAndAssignor = 'From {listName} \u00b7 assigned by {assignor}'` at `strings.dart:424`
  - [ ] No changes needed to `now_task_card.dart` or `now_task_card_test.dart` for AC2 — the UI layer already supports this
  - [ ] The only work is ensuring the API stub for `GET /v1/tasks/current` can return an assigned task, and that `NowTask.assignorName` is populated correctly
  - [ ] `NowTask.assignorName` is already present in the domain model (`now_task.dart:22`) and DTO (`now_task_dto.dart:23`) — no model changes needed

### Flutter: Task list screen — assigned tasks appear under the shared list (AC: 1)

- [ ] Verify that `apps/flutter/lib/features/tasks/presentation/tasks_screen.dart` (or `list_detail_screen.dart`) renders tasks where `assignedToUserId` matches the current user (AC: 1)
  - [ ] Current `tasksProvider` calls `GET /v1/lists/{id}/tasks` or `GET /v1/tasks` — when a task's `assignedToUserId` matches the current user, it will be returned by the API and rendered automatically once the API stub is updated
  - [ ] No Flutter code change required if the tasks provider already fetches from the correct endpoint — verify this is the case by checking `tasks_provider.dart` and `tasks_repository.dart`
  - [ ] If the provider only fetches tasks by list (not by user-wide assignment), add a `GET /v1/tasks?assignedToMe=true` stub endpoint (or extend the existing `GET /v1/tasks` stub to include cross-list assigned tasks)
  - [ ] The task row will automatically show the list name chip (new `listName` field) for assigned tasks from shared lists

### Flutter: l10n strings (AC: 1, 2, 3)

- [ ] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Shared tasks in personal schedule (FR19) ──` section (AC: 1, 2, 3)
  - [ ] `static const String taskFromListLabel = 'from {listName}';` — Today-tab attribution chip for tasks from shared lists
  - [ ] `static const String taskAssignedByLabel = 'Assigned by {name}';` — accessibility label for assignor attribution
  - [ ] `static const String taskUnassignSuccess = 'Task unassigned.';` — feedback after unassign
  - [ ] `static const String taskUnassignError = 'Could not unassign task. Please try again.';`
  - [ ] NOTE: `AppStrings.nowCardAttributionFromListAndAssignor` already exists at line 424 — do NOT duplicate it

### Tests

- [ ] Widget test for `NowTaskCard` attribution rendering in `apps/flutter/test/features/now/now_task_card_test.dart` (AC: 2)
  - [ ] Create or extend existing `now_task_card_test.dart`
  - [ ] Test: when `task.listName = 'Household'` and `task.assignorName = 'Jordan'`, attribution text `'From Household · assigned by Jordan'` is rendered
  - [ ] Test: when only `task.listName = 'Household'` (no assignorName), attribution text `'From Household'` is rendered
  - [ ] Test: when neither field is set, attribution shows default `AppStrings.nowCardAttribution` ("Your past self")
  - [ ] `NowTaskCard` is a plain `StatefulWidget` — NO provider overrides needed; pass `NowTask` directly via constructor
  - [ ] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

- [ ] Unit test for `TaskDto.fromJson` handles `listName` in `apps/flutter/test/features/tasks/task_dto_test.dart` (AC: 1)
  - [ ] Extend existing `task_dto_test.dart` (created in Story 5.2)
  - [ ] JSON with `listName: 'Household'` parses correctly
  - [ ] JSON WITHOUT `listName` (old API stub) parses to `null` via `@JsonKey(defaultValue: null)`

- [ ] Widget test for `SharingRepository.unassignTask` in `apps/flutter/test/features/lists/sharing_repository_test.dart` (AC: 3)
  - [ ] Create if not exists; extend if it does
  - [ ] Stub a `MockDio` / `mocktail` mock that returns 200 with `{ data: { taskId, listId, previousAssigneeId } }`
  - [ ] Verify `unassignTask('list-id', 'task-id')` fires a `DELETE` request to `/v1/lists/list-id/tasks/task-id/assignment`
  - [ ] Override `sharingRepositoryProvider` with a stub if mounting a widget; otherwise test the repository directly

## Dev Notes

### CRITICAL: `listName` already flows through the Now tab — no model changes there

`NowTask` and `NowTaskDto` already have `listName` and `assignorName` fields (committed in earlier stories). The `_buildAttribution()` method in `now_task_card.dart` at line 426 already handles the "from [List Name] · assigned by [Name]" case. **Do NOT touch `now_task.dart`, `now_task_dto.dart`, or `now_task_card.dart`** — they are complete for AC2. The only Now-tab work is confirming the API stub can exercise the path.

### CRITICAL: `taskSchema` — `listName` is new; update `stubTask()` default

Adding `listName` to `taskSchema` in `apps/api/src/routes/tasks.ts` is an **additive non-breaking change** because:
- All existing `stubTask()` callers will pick up `listName: null` from the updated `stubTask()` default
- No existing test assertions should break — they check for specific fields, not exhaustive schemas
- Follow the same pattern used for `assignedToUserId: null` in Story 5.2

### CRITICAL: Route registration in `sharing.ts` — specific before parameterized

The new `DELETE /v1/lists/{id}/tasks/{taskId}/assignment` route uses two path parameters. In Hono, register it BEFORE any route that would shadow it (e.g., a future `DELETE /v1/lists/{id}`). Current `sharing.ts` route order (as of Story 5.2):
1. `POST /v1/lists/{id}/share`
2. `GET /v1/lists/{id}/members`
3. `POST /v1/lists/{id}/assign` ← specific before GET members
4. `POST /v1/lists/{id}/auto-assign`

Add `DELETE /v1/lists/{id}/tasks/{taskId}/assignment` after item 4. This path is unique enough (3-level nesting) to avoid shadowing issues, but register at the top of the sharing router as a best practice.

### CRITICAL: `SharingRepository` is the correct repository for unassignment

`unassignTask()` belongs in `apps/flutter/lib/features/lists/data/sharing_repository.dart` — NOT in `lists_repository.dart` or `tasks_repository.dart`. Established pattern: all sharing-domain operations (invite, accept, assign, auto-assign) live in `SharingRepository`.

### CRITICAL: Actual file names (Story 5.1 deviation)

As documented in Story 5.2, the actual names differ from original specs:

| Spec name | Actual name |
|---|---|
| `invitations.ts` route | `sharing.ts` route |
| `InvitationsRepository` | `SharingRepository` |
| `invitationsRepositoryProvider` | `sharingRepositoryProvider` |

### CRITICAL: Migration NOT required for this story

Story 5.2 already added `assignedToUserId` to the `tasks` table (migration `0009_task_assignment_strategies.sql`). This story does NOT add new DB columns — it only extends API stubs and Flutter behavior to surface that data correctly. **Next migration if needed will be `0010_*`.**

### CRITICAL: Drizzle `casing: 'camelCase'`

No new schema files in this story. But if any API stub references Drizzle schema directly, remember: write columns as camelCase (`assignedToUserId`), Drizzle maps to `assigned_to_user_id` in DDL automatically.

### CRITICAL: TypeScript NodeNext — `.js` extensions in all local imports

Any new TypeScript code in `apps/api/src/routes/sharing.ts` must use `.js` extensions for local imports:
```typescript
import { ok, err } from '../lib/response.js'
```

### CRITICAL: `z.record()` requires two arguments

If any new Zod schema uses `z.record(...)`, use `z.record(z.string(), z.string())`.

### CRITICAL: Committed generated files

Run after any Dart model/provider changes:
```
dart run build_runner build --delete-conflicting-outputs
```

Files that may need regeneration in this story:
- `task.freezed.dart` — if `Task` gets `listName` field
- `task_dto.freezed.dart`, `task_dto.g.dart` — when `TaskDto` gets `listName`
- `sharing_repository.g.dart` — when `unassignTask()` is added (provider hash may change)

Commit ALL regenerated files.

### CRITICAL: Widget tests need Riverpod overrides

Any test that touches `ConsumerWidget` or `ConsumerStatefulWidget` MUST override providers:
```dart
final container = ProviderContainer(
  overrides: [
    sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
  ],
);
```
Pattern established in Stories 4.1/4.2, 5.1, 5.2.

The `NowTaskCard` attribution test does NOT need provider overrides — `NowTaskCard` is a plain `StatefulWidget` that accepts `NowTask` directly via constructor.

### CRITICAL: `surfacePrimary` not `backgroundPrimary`

`OnTaskColors` uses `colors.surfacePrimary`, NOT `backgroundPrimary`. Applies if any new screens/sheets are added. No new screens in this story.

### CRITICAL: `minimumSize: const Size(44, 44)` on CupertinoButton

Use `minimumSize: const Size(44, 44)`, NOT `minSize`. Pattern across all post-Story-3.7 widgets.

### 60-second removal SLA (AC3)

AC3 requires removed tasks disappear from the previous assignee's schedule "within 60 seconds." In v1 stub form this means:
- The API `DELETE` endpoint sets `assignedToUserId = null` in the stub response
- Flutter calls `unassignTask()`, which should then trigger `ref.invalidate(tasksProvider)` or equivalent to force a re-fetch
- The actual real-time propagation (WebSocket or polling) is deferred to Epic 8 (notifications infrastructure)
- For now: stub the DELETE call and invalidate the local Riverpod state — the 60-second SLA is a backend guarantee for production; in v1 it's satisfied by the immediate client-side state update after the API call

### API: Unassignment response structure

```typescript
const unassignTaskResponseSchema = z.object({
  taskId: z.string().uuid(),
  listId: z.string().uuid(),
  previousAssigneeId: z.string().uuid().nullable(),
})
```

### API: `GET /v1/tasks/current` stub assignor resolution

The `assignorName` in `currentTaskSchema` is resolved server-side by looking up the assigning member from `list_members` where `userId = task.assignedByUserId`. There is no `assignedByUserId` field yet — Story 5.2 only added `assignedToUserId`. In v1 stub: hardcode `assignorName: 'Jordan'` when `task.assignedToUserId` is non-null, null otherwise.

### Deferred work carried forward

- **`SharingRepository.getInvitationDetails` field name `inviterName` vs `invitedByName`** — Tracked in `deferred-work.md`. Do NOT fix in this story.
- **`console.log` in stub handlers** — Pre-existing, tracked in `deferred-work.md`. Consistent pattern; leave as-is.
- **Fake test repos instantiate real `ApiClient`** — Pre-existing pattern from 5.1/5.2. Keep consistent; don't refactor.

### UX spec references

From `ux-design-specification.md` line 1570:
> Now tab attribution: SF Pro 13pt, `color.text.secondary`, "[Name] assigned this · [list name]". Today row: assignor name in the metadata chip, list colour dot.

The **Now tab** uses the existing `_buildAttribution()` logic which produces `"From {listName} · assigned by {assignor}"` (New York italic, 15pt). This matches the UX intent. No change needed.

The **Today row** shows a metadata chip with assignor name and list colour dot. Implement as a simple text label for v1 (the list colour dot requires list colour tracking which is not in scope); use `AppStrings.taskFromListLabel`.

### Files to Create

None (all new functionality extends existing files or adds new endpoints to existing route files).

### Files to Modify

**`apps/api/src/routes/tasks.ts`:**
- Add `listName: z.string().nullable()` to `taskSchema`
- Update `stubTask()` to include `listName: null`
- Update `GET /v1/tasks` stub to include a simulated assigned task
- Update `GET /v1/tasks/current` stub to exercise `assignorName` path

**`apps/api/src/routes/sharing.ts`:**
- Add `DELETE /v1/lists/{id}/tasks/{taskId}/assignment` endpoint

**`apps/flutter/lib/features/tasks/domain/task.dart`:**
- Add `String? listName`

**`apps/flutter/lib/features/tasks/domain/task.freezed.dart`:**
- Regenerated

**`apps/flutter/lib/features/tasks/data/task_dto.dart`:**
- Add `String? listName` with `@JsonKey(defaultValue: null)`

**`apps/flutter/lib/features/tasks/data/task_dto.freezed.dart`:**
- Regenerated

**`apps/flutter/lib/features/tasks/data/task_dto.g.dart`:**
- Regenerated

**`apps/flutter/lib/features/lists/data/sharing_repository.dart`:**
- Add `unassignTask(String listId, String taskId)` method

**`apps/flutter/lib/features/lists/data/sharing_repository.g.dart`:**
- Regenerated if provider hash changes

**`apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart`:**
- Show list attribution chip when `task.listName != null`

**`apps/flutter/lib/core/l10n/strings.dart`:**
- Add FR19 strings section

### Files to Create (Tests)

**`apps/flutter/test/features/now/`:**
- `now_task_card_test.dart` (new — or extend if exists)

**`apps/flutter/test/features/lists/`:**
- `sharing_repository_test.dart` (new — or extend if exists)

**`apps/flutter/test/features/tasks/`:**
- `task_dto_test.dart` (extend existing — created in Story 5.2)

### Review Findings

- [ ] [Review][Patch] Unused `proof_mode.dart` import in `now_task_card_test.dart` [`apps/flutter/test/features/now/now_task_card_test.dart:6`] — `import 'package:ontask/features/now/domain/proof_mode.dart'` is imported but `ProofMode` is never referenced in the file. Will trigger `unused_import` lint warning. Remove the import.
- [ ] [Review][Patch] `sharing_repository_test.dart` tests a fake override, not the real `dio.delete()` call [`apps/flutter/test/features/lists/sharing_repository_test.dart`] — `_RecordingFakeRepository` overrides `unassignTask()` entirely, so the test never exercises the actual `_client.dio.delete('/v1/lists/$listId/tasks/$taskId/assignment')` call in `SharingRepository`. Critical check #9 (verify DELETE fires to correct URL) is not met. Replace with a `MockDio`/`mocktail` setup or `HttpMock` that intercepts the real HTTP call, similar to the approach in Story 5.2 test patterns — or at minimum add a test that instantiates a real `SharingRepository` with a mock `Dio` and verifies the URL and method.
- [ ] [Review][Patch] `today_screen.dart` never passes `listName` to `TodayTaskRow` — attribution chip never renders [`apps/flutter/lib/features/today/presentation/today_screen.dart:523`] — `TodayTaskRow(...)` call in `today_screen.dart` does not pass `listName: task.listName`. The attribution chip added to the widget is wired up correctly in the widget itself, but the call site omits the field, so the chip will never appear for assigned tasks. Add `listName: task.listName` to the `TodayTaskRow` constructor call.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
