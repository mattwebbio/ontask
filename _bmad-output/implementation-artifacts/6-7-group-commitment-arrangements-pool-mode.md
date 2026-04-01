# Story 6.7: Group Commitment Arrangements & Pool Mode

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a group member,
I want to enter a shared commitment where everyone has skin in the game,
So that we're all accountable to each other — not just ourselves.

## Acceptance Criteria

1. **Given** a shared list is active
   **When** a member proposes a group commitment
   **Then** each member can set their individual stake amount (FR29)
   **And** all members can review the proposed stakes before activating
   **And** the group commitment activates only when all members have explicitly approved (unanimous approval required)

2. **Given** a group commitment is being set up
   **When** pool mode is offered
   **Then** each member must explicitly opt into pool mode — it is not inherited from group commitment approval (FR30)
   **And** members who opt in understand: any member failing their assigned task results in charges for all members per their individual stakes

3. **Given** a pool mode charge is triggered
   **When** the charge is processed
   **Then** all opted-in members are charged their individual pool stake using the same idempotency and retry mechanics as individual charges (Story 6.5)
   **And** each charge is a separate Stripe operation with its own idempotency key

## Tasks / Subtasks

### Backend: DB schema — new `group_commitments` and `group_commitment_members` tables (AC: 1, 2, 3)

- [x]Create `packages/core/src/schema/group-commitments.ts` (AC: 1, 2, 3)
  - [x]Define `groupCommitmentsTable`:
    ```typescript
    import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'
    import { listsTable } from './lists.js'
    import { tasksTable } from './tasks.js'

    // ── Group commitments table ─────────────────────────────────────────────
    // Represents a shared commitment arrangement across members of a shared list.
    // Activates only when all members have explicitly approved (FR29, Story 6.7).
    export const groupCommitmentsTable = pgTable('group_commitments', {
      id: uuid().primaryKey().defaultRandom(),
      listId: uuid().notNull().references(() => listsTable.id, { onDelete: 'cascade' }),
      taskId: uuid().notNull().references(() => tasksTable.id, { onDelete: 'cascade' }),
      proposedByUserId: uuid().notNull(),   // user who initiated the group commitment proposal
      status: text().notNull().default('pending'), // 'pending' | 'active' | 'cancelled'
      // 'pending'  = awaiting unanimous approval
      // 'active'   = all members approved; charges may be triggered
      // 'cancelled' = proposal withdrawn or list dissolved
      createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
      updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
    })
    ```
  - [x]Export as `groupCommitmentsTable` from the file

- [x]Create `packages/core/src/schema/group-commitment-members.ts` (AC: 1, 2, 3)
  - [x]Define `groupCommitmentMembersTable`:
    ```typescript
    import { pgTable, uuid, text, integer, boolean, timestamp, unique } from 'drizzle-orm/pg-core'
    import { groupCommitmentsTable } from './group-commitments.js'

    // ── Group commitment members table ───────────────────────────────────────
    // Per-member state within a group commitment: individual stake, approval status,
    // and pool mode opt-in (FR29, FR30, Story 6.7).
    export const groupCommitmentMembersTable = pgTable('group_commitment_members', {
      id: uuid().primaryKey().defaultRandom(),
      groupCommitmentId: uuid().notNull().references(() => groupCommitmentsTable.id, { onDelete: 'cascade' }),
      userId: uuid().notNull(),
      stakeAmountCents: integer(),         // nullable; each member sets their own amount
      approved: boolean().notNull().default(false),  // explicit approval for the group commitment
      poolModeOptIn: boolean().notNull().default(false), // explicit opt-in for pool mode (separate from approval)
      // Pool mode: if true, this member is charged if ANY opted-in member fails their task
      createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
      updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
    }, (table) => [
      unique('group_commitment_members_commitment_user_unique').on(
        table.groupCommitmentId, table.userId
      ),
    ])
    ```
  - [x]Export as `groupCommitmentMembersTable` from the file

- [x]Export both new tables from `packages/core/src/schema/index.ts` (AC: 1, 2, 3)
  - [x]Add `export { groupCommitmentsTable } from './group-commitments.js'`
  - [x]Add `export { groupCommitmentMembersTable } from './group-commitment-members.js'`
  - [x]Follow the existing export pattern — one export per line, alphabetically adjacent to related tables

- [x]Generate migration `packages/core/src/schema/migrations/0017_group_commitments.sql` (AC: 1, 2, 3)
  - [x]Run `pnpm drizzle-kit generate` from `apps/api/` (where `drizzle.config.ts` lives — NOT from `packages/core/`)
  - [x]Commit the generated SQL, updated `meta/_journal.json`, and `meta/0017_snapshot.json`
  - [x]Migration must create both `group_commitments` and `group_commitment_members` tables with all constraints

### Backend: API — group commitment endpoints in `commitment-contracts.ts` (AC: 1, 2, 3)

All new routes are added to `apps/api/src/routes/commitment-contracts.ts`. The `commitmentContractsRouter` is already mounted in `apps/api/src/index.ts` — **do NOT modify `index.ts`**.

