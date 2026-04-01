# Story 5.1: List Sharing & Invitations

Status: review

## Story

As a user,
I want to share any list with named people by email invitation,
So that my household or team can coordinate tasks in one place.

## Acceptance Criteria

1. **Given** the user opens a list and chooses "Share" **When** they enter an email address **Then** an invitation is sent to that address and the list is labelled "shared" with a member count (FR15)

2. **Given** an invitation is received **When** the recipient opens the deep link from the email **Then** they are shown the list name and the name of the person who invited them **And** accepting adds them as a list member with full task visibility (FR16) **And** if the recipient is not yet subscribed, they are routed through the independent trial onboarding path (FR86)

3. **Given** a user is a member of a shared list **When** they view their Lists tab **Then** the shared list appears with a shared indicator and member avatars

## Tasks / Subtasks

### DB: Add `list_members` and `list_invitations` tables

- [x] Create `packages/core/src/schema/list-members.ts` (AC: 1, 2, 3)
  - [x] `listMembersTable` — columns: `id` (uuid PK), `listId` (uuid FK → lists), `userId` (uuid), `role` (text `'owner'|'member'`), `joinedAt` (timestamp), `createdAt`, `updatedAt`
- [x] Create `packages/core/src/schema/list-invitations.ts` (AC: 1, 2)
  - [x] `listInvitationsTable` — columns: `id` (uuid PK), `listId` (uuid FK → lists), `invitedByUserId` (uuid), `inviteeEmail` (text not null), `token` (text not null unique — secure random), `status` (text `'pending'|'accepted'|'declined'`), `expiresAt` (timestamp), `createdAt`, `updatedAt`
- [x] Export both new tables from `packages/core/src/schema/index.ts`
- [x] Write migration `packages/core/src/schema/migrations/0008_list_sharing.sql` — `CREATE TABLE list_members`, `CREATE TABLE list_invitations`

### API: Share endpoint and invitation acceptance

- [x] Create `apps/api/src/routes/sharing.ts` with stub implementations (AC: 1, 2)
  - [x] `POST /v1/lists/:id/share` — accepts `{ email: string }`, creates a stub invitation record, returns `{ data: { invitationId, listId, inviteeEmail, status: 'pending' } }` (stub: logs "TODO: send email", returns 201)
  - [x] `POST /v1/invitations/:token/accept` — accepts the invitation token from the deep link, returns `{ data: { listId, listTitle, inviterName, memberCount } }` (stub: returns plausible fixture data)
  - [x] `GET /v1/lists/:id/members` — returns paginated member list `{ data: [{ userId, displayName, avatarInitials, role, joinedAt }], pagination }` (stub: returns fixture with 2 members including the current user)
  - [x] All routes use `@hono/zod-openapi` schemas — no untyped routes
- [x] Register `sharingRouter` in `apps/api/src/index.ts`

### Flutter: Share sheet widget

- [x] Create `apps/flutter/lib/features/lists/presentation/widgets/share_list_sheet.dart` (AC: 1)
  - [x] `ShareListSheet` — `StatefulWidget`, accepts `listId`, `listTitle`
  - [x] Email input field (`CupertinoTextField`) with "Send invitation" button (`CupertinoButton.filled`)
  - [x] On submit: calls `sharingRepository.shareList(listId, email)`, shows inline success ("Invitation sent to {email}.") or inline error
  - [x] Validate email format before submitting (show "Enter a valid email address." if empty/invalid)
  - [x] All strings via `AppStrings` constants
  - [x] All colours via `Theme.of(context).extension<OnTaskColors>()!` — use `colors.accentPrimary` for avatar circles and primary buttons; `colors.surfaceSecondary` for sheet background; `colors.textSecondary` for secondary text
- [x] Add "Share" action to `list_detail_screen.dart` `_showMoreActions` action sheet (AC: 1)
  - [x] Append a new `CupertinoActionSheetAction` with label `AppStrings.shareListAction`
  - [x] On tap: close action sheet, then `showModalBottomSheet(..., builder: (_) => ShareListSheet(listId: widget.listId, listTitle: list?.title ?? ''))`

