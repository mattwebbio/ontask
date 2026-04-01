# Story 7.1: Proof Capture Modal Foundation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want a single, consistent entry point for submitting proof regardless of proof type,
so that verification feels streamlined rather than scattered across different flows.

## Acceptance Criteria

1. **Given** a user completes a task that requires proof or chooses to verify
   **When** the Proof Capture Modal opens
   **Then** the modal is a bottom sheet showing four proof path options: Photo/Video, HealthKit Auto, Screenshot/Document, Offline
   **And** the Offline option is shown only when the device is offline
   **And** the user can navigate between proof paths and back out to the path selector
   **And** dismissing the modal without submitting leaves the task in "pending completion" state — no proof is lost
   (UX-DR11)

2. **Given** the modal is rendered on macOS
   **When** the proof paths are displayed
   **Then** the HealthKit option is hidden with no broken affordances
   **And** Watch Mode is not referenced in any macOS modal copy

## Tasks / Subtasks

### Flutter: Create `proof/` feature directory skeleton (AC: 1, 2)

- [x] Create directory `apps/flutter/lib/features/proof/` with `data/`, `domain/`, and `presentation/` subdirectories
  - [x] Create `apps/flutter/lib/features/proof/domain/proof_path.dart` — enum `ProofPath { photo, healthKit, screenshot, offline }` with `fromJson`/`toJson`; use same pattern as `ProofMode` enum in `apps/flutter/lib/features/now/domain/proof_mode.dart`
  - [x] Create `apps/flutter/lib/features/proof/domain/proof_submission_state.dart` — sealed class or Freezed model representing states: `idle`, `pathSelected(ProofPath path)`, `submitted`, `dismissed`

### Flutter: `ProofCaptureModal` — path selector bottom sheet (AC: 1, 2)

- [x] Create `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`
  - [x] `ConsumerStatefulWidget`, internal `_selectedPath` nullable, starts at path selector view
  - [x] Presented via `showCupertinoModalPopup` (consistent with `CharitySheetScreen`, `StakeSheetScreen` — see `apps/flutter/lib/features/commitment_contracts/presentation/charity_sheet_screen.dart:17-20`)
  - [x] Anatomy: `CupertinoActionSheet`-style bottom sheet (partial cover — task card remains visible above), title "Submit proof for [taskName]", four path option rows
  - [x] **Path option rows** — each row: leading icon + title + subtitle; use `CupertinoListTile` or custom `GestureDetector` row matching visual style of `CharitySheetScreen` list rows
    - Photo/Video: `CupertinoIcons.camera` · "Photo or Video" · "Capture with your camera"
    - HealthKit Auto: `CupertinoIcons.heart` · "HealthKit" · "Auto-verify from Apple Health" — **hidden on macOS** (see macOS guard below)
    - Screenshot/Document: `CupertinoIcons.doc` · "Screenshot or Document" · "Upload PNG, JPG, or PDF"
    - Offline: `CupertinoIcons.wifi_slash` · "Save for Later" · "Proof saved — will sync when you're back online" — **shown only when device is offline**
  - [x] Tapping a path row: set `_selectedPath`, show stub sub-view (placeholder `Text` + back button for now — full impl in Stories 7.2–7.6)
  - [x] Back button from sub-view returns to path selector (sets `_selectedPath = null`)
  - [x] Swipe-down / explicit cancel: dismiss with `Navigator.pop(context, null)` — returns `null` (no proof submitted); task stays in pending completion
  - [x] **macOS platform guard:** wrap HealthKit row in `if (!Platform.isMacOS)` — import `dart:io` show Platform (established pattern in `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart:1`)
  - [x] **Offline detection:** use `Connectivity` package (already in pubspec as `connectivity_plus: ^6.1.4`); show Offline path only when `ConnectivityResult.none`
  - [x] Accessibility: VoiceOver focus on sheet heading "Submit proof for [taskName]" on open (per UX spec `ux-design-specification.md` line 1679 focus management table)
  - [x] All user-visible strings in `AppStrings` (no hardcoded strings)

### Flutter: Wire `ProofCaptureModal` into `NowTaskCard` (AC: 1)

