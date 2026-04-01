# Story 5.6: Member Management & Shared Ownership

Status: review

## Story

As a list owner,
I want to remove members, manage shared ownership rights, and allow members to leave,
so that list membership stays accurate and administrative responsibility can be distributed.

## Acceptance Criteria

1. **Given** a list owner opens List Settings → Members **When** they remove a member **Then** the removed member loses access immediately and the list disappears from their Lists tab (FR62) **And** the removed member's incomplete assigned tasks are unassigned

2. **Given** a list member opens List Settings **When** they choose "Leave list" **Then** they are removed from the list and their assigned tasks are unassigned **And** they cannot rejoin without a new invitation

3. **Given** a list has an owner **When** they grant owner rights to another member **Then** that member gains full administrative rights: invite, remove, configure strategy, delete list (FR75) **And** multiple owners can coexist; ownership is not exclusive

## Tasks / Subtasks

### Backend: API — add member management endpoints to `apps/api/src/routes/sharing.ts` (AC: 1, 2, 3)

- [x] Add `DELETE /v1/lists/{id}/members/{userId}` — remove a member (AC: 1)
  - [x] Request params: `{ id: z.string().uuid(), userId: z.string().uuid() }`
  - [x] Response 200: `{ data: { listId, removedUserId, unassignedTaskCount } }`
  - [x] Response 403: caller is not a list owner
  - [x] Response 404: list or member not found
  - [x] Response 422: cannot remove the last owner (list must retain at least one owner)
  - [x] Stub: return 200 with `{ listId: id, removedUserId: userId, unassignedTaskCount: 1 }`; add `TODO(impl): verify caller is owner via list_members, delete list_members row, set assignedToUserId = NULL on tasks WHERE listId = id AND assignedToUserId = userId AND completedAt IS NULL`
  - [x] Tag: `'Sharing'`
  - [x] Register BEFORE `GET /v1/lists/{id}/members` (specific/nested before list-members) — specific before parameterized rule
  - [x] Use `.js` extensions for all local imports
  - [x] Use `@hono/zod-openapi` `createRoute` pattern — no untyped routes

- [x] Add `POST /v1/lists/{id}/leave` — current user leaves the list (AC: 2)
  - [x] Request params: `{ id: z.string().uuid() }`, body: empty `{}`
  - [x] Response 200: `{ data: { listId, unassignedTaskCount } }`
  - [x] Response 403: last owner cannot leave (must promote another member to owner first)
  - [x] Response 404: list not found or caller is not a member
  - [x] Stub: return 200 with `{ listId: id, unassignedTaskCount: 1 }`; add `TODO(impl): verify caller is member via JWT, enforce last-owner guard, delete list_members row for jwt.sub, set assignedToUserId = NULL on caller's incomplete tasks`
  - [x] Tag: `'Sharing'`
  - [x] Register BEFORE `GET /v1/lists/{id}/members` — specific before parameterized rule
  - [x] Use `.js` extensions for all local imports

- [x] Add `PATCH /v1/lists/{id}/members/{userId}/role` — grant or revoke owner role (AC: 3)
  - [x] Request params: `{ id: z.string().uuid(), userId: z.string().uuid() }`
  - [x] Request body schema: `{ role: z.enum(['owner', 'member']) }`
  - [x] Response 200: `{ data: { listId, userId, role } }`
  - [x] Response 403: caller is not a list owner
  - [x] Response 404: list or member not found
  - [x] Response 422: cannot demote the last owner to member (must retain at least one owner)
  - [x] Stub: return 200 with `{ listId: id, userId, role: body.role }`; add `TODO(impl): verify caller is owner, enforce last-owner guard when demoting, update list_members.role via Drizzle`
  - [x] Tag: `'Sharing'`
  - [x] Register BEFORE `GET /v1/lists/{id}/members` — specific before parameterized rule
  - [x] Use `.js` extensions for all local imports

### Backend: Route registration order in `apps/api/src/routes/sharing.ts` (AC: 1, 2, 3)

