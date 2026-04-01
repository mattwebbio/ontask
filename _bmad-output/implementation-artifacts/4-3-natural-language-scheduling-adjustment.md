# Story 4.3: Natural Language Scheduling Adjustment

Status: review

## Story

As a user,
I want to adjust my schedule for the current task using a natural language input,
So that rescheduling feels like talking to an assistant rather than filling in a form.

## Acceptance Criteria

1. **Given** a task is shown in the Now or Today tab **When** the user opens the "Reschedule" input **Then** they can type a natural language adjustment: "move this to after lunch", "I need 30 more minutes", "push this to tomorrow" (FR14) **And** the system shows the proposed new slot for confirmation before applying it

2. **Given** the user confirms the adjustment **When** the rescheduling is applied **Then** the task's scheduled time is updated and the Google Calendar block is moved accordingly (Story 3.4)

## Tasks / Subtasks

### Flutter: Add "Reschedule with AI" entry point to `NowTaskCard`

- [x] Modify `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` (AC: 1)
  - [x] Add `VoidCallback? onNudge` parameter to `NowTaskCard` (alongside existing `onComplete`, `onStart`, `onPause`, `onStop`)
  - [x] When `onNudge` is non-null, add a "Reschedule with AI" `CupertinoButton` (text-style, secondary) in the action button area of the card, below or alongside the timer buttons (UX: do NOT add a swipe action on the card — the card does not use swipe; use a dedicated button)
  - [x] Button label: `AppStrings.todayRowNudge` (already exists: `'Reschedule with AI'`)
  - [x] Button calls `onNudge!()` on tap
  - [x] `minimumSize: const Size(44, 44)` on the button — `minSize` is deprecated
  - [x] All colours via `Theme.of(context).extension<OnTaskColors>()!` — use `colors.textSecondary` for secondary button text; no `backgroundPrimary` (does not exist)

- [x] Wire `onNudge` callback in `apps/flutter/lib/features/now/presentation/now_screen.dart` (AC: 1)
  - [x] Add import for `NudgeInputSheet` from `../../scheduling/presentation/widgets/nudge_input_sheet.dart`
  - [x] Pass `onNudge: () => _openNudgeSheet(task.id, task.title)` to `NowTaskCard`
  - [x] Implement `_openNudgeSheet(String taskId, String taskTitle)` method: calls `showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => NudgeInputSheet(taskId: taskId, taskTitle: taskTitle, onApplied: () { ref.read(nowProvider.notifier).refresh(); }))`
  - [x] `NowProvider` already has a `refresh()` method (check `now_provider.dart` — if absent, call `ref.invalidate(nowProvider)` instead)
  - [x] Do NOT add `useRootNavigator: true` unless testing reveals nested navigator issues

### Flutter: Ensure `TodayTaskRow` nudge entry point works for Today tab (AC: 1)

- [x] Verify `apps/flutter/lib/features/today/presentation/today_screen.dart` already passes `onNudge` to all `TodayTaskRow` instances (Story 3.7 implemented this — do NOT re-implement)
  - [x] Confirm `NudgeInputSheet` is already imported in `today_screen.dart`
  - [x] Confirm `onApplied` callback calls `todayProvider.refresh()` or equivalent
  - [x] If `onNudge` wiring is already in place: no changes needed to `today_screen.dart`

### Flutter: l10n Strings

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under the existing `// ── Scheduling nudge (FR14) ──` section (AC: 1)
  - [x] `nowCardNudgeButton = 'Reschedule with AI'` — label for the Now card button (if `todayRowNudge` is not semantically reusable for a card button, add a card-specific string; if the same string works, reuse `todayRowNudge`)
  - [x] Check: `todayRowNudge = 'Reschedule with AI'` (line 610) already exists — reuse it for the Now card button unless UX specifies different copy

### Tests

