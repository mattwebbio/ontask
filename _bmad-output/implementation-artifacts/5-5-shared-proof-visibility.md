# Story 5.5: Shared Proof Visibility

Status: ready-for-dev

## Story

As a list member,
I want to view proof submitted by other members for tasks they completed,
so that we can all see the evidence and stay accountable to each other.

## Acceptance Criteria

1. **Given** a member completes a task with retained proof **When** another member views that task in the shared list **Then** they can access the submitted proof (photo, video, or document) from the task detail view (FR21) **And** proof is scoped to members of the shared list only — inaccessible to anyone outside the list (NFR-S4)

2. **Given** a member submits proof for a shared list task **When** the proof is retained and verified **Then** other members receive a notification that the task was completed — notification delivery is implemented in Story 8.4 (not required to pass this story)

## Tasks / Subtasks

### Backend: DB schema — add `proofMediaUrl` and `proofRetained` to `tasks` table (AC: 1)

- [ ] Add `proofRetained` column to `packages/core/src/schema/tasks.ts` (AC: 1)
  - [ ] Column: `proofRetained: boolean().default(false).notNull()` — true when the user chose "Keep as completion record" (FR38, Story 7.7)
  - [ ] Follows camelCase convention; Drizzle generates `proof_retained` in DDL automatically
- [ ] Add `proofMediaUrl` column to `packages/core/src/schema/tasks.ts` (AC: 1)
  - [ ] Column: `proofMediaUrl: text()` — nullable; presigned URL or storage path for photo/video/document proof (FR21, NFR-S4)
  - [ ] In production this will be a private Backblaze B2 object URL scoped to list members (NFR-S4) — in stub: a fixed dummy URL
- [ ] Generate migration `packages/core/src/schema/migrations/0011_shared_proof_visibility.sql` (AC: 1)
  - [ ] Run `pnpm drizzle-kit generate` from `packages/core/` to produce the migration
  - [ ] Migration must: ADD `proof_retained` to `tasks`, ADD `proof_media_url` to `tasks`
  - [ ] Commit generated SQL, updated `meta/_journal.json`, and `meta/0011_snapshot.json`

### Backend: API — extend `taskSchema` with proof visibility fields (AC: 1)

- [ ] Add `proofRetained` and `proofMediaUrl` to `taskSchema` in `apps/api/src/routes/tasks.ts` (AC: 1)
  - [ ] `proofRetained: z.boolean()` — false by default; true when proof is retained as a completion record
  - [ ] `proofMediaUrl: z.string().url().nullable()` — null if no retained proof; presigned URL when proof available
  - [ ] Update `stubTask()` to include `proofRetained: false` and `proofMediaUrl: null`
  - [ ] This is additive/non-breaking: all existing callers get `proofRetained: false`, `proofMediaUrl: null`

- [ ] Add `GET /v1/tasks/{id}/proof` endpoint in `apps/api/src/routes/tasks.ts` (AC: 1)
  - [ ] Request params: `{ id: z.string().uuid() }` — task ID
  - [ ] Response 200: `{ data: { taskId: string, proofMediaUrl: string | null, proofRetained: boolean, completedAt: string | null, completedByUserId: string | null, completedByName: string | null } }`
  - [ ] Response 403: caller is not a member of the list this task belongs to
  - [ ] Response 404: task not found
  - [ ] Stub: return 200 with hardcoded proof data; add `TODO(impl): verify caller is a list_member for the task's listId; return presigned Backblaze B2 URL with short TTL (15 min) scoped to caller JWT`
  - [ ] Stub response when task IS completed with retained proof: `{ taskId, proofMediaUrl: 'https://example.com/stub-proof.jpg', proofRetained: true, completedAt: '<recent ISO string>', completedByUserId: '<uuid>', completedByName: 'Jordan' }`
  - [ ] Stub response when task is NOT completed or proof not retained: `{ taskId, proofMediaUrl: null, proofRetained: false, completedAt: null, completedByUserId: null, completedByName: null }`
  - [ ] Toggle which stub is returned based on a query param `?demo=withProof` so Flutter tests can deterministically exercise both paths
  - [ ] Tag: `'Tasks'`
  - [ ] Register BEFORE the parameterized `PATCH /v1/tasks/{id}` route — specific before parameterized rule
  - [ ] Use `.js` extensions for all local imports
  - [ ] Use `@hono/zod-openapi` `createRoute` pattern — no untyped routes