- [x] Verify and set the final route order in `sharing.ts` so all new specific routes precede `GET /v1/lists/{id}/members` (AC: 1, 2, 3)
  - [x] Confirmed order for new routes (insert before `GET /v1/lists/{id}/members`):
    1. `POST /v1/lists/{id}/share` (existing)
    2. `POST /v1/lists/{id}/assign` (existing)
    3. `POST /v1/lists/{id}/auto-assign` (existing)
    4. `DELETE /v1/lists/{id}/tasks/{taskId}/assignment` (existing)
    5. `POST /v1/lists/{id}/leave` ← new
    6. `DELETE /v1/lists/{id}/members/{userId}` ← new
    7. `PATCH /v1/lists/{id}/members/{userId}/role` ← new
    8. `GET /v1/lists/{id}/members` (existing — must remain after all specific `/lists/{id}/...` routes)

### Flutter: Domain model — extend `ListMember` with email (AC: 1, 3)

- [x] Add `String? email` to `apps/flutter/lib/features/lists/domain/list_member.dart` (AC: 1, 3)
  - [x] `String? email` — nullable; the member's email; may be null for members who joined before email tracking was added or for privacy reasons
  - [x] Use `@Default(null)` is NOT needed — nullable field with no default is fine in Freezed; just `String? email`
  - [x] Current fields: `userId`, `displayName`, `avatarInitials`, `role`, `joinedAt`, `roundRobinIndex` — do NOT remove any
  - [x] Regenerate `list_member.freezed.dart` — run `dart run build_runner build --delete-conflicting-outputs` and commit

### Flutter: SharingRepository — add member management methods (AC: 1, 2, 3)

- [x] Add `removeMember` to `apps/flutter/lib/features/lists/data/sharing_repository.dart` (AC: 1)
  - [x] `Future<Map<String, dynamic>> removeMember(String listId, String userId)` — `DELETE /v1/lists/$listId/members/$userId`
  - [x] Use `_client.dio.delete<Map<String, dynamic>>('/v1/lists/$listId/members/$userId')`
  - [x] Return `response.data!['data'] as Map<String, dynamic>`
  - [x] This IS a sharing-domain operation — belongs in `SharingRepository`, NOT in `ListsRepository`

- [x] Add `leaveList` to `apps/flutter/lib/features/lists/data/sharing_repository.dart` (AC: 2)
  - [x] `Future<Map<String, dynamic>> leaveList(String listId)` — `POST /v1/lists/$listId/leave`
  - [x] Use `_client.dio.post<Map<String, dynamic>>('/v1/lists/$listId/leave', data: <String, dynamic>{})`
  - [x] Return `response.data!['data'] as Map<String, dynamic>`

- [x] Add `updateMemberRole` to `apps/flutter/lib/features/lists/data/sharing_repository.dart` (AC: 3)
  - [x] `Future<Map<String, dynamic>> updateMemberRole(String listId, String userId, String role)` — `PATCH /v1/lists/$listId/members/$userId/role`
  - [x] Use `_client.dio.patch<Map<String, dynamic>>('/v1/lists/$listId/members/$userId/role', data: {'role': role})`
  - [x] Return `response.data!['data'] as Map<String, dynamic>`

- [x] Regenerate `sharing_repository.g.dart` — provider hash may change if `@riverpod` annotation context changes; commit

### Flutter: List Settings screen — add Members section (AC: 1, 2, 3)

- [x] Extend `apps/flutter/lib/features/lists/presentation/list_settings_screen.dart` with a "Members" section (AC: 1, 2, 3)
  - [x] Add section below the existing "Accountability" section
  - [x] Section header: `AppStrings.membersSettingsLabel` (new string — see l10n section)
  - [x] Fetch members using `ref.watch(listMembersProvider(widget.listId))` — this provider already exists at `apps/flutter/lib/features/lists/presentation/list_members_provider.dart`
  - [x] For each member, render a row with: avatar initials circle, `displayName`, role badge ("Owner" / "Member")
  - [x] For `role == 'owner'`: show `AppStrings.memberRoleOwner` badge in `colors.accentPrimary`
  - [x] For `role == 'member'`: show `AppStrings.memberRoleMember` badge in `colors.textSecondary`
  - [x] Only show management actions (remove, grant owner) if the current user is an owner — detect via checking caller's own `ListMember.role == 'owner'` from the member list
  - [x] Owner management actions: trailing `CupertinoButton` with `CupertinoIcons.ellipsis_circle` → opens `CupertinoActionSheet` per member with options: "Grant Owner", "Remove from list" (show "Revoke Owner" instead of "Grant Owner" when member already has role `'owner'`)
  - [x] "Grant Owner" / "Revoke Owner": calls `sharingRepository.updateMemberRole(listId, userId, 'owner'/'member')` → `ref.invalidate(listMembersProvider(widget.listId))`
  - [x] "Remove from list": show a `CupertinoAlertDialog` confirmation with title `AppStrings.removeMemberConfirmTitle`, message `AppStrings.removeMemberConfirmMessage`, actions: Cancel + `AppStrings.actionDelete` (destructive) → on confirm: call `sharingRepository.removeMember(listId, userId)` → `ref.invalidate(listMembersProvider(widget.listId))` AND `ref.invalidate(listsProvider)`
  - [x] Loading state during management actions: `_isManagingMember` bool state (similar to `_isUpdatingStrategy`)
  - [x] Error state: `CupertinoAlertDialog` with title `AppStrings.dialogErrorTitle`, message `AppStrings.memberManagementError`
  - [x] Background: `colors.surfacePrimary` (already set on screen)
  - [x] `minimumSize: const Size(44, 44)` on any `CupertinoButton`

