# Story 6.6: Stake Modification & Cancellation

Status: review

## Story

As a user,
I want to be able to cancel or reduce my stake before the deadline window closes,
So that I have a safety valve for genuine changes in circumstance — not procrastination.

## Acceptance Criteria

1. **Given** a task has an active stake
   **When** the user views the task
   **Then** the modification window deadline is displayed: "You can adjust or cancel this stake until [datetime]"

2. **Given** the modification window is open
   **When** the user cancels or reduces the stake
   **Then** the financial commitment is removed or reduced and no charge will occur for the cancelled amount (FR63)
   **And** the task remains in the task list as a normal (unstaked) task

3. **Given** the modification window has closed (within the pre-deadline period)
   **When** the user tries to modify the stake
   **Then** the modification controls are disabled and a clear message explains why: "This stake is locked — the deadline is too close to change it"

## Tasks / Subtasks

### Backend: DB schema — add `stakeModificationDeadline` column to `tasks` table (AC: 1, 2, 3)

- [x] Modify `packages/core/src/schema/tasks.ts` (AC: 1, 2, 3)
  - [x] Add column: `stakeModificationDeadline: timestamp({ withTimezone: true })` — nullable; set when a stake is locked in; null means no stake or modification not yet computed
  - [x] Place after `stakeAmountCents` and before `completedAt` — follow existing column ordering
  - [x] Use `timestamp({ withTimezone: true })` — consistent with all other timestamp columns in this schema
  - [x] No `.notNull()` — only set when a stake is active
  - [x] Comment: `// nullable; set to (dueDate - 24h) when stake is locked; null means unstaked (FR63, Story 6.6)`

- [x] Generate migration `packages/core/src/schema/migrations/0016_stake_modification_deadline.sql` (AC: 1, 2, 3)
  - [x] Run `pnpm drizzle-kit generate` from `apps/api/` (where `drizzle.config.ts` lives — NOT `packages/core/`)
  - [x] Commit generated SQL, updated `meta/_journal.json`, and `meta/0016_snapshot.json`
  - [x] Migration: `ALTER TABLE tasks ADD COLUMN stake_modification_deadline timestamptz;`

### Backend: API — stake status endpoint (AC: 1, 3)

- [x] Update `stakeResponseSchema` in `apps/api/src/routes/commitment-contracts.ts` (AC: 1, 3)
  - [x] Extend `stakeResponseSchema` to include modification window info:
    ```typescript
    const stakeResponseSchema = z.object({
      taskId: z.string().uuid(),
      stakeAmountCents: z.number().int().nullable(),
      stakeModificationDeadline: z.string().datetime().nullable(), // ISO 8601 UTC; null when no stake
      canModify: z.boolean(),   // true when stake exists AND now < stakeModificationDeadline
    })
    ```
  - [x] This extends the schema added in Story 6.2 — DO NOT create a new schema; modify the existing one

- [x] Update `GET /v1/tasks/:taskId/stake` stub (AC: 1, 3)
  - [x] Change stub response to reflect new fields:
    ```typescript
    return c.json(ok({
      taskId,
      stakeAmountCents: null,
      stakeModificationDeadline: null,
      canModify: false,
    }), 200)
    ```
  - [x] Update `TODO(impl)` comment: `// TODO(impl): query tasks table for stakeAmountCents, stakeModificationDeadline where id = taskId AND userId = JWT sub; compute canModify = stakeAmountCents != null && new Date() < new Date(stakeModificationDeadline)`

- [x] Update `PUT /v1/tasks/:taskId/stake` stub (AC: 1, 2)
  - [x] Change stub response to include the new fields:
    ```typescript
    // Compute modification deadline: dueDate - 24h (caller must provide dueDate or API computes from task)
    return c.json(ok({
      taskId: body.taskId,
      stakeAmountCents: body.stakeAmountCents,
      stakeModificationDeadline: null,  // TODO(impl): set to task.dueDate - 24h; persist to tasks table
      canModify: true,
    }), 200)
    ```
  - [x] Add `TODO(impl): after upserting stakeAmountCents, set tasks.stakeModificationDeadline = task.dueDate - 24h`