### Flutter: Invitation accept screen

- [x] Create `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart` (AC: 2)
  - [x] `AcceptInvitationScreen` — `ConsumerStatefulWidget`, accepts `token` string param
  - [x] On init: calls `sharingRepository.getInvitationDetails(token)` — shows loading, then renders: list name (large text), "Invited by {inviterName}" (secondary text), "Accept" button, "Decline" button
  - [x] "Accept" → calls `sharingRepository.acceptInvitation(token)` → on success: navigates to `/lists` (or `/onboarding` if not yet subscribed — stub logic: always go to `/lists`)
  - [x] "Decline" → calls `sharingRepository.declineInvitation(token)` → navigates back / closes
  - [x] Error state: show "This invitation has expired or is no longer valid." with a "Go to Lists" button
  - [x] All strings via `AppStrings`; all colours via `OnTaskColors`
- [x] Register `/invite/:token` route in `apps/flutter/lib/core/router/app_router.dart`
  - [x] Add `GoRoute(path: '/invite/:token', ...)` inside the `StatefulShellRoute` lists branch under `/lists`, or as a top-level route accessible without shell (matching `chapter-break` pattern) — use top-level route so no tab bar appears
  - [x] Pass `state.pathParameters['token']!` to `AcceptInvitationScreen`

### Flutter: Shared list indicator in ListsScreen

- [x] Modify `apps/flutter/lib/features/lists/presentation/lists_screen.dart` to show shared indicator (AC: 3)
  - [x] Watch `listMembersProvider(listId)` per list row — `AsyncValue<List<ListMember>>`
  - [x] When `memberCount >= 2`: show a `Row` of `_MemberAvatar` widgets (first 3 max) and a member count label alongside the list title
  - [x] `_MemberAvatar` — private widget: 20×20 circular `Container`, background `colors.accentPrimary`, foreground `colors.surfacePrimary`, shows 1–2 initial characters of `avatarInitials`
  - [x] When `memberCount < 2` (personal list): show no shared indicator (unchanged layout)
  - [x] Do NOT break the existing chevron-right icon or onTap behaviour

### Flutter: Sharing data layer

- [x] Create `apps/flutter/lib/features/lists/domain/list_member.dart` (AC: 3)
  - [x] `ListMember` — `@freezed` with fields: `userId`, `displayName`, `avatarInitials`, `role` (String), `joinedAt` (DateTime)
- [x] Create `apps/flutter/lib/features/lists/data/sharing_repository.dart` (AC: 1, 2, 3)
  - [x] `SharingRepository` — Riverpod `@riverpod` provider wrapping `ApiClient`
  - [x] `shareList(String listId, String email)` — `POST /v1/lists/:id/share`
  - [x] `getInvitationDetails(String token)` — `GET /v1/invitations/:token` (returns `InvitationDetails` — inline class: `listTitle`, `inviterName`)
  - [x] `acceptInvitation(String token)` — `POST /v1/invitations/:token/accept`
  - [x] `declineInvitation(String token)` — `POST /v1/invitations/:token/decline` (stub endpoint, returns 204)
  - [x] `getListMembers(String listId)` — `GET /v1/lists/:id/members`
- [x] Create `apps/flutter/lib/features/lists/presentation/list_members_provider.dart` (AC: 3)
  - [x] `@riverpod` `ListMembersNotifier` — family keyed by `listId`, calls `sharingRepository.getListMembers(listId)`, returns `AsyncValue<List<ListMember>>`

