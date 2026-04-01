# Story 5.1: List Sharing & Invitations

Status: in-progress

## Story

As a user,
I want to share any list with named people by email invitation,
So that my household or team can coordinate tasks in one place.

## Acceptance Criteria

1. **Given** the user opens a list and chooses "Share" **When** they enter an email address **Then** an invitation is sent to that address and the list is labelled "shared" with a member count (FR15)

2. **Given** an invitation is received **When** the recipient opens the deep link from the email **Then** they are shown the list name and the name of the person who invited them **And** accepting adds them as a list member with full task visibility (FR16) **And** if the recipient is not yet subscribed, they are routed through the independent trial onboarding path (FR86)

3. **Given** a user is a member of a shared list **When** they view their Lists tab **Then** the shared list appears with a shared indicator and member avatars

## Tasks / Subtasks

### Backend: New DB tables in `packages/core`

- [ ] Add `list_members` table to `packages/core/src/schema/list-members.ts` (AC: 1, 2, 3)
  - [ ] Columns: `id` (uuid PK), `list_id` (uuid NOT NULL), `user_id` (uuid NOT NULL), `role` (text NOT NULL — `'owner'` | `'member'`), `created_at` (timestamptz), `updated_at` (timestamptz)
  - [ ] Unique constraint on `(list_id, user_id)` — one membership row per user per list
  - [ ] Export as `listMembersTable` from `packages/core/src/schema/list-members.ts`

- [ ] Add `list_invitations` table to `packages/core/src/schema/list-invitations.ts` (AC: 1, 2)
  - [ ] Columns: `id` (uuid PK), `list_id` (uuid NOT NULL), `invited_by_user_id` (uuid NOT NULL), `invitee_email` (text NOT NULL), `token` (text NOT NULL UNIQUE — secure random, used in deep link), `status` (text NOT NULL DEFAULT `'pending'` — `'pending'` | `'accepted'` | `'revoked'`), `created_at` (timestamptz), `updated_at` (timestamptz), `expires_at` (timestamptz NOT NULL — 7 days from creation)
  - [ ] Unique constraint on `(list_id, invitee_email)` WHERE `status = 'pending'` — prevent duplicate pending invites to the same email for the same list (partial index)
  - [ ] Export as `listInvitationsTable` from `packages/core/src/schema/list-invitations.ts`

- [ ] Export both new tables from `packages/core/src/schema/index.ts` (AC: 1, 2, 3)
  - [ ] Add `export { listMembersTable } from './list-members.js'`
  - [ ] Add `export { listInvitationsTable } from './list-invitations.js'`

- [ ] Generate migration `packages/core/src/schema/migrations/0008_list_sharing.sql` (AC: 1, 2, 3)
  - [ ] Run `pnpm drizzle-kit generate` from `packages/core/` to produce the migration file
  - [ ] Commit the generated SQL file and updated `meta/_journal.json`
  - [ ] Migration must create both `list_members` and `list_invitations` tables with all constraints

### Backend: `listSchema` extension in `apps/api/src/routes/lists.ts`

- [ ] Extend `listSchema` to include sharing fields (AC: 1, 3)
  - [ ] Add `isShared: z.boolean()` — true when `memberCount > 1`
  - [ ] Add `memberCount: z.number().int()` — number of accepted members
  - [ ] Add `memberAvatarInitials: z.array(z.string()).max(3)` — first letter of each member's display name, capped at 3 for UI avatars (stub: empty array)
  - [ ] Update `stubList()` helper with `isShared: false, memberCount: 1, memberAvatarInitials: []`
  - [ ] `GET /v1/lists` stub response now includes these fields on every list item
  - [ ] `GET /v1/lists/:id` stub response now includes these fields

### Backend: New sharing endpoints in `apps/api/src/routes/lists.ts`

All new routes must be registered BEFORE the parameterized `GET /v1/lists/{id}` route (specific paths before `/:id`).

- [ ] `POST /v1/lists/{id}/share` — send invitation (AC: 1)
  - [ ] Request body schema: `{ email: z.string().email() }`
  - [ ] Response 201: `{ data: { invitationId, listId, inviteeEmail, status, expiresAt } }`
  - [ ] Response 404: list not found
  - [ ] Response 409: invitation already pending for this email+list
  - [ ] Response 422: invitee is already a member
  - [ ] Stub: return 201 with plausible static data; add `TODO(impl): insert into list_invitations, send email via email service (deferred), check ownership`
  - [ ] Tag: `'Lists'`

- [ ] `GET /v1/lists/{id}/members` — list members (AC: 3)
  - [ ] Response 200: `{ data: [{ userId, email, displayName, role, joinedAt }], pagination: { cursor, hasMore } }`
  - [ ] Response 404: list not found
  - [ ] Stub: return 200 with one stub owner member
  - [ ] Tag: `'Lists'`

