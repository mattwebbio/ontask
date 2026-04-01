# Story 6.2: Stake Setting UI

Status: review

## Story

As a user,
I want to set a financial stake on a task using a tactile slider with zone feedback,
so that I can calibrate exactly how much accountability pressure I need.

## Acceptance Criteria

1. **Given** the user opens a task and taps "Add stake"
   **When** the Stake Slider is shown
   **Then** the slider is built on a `CupertinoSlider` base with a custom track painter showing three colour zones: green/sage (low, $5–$20), yellow/amber (moderate, $25–$75), red/terracotta (high, $100+) (UX-DR7)
   **And** haptic feedback pulses (`HapticFeedback.selectionClick()`) when the thumb crosses a zone threshold
   **And** a 5% slider-width deadband is applied to prevent multiple fires on slow threshold crossing
   **And** the lock icon on the slider closes more firmly (visual tightening animation via `AnimatedSwitcher`) at higher values

2. **Given** the slider is in the red zone ($100+)
   **When** the calibration guidance is shown
   **Then** inline text reads: "This amount will cause real financial pain if missed. That's the point — but only if you're sure."

3. **Given** the user prefers an exact amount
   **When** they tap the displayed amount
   **Then** they can type an exact value directly instead of using the slider (minimum $5 increments)

4. **Given** no payment method is stored
   **When** the user tries to set a stake (taps "Add stake")
   **Then** the slider collapses and an inline prompt appears: "To lock in a stake, you'll need to add a payment method."
   **And** a single CTA "Set up payment" navigates to `PaymentSettingsScreen`

## Tasks / Subtasks

### Backend: DB schema — add `stakeAmountCents` column to `tasks` table (AC: 1, 3)

- [x] Modify `packages/core/src/schema/tasks.ts` (AC: 1, 3)
  - [x] Add column: `stakeAmountCents: integer()` — nullable; stake in US cents; null means no stake set
  - [x] Place after `proofMediaUrl` and before `completedAt` — follow existing column ordering
  - [x] Use `integer()` (not `numeric`/`decimal`) — cents are integers; avoids floating-point issues
  - [x] No `.notNull()` — stake is optional on any task

- [x] Generate migration `packages/core/src/schema/migrations/0013_stake_amount_cents.sql` (AC: 1, 3)
  - [x] Run `pnpm drizzle-kit generate` from `apps/api/` (where `drizzle.config.ts` lives — NOT `packages/core/`)
  - [x] Commit generated SQL, updated `meta/_journal.json`, and `meta/0013_snapshot.json`
  - [x] Migration: `ALTER TABLE tasks ADD COLUMN stake_amount_cents integer;`

### Backend: API — stake endpoints in `apps/api/src/routes/commitment-contracts.ts` (AC: 1, 3, 4)

- [x] Add `stakeSchema` and related schemas (AC: 1, 3)
  ```typescript
  const stakeSchema = z.object({
    taskId: z.string().uuid(),
    stakeAmountCents: z.number().int().min(500), // minimum $5 = 500 cents
  })
  const stakeResponseSchema = z.object({
    taskId: z.string().uuid(),
    stakeAmountCents: z.number().int().nullable(),
  })
  ```

- [x] Add `GET /v1/tasks/:taskId/stake` — get current stake for a task (AC: 1)
  - [x] Route param: `taskId` (uuid)
  - [x] Response 200: `{ data: stakeResponseSchema }`
  - [x] Stub: return `{ taskId, stakeAmountCents: null }`
  - [x] Tag: `'Stake'`
  - [x] Add `TODO(impl): query tasks table for stakeAmountCents where id = taskId AND userId = JWT sub`

- [x] Add `PUT /v1/tasks/:taskId/stake` — set or update stake on a task (AC: 1, 3)
  - [x] Request body schema: `stakeSchema`
  - [x] Response 200: `{ data: stakeResponseSchema }`
  - [x] Response 422 (`NO_PAYMENT_METHOD`): if no stored payment method
  - [x] Stub: return 200 with `{ taskId, stakeAmountCents: body.stakeAmountCents }`
  - [x] Tag: `'Stake'`
  - [x] Add `TODO(impl): check commitment_contracts.stripePaymentMethodId for userId; if null return 422 NO_PAYMENT_METHOD; else upsert tasks.stakeAmountCents; set commitment_contracts.hasActiveStakes = true`