### Flutter: l10n strings

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under `// ── Lists tab` (AC: 1, 2, 3)
  - [x] `shareListAction = 'Share list'`
  - [x] `shareListTitle = 'Invite someone'`
  - [x] `shareListEmailPlaceholder = 'Email address'`
  - [x] `shareListSendButton = 'Send invitation'`
  - [x] `shareListSuccessMessage = 'Invitation sent to {email}.'`
  - [x] `shareListErrorInvalidEmail = 'Enter a valid email address.'`
  - [x] `shareListErrorGeneric = 'Something went wrong. Please try again.'`
  - [x] `inviteAcceptTitle = 'You\u2019re invited'`
  - [x] `inviteAcceptSubtitle = 'Invited by {inviterName}'`
  - [x] `inviteAcceptButton = 'Accept & join list'`
  - [x] `inviteDeclineButton = 'Decline'`
  - [x] `inviteExpiredMessage = 'This invitation has expired or is no longer valid.'`
  - [x] `inviteGoToLists = 'Go to Lists'`
  - [x] `listSharedIndicator = 'Shared'`
  - [x] `listMemberCount = '{count} members'`

### Tests

- [x] Write widget tests for `ShareListSheet` in `apps/flutter/test/features/lists/share_list_sheet_test.dart` (AC: 1)
  - [x] Shows email field and send button
  - [x] Shows validation error when email is empty on submit
  - [x] Shows validation error when email format is invalid (no `@`)
  - [x] Calls `sharingRepository.shareList` on valid submission
  - [x] Shows success message after successful submission
  - [x] Use `_FakeSharingRepository` (stub that completes immediately) for provider override
- [x] Write widget tests for `AcceptInvitationScreen` in `apps/flutter/test/features/lists/accept_invitation_screen_test.dart` (AC: 2)
  - [x] Shows loading indicator while fetching invitation details
  - [x] Shows list name and inviter name from response
  - [x] Accept button triggers `sharingRepository.acceptInvitation`
  - [x] Decline button triggers `sharingRepository.declineInvitation`
  - [x] Shows error message when invitation is invalid (repo throws)
- [x] Write widget tests for shared list indicator in `apps/flutter/test/features/lists/lists_screen_shared_indicator_test.dart` (AC: 3)
  - [x] Shows member avatars when list has 2+ members
  - [x] Shows no shared indicator for personal list (1 member or none)
  - [x] Shows first initial of each member in avatar circle

## Dev Notes

### Color Tokens Confirmed — `colors.accentPrimary` EXISTS

`OnTaskColors` (in `apps/flutter/lib/core/theme/app_theme.dart`) exposes the following tokens:
- `surfacePrimary` — page/sheet background
- `surfaceSecondary` — secondary surface (dividers, avatar circle background alternative)
- `accentPrimary` — confirmed present, use for avatar circles and primary interactive elements
- `accentCommitment` — for commitment/financial context (not relevant here)
- `accentCompletion` — for completion context (not relevant here)
- `textPrimary` — main text
- `textSecondary` — secondary / hint text
- Schedule health and stake zone colours (not relevant here)

For avatar circles: `backgroundColor: colors.accentPrimary`, `foreground: colors.surfacePrimary`.

### Architecture: Stub-first, FR15-16 only

This story implements the **sharing flow stub**: invite, deep-link accept, member list display. No email delivery service is wired (stub logs to console / returns success). No real database writes for invitation tokens — all stub fixtures. Real Drizzle implementation and email service integration are deferred until infrastructure is confirmed.

The story explicitly excludes:
- Real email delivery (Resend / SendGrid — infrastructure decision not yet made)
- Task assignment strategies (Story 5.2)
- Cascade of shared tasks into personal schedule (Story 5.3)
- Member removal / ownership transfer (Story 5.6)

### Deep Link Route: Top-level `/invite/:token`

The invitation acceptance screen must NOT render inside the authenticated tab shell (same reasoning as `/chapter-break` and `/auth/sign-in`). A recipient who hasn't signed up yet needs to reach this route. Register as a top-level `GoRoute` OUTSIDE `StatefulShellRoute.indexedStack`. The redirect logic already passes unauthenticated users to `/auth/sign-in` — so an unauthenticated recipient clicking the link will land at sign-in first, then be redirected back after auth. This is acceptable for the stub; deep-link re-entry after auth is a later enhancement.

Route registration pattern (matches `chapter-break`):
```dart
GoRoute(
  path: '/invite/:token',
  builder: (context, state) => AcceptInvitationScreen(
    token: state.pathParameters['token']!,
  ),
),
```

### API: New `sharing.ts` route file