- [ ] `POST /v1/invitations/{token}/accept` — accept invitation via deep link (AC: 2)
  - [ ] This route is NOT under `/v1/lists/` — it is a standalone resource at `/v1/invitations/:token/accept`
  - [ ] Request body: empty (`{}`)
  - [ ] Response 200: `{ data: { listId, listTitle, invitedByName, membershipId } }` — after acceptance, return enough for Flutter to navigate to the list
  - [ ] Response 404: token not found or expired
  - [ ] Response 409: already a member
  - [ ] Response 410: invitation revoked
  - [ ] Stub: return 200 with static data; add `TODO(impl): validate token, check expiry, insert list_members row, update invitation status to 'accepted', trigger FR86 onboarding if user not subscribed`
  - [ ] Tag: `'Invitations'`
  - [ ] Register this route in a NEW router file `apps/api/src/routes/invitations.ts` — do NOT add it to `lists.ts`
  - [ ] Mount the new router in `apps/api/src/index.ts`

- [ ] `GET /v1/invitations/{token}` — get invitation preview (AC: 2)
  - [ ] Used by the Flutter deep link handler to show "X invited you to list Y" BEFORE the user taps Accept
  - [ ] Response 200: `{ data: { listId, listTitle, invitedByName, inviteeEmail, status, expiresAt } }`
  - [ ] Response 404: token not found or expired
  - [ ] Stub: return 200 with static preview data
  - [ ] Tag: `'Invitations'`
  - [ ] In same `apps/api/src/routes/invitations.ts` file, registered BEFORE `/v1/invitations/{token}/accept`

### Flutter: Domain models

- [ ] Add `ListMember` domain model to `apps/flutter/lib/features/lists/domain/list_member.dart` (AC: 3)
  - [ ] Freezed class with fields: `userId` (String), `email` (String), `displayName` (String), `role` (String — `'owner'` | `'member'`), `joinedAt` (DateTime)
  - [ ] `part 'list_member.freezed.dart'` — run `build_runner` and commit generated files

- [ ] Add `ListInvitation` domain model to `apps/flutter/lib/features/lists/domain/list_invitation.dart` (AC: 1, 2)
  - [ ] Freezed class with fields: `invitationId` (String), `listId` (String), `listTitle` (String), `invitedByName` (String), `inviteeEmail` (String), `status` (String), `expiresAt` (DateTime)
  - [ ] `part 'list_invitation.freezed.dart'` — run `build_runner` and commit generated files

- [ ] Extend `TaskList` domain model in `apps/flutter/lib/features/lists/domain/task_list.dart` (AC: 1, 3)
  - [ ] Add `isShared` (bool, default false), `memberCount` (int, default 1), `memberAvatarInitials` (List\<String\>, default const [])
  - [ ] Mark with `@Default(false)`, `@Default(1)`, `@Default(<String>[])` — Freezed default syntax
  - [ ] Regenerate `task_list.freezed.dart` — commit

### Flutter: DTOs

- [ ] Add `ListMemberDto` to `apps/flutter/lib/features/lists/data/list_member_dto.dart` (AC: 3)
  - [ ] Freezed + `json_serializable` with `fromJson`/`toDomain()` mapping to `ListMember`
  - [ ] Commit generated `.freezed.dart` and `.g.dart`

- [ ] Add `ListInvitationDto` to `apps/flutter/lib/features/lists/data/list_invitation_dto.dart` (AC: 1, 2)
  - [ ] Freezed + `json_serializable` with `fromJson`/`toDomain()` mapping to `ListInvitation`
  - [ ] Commit generated `.freezed.dart` and `.g.dart`

- [ ] Extend `ListDto` in `apps/flutter/lib/features/lists/data/list_dto.dart` (AC: 1, 3)
  - [ ] Add `isShared` (bool with `@JsonKey(defaultValue: false)`), `memberCount` (int with `@JsonKey(defaultValue: 1)`), `memberAvatarInitials` (List\<String\> with `@JsonKey(defaultValue: []`)
  - [ ] Extend `toDomain()` to pass these fields through
  - [ ] Regenerate `list_dto.freezed.dart` and `list_dto.g.dart` — commit

### Flutter: Repository methods

- [ ] Add sharing methods to `apps/flutter/lib/features/lists/data/lists_repository.dart` (AC: 1, 3)
  - [ ] `Future<ListInvitation> inviteToList(String listId, String email)` — `POST /v1/lists/$listId/share`
  - [ ] `Future<List<ListMember>> getListMembers(String listId)` — `GET /v1/lists/$listId/members`
  - [ ] Parse `response.data!['data']` using `ListInvitationDto.fromJson` / `ListMemberDto.fromJson` respectively