- [x] Modify `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart`
  - [x] In `_buildCta` (line 348), replace the `// For photo + watchMode: stub proof flow (Epic 7)` comment (line 360) with a real `showCupertinoModalPopup` call that opens `ProofCaptureModal`
  - [x] Pass `taskName: widget.task.title` to `ProofCaptureModal`
  - [x] Pass `proofMode: widget.task.proofMode` to `ProofCaptureModal` (so modal can default-select the pre-set path if applicable)
  - [x] Import `proof_capture_modal.dart`; do NOT inline the modal logic into `now_task_card.dart`
  - [x] On modal return: if result is non-null (proof submitted), call `widget.onComplete?.call()` — otherwise do nothing (task stays in pending completion)

### Flutter: l10n strings (AC: 1, 2)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Proof Capture Modal (FR31, Story 7.1) ──` section:
  ```dart
  // ── Proof Capture Modal (FR31, Story 7.1) ────────────────────────────────────
  /// Sheet title — "Submit proof for [task name]"
  static const String proofModalTitle = 'Submit proof for';

  /// Photo/Video path title.
  static const String proofPathPhotoTitle = 'Photo or Video';
  /// Photo/Video path subtitle.
  static const String proofPathPhotoSubtitle = 'Capture with your camera';

  /// HealthKit Auto path title (iOS only — hidden on macOS).
  static const String proofPathHealthKitTitle = 'HealthKit';
  /// HealthKit Auto path subtitle.
  static const String proofPathHealthKitSubtitle = 'Auto-verify from Apple Health';

  /// Screenshot/Document path title.
  static const String proofPathScreenshotTitle = 'Screenshot or Document';
  /// Screenshot/Document path subtitle.
  static const String proofPathScreenshotSubtitle = 'Upload PNG, JPG, or PDF';

  /// Offline path title (shown only when device is offline).
  static const String proofPathOfflineTitle = 'Save for Later';
  /// Offline path subtitle.
  static const String proofPathOfflineSubtitle = "Proof saved — will sync when you're back online";

  /// Back button label in sub-view.
  static const String proofModalBack = 'Back';

  /// Stub sub-view placeholder (shown until Stories 7.2–7.6 implement real sub-views).
  static const String proofPathComingSoon = 'This proof path is coming soon.';
  ```

### Flutter: Tests (AC: 1, 2)

- [x] Create `apps/flutter/test/features/proof/proof_capture_modal_test.dart` (new file)
  - [x] Wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')` (established pattern — `billing_history_screen_test.dart:34-35`)
  - [x] Tests:
    ```dart
    testWidgets('shows four path options on iOS (photo, healthkit, screenshot, offline-when-offline)', (tester) async { ... })
    testWidgets('hides HealthKit option on macOS', (tester) async { ... })
    testWidgets('shows Offline option only when device is offline', (tester) async { ... })
    testWidgets('tapping a path shows sub-view and back button', (tester) async { ... })
    testWidgets('tapping back from sub-view returns to path selector', (tester) async { ... })
    testWidgets('dismissing modal without selecting a path returns null', (tester) async { ... })
    ```

## Dev Notes

### CRITICAL: Feature goes in `apps/flutter/lib/features/proof/` — NOT anywhere else

Architecture explicitly assigns FR31-32, FR35-38 to `apps/flutter/lib/features/proof/` and FR33-34 to `apps/flutter/lib/features/watch_mode/`. Story 7.1 ONLY creates the `proof/` feature. Do NOT create a `watch_mode/` directory — that is Epic 7, Story 7.4. Do NOT put proof modal code in `now/` or `commitment_contracts/` features.

### CRITICAL: `showCupertinoModalPopup` — established modal pattern

ALL modal bottom sheets in this app use `showCupertinoModalPopup` (see `commitment_contracts/presentation/charity_sheet_screen.dart`, `tasks/presentation/widgets/task_edit_inline.dart`, `tasks/presentation/widgets/task_row.dart`). Do NOT use `showModalBottomSheet` (Material) or `showGeneralDialog`. The modal is not a full-screen push — it is a partial-cover bottom sheet, task card visible behind.

### CRITICAL: Platform guard for HealthKit — `dart:io` Platform, NOT `kIsWeb`