Follow existing route file pattern (`lists.ts`, `calendar.ts`). All new routes use `@hono/zod-openapi`. New endpoints:
- `POST /v1/lists/:id/share` — body: `{ email: string }`, response: `{ data: { invitationId, listId, inviteeEmail, status } }`
- `GET /v1/invitations/:token` — response: `{ data: { listTitle, inviterName, inviterAvatarInitials, status } }`
- `POST /v1/invitations/:token/accept` — response: `{ data: { listId, listTitle, memberCount } }`
- `POST /v1/invitations/:token/decline` — response: 204
- `GET /v1/lists/:id/members` — response: `{ data: [ListMember], pagination }`

Register `sharingRouter` in `apps/api/src/index.ts` after `listsRouter`.

IMPORTANT: `POST /v1/invitations/:token/accept` must be registered BEFORE `GET /v1/invitations/:token` in Hono to avoid path conflict (Hono matches in registration order).

### Flutter: `list_members_provider` — family provider pattern

Follow the `tasksProvider(listId: ...)` family pattern from `tasks_provider.dart`. The `ListMembersNotifier` is a `@riverpod` family notifier taking `listId` as a positional argument. Generated provider name: `listMembersProvider`.

### Flutter: `SharingRepository` provider

Follow `ListsRepository` / `listsRepositoryProvider` pattern. Inject `ApiClient` via `ref.watch(apiClientProvider)`. Stub implementations should return hardcoded fixture data rather than making real network calls — use `Future.value(...)` to return immediately.

Fixture stub for `getListMembers`:
```dart
Future<List<ListMember>> getListMembers(String listId) async {
  // TODO(impl): real GET /v1/lists/:id/members
  return [
    ListMember(userId: 'user-1', displayName: 'Jordan', avatarInitials: 'J', role: 'owner', joinedAt: DateTime(2026, 3, 31)),
    ListMember(userId: 'user-2', displayName: 'Sam', avatarInitials: 'S', role: 'member', joinedAt: DateTime(2026, 3, 31)),
  ];
}
```

Fixture stub for `getInvitationDetails`:
```dart
Future<InvitationDetails> getInvitationDetails(String token) async {
  // TODO(impl): real GET /v1/invitations/:token
  return InvitationDetails(listTitle: 'Household Chores', inviterName: 'Jordan');
}
```

### Flutter: `list_member.dart` domain model

Use `@freezed` annotation. Include `part 'list_member.freezed.dart'`. Run `flutter pub run build_runner build --delete-conflicting-outputs` after creating the file to generate the freezed classes.

```dart
@freezed
abstract class ListMember with _$ListMember {
  const factory ListMember({
    required String userId,
    required String displayName,
    required String avatarInitials,
    required String role,
    required DateTime joinedAt,
  }) = _ListMember;
}
```

`InvitationDetails` is a simple non-freezed class used only within `SharingRepository` — no need for code generation:
```dart
class InvitationDetails {
  final String listTitle;
  final String inviterName;
  const InvitationDetails({required this.listTitle, required this.inviterName});
}
```

### Flutter: `ShareListSheet` follows `CreateListScreen` pattern

`CreateListScreen` is a `StatefulWidget` shown as a modal bottom sheet. Follow the same structure for `ShareListSheet`. It wraps in `SafeArea`, uses `CupertinoTextField` for input, and `CupertinoButton.filled` for the primary action.

Email validation — simple check: `email.contains('@') && email.contains('.')`.

### Flutter: `ListsScreen` must keep existing tests passing

`apps/flutter/test/features/lists/lists_screen_test.dart` has 5 tests. Adding `listMembersProvider` watches to each list row will cause the provider to be called. Override `listMembersProvider` in the test setup with a stub that returns an empty list (personal list behaviour) — or return a list with 1 member. Do NOT break existing tests.

The `listMembersProvider` is a family provider. Override it using:
```dart
listMembersProvider('list-1').overrideWith(() => _FakeListMembersNotifier(const AsyncData([]))),
```