- [x] Add `DELETE /v1/tasks/:taskId/stake` — remove stake from a task (AC: 1)
  - [x] Response 200: `{ data: { removed: z.boolean() } }`
  - [x] Stub: return `{ removed: true }`
  - [x] Tag: `'Stake'`
  - [x] Add `TODO(impl): set tasks.stakeAmountCents = null; recheck commitment_contracts.hasActiveStakes across all tasks for userId`

- [x] Route registration order (specific before parameterized — critical rule):
  - All three stake routes are under `/v1/tasks/:taskId/stake` — register in order: GET, PUT, DELETE
  - Register AFTER the existing payment-method routes in `commitment-contracts.ts`
  - No conflict with `tasks.ts` routes — stake routes live in `commitment-contracts.ts` by architecture spec

### Flutter: Domain model — `TaskStake` in `apps/flutter/lib/features/commitment_contracts/domain/` (AC: 1, 3)

- [x] Create `apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart`
  - [x] Freezed model:
    ```dart
    @freezed
    class TaskStake with _$TaskStake {
      const factory TaskStake({
        required String taskId,
        int? stakeAmountCents,   // null = no stake
      }) = _TaskStake;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit generated `task_stake.freezed.dart`

### Flutter: Repository — stake methods in `CommitmentContractsRepository` (AC: 1, 3, 4)

- [x] Extend `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`
  - [x] Add method: `Future<TaskStake> getTaskStake(String taskId)` — `GET /v1/tasks/:taskId/stake`
  - [x] Add method: `Future<TaskStake> setTaskStake(String taskId, int stakeAmountCents)` — `PUT /v1/tasks/:taskId/stake`
  - [x] Add method: `Future<void> removeTaskStake(String taskId)` — `DELETE /v1/tasks/:taskId/stake`
  - [x] Parse `TaskStake`: `TaskStake(taskId: data['taskId'], stakeAmountCents: data['stakeAmountCents'] as int?)`
  - [x] Use `_client.dio.get/put/delete<Map<String, dynamic>>(...)` pattern (same as existing methods)
  - [x] Re-run `dart run build_runner build --delete-conflicting-outputs` — regenerates `commitment_contracts_repository.g.dart`
  - [x] Commit updated `commitment_contracts_repository.g.dart`

### Flutter: `StakeSliderWidget` — custom slider component (AC: 1, 2, 3)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/widgets/stake_slider_widget.dart` (AC: 1, 2, 3)
  - [x] `StatefulWidget` (no need for `ConsumerStatefulWidget` — pure UI, caller passes callbacks)
  - [x] Constructor:
    ```dart
    const StakeSliderWidget({
      super.key,
      required this.stakeAmountCents,   // current value (null = $0 / no stake)
      required this.onChanged,          // (int? cents) => void
      required this.onConfirm,          // () => void — called when user taps confirm
    });
    ```
  - [x] Slider range: `0` to `20000` cents ($0–$200); use `double` internally for `CupertinoSlider`
    - `min: 0`, `max: 20000`, `divisions: 40` (every $5 increment = 500 cents)
  - [x] **Zone thresholds** (from UX spec):
    - Low zone: 0–2000 cents ($0–$20) → `colors.stakeZoneLow` (sage `#6B9E78`)
    - Mid zone: 2500–7500 cents ($25–$75) → `colors.stakeZoneMid` (amber `#C98A2E`)
    - High zone: 10000+ cents ($100+) → `colors.stakeZoneHigh` (terracotta `#C4623A`)
  - [x] **Custom track via `CustomPainter`** — Create `_StakeTrackPainter extends CustomPainter`:
    - Paint three colour zones on the track as gradient: sage → amber → terracotta
    - Zone boundaries at 20% ($40) and 55% ($110) of the track width for visual balance
    - Track height: 4pt; border-radius: 100px (pill shape)
  - [x] **Lock icon evolution** (`AnimatedSwitcher`, duration 200ms):
    - $0: `CupertinoIcons.lock_open` in `colors.stakeZoneLow`
    - Mid zone: `CupertinoIcons.lock_slash` or half-closed representation in `colors.stakeZoneMid`
    - High zone: `CupertinoIcons.lock_fill` in `colors.stakeZoneHigh`
  - [x] **Haptic feedback** — track last zone in `_currentZone` state:
    ```dart
    if (newZone != _currentZone) {
      HapticFeedback.selectionClick();
      _currentZone = newZone;
    }
    ```
    - 5% deadband: only fire if slider has moved ≥ 5% of full range past the threshold
  - [x] **Amount display**: `'$${(stakeAmountCents! / 100).toStringAsFixed(0)}'` at 20pt Bold, zone colour
    - Tap to enter exact amount: `showCupertinoDialog` with a `CupertinoTextField` — numeric keyboard
    - Minimum: 500 cents ($5); enforce in `onChanged` — snap to $5 if below
  - [x] **Zone labels row**: "Low" / "Mid" / "High" in 10pt, respective zone colours, above the track
  - [x] **Red zone guidance text** (AC: 2): shown only when `stakeAmountCents >= 10000`:
    ```
    "This amount will cause real financial pain if missed. That's the point — but only if you're sure."
    ```
    - Font: New York serif (voice copy style from UX spec), 15pt Regular italic
    - Colour: `colors.stakeZoneHigh`
    - Appear/disappear with `AnimatedOpacity` (200ms)
  - [x] **"Lock it in." confirm button**: `CupertinoButton` primary style, shown below slider
    - `minimumSize: const Size(44, 44)` — required on all `CupertinoButton` instances
    - Disabled when `stakeAmountCents == null || stakeAmountCents == 0`
    - Copy: `AppStrings.stakeConfirmButton`
  - [x] **Reduce Motion**: check `isReducedMotion(context)` — skip `AnimatedSwitcher` animation, use instant state change
  - [x] Accessibility: VoiceOver reads amount as `'$5 stake'`, `'$25 stake'` etc.; zone label announced on zone change