- [x] Write widget tests for `NowTaskCard` nudge integration in `apps/flutter/test/features/now/now_task_card_nudge_test.dart` (AC: 1)
  - [x] When `onNudge` is null: "Reschedule with AI" button is NOT visible
  - [x] When `onNudge` is non-null: "Reschedule with AI" button IS visible
  - [x] Tapping "Reschedule with AI" fires `onNudge` callback
  - [x] Follow existing `now_task_card_timer_test.dart` pattern for widget setup: plain `ProviderScope` (no overrides needed if `NowTaskCard` doesn't directly watch providers — it's a `StatefulWidget` not `ConsumerWidget`)
  - [x] If the test helper mounts `NowScreen` (instead of bare `NowTaskCard`), add `nowProvider` override with stub notifier to prevent real Dio network calls (same pattern as `listsProvider`/`tasksProvider` stub notifiers from Stories 4.1 and 4.2)

- [x] Verify existing `nudge_input_sheet_test.dart` passes unchanged (AC: 1, 2)
  - [x] No changes to `NudgeInputSheet` widget itself — it already handles proposal and confirm flows from Story 3.7
  - [x] Existing sheet tests at `apps/flutter/test/features/scheduling/nudge_input_sheet_test.dart` must continue to pass

## Dev Notes

### CRITICAL: Story 3.7 already built the entire nudge backend and Flutter sheet — do NOT re-implement

Story 3.7 (done) implemented:
- `packages/ai/src/nudge-parser.ts` — `parseSchedulingNudge()` (DONE — do not touch)
- `apps/api/src/routes/scheduling.ts` — `POST /v1/tasks/:id/schedule/nudge` and `POST /v1/tasks/:id/schedule/nudge/confirm` (DONE — do not touch)
- `apps/flutter/lib/features/scheduling/presentation/widgets/nudge_input_sheet.dart` — `NudgeInputSheet` widget (DONE — do not touch)
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` — `proposeNudge()` and `confirmNudge()` methods (DONE — do not touch)
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` — `onNudge` callback on `TodayTaskRow` (DONE — do not touch)
- `apps/flutter/lib/features/today/presentation/today_screen.dart` — already wires `onNudge` to open `NudgeInputSheet` (DONE — verify and do not duplicate)

Story 4.3 ONLY adds the Now tab entry point to the existing nudge infrastructure. The scope is:
1. Add `onNudge` callback to `NowTaskCard`
2. Wire it in `NowScreen` to open the existing `NudgeInputSheet`
3. Tests for the new `NowTaskCard` callback

### CRITICAL: `NudgeInputSheet` is already complete — do NOT modify it

`apps/flutter/lib/features/scheduling/presentation/widgets/nudge_input_sheet.dart` accepts `taskId`, `taskTitle`, and optional `onApplied`. It handles all states: idle → loading → proposal/low-confidence/error. When user taps "Apply", it calls `schedulingRepository.confirmNudge()` and then calls `onApplied`. Pass `onApplied: () => ref.invalidate(nowProvider)` (or equivalent refresh) to update the Now card after confirmation.

### CRITICAL: `NowTaskCard` is a `StatefulWidget`, not `ConsumerWidget`

`NowTaskCard` at `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` is a `StatefulWidget`. It does NOT read providers directly. All data flows in via constructor params. Add `VoidCallback? onNudge` as a constructor param — same pattern as `onComplete`, `onStart`, `onPause`, `onStop`.

### CRITICAL: `NowScreen` owns provider access — wire nudge there

`NowScreen` at `apps/flutter/lib/features/now/presentation/now_screen.dart` is a `ConsumerStatefulWidget` with access to `ref`. It constructs `NowTaskCard` and passes all callbacks. Add `onNudge` here:

```dart
return NowTaskCard(
  task: task,
  timerRunning: timerState.isRunning,
  timerElapsedSeconds: elapsed,
  onComplete: () { ... },
  onStart: () { ... },
  onPause: () { ... },
  onStop: () { ... },
  onNudge: () => _openNudgeSheet(task.id, task.title),  // ADD THIS
);
```

### CRITICAL: `showModalBottomSheet` import — use Material, not Cupertino

`showModalBottomSheet` is a Material widget. `NowScreen` currently imports only `package:flutter/cupertino.dart`. You must add `import 'package:flutter/material.dart' show showModalBottomSheet, Colors;` (selective import). The rest of the app uses this pattern — see `today_screen.dart` for reference.

### CRITICAL: `nowProvider.notifier.refresh()` — confirm the method name

Before using `ref.read(nowProvider.notifier).refresh()`, check `apps/flutter/lib/features/now/presentation/now_provider.dart` for the exact method name. If no `refresh()` method exists, use `ref.invalidate(nowProvider)` instead to trigger a reload. Do NOT call `ref.refresh(nowProvider)` (deprecated in newer Riverpod).