- [ ] Add invitation repository `apps/flutter/lib/features/lists/data/invitations_repository.dart` (AC: 2)
  - [ ] `Future<ListInvitation> getInvitation(String token)` — `GET /v1/invitations/$token`
  - [ ] `Future<ListInvitation> acceptInvitation(String token)` — `POST /v1/invitations/$token/accept`
  - [ ] `@riverpod InvitationsRepository invitationsRepository(Ref ref)` provider — follow `listsRepository` provider pattern
  - [ ] Commit generated `invitations_repository.g.dart`

### Flutter: Share sheet (bottom sheet)

- [ ] Create `apps/flutter/lib/features/lists/presentation/widgets/share_list_sheet.dart` (AC: 1)
  - [ ] `StatefulWidget` (not `ConsumerWidget`) that accepts `listId` and `listTitle` as constructor params
  - [ ] Shows a text field for email input with a `CupertinoTextField`
  - [ ] "Send Invite" `CupertinoButton` — calls `listsRepository.inviteToList(listId, email)` via a callback from the parent `ConsumerStatefulWidget` that mounts this sheet
  - [ ] Shows loading spinner while request is in flight, success message on 201, error message on failure
  - [ ] Uses `colors.surfacePrimary` as background; `colors.textSecondary` for placeholder text
  - [ ] `minimumSize: const Size(44, 44)` on any `CupertinoButton`

### Flutter: Invitation acceptance screen

- [ ] Create `apps/flutter/lib/features/lists/presentation/invitation_accept_screen.dart` (AC: 2)
  - [ ] `ConsumerStatefulWidget` — receives `token` param via GoRouter
  - [ ] On mount: calls `invitationsRepository.getInvitation(token)` — shows loading state
  - [ ] Shows: list name, name of person who invited them, "Accept" and "Decline" buttons
  - [ ] "Accept" calls `invitationsRepository.acceptInvitation(token)` — on success navigates to the list (`context.go('/lists/${invitation.listId}')`)
  - [ ] If recipient is not subscribed, show info text: `AppStrings.invitationTrialNote` pointing to the onboarding path (FR86 — actual subscription routing implemented in Story 9.6; this story stubs it with the info text only)
  - [ ] "Decline" simply pops the screen
  - [ ] Error states: expired token → `AppStrings.invitationExpired`; already member → `AppStrings.invitationAlreadyMember`

### Flutter: GoRouter deep link registration

- [ ] Register `/invitation/:token` route in `apps/flutter/lib/core/router/app_router.dart` (AC: 2)
  - [ ] Route path: `/invitation/:token`
  - [ ] Builder: `InvitationAcceptScreen(token: state.pathParameters['token']!)`
  - [ ] Deep link entry — no auth guard required (accept flow may be for a new user); stub: always show the acceptance screen
  - [ ] Note: The AASA deep link wiring (Universal Links from email) is an infrastructure concern handled in Story 13.1. This story only registers the GoRouter route so the app handles `/invitation/:token` navigation correctly.

### Flutter: `ListDetailScreen` "Share" entry point

- [ ] Add "Share" button to `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart` (AC: 1)
  - [ ] Add a trailing `CupertinoButton` in the `CupertinoNavigationBar` — icon: `CupertinoIcons.person_badge_plus` or text "Share" (use text, consistent with existing nav bar buttons)
  - [ ] Only show "Share" button when NOT in multi-select mode (`_isMultiSelectMode == false`)
  - [ ] On tap: open `ShareListSheet` via `showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => ShareListSheet(listId: widget.listId, listTitle: list?.title ?? ''))`
  - [ ] Import `'package:flutter/material.dart' show showModalBottomSheet, Colors'` selectively — `list_detail_screen.dart` already imports Material; verify `showModalBottomSheet` is accessible

### Flutter: Shared list indicator in `ListsScreen`

- [ ] Update list row rendering in `apps/flutter/lib/features/lists/presentation/lists_screen.dart` (AC: 3)
  - [ ] For lists where `list.isShared == true`, show a "shared" badge or member avatars beside the list title
  - [ ] Member avatar initials: show up to 3 circles with `memberAvatarInitials` text, styled with `colors.accentPrimary` background
  - [ ] Member count label: e.g. `"${list.memberCount} members"` in `colors.textSecondary` style
  - [ ] Use `AppStrings.listSharedBadge` for accessibility label (new string, see l10n below)

### Flutter: l10n strings