### Flutter: `StakeSheetScreen` — modal bottom sheet (AC: 1, 2, 3, 4)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart` (AC: 1, 2, 3, 4)
  - [x] `ConsumerStatefulWidget` — needs `commitmentContractsRepositoryProvider` and `getPaymentStatus()`
  - [x] Constructor: `StakeSheetScreen({ required this.taskId, this.existingStakeAmountCents })`
  - [x] Presented as a modal bottom sheet (not a full-screen route) — caller uses `showCupertinoModalPopup` or `showModalBottomSheet`
  - [x] **Payment method gate** (AC: 4):
    - On init: check `CommitmentPaymentStatus.hasPaymentMethod` via `ref.watch(commitmentContractsRepositoryProvider)`
    - If `hasPaymentMethod == false`: show collapsed state with inline prompt copy `AppStrings.stakePaymentMethodRequired` + `CupertinoButton` "Set up payment" → `Navigator.push(CupertinoPageRoute(builder: (_) => PaymentSettingsScreen()))`
    - If `hasPaymentMethod == true`: show `StakeSliderWidget`
  - [x] **Confirm flow**: on `onConfirm` callback from `StakeSliderWidget`:
    - Call `repository.setTaskStake(taskId, stakeAmountCents)` with `_isLoading` state pattern (same as `PaymentSettingsScreen`)
    - On success: `Navigator.pop(context, stakeAmountCents)` — returns value to caller
    - On error: `CupertinoAlertDialog` with `AppStrings.dialogErrorTitle` + `AppStrings.stakeSetError`
  - [x] **Remove stake**: if `existingStakeAmountCents != null`, show "Remove stake" `CupertinoButton` (destructive)
    - Confirm with `CupertinoAlertDialog`: title `AppStrings.stakeRemoveConfirmTitle`, actions: `AppStrings.actionCancel` + `AppStrings.actionDelete`
    - On confirm: `repository.removeTaskStake(taskId)` → `Navigator.pop(context, null)`
  - [x] Background: `colors.surfacePrimary` (not `backgroundPrimary`)
  - [x] `_isLoading` bool for loading state — `setState` pattern