- [x] Add "Leave list" option to `list_settings_screen.dart` for non-owner members (AC: 2)
  - [x] Show a "Leave list" `CupertinoButton` with destructive styling at the bottom of the Members section
  - [x] Only show when current user is NOT the last owner (if user is the only owner, show a disabled button with tooltip `AppStrings.leaveListLastOwnerNote`)
  - [x] Tapping opens a `CupertinoAlertDialog` confirmation: title `AppStrings.leaveListConfirmTitle`, message `AppStrings.leaveListConfirmMessage`, actions: Cancel + `AppStrings.actionDelete` (destructive)
  - [x] On confirm: call `sharingRepository.leaveList(listId)` → on success, `context.go('/lists')` to navigate back to lists screen (list is no longer accessible)
  - [x] Error state: show `CupertinoAlertDialog` with `AppStrings.dialogErrorTitle` and `AppStrings.leaveListError`

### Flutter: l10n strings (AC: 1, 2, 3)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Member management & shared ownership (FR62, FR75) ──` section (AC: 1, 2, 3)
  - [x] `static const String membersSettingsLabel = 'Members';` — section header in List Settings
  - [x] `static const String memberRoleOwner = 'Owner';` — role badge
  - [x] `static const String memberRoleMember = 'Member';` — role badge
  - [x] `static const String memberGrantOwner = 'Grant Owner';` — action sheet option
  - [x] `static const String memberRevokeOwner = 'Revoke Owner';` — action sheet option
  - [x] `static const String memberRemoveFromList = 'Remove from list';` — action sheet option
  - [x] `static const String removeMemberConfirmTitle = 'Remove member?';`
  - [x] `static const String removeMemberConfirmMessage = 'This member will lose access to the list immediately and their assigned tasks will be unassigned.';`
  - [x] `static const String leaveListButton = 'Leave list';` — button label
  - [x] `static const String leaveListConfirmTitle = 'Leave list?';`
  - [x] `static const String leaveListConfirmMessage = 'You will lose access to this list. Your assigned tasks will be unassigned. You cannot rejoin without a new invitation.';`
  - [x] `static const String leaveListLastOwnerNote = 'You cannot leave as the last owner. Promote another member to owner first.';`
  - [x] `static const String memberManagementError = 'Could not update member. Please try again.';`
  - [x] `static const String leaveListError = 'Could not leave list. Please try again.';`
  - [x] NOTE: `AppStrings.actionDelete`, `AppStrings.actionOk`, `AppStrings.dialogErrorTitle` already exist — do NOT recreate

### Tests

- [x] Unit test for `SharingRepository` new methods in `apps/flutter/test/features/lists/sharing_repository_test.dart` (AC: 1, 2, 3)
  - [x] Extend existing `sharing_repository_test.dart` (created in Story 5.3)
  - [x] Test: `removeMember('list-id', 'user-id')` fires `DELETE /v1/lists/list-id/members/user-id`
  - [x] Test: `leaveList('list-id')` fires `POST /v1/lists/list-id/leave`
  - [x] Test: `updateMemberRole('list-id', 'user-id', 'owner')` fires `PATCH /v1/lists/list-id/members/user-id/role` with body `{'role': 'owner'}`
  - [x] Use same `mocktail` + `MockDio` pattern established in Story 5.3 `sharing_repository_test.dart`

