# Story 6.8: Full Commitment Lock Flow & Animation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the commitment lock experience to feel ceremonial and irreversible,
So that I take the commitment seriously and feel the weight of the decision.

## Acceptance Criteria

1. **Given** the user has set a stake amount and selected a charity
   **When** they reach the lock confirmation step
   **Then** a full-screen Commitment Ceremony Card is shown with: task title, stake amount, charity name, and deadline displayed prominently (UX-DR8)
   **And** copy uses the "past self / future self" framing: "Your future self is counting on you" (UX-DR32)
   **And** "The vault close" motion token plays on confirmation — a satisfying vault-door-closing micro-animation (UX-DR20)
   **And** "The vault close" degrades to an instant state change when "Reduce Motion" is enabled

2. **Given** a group commitment is being locked
   **When** the full flow runs
   **Then** the sequence is: Stake Slider → Charity Selection → Deadline Confirmation → Group Approval (unanimous) → Pool Mode opt-in → Lock Confirmation (UX-DR34)
   **And** the flow cannot be skipped or reordered

3. **Given** the commitment is locked
   **When** the user returns to the task
   **Then** the Now Tab Task Card switches to the "committed" display variant showing stake amount and proof mode

## Tasks / Subtasks

### Flutter: "The vault close" motion token — add to `MotionTokens` (AC: 1)

- [x] Add vault close token constants to `apps/flutter/lib/core/motion/motion_tokens.dart` (AC: 1)
  - [x] Add under a new `// ── "The vault close" — commitment lock confirmed (UX-DR20) ──` section:
    ```dart
    // ── "The vault close" — commitment lock confirmed (UX-DR20) ─────────────
    /// Total duration of "The vault close" animation (ms).
    /// Weighted closing arc — weighty, deliberate, final.
    /// Source: UX spec line 1700 — "Weighted closing arc, 600ms"
    static const int vaultCloseDurationMs = 600;

    /// Reduced-motion fallback duration for "The vault close" (ms).
    /// Instant opacity change only.
    /// Source: UX spec line 1700 — "Instant opacity change, 100ms"
    static const int vaultCloseReducedMotionDurationMs = 100;
    ```
  - [x] The file comment at top already says "Epic 6 tokens ('The vault close', 'The release') are NOT implemented here" — UPDATE that comment to remove the vault-close exclusion once added. Do not change the note about "The release" (that remains for a future story).