- [ ] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Shared lists (FR15-16) ──` section (AC: 1, 2, 3)
  - [ ] `static const String listShareButton = 'Share';` — nav bar button label
  - [ ] `static const String listShareSheetTitle = 'Invite to list';` — bottom sheet heading
  - [ ] `static const String listShareEmailPlaceholder = 'Email address';` — text field placeholder
  - [ ] `static const String listShareSendButton = 'Send Invite';` — CTA button
  - [ ] `static const String listShareSuccess = 'Invitation sent!';` — success feedback
  - [ ] `static const String listShareError = 'Could not send invitation. Please try again.';`
  - [ ] `static const String listSharedBadge = 'Shared list';` — accessibility label for shared indicator
  - [ ] `static const String invitationTitle = 'You're invited';` — acceptance screen header
  - [ ] `static const String invitationAcceptButton = 'Accept invitation';`
  - [ ] `static const String invitationDeclineButton = 'Decline';`
  - [ ] `static const String invitationExpired = 'This invitation has expired or is no longer valid.';`
  - [ ] `static const String invitationAlreadyMember = 'You are already a member of this list.';`
  - [ ] `static const String invitationTrialNote = 'Start a free trial to join this list and access all features.';`

### Tests

- [ ] Widget tests for `ShareListSheet` in `apps/flutter/test/features/lists/share_list_sheet_test.dart` (AC: 1)
  - [ ] Sheet renders email text field and "Send Invite" button
  - [ ] Tapping "Send Invite" with empty email does NOT fire network call (validate empty input)
  - [ ] Tapping "Send Invite" with valid email triggers `inviteToList` — stub the repository with a `mocktail` mock
  - [ ] Do NOT mount `ListDetailScreen` in these tests; test the bare `ShareListSheet` widget

- [ ] Widget tests for `InvitationAcceptScreen` in `apps/flutter/test/features/lists/invitation_accept_screen_test.dart` (AC: 2)
  - [ ] Loading state shown on mount
  - [ ] Invitation details rendered after `getInvitation` returns
  - [ ] "Accept" button calls `acceptInvitation`
  - [ ] Override `invitationsRepositoryProvider` with a stub notifier — same pattern as `listsRepositoryProvider` overrides from Stories 4.1/4.2: extend `InvitationsRepository` with stub overrides that prevent real Dio calls

- [ ] Verify `ListDto.fromJson` handles `isShared`, `memberCount`, `memberAvatarInitials` correctly — add unit test in `apps/flutter/test/features/lists/list_dto_test.dart` (AC: 3)
  - [ ] JSON with all new fields parses correctly
  - [ ] JSON WITHOUT new fields (old API stub) parses correctly using `@JsonKey(defaultValue:)` defaults

## Dev Notes

### CRITICAL: Route registration order — specific before parameterized

`apps/api/src/routes/lists.ts` currently has routes in this order (existing, do NOT change):
1. `POST /v1/lists`
2. `GET /v1/lists`
3. `GET /v1/lists/{id}/prediction` ← specific before `{id}`
4. `GET /v1/lists/{id}`
5. `PATCH /v1/lists/{id}`
6. `DELETE /v1/lists/{id}/archive`

New sharing endpoints in `lists.ts` MUST be added BEFORE the `GET /v1/lists/{id}` handler (after `GET /v1/lists/{id}/prediction`). Add:
- `POST /v1/lists/{id}/share` — before `GET /v1/lists/{id}`
- `GET /v1/lists/{id}/members` — before `GET /v1/lists/{id}`

The invitation routes (`GET /v1/invitations/{token}` and `POST /v1/invitations/{token}/accept`) go in a separate `apps/api/src/routes/invitations.ts` file; within that file, register `GET /v1/invitations/{token}` BEFORE `POST /v1/invitations/{token}/accept` to prevent path shadowing.

### CRITICAL: New invitations router must be mounted in `apps/api/src/index.ts`

After creating `apps/api/src/routes/invitations.ts` with an `invitationsRouter` export, mount it in `apps/api/src/index.ts` alongside the existing route mounts. Follow the same pattern as other routers already mounted there.

### CRITICAL: Drizzle schema — `casing: 'camelCase'` handles column name mapping

Do NOT add manual field mapping in schema or repository. Column names in SQL are snake_case (e.g., `list_id`, `invited_by_user_id`). Drizzle with `casing: 'camelCase'` (in `apps/api/src/db/index.ts`) transforms these automatically to camelCase in TypeScript. Write Drizzle schema columns in camelCase — `listId: uuid().notNull()` — and Drizzle generates the correct snake_case DDL.

### CRITICAL: `z.record()` requires TWO arguments

If any Zod schema in the new routes uses `z.record(...)`, it must be `z.record(z.string(), z.string())` — this Zod version requires both key AND value type arguments.

### CRITICAL: All local TS imports must use `.js` extensions