- [x] Widget test for `ListSettingsScreen` members section in `apps/flutter/test/features/lists/list_settings_screen_test.dart` (AC: 1, 2, 3)
  - [x] Extend existing `list_settings_screen_test.dart` (created in Story 5.2, extended in Story 5.4)
  - [x] Test: members section header `AppStrings.membersSettingsLabel` renders
  - [x] Test: member display name renders for a stub member list
  - [x] Test: when current user is owner, the ellipsis button renders on member rows
  - [x] Test: when current user is NOT owner, no management buttons are shown
  - [x] Test: "Leave list" button renders for non-last-owner member
  - [x] Override `sharingRepositoryProvider` and `listMembersProvider` with stub values — same `ProviderContainer` pattern as Story 5.4 tests
  - [x] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

## Dev Notes

### CRITICAL: `SharingRepository` owns all member management operations — not `ListsRepository`

Member management (remove, leave, role update) is sharing-domain. Route to `apps/flutter/lib/features/lists/data/sharing_repository.dart`. Do NOT add these to `ListsRepository` or `TasksRepository`.

Pattern established:
- Sharing/invite/assign/membership = `SharingRepository`
- List CRUD + accountability = `ListsRepository`
- Proof/task state = `TasksRepository`

### CRITICAL: `listMembersNotifierProvider` already exists — do NOT recreate it

`apps/flutter/lib/features/lists/presentation/list_members_provider.dart` exports `ListMembersNotifier` (a `@riverpod` class keyed by `listId`). The provider is `listMembersNotifierProvider(listId)`. `list_settings_screen.dart` already imports `sharing_repository.dart` (line 8 of existing file). Use `ref.watch(listMembersNotifierProvider(widget.listId))` to fetch members.

### CRITICAL: Last-owner guard must be enforced on BOTH API and UI

Both the API stub (403/422) and the Flutter UI (disabled "Leave list" button, no "Revoke Owner" action when only one owner) must prevent the last owner from leaving or being demoted. The UI guard: count members where `role == 'owner'`; if count == 1 and that member is the current user, disable the leave/revoke actions.

### CRITICAL: `listMembersTable` schema — actual columns

`packages/core/src/schema/list-members.ts` has: `id`, `listId`, `userId`, `role`, `roundRobinIndex`, `joinedAt`, `createdAt`, `updatedAt`. The `joinedAt` column exists and is used by `ListMember.joinedAt`. The `role` column values are `'owner'` | `'member'`.

### CRITICAL: No new DB migration required for this story

This story adds new API endpoints and Flutter UI only. It does NOT add new DB columns — it operates on existing `listMembersTable` columns (`role`, `userId`). Migration `0011` was used in Story 5.5. Next migration (if needed in future) would be `0012_...`.

### CRITICAL: Actual class/file names — carried forward from Stories 5.1–5.5

| Spec name | Actual name | Location |
|---|---|---|
| `invitations.ts` route | `sharing.ts` route | `apps/api/src/routes/sharing.ts` |
| `sharingRouter` export | `sharingRouter` | `apps/api/src/routes/sharing.ts` |
| `InvitationsRepository` | `SharingRepository` | `apps/flutter/lib/features/lists/data/sharing_repository.dart` |
| `invitationsRepositoryProvider` | `sharingRepositoryProvider` | `sharing_repository.g.dart` |
| `InvitationAcceptScreen` | `AcceptInvitationScreen` | `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart` |
| `listMembersProvider` | `listMembersNotifierProvider(listId)` | `apps/flutter/lib/features/lists/presentation/list_members_provider.dart` |

### CRITICAL: Route registration order in `sharing.ts` — new routes before `GET /v1/lists/{id}/members`

`sharing.ts` current order (as of Story 5.3):
1. `POST /v1/lists/{id}/share`
2. `GET /v1/invitations/{token}`
3. `POST /v1/invitations/{token}/accept`
4. `POST /v1/invitations/{token}/decline`
5. `POST /v1/lists/{id}/assign`
6. `POST /v1/lists/{id}/auto-assign`
7. `DELETE /v1/lists/{id}/tasks/{taskId}/assignment`
8. `GET /v1/lists/{id}/members`

New routes for this story go BEFORE item 8:
- `POST /v1/lists/{id}/leave`
- `DELETE /v1/lists/{id}/members/{userId}`
- `PATCH /v1/lists/{id}/members/{userId}/role`

The `DELETE /v1/lists/{id}/members/{userId}` and `PATCH /v1/lists/{id}/members/{userId}/role` routes include the `{userId}` sub-segment, making them more specific than `GET /v1/lists/{id}/members`. Register all before `GET /v1/lists/{id}/members`.