However, for the existing `lists_screen_test.dart`, since we don't know the list IDs in advance in all tests, the safest approach is to make the shared indicator display graceful on loading state (shows nothing if members are loading or erroring). The existing tests don't need modification if the indicator is hidden when `membersState` is not `AsyncData` with 2+ members.

### DB: Migration naming

Next migration index is `0008`. File: `packages/core/src/schema/migrations/0008_list_sharing.sql`. The journal file (`meta/_journal.json`) and snapshot must be updated manually — Drizzle Kit generates these. For this story, write the SQL manually as `0008_list_sharing.sql` and add a journal entry.  Schema snapshot (`0008_snapshot.json`) is NOT required for this story's stub implementation — skip the snapshot file.

### CRITICAL: Freezed code generation

After creating `list_member.dart`, run:
```
cd apps/flutter && flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `list_member.freezed.dart`. The generated file must be committed. If the build_runner cannot run in the implementation environment, create a minimal manual implementation of the freezed class (matching the pattern in `task_list.freezed.dart`).

### CRITICAL: Riverpod code generation for new providers

After creating `list_members_provider.dart` and `sharing_repository.dart` with `@riverpod` annotations, run build_runner to generate `.g.dart` files. If build_runner cannot run, write the `.g.dart` file manually following the pattern in `lists_provider.g.dart`.

### Previous Story Learnings

- Use `ref.watch(apiClientProvider)` (not `ref.read`) in `@riverpod` providers that construct repositories — consistent with all previous stories.
- All `CupertinoButton` usage: use `minimumSize: const Size(44, 44)` not deprecated `minSize`.
- `showModalBottomSheet` requires `import 'package:flutter/material.dart' show showModalBottomSheet, Colors;` if the file only imports `cupertino.dart`.
- `OnTaskColors` does NOT have `backgroundPrimary`. Use `colors.surfacePrimary`.
- Import ordering in Dart: dart: → package: → relative. Keep linter happy.
- `@riverpod` family providers: positional args generate `providerName(arg)` — e.g., `listMembersProvider('list-1')`.
- Test repository fakes must extend `SharingRepository` using `super(ApiClient(baseUrl: 'http://fake'))` — not `super(null as dynamic)`.
- Loading state tests: use `Completer<T>().future` (never resolves, no timer) instead of `Future.delayed` (leaves timer pending, causes assertion error).
- Test fake base type should be `SharingRepository?` (not the concrete fake subclass) when `buildScreen` needs to accept multiple fake subclasses.

### Files to Create / Modify

**New files:**
- `packages/core/src/schema/list-members.ts`
- `packages/core/src/schema/list-invitations.ts`
- `packages/core/src/schema/migrations/0008_list_sharing.sql`
- `apps/api/src/routes/sharing.ts`
- `apps/flutter/lib/features/lists/domain/list_member.dart`
- `apps/flutter/lib/features/lists/domain/list_member.freezed.dart` (manually authored — build_runner unavailable)
- `apps/flutter/lib/features/lists/data/sharing_repository.dart`
- `apps/flutter/lib/features/lists/data/sharing_repository.g.dart` (manually authored)
- `apps/flutter/lib/features/lists/presentation/list_members_provider.dart`
- `apps/flutter/lib/features/lists/presentation/list_members_provider.g.dart` (manually authored)
- `apps/flutter/lib/features/lists/presentation/widgets/share_list_sheet.dart`
- `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart`
- `apps/flutter/test/features/lists/share_list_sheet_test.dart`
- `apps/flutter/test/features/lists/accept_invitation_screen_test.dart`
- `apps/flutter/test/features/lists/lists_screen_shared_indicator_test.dart`

**Modified files:**
- `packages/core/src/schema/index.ts`
- `packages/core/src/schema/migrations/meta/_journal.json`
- `apps/api/src/index.ts`
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/flutter/lib/core/router/app_router.dart`
- `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart`
- `apps/flutter/lib/features/lists/presentation/lists_screen.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

1. `_FakeSharingRepository.getListMembers` initially returned `Future<List<dynamic>>` — fixed to `Future<List<ListMember>>` with correct import.
2. `super(null as dynamic)` caused runtime type error — fixed to `super(ApiClient(baseUrl: 'http://fake'))` matching established test pattern.
3. Loading state test used `Future.delayed(Duration(hours: 1))` causing `timersPending` assertion failure — fixed to `Completer<InvitationDetails>().future`.
4. `buildScreen` parameter typed as `_FakeSharingRepository?` could not accept `_SlowSharingRepository` — fixed to `SharingRepository?`.

### Completion Notes List

- All 15 new DB/API/Flutter/test files created; all 7 existing files modified as specified.
- Freezed and Riverpod `.g.dart` files authored manually (build_runner unavailable in worktree environment), precisely following existing generated-file patterns (`task_list.freezed.dart`, `lists_repository.g.dart`, `sections_provider.g.dart`).
- `_SharedIndicator` widget gracefully renders `SizedBox.shrink()` on loading/error/personal states — existing `lists_screen_test.dart` (5 tests) pass without modification.
- TypeScript typechecks pass: `pnpm --filter @ontask/api typecheck` and `pnpm --filter @ontask/core typecheck` both clean.
- Full Flutter regression suite: **596 tests passed, 0 failures**.
- `POST /v1/invitations/:token/accept` registered before `GET /v1/invitations/:token` in Hono to avoid path shadowing.
- Migration journal updated at index 8; snapshot file skipped (stub implementation, not required for story).

### File List

**New files created:**
- `packages/core/src/schema/list-members.ts`
- `packages/core/src/schema/list-invitations.ts`
- `packages/core/src/schema/migrations/0008_list_sharing.sql`
- `apps/api/src/routes/sharing.ts`
- `apps/flutter/lib/features/lists/domain/list_member.dart`
- `apps/flutter/lib/features/lists/domain/list_member.freezed.dart`
- `apps/flutter/lib/features/lists/data/sharing_repository.dart`
- `apps/flutter/lib/features/lists/data/sharing_repository.g.dart`
- `apps/flutter/lib/features/lists/presentation/list_members_provider.dart`
- `apps/flutter/lib/features/lists/presentation/list_members_provider.g.dart`
- `apps/flutter/lib/features/lists/presentation/widgets/share_list_sheet.dart`
- `apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart`
- `apps/flutter/test/features/lists/share_list_sheet_test.dart`
- `apps/flutter/test/features/lists/accept_invitation_screen_test.dart`
- `apps/flutter/test/features/lists/lists_screen_shared_indicator_test.dart`

**Modified files:**
- `packages/core/src/schema/index.ts`
- `packages/core/src/schema/migrations/meta/_journal.json`
- `apps/api/src/index.ts`
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/flutter/lib/core/router/app_router.dart`
- `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart`
- `apps/flutter/lib/features/lists/presentation/lists_screen.dart`