### Flutter: Commitment Ceremony Card widget (AC: 1, 3)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/widgets/commitment_ceremony_card.dart` (AC: 1)

  **Architecture note:** The UX spec (line 1318) states: "The `CommittedTaskDisplay` base widget is shared between the Now tab committed card and the commitment ceremony card. Surface token is the only differentiator — `color.surface.primary` for standard, `color.accent.commitment` for ceremony emphasis." This story introduces the ceremony card as a new widget. The `CommittedTaskDisplay` base widget does not yet exist as a standalone widget — implement the ceremony card directly and note that `CommittedTaskDisplay` refactoring is deferred.

  **Widget anatomy** (per UX spec line 1141–1148):
  - Dark surface (`colors.accentCommitment` fill)
  - Eyebrow label: 9pt, uppercase, `colors.textSecondary` on dark (e.g., "YOUR COMMITMENT")
  - Task title: New York font, 20pt, `colors.surfacePrimary` on dark
  - Stake row: lock icon (SF Symbol `lock.fill`) + formatted amount in `colors.accentCompletion` + "at stake"
  - Deadline row: formatted deadline string
  - Charity row: charity name
  - Sub-copy (New York italic, 15pt): "Your future self is counting on you." (`AppStrings.commitmentCeremonyCopy`)
  - "Lock it in." `CupertinoButton` with `colors.accentCommitment` fill and `colors.surfacePrimary` text

  ```dart
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart' show Theme;
  import 'package:flutter/services.dart';
  import '../../../../core/l10n/strings.dart';
  import '../../../../core/motion/motion_tokens.dart';
  import '../../../../core/theme/app_spacing.dart';
  import '../../../../core/theme/app_theme.dart';

  /// Full-screen Commitment Ceremony Card shown at the lock confirmation step.
  ///
  /// Displays task title, stake amount, charity name, and deadline on a dark
  /// `accentCommitment` surface to signal this is a moment of weight and ceremony.
  ///
  /// On confirmation: plays "The vault close" animation (UX-DR20) — a 600ms
  /// opacity-to-close arc, degraded to a 100ms instant change when
  /// [MediaQuery.disableAnimations] is true.
  ///
  /// Haptic: [HapticFeedback.heavyImpact()] fires on the "Lock it in." tap —
  /// the heaviest haptic in the product (UX spec line 1527).
  class CommitmentCeremonyCard extends StatefulWidget {
    const CommitmentCeremonyCard({
      super.key,
      required this.taskTitle,
      required this.stakeAmountCents,
      required this.charityName,
      required this.deadline,
      required this.onLock,
      this.isLoading = false,
    });

    final String taskTitle;
    final int stakeAmountCents;
    final String charityName;
    final DateTime deadline;
    final VoidCallback onLock;
    final bool isLoading;

    @override
    State<CommitmentCeremonyCard> createState() => _CommitmentCeremonyCardState();
  }
  ```

  **`_CommitmentCeremonyCardState` implementation notes:**
  - Use `AnimationController` with `vsync: this` (mixin `SingleTickerProviderStateMixin`)
  - `_controller.duration` = `Duration(milliseconds: isReducedMotion(context) ? MotionTokens.vaultCloseReducedMotionDurationMs : MotionTokens.vaultCloseDurationMs)`
  - Read reduced motion in `didChangeDependencies`, NOT `initState`
  - On "Lock it in." tap:
    1. `HapticFeedback.heavyImpact()`
    2. `_controller.forward()` — animates card opacity from 1.0 → 0.0 (closing vault)
    3. After animation completes: call `widget.onLock()`
  - Reduce motion path: `_controller.forward()` still called — the short 100ms duration IS the instant change
  - DO NOT call `widget.onLock()` directly — always go through the animation path so the API call fires after the animation
  - Format stake amount: use `CommitmentRow.formatAmount(stakeAmountCents)` (already exists in `commitment_row.dart`)
  - Format deadline: use `intl` package `DateFormat('MMM d \'at\' h:mm a').format(deadline.toLocal())`

  **Layout (full-screen, dark surface):**
  ```dart
  // Outer: Scaffold/CupertinoPageScaffold, background = colors.accentCommitment
  // FadeTransition wrapping the card content
  // Column (center-aligned, padding: AppSpacing.l):
  //   eyebrow label (9pt uppercase, colors.surfacePrimary.withOpacity(0.6))
  //   SizedBox(height: AppSpacing.m)
  //   task title (New York, 20pt semibold, colors.surfacePrimary)
  //   SizedBox(height: AppSpacing.l)
  //   stake row (lock icon + formatted amount, colors.accentCompletion, + "at stake")
  //   SizedBox(height: AppSpacing.s)
  //   deadline row (formatted deadline, colors.surfacePrimary.withOpacity(0.8))
  //   SizedBox(height: AppSpacing.s)
  //   charity row (charity name, colors.surfacePrimary.withOpacity(0.8))
  //   SizedBox(height: AppSpacing.xl)
  //   sub-copy: AppStrings.commitmentCeremonyCopy (New York italic, 15pt, colors.surfacePrimary.withOpacity(0.7))
  //   SizedBox(height: AppSpacing.xl)
  //   "Lock it in." CupertinoButton (heavy weight button style, full-width)
  ```

  - "Lock it in." button: `minimumSize: const Size(44, 44)`, full-width, `colors.surfacePrimary` fill, `colors.accentCommitment` text (inverted from background)
  - When `isLoading = true`: replace button with `CupertinoActivityIndicator(color: colors.surfacePrimary)`
  - Access New York font: use `const TextStyle(fontFamily: 'NewYorkSmall')` — available system font (no bundle cost), as per UX spec line 716. Use `fontStyle: FontStyle.italic` for sub-copy.