Every `import` in the new `invitations.ts` route file must use `.js` extension for local files (e.g., `import { ok, err } from '../lib/response.js'`). TypeScript NodeNext module resolution requires this. Follow every existing route file as reference.

### CRITICAL: `listSchema` extension is additive — do NOT break existing API consumers

The existing `listSchema` in `apps/api/src/routes/lists.ts` has: `id, userId, title, defaultDueDate, position, archivedAt, createdAt, updatedAt`. Add the three new sharing fields (`isShared`, `memberCount`, `memberAvatarInitials`) to this schema with sensible defaults in all existing stub responses (`stubList()` helper). Existing tests that mock this response must continue to pass.

### CRITICAL: Flutter — Freezed default syntax for optional fields with defaults

When adding new fields to existing Freezed classes (e.g., `TaskList`, `ListDto`), use `@Default(value)` annotation, NOT a nullable type, to keep the API clean:
```dart
@Default(false) bool isShared,
@Default(1) int memberCount,
@Default(<String>[]) List<String> memberAvatarInitials,
```
Freezed generates correct serialization for these. For `ListDto` specifically, pair with `@JsonKey(defaultValue: ...)` to handle old API stubs that may not include the field.

### CRITICAL: Committed generated files

All `.freezed.dart` and `.g.dart` files MUST be committed to the repo. The `.gitignore` explicitly does NOT ignore them (confirmed in architecture). Run `flutter pub run build_runner build --delete-conflicting-outputs` after any Dart model changes and commit all generated output.

### CRITICAL: `surfacePrimary` not `backgroundPrimary`

`OnTaskColors` does NOT have `backgroundPrimary`. Use `colors.surfacePrimary` for sheet/screen backgrounds and `colors.textSecondary` for placeholder/secondary text. This applies to `ShareListSheet`, `InvitationAcceptScreen`, and any new widgets.

### CRITICAL: `minimumSize: const Size(44, 44)` on `CupertinoButton` — `minSize` is deprecated

Use `minimumSize: const Size(44, 44)` not `minSize`. Consistent with Stories 3.7, 4.1, 4.2, 4.3.

### CRITICAL: Widget tests need Riverpod overrides to prevent real Dio calls

Tests that use `ConsumerWidget`s or mount screens with providers MUST override repositories with stub notifiers. Pattern from Story 4.1/4.2:
```dart
final container = ProviderContainer(
  overrides: [
    listsRepositoryProvider.overrideWithValue(FakeListsRepository()),
    invitationsRepositoryProvider.overrideWithValue(FakeInvitationsRepository()),
  ],
);
```
For `ShareListSheet` (plain `StatefulWidget`) — test via callback injection, no provider override needed.

### CRITICAL: `InvitationAcceptScreen` is the deep link landing page — no auth guard for this route

The invitation acceptance flow must work for new users arriving via email deep link. In v1, stub the auth check in the router (no guard on `/invitation/:token`). The actual auth-before-accept flow is a detail for Story 9.6 (invited user onboarding). For Story 5.1, simply show the acceptance screen and let the API stub return 200.

### API: `invitations.ts` route file structure

```typescript
// apps/api/src/routes/invitations.ts
import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// GET /v1/invitations/{token}  — REGISTERED FIRST
// POST /v1/invitations/{token}/accept  — REGISTERED SECOND

export { app as invitationsRouter }
```

### DB schema: `list_members` and `list_invitations` — no FK to users table yet

The `users` table FK constraint pattern is deferred (see `TODO(story-TBD)` in `lists.ts` — `userId` on `listsTable` still has no FK). Follow the same pattern: define `userId`, `invitedByUserId` as `uuid().notNull()` without an FK reference. Add `// TODO(story-TBD): FK to users table when users schema is finalized` comment.

### DB: Partial unique index for pending invitations

The constraint "no duplicate pending invites to the same email+list" is ideally a partial unique index: `UNIQUE (list_id, invitee_email) WHERE status = 'pending'`. Drizzle's `pgTable` supports this via `.unique()` with a conditional expression. If the Drizzle version in the project doesn't cleanly support conditional indexes in the schema definition, implement the uniqueness check in the API route logic and add a `TODO` comment.

### Flutter: `task_list.freezed.dart` regeneration will cascade

Modifying `TaskList` in `task_list.dart` (adding `isShared`, `memberCount`, `memberAvatarInitials`) will regenerate `task_list.freezed.dart`. This is expected and correct. After running `build_runner`, verify that ALL `.g.dart` and `.freezed.dart` files that were re-generated are committed.

### Flutter: GoRouter `/invitation/:token` deep link path

The GoRouter path uses `:token` (Hono/GoRouter style). Retrieve it with `state.pathParameters['token']!`. The Universal Link email domain path (`ontaskhq.com/invitation/:token`) mapping to the app is an AASA concern handled in Story 13.1 — this story only registers the app-side route.