- [ ] Update `GET /v1/tasks` stub to demonstrate proof visibility (AC: 1)
  - [ ] Include one stub completed task with `completedAt` set, `proofRetained: true`, and `proofMediaUrl: 'https://example.com/stub-proof.jpg'` to exercise the proof indicator in the UI
  - [ ] Other tasks retain `proofRetained: false`, `proofMediaUrl: null` as before

### Backend: API — add `completedByName` to task response (AC: 1)

- [ ] Add `completedByName` to `taskSchema` in `apps/api/src/routes/tasks.ts` (AC: 1)
  - [ ] `completedByName: z.string().nullable()` — display name of the member who completed the task; null if task is incomplete or completer is unknown
  - [ ] Update `stubTask()` to include `completedByName: null`
  - [ ] Add `TODO(impl): resolve completedByName from list_members where userId = tasks.completedByUserId; join on listId`
  - [ ] This is additive/non-breaking

### Flutter: Domain model — extend `Task` with proof visibility fields (AC: 1)

- [ ] Add `String? proofMediaUrl`, `bool proofRetained`, and `String? completedByName` to `apps/flutter/lib/features/tasks/domain/task.dart` (AC: 1)
  - [ ] `String? proofMediaUrl` — nullable; the URL to the proof media (photo/video/doc)
  - [ ] `@Default(false) bool proofRetained` — false by default; true when proof has been retained
  - [ ] `String? completedByName` — display name of member who completed the task; null when incomplete or unknown
  - [ ] Do NOT recreate `ProofMode` — already imported from `'../../now/domain/proof_mode.dart'`
  - [ ] Regenerate `task.freezed.dart` — commit generated file

### Flutter: DTO — propagate proof visibility fields through `TaskDto` (AC: 1)

- [ ] Extend `TaskDto` in `apps/flutter/lib/features/tasks/data/task_dto.dart` (AC: 1)
  - [ ] `@JsonKey(defaultValue: null) String? proofMediaUrl`
  - [ ] `@JsonKey(defaultValue: false) bool proofRetained`
  - [ ] `@JsonKey(defaultValue: null) String? completedByName`
  - [ ] Extend `toDomain()` to pass all three fields through
  - [ ] Regenerate `task_dto.freezed.dart` and `task_dto.g.dart` — commit both

### Flutter: Repository — add `getTaskProof` method (AC: 1)

- [ ] Add `getTaskProof` method to `apps/flutter/lib/features/tasks/data/tasks_repository.dart` (AC: 1)
  - [ ] `Future<Map<String, dynamic>> getTaskProof(String taskId)` — `GET /v1/tasks/$taskId/proof`
  - [ ] Parse `response.data!['data']` — return raw map (same `response.data!['data']` pattern as other repository methods)
  - [ ] Use `_client.dio.get('/v1/tasks/$taskId/proof')`
  - [ ] This is a domain operation (not sharing), so it belongs in `TasksRepository` — NOT in `SharingRepository`
  - [ ] Regenerate `tasks_repository.g.dart` if provider hash changes — commit

### Flutter: Task row — show proof retained indicator for completed tasks (AC: 1)

- [ ] Update `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` to show a proof indicator when `task.completedAt != null && task.proofRetained == true` (AC: 1)
  - [ ] Show a small icon or chip (e.g., `CupertinoIcons.camera_viewfinder` or `CupertinoIcons.doc_checkmark`) alongside or below the task title
  - [ ] Style: `colors.textSecondary`, SF Pro 13pt — consistent with attribution chip style from Stories 5.3 and 5.4
  - [ ] Label: `AppStrings.proofRetainedLabel` (new string — see l10n section below)
  - [ ] When `task.completedByName != null`, show: `AppStrings.proofCompletedByLabel` with `{name}` substitution (e.g., "Jordan submitted proof")
  - [ ] When `task.completedByName == null` (own task), show: `AppStrings.proofRetainedLabel` (e.g., "Proof submitted")
  - [ ] Tapping this indicator opens the proof detail sheet (see below)
  - [ ] When `task.completedAt != null && task.proofRetained == false`, show no proof indicator (proof was discarded or not required)
  - [ ] When `task.completedAt == null`, show no proof indicator (task not yet completed)

### Flutter: Proof detail bottom sheet (AC: 1)