- [x] Add `POST /v1/tasks/:taskId/stake/cancel` endpoint (AC: 2, 3)
  - [x] Use `createRoute` pattern with `@hono/zod-openapi`
  - [x] Route definition:
    ```typescript
    const cancelStakeRoute = createRoute({
      method: 'post',
      path: '/v1/tasks/:taskId/stake/cancel',
      tags: ['Stake'],
      summary: 'Cancel the stake on a task',
      description:
        'Cancels the stake on the given task if the modification window is open. ' +
        'Returns 422 STAKE_LOCKED if the modification window has closed. ' +
        'Returns 422 NO_ACTIVE_STAKE if no stake is set.',
      request: {
        params: z.object({ taskId: z.string().uuid() }),
      },
      responses: {
        200: {
          content: { 'application/json': { schema: z.object({ data: z.object({ cancelled: z.boolean() }) }) } },
          description: 'Stake cancelled successfully',
        },
        422: {
          content: { 'application/json': { schema: errorSchema } },
          description: 'Stake locked or no active stake',
        },
      },
    })
    ```
  - [x] Handler stub:
    ```typescript
    app.openapi(cancelStakeRoute, async (c) => {
      const { taskId } = c.req.valid('param')
      // TODO(impl): check tasks.stakeAmountCents != null for taskId+userId; if null return 422 NO_ACTIVE_STAKE
      // TODO(impl): check tasks.stakeModificationDeadline; if now >= stakeModificationDeadline return 422 STAKE_LOCKED
      // TODO(impl): set tasks.stakeAmountCents = null AND tasks.stakeModificationDeadline = null
      // TODO(impl): recheck commitment_contracts.hasActiveStakes across all tasks for userId
      // TODO(impl): if a charge_events row exists with status='pending' for this task, cancel/ignore it (check for active charges before clearing)
      return c.json(ok({ cancelled: true }), 200)
    })
    ```
  - [x] Tag: `'Stake'`
  - [x] Register AFTER the existing `DELETE /v1/tasks/:taskId/stake` route — maintain ordering: GET, PUT, DELETE, POST .../cancel
  - [x] **IMPORTANT**: This is a new endpoint separate from `DELETE /v1/tasks/:taskId/stake`. The cancel endpoint enforces the modification window; the DELETE endpoint (Story 6.2) was unrestricted. Going forward, the UI should use this cancel endpoint for user-initiated cancellations with window enforcement.
  - [x] Add `422` error codes to the existing `AppErrorCode` definitions if `STAKE_LOCKED` and `NO_ACTIVE_STAKE` are not already defined

- [x] Verify `STAKE_LOCKED` and `NO_ACTIVE_STAKE` error codes exist (AC: 2, 3)
  - [x] Check `apps/api/src/lib/errors.ts` (or wherever `AppErrorCode` is defined) for `STAKE_LOCKED` and `NO_ACTIVE_STAKE`
  - [x] If missing, add them following the existing pattern used for `NO_PAYMENT_METHOD`

### Backend: Charge safety — prevent charge for cancelled/window-open stakes (AC: 2)

- [x] Update `apps/api/src/lib/charge-scheduler.ts` `TODO(impl)` comment (AC: 2)
  - [x] The existing `triggerOverdueCharges` stub already has a `TODO(impl)`. Add a note to the comment:
    ```typescript
    // TODO(impl): implement DB query and queue dispatch
    // CRITICAL: when querying tasks for overdue charges, EXCLUDE tasks where
    // stakeModificationDeadline IS NULL (stake was cancelled or never set) OR
    // stakeAmountCents IS NULL. Only charge if stakeAmountCents IS NOT NULL.
    // The cancel endpoint sets stakeAmountCents = null, preventing spurious charges.
    ```
  - [x] No actual logic change needed here — the NULL check on `stakeAmountCents` already prevents charging cancelled stakes. This comment documents the contract.

### Flutter: Domain model — extend `TaskStake` (AC: 1, 2, 3)