### Flutter: Lock Confirmation Screen (AC: 1, 2)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/lock_confirmation_screen.dart` (AC: 1, 2)
  - [x] `ConsumerStatefulWidget` — receives: `taskId`, `taskTitle`, `stakeAmountCents`, `charityName`, `charityId`, `deadline` as constructor params
  - [x] `_isLoading = false` as default field value
  - [x] Renders `CommitmentCeremonyCard` with all required fields
  - [x] `onLock` callback calls `_performLock()`:
    ```dart
    Future<void> _performLock() async {
      setState(() => _isLoading = true);
      try {
        // setTaskStake already called in StakeSheetScreen — the lock confirmation
        // screen's job is to show the ceremony and navigate to completion.
        // If a separate /lock endpoint is added in a future story, call it here.
        // For now: navigate to chapter-break screen after animation completes.
        if (mounted) {
          context.push('/chapter-break', extra: {
            'taskTitle': widget.taskTitle,
            'stakeAmount': CommitmentRow.formatAmount(widget.stakeAmountCents),
          });
        }
      } catch (e) {
        if (mounted) _showErrorDialog(AppStrings.lockConfirmError);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
    ```
  - [x] Screen background: `colors.accentCommitment` (full-screen dark surface — no scaffold backdrop visible)
  - [x] No back button shown (commitment is irreversible — deliberate action pattern)
  - [x] iOS swipe-back disabled: set `NavigatorObserver` or use `PopScope(canPop: false)` to prevent accidental back gesture during the ceremony card

### Flutter: Wire lock confirmation into `StakeSheetScreen` flow (AC: 1, 2)

The `StakeSheetScreen` (at `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart`) currently pops with the stake amount on `_onConfirm()`. Story 6.8 replaces this pop with a navigation to the `LockConfirmationScreen`.

- [x] Modify `_onConfirm()` in `StakeSheetScreen` to navigate to `LockConfirmationScreen` after `setTaskStake` succeeds:
  ```dart
  Future<void> _onConfirm() async {
    final cents = _stakeAmountCents;
    if (cents == null || cents < 500) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.setTaskStake(widget.taskId, cents);
      if (mounted) {
        // Navigate to lock confirmation ceremony instead of popping immediately.
        // LockConfirmationScreen will navigate to /chapter-break after animation.
        await Navigator.of(context).push(
          CupertinoPageRoute<void>(
            builder: (_) => LockConfirmationScreen(
              taskId: widget.taskId,
              taskTitle: widget.taskTitle,
              stakeAmountCents: cents,
              charityName: _selectedCharity?.name ?? '',
              charityId: _selectedCharity?.id ?? '',
              deadline: DateTime.now().add(const Duration(days: 30)), // TODO: use actual task deadline when task deadline is available
            ),
          ),
        );
        // After ceremony, pop the stake sheet too (stack cleanup).
        if (mounted) Navigator.of(context).pop(cents);
      }
    } on DioException catch (e) {
      // ... existing error handling unchanged
    }
  }
  ```
  - [x] Add import for `LockConfirmationScreen` at top of `stake_sheet_screen.dart`
  - [x] Add `taskTitle` constructor parameter to `StakeSheetScreen` (required, `String`) — callers must pass the task title
  - [x] The `_selectedCharity` field already exists in `StakeSheetScreen` — pass it through

  **IMPORTANT:** `StakeSheetScreen` does not currently have a `taskTitle` parameter. Adding it is a breaking change — all existing call sites must be updated. Check call sites via:
  ```bash
  grep -rn "StakeSheetScreen(" apps/flutter/lib/
  ```
  Update every call site to pass `taskTitle`.

### Flutter: NowTaskCard — verify "committed" display variant (AC: 3)