- [ ] Create `apps/flutter/lib/features/tasks/presentation/widgets/task_proof_sheet.dart` (AC: 1)
  - [ ] A `showCupertinoModalPopup`-based bottom sheet that displays proof media for a completed task
  - [ ] Accept constructor params: `String taskId`, `String? proofMediaUrl`, `String? completedByName`, `DateTime? completedAt`
  - [ ] If `proofMediaUrl != null`: show the proof media inline using `Image.network(proofMediaUrl, fit: BoxFit.contain)` in a scrollable view
  - [ ] If `proofMediaUrl == null`: show a placeholder with `AppStrings.proofNotAvailableMessage` (e.g., "Proof not available or was discarded.")
  - [ ] Show completedByName and completedAt as metadata: "Completed by [name] · [date/time]" using `AppStrings.proofCompletedByAtLabel` — use `AppStrings.proofCompletedByLabel` fallback if completedByName is null
  - [ ] Sheet header: `AppStrings.proofDetailTitle` (e.g., "Proof")
  - [ ] Close button: `CupertinoIcons.xmark` — taps pop the modal
  - [ ] Background: `colors.surfacePrimary` (NOT `backgroundPrimary`)
  - [ ] Any `CupertinoButton`: `minimumSize: const Size(44, 44)`
  - [ ] Loading state: show `CupertinoActivityIndicator` while the image loads
  - [ ] Error state: show `AppStrings.proofLoadError` if `Image.network` fails
  - [ ] Privacy note: `AppStrings.proofPrivacyNote` — "Visible to list members only" — shown as secondary footer text

### Flutter: Task row — wire proof sheet open from indicator tap (AC: 1)

- [ ] In `task_row.dart`, when the proof indicator is tapped, call `getTaskProof(task.id)` via `tasksRepositoryProvider`, then open `TaskProofSheet` with the result (AC: 1)
  - [ ] Use `ref.read(tasksRepositoryProvider).getTaskProof(task.id)` — this is inside a `ConsumerWidget` or pass ref via callback
  - [ ] Show `CupertinoActivityIndicator` during the API call
  - [ ] On success: open `TaskProofSheet` via `showCupertinoModalPopup`
  - [ ] On error: show a `CupertinoAlertDialog` with title `AppStrings.dialogErrorTitle` and message `AppStrings.proofLoadError`; action `AppStrings.actionOk`

### Flutter: l10n strings (AC: 1)