### Flutter: `listsRepository` already uses `apiClientProvider` — follow that exact import chain

`apps/flutter/lib/features/lists/data/lists_repository.dart` shows the authoritative pattern for new `@riverpod`-annotated repository providers:
```dart
@riverpod
ListsRepository listsRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return ListsRepository(client);
}
```
Use the same pattern in `invitations_repository.dart` with `InvitationsRepository`.

### UX: Shared list indicator in `ListsScreen`

The shared indicator should be lightweight — a small row of coloured circles (avatar initials, max 3) and a member count. Do not create a custom painter; use `Container` + `Text` inside a `Row`. Style the avatar circles with `colors.accentPrimary` background and white text. The existing `ListsScreen` list uses `CupertinoListTile` or similar; match the existing row widget shape.

### Files to Create

**`packages/core/src/schema/`:**
- `list-members.ts` (new)
- `list-invitations.ts` (new)
- `migrations/0008_list_sharing.sql` (generated by `drizzle-kit generate`)
- `migrations/meta/0008_snapshot.json` (generated)
- `migrations/meta/_journal.json` (updated by generator)

**`apps/api/src/routes/`:**
- `invitations.ts` (new)

**`apps/flutter/lib/features/lists/domain/`:**
- `list_member.dart` (new)
- `list_member.freezed.dart` (generated)
- `list_invitation.dart` (new)
- `list_invitation.freezed.dart` (generated)

**`apps/flutter/lib/features/lists/data/`:**
- `list_member_dto.dart` (new)
- `list_member_dto.freezed.dart` (generated)
- `list_member_dto.g.dart` (generated)
- `list_invitation_dto.dart` (new)
- `list_invitation_dto.freezed.dart` (generated)
- `list_invitation_dto.g.dart` (generated)
- `invitations_repository.dart` (new)
- `invitations_repository.g.dart` (generated)

**`apps/flutter/lib/features/lists/presentation/`:**
- `invitation_accept_screen.dart` (new)
- `widgets/share_list_sheet.dart` (new)

**`apps/flutter/test/features/lists/`:**
- `share_list_sheet_test.dart` (new)
- `invitation_accept_screen_test.dart` (new)
- `list_dto_test.dart` (new)

### Files to Modify

**`packages/core/src/schema/`:**
- `index.ts` — add exports for `listMembersTable`, `listInvitationsTable`

**`apps/api/src/`:**
- `routes/lists.ts` — extend `listSchema` and `stubList()`, add `POST /v1/lists/{id}/share`, `GET /v1/lists/{id}/members`
- `index.ts` — mount `invitationsRouter`

**`apps/flutter/lib/features/lists/`:**
- `domain/task_list.dart` — add `isShared`, `memberCount`, `memberAvatarInitials` fields
- `domain/task_list.freezed.dart` — regenerated
- `data/list_dto.dart` — extend with new sharing fields + `toDomain()` mapping
- `data/list_dto.freezed.dart` — regenerated
- `data/list_dto.g.dart` — regenerated
- `data/lists_repository.dart` — add `inviteToList()`, `getListMembers()`
- `data/lists_repository.g.dart` — regenerated (provider hash update)
- `presentation/list_detail_screen.dart` — add "Share" nav bar button
- `presentation/lists_screen.dart` — show shared indicator + member avatars

**`apps/flutter/lib/core/l10n/strings.dart` — add sharing strings section**

**`apps/flutter/lib/core/router/app_router.dart` — add `/invitation/:token` route**

**`_bmad-output/implementation-artifacts/sprint-status.yaml` — update `5-1-list-sharing-invitations` from `backlog` to `ready-for-dev`**

### Project Structure Notes

- Sharing feature stays within `apps/flutter/lib/features/lists/` — no new top-level feature directory needed
- `invitations_repository.dart` lives in `lists/data/` not a standalone `invitations/` feature directory — invitations are part of the lists domain
- `InvitationAcceptScreen` lives in `lists/presentation/` for the same reason
- The API `invitations.ts` route file is a new file alongside existing route files in `apps/api/src/routes/` — separate from `lists.ts` to keep file size manageable
- No changes to `packages/scheduling/`, `packages/ai/`, `apps/mcp/`, or `apps/admin/`
- 100% test coverage NOT enforced for `apps/api` or `apps/flutter` (only `packages/ai` and `packages/scheduling` require 100%)

### References