The `NowTaskCard` already has two surface variants (line 20–21 of `now_task_card.dart`): light surface for standard tasks, dark surface (`accentCommitment`) for committed tasks with a stake. The committed display is already triggered when `widget.task.stakeAmountCents != null`.

- [x] Verify the committed variant renders correctly after a lock by running the app and confirming:
  - The card background switches to `colors.accentCommitment`
  - `stakeAmountCents` and `proofMode` appear in the card
  - `CommitmentRow` shows the stake amount
  - `ProofModeIndicator` shows the proof mode
- [x] Add a widget test to `apps/flutter/test/features/now/now_task_card_test.dart` (extend existing, do NOT create new file):
  ```dart
  testWidgets('renders committed variant (dark surface) when stakeAmountCents is set', (tester) async {
    // Provide NowTask with stakeAmountCents: 2500, proofMode: ProofMode.photo
    // Verify accentCommitment color applied as card background
    // Verify CommitmentRow is rendered with formatted amount
  });
  ```

### Flutter: Group commitment lock flow sequence (AC: 2)

The group commitment flow sequence — Stake Slider → Charity Selection → Deadline Confirmation → Group Approval → Pool Mode opt-in → Lock Confirmation — is orchestrated across:
- `StakeSheetScreen` (Stories 6.2, 6.3) — stake slider + charity selection
- `GroupCommitmentReviewScreen` (Story 6.7) — group approval + pool mode opt-in
- `LockConfirmationScreen` (this story) — lock confirmation

The "cannot be skipped or reordered" AC is enforced by:
1. `StakeSheetScreen` only shows the "Lock it in." button when `_stakeAmountCents >= 500` AND a payment method exists
2. `GroupCommitmentReviewScreen` only shows the pool mode section after `commitment.isActive` (unanimous approval)
3. `LockConfirmationScreen` is only navigated to after `setTaskStake` succeeds

- [x] No new orchestration code is required for Story 6.8 — the sequence constraint is already enforced by the existing screen guards. Document this in Dev Notes.
- [x] Add a widget test to `apps/flutter/test/features/commitment_contracts/lock_confirmation_screen_test.dart` (new file — new screen):
  ```dart
  testWidgets('renders CommitmentCeremonyCard with task title and amount', (tester) async {
    // Provide taskTitle: 'Test task', stakeAmountCents: 5000, charityName: 'Test Charity'
    // Verify AppStrings.commitmentCeremonyCopy text present
    // Verify formatted stake amount '$50' present
    // Verify 'Test Charity' present
  });
  testWidgets('tapping Lock it in. fires heavyImpact and calls onLock after animation', (tester) async {
    // Mock HapticFeedback, verify heavyImpact called on button tap
    // Verify _performLock called
  });
  testWidgets('does not show back button', (tester) async {
    // Verify no CupertinoNavigationBar back button present
  });
  testWidgets('shows CupertinoActivityIndicator when isLoading=true', (tester) async {
    // Set _isLoading=true, verify CupertinoActivityIndicator present, Lock button absent
  });
  ```
  - Wrap in `MaterialApp` with `OnTaskTheme.light()` (established pattern from Story 6.7)
  - Use `ProviderContainer` override pattern for `commitmentContractsRepositoryProvider`

### Flutter: l10n strings (AC: 1)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Commitment lock ceremony (UX-DR8, UX-DR20, UX-DR32) ──` section:
  ```dart
  // ── Commitment lock ceremony (UX-DR8, UX-DR20, UX-DR32) ─────────────────────
  /// Eyebrow label on the full-screen Commitment Ceremony Card.
  static const String commitmentCeremonyEyebrow = 'YOUR COMMITMENT';

  /// Sub-copy on the Commitment Ceremony Card — future self voice (UX-DR32).
  static const String commitmentCeremonyCopy =
      'Your future self is counting on you.';

  /// Error shown if the lock API call fails (for future implementation).
  static const String lockConfirmError =
      'Could not lock your commitment. Please try again.';
  ```
  - NOTE: `AppStrings.stakeConfirmButton` ('Lock it in.') already exists — do NOT recreate
  - NOTE: `AppStrings.dialogErrorTitle`, `AppStrings.actionOk` already exist — do NOT recreate