- [x] Modify `apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart` (AC: 1, 2, 3)
  - [x] Add fields to `TaskStake` Freezed model:
    ```dart
    @freezed
    abstract class TaskStake with _$TaskStake {
      const factory TaskStake({
        required String taskId,
        int? stakeAmountCents,           // null = no stake
        DateTime? stakeModificationDeadline, // null when no stake or not yet computed
        @Default(false) bool canModify,  // true when window is open
      }) = _TaskStake;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit regenerated `task_stake.freezed.dart`

- [x] Update `CommitmentContractsRepository.getTaskStake` parse logic (AC: 1, 2, 3)
  - [x] In `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`:
    ```dart
    Future<TaskStake> getTaskStake(String taskId) async {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/v1/tasks/$taskId/stake',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      final deadlineStr = data['stakeModificationDeadline'] as String?;
      return TaskStake(
        taskId: data['taskId'] as String,
        stakeAmountCents: data['stakeAmountCents'] as int?,
        stakeModificationDeadline:
            deadlineStr != null ? DateTime.parse(deadlineStr).toLocal() : null,
        canModify: data['canModify'] as bool? ?? false,
      );
    }
    ```
  - [x] Update `setTaskStake` parse to also read the new fields (same pattern)
  - [x] Add `cancelStake` method:
    ```dart
    /// Cancels the active stake on a task if the modification window is open.
    ///
    /// `POST /v1/tasks/:taskId/stake/cancel`
    /// Throws [DioException] with status 422 if stake is locked or no stake set.
    Future<void> cancelStake(String taskId) async {
      await _client.dio.post<Map<String, dynamic>>(
        '/v1/tasks/$taskId/stake/cancel',
        data: <String, dynamic>{},
      );
    }
    ```
  - [x] Re-run `dart run build_runner build --delete-conflicting-outputs` — regenerates `commitment_contracts_repository.g.dart`
  - [x] Commit updated `commitment_contracts_repository.g.dart`

### Flutter: `StakeSheetScreen` — modification window UI (AC: 1, 2, 3)

- [x] Modify `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart` (AC: 1, 2, 3)

  **Load modification window state on init:**
  - [x] In `initState`, extend to also load modification window info when `existingStakeAmountCents != null`:
    ```dart
    @override
    void initState() {
      super.initState();
      _stakeAmountCents = widget.existingStakeAmountCents;
      _checkPaymentMethod();
      _loadDefaultCharity();
      if (widget.existingStakeAmountCents != null) {
        _loadModificationWindow();
      }
    }
    ```
  - [x] Add `DateTime? _modificationDeadline` and `bool _canModify = false` state fields
  - [x] Add `_loadModificationWindow()` method:
    ```dart
    Future<void> _loadModificationWindow() async {
      try {
        final repository = ref.read(commitmentContractsRepositoryProvider);
        final stake = await repository.getTaskStake(widget.taskId);
        if (!mounted) return;
        setState(() {
          _modificationDeadline = stake.stakeModificationDeadline;
          _canModify = stake.canModify;
        });
      } catch (e) {
        // Safe fallback: treat as locked on error — prevents accidental modification
        if (mounted) setState(() => _canModify = false);
      }
    }
    ```

  **Display modification window deadline (AC: 1):**
  - [x] When `existingStakeAmountCents != null` AND `_modificationDeadline != null`, show informational text above the slider:
    - Copy: `AppStrings.stakeModificationWindowLabel` (formatted with deadline datetime)
    - Font: 13pt Regular, `colors.textSecondary`
    - Example rendered: "You can adjust or cancel this stake until Apr 2 at 3:00 PM"
    - Use `_formatModificationDeadline(DateTime dt)` helper method:
      ```dart
      String _formatModificationDeadline(DateTime dt) {
        // Format: "Apr 2 at 3:00 PM" — use intl package DateFormat
        // Import: import 'package:intl/intl.dart';
        final datePart = DateFormat('MMM d').format(dt);
        final timePart = DateFormat('h:mm a').format(dt);
        return '${AppStrings.stakeModificationWindowPrefix} $datePart ${AppStrings.stakeModificationWindowAt} $timePart';
      }
      ```

  **Locked state UI (AC: 3):**
  - [x] When `existingStakeAmountCents != null` AND `!_canModify`:
    - Show `StakeSliderWidget` in a visually disabled state (wrap in `IgnorePointer(ignoring: true, ...)` + `Opacity(opacity: 0.5, ...)`)
    - Show locked message below: `AppStrings.stakeLockedMessage`
    - Hide "Lock it in." confirm button
    - Show "Remove stake" button as disabled (grayed out, `onPressed: null`)
    - Do NOT call `repository.cancelStake` when locked

  **Cancel flow using new endpoint (AC: 2, 3):**
  - [x] Replace the existing "Remove stake" button logic to use `repository.cancelStake(taskId)` instead of `repository.removeTaskStake(taskId)`:
    ```dart
    Future<void> _handleCancelStake() async {
      if (!_canModify) return; // Guard: should not be reachable if UI is correct
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(AppStrings.stakeRemoveConfirmTitle),
          content: Text(AppStrings.stakeRemoveConfirmMessage),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.actionCancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.actionDelete),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _isLoading = true);
      try {
        final repository = ref.read(commitmentContractsRepositoryProvider);
        await repository.cancelStake(widget.taskId);
        if (mounted) Navigator.pop(context, null);
      } on DioException catch (e) {
        if (!mounted) return;
        final errorCode = e.response?.data?['error']?['code'] as String?;
        final message = errorCode == 'STAKE_LOCKED'
            ? AppStrings.stakeLockedError
            : AppStrings.stakeCancelError;
        await showCupertinoDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(AppStrings.dialogErrorTitle),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.actionOk),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        await showCupertinoDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(AppStrings.dialogErrorTitle),
            content: Text(AppStrings.stakeCancelError),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.actionOk),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
    ```
  - [x] Use `catch (e)` not `catch (_)` in ALL catch blocks (established pattern)
  - [x] Background: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

### Flutter: l10n strings (AC: 1, 2, 3)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Stake modification & cancellation (FR63) ──` section:
  ```dart
  // ── Stake modification & cancellation (FR63) ──────────────────────────────
  /// Prefix for the modification window label. Full text rendered as:
  /// "You can adjust or cancel this stake until Apr 2 at 3:00 PM"
  static const String stakeModificationWindowPrefix =
      'You can adjust or cancel this stake until';
  static const String stakeModificationWindowAt = 'at';
  static const String stakeLockedMessage =
      "This stake is locked — the deadline is too close to change it";
  static const String stakeLockedError =
      'This stake is locked and can no longer be modified.';
  static const String stakeCancelError =
      'Could not cancel stake. Please try again.';
  ```
  - NOTE: `AppStrings.stakeRemoveConfirmTitle`, `AppStrings.stakeRemoveConfirmMessage`, `AppStrings.dialogErrorTitle`, `AppStrings.actionCancel`, `AppStrings.actionDelete`, `AppStrings.actionOk` already exist — do NOT recreate