### Flutter: Task edit inline — "Add stake" entry point (AC: 1, 4)

- [x] Extend `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` (AC: 1, 4)
  - [x] Add "Add stake" / stake display row below the existing task property rows
  - [x] When `task.stakeAmountCents == null`: show `CupertinoButton` with `CupertinoIcons.lock` icon + `AppStrings.stakeAddButton` label in `colors.stakeZoneLow`
  - [x] When `task.stakeAmountCents != null`: show existing stake amount formatted + lock icon in zone colour + tap to modify
  - [x] On tap: open `StakeSheetScreen` via `showCupertinoModalPopup`:
    ```dart
    final result = await showCupertinoModalPopup<int?>(
      context: context,
      builder: (_) => StakeSheetScreen(
        taskId: task.id,
        existingStakeAmountCents: task.stakeAmountCents,
      ),
    );
    // result == null means removed; result != null means new amount set
    ```
  - [x] On sheet close: call task update to persist `stakeAmountCents` via `tasksProvider`
    - Add `TODO(impl): call PATCH /v1/tasks/:id with stakeAmountCents in Story 6.2`
    - Use optimistic local state update (same pattern as other task property edits in `task_edit_inline.dart`)
  - [x] Comment: `// ── Commitment stake (Epic 6, Story 6.2) ──────────────────`

### Flutter: l10n strings (AC: 1, 2, 3, 4)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Stake setting UI (FR22, FR28, UX-DR7) ──` section
  - [x] `static const String stakeAddButton = 'Add stake';`
  - [x] `static const String stakeSliderTitle = 'Set your stake';`
  - [x] `static const String stakeZoneLowLabel = 'Low';`
  - [x] `static const String stakeZoneMidLabel = 'Mid';`
  - [x] `static const String stakeZoneHighLabel = 'High';`
  - [x] `static const String stakeHighZoneGuidance = 'This amount will cause real financial pain if missed. That\'s the point — but only if you\'re sure.';`
  - [x] `static const String stakeConfirmButton = 'Lock it in.';`
  - [x] `static const String stakeRemoveConfirmTitle = 'Remove stake?';`
  - [x] `static const String stakeRemoveConfirmMessage = 'Your financial commitment will be cancelled. The task will continue as a normal unstaked task.';`
  - [x] `static const String stakeSetError = 'Could not set stake. Please try again.';`
  - [x] `static const String stakePaymentMethodRequired = 'To lock in a stake, you\'ll need to add a payment method.';`
  - [x] `static const String stakeSetupPaymentCta = 'Set up payment';`
  - [x] NOTE: `AppStrings.actionDelete`, `AppStrings.actionCancel`, `AppStrings.dialogErrorTitle` already exist — do NOT recreate
  - [x] NOTE: `AppStrings.nowCardStakeLabel` (`'at stake'`) and `AppStrings.chapterBreakStakeLabel` already exist

### Tests