### Flutter: Router — add `/commitment-lock` route (AC: 1, 2)

`LockConfirmationScreen` is currently navigated to via `Navigator.push` from `StakeSheetScreen` (programmatic push, consistent with the group commitment screens pattern from Story 6.7). No GoRouter deep-link route is required for Story 6.8. Document this in Dev Notes (same deferral as Story 6.7 group commitment screens).

- [x] No router changes required in this story — document in Dev Notes

## Dev Notes

### CRITICAL: `StakeSheetScreen` currently does not have `taskTitle` param — add it

`StakeSheetScreen` constructor currently only takes `taskId` and `existingStakeAmountCents`. Story 6.8 requires adding `taskTitle` (required `String`) to pass to `LockConfirmationScreen`. This is a breaking change. Find all call sites:
```bash
grep -rn "StakeSheetScreen(" apps/flutter/lib/
```
Update every call site. The widget is opened via `showCupertinoModalPopup` — the caller always has the task title available.

### CRITICAL: `_onConfirm` in `StakeSheetScreen` — preserve all existing error handling

The `_onConfirm` method in `StakeSheetScreen` (lines 121–147) has established error handling for `DioException` (422 → no payment method, other → generic error) and generic catch. When modifying `_onConfirm` to navigate to `LockConfirmationScreen`, preserve ALL existing error paths unchanged. Only the success path changes (navigate instead of pop).

### CRITICAL: Animation controller — check `disableAnimations` in `didChangeDependencies`, NOT `initState`

The `isReducedMotion` helper (`apps/flutter/lib/core/motion/motion_tokens.dart:40`) reads `MediaQuery.of(context).disableAnimations`. This must be called in `didChangeDependencies` (not `initState`) because `MediaQuery` is not available during `initState`. The established pattern is in `apps/flutter/lib/features/today/presentation/today_screen.dart` lines 620–625.

### CRITICAL: `HapticFeedback.heavyImpact()` on lock — heaviest haptic in the product

Per UX spec line 1527: "Lock it in." tap = `heavyImpact()`. This is the heaviest haptic in the entire product. The asymmetric haptic design is intentional (UX spec line 1368): "Light at initiation, heavy at commitment (vault close). Weight mirrors emotional stakes."

Existing haptic usage for reference:
- Stake slider zone threshold: `HapticFeedback.selectionClick()` (`stake_slider_widget.dart:145`)
- Now tab card complete: `HapticFeedback.mediumImpact()` (`now_task_card.dart:358`)
- Lock it in.: `HapticFeedback.heavyImpact()` (NEW — this story)

### CRITICAL: `onLock` fires AFTER animation completes, not on tap

The vault close animation is the confirmation — per UX spec line 1552: "the vault close animation serves as the confirmation — the animation plays on tap, the charge is committed when the animation completes." The `onLock` callback must be invoked in the `AnimationController.addStatusListener` when `status == AnimationStatus.completed`, NOT directly in the button's `onPressed`. The API call (and chapter-break navigation) happens after the animation ends.

### CRITICAL: `CommitmentRow.formatAmount` — reuse existing formatter

`apps/flutter/lib/features/now/presentation/widgets/commitment_row.dart` has `CommitmentRow.formatAmount(int cents)` which returns a formatted dollar string (e.g., `'$50'`). Import and use this for the stake amount display in `CommitmentCeremonyCard`. Do NOT reimplement currency formatting.

### CRITICAL: `PopScope(canPop: false)` on LockConfirmationScreen

The lock confirmation screen must prevent the user from accidentally navigating back via the iOS swipe-back gesture during the ceremony. Use `PopScope(canPop: false)` as the outermost widget. This is consistent with the `FarewellScreen` approach (which uses `pushAndRemoveUntil` to block back navigation).

### CRITICAL: New York font — system font, no bundle required