### Tests — repository (AC: 1, 2, 3)

- [x] Extend `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart` (do NOT create a new test file)
  - [x] Add group `'CommitmentContractsRepository.getTaskStake with modification window (Story 6.6)'`:
    - [x] Test: `getTaskStake` maps `stakeModificationDeadline` as `DateTime` when present
      ```dart
      test('maps stakeModificationDeadline as DateTime when stake is active', () async {
        // Mock GET /v1/tasks/task-id/stake returning deadline ISO string
        // Verify TaskStake.stakeModificationDeadline is not null
        // Verify canModify == true
      });
      ```
    - [x] Test: `getTaskStake` sets `canModify = false` and `stakeModificationDeadline = null` when no stake
    - [x] Test: `getTaskStake` sets `canModify = false` when deadline is in the past (window closed)
  - [x] Add group `'CommitmentContractsRepository.cancelStake (Story 6.6)'`:
    - [x] Test: `cancelStake('task-id')` fires `POST /v1/tasks/task-id/stake/cancel` with empty body
    - [x] Test: `cancelStake` propagates `DioException` with 422 `STAKE_LOCKED` when window closed
    - [x] Test: `cancelStake` propagates `DioException` with 422 `NO_ACTIVE_STAKE` when no stake
  - [x] Use same `mocktail` + `MockDio` pattern from Stories 6.1–6.5

### Tests — widget tests for `StakeSheetScreen` modification window (AC: 1, 2, 3)