### CRITICAL: TypeScript NodeNext — `.js` extensions in all local imports

All new handler code in `sharing.ts` must use `.js` extensions:
```typescript
import { ok, err } from '../lib/response.js'
```

### CRITICAL: `z.record()` requires two arguments

If any Zod schema uses `z.record(...)`, use `z.record(z.string(), valueType)` — two args required.

### CRITICAL: Committed generated files

Run after any Dart model/provider changes:
```
dart run build_runner build --delete-conflicting-outputs
```

Files needing regeneration in this story:
- `list_member.freezed.dart` — `ListMember` gets optional `email` field
- `sharing_repository.g.dart` — may change if provider annotation context changes

Commit ALL regenerated files. No `build_runner` in CI.

### CRITICAL: Widget tests need Riverpod overrides

Any test touching `ConsumerWidget` / `ConsumerStatefulWidget` MUST override providers:
```dart
final container = ProviderContainer(
  overrides: [
    sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
    listMembersNotifierProvider(listId).overrideWith(...),
  ],
);
```
Pattern established in Stories 4.1/4.2, 5.1–5.5.

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

Use `colors.surfacePrimary` for all sheet/screen backgrounds. `backgroundPrimary` does not exist.

### CRITICAL: `minimumSize: const Size(44, 44)` on `CupertinoButton`

Use `minimumSize: const Size(44, 44)`, NOT the deprecated `minSize`. Applies to all new `CupertinoButton` instances.

### CRITICAL: Drizzle `casing: 'camelCase'` — no changes needed this story

No new DB schema columns are added in this story. The note is retained for consistency: write Drizzle schema in camelCase; Drizzle generates snake_case DDL automatically. Do NOT add manual `name()` overrides.

### CRITICAL: `AppStrings` existing strings — do NOT recreate

Already exist and must be reused:
- `AppStrings.actionDelete` — destructive confirmation action label
- `AppStrings.actionOk` — OK/dismiss action label
- `AppStrings.dialogErrorTitle` — 'Error' for alert dialogs
- `AppStrings.actionRename` — rename action (not needed this story but exists)
- `AppStrings.proofModeStandard` — 'Standard (no proof)' (not needed this story)

### Current route state in `apps/api/src/routes/sharing.ts` (as of Story 5.5)

Existing endpoints (do NOT modify):
- `POST /v1/lists/{id}/share` (FR15)
- `GET /v1/invitations/{token}` (FR16)
- `POST /v1/invitations/{token}/accept` (FR16)
- `POST /v1/invitations/{token}/decline` (FR16)
- `POST /v1/lists/{id}/assign` (FR18)
- `POST /v1/lists/{id}/auto-assign` (FR17)
- `DELETE /v1/lists/{id}/tasks/{taskId}/assignment` (FR19)
- `GET /v1/lists/{id}/members` (FR15)

### Deferred: real data enforcement

Production `TODO(impl)` notes for each new endpoint:
- `DELETE /v1/lists/{id}/members/{userId}`: verify caller is owner, protect last owner, delete `list_members` row, NULL out `tasks.assignedToUserId` where incomplete
- `POST /v1/lists/{id}/leave`: verify caller is member via JWT sub, enforce last-owner guard, delete own `list_members` row, NULL out caller's incomplete assigned tasks
- `PATCH /v1/lists/{id}/members/{userId}/role`: verify caller is owner, enforce last-owner guard on demote, update `list_members.role`

### Task `assignedToUserId` field already exists

`tasks` table has `assignedToUserId` (added in Story 5.2 migration `0009_task_assignment_strategies.sql`). The unassign-on-remove/leave logic sets this to `NULL` for incomplete tasks. This is a backend-only concern in v1 stub — the stub returns `unassignedTaskCount: 1` as a placeholder.

### UX: Owner detection in `ListSettingsScreen`

To determine if the current user is an owner, the simplest v1 approach: from the member list returned by `listMembersNotifierProvider`, find the entry where `userId` matches the authenticated user's ID. The authenticated user ID is available from the existing auth provider pattern used in other screens. If the current user's `role == 'owner'`, show management actions.

In v1 stub, since auth is stubbed, the dev can use a hardcoded `'d0000000-0000-4000-8000-000000000001'` (Jordan, owner) as the "current user" for UI logic — add a `TODO(impl): replace with real JWT sub` comment.

### `ListMember.email` — when and why