The `CommitmentCeremonyCard` uses New York font (`fontFamily: 'NewYorkSmall'`) for the task title and italic sub-copy. Per UX spec line 716: "Designed by Apple to pair with SF Pro; zero bundle cost; ships on all supported devices." No font asset registration required. For the italic sub-copy: `TextStyle(fontFamily: 'NewYorkSmall', fontStyle: FontStyle.italic, fontSize: 15)`.

### CRITICAL: `accentCompletion` vs `accentCommitment` colour tokens

- `colors.accentCommitment` = the dark background of the ceremony card (terracotta/dark commitment colour)
- `colors.accentCompletion` = the colour used for the stake amount text within the card (the "earned/positive" accent)
Check `apps/flutter/lib/core/theme/app_theme.dart` for the full `OnTaskColors` field list. The UX spec (line 1141) says the stake row uses `color.accent.completion` for the amount text.

### CRITICAL: `intl` package available for deadline formatting

The `intl` package was added in Story 6.6. Use `DateFormat('MMM d \'at\' h:mm a').format(deadline.toLocal())` for deadline display. Import: `import 'package:intl/intl.dart';`.

### CRITICAL: All routes use Navigator.push (not GoRouter) for this screen

`LockConfirmationScreen` is pushed from `StakeSheetScreen` using `Navigator.of(context).push(CupertinoPageRoute(...))`. This is consistent with the pattern used for `GroupCommitmentReviewScreen` (Story 6.7) — group commitment and lock ceremony screens are accessed programmatically, not via deep link. GoRouter route registration is deferred (noted in deferred items below).

### CRITICAL: `(x as num).toInt()` for JSON numerics — existing pattern

Not directly applicable to this story (no new API calls), but the pattern is established from Stories 6.1–6.7 for any future additions.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

No new Freezed models in this story, but if any existing models are touched, always run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
and commit all generated files.

### Architecture: `CommittedTaskDisplay` base widget — deferred refactoring

The UX spec (line 1318) envisions a shared `CommittedTaskDisplay` base widget used by both the `NowTaskCard` committed variant and the `CommitmentCeremonyCard`. In Story 6.8, implement `CommitmentCeremonyCard` directly without extracting `CommittedTaskDisplay`. The refactoring into a shared base widget is deferred to a future story when the committed Now tab card also needs to be updated. Document this decision with a `// TODO(refactor): extract CommittedTaskDisplay base widget` comment in `commitment_ceremony_card.dart`.

### Architecture: No new API endpoint in Story 6.8

Story 6.8 is a pure Flutter UI story. The "lock" action is the `PUT /v1/tasks/:taskId/stake` call already made in `StakeSheetScreen._onConfirm()`. The ceremony card is the UX ceremony around a call that already happened. A dedicated `POST /v1/tasks/:taskId/stake/lock` endpoint may be added in a future story when the server-side commitment contract immutability is implemented — add a `TODO(v2)` comment in `LockConfirmationScreen._performLock()`.

### Architecture: Group flow sequence is enforced by existing screen guards

The "cannot be skipped or reordered" AC for the group commitment flow (AC 2) is satisfied by:
1. `StakeSheetScreen` only enables "Lock it in." when stake ≥ $5 AND payment method exists
2. Group commitment requires `GroupCommitmentReviewScreen` to show unanimous approval before the pool mode section is visible
3. `LockConfirmationScreen` is only reachable after `setTaskStake` returns 200

No new flow-control logic is required. The ordering is enforced by the data dependencies between screens.

### Architecture: `NowTaskCard` committed variant already implemented

`apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` line 120: `final isCommitted = widget.task.stakeAmountCents != null;`. The dark surface (`accentCommitment`) already applies when the task has a stake. Story 6.8 AC 3 is verified by testing the existing code path, not implementing new code. The NowTaskCard widget test should confirm this.

### Architecture: File locations