- [x] Extend `apps/flutter/test/features/commitment_contracts/stake_sheet_screen_test.dart` (do NOT create a new test file)
  - [x] Add group `'StakeSheetScreen — modification window (Story 6.6)'`:
    - [x] Test: modification deadline label renders when stake is active and window is open
      ```dart
      test('shows modification window label when canModify is true', () async {
        // Provide mock getTaskStake returning TaskStake with canModify=true, stakeModificationDeadline set
        // Open StakeSheetScreen with existingStakeAmountCents = 2500
        // Verify text containing 'You can adjust or cancel this stake until' is present
      });
      ```
    - [x] Test: slider and "Remove stake" button are disabled when `canModify == false`
      ```dart
      test('disables controls when modification window is closed', () async {
        // Provide mock returning canModify=false
        // Verify IgnorePointer / Opacity wrapping slider
        // Verify locked message AppStrings.stakeLockedMessage is present
        // Verify 'Remove stake' CupertinoButton has onPressed == null
      });
      ```
    - [x] Test: locked message `AppStrings.stakeLockedMessage` is shown when `canModify == false`
    - [x] Test: locked message absent when `canModify == true`
  - [x] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension (established pattern)
  - [x] Override `commitmentContractsRepositoryProvider` using same `ProviderContainer` pattern as existing tests

## Dev Notes

### CRITICAL: Migration number is `0016`

Last migration was `0015_charge_events.sql` (Story 6.5). Next is `0016_stake_modification_deadline.sql`. Run `pnpm drizzle-kit generate` from `apps/api/` (not `packages/core/`) — the `drizzle.config.ts` lives in `apps/api/`.

### CRITICAL: Modification window = 24 hours before deadline

The "pre-deadline window" is **24 hours before the task's due date**. This is derived from UX spec line 767: "Activates automatically when a staked task deadline is within a configurable window (default: 24h)." For Story 6.6:

```
stakeModificationDeadline = task.dueDate - 24 hours
```

When `now >= stakeModificationDeadline`, the window is closed (`canModify = false`). The API computes this server-side and returns `canModify` as a boolean. The Flutter client trusts the server — it does NOT recompute the window client-side.

### CRITICAL: Check `charge_events` before cancelling stake

When `cancelStake` is eventually wired to the real DB (replacing `TODO(impl)`), the implementation MUST check if a `charge_events` row exists for this task with `status IN ('pending', 'charged', 'disbursed', 'disbursement_failed')`. A pending charge event means the charge scheduler has already queued this task. The cancel flow should:
1. If `status = 'pending'` — this is safe to cancel; set `stakeAmountCents = null`; the charge-trigger consumer will idempotency-check and find no stake
2. If `status = 'charged'` or `'disbursed'` or `'disbursement_failed'` — the charge has already been processed; cancellation is not possible at this stage; return 422 `STAKE_LOCKED`

The stub returns `cancelled: true` unconditionally — this is correct stub behavior for Story 6.6.

### CRITICAL: New `POST /v1/tasks/:taskId/stake/cancel` vs existing `DELETE /v1/tasks/:taskId/stake`

Story 6.2 added `DELETE /v1/tasks/:taskId/stake` as an unrestricted endpoint (no window enforcement). Story 6.6 adds the enforced `POST .../cancel` endpoint. Both endpoints coexist:
- `DELETE /v1/tasks/:taskId/stake` — unrestricted removal (used by internal/admin flows; not surfaced to user after Story 6.6)
- `POST /v1/tasks/:taskId/stake/cancel` — user-initiated cancellation with window enforcement

The Flutter UI switches from calling the DELETE endpoint to calling the POST cancel endpoint for the user-facing "Remove stake" button.

### CRITICAL: `stakeResponseSchema` already exists in `commitment-contracts.ts` — extend it, do NOT duplicate

The `stakeResponseSchema` was created in Story 6.2:
```typescript
const stakeResponseSchema = z.object({
  taskId: z.string().uuid(),
  stakeAmountCents: z.number().int().nullable(),
})
```
Add the two new fields to this existing schema — do not create `stakeResponseSchemaV2` or similar.

### CRITICAL: TypeScript imports use `.js` extensions

```typescript
import { ok, err } from '../lib/response.js'
```

All local imports in `apps/api/` must use `.js` extensions. The new cancel route lives in the same `commitment-contracts.ts` file — no import needed for the route handler itself.

### CRITICAL: All routes use `createRoute` pattern with `@hono/zod-openapi`

The new `POST /v1/tasks/:taskId/stake/cancel` route must use `createRoute({ method: 'post', path: ..., ... })`. No untyped Hono routes. Follow the existing pattern in `commitment-contracts.ts`.

### CRITICAL: `commitmentContractsRouter` already mounted — no `index.ts` change needed