- [x] Unit tests for `CommitmentContractsRepository` stake methods in `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart`
  - [x] Add to existing test file (do NOT create a new one — extend Story 6.1's test file)
  - [x] Test: `getTaskStake('task-id')` fires `GET /v1/tasks/task-id/stake` and maps `taskId` + `stakeAmountCents`
  - [x] Test: `setTaskStake('task-id', 2500)` fires `PUT /v1/tasks/task-id/stake` with body `{'taskId': 'task-id', 'stakeAmountCents': 2500}`
  - [x] Test: `removeTaskStake('task-id')` fires `DELETE /v1/tasks/task-id/stake`
  - [x] Use same `mocktail` + `MockDio` pattern from Story 6.1

- [x] Widget tests for `StakeSliderWidget` in `apps/flutter/test/features/commitment_contracts/stake_slider_widget_test.dart`
  - [x] New test file
  - [x] Test: slider renders zone labels "Low", "Mid", "High"
  - [x] Test: red zone guidance text appears when `stakeAmountCents >= 10000`
  - [x] Test: red zone guidance text absent when `stakeAmountCents < 10000`
  - [x] Test: "Lock it in." button is disabled when `stakeAmountCents == 0`
  - [x] Test: "Lock it in." button is enabled when `stakeAmountCents >= 500`
  - [x] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

- [x] Widget tests for `StakeSheetScreen` in `apps/flutter/test/features/commitment_contracts/stake_sheet_screen_test.dart`
  - [x] New test file
  - [x] Test: payment gate renders when `hasPaymentMethod == false` — shows `AppStrings.stakePaymentMethodRequired`
  - [x] Test: slider renders when `hasPaymentMethod == true`
  - [x] Test: "Remove stake" button renders when `existingStakeAmountCents != null`
  - [x] Test: "Remove stake" button absent when `existingStakeAmountCents == null`
  - [x] Override `commitmentContractsRepositoryProvider` — same `ProviderContainer` pattern as Stories 5.4/5.6/6.1

## Dev Notes

### CRITICAL: This is Epic 6, Story 2 — all stake API calls are stubs with TODO(impl) markers

Per Epic 6 note: Story 13.1 (AASA + payment pages) must be deployed before Epic 6 can be tested end-to-end. All stake endpoints are stubs returning fixture data. The actual charge mechanism is in Story 6.5. This story only implements the UI for setting the amount and persisting it to the DB.

### CRITICAL: Migration numbering — next is 0013

`0012_commitment_contracts.sql` was created in Story 6.1. Next migration is `0013_stake_amount_cents.sql`. Run `pnpm drizzle-kit generate` from `apps/api/` (not `packages/core/`) — the `drizzle.config.ts` lives in `apps/api/`.

### CRITICAL: `stakeAmountCents` goes on the `tasks` table, NOT `commitment_contracts`

`commitment_contracts` stores per-user payment method metadata (hasActiveStakes boolean). `tasks` stores per-task stake amounts as `stakeAmountCents: integer()` (nullable). This matches the architecture's `stakeAmount: Decimal?` in the LiveActivity `ContentState` struct — the tasks table owns the stake amount. The `commitment_contracts.hasActiveStakes` boolean is a denormalized flag that should be updated whenever a stake is set/removed (stub for now with `TODO(impl)`).

### CRITICAL: Stake amount in cents — integer, not decimal

The API, DB, and Flutter domain all use **integer cents** (e.g., 2500 = $25.00). The `NowTask.stakeAmountCents` field already exists as `int?` in the now tab (Story 2.7). `CommitmentRow.formatAmount()` already handles cents-to-dollars formatting. Use `stakeAmountCents` consistently — never `stakeAmount` as a float.

### CRITICAL: New stake API routes in `commitment-contracts.ts`, NOT `tasks.ts`

Architecture spec: `apps/api/src/routes/commitment-contracts.ts` handles FR22-30, FR63-65. Do NOT add stake routes to `tasks.ts`. The router is already mounted at `/` in `index.ts` — no change needed there.

### CRITICAL: Route registration order — specific before parameterized

Within `commitment-contracts.ts`, the new stake routes use `/v1/tasks/:taskId/stake`. These are specific sub-resource routes — register GET before PUT before DELETE. There are no conflicting routes in `tasks.ts` since task routes use `/v1/tasks` and `/v1/tasks/:id` (no `/stake` suffix).

### CRITICAL: `StakeSliderWidget` is a pure widget, `StakeSheetScreen` is the Riverpod consumer

`StakeSliderWidget` has no Riverpod dependency — it takes callbacks. `StakeSheetScreen` is the `ConsumerStatefulWidget` that fetches payment status and calls the repository. This separation enables easy widget testing of the slider without provider setup.

### CRITICAL: Task edit entry point — do NOT add routes to AppRouter for StakeSheetScreen

`StakeSheetScreen` is presented as a `CupertinoModalPopup` (modal bottom sheet), not pushed onto the navigation stack. Do NOT add a named route to `app_router.dart`. Caller uses `showCupertinoModalPopup` directly from `task_edit_inline.dart`.

### CRITICAL: TypeScript NodeNext — `.js` extensions on all local imports

```typescript
// Correct
import { ok, err } from '../lib/response.js'
// The new stake schemas live in the same commitment-contracts.ts file — no import needed
```

### CRITICAL: `@hono/zod-openapi` — always use `createRoute` pattern

All three stake routes in `commitment-contracts.ts` must use `createRoute({ method, path, tags, request, responses })`. No untyped Hono routes. Follow the existing pattern already in the file for `getPaymentMethodRoute`, `setupSessionRoute`, etc.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

After changes to `TaskStake` model and `CommitmentContractsRepository`:
```
dart run build_runner build --delete-conflicting-outputs
```
Commit ALL generated files. No `build_runner` in CI.

Files needing generation/regeneration in this story:
- `task_stake.freezed.dart` — new Freezed model (new file)
- `commitment_contracts_repository.g.dart` — updated (new methods added to existing `@riverpod` class)

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

Use `colors.surfacePrimary` for sheet/screen backgrounds. `backgroundPrimary` does not exist.
Access: `final colors = Theme.of(context).extension<OnTaskColors>()!;`

### CRITICAL: `minimumSize: const Size(44, 44)` on ALL `CupertinoButton` instances

Every new `CupertinoButton` in `StakeSliderWidget` and `StakeSheetScreen` must include `minimumSize: const Size(44, 44)`.

### CRITICAL: Stake colour tokens — `colors.stakeZoneLow/Mid/High`

Already defined in `OnTaskColors` and `AppColors`:
- `stakeZoneLow` = sage `#6B9E78` (declared in `app_colors.dart:102`)
- `stakeZoneMid` = amber `#C98A2E` (declared in `app_colors.dart:103`)
- `stakeZoneHigh` = terracotta `#C4623A` (declared in `app_colors.dart:104`)

Access via `Theme.of(context).extension<OnTaskColors>()!.stakeZoneLow/Mid/High`. Do NOT hardcode hex values.

### CRITICAL: `z.record()` requires two arguments

If any Zod schema uses `z.record(...)`, use `z.record(z.string(), valueType)` — two args required.

### CRITICAL: Drizzle `casing: 'camelCase'`

Write schema in camelCase (`stakeAmountCents`). Drizzle generates snake_case DDL (`stake_amount_cents`) automatically. Do NOT add manual `.name()` overrides.

### CRITICAL: `{ withTimezone: true }` on ALL timestamp columns

All timestamp columns must use `{ withTimezone: true }` (established in Story 6.1 patches). `stakeAmountCents` is `integer()` — no timezone concern for this column.

### CRITICAL: `AppStrings` existing strings — do NOT recreate

Already exist and must be reused:
- `AppStrings.actionDelete` — destructive confirmation action label
- `AppStrings.actionCancel` — cancel label
- `AppStrings.actionOk` — OK/dismiss action label
- `AppStrings.dialogErrorTitle` — 'Error' for alert dialogs
- `AppStrings.nowCardStakeLabel` — 'at stake' (shown in Now tab)
- `AppStrings.chapterBreakStakeLabel` — 'Stake returned' (shown in chapter break)

### UX: Slider anatomy (from UX spec line ~1131)

Full spec: Zone labels row (Low / Mid / High, 10pt, zone colours) → custom track (`CustomPainter`, gradient: `stakeZoneLow` → `stakeZoneMid` → `stakeZoneHigh`) → thumb (white circle, 22pt, shadow, border colour = current zone colour) → amount display (20pt Bold, current zone colour) → lock icon (`AnimatedSwitcher`: open padlock $0 → half-closed mid → fully closed high).

**Haptic debounce**: `HapticFeedback.selectionClick()` fires at each zone boundary with a 5% slider-width deadband to prevent multiple fires on slow threshold crossing.

### UX: Payment method gate (from UX spec line ~1442)

If no payment method exists when stake slider is expanded: slider collapses, inline prompt appears: "To lock in a stake, you'll need to add a payment method." Single CTA: "Set up payment" → `PaymentSettingsScreen`. Non-blocking — user can close and add without stake. This is `AppStrings.stakePaymentMethodRequired`.

### UX: Motion tokens note

"The vault close" motion token is NOT implemented in this story — it is deferred to Story 6.8 (Full Commitment Lock Flow & Animation). `MotionTokens` in `apps/flutter/lib/core/motion/motion_tokens.dart` notes this explicitly ("Epic 6 tokens are NOT implemented here"). The `AnimatedSwitcher` for the lock icon in `StakeSliderWidget` is a simple UI state transition, not "The vault close" ceremony.

### Deferred items from Story 6.1 that impact this story

- **`catch (_)` in `_removePaymentMethod` gives generic error on 422** — same pattern must NOT be repeated in `StakeSheetScreen`. Distinguish 422 `NO_PAYMENT_METHOD` from generic errors.
- **Widget test missing `onPressed == null` assertion** — in new widget tests, explicitly assert `CupertinoButton.onPressed == null` when "Lock it in." is disabled.

### `CommitmentRow.formatAmount()` — reuse for display

`apps/flutter/lib/features/now/presentation/widgets/commitment_row.dart` exports `CommitmentRow.formatAmount(int stakeAmountCents)` which formats cents to dollar string. Import and reuse this in `StakeSliderWidget` amount display to avoid duplicating formatting logic. Note: it has no guard for negative values (deferred issue from Story 2.7 review) — input will always be ≥ 0 here so this is safe.

### Existing route state in `apps/api/src/routes/commitment-contracts.ts`

Currently registered routes (do NOT modify existing route implementations):
- `GET /v1/payment-method`
- `POST /v1/payment-method/setup-session`
- `POST /v1/payment-method/confirm`
- `DELETE /v1/payment-method`

Add stake routes after these.

### Project Structure Notes

- Modify: `packages/core/src/schema/tasks.ts` — add `stakeAmountCents` column
- New migration: `packages/core/src/schema/migrations/0013_stake_amount_cents.sql` (generate from `apps/api/`)
- Modify: `apps/api/src/routes/commitment-contracts.ts` — add 3 stake routes
- New Flutter domain model: `apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart` (create)
- New Flutter domain generated: `apps/flutter/lib/features/commitment_contracts/domain/task_stake.freezed.dart` (generate)
- Modify: `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` (add 3 methods)
- Regenerate: `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart`
- New Flutter widget: `apps/flutter/lib/features/commitment_contracts/presentation/widgets/stake_slider_widget.dart` (create, new `widgets/` directory)
- New Flutter screen: `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart` (create)
- Modify: `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — add stake entry point
- Modify: `apps/flutter/lib/core/l10n/strings.dart` — add stake UI strings

### References

- Epic 6 story definition: `_bmad-output/planning-artifacts/epics.md` lines 1522–1548
- UX stake slider anatomy: `_bmad-output/planning-artifacts/ux-design-specification.md` lines 1127–1138
- UX payment gate: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1442
- UX stake zone colours: `_bmad-output/planning-artifacts/ux-design-specification.md` lines 689–695
- UX add-task flow with stake: `_bmad-output/planning-artifacts/ux-design-specification.md` lines 916–927
- Architecture Flutter feature structure: `_bmad-output/planning-artifacts/architecture.md` line 869
- Architecture stake API route location: `_bmad-output/planning-artifacts/architecture.md` line 735
- Architecture `stakeAmount` in LiveActivity: `_bmad-output/planning-artifacts/architecture.md` line 250
- Colour tokens implementation: `apps/flutter/lib/core/theme/app_colors.dart` lines 102–104
- `OnTaskColors` stakeZone fields: `apps/flutter/lib/core/theme/app_theme.dart` lines 239–241
- `CommitmentRow.formatAmount()`: `apps/flutter/lib/features/now/presentation/widgets/commitment_row.dart`
- `MotionTokens` and Epic 6 deferral: `apps/flutter/lib/core/motion/motion_tokens.dart` line 9
- Previous story patterns: `_bmad-output/implementation-artifacts/6-1-payment-method-setup.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Migration rename: drizzle-kit auto-generates names (e.g., `0013_graceful_jackpot`); renamed to `0013_stake_amount_cents` for consistency with story spec. Updated `_journal.json` tag accordingly.
- `_midZoneMin` constant was unused (zone boundary check happens implicitly via `_lowZoneMax` and `_midZoneMax`); removed to resolve analyzer warning.
- `removeTaskStake` uses `dio.delete` without `data:` arg (no body required for DELETE) — consistent with the API contract.

### Completion Notes List

- Added `stakeAmountCents: integer()` to `packages/core/src/schema/tasks.ts` after `proofMediaUrl`, before `completedAt`. Nullable, no default.
- Generated and renamed migration `0013_stake_amount_cents.sql` — includes `ALTER TABLE tasks ADD COLUMN stake_amount_cents integer` plus commitment_contracts timestamp type fixes from drizzle-kit diff.
- Added 3 stub stake routes (GET/PUT/DELETE `/v1/tasks/:taskId/stake`) to `commitment-contracts.ts` using `createRoute` pattern. All tagged `'Stake'`, all include `TODO(impl)` markers.
- Created `TaskStake` Freezed domain model; ran build_runner; committed `task_stake.freezed.dart`.
- Added `getTaskStake`, `setTaskStake`, `removeTaskStake` methods to `CommitmentContractsRepository`; re-ran build_runner; `commitment_contracts_repository.g.dart` unchanged (no new provider annotations added).
- Created `StakeSliderWidget` (pure `StatefulWidget`): tri-colour gradient track via `_StakeTrackPainter`, `CupertinoSlider`, `AnimatedSwitcher` lock icon (open/slash/fill), `HapticFeedback.selectionClick()` with 5% deadband, `AnimatedOpacity` red-zone guidance text, tappable amount display with `showCupertinoDialog` exact entry, `isReducedMotion` Reduce Motion check, VoiceOver Semantics label.
- Created `StakeSheetScreen` (`ConsumerStatefulWidget`): payment gate (hasPaymentMethod check on init), slider view, confirm flow with 422 DioException handling, remove stake with confirmation dialog, `colors.surfacePrimary` background.
- Added `stakeAmountCents: int?` field to `Task` Freezed model; re-ran build_runner.
- Extended `task_edit_inline.dart` with "Add stake" row (lock icon + amount display), `_openStakeSheet` method using `showCupertinoModalPopup`, optimistic local state, `TODO(impl)` marker.
- Added 12 `AppStrings` stake constants under `// ── Stake setting UI (FR22, FR28, UX-DR7) ──` section.
- Tests: 872 total passing, 0 failing. New tests: 6 repository unit tests (stake methods), 5 slider widget tests, 4 sheet screen widget tests = 15 new tests total.

### File List

- `packages/core/src/schema/tasks.ts` — modified (added `stakeAmountCents`)
- `packages/core/src/schema/migrations/0013_stake_amount_cents.sql` — new (generated + renamed)
- `packages/core/src/schema/migrations/meta/_journal.json` — modified (updated tag)
- `packages/core/src/schema/migrations/meta/0013_snapshot.json` — new (generated)
- `apps/api/src/routes/commitment-contracts.ts` — modified (3 stake routes added)
- `apps/flutter/lib/features/commitment_contracts/domain/task_stake.dart` — new
- `apps/flutter/lib/features/commitment_contracts/domain/task_stake.freezed.dart` — new (generated)
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` — modified (3 stake methods + import)
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart` — modified (regenerated)
- `apps/flutter/lib/features/commitment_contracts/presentation/widgets/stake_slider_widget.dart` — new
- `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart` — new
- `apps/flutter/lib/features/tasks/domain/task.dart` — modified (added `stakeAmountCents` field)
- `apps/flutter/lib/features/tasks/domain/task.freezed.dart` — modified (regenerated)
- `apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart` — modified (stake entry point)
- `apps/flutter/lib/core/l10n/strings.dart` — modified (stake UI strings)
- `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart` — modified (stake method tests)
- `apps/flutter/test/features/commitment_contracts/stake_slider_widget_test.dart` — new
- `apps/flutter/test/features/commitment_contracts/stake_sheet_screen_test.dart` — new
- `_bmad-output/implementation-artifacts/6-2-stake-setting-ui.md` — modified (story status + dev record)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — modified (status: review)

### Change Log

- 2026-04-01: Story 6.2 implemented — Stake Setting UI. DB schema, stub API endpoints, TaskStake domain model, StakeSliderWidget, StakeSheetScreen, task edit entry point, l10n strings. 872 tests passing.