#### Schema definitions (add after existing schemas, before first route definition)

- [x]Add Zod schemas for group commitment requests and responses:
  ```typescript
  // ── Group commitment schemas ──────────────────────────────────────────────
  const groupCommitmentMemberSchema = z.object({
    userId: z.string().uuid(),
    stakeAmountCents: z.number().int().min(500).nullable(),
    approved: z.boolean(),
    poolModeOptIn: z.boolean(),
  })

  const groupCommitmentSchema = z.object({
    id: z.string().uuid(),
    listId: z.string().uuid(),
    taskId: z.string().uuid(),
    proposedByUserId: z.string().uuid(),
    status: z.enum(['pending', 'active', 'cancelled']),
    members: z.array(groupCommitmentMemberSchema),
    createdAt: z.string().datetime(),
    updatedAt: z.string().datetime(),
  })

  const proposeGroupCommitmentBodySchema = z.object({
    listId: z.string().uuid(),
    taskId: z.string().uuid(),
  })

  const approveGroupCommitmentBodySchema = z.object({
    stakeAmountCents: z.number().int().min(500),
  })

  const poolModeOptInBodySchema = z.object({
    optIn: z.boolean(),
  })
  ```

#### Route: `POST /v1/group-commitments` — propose a group commitment (AC: 1)

- [x]Add `proposeGroupCommitmentRoute` using `createRoute`:
  ```typescript
  const proposeGroupCommitmentRoute = createRoute({
    method: 'post',
    path: '/v1/group-commitments',
    tags: ['GroupCommitments'],
    summary: 'Propose a group commitment for a shared list task',
    description:
      'Creates a group commitment proposal for a task in a shared list. ' +
      'All list members are notified and must approve individually. ' +
      'The commitment activates only when all members have explicitly approved (FR29, Story 6.7).',
    request: {
      body: {
        content: { 'application/json': { schema: proposeGroupCommitmentBodySchema } },
        required: true,
      },
    },
    responses: {
      201: {
        content: { 'application/json': { schema: z.object({ data: groupCommitmentSchema }) } },
        description: 'Group commitment proposal created',
      },
      404: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'List or task not found',
      },
      422: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Task is not in the specified shared list, or list has no members',
      },
    },
  })
  ```
- [x]Add handler stub:
  ```typescript
  app.openapi(proposeGroupCommitmentRoute, async (c) => {
    const body = c.req.valid('json')
    const groupCommitmentId = '00000000-0000-0000-0000-000000000001'
    const now = new Date().toISOString()
    // TODO(impl): verify listId exists and taskId belongs to listId; verify authenticated user is a member
    // TODO(impl): insert into group_commitments (status='pending', proposedByUserId = JWT sub)
    // TODO(impl): insert one group_commitment_members row per list member (approved=false, poolModeOptIn=false)
    // TODO(impl): send notification to all list members (deferred to Story 8.4)
    return c.json(ok({
      id: groupCommitmentId,
      listId: body.listId,
      taskId: body.taskId,
      proposedByUserId: '00000000-0000-0000-0000-000000000099',
      status: 'pending' as const,
      members: [],
      createdAt: now,
      updatedAt: now,
    }), 201)
  })
  ```

#### Route: `GET /v1/group-commitments/:groupCommitmentId` — get group commitment (AC: 1, 2)

- [x]Add `getGroupCommitmentRoute` using `createRoute`:
  ```typescript
  const getGroupCommitmentRoute = createRoute({
    method: 'get',
    path: '/v1/group-commitments/:groupCommitmentId',
    tags: ['GroupCommitments'],
    summary: 'Get group commitment details',
    description:
      'Returns the group commitment with all member stakes, approval statuses, and pool mode opt-ins. ' +
      'Used to show the review screen to each member (FR29, Story 6.7).',
    request: {
      params: z.object({ groupCommitmentId: z.string().uuid() }),
    },
    responses: {
      200: {
        content: { 'application/json': { schema: z.object({ data: groupCommitmentSchema }) } },
        description: 'Group commitment details',
      },
      404: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Group commitment not found',
      },
    },
  })
  ```
- [x]Add handler stub:
  ```typescript
  app.openapi(getGroupCommitmentRoute, async (c) => {
    const { groupCommitmentId } = c.req.valid('param')
    const now = new Date().toISOString()
    // TODO(impl): query group_commitments join group_commitment_members where id = groupCommitmentId
    // TODO(impl): verify authenticated user is a member of the associated list
    return c.json(ok({
      id: groupCommitmentId,
      listId: '00000000-0000-0000-0000-000000000002',
      taskId: '00000000-0000-0000-0000-000000000003',
      proposedByUserId: '00000000-0000-0000-0000-000000000099',
      status: 'pending' as const,
      members: [],
      createdAt: now,
      updatedAt: now,
    }), 200)
  })
  ```

#### Route: `POST /v1/group-commitments/:groupCommitmentId/approve` — member approves (AC: 1)