The `commitmentContractsRouter` is already mounted in `apps/api/src/index.ts`. New routes added to `commitment-contracts.ts` automatically register. Do NOT modify `index.ts`.

### CRITICAL: `_isLoading = true` as default value to avoid blank first frame

From Story 6.5 lessons: if the screen loads async data on init, set `_isLoading = true` as the default field value. In `StakeSheetScreen`, the existing `_isLoading = false` is correct (payment method check shows loading state while in-flight). For the new `_loadModificationWindow()`, use a separate `_isLoadingWindow = false` state field — it loads independently of the payment method check.

### CRITICAL: `(x as num).toInt()` for JSON numeric fields

If any JSON response field is typed as `num` rather than `int` at runtime, cast: `(data['stakeAmountCents'] as num).toInt()`. For `bool` fields, cast directly: `data['canModify'] as bool? ?? false`.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

After changes to `TaskStake` model and `CommitmentContractsRepository`:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Commit ALL generated files. No `build_runner` in CI.

Files needing regeneration in this story:
- `task_stake.freezed.dart` — updated Freezed model (new fields)
- `commitment_contracts_repository.g.dart` — updated (new `cancelStake` method added to `@riverpod` class)

### CRITICAL: `OnTaskColors.surfacePrimary` for backgrounds

Use `colors.surfacePrimary` for sheet/screen backgrounds. `backgroundPrimary` does not exist.
Access: `final colors = Theme.of(context).extension<OnTaskColors>()!;`

### CRITICAL: `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances

Every new `CupertinoButton` added to `StakeSheetScreen` must include `minimumSize: const Size(44, 44)`.

### CRITICAL: `catch (e)` not `catch (_)` in all error handlers

All catch blocks must use `catch (e)` — never `catch (_)`. This was a recurring review finding across 6.3 and 6.5.

### CRITICAL: `intl` package for date formatting

Use `package:intl/intl.dart` (`DateFormat`) for formatting `stakeModificationDeadline` display. The `intl` package is already a dependency in the Flutter project (used in other screens).

### CRITICAL: All UI strings in `AppStrings`

Do NOT hardcode user-facing copy. Every string in the UI must reference an `AppStrings` constant. The new strings added in this story are prefixed `stakeModification*`, `stakeLocked*`, and `stakeCancel*`.

### CRITICAL: Widget tests — wrap in `MaterialApp` with `OnTaskTheme`

All widget tests for `StakeSheetScreen` and related widgets must be wrapped:
```dart
await tester.pumpWidget(
  MaterialApp(
    theme: OnTaskTheme.light(),
    home: ...,
  ),
);
```

### CRITICAL: Repository tests extend existing `commitment_contracts_repository_test.dart`

Do NOT create a new test file for repository tests. Add groups to the existing file. This is a pattern established in Stories 6.2–6.5.

### Architecture: `stakeModificationDeadline` is server-computed, client displays only

The Flutter app does NOT compute `dueDate - 24h` locally. The server computes and returns:
- `stakeModificationDeadline: string | null` — ISO 8601 UTC datetime
- `canModify: boolean` — precomputed flag

The Flutter client converts `stakeModificationDeadline` to a local `DateTime` and formats it for display. This design ensures the window boundary is consistent even if device clock is wrong.

### Architecture: `tasks` schema — existing columns

From Story 6.2: `tasks.stakeAmountCents` (integer, nullable). New column added this story:
- `tasks.stakeModificationDeadline` (timestamptz, nullable) — set to `task.dueDate - 24h` when stake is locked

Both columns are nullable (no stake = null for both).

### Architecture: `charge_events` table — interaction with cancellation

Story 6.5 added the `charge_events` table with `status` values: `'pending'`, `'charged'`, `'failed'`, `'disbursed'`, `'disbursement_failed'`. When the user cancels a stake, the `cancelStake` stub sets `stakeAmountCents = null`. The charge scheduler (Story 6.5, `charge-scheduler.ts`) already queries `WHERE stakeAmountCents IS NOT NULL`, so cleared stakes will never be enqueued. The `TODO(impl)` note in the cancel handler documents the additional `charge_events` check needed for real implementation.

### Architecture: `commitment-contracts.ts` — existing routes (do NOT modify)