### Change Log

- 2026-03-31: Story implemented by claude-sonnet-4-6.
  - Added `list_members` and `list_invitations` DB schema tables with migration `0008_list_sharing.sql`.
  - Added 5 stub API routes in `apps/api/src/routes/sharing.ts` (share list, get/accept/decline invitation, list members).
  - Added 15 new `AppStrings` constants for the sharing/invitation UI.
  - Created `ListMember` freezed domain model with manually authored generated files.
  - Created `SharingRepository` with stub fixture data and manually authored `.g.dart`.
  - Created `ListMembersNotifier` family provider with manually authored `.g.dart`.
  - Created `ShareListSheet` modal bottom sheet widget (email input, validation, success/error states).
  - Created `AcceptInvitationScreen` (loading/content/error states, accept/decline actions).
  - Registered `/invite/:token` top-level GoRoute (no shell chrome, matches `chapter-break` pattern).
  - Added `_SharedIndicator` + `_MemberAvatar` to `ListsScreen` — shows stacked avatars and member count for shared lists (2+ members); gracefully hidden for personal/loading/error states.
  - Added "Share list" action to `ListDetailScreen` more-actions sheet.
  - 19 new widget tests added (7 share sheet, 6 accept screen, 6 shared indicator); 596/596 tests pass.