### CRITICAL: `NudgeInputSheet` import path from `NowScreen`

The `NudgeInputSheet` is in the `scheduling` feature, not the `now` feature. The correct relative import from `now_screen.dart` is:

```dart
import '../../scheduling/presentation/widgets/nudge_input_sheet.dart';
```

This matches the pattern already used in `today_screen.dart` (confirm the exact relative path before implementing).

### CRITICAL: `OnTaskColors` — use `surfacePrimary` not `backgroundPrimary`

Repeated from Stories 3.6, 3.7, 4.1, 4.2: `OnTaskColors` does NOT have `backgroundPrimary`. Use `colors.surfacePrimary` for backgrounds, `colors.textSecondary` for secondary text/buttons. The `NowTaskCard` already follows this pattern.

### CRITICAL: `minimumSize` not `minSize` on `CupertinoButton`

`minSize` is deprecated. Use:
```dart
CupertinoButton(
  minimumSize: const Size(44, 44),
  onPressed: onNudge,
  child: Text(AppStrings.todayRowNudge),
)
```

### API: No backend changes needed

All backend endpoints (`POST /v1/tasks/:id/schedule/nudge` and `/nudge/confirm`) are already implemented and working from Story 3.7. Zero changes to `apps/api/` are required for this story.

### No new packages/ai changes needed

`parseSchedulingNudge()` in `packages/ai/src/nudge-parser.ts` is already complete from Story 3.7. Zero changes to `packages/ai/` are required.

### No new `SchedulingRepository` changes needed

`proposeNudge()` and `confirmNudge()` are already implemented in `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` from Story 3.7.

### Widget test setup for `NowTaskCard` nudge tests

`NowTaskCard` is a plain `StatefulWidget` with no provider reads. Widget tests do NOT need Riverpod overrides for the bare `NowTaskCard`. Follow `now_task_card_timer_test.dart` pattern:

```dart
Widget buildCard({required NowTask task, VoidCallback? onNudge}) {
  return ProviderScope(
    child: CupertinoApp(
      home: CupertinoPageScaffold(
        child: NowTaskCard(
          task: task,
          onNudge: onNudge,
        ),
      ),
    ),
  );
}
```

If tests mount `NowScreen` instead, add `nowProvider` override with a stub notifier that prevents real Dio network calls (same pattern as `listsProvider`/`tasksProvider` stubs in `add_tab_nlp_test.dart` and `guided_chat_sheet_test.dart`).

### UX: Button placement on `NowTaskCard`

The `NowTaskCard` uses a centred layout with timer action buttons. The "Reschedule with AI" nudge button should appear as a secondary text-style button below the main timer/completion actions. It must not compete visually with the primary "Mark Done" or timer start/pause buttons. Use `CupertinoButton` with no fill (plain text style) or with `colors.surfaceSecondary` background for minimal visual weight.

### Pre-existing tests: verify Today tab nudge tests still pass

Story 3.7 added tests in `apps/flutter/test/features/scheduling/nudge_input_sheet_test.dart` and `apps/flutter/test/features/today/today_reveal_animation_test.dart`. Story 4.3 does NOT touch those files. All pre-existing tests must pass unchanged.

### Files to Create / Modify

**Modify (apps/flutter — now feature):**
- `apps/flutter/lib/features/now/presentation/now_screen.dart` — add `onNudge` wiring + `_openNudgeSheet()` method + `NudgeInputSheet` import
- `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` — add `onNudge` callback param + button in action area

**Modify (apps/flutter — l10n, if needed):**
- `apps/flutter/lib/core/l10n/strings.dart` — add Now-card-specific nudge string only if `todayRowNudge` is not appropriate for card context (likely reuse existing string, no new entry needed)

**New (apps/flutter tests):**
- `apps/flutter/test/features/now/now_task_card_nudge_test.dart` — widget tests for nudge button visibility and callback

**Update (sprint tracking):**
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — update `4-3-natural-language-scheduling-adjustment` from `backlog` to `ready-for-dev`

### Project Structure Notes