New files to create:
```
apps/flutter/lib/features/commitment_contracts/presentation/widgets/commitment_ceremony_card.dart
apps/flutter/lib/features/commitment_contracts/presentation/lock_confirmation_screen.dart
apps/flutter/test/features/commitment_contracts/lock_confirmation_screen_test.dart
```

Modified files:
```
apps/flutter/lib/core/motion/motion_tokens.dart              — add vault close token constants
apps/flutter/lib/core/l10n/strings.dart                      — add commitment ceremony strings
apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart
                                                              — add taskTitle param, modify _onConfirm
apps/flutter/test/features/now/now_task_card_test.dart        — extend with committed variant test
```

### UX: "Lock it in." button style

Per UX spec line 1386: "Its own category. Full-width, `color.accent.commitment` fill (dark surface), `color.surface.primary` text, 14–15pt, New York italic. Used exclusively for the commitment lock action. Visual weight is heavier than primary — longer border-radius, slightly more padding. The period in 'Lock it in.' is part of the pattern — declarative, not exclamatory."

On the `CommitmentCeremonyCard` (dark surface), the button inverts: `colors.surfacePrimary` fill, `colors.accentCommitment` text.

### UX: Vault close animation — weighted closing arc

"The vault close" is described as a "Weighted closing arc, 600ms" (UX spec line 1700). Implement as a `FadeTransition` from `opacity: 1.0` to `opacity: 0.0` using a `CurvedAnimation` with `Curves.easeIn` (weighted — starts slow, accelerates out). Under Reduce Motion: `Curves.linear`, 100ms. The "arc" metaphor is expressed through the easing curve, not literal movement.

### UX: Ceremony card is full-screen, not a modal sheet

Unlike `StakeSheetScreen` (a bottom sheet), `LockConfirmationScreen` is a full-screen `CupertinoPageRoute`. This signals the register shift described in UX spec line 842: "the moment of locking in a stake should feel ceremonial — a visual register shift that signals: this is different."

### Deferred items (not in scope for Story 6.8)

- GoRouter deep-link route for `LockConfirmationScreen` — accessed via `Navigator.push` for now
- `CommittedTaskDisplay` base widget refactoring — ceremony card implements directly
- `POST /v1/tasks/:taskId/stake/lock` API endpoint — lock ceremony navigates to chapter-break without a separate lock call
- Deadline value from task API — `LockConfirmationScreen` currently receives deadline as a param; real task deadline integration is a task detail story
- "The release" motion token — separate story (Now tab task completion)

### Previous story learnings carried forward (Stories 6.1–6.7)