Use `import 'dart:io' show Platform;` and `Platform.isMacOS` to hide HealthKit. This is the established pattern (`apps/flutter/lib/features/lists/presentation/list_detail_screen.dart:1` and `apps/flutter/lib/features/shell/presentation/app_shell.dart:1`). Do NOT use `Theme.of(context).platform` or `defaultTargetPlatform` — those are unreliable in tests. `dart:io Platform` matches how the macOS shell guard is done.

### CRITICAL: No proof logic in `NowTaskCard` — delegate to `ProofCaptureModal`

`now_task_card.dart` already has a `// For photo + watchMode: stub proof flow (Epic 7)` comment at line 360. Replace only that stub comment with a `showCupertinoModalPopup` call. The modal owns all proof logic. `NowTaskCard` only handles the CTA tap and the result (complete vs. no-op). Keep `NowTaskCard` thin.

### CRITICAL: Pending completion semantics — dismissal = no state change

When the modal is dismissed without submitting (swipe-down, back navigation out of path selector), the task stays in its current state. Do NOT call `widget.onComplete()`. Do NOT change task status to anything. The "pending completion" state is the normal Now tab task-in-progress state — it is not a new DB state that needs to be written. This is purely a UI concern for Story 7.1.

### CRITICAL: `withValues(alpha:)` — NOT `withOpacity()`

`withOpacity()` is deprecated. Use `.withValues(alpha: value)` for all colour opacity adjustments. Flagged in Story 6.8 review (5 instances). Propagated from Story 6.9 dev notes.

### CRITICAL: All UI strings in `AppStrings` — no hardcoded strings

Every user-visible string including sheet title, path labels, subtitles, placeholder text must come from `AppStrings`. Add under a `// ── Proof Capture Modal (FR31, Story 7.1) ──` section per convention.

### CRITICAL: `minimumSize: const Size(44, 44)` on all interactive elements

All `CupertinoButton` instances and custom tap targets require minimum 44×44pt touch target. This is enforced across all Epic 6 screens and is a project-wide invariant.

### Architecture: `apps/flutter/lib/features/proof/` structure

```
apps/flutter/lib/features/proof/
├── data/
│   └── (empty for Story 7.1 — repository added in 7.2+)
├── domain/
│   ├── proof_path.dart           # NEW — ProofPath enum
│   └── proof_submission_state.dart  # NEW — sealed state model
└── presentation/
    └── proof_capture_modal.dart  # NEW — ProofCaptureModal widget
```

### Architecture: Bottom sheet anatomy (UX spec §7, line 1187–1198)

The UX spec defines the Proof Capture Modal as:
> "Bottom sheet (modal, partial cover — task card visible at top) → camera viewfinder → capture button → retake / submit → AI verification result"

For Story 7.1, only the **path selector layer** is built — the inner sub-views (camera viewfinder, HealthKit flow etc.) are stubs. Each sub-view shows a placeholder until Stories 7.2–7.6 are implemented.

The sheet heading must receive VoiceOver focus on open: `"Submit proof for [task name]"` — per UX spec accessibility table (line 1679).

### Architecture: Modal presentation from `NowTaskCard`

`NowTaskCard._buildCta` (line 348–382) already wires `onComplete` for mark-done. The photo and watchMode CTAs currently call `widget.onComplete?.call()` as a stub (line 361). Story 7.1 changes the `ProofMode.photo` case to open the modal instead. `ProofMode.watchMode` is not wired to the proof modal — Watch Mode has its own session flow (Story 7.4). Story 7.1 only replaces the `ProofMode.photo` CTA stub.

`ProofMode` enum lives at `apps/flutter/lib/features/now/domain/proof_mode.dart`. Do NOT move or duplicate it.

### Architecture: `ProofPath` vs `ProofMode`

- **`ProofMode`** (existing, `now/domain/proof_mode.dart`) — the verification mode selected when a task is created/locked. Drives the CTA label on `NowTaskCard`. Do NOT modify.
- **`ProofPath`** (new, `proof/domain/proof_path.dart`) — the path chosen inside the Proof Capture Modal. A `photo` ProofMode opens the modal, and within the modal the user selects which path to use (Photo/Video, Screenshot, HealthKit, Offline).