- [x]Add `approveGroupCommitmentRoute` using `createRoute`:
  ```typescript
  const approveGroupCommitmentRoute = createRoute({
    method: 'post',
    path: '/v1/group-commitments/:groupCommitmentId/approve',
    tags: ['GroupCommitments'],
    summary: 'Approve a group commitment and set individual stake',
    description:
      'The authenticated member approves the group commitment and sets their individual stake amount. ' +
      'When all members have approved, the group commitment status transitions to "active". ' +
      'Approval is separate from pool mode opt-in (FR29, FR30, Story 6.7).',
    request: {
      params: z.object({ groupCommitmentId: z.string().uuid() }),
      body: {
        content: { 'application/json': { schema: approveGroupCommitmentBodySchema } },
        required: true,
      },
    },
    responses: {
      200: {
        content: { 'application/json': { schema: z.object({ data: groupCommitmentSchema }) } },
        description: 'Approval recorded; returns updated group commitment',
      },
      404: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Group commitment not found',
      },
      422: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Commitment is not pending, or member has no payment method',
      },
    },
  })
  ```
- [x]Add handler stub:
  ```typescript
  app.openapi(approveGroupCommitmentRoute, async (c) => {
    const { groupCommitmentId } = c.req.valid('param')
    const body = c.req.valid('json')
    const now = new Date().toISOString()
    // TODO(impl): set group_commitment_members.approved = true, stakeAmountCents = body.stakeAmountCents
    //             WHERE groupCommitmentId AND userId = JWT sub
    // TODO(impl): check if ALL members have approved; if so, set group_commitments.status = 'active'
    //             AND set tasks.stakeAmountCents and tasks.stakeModificationDeadline for each member's task
    // TODO(impl): verify member has a payment method (commitment_contracts row with stripePaymentMethodId set)
    //             If not, return 422 with code 'NO_PAYMENT_METHOD'
    return c.json(ok({
      id: groupCommitmentId,
      listId: '00000000-0000-0000-0000-000000000002',
      taskId: '00000000-0000-0000-0000-000000000003',
      proposedByUserId: '00000000-0000-0000-0000-000000000099',
      status: 'pending' as const,
      members: [{ userId: '00000000-0000-0000-0000-000000000099', stakeAmountCents: body.stakeAmountCents, approved: true, poolModeOptIn: false }],
      createdAt: now,
      updatedAt: now,
    }), 200)
  })
  ```

#### Route: `POST /v1/group-commitments/:groupCommitmentId/pool-mode` — pool mode opt-in (AC: 2)

- [x]Add `poolModeOptInRoute` using `createRoute`:
  ```typescript
  const poolModeOptInRoute = createRoute({
    method: 'post',
    path: '/v1/group-commitments/:groupCommitmentId/pool-mode',
    tags: ['GroupCommitments'],
    summary: 'Opt in or out of pool mode for a group commitment',
    description:
      'Explicitly sets pool mode opt-in for the authenticated member. ' +
      'Pool mode is NOT inherited from group commitment approval — it requires a separate explicit opt-in. ' +
      'Members who opt in understand: any opted-in member failing triggers charges for ALL opted-in members (FR30, Story 6.7).',
    request: {
      params: z.object({ groupCommitmentId: z.string().uuid() }),
      body: {
        content: { 'application/json': { schema: poolModeOptInBodySchema } },
        required: true,
      },
    },
    responses: {
      200: {
        content: { 'application/json': { schema: z.object({ data: z.object({ groupCommitmentId: z.string().uuid(), userId: z.string().uuid(), poolModeOptIn: z.boolean() }) }) } },
        description: 'Pool mode preference recorded',
      },
      404: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Group commitment not found',
      },
      422: {
        content: { 'application/json': { schema: ErrorSchema } },
        description: 'Group commitment is not active (must be approved before opting into pool mode)',
      },
    },
  })
  ```
- [x]Add handler stub:
  ```typescript
  app.openapi(poolModeOptInRoute, async (c) => {
    const { groupCommitmentId } = c.req.valid('param')
    const body = c.req.valid('json')
    // TODO(impl): set group_commitment_members.poolModeOptIn = body.optIn
    //             WHERE groupCommitmentId AND userId = JWT sub
    // TODO(impl): verify group_commitments.status = 'active' (cannot opt in on pending/cancelled)
    return c.json(ok({
      groupCommitmentId,
      userId: '00000000-0000-0000-0000-000000000099',
      poolModeOptIn: body.optIn,
    }), 200)
  })
  ```

#### Error code — `NOT_SHARED_LIST` (AC: 1)

- [x]Add `NotSharedListError` to `apps/api/src/lib/errors.ts`:
  ```typescript
  /** 422 — Task does not belong to a shared list (FR29, Story 6.7) */
  export class NotSharedListError extends AppError {
    constructor(message = 'This task is not in a shared list', details?: Record<string, unknown>) {
      super('NOT_SHARED_LIST', 422, message, details)
    }
  }
  ```
  - Check that `NOT_SHARED_LIST` does not already exist before adding — grep `errors.ts` for it

### Flutter: Domain models (AC: 1, 2)