- [ ] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Shared proof visibility (FR21) ──` section (AC: 1)
  - [ ] `static const String proofRetainedLabel = 'Proof submitted';` — shown on task row when proof is retained (own task)
  - [ ] `static const String proofCompletedByLabel = '{name} submitted proof';` — shown on task row when another member submitted proof
  - [ ] `static const String proofCompletedByAtLabel = 'Completed by {name} · {dateTime}';` — metadata in proof sheet
  - [ ] `static const String proofDetailTitle = 'Proof';` — bottom sheet header
  - [ ] `static const String proofNotAvailableMessage = 'Proof not available or was discarded.';`
  - [ ] `static const String proofLoadError = 'Could not load proof. Please try again.';`
  - [ ] `static const String proofPrivacyNote = 'Visible to list members only.';`
  - [ ] NOTE: `AppStrings.nowCardSubmitProof`, `AppStrings.nowCardProofPhoto`, `AppStrings.nowCardProofWatchMode`, `AppStrings.nowCardProofHealthKit` already exist — do NOT duplicate
  - [ ] NOTE: `AppStrings.dialogErrorTitle`, `AppStrings.actionOk` already exist from Story 5.4 — do NOT recreate

### Tests

- [ ] Unit test for `TaskDto.fromJson` handles `proofRetained`, `proofMediaUrl`, `completedByName` in `apps/flutter/test/features/tasks/task_dto_test.dart` (AC: 1)
  - [ ] Extend existing `task_dto_test.dart` (created in Story 5.2, extended in 5.3 and 5.4)
  - [ ] JSON with `proofRetained: true` and `proofMediaUrl: 'https://example.com/proof.jpg'` parses correctly
  - [ ] JSON WITHOUT `proofRetained` parses to `false` via `@JsonKey(defaultValue: false)`
  - [ ] JSON WITHOUT `proofMediaUrl` parses to `null` via `@JsonKey(defaultValue: null)`
  - [ ] JSON with `completedByName: 'Jordan'` parses correctly; absent field parses to null

- [ ] Widget test for proof indicator in `apps/flutter/test/features/tasks/task_row_test.dart` (AC: 1)
  - [ ] Extend existing `task_row_test.dart` (created in Story 5.4)
  - [ ] Test: when `task.completedAt != null && task.proofRetained == true && task.completedByName == 'Jordan'`, the text `'Jordan submitted proof'` renders
  - [ ] Test: when `task.completedAt != null && task.proofRetained == true && task.completedByName == null`, the text `'Proof submitted'` renders
  - [ ] Test: when `task.completedAt != null && task.proofRetained == false`, no proof indicator renders
  - [ ] Test: when `task.completedAt == null`, no proof indicator renders
  - [ ] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

- [ ] Widget test for `TaskProofSheet` in `apps/flutter/test/features/tasks/task_proof_sheet_test.dart` (AC: 1)
  - [ ] Create new test file
  - [ ] Test: when `proofMediaUrl` is non-null, an `Image.network` widget is present in the tree
  - [ ] Test: when `proofMediaUrl` is null, `AppStrings.proofNotAvailableMessage` text renders
  - [ ] Test: sheet title `AppStrings.proofDetailTitle` renders
  - [ ] Test: `AppStrings.proofPrivacyNote` footer renders
  - [ ] Test: close button (`CupertinoIcons.xmark`) is present
  - [ ] `TaskProofSheet` is a plain `StatelessWidget` — no provider overrides needed; pass data directly via constructor
  - [ ] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

- [ ] Unit test for `TasksRepository.getTaskProof` in `apps/flutter/test/features/tasks/tasks_repository_test.dart` (AC: 1)
  - [ ] Create or extend `tasks_repository_test.dart`
  - [ ] Stub a `MockDio`/`mocktail` mock that returns 200 with `{ data: { taskId, proofMediaUrl, proofRetained, completedAt, completedByUserId, completedByName } }`
  - [ ] Verify `getTaskProof('task-id')` fires a `GET` request to `/v1/tasks/task-id/proof`
  - [ ] Use same `mocktail` pattern as `sharing_repository_test.dart` from Story 5.3

## Dev Notes

### CRITICAL: Migration numbering — next is `0011`

Last committed migration: `0010_accountability_settings_cascade.sql`. The next migration MUST be `0011_shared_proof_visibility.sql`. Verify in `packages/core/src/schema/migrations/meta/_journal.json` before running `pnpm drizzle-kit generate`.

### CRITICAL: This story is a v1 stub — full proof capture and storage is Epic 7

Story 5.5 implements **visibility** of proof (FR21) using stub data. It does NOT implement:
- Proof capture (camera/photo/video) — Epic 7, Story 7.1–7.2
- AI verification — Epic 7, Story 7.2
- Backblaze B2 presigned URL generation — Epic 7, Story 7.7
- Notification on proof submission — Story 8.4

The stub API returns a fixed `proofMediaUrl` (a public placeholder image URL). The Flutter UI renders it using `Image.network`. When Epic 7 lands, `getTaskProof` will be updated to fetch a real presigned URL with short TTL (15 min).

### CRITICAL: `SharingRepository` is NOT the right repo for proof retrieval

`getTaskProof()` belongs in `apps/flutter/lib/features/tasks/data/tasks_repository.dart` — NOT in `SharingRepository`. Established pattern: proof/task state = `TasksRepository`; sharing-domain (invite/accept/assign) = `SharingRepository`.

### CRITICAL: `proofMode` vs `proofRetained` — two different concepts

- `proofMode` (exists on `Task` since Story 5.4): the *type* of proof required (photo/watchMode/healthKit/etc.) — a requirement setting
- `proofRetained` (new in this story): whether the *submitted* proof has been kept as a completion record (FR38) — a completion state

Do NOT conflate these. `proofMode == ProofMode.photo` means a photo is required. `proofRetained == true` means a proof file was kept. Both can coexist.

### CRITICAL: `ProofMode` enum — do NOT recreate

Already exists at `apps/flutter/lib/features/now/domain/proof_mode.dart`. Do NOT create a duplicate. Task model already imports it from that path.

### CRITICAL: NFR-S4 — access scoping must be enforced at the API level

The `GET /v1/tasks/{id}/proof` stub returns data for any caller in v1. The production `TODO(impl)` note must explicitly state: **verify caller is a `list_member` of the task's `listId` before returning the URL**. If the task is not in a shared list, only the task owner (`userId == jwt.sub`) may access it. Document this in the stub handler comment.

### CRITICAL: Drizzle `casing: 'camelCase'`

New schema columns:
- `proofRetained` → Drizzle generates `proof_retained` in DDL
- `proofMediaUrl` → Drizzle generates `proof_media_url` in DDL

Never add manual `name()` overrides — the global `casing: 'camelCase'` config handles mapping automatically.

### CRITICAL: TypeScript NodeNext — `.js` extensions in all local imports

Any new TypeScript code in `tasks.ts` or API route files must use `.js` extensions:
```typescript
import { ok, err } from '../lib/response.js'
```

### CRITICAL: `z.record()` requires two arguments

If any new Zod schema uses `z.record(...)`, use `z.record(z.string(), valueType)`.

### CRITICAL: Committed generated files

Run after any Dart model/provider changes:
```
dart run build_runner build --delete-conflicting-outputs
```

Files that need regeneration in this story:
- `task.freezed.dart` — `Task` gets `proofMediaUrl`, `proofRetained`, `completedByName`
- `task_dto.freezed.dart`, `task_dto.g.dart` — `TaskDto` gets three new fields
- `tasks_repository.g.dart` — new `getTaskProof()` method (provider hash may change)

Commit ALL regenerated files. No `build_runner` in CI.

### CRITICAL: Widget tests need Riverpod overrides

Any test that touches a `ConsumerWidget` or `ConsumerStatefulWidget` MUST override providers:
```dart
final container = ProviderContainer(
  overrides: [
    tasksRepositoryProvider.overrideWithValue(FakeTasksRepository()),
  ],
);
```
Pattern established in Stories 4.1/4.2, 5.1–5.4.

`TaskProofSheet` is a plain `StatelessWidget` — NO provider overrides needed; pass data directly.

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

`TaskProofSheet` background: `colors.surfacePrimary`. This is the correct token. `backgroundPrimary` does not exist.

### CRITICAL: `minimumSize: const Size(44, 44)` on `CupertinoButton`

Use `minimumSize: const Size(44, 44)`, NOT the deprecated `minSize`. Applies to the close button in `TaskProofSheet` and any `CupertinoButton` in the proof indicator tap area.

### CRITICAL: Actual class names — carried forward from Stories 5.1–5.4

| Spec name | Actual name | Location |
|---|---|---|
| `invitations.ts` route | `sharing.ts` route | `apps/api/src/routes/sharing.ts` |
| `InvitationsRepository` | `SharingRepository` | `apps/flutter/lib/features/lists/data/sharing_repository.dart` |
| `invitationsRepositoryProvider` | `sharingRepositoryProvider` | `sharing_repository.g.dart` |
| `InvitationAcceptScreen` | `AcceptInvitationScreen` | `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart` |

### Route registration order in `tasks.ts` — specific before parameterized

`GET /v1/tasks/{id}/proof` uses a nested path. Register it BEFORE `PATCH /v1/tasks/{id}` (and before any future `GET /v1/tasks/{id}`). Current route registration order in `tasks.ts` (as of Story 5.4):
1. `GET /v1/tasks` (list)
2. `GET /v1/tasks/current` (must stay first — registered before `{id}` catch-all)
3. `GET /v1/tasks/today`
4. `GET /v1/tasks/search`
5. `PATCH /v1/tasks/{id}/proof-mode` ← specific before `{id}`
6. `PATCH /v1/tasks/{id}`
7. `POST /v1/tasks/{id}/complete`
8. etc.

Add `GET /v1/tasks/{id}/proof` after item 5 (alongside other `{id}/sub-resource` routes), before any unqualified `GET /v1/tasks/{id}`.

### API: Proof visibility response schema

```typescript
const taskProofResponseSchema = z.object({
  taskId: z.string().uuid(),
  proofMediaUrl: z.string().url().nullable(),
  proofRetained: z.boolean(),
  completedAt: z.string().datetime().nullable(),
  completedByUserId: z.string().uuid().nullable(),
  completedByName: z.string().nullable(),
})
```

### Stub `proofMediaUrl` value

Use a stable public placeholder for stub testing:
```typescript
proofMediaUrl: 'https://placehold.co/600x400.jpg'
```
This ensures `Image.network` succeeds in widget tests without needing an HTTP mock for the image itself. Widget tests should test presence of the widget, not image loading (which requires mocking `NetworkImage`).

### Image loading in widget tests

`Image.network` requires network access in tests. Widget tests should:
- Assert the `Image.network` widget is present in the tree (widget type check)
- NOT assert visual pixel output of the loaded image
- Consider using `TestWidgetsFlutterBinding.ensureInitialized()` and mocking `HttpClient` via `io.HttpOverrides.global` if image loading causes test failures; otherwise, test widget presence only

### `Task.completedAt` vs `TaskProofSheet.completedAt`

`Task.completedAt` (type: `DateTime?`) is already on the domain model. Pass `task.completedAt` directly to `TaskProofSheet`. No new field needed on `Task` for completion time display.

### Deferred: real presigned URL generation

Production implementation (`TODO(impl)` notes):
1. Look up task from DB; verify `userId == jwt.sub` OR caller exists in `list_members` for `task.listId`
2. If `proofRetained == false` or `proofMediaUrl IS NULL` in DB: return null
3. Generate a 15-minute presigned Backblaze B2 URL (or Cloudflare R2 equivalent per final infra decision) for the stored object
4. Return URL in response — do NOT store presigned URLs in DB

This work is deferred to Epic 7 (Story 7.7 — Proof Retention Settings).

### Deferred: notification on proof submission (AC: 2)

AC2 (notification when member submits proof) is explicitly deferred to Story 8.4. This story's v1 stub satisfies AC1 only. The AC2 condition is noted in the story as a known future dependency.

### UX spec reference

From `UX-DR5`: Now Tab Task Card shows proof mode indicator. For the shared list task row, use the same `ProofModeIndicator` widget pattern already used in `task_row.dart` for the proof requirement indicator (Story 5.4). Do NOT duplicate the indicator widget — reuse existing `proof_mode_indicator.dart` at `apps/flutter/lib/features/now/presentation/widgets/proof_mode_indicator.dart` if it suits the display; otherwise add a minimal inline chip following the same 13pt `colors.textSecondary` style.

### Files to Create

**`apps/flutter/lib/features/tasks/presentation/widgets/task_proof_sheet.dart`** — new proof detail bottom sheet widget

### Files to Modify

**`packages/core/src/schema/tasks.ts`:**
- Add `proofRetained: boolean().default(false).notNull()`
- Add `proofMediaUrl: text()`

**`packages/core/src/schema/migrations/0011_shared_proof_visibility.sql`:**
- Generated (do not hand-edit)

**`packages/core/src/schema/migrations/meta/_journal.json`:**
- Updated by `drizzle-kit generate`

**`packages/core/src/schema/migrations/meta/0011_snapshot.json`:**
- Generated by `drizzle-kit generate`

**`apps/api/src/routes/tasks.ts`:**
- Add `proofRetained` and `proofMediaUrl` to `taskSchema`
- Add `completedByName` to `taskSchema`
- Update `stubTask()` with new fields
- Add `GET /v1/tasks/{id}/proof` endpoint

**`apps/flutter/lib/features/tasks/domain/task.dart`:**
- Add `String? proofMediaUrl`, `@Default(false) bool proofRetained`, `String? completedByName`

**`apps/flutter/lib/features/tasks/domain/task.freezed.dart`:**
- Regenerated

**`apps/flutter/lib/features/tasks/data/task_dto.dart`:**
- Add three new fields with `@JsonKey` defaults

**`apps/flutter/lib/features/tasks/data/task_dto.freezed.dart`:**
- Regenerated

**`apps/flutter/lib/features/tasks/data/task_dto.g.dart`:**
- Regenerated

**`apps/flutter/lib/features/tasks/data/tasks_repository.dart`:**
- Add `getTaskProof(String taskId)` method

**`apps/flutter/lib/features/tasks/data/tasks_repository.g.dart`:**
- Regenerated if provider hash changes

**`apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`:**
- Add proof retained indicator with completedByName display
- Wire proof indicator tap to open `TaskProofSheet` via `getTaskProof`

**`apps/flutter/lib/core/l10n/strings.dart`:**
- Add FR21 strings section

### Files to Create (Tests)

**`apps/flutter/test/features/tasks/task_proof_sheet_test.dart`** — new widget test

**`apps/flutter/test/features/tasks/tasks_repository_test.dart`** — new or extend if exists

**`apps/flutter/test/features/tasks/task_dto_test.dart`** — extend existing (Story 5.4 extended it last)

**`apps/flutter/test/features/tasks/task_row_test.dart`** — extend existing (created in Story 5.4)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