- FR15: Users can share any list by email invitation — [Source: _bmad-output/planning-artifacts/epics.md#Story-5.1]
- FR16: Invitation recipient sees list name and inviter name; accepting adds them as member with full task visibility — [Source: _bmad-output/planning-artifacts/epics.md#Story-5.1]
- FR86: Invited non-subscribed users are routed through independent trial onboarding — [Source: _bmad-output/planning-artifacts/epics.md#Story-5.1]
- Route registration: specific paths before parameterized `/:id` routes — [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns — Naming Conventions; Story 4.1 Dev Notes]
- `casing: 'camelCase'` — [Source: _bmad-output/planning-artifacts/architecture.md#Database Driver]
- `z.record()` requires two arguments — [Source: Story 4.1 key context]
- `.js` extensions in TS imports — [Source: Story 4.1 key context]
- `surfacePrimary` not `backgroundPrimary` — [Source: Stories 3.6, 4.1, 4.2, 4.3 Dev Notes]
- `minimumSize: const Size(44, 44)` — [Source: Stories 3.7, 4.3 Dev Notes]
- Generated `.freezed.dart` and `.g.dart` committed to repo — [Source: _bmad-output/planning-artifacts/architecture.md#CI/CD]
- Widget tests with stub notifiers — [Source: Stories 4.1, 4.2, 4.3 Dev Notes]
- `packages/core/src/schema/index.ts` — existing schema exports pattern; `list-members.ts` and `list-invitations.ts` follow same export style
- `apps/api/src/routes/lists.ts` — existing lists route as template for new sharing endpoints
- `apps/flutter/lib/features/lists/data/lists_repository.dart` — authoritative repository pattern for this feature
- `apps/flutter/lib/features/lists/domain/task_list.dart` — extend with Freezed `@Default` syntax
- Migration numbering: last migration is `0007_google_webhook_channel.sql` → next is `0008_list_sharing.sql` — [Source: packages/core/src/schema/migrations/meta/_journal.json]
- Story 9.6 (invited user onboarding path) is deferred dependency for FR86 full implementation — stub with `invitationTrialNote` info text in this story only

## Review Findings

### Decision-Needed

- [ ] [Review][Decision] Route file naming deviation: `sharing.ts` / `sharingRouter` vs spec's `invitations.ts` / `invitationsRouter` — Dev combined all sharing + invitation endpoints into one `sharing.ts` file instead of a separate `invitations.ts`. This is a structural deviation but functionally correct. Decide: (a) rename/split to match spec exactly, or (b) accept the combined approach and update spec accordingly.

- [ ] [Review][Decision] Invitation status enum uses `'declined'` not `'revoked'` — Spec requires `'pending' | 'accepted' | 'revoked'` but impl uses `'pending' | 'accepted' | 'declined'`. The acceptance screen "Decline" button also calls `declineInvitation()`, so the whole flow is internally consistent with `'declined'`. Decide: (a) change to `'revoked'` throughout per spec, or (b) accept `'declined'` as the correct terminology and update spec.

- [ ] [Review][Decision] `ShareListSheet` is `ConsumerStatefulWidget` not `StatefulWidget` — Spec says "StatefulWidget (not ConsumerWidget) that accepts listId and listTitle … calls listsRepository.inviteToList via a callback from the parent ConsumerStatefulWidget". Impl uses ConsumerStatefulWidget directly and calls `sharingRepository.shareList()`. Decide: (a) refactor to StatefulWidget with callback injection per spec, or (b) accept ConsumerStatefulWidget as the correct approach.

- [ ] [Review][Decision] `lists_repository.dart` not modified — Spec required adding `inviteToList()` and `getListMembers()` to `ListsRepository`. Impl created `sharing_repository.dart` (`SharingRepository`) instead. Functionally equivalent but deviates from spec's data layer architecture. Decide: (a) add methods to `lists_repository.dart` and deprecate `sharing_repository.dart`, or (b) accept `SharingRepository` as a standalone repository.

- [ ] [Review][Decision] GoRouter path is `/invite/:token` not `/invitation/:token` — Spec requires `/invitation/:token` and deep-link note also says `ontaskhq.com/invitation/:token`. Impl registers `/invite/:token`. Decide: (a) change to `/invitation/:token` throughout, or (b) confirm `/invite/:token` is the intended path.

### Patches

- [ ] [Review][Patch] `listSchema` in `lists.ts` not extended with sharing fields — `isShared`, `memberCount`, `memberAvatarInitials` missing from `listSchema` and `stubList()`. AC3 spec: "stub: `isShared: false, memberCount: 1, memberAvatarInitials: []`". Existing API tests will receive responses without these fields. [apps/api/src/routes/lists.ts:26]

- [ ] [Review][Patch] `TaskList` domain model not extended — `isShared` (bool), `memberCount` (int), `memberAvatarInitials` (List<String>) absent from `task_list.dart`; `task_list.freezed.dart` was regenerated but without these fields. [apps/flutter/lib/features/lists/domain/task_list.dart]

- [ ] [Review][Patch] `ListDto` not extended with sharing fields — `isShared`, `memberCount`, `memberAvatarInitials` absent from `list_dto.dart`; `toDomain()` does not pass them through. `list_dto.freezed.dart` and `list_dto.g.dart` were regenerated but are stale relative to what is needed. [apps/flutter/lib/features/lists/data/list_dto.dart]

- [ ] [Review][Patch] `list_dto_test.dart` not created — Spec required unit tests for `ListDto.fromJson` handling new fields with and without defaults. [apps/flutter/test/features/lists/list_dto_test.dart — missing]

- [ ] [Review][Patch] `ListInvitation` domain model and generated files missing — `list_invitation.dart` and `list_invitation.freezed.dart` not committed. Spec required a Freezed domain model for invitation data. [apps/flutter/lib/features/lists/domain/list_invitation.dart — missing]

- [ ] [Review][Patch] `list_member_dto.dart`, `list_invitation_dto.dart` and their generated files missing — Spec required full DTO layer for both member and invitation responses with `fromJson`/`toDomain()`. None of these files exist on the branch. [apps/flutter/lib/features/lists/data/ — multiple files missing]

- [ ] [Review][Patch] `POST /v1/lists/{id}/share` missing 409 response — Spec requires 409 for "invitation already pending for this email+list". Route definition only has 201, 404, 422. [apps/api/src/routes/sharing.ts:100–130]

- [ ] [Review][Patch] `invitationSchema` missing `expiresAt` — Spec 201 response: `{ invitationId, listId, inviteeEmail, status, expiresAt }`. Actual schema omits `expiresAt`. [apps/api/src/routes/sharing.ts:13]

- [ ] [Review][Patch] `invitationDetailsSchema` field mismatches — Spec: `{ listId, listTitle, invitedByName, inviteeEmail, status, expiresAt }`. Actual: `{ listTitle, inviterName, inviterAvatarInitials, status }` — missing `listId`, `inviteeEmail`, `expiresAt`; uses `inviterName` not `invitedByName`. Repository reads `data['inviterName']` which is consistent with current API schema but diverges from spec. [apps/api/src/routes/sharing.ts:22]

- [ ] [Review][Patch] `acceptInvitationResponseSchema` missing `membershipId` — Spec: `{ listId, listTitle, invitedByName, membershipId }`. Actual: `{ listId, listTitle, memberCount }` — `membershipId` absent, `memberCount` not in spec. [apps/api/src/routes/sharing.ts:29]

- [ ] [Review][Patch] `minimumSize: const Size(44, 44)` absent on CupertinoButton instances — All `CupertinoButton` and `CupertinoButton.filled` widgets in new files lack `minimumSize: const Size(44, 44)`. Spec critical note and story patterns 3.7/4.1–4.3 require it. [apps/flutter/lib/features/lists/presentation/widgets/share_list_sheet.dart:174, apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart:136,179,193]

- [ ] [Review][Patch] After accepting invitation, navigates to `/lists` not `/lists/${invitation.listId}` — Spec: `context.go('/lists/${invitation.listId}')`. Actual: `context.go('/lists')`. The `acceptInvitation()` response includes `listId` but it is not used for navigation. [apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart:78]

- [ ] [Review][Patch] `invitationTrialNote` string missing and not shown in acceptance screen — Spec: show `AppStrings.invitationTrialNote` for non-subscribed users. String not in `strings.dart`; acceptance screen has a TODO comment but no UI for it. [apps/flutter/lib/core/l10n/strings.dart, apps/flutter/lib/features/lists/presentation/accept_invitation_screen.dart]

- [ ] [Review][Patch] `list_members` schema missing unique constraint `(list_id, user_id)` — Spec: "Unique constraint on `(list_id, user_id)`". Neither `list-members.ts` nor `0008_list_sharing.sql` includes this constraint. [packages/core/src/schema/list-members.ts, packages/core/src/schema/migrations/0008_list_sharing.sql]

- [ ] [Review][Patch] `list_invitations` schema missing partial unique constraint `(list_id, invitee_email)` WHERE `status = 'pending'` — Spec requires this constraint (or API-level check with TODO). Neither schema nor migration includes it. [packages/core/src/schema/list-invitations.ts, packages/core/src/schema/migrations/0008_list_sharing.sql]

### Deferred

- [x] [Review][Defer] `SharingRepository.getInvitationDetails` accesses `data['inviterName']` — field name diverges from spec's `invitedByName`. Linked to `invitationDetailsSchema` patch above; resolve both together. [apps/flutter/lib/features/lists/data/sharing_repository.dart:43] — deferred, pre-existing coupling to the schema patch

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