### Architecture: Offline detection

If `connectivity_plus` is already in `apps/flutter/pubspec.yaml`, use `Connectivity().checkConnectivity()`. If not present, add it — it is referenced in the architecture for offline proof queue (ARCH-26, FR37). Check `pubspec.yaml` before adding. The Offline path tile must only appear when `ConnectivityResult.none` is returned.

### Architecture: No new router entries

`ProofCaptureModal` is NOT a GoRouter route. It is presented modally only. Do NOT add any entry to `apps/flutter/lib/core/router/`. This is consistent with `CharitySheetScreen` (line 20: "NOT added to AppRouter").

### Architecture: API route for proof submissions

The API proof endpoints will live in `apps/api/src/routes/proof.ts` (FR31-41) — this file does not yet exist for Story 7.1. Story 7.1 is purely the Flutter modal shell with no API calls. The Hono `proof.ts` route is wired in Stories 7.2+.

### UX: Four proof paths, display conditions

| Path | Icon | Visible |
|---|---|---|
| Photo/Video | `CupertinoIcons.camera` | Always (iOS + macOS) |
| HealthKit | `CupertinoIcons.heart` | iOS only (`!Platform.isMacOS`) |
| Screenshot/Document | `CupertinoIcons.doc` | Always (iOS + macOS) |
| Offline | `CupertinoIcons.exclamationmark_wifi` or `wifi_slash` | Only when `ConnectivityResult.none` |

macOS must show Photo/Video and Screenshot/Document only. No broken affordances — the HealthKit row is simply absent.

### UX: Sheet presentation style

UX spec (line 1452): "Used for: Guided chat input, proof capture, charity selection, payment setup. Standard iOS bottom sheet presentation. Swipe-down to dismiss. Never used for destructive confirmations."

The sheet is presented as a `CupertinoActionSheet`-style modal or custom `Container` inside `showCupertinoModalPopup`. The task card must remain visible at the top — partial cover, not full screen.

### UX: No New York serif in modal copy

All modal text is SF Pro. New York serif is used only in Now tab hero title, attribution copy, and high-stakes emotional moments (UX spec line 1467–1474). Proof modal copy is functional UI — SF Pro throughout.

### Previous Story Learnings (from Stories 6.7–6.9, carried forward)

- TypeScript imports use `.js` extensions throughout `apps/api/` — relevant when proof API routes are added in 7.2+
- Generated `.freezed.dart` and `.g.dart` files must be committed after `build_runner` (if Freezed is used for `proof_submission_state.dart`)
- Use `catch (e)` not `catch (_)` in all error handlers
- `OnTaskColors.surfacePrimary` for light backgrounds; `OnTaskColors.accentPrimary` for accent stroke
- `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances
- All UI strings in `AppStrings`
- Widget tests: wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')` (established in Story 6.7, confirmed in Story 6.9 billing_history_screen_test.dart)
- `withValues(alpha:)` NOT `withOpacity()` — `withOpacity()` is deprecated (Story 6.8 review finding)
- No GoRouter route registration — modal bottom sheets use `showCupertinoModalPopup` only
- `(value as num).toInt()` for JSON numeric fields — not needed in 7.1 (no API calls) but carry forward to 7.2+
- `isReducedMotion(context)` in `didChangeDependencies` — relevant in 7.2 where verification spinner plays
- `dart:io` `Platform.isMacOS` for platform guards (not `defaultTargetPlatform`)

### Deferred items (not in scope for Story 7.1)

- Actual camera capture / photo upload — Story 7.2
- HealthKit permission request and auto-verification — Story 7.5
- Screenshot/document upload — Story 7.3
- Offline proof queue and sync — Story 7.6
- AI verification pipeline, pulsing arc animation (UX-DR30) — Story 7.2
- `apps/api/src/routes/proof.ts` API route file — Story 7.2+
- Watch Mode session overlay — Story 7.4 (`apps/flutter/lib/features/watch_mode/`)
- Proof retention settings (FR38) — Story 7.7
- Dispute flow (FR39, FR40) — separate story (Epic 7)
- `packages/core/schema/proof.ts` DB schema — deferred until Story 7.2 API work