Currently registered routes — do NOT change existing implementations:
- `GET /v1/payment-method`
- `POST /v1/payment-method/setup-session`
- `POST /v1/payment-method/confirm`
- `DELETE /v1/payment-method`
- `GET /v1/tasks/:taskId/stake` ← extend schema, update stub
- `PUT /v1/tasks/:taskId/stake` ← extend schema, update stub
- `DELETE /v1/tasks/:taskId/stake` ← no change
- `GET /v1/charities`
- `GET /v1/commitment-contracts/charity`
- `POST /v1/commitment-contracts/charity`
- `GET /v1/impact`

New route to add: `POST /v1/tasks/:taskId/stake/cancel`

### Architecture: File locations

Modified files:
```
packages/core/src/schema/tasks.ts                       — add stakeModificationDeadline column
packages/core/src/schema/migrations/0016_stake_modification_deadline.sql — new migration
packages/core/src/schema/migrations/meta/_journal.json  — updated by drizzle-kit
packages/core/src/schema/migrations/meta/0016_snapshot.json — generated by drizzle-kit
apps/api/src/routes/commitment-contracts.ts             — extend stakeResponseSchema, add cancel route
apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart         — add new fields
apps/flutter/lib/features/commitment_contracts/domain/task_stake.freezed.dart — regenerated
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart — update getTaskStake, setTaskStake parse; add cancelStake
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart — regenerated
apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart — modification window UI
apps/flutter/lib/core/l10n/strings.dart                — new stake modification strings
apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart — extend
apps/flutter/test/features/commitment_contracts/stake_sheet_screen_test.dart  — extend
```

### UX: Modification window deadline display

Per epics AC: "You can adjust or cancel this stake until [datetime]" — the datetime is rendered in local time, human-readable format. The AC uses `[datetime]` as a placeholder; render it as `"Apr 2 at 3:00 PM"` style (month, day, time with AM/PM). Do NOT use raw ISO 8601 strings in the UI.

### UX: Locked state visual treatment

When window is closed (`canModify = false`):
- The slider is visible but non-interactive: `IgnorePointer(ignoring: true)` + `Opacity(opacity: 0.5)`
- Locked message appears below the slider: "This stake is locked — the deadline is too close to change it"
- "Remove stake" button is rendered but disabled: `onPressed: null`
- Message font: 13pt Regular, `colors.textSecondary` or `colors.stakeZoneHigh` for emphasis
- This is consistent with the AC copy from the epics

### Deferred items from Story 6.5 that do NOT impact this story

- `disburseDonation` stub permanently returns `{ success: false }` — not relevant here
- No test for `everyOrgConsumer` — not relevant here
- `triggerOverdueCharges` no-op stub — Story 6.6 only adds a comment to this stub; no behavior change

### Previous story learnings carried forward (Stories 6.1–6.5)

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
- `commitmentContractsRouter` already mounted — no `index.ts` change needed for new routes
- `_isLoading = true` as default value to avoid blank first frame
- `(x as num).toInt()` for JSON numeric fields
- Story 6.5 added `charge_events` table — stake cancellation must check for active charges (in TODO(impl))
- `charge_events.status` values: `'pending'`, `'charged'`, `'failed'`, `'disbursed'`, `'disbursement_failed'`

### References

- Epic 6 Story 6.6 definition: `_bmad-output/planning-artifacts/epics.md` lines 1625–1645
- FR63 definition: `_bmad-output/planning-artifacts/prd.md` line 549
- UX pre-deadline window (24h default): `_bmad-output/planning-artifacts/ux-design-specification.md` line 767
- UX midnight stake edge case: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1054
- Architecture FR63 file mapping: `_bmad-output/planning-artifacts/architecture.md` line 735
- Tasks schema: `packages/core/src/schema/tasks.ts`
- Commitment contracts schema: `packages/core/src/schema/commitment-contracts.ts`
- Charge events schema: `packages/core/src/schema/charge-events.ts`
- Last migration: `packages/core/src/schema/migrations/0015_charge_events.sql`
- Existing commitment-contracts routes: `apps/api/src/routes/commitment-contracts.ts`
- Existing StakeSheetScreen: `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart`
- Existing TaskStake domain model: `apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart`
- Existing repository: `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`
- Existing l10n strings: `apps/flutter/lib/core/l10n/strings.dart`
- AppStrings existing stake strings (lines 823–843)
- Story 6.2 story file: `_bmad-output/implementation-artifacts/6-2-stake-setting-ui.md` (stake UI patterns)
- Story 6.5 story file: `_bmad-output/implementation-artifacts/6-5-automated-charge-processing-charity-disbursement.md` (charge events schema, queue patterns)