Adding optional `email` to `ListMember` domain model enables the "Remove from list" confirmation to show "Remove [email]?" for clarity. The API's `listMemberSchema` in `sharing.ts` currently does not include `email`; add it as `email: z.string().email().nullable()` to `listMemberSchema` in `sharing.ts` and update `stubMembers()` to include `email: 'jordan@example.com'` / `email: 'sam@example.com'`. Update `SharingRepository._memberFromJson` to parse `email`.

### Files to Create

None — all new functionality extends existing files.

### Files to Modify

**`apps/api/src/routes/sharing.ts`:**
- Add `listMemberSchema` extension with `email` field
- Update `stubMembers()` with email values
- Add `DELETE /v1/lists/{id}/members/{userId}`
- Add `POST /v1/lists/{id}/leave`
- Add `PATCH /v1/lists/{id}/members/{userId}/role`

**`apps/flutter/lib/features/lists/domain/list_member.dart`:**
- Add `String? email`

**`apps/flutter/lib/features/lists/domain/list_member.freezed.dart`:**
- Regenerated

**`apps/flutter/lib/features/lists/data/sharing_repository.dart`:**
- Add `removeMember(String listId, String userId)`
- Add `leaveList(String listId)`
- Add `updateMemberRole(String listId, String userId, String role)`
- Update `_memberFromJson` to parse `email`

**`apps/flutter/lib/features/lists/data/sharing_repository.g.dart`:**
- Regenerated if provider hash changes

**`apps/flutter/lib/features/lists/presentation/list_settings_screen.dart`:**
- Add Members section with per-member action sheet (remove, grant/revoke owner)
- Add "Leave list" button for non-last-owner members

**`apps/flutter/lib/core/l10n/strings.dart`:**
- Add FR62/FR75 strings section

### Files to Modify (Tests)

**`apps/flutter/test/features/lists/sharing_repository_test.dart`:**
- Extend with tests for `removeMember`, `leaveList`, `updateMemberRole`

**`apps/flutter/test/features/lists/list_settings_screen_test.dart`:**
- Extend with tests for Members section rendering and management actions

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation proceeded without blockers.

### Completion Notes List

- Added three API endpoints to `sharing.ts`: `POST /leave`, `DELETE /members/{userId}`, `PATCH /members/{userId}/role` — all stub implementations with `TODO(impl)` markers, registered before `GET /v1/lists/{id}/members` per route-ordering spec.
- Extended `listMemberSchema` with nullable `email` field and updated `stubMembers()` with email values.
- Added `String? email` to `ListMember` Freezed model; regenerated `list_member.freezed.dart` via `build_runner`.
- Added `removeMember`, `leaveList`, `updateMemberRole` to `SharingRepository`; updated `_memberFromJson` to parse `email`.
- Extended `list_settings_screen.dart` with full Members section: avatar rows, role badges, ellipsis action sheet (grant/revoke owner, remove), "Leave list" button with last-owner guard, confirmation dialogs, and `_isManagingMember` loading state. Used `listMembersProvider(listId)` (actual generated provider name — `listMembersNotifierProvider` in spec was a naming discrepancy).
- Added 14 l10n strings for member management under the `// ── Member management & shared ownership (FR62, FR75) ──` section.
- Extended `sharing_repository_test.dart` with 4 new unit tests for `removeMember`, `leaveList`, `updateMemberRole`.
- Extended `list_settings_screen_test.dart` with 5 widget tests for the Members section; overrode `listMembersProvider` with `_FakeListMembersNotifier`.
- All 665 Flutter tests pass. Zero regressions. No TypeScript errors introduced in `sharing.ts`.

### File List

apps/api/src/routes/sharing.ts
apps/flutter/lib/features/lists/domain/list_member.dart
apps/flutter/lib/features/lists/domain/list_member.freezed.dart
apps/flutter/lib/features/lists/data/sharing_repository.dart
apps/flutter/lib/features/lists/presentation/list_settings_screen.dart
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/test/features/lists/sharing_repository_test.dart
apps/flutter/test/features/lists/list_settings_screen_test.dart
_bmad-output/implementation-artifacts/5-6-member-management-shared-ownership.md
_bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- 2026-04-01: Story 5.6 implemented — Member Management & Shared Ownership. Added API endpoints (remove member, leave list, update role), Flutter SharingRepository methods, Members section in ListSettingsScreen, 14 l10n strings, 9 new tests (4 unit + 5 widget). All 665 Flutter tests pass.