### Project Structure Notes

- `apps/flutter/lib/features/proof/` does not yet exist — create it fresh in this story
- `ProofMode` enum already exists at `apps/flutter/lib/features/now/domain/proof_mode.dart` — read it, do not duplicate
- `showCupertinoModalPopup` is the only modal pattern used in this codebase — never `showModalBottomSheet`
- `dart:io` Platform guard pattern confirmed in `list_detail_screen.dart` and `app_shell.dart`
- Test pattern confirmed in `billing_history_screen_test.dart` (Story 6.9)

### References

- UX spec §7 Proof Capture Modal: [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 1187–1198
- UX spec §4 Modal sheets: [`_bmad-output/planning-artifacts/ux-design-specification.md`] line 1452
- UX spec accessibility focus management table: [`_bmad-output/planning-artifacts/ux-design-specification.md`] line 1679
- UX spec proof submission flows: [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 188–203
- Architecture Flutter `proof/` directory: [`_bmad-output/planning-artifacts/architecture.md`] line 870
- Architecture `apps/api/src/routes/proof.ts`: [`_bmad-output/planning-artifacts/architecture.md`] line 736
- `ProofMode` enum (existing): [`apps/flutter/lib/features/now/domain/proof_mode.dart`]
- `ProofModeIndicator` widget (existing): [`apps/flutter/lib/features/now/presentation/widgets/proof_mode_indicator.dart`]
- `NowTaskCard._buildCta` stub comment (line 360): [`apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart`]
- `CharitySheetScreen` modal pattern: [`apps/flutter/lib/features/commitment_contracts/presentation/charity_sheet_screen.dart`]
- Platform guard pattern: [`apps/flutter/lib/features/lists/presentation/list_detail_screen.dart`] line 1
- Previous story dev notes: [`_bmad-output/implementation-artifacts/6-9-billing-history-api-contract-status.md`]
- Epic 7 story definition: [`_bmad-output/planning-artifacts/epics.md`] line 1726

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `CupertinoIcons.exclamationmark_wifi` does not exist in this Flutter SDK version; used `CupertinoIcons.wifi_slash` instead (confirmed by checking icons.dart).

### Completion Notes List

- Created `apps/flutter/lib/features/proof/` directory skeleton with `data/`, `domain/`, and `presentation/` subdirectories.
- Implemented `ProofPath` enum mirroring the `ProofMode` pattern with `fromJson`/`toJson`.
- Implemented `ProofSubmissionState` sealed class with four states: `idle`, `pathSelected`, `submitted`, `dismissed`.
- Created `ProofCaptureModal` as a `ConsumerStatefulWidget` bottom sheet: path selector with four rows (Photo/Video, HealthKit iOS-only, Screenshot, Offline-only-when-offline), stub sub-views with back button, VoiceOver focus on heading, all strings from `AppStrings`, `dart:io Platform.isMacOS` guard, `connectivity_plus` offline detection.
- Wired `ProofCaptureModal` into `NowTaskCard._buildCta` for `ProofMode.photo` — other modes still call `onComplete` directly.
- Added 13 new `AppStrings` constants under `// ── Proof Capture Modal (FR31, Story 7.1) ──`.
- 7 widget tests pass; full suite (700+ tests) passes with exit code 0; `flutter analyze` reports no issues.

### File List

- `apps/flutter/lib/features/proof/domain/proof_path.dart` (new)
- `apps/flutter/lib/features/proof/domain/proof_submission_state.dart` (new)
- `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart` (new)
- `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` (modified)
- `apps/flutter/lib/core/l10n/strings.dart` (modified)
- `apps/flutter/test/features/proof/proof_capture_modal_test.dart` (new)
- `_bmad-output/implementation-artifacts/7-1-proof-capture-modal-foundation.md` (updated)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (updated)

## Change Log

- 2026-04-01: Story 7.1 implemented — proof feature directory skeleton, ProofPath enum, ProofSubmissionState sealed class, ProofCaptureModal bottom sheet with platform/connectivity guards, NowTaskCard wiring, l10n strings, and 7 widget tests. (claude-sonnet-4-6)