## Dev Agent Record

### Implementation Plan

Implemented the stake modification window following the red-green-refactor cycle across all 7 task groups:

1. **DB schema**: Added `stakeModificationDeadline` (timestamptz, nullable) to `tasks` table. Generated migration `0016_stake_modification_deadline.sql` using `drizzle-kit generate` from `apps/api/`.

2. **API stubs**: Extended `stakeResponseSchema` with `stakeModificationDeadline` and `canModify` fields. Updated GET and PUT stub responses. Added `POST /v1/tasks/:taskId/stake/cancel` endpoint using `createRoute` pattern with `@hono/zod-openapi`. Added `StakeLockedError` and `NoActiveStakeError` classes to `errors.ts`.

3. **Charge safety**: Added CRITICAL comment to `charge-scheduler.ts` documenting that the charge query must exclude tasks where `stakeAmountCents IS NULL` (cancelled stakes).

4. **Flutter domain model**: Extended `TaskStake` Freezed model with `stakeModificationDeadline` and `canModify` fields. Regenerated `task_stake.freezed.dart`.

5. **Flutter repository**: Updated `getTaskStake` and `setTaskStake` to parse new fields. Added `cancelStake` method calling `POST .../stake/cancel`. Regenerated `commitment_contracts_repository.g.dart`. Added `intl` package to `pubspec.yaml` for `DateFormat`.

6. **Flutter UI**: Updated `StakeSheetScreen` to load modification window on init, display deadline label, show disabled/opacity slider when locked, show locked message, and use `cancelStake` for the remove button (disabled when `!_canModify`). Fixed all `catch (_)` to `catch (e)`.

7. **Tests**: Added 6 repository tests (3 for `getTaskStake` with modification window, 3 for `cancelStake`). Added 4 widget tests for modification window UI (label shown/absent, locked state controls, locked message).

### Completion Notes

- All 61 Flutter commitment_contracts tests pass (25 repository, 8 widget stake_sheet + 28 others)
- All 186 API tests pass (no regressions)
- Pre-existing TypeScript errors in `charge-trigger-consumer.ts` (drizzle-orm duplicate package issue) are not introduced by this story
- Pre-existing `use_null_aware_elements` lint infos in `searchCharities` method unchanged
- `intl 0.20.2` added to `pubspec.yaml` — story notes said it was already present but it was not

## File List

- `packages/core/src/schema/tasks.ts` — added `stakeModificationDeadline` column
- `packages/core/src/schema/migrations/0016_stake_modification_deadline.sql` — new migration (generated)
- `packages/core/src/schema/migrations/meta/_journal.json` — updated by drizzle-kit
- `packages/core/src/schema/migrations/meta/0016_snapshot.json` — generated by drizzle-kit
- `apps/api/src/routes/commitment-contracts.ts` — extended stakeResponseSchema, updated GET/PUT stubs, added cancel route
- `apps/api/src/lib/errors.ts` — added StakeLockedError and NoActiveStakeError
- `apps/api/src/lib/charge-scheduler.ts` — added CRITICAL comment about stakeAmountCents null check
- `apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart` — added stakeModificationDeadline and canModify fields
- `apps/flutter/lib/features/commitment_contracts/domain/task_stake.freezed.dart` — regenerated
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` — updated getTaskStake/setTaskStake parse; added cancelStake
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart` — regenerated
- `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart` — modification window UI
- `apps/flutter/lib/core/l10n/strings.dart` — new stake modification strings
- `apps/flutter/pubspec.yaml` — added intl dependency
- `apps/flutter/pubspec.lock` — updated by flutter pub add
- `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart` — extended with Story 6.6 groups
- `apps/flutter/test/features/commitment_contracts/stake_sheet_screen_test.dart` — extended with modification window tests
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — updated story status

## Change Log

- 2026-04-01: Story 6.6 implementation — stake modification window DB column, API endpoint, Flutter domain model, UI, and tests