- TypeScript imports use `.js` extensions (not applicable to this Flutter-only story)
- Generated `.freezed.dart` and `.g.dart` files must be committed after `build_runner`
- Use `catch (e)` not `catch (_)` in all error handlers
- `OnTaskColors.surfacePrimary` for light backgrounds; `OnTaskColors.accentCommitment` for dark ceremony surface
- `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances
- All UI strings in `AppStrings`
- Widget tests: wrap in `MaterialApp` with `OnTaskTheme.light(ThemeVariant.clay, 'PlayfairDisplay')` (as established in Story 6.7 completion notes)
- Repository tests extend existing `commitment_contracts_repository_test.dart` (no new repository in this story)
- `isReducedMotion(context)` helper at `apps/flutter/lib/core/motion/motion_tokens.dart:40` — call in `didChangeDependencies`, not `initState`
- `intl` package available for date/currency formatting (added Story 6.6)
- `_isLoading = false` as default value in `ConsumerStatefulWidget` (not `true` — content is not auto-fetched on mount for this screen)
- Pool mode opt-in is separate from group approval (Story 6.7) — do not conflate them in ceremony flow

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Animation status listener test required mocking `SystemChannels.platform` for `HapticFeedback.heavyImpact()` — without the mock, the async method would not proceed past the `await` in tests.
- `didChangeDependencies` pattern used for `isReducedMotion(context)` as mandated by Dev Notes (MediaQuery not available during `initState`).

### Completion Notes List

- Added `MotionTokens.vaultCloseDurationMs = 600` and `MotionTokens.vaultCloseReducedMotionDurationMs = 100` to `motion_tokens.dart`; updated file-level comment to reflect vault close token is now implemented.
- Created `CommitmentCeremonyCard` widget with `FadeTransition` (easeIn 600ms), `HapticFeedback.heavyImpact()` on tap, `onLock` fires only after `AnimationStatus.completed`, full reduced-motion support via `isReducedMotion(context)` in `didChangeDependencies`.
- Created `LockConfirmationScreen` (`ConsumerStatefulWidget`) with `PopScope(canPop: false)`, dark `accentCommitment` scaffold background, navigates to `/chapter-break` via GoRouter `context.push` after ceremony animation completes.
- Modified `StakeSheetScreen._onConfirm` to navigate to `LockConfirmationScreen` (instead of `pop`) after `setTaskStake` succeeds. Added `taskTitle` required constructor param. Updated call site in `task_edit_inline.dart` and the test helper in `stake_sheet_screen_test.dart`.
- Added 3 l10n strings: `commitmentCeremonyEyebrow`, `commitmentCeremonyCopy`, `lockConfirmError`.
- NowTaskCard committed variant (AC 3) verified via widget test: `accentCommitment` background applied when `stakeAmountCents != null`, `CommitmentRow` renders `$25` and "at stake".
- Group commitment flow sequence (AC 2) is enforced by existing screen guards — no new orchestration code required.
- No GoRouter route registration for `LockConfirmationScreen` — deferred (consistent with Story 6.7 group commitment screens).
- All 5 new `lock_confirmation_screen_test.dart` tests pass; 1 new `now_task_card_test.dart` test added and passes; full regression suite (exit 0).

### File List

- apps/flutter/lib/core/motion/motion_tokens.dart (modified)
- apps/flutter/lib/core/l10n/strings.dart (modified)
- apps/flutter/lib/features/commitment_contracts/presentation/widgets/commitment_ceremony_card.dart (new)
- apps/flutter/lib/features/commitment_contracts/presentation/lock_confirmation_screen.dart (new)
- apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart (modified)
- apps/flutter/lib/features/tasks/presentation/widgets/task_edit_inline.dart (modified)
- apps/flutter/test/features/commitment_contracts/lock_confirmation_screen_test.dart (new)
- apps/flutter/test/features/commitment_contracts/stake_sheet_screen_test.dart (modified)
- apps/flutter/test/features/now/now_task_card_test.dart (modified)

### Change Log

- 2026-04-01: Story 6.8 implemented — full commitment lock flow and vault-close animation. Added MotionTokens vault close constants, CommitmentCeremonyCard widget, LockConfirmationScreen, wired StakeSheetScreen to navigate to ceremony before popping, added committed variant NowTaskCard test and lock confirmation screen tests.

### Review Findings

- [ ] [Review][Patch] `withOpacity()` deprecated — 5 instances in `CommitmentCeremonyCard` should use `.withValues(alpha:)` [commitment_ceremony_card.dart:128,164,177,188,201]
- [ ] [Review][Patch] `_isLoading=true` set after animation completes — card is at opacity 0 when spinner appears, making the loading state invisible to the user; restructure so `isLoading` is set before animation plays, or pass it as a separate `_locked` flag [lock_confirmation_screen.dart:54]
- [ ] [Review][Patch] `PopScope(canPop: false)` not directly asserted in tests — `lock_confirmation_screen_test.dart` verifies no `CupertinoNavigationBar` but does not assert `PopScope` presence [lock_confirmation_screen_test.dart:127-137]
- [x] [Review][Defer] `minSize` deprecated in `task_edit_inline.dart` (lines 670, 694) — deferred, pre-existing (exists in HEAD before Story 6.8; line shift of +1 is the only Story 6.8 impact)
- [x] [Review][Defer] `deadline` hardcoded as 30-days-from-now placeholder in `StakeSheetScreen._onConfirm` — deferred, documented in story Deferred Items; real task deadline integration is a separate story