- [x]Create `apps/flutter/lib/features/commitment_contracts/domain/group_commitment.dart` (AC: 1, 2)
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'group_commitment.freezed.dart';

  /// Represents one member's state within a group commitment.
  @freezed
  abstract class GroupCommitmentMember with _$GroupCommitmentMember {
    const factory GroupCommitmentMember({
      required String userId,
      int? stakeAmountCents,
      @Default(false) bool approved,
      @Default(false) bool poolModeOptIn,
    }) = _GroupCommitmentMember;
  }

  /// Represents a group commitment arrangement for a shared list task (FR29, FR30).
  ///
  /// Status lifecycle: pending → active → (charged or cancelled)
  /// Pool mode is tracked per-member — not inherited from approval.
  @freezed
  abstract class GroupCommitment with _$GroupCommitment {
    const factory GroupCommitment({
      required String id,
      required String listId,
      required String taskId,
      required String proposedByUserId,
      required String status, // 'pending' | 'active' | 'cancelled'
      @Default(<GroupCommitmentMember>[]) List<GroupCommitmentMember> members,
      required DateTime createdAt,
      required DateTime updatedAt,
    }) = _GroupCommitment;

    /// Returns true when all members have explicitly approved.
    bool get isActive => status == 'active';

    /// Returns true when the commitment is awaiting member approvals.
    bool get isPending => status == 'pending';
  }
  ```
  - [x]Run `dart run build_runner build --delete-conflicting-outputs`
  - [x]Commit generated `group_commitment.freezed.dart`

### Flutter: Repository — group commitment methods (AC: 1, 2, 3)

- [x]Add group commitment methods to `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` (AC: 1, 2, 3)

  **Import** the new domain model at the top of the file:
  ```dart
  import '../domain/group_commitment.dart';
  ```

  **Add `proposeGroupCommitment` method:**
  ```dart
  /// Proposes a group commitment for a task in a shared list.
  ///
  /// `POST /v1/group-commitments`
  /// Returns the newly created [GroupCommitment] in 'pending' status.
  Future<GroupCommitment> proposeGroupCommitment({
    required String listId,
    required String taskId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/group-commitments',
      data: {'listId': listId, 'taskId': taskId},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return _groupCommitmentFromJson(data);
  }
  ```

  **Add `getGroupCommitment` method:**
  ```dart
  /// Fetches a group commitment with all member states.
  ///
  /// `GET /v1/group-commitments/:groupCommitmentId`
  Future<GroupCommitment> getGroupCommitment(String groupCommitmentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/group-commitments/$groupCommitmentId',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return _groupCommitmentFromJson(data);
  }
  ```

  **Add `approveGroupCommitment` method:**
  ```dart
  /// Approves the group commitment and sets the member's individual stake.
  ///
  /// `POST /v1/group-commitments/:groupCommitmentId/approve`
  /// Throws [DioException] with 422 if no payment method or commitment not pending.
  Future<GroupCommitment> approveGroupCommitment(
    String groupCommitmentId, {
    required int stakeAmountCents,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/group-commitments/$groupCommitmentId/approve',
      data: {'stakeAmountCents': stakeAmountCents},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return _groupCommitmentFromJson(data);
  }
  ```

  **Add `setPoolModeOptIn` method:**
  ```dart
  /// Sets pool mode opt-in for the authenticated member.
  ///
  /// `POST /v1/group-commitments/:groupCommitmentId/pool-mode`
  /// [optIn] = true to opt in; false to opt out.
  /// Throws [DioException] with 422 if commitment is not active.
  Future<void> setPoolModeOptIn(
    String groupCommitmentId, {
    required bool optIn,
  }) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/v1/group-commitments/$groupCommitmentId/pool-mode',
      data: {'optIn': optIn},
    );
  }
  ```

  **Add `_groupCommitmentFromJson` private helper:**
  ```dart
  GroupCommitment _groupCommitmentFromJson(Map<String, dynamic> data) {
    final membersList = (data['members'] as List? ?? [])
        .map((m) {
          final member = m as Map<String, dynamic>;
          return GroupCommitmentMember(
            userId: member['userId'] as String,
            stakeAmountCents: member['stakeAmountCents'] != null
                ? (member['stakeAmountCents'] as num).toInt()
                : null,
            approved: member['approved'] as bool? ?? false,
            poolModeOptIn: member['poolModeOptIn'] as bool? ?? false,
          );
        })
        .toList();
    return GroupCommitment(
      id: data['id'] as String,
      listId: data['listId'] as String,
      taskId: data['taskId'] as String,
      proposedByUserId: data['proposedByUserId'] as String,
      status: data['status'] as String,
      members: membersList,
      createdAt: DateTime.parse(data['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(data['updatedAt'] as String).toLocal(),
    );
  }
  ```

  - [x]Re-run `dart run build_runner build --delete-conflicting-outputs` — regenerates `commitment_contracts_repository.g.dart`
  - [x]Commit updated `commitment_contracts_repository.g.dart`

### Flutter: Group Commitment Proposal Screen (AC: 1)

- [x]Create `apps/flutter/lib/features/commitment_contracts/presentation/group_commitment_proposal_screen.dart` (AC: 1)
  - [x]`ConsumerStatefulWidget` — receives `listId` and `taskId` as constructor params
  - [x]`_isLoading = true` as default field value (avoids blank first frame)
  - [x]On mount: calls `commitmentContractsRepository.proposeGroupCommitment(listId: listId, taskId: taskId)`
  - [x]On success: navigates to `GroupCommitmentReviewScreen` passing the returned `GroupCommitment`
  - [x]On error: shows `CupertinoAlertDialog` with `AppStrings.groupCommitmentProposeError`
  - [x]Loading state: centered `CupertinoActivityIndicator`
  - [x]Screen background: `OnTaskColors.surfacePrimary`
  - [x]Access colors: `final colors = Theme.of(context).extension<OnTaskColors>()!;`

- [x]Create `apps/flutter/lib/features/commitment_contracts/presentation/group_commitment_review_screen.dart` (AC: 1, 2)
  - [x]`ConsumerStatefulWidget` — receives `GroupCommitment` as constructor param
  - [x]`_isLoading = false` as default (content available immediately from passed commitment)
  - [x]Displays the group commitment: task title area (title displayed from task detail context or passed param), list of members with their approval status
  - [x]For the current user's row: shows a stake amount input (same `StakeSliderWidget` reused from Story 6.2) and an "Approve" `CupertinoButton`
  - [x]"Approve" calls `commitmentContractsRepository.approveGroupCommitment(groupCommitmentId, stakeAmountCents: _stakeAmountCents)`
  - [x]After approval, refreshes the commitment via `getGroupCommitment` to show updated states
  - [x]When `commitment.isActive` (all approved): shows pool mode opt-in section (see below)
  - [x]Background: `OnTaskColors.surfacePrimary`
  - [x]All `CupertinoButton` instances: `minimumSize: const Size(44, 44)`

  **Pool mode opt-in section (shown only when `commitment.isActive`):**
  - [x]Informational copy: `AppStrings.poolModeDescription`
  - [x]`CupertinoSwitch` for pool mode opt-in (not a `CupertinoButton` — it is a toggle)
  - [x]When toggled, calls `commitmentContractsRepository.setPoolModeOptIn(groupCommitmentId, optIn: value)`
  - [x]Shows per-member pool mode status in the member list (opted-in checkmark vs pending)
  - [x]Pool mode opt-in is independent of approval — a member who approved may still decline pool mode
  - [x]On toggle error: shows `CupertinoAlertDialog` with `AppStrings.poolModeOptInError`

### Flutter: l10n strings (AC: 1, 2)

- [x]Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Group commitments & pool mode (FR29, FR30) ──` section:
  ```dart
  // ── Group commitments & pool mode (FR29, FR30) ──────────────────────────────
  static const String groupCommitmentProposalTitle = 'Group commitment';
  static const String groupCommitmentReviewTitle = 'Review commitment';
  static const String groupCommitmentApproveButton = 'Approve & set stake';
  static const String groupCommitmentPendingStatus = 'Pending approval';
  static const String groupCommitmentActiveStatus = 'All approved';
  static const String groupCommitmentMembersApprovedLabel = 'members approved';
  static const String groupCommitmentProposeError =
      'Could not propose group commitment. Please try again.';
  static const String groupCommitmentApproveError =
      'Could not approve commitment. Please try again.';
  static const String poolModeSectionTitle = 'Pool mode';
  static const String poolModeDescription =
      'In pool mode, everyone is charged if any opted-in member misses their task. '
      'This is separate from approving the commitment — opt in only if you\'re sure.';
  static const String poolModeToggleLabel = 'Join pool mode';
  static const String poolModeOptInError =
      'Could not update pool mode preference. Please try again.';
  ```
  - NOTE: `AppStrings.dialogErrorTitle`, `AppStrings.actionOk`, `AppStrings.actionCancel` already exist — do NOT recreate

### Tests — repository (AC: 1, 2, 3)

- [x]Extend `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart` (do NOT create a new test file — extend the existing one)
  - [x]Add group `'CommitmentContractsRepository — group commitments (Story 6.7)'`:
    - [x]Test: `proposeGroupCommitment` fires `POST /v1/group-commitments` with `listId` and `taskId`
      ```dart
      test('proposeGroupCommitment sends POST with correct body', () async {
        // Mock POST /v1/group-commitments returning a stub GroupCommitment
        // Verify returned GroupCommitment.status == 'pending'
        // Verify listId and taskId match
      });
      ```
    - [x]Test: `getGroupCommitment` fires `GET /v1/group-commitments/:id` and maps response
    - [x]Test: `approveGroupCommitment` fires `POST .../approve` with `stakeAmountCents`
    - [x]Test: `setPoolModeOptIn` fires `POST .../pool-mode` with `{'optIn': true}`
    - [x]Test: `_groupCommitmentFromJson` maps `stakeAmountCents` correctly using `(x as num).toInt()` pattern for members
    - [x]Test: `_groupCommitmentFromJson` handles empty members list (returns `GroupCommitment` with `members: []`)
  - [x]Use the same `mocktail` + `MockDio` pattern from Stories 6.1–6.6

### Tests — widget tests (AC: 1, 2)

- [x]Create `apps/flutter/test/features/commitment_contracts/group_commitment_review_screen_test.dart` (new file — this is a new screen)
  - [x]Test: member list renders with approval statuses
    ```dart
    test('shows member rows with pending approval status', () async {
      // Provide GroupCommitment with status='pending', members with approved=false
      // Verify AppStrings.groupCommitmentPendingStatus text present
    });
    ```
  - [x]Test: "Approve & set stake" button calls `approveGroupCommitment`
  - [x]Test: pool mode section is hidden when `commitment.status == 'pending'`
  - [x]Test: pool mode section is shown when `commitment.status == 'active'`
  - [x]Test: toggling `CupertinoSwitch` calls `setPoolModeOptIn(groupCommitmentId, optIn: true)`
  - [x]Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension (established pattern)
  - [x]Override `commitmentContractsRepositoryProvider` using the same `ProviderContainer` pattern as existing tests in `stake_sheet_screen_test.dart`

## Dev Notes

### CRITICAL: Migration number is `0017`

Last migration was `0016_stake_modification_deadline.sql` (Story 6.6). Next is `0017_group_commitments.sql`. Always run `pnpm drizzle-kit generate` from `apps/api/` (NOT `packages/core/`) — the `drizzle.config.ts` lives in `apps/api/`.

### CRITICAL: Two new schema files, not one

Both `group_commitments` and `group_commitment_members` tables are new. Each gets its own `.ts` file under `packages/core/src/schema/`, following the naming convention of all existing schema files (e.g., `charge-events.ts`, `list-members.ts`). Both must be exported from `packages/core/src/schema/index.ts`.

### CRITICAL: Pool mode opt-in is SEPARATE from group commitment approval

The epics AC is explicit: "each member must explicitly opt into pool mode — it is not inherited from group commitment approval." The `approved` and `poolModeOptIn` fields in `group_commitment_members` are separate booleans. A member can approve the group commitment (setting `approved = true`) but decline pool mode (keeping `poolModeOptIn = false`). The UI must present these as two distinct actions with separate confirmation. Do NOT conflate them.

### CRITICAL: Unanimous approval required before pool mode is offered

Pool mode opt-in can only be set AFTER the group commitment transitions to `'active'` (all members approved). The `POST .../pool-mode` endpoint returns 422 if the commitment is not yet active. The Flutter UI guards this by only showing the pool mode section when `commitment.isActive`.

### CRITICAL: Pool mode charges reuse Story 6.5 idempotency mechanics

Per AC 3: pool mode charges use "the same idempotency and retry mechanics as individual charges (Story 6.5)" with "each charge is a separate Stripe operation with its own idempotency key." The idempotency key pattern for pool charges should be: `pool-{groupCommitmentId}-{userId}` (distinct from the individual charge key `charge-{taskId}-{userId}`). The charge-trigger consumer (Story 6.5) will need a separate queue message type for pool charges in future implementation, but the stub endpoints in this story lay the data foundation.

### CRITICAL: `commitmentContractsRouter` already mounted — no `index.ts` change needed

`apps/api/src/index.ts` already mounts `commitmentContractsRouter` at line 73. All new group commitment routes added to `commitment-contracts.ts` automatically register. Do NOT modify `index.ts`.

### CRITICAL: TypeScript imports use `.js` extensions

All local imports in `apps/api/` must use `.js` extensions:
```typescript
import { ok, err } from '../lib/response.js'
```
No new import files are needed for this story — all routes remain in `commitment-contracts.ts`.

### CRITICAL: All routes use `createRoute` pattern with `@hono/zod-openapi`

Every new route must use `createRoute({ method: '...', path: '...', ... })` and `app.openapi(...)`. No untyped Hono routes. Follow the exact pattern used for `cancelStakeRoute` in `commitment-contracts.ts`.

### CRITICAL: `(x as num).toInt()` for JSON numeric fields

When parsing `stakeAmountCents` from API JSON in the repository's `_groupCommitmentFromJson` helper, always cast: `(member['stakeAmountCents'] as num).toInt()`. Do not assume the JSON field is already typed as `int`.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

After changes to the new `GroupCommitment` model and `CommitmentContractsRepository`:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Commit ALL generated files. No `build_runner` in CI.

Files needing regeneration in this story:
- `group_commitment.freezed.dart` — new Freezed model
- `commitment_contracts_repository.g.dart` — updated (new group commitment methods added to `@riverpod` class)

### CRITICAL: `OnTaskColors.surfacePrimary` for backgrounds

Use `colors.surfacePrimary` for screen and sheet backgrounds. `backgroundPrimary` does not exist.
Access: `final colors = Theme.of(context).extension<OnTaskColors>()!;`

### CRITICAL: `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances

Every `CupertinoButton` added in new screens must include `minimumSize: const Size(44, 44)`. The "Approve & set stake" button and any other `CupertinoButton` instances in the new screens require this.

### CRITICAL: `catch (e)` not `catch (_)` in all error handlers

All catch blocks must use `catch (e)` — never `catch (_)`. Enforced consistently across Stories 6.1–6.6.

### CRITICAL: All UI strings in `AppStrings`

Every user-facing string must reference an `AppStrings` constant. Do NOT hardcode any copy inline in the widget tree. New strings are added under the `// ── Group commitments & pool mode ──` section.

### CRITICAL: Widget tests — wrap in `MaterialApp` with `OnTaskTheme`

All widget tests for new group commitment screens must be wrapped:
```dart
await tester.pumpWidget(
  MaterialApp(
    theme: OnTaskTheme.light(),
    home: ...,
  ),
);
```

### CRITICAL: Repository tests extend existing `commitment_contracts_repository_test.dart`

Do NOT create a new repository test file. Add new groups to the existing file. This pattern is established in Stories 6.2–6.6.

### Architecture: Group commitment status lifecycle

```
pending  →  active   (when all group_commitment_members.approved = true)
pending  →  cancelled (if proposal withdrawn; not in scope for Story 6.7 — deferred)
active   →  (charges processed by charge scheduler for failed tasks; Story 6.5 extension)
```

The stub endpoints in this story do NOT implement the real DB transitions. They provide the correct response shapes and `TODO(impl)` documentation so the dev team has the full contract.

### Architecture: Relationship between `group_commitments` and individual `tasks.stakeAmountCents`

When a group commitment becomes active (all members approved), each member's `stakeAmountCents` should be written to `tasks.stakeAmountCents` for their individual task row. This mirrors how individual stakes work (Story 6.2). The `TODO(impl)` comment in `approveGroupCommitmentRoute` documents this. The existing `stakeAmountCents` column in `tasks` is reused — no new column required.

### Architecture: Pool mode charge trigger (future implementation guidance)

When pool mode is active and any opted-in member's task deadline passes without verified completion:
- The charge scheduler (Story 6.5, `charge-scheduler.ts`) must be extended to query `group_commitment_members WHERE poolModeOptIn = true` for the relevant `groupCommitmentId`
- Each opted-in member receives a separate charge (separate Stripe PaymentIntent with idempotency key `pool-{groupCommitmentId}-{userId}`)
- This is NOT implemented in this story — it is documented here as future implementation context
- The `charge_events` table (Story 6.5) already supports the required fields; no new schema columns needed

### Architecture: Existing routes in `commitment-contracts.ts` (do NOT modify)

The following routes are already registered and must NOT be changed:
- `GET /v1/payment-method`
- `POST /v1/payment-method/setup-session`
- `POST /v1/payment-method/confirm`
- `DELETE /v1/payment-method`
- `GET /v1/tasks/:taskId/stake`
- `PUT /v1/tasks/:taskId/stake`
- `DELETE /v1/tasks/:taskId/stake`
- `POST /v1/tasks/:taskId/stake/cancel`
- `GET /v1/charities`
- `GET /v1/commitment-contracts/charity`
- `POST /v1/commitment-contracts/charity`
- `GET /v1/impact`

New routes to add: `POST /v1/group-commitments`, `GET /v1/group-commitments/:id`, `POST /v1/group-commitments/:id/approve`, `POST /v1/group-commitments/:id/pool-mode`

### Architecture: `SharingRepository` provides member data — do NOT duplicate in `CommitmentContractsRepository`

`apps/flutter/lib/features/lists/data/sharing_repository.dart` already has `getListMembers(String listId)` which returns `List<ListMember>`. The `GroupCommitmentReviewScreen` should fetch the member list via `sharingRepository.getListMembers(listId)` to display member display names and avatars alongside approval status. Do NOT re-implement member fetching in `CommitmentContractsRepository`. The `ListMember` domain model lives at `apps/flutter/lib/features/lists/domain/list_member.dart`.

### Architecture: File locations

New files to create:
```
packages/core/src/schema/group-commitments.ts
packages/core/src/schema/group-commitment-members.ts
packages/core/src/schema/migrations/0017_group_commitments.sql        — generated by drizzle-kit
packages/core/src/schema/migrations/meta/_journal.json                — updated by drizzle-kit
packages/core/src/schema/migrations/meta/0017_snapshot.json           — generated by drizzle-kit
apps/flutter/lib/features/commitment_contracts/domain/group_commitment.dart
apps/flutter/lib/features/commitment_contracts/domain/group_commitment.freezed.dart  — generated
apps/flutter/lib/features/commitment_contracts/presentation/group_commitment_proposal_screen.dart
apps/flutter/lib/features/commitment_contracts/presentation/group_commitment_review_screen.dart
apps/flutter/test/features/commitment_contracts/group_commitment_review_screen_test.dart
```

Modified files:
```
packages/core/src/schema/index.ts                                      — export new tables
apps/api/src/routes/commitment-contracts.ts                            — add 4 new routes + schemas
apps/api/src/lib/errors.ts                                             — add NotSharedListError
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart  — add 4 methods + helper
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart  — regenerated
apps/flutter/lib/core/l10n/strings.dart                               — new group commitment strings
apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart  — extend
```

### UX: Review screen layout

The `GroupCommitmentReviewScreen` shows:
1. Task title and list name at the top
2. Member list: each row shows avatar initials (from `SharingRepository.getListMembers`), display name, their stake amount (or "Not set" if null), and approval checkmark
3. Current user's row has the `StakeSliderWidget` inline (same widget from Story 6.2 — do NOT recreate) and "Approve & set stake" `CupertinoButton`
4. Below the member list: pool mode section (only when `commitment.isActive`)
5. Background: `OnTaskColors.surfacePrimary`

### UX: Pool mode disclosure requirement

The AC is explicit: "Members who opt in understand: any member failing their assigned task results in charges for all members per their individual stakes." The `AppStrings.poolModeDescription` string captures this disclosure. Display it prominently BEFORE the `CupertinoSwitch` toggle — not after.

### Deferred items (not in scope for Story 6.7)

- Group commitment cancellation/withdrawal — no cancel endpoint in this story
- Notification delivery to members (referred to in `TODO(impl)` comments — deferred to Story 8.4)
- Real DB implementation of all stubs — `TODO(impl)` markers throughout
- Integration with charge scheduler for pool mode charges — documented in Dev Notes above; implemented when Story 6.5 is fully wired
- GoRouter route registration for `GroupCommitmentReviewScreen` — can be accessed programmatically from calling context; full deep-link routing deferred

### Previous story learnings carried forward (Stories 6.1–6.6)

- TypeScript imports use `.js` extensions
- `drizzle-kit generate` runs from `apps/api/` (not `packages/core/`)
- Generated `.freezed.dart` and `.g.dart` files must be committed
- Use `catch (e)` not `catch (_)` in all error handlers
- `OnTaskColors.surfacePrimary` for backgrounds
- `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances
- All UI strings in `AppStrings`
- Widget tests: wrap in `MaterialApp` with `OnTaskTheme`
- Repository tests extend existing `commitment_contracts_repository_test.dart`
- All routes use `createRoute` pattern with `@hono/zod-openapi`
- `commitmentContractsRouter` already mounted — no `index.ts` change needed
- `_isLoading = true` as default value to avoid blank first frame
- `(x as num).toInt()` for JSON numeric fields
- `intl` package available for date formatting (added Story 6.6)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Implemented two new DB schema files: `group-commitments.ts` and `group-commitment-members.ts` following existing schema patterns.
- Exported both from `packages/core/src/schema/index.ts`.
- Generated migration `0017_unique_nighthawk.sql` (drizzle-kit auto-names; creates both tables with all constraints and FK references).
- Added 4 new OpenAPI routes to `commitment-contracts.ts`: POST /v1/group-commitments, GET /v1/group-commitments/:id, POST .../approve, POST .../pool-mode.
- All routes use `createRoute` + `app.openapi` pattern with stub handlers and TODO(impl) comments.
- Added `NotSharedListError` (NOT_SHARED_LIST, 422) to `errors.ts`.
- Created Flutter `GroupCommitment` + `GroupCommitmentMember` Freezed models with `isActive`/`isPending` computed getters.
- Added 4 repository methods + `_groupCommitmentFromJson` helper to `CommitmentContractsRepository`. Uses `(x as num).toInt()` for stakeAmountCents.
- Ran `build_runner build --delete-conflicting-outputs` — generated `group_commitment.freezed.dart` and updated `commitment_contracts_repository.g.dart`.
- Created `GroupCommitmentProposalScreen` (auto-proposes on mount, navigates to review on success).
- Created `GroupCommitmentReviewScreen` with stake slider for approval, pool mode section shown only when `commitment.isActive`, CupertinoSwitch for pool mode toggle.
- Pool mode disclosure rendered BEFORE toggle per UX spec.
- Added group commitment & pool mode strings section to `AppStrings`.
- All widget tests wrapped in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')`.
- Extended `commitment_contracts_repository_test.dart` with 6 new tests (did not create a new file).
- Created `group_commitment_review_screen_test.dart` with 5 widget tests.
- All 186 API tests pass; all 738 Flutter tests pass; no regressions.

### File List

packages/core/src/schema/group-commitments.ts
packages/core/src/schema/group-commitment-members.ts
packages/core/src/schema/index.ts
packages/core/src/schema/migrations/0017_unique_nighthawk.sql
packages/core/src/schema/migrations/meta/_journal.json
packages/core/src/schema/migrations/meta/0017_snapshot.json
apps/api/src/routes/commitment-contracts.ts
apps/api/src/lib/errors.ts
apps/flutter/lib/features/commitment_contracts/domain/group_commitment.dart
apps/flutter/lib/features/commitment_contracts/domain/group_commitment.freezed.dart
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart
apps/flutter/lib/features/commitment_contracts/presentation/group_commitment_proposal_screen.dart
apps/flutter/lib/features/commitment_contracts/presentation/group_commitment_review_screen.dart
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart
apps/flutter/test/features/commitment_contracts/group_commitment_review_screen_test.dart

## Change Log

- 2026-04-01: Story 6.7 implemented — group commitment DB schema, API stub routes, Flutter domain model, repository methods, proposal/review screens, l10n strings, repository tests, and widget tests. All 186 API tests and 738 Flutter tests pass.