- `NudgeInputSheet` is owned by the `scheduling` feature at `apps/flutter/lib/features/scheduling/presentation/widgets/` — it is shared between Now and Today tabs; do NOT move it
- The Now tab lives at `apps/flutter/lib/features/now/` — changes are confined to `now_screen.dart` and `now_task_card.dart`
- No new files in `packages/ai/`, `packages/scheduling/`, or `apps/api/` required

### References

- FR14: Users can adjust scheduled tasks using natural language nudges
- Story 3.7 Dev Notes — complete nudge infrastructure: `parseSchedulingNudge()`, `NudgeInputSheet`, `proposeNudge()`, `confirmNudge()`, `POST /v1/tasks/:id/schedule/nudge`, `POST /v1/tasks/:id/schedule/nudge/confirm`
- Story 3.7 Completion Notes — `POST /v1/tasks/:id/schedule/nudge` is proposal-only (no DB writes); `/confirm` commits and syncs Google Calendar
- `apps/flutter/lib/features/scheduling/presentation/widgets/nudge_input_sheet.dart` — complete `NudgeInputSheet` (do NOT modify)
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` — `proposeNudge()` and `confirmNudge()` already implemented
- `apps/flutter/lib/features/now/presentation/now_screen.dart` — `NowScreen` (`ConsumerStatefulWidget`) — wire `onNudge` here
- `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` — `NowTaskCard` (`StatefulWidget`) — add `onNudge` param
- `apps/flutter/lib/features/today/presentation/today_screen.dart` — reference for how `onNudge` is wired to open `NudgeInputSheet` (authoritative wiring pattern to replicate)
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` — `onNudge` callback already on `TodayTaskRow` (Story 3.7)
- `apps/flutter/lib/core/l10n/strings.dart` line 610 — `todayRowNudge = 'Reschedule with AI'` (existing — reuse)
- `apps/flutter/test/features/now/now_task_card_timer_test.dart` — authoritative `NowTaskCard` widget test pattern
- Story 4.1 Debug Log item 5 — widget tests need Riverpod overrides for `listsProvider` and `tasksProvider` stub notifiers to prevent real Dio network calls (only needed if mounting `NowScreen`, not bare `NowTaskCard`)
- `RunScheduleOptions.dryRun: true` — skips calendar sync for proposal-only (already used in nudge endpoint; no changes needed)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Confirmed `NowProvider.refresh()` exists in `now_provider.dart` — used directly rather than `ref.invalidate(nowProvider)`
- Confirmed `today_screen.dart` already has full `onNudge` wiring from Story 3.7 — no changes needed to Today tab
- `todayRowNudge = 'Reschedule with AI'` at line 610 in `strings.dart` reused as-is for Now card button — identical copy, no new string needed
- Used `MaterialApp` wrapper (not `CupertinoApp`) in widget tests to match existing `now_task_card_timer_test.dart` pattern — bare `NowTaskCard` needs no provider overrides

### Completion Notes List

- Added `VoidCallback? onNudge` param to `NowTaskCard` with `minimumSize: const Size(44, 44)` button using `colors.textSecondary` for text colour, rendered below the primary CTA only when `onNudge != null`
- Wired `onNudge` in `NowScreen._openNudgeSheet()` using `showModalBottomSheet` with `Colors.transparent` background; `onApplied` calls `ref.read(nowProvider.notifier).refresh()`
- Added selective Material import `show Colors, showModalBottomSheet` to `now_screen.dart` (same pattern as `today_screen.dart`)
- Verified Today tab `onNudge` wiring already complete from Story 3.7 — no changes made
- 3 new widget tests in `now_task_card_nudge_test.dart`: null/non-null visibility + tap callback — all pass
- All 88 now-feature tests pass; scheduling and today feature regression tests pass (exit code 0)

### File List

- apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart (modified)
- apps/flutter/lib/features/now/presentation/now_screen.dart (modified)
- apps/flutter/test/features/now/now_task_card_nudge_test.dart (new)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)
- _bmad-output/implementation-artifacts/4-3-natural-language-scheduling-adjustment.md (modified)

## Change Log

- 2026-03-31: Story 4.3 implemented — added `onNudge` callback to `NowTaskCard`, wired `_openNudgeSheet()` in `NowScreen`, added 3 widget tests for nudge button visibility and callback. No backend, l10n, or Today tab changes required.
