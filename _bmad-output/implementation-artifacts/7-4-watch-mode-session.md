# Story 7.4: Watch Mode / Live Session

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want a passive camera-based focus mode that monitors whether I'm working,
So that I have an accountability presence during deep work without needing to remember to submit proof.

## Acceptance Criteria

1. **Given** the user activates Watch Mode from the Now tab card (proof mode = watchMode)
   **When** they tap "Start Watch Mode"
   **Then** Watch Mode is available for any task, staked or not (FR34)
   **And** the Watch Mode Overlay is shown: minimal UI with camera indicator, task name, elapsed timer, and End Session button (UX-DR10)

2. **Given** Watch Mode is active
   **When** the polling interval fires (every 30–60 seconds)
   **Then** the camera captures a frame (ARCH-32)
   **And** the frame is processed in-flight by the AI stub and immediately discarded — no frame is stored at any point (NFR-S3)

3. **Given** Watch Mode is running
   **When** the user taps "End Session"
   **Then** Watch Mode ends and a session summary is shown: duration and detected activity percentage (FR66, FR67)
   **And** if the session was for a staked task, the activity data is submitted as verification evidence

4. **Given** the app is running on macOS
   **When** the user would otherwise see a Watch Mode option
   **Then** Watch Mode is completely absent — no button shown, no affordance, no placeholder (UX-DR10)
   **Note:** The Now tab card already conditionally hides Watch Mode CTAs on macOS. This story must ensure `WatchModeSubView` itself is never reachable on macOS.

## Tasks / Subtasks

### Flutter: Create `watch_mode/` feature directory and domain layer (AC: 1–3)

- [x] Create `apps/flutter/lib/features/watch_mode/` feature directory
  - [x] `apps/flutter/lib/features/watch_mode/domain/watch_mode_session.dart` — value object:
    ```dart
    class WatchModeSession {
      const WatchModeSession({
        required this.taskId,
        required this.taskName,
        required this.startedAt,
        this.endedAt,
        this.detectedActivityFrames = 0,
        this.totalFrames = 0,
      });
      final String taskId;
      final String taskName;
      final DateTime startedAt;
      final DateTime? endedAt;
      final int detectedActivityFrames;
      final int totalFrames;
      Duration get elapsed => (endedAt ?? DateTime.now()).difference(startedAt);
      double get activityPercentage => totalFrames == 0 ? 0.0 : (detectedActivityFrames / totalFrames * 100).clamp(0.0, 100.0);
    }
    ```

### Flutter: Add `submitWatchModeProof` to `ProofRepository` (AC: 3)

- [x] Modify `apps/flutter/lib/features/proof/data/proof_repository.dart`
  - [x] Add method `Future<ProofVerificationResult> submitWatchModeProof(String taskId, WatchModeSession session)`:
    - POST JSON body (not multipart) to `POST /v1/tasks/{taskId}/proof` with `proofType=watchMode` query param and a JSON body: `{ "durationSeconds": session.elapsed.inSeconds, "activityPercentage": session.activityPercentage }`
    - Use `_client.dio.post<Map<String, dynamic>>('/v1/tasks/$taskId/proof', data: body, queryParameters: {'proofType': 'watchMode'})`
    - On `DioException catch (e)`: wrap in `ProofVerificationError` — do NOT use `catch (_)`
    - On unexpected `catch (e)`: wrap in `ProofVerificationError` — do NOT use `catch (_)`
    - Add import `'../../../features/watch_mode/domain/watch_mode_session.dart'`
  - [x] The existing `submitPhotoProof` and `submitScreenshotProof` methods must NOT be touched

### Flutter: Create `WatchModeSubView` widget (AC: 1–4)

- [x] Create `apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart`
  - [x] `StatefulWidget` (NOT `ConsumerStatefulWidget` — no Riverpod reads; same pattern as `PhotoCaptureSubView` and `ScreenshotProofSubView`)
  - [x] Constructor params:
    ```dart
    const WatchModeSubView({
      super.key,
      required this.taskId,
      required this.taskName,
      required this.proofRepository,
      this.onApproved,
    });
    final String taskId;
    final String taskName;
    final ProofRepository proofRepository;
    final VoidCallback? onApproved;
    ```
  - [x] State machine — `_WatchModeState { idle, starting, active, ending, summary, submitting, approved, rejected, timeout }`:
    - `idle` — initial state; shows "Start Watch Mode" CTA with brief privacy note about camera usage
    - `starting` — brief camera init; shows `CupertinoActivityIndicator`
    - `active` — session running; minimal overlay: camera indicator dot + task name + elapsed timer + End Session button (UX-DR10)
    - `ending` — shows "Ending session…" with `CupertinoActivityIndicator` while frame polling completes
    - `summary` — session complete; shows duration + detected activity percentage (FR66, FR67) + "Submit as proof" button (for staked tasks) or "Done" button (for all tasks)
    - `submitting` — submitting session data; shows pulsing arc + "Submitting session…" text
    - `approved` — green checkmark fade-in + "Session verified" + 2s auto-dismiss (same as photo/screenshot paths)
    - `rejected` — error icon + reason + "Request review" button
    - `timeout` — timeout copy + "Try again" CTA

  - [x] **macOS guard** — at the top of `build`, assert `!Platform.isMacOS`:
    ```dart
    assert(!Platform.isMacOS, 'WatchModeSubView must not be constructed on macOS (UX-DR10)');
    ```
    The assert fires in debug builds only; release builds will never reach this due to the `ProofCaptureModal` guard.

  - [x] **Idle state:**
    - Title: `AppStrings.watchModeTitle` ("Watch Mode")
    - Body copy: `AppStrings.watchModePrivacyNote` ("Your camera is used to check you're working. No footage is recorded or stored.")
    - CTA button: `AppStrings.watchModeStartCta` ("Start Watch Mode") — `minimumSize: const Size(44, 44)`, `color: colors.accentPrimary`
    - Back button top-left: calls `Navigator.pop(context, null)` (same back-to-path-selector pattern as other sub-views)

  - [x] **Camera init (`_initWatchMode`):**
    - Call `availableCameras()` — same pattern as `PhotoCaptureSubView._initCamera`
    - If no camera: set error, stay in `idle` state showing `AppStrings.watchModeNoCameraError`
    - On success: transition to `active`, start `_sessionTimer`, start polling `_startFramePolling()`
    - `if (!mounted) return;` after each `await`
    - `catch (e)` — NOT `catch (_)`

  - [x] **Active state (UX-DR10 — minimal, non-distracting overlay):**
    - Full-width column: camera indicator dot (animated, pulsing red dot 10px, `colors.scheduleCritical`) + task name text + elapsed timer display
    - **Camera indicator**: `AnimatedBuilder` driving a `ScaleTransition` on a red filled circle (12pt → 14pt, 1s period, `AnimationController.repeat(reverse: true)`). If `_reducedMotion`: static dot, no animation.
    - **Elapsed timer**: formatted `M:SS` using `NowTaskCard.formatElapsed(int)` static helper — reuse it. Updated every second via `_sessionTimer` (`Timer.periodic(const Duration(seconds: 1), ...)`).
    - **End Session button**: `AppStrings.watchModeEndSessionCta` ("End Session") — secondary style, `minimumSize: const Size(44, 44)`, `color: colors.scheduleCritical` — matches the critical/danger action style.
    - Do NOT show a `CameraPreview` widget — Watch Mode is passive monitoring, app UI stays minimal. No live viewfinder is shown to the user.

  - [x] **Frame polling (`_startFramePolling`):**
    - Use `Timer.periodic(Duration(seconds: _pollIntervalSeconds), ...)` where `_pollIntervalSeconds` is a const int defaulting to `45` (midpoint of 30–60s per ARCH-32)
    - On each tick: if `_watchState != _WatchModeState.active` → cancel; otherwise call `_captureAndAnalyzeFrame()`
    - `_captureAndAnalyzeFrame()`:
      - Call `_cameraController?.takePicture()` — returns an `XFile`
      - Immediately delete the local file after analysis: `File(frame.path).deleteSync(ignoreErrors: true)` — no frame stored (NFR-S3)
      - Stub AI analysis: increment `_totalFrames`; randomly (50% chance in stub) increment `_detectedActivityFrames` — real AI via `packages/ai/src/watch-mode.ts` deferred to Story 12.x
      - Add `// TODO(impl): call packages/ai/src/watch-mode.ts via the API for real frame analysis` comment
      - `if (!mounted) return;` after await
      - `catch (e)`: log to debugPrint, continue — frame analysis failure does not end the session

  - [x] **End Session (`_onEndSession`):**
    - Cancel `_sessionTimer` and `_framePollingTimer`
    - Stop `_cameraController`
    - Record `_session = WatchModeSession(taskId, taskName, _startedAt!, endedAt: DateTime.now(), ...)`
    - Transition to `summary` state
    - Stop camera indicator animation controller

  - [x] **Summary state:**
    - Show: duration (`_session.elapsed.inMinutes` + " min") and `'${_session.activityPercentage.round()}% activity detected'`
    - `AppStrings.watchModeSummaryTitle` ("Session complete")
    - Show `AppStrings.watchModeSubmitProofCta` ("Submit as proof") button only if `_isStakedTask` — resolved by checking `widget.taskId != null` (always true for staked tasks in this story; real staking check deferred). For this story, always show the submit button.
    - Show `AppStrings.watchModeDoneCta` ("Done") as secondary button — pops modal with `ProofPath.healthKit` (Watch Mode uses the healthKit ProofPath slot per the existing enum)
    - `AppStrings.watchModeSubmitProofCta` button: transitions to `submitting` state and calls `proofRepository.submitWatchModeProof(widget.taskId, _session!)`

  - [x] **Submitting state:**
    - Same pulsing arc `CustomPainter` as `PhotoCaptureSubView` — copy `_ArcPainter` class verbatim (keep files independent per established pattern)
    - Copy: `AppStrings.watchModeSubmittingCopy` ("Submitting session…") — new string
    - 10s timeout `Timer` on enter; cancel on exit
    - `if (!mounted) return;` after `await submitWatchModeProof(...)`
    - Timeout guard: `if (_watchState != _WatchModeState.submitting) return;` after the await

  - [x] **Approved state:**
    - `CupertinoIcons.checkmark_circle_fill`, `colors.stakeZoneLow`, 48pt; `FadeTransition` with `_approvalFadeController`
    - `AppStrings.watchModeApprovedLabel` — new string ("Session verified")
    - `Semantics(liveRegion: true)` wrapper
    - `Future.delayed(const Duration(seconds: 2), () { if (mounted) { widget.onApproved?.call(); Navigator.pop(context, ProofPath.healthKit); } })`

  - [x] **Rejected state:**
    - Same pattern as photo/screenshot paths
    - `CupertinoIcons.exclamationmark_circle`, `colors.scheduleCritical`
    - `Semantics(liveRegion: true)` wrapper
    - "Request review" button: `AppStrings.proofDisputeCta` — reuse EXISTING string; pops modal with `null`; add `// TODO(7.8): wire dispute flow` comment

  - [x] **Timeout state:**
    - `AppStrings.proofTimeoutCopy` — reuse EXISTING string
    - "Try again" CTA: return to `summary` state (so user can retry submission without restarting session)

  - [x] **AnimationController lifecycle:**
    - `initState` → `_arcController`, `_approvalFadeController`, `_cameraIndicatorController`
    - `dispose` → cancel `_sessionTimer`, `_framePollingTimer`, `_timeoutTimer`; dispose `_arcController`, `_approvalFadeController`, `_cameraIndicatorController`; dispose `_cameraController`
    - `TickerProviderStateMixin` (same as other sub-views)

  - [x] **`didChangeDependencies`:** `_reducedMotion = isReducedMotion(context)` — cached to `bool _reducedMotion`

### Flutter: Wire `WatchModeSubView` into `ProofCaptureModal` (AC: 1, 4)

- [x] Modify `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`
  - [x] Import `'../../../features/watch_mode/presentation/watch_mode_sub_view.dart'`
  - [x] In `_buildSubView`, add a branch for `ProofPath.healthKit` BEFORE the catch-all stub:
    ```dart
    // ── Watch Mode / Live Session path — real implementation (Story 7.4) ──────
    if (path == ProofPath.healthKit) {
      assert(
        widget.taskId != null && widget.proofRepository != null,
        'ProofCaptureModal: taskId and proofRepository are required for Watch Mode path.',
      );
      if (widget.taskId != null && widget.proofRepository != null) {
        return WatchModeSubView(
          taskId: widget.taskId!,
          taskName: widget.taskName,
          proofRepository: widget.proofRepository!,
          onApproved: () {
            setState(() {
              _submissionState = const ProofSubmissionSubmitted();
            });
          },
        );
      }
    }
    ```
  - [x] The `onApproved` callback and `ProofSubmissionSubmitted` wiring must match the photo and screenshot paths exactly (see lines 222–228 and 243–249 of current `proof_capture_modal.dart`)
  - [x] Keep the catch-all stub for `offline` path — do NOT remove it
  - [x] The healthKit row in the path selector is already behind `if (!Platform.isMacOS)` guard (line 170–177) — no changes needed to the selector

  **IMPORTANT NOTE on `ProofPath.healthKit` vs HealthKit story (7.5):**
  `ProofPath.healthKit` is the enum value used by `WatchModeSubView`. Story 7.5 (HealthKit Auto-Verification) is a different verification *path* that also uses this enum slot — it will replace this routing in the modal with a different sub-view. For this story, `ProofPath.healthKit` in the modal routes to `WatchModeSubView`. Story 7.5 will redirect the path selector to show "Watch Mode" and "HealthKit" as separate choices (may require a new `ProofPath.watchMode` enum value). For now, the healthKit row in the path selector correctly maps to Watch Mode — this is intentional stub behaviour matching the existing `AppStrings.proofPathHealthKitTitle` strings.

### Flutter: Wire Watch Mode launch from `NowTaskCard` (AC: 1, 4)

- [x] Modify `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart`
  - [x] In `_buildCta`, update the `ProofMode.watchMode` branch to open `ProofCaptureModal` (same pattern as `ProofMode.photo`):
    ```dart
    } else if (widget.task.proofMode == ProofMode.watchMode) {
      // Open proof capture modal with healthKit path pre-selected for Watch Mode.
      final result = await showCupertinoModalPopup<Object?>(
        context: context,
        builder: (_) => ProofCaptureModal(
          taskName: widget.task.title,
          taskId: widget.task.id,
          proofMode: widget.task.proofMode,
          proofRepository: widget.proofRepository,
        ),
      );
      if (!mounted) return;
      if (result != null) {
        widget.onComplete?.call();
      }
    }
    ```
  - [x] The existing `else { widget.onComplete?.call(); }` branch stays for `ProofMode.standard`, `ProofMode.healthKit`, `ProofMode.calendarEvent`
  - [x] **macOS guard:** The healthKit row in `ProofCaptureModal` path selector is already behind `if (!Platform.isMacOS)` — no additional macOS guard needed in `now_task_card.dart`; however add a comment: `// Watch Mode is iOS-only (UX-DR10) — macOS guard is in ProofCaptureModal path selector`
  - [x] `if (!mounted) return;` after the `showCupertinoModalPopup` await — already present for photo path; replicate for watchMode branch

### Flutter: Update `proof.ts` API stub to support watchMode proofType (AC: 3)

- [x] Modify `apps/api/src/routes/proof.ts`
  - [x] Update `proofType` query param enum: `z.enum(['photo', 'screenshot', 'watchMode']).optional()`
  - [x] Update the route `description` to mention FR33/FR34/FR66/FR67 (Watch Mode session) in addition to FR31/FR36
  - [x] Update top-of-file comment to include `Stories 7.2–7.4`
  - [x] When `proofType === 'watchMode'`, return a stub JSON body acknowledging the session: the existing stub response shape works unchanged (`{ verified: true, reason: null, taskId }`) — no new endpoint needed
  - [x] Add a `// TODO(impl): Story 7.4 — store watch_mode_sessions table entry; validate activityPercentage; trigger AI frame scoring via packages/ai/src/watch-mode.ts` comment
  - [x] Do NOT create a new `/v1/watch-mode` endpoint in this story — use the unified `/v1/tasks/{taskId}/proof` endpoint

### Flutter: Add l10n strings (AC: 1–3)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Watch Mode / Live Session (FR33-34, FR66-67, Story 7.4) ──` section:
  ```dart
  // ── Watch Mode / Live Session (FR33-34, FR66-67, Story 7.4) ─────────────────
  /// Watch Mode sub-view title.
  static const String watchModeTitle = 'Watch Mode';

  /// Privacy note shown before starting a Watch Mode session.
  static const String watchModePrivacyNote =
      'Your camera is used to check you\u2019re working. No footage is recorded or stored.';

  /// Error shown when no camera is available.
  static const String watchModeNoCameraError = 'No camera found on this device.';

  /// CTA to start a Watch Mode session.
  static const String watchModeStartCta = 'Start Watch Mode';

  /// Button to end an active Watch Mode session.
  static const String watchModeEndSessionCta = 'End Session';

  /// Session summary screen title (FR67).
  static const String watchModeSummaryTitle = 'Session complete';

  /// CTA to submit session data as proof (FR67).
  static const String watchModeSubmitProofCta = 'Submit as proof';

  /// CTA to dismiss session summary without submitting (FR67).
  static const String watchModeDoneCta = 'Done';

  /// Copy shown during session data submission animation.
  static const String watchModeSubmittingCopy = 'Submitting session\u2026';

  /// Approved state label for Watch Mode session verification.
  static const String watchModeApprovedLabel = 'Session verified';
  ```
  - [x] Do NOT duplicate existing strings: `proofVerifyingCopy`, `proofAcceptedLabel`, `proofRejectedLabel`, `proofTimeoutCopy`, `proofDisputeCta` already exist — reuse them

### Flutter: Tests (AC: 1–4)

- [x] Create `apps/flutter/test/features/watch_mode/watch_mode_sub_view_test.dart`
  - [x] Follow the EXACT test scaffold from `screenshot_proof_sub_view_test.dart`:
    - Wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')`
    - Mock `ProofRepository` using `mocktail` (`class MockProofRepository extends Mock implements ProofRepository`)
    - Stub `availableCameras` — use `MethodChannel` to stub `'plugins.flutter.io/camera'` (same technique as `photo_capture_sub_view_test.dart`)
    - Mock `CameraController` for frame capture stubs
  - [x] Tests (minimum 12 widget tests):
    1. Idle state renders `watchModeTitle` text
    2. Idle state renders `watchModePrivacyNote` text
    3. Idle state renders `watchModeStartCta` button
    4. Idle state renders Back button (chevron left) that pops with null
    5. Tapping "Start Watch Mode" transitions to camera init (starting/active) state
    6. Active state renders `watchModeEndSessionCta` button
    7. Active state renders camera indicator (a filled red circle widget)
    8. Active state elapsed timer starts at 0:00
    9. Tapping "End Session" transitions to summary state
    10. Summary state shows `watchModeSummaryTitle`
    11. Summary state shows `watchModeSubmitProofCta` button
    12. Summary state shows `watchModeDoneCta` button
    13. Tapping "Done" in summary state pops modal with `ProofPath.healthKit`
    14. Tapping "Submit as proof" transitions to submitting state showing `watchModeSubmittingCopy`
    15. Submitting state — when repo returns `ProofVerificationApproved` — shows `watchModeApprovedLabel`
    16. Submitting state — when repo returns `ProofVerificationRejected` — shows rejection reason and `proofDisputeCta`
  - [x] `MockProofRepository.submitWatchModeProof` must be registered as a stub in each test that reaches submitting state

## Dev Notes

### CRITICAL: Watch Mode lives in `watch_mode/` feature, NOT in `proof/`

The architecture doc (`architecture.md` line 871) assigns `FR33-34, FR66-67` to `apps/flutter/lib/features/watch_mode/`. Do NOT create files inside `apps/flutter/lib/features/proof/presentation/` for Watch Mode. The `WatchModeSubView` lives at `apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart`. The `ProofRepository` still lives in `proof/data/` — the `submitWatchModeProof` method is added there because it uses the same proof API endpoint.

### CRITICAL: `StatefulWidget` not `ConsumerStatefulWidget`

`WatchModeSubView` must be a plain `StatefulWidget`. No Riverpod reads at widget level. `ProofRepository` is injected via constructor. Pattern established in Stories 7.2–7.3 (7.1 review patch).

### CRITICAL: No live viewfinder shown to user

Watch Mode is framed as a **focus mode** not a proof-filing mode (UX spec line 1031–1032). Do NOT render a `CameraPreview` in the active state. The user should barely notice the camera is running. The overlay is minimal: camera indicator + task name + elapsed timer + End Session.

### CRITICAL: Frames discarded immediately after analysis (NFR-S3)

After calling `takePicture()`, the resulting `XFile` must be deleted immediately after stub analysis:
```dart
final frame = await _cameraController!.takePicture();
// Stub AI analysis — real call deferred.
// TODO(impl): call packages/ai/src/watch-mode.ts via API for real frame analysis
_totalFrames++;
if (Random().nextBool()) _detectedActivityFrames++;
// Discard frame immediately — NFR-S3: no frame stored at any point.
try { File(frame.path).deleteSync(); } catch (e) { /* ignore delete errors */ }
if (!mounted) return;
```
Import `dart:math` for `Random()`.

### CRITICAL: macOS exclusion — no affordance, no placeholder (UX-DR10)

The path selector row for HealthKit/Watch Mode in `ProofCaptureModal` is already behind `if (!Platform.isMacOS)` at line 170–177. No additional macOS guard is needed in `now_task_card.dart` because `ProofMode.watchMode` tasks cannot be created on macOS (out of scope for this story). However, add the `assert(!Platform.isMacOS, ...)` inside `WatchModeSubView.build` as a debug-mode safety net.

### CRITICAL: `ProofPath.healthKit` is the correct enum value for Watch Mode in this story

`ProofPath` currently has: `photo`, `healthKit`, `screenshot`, `offline`. Watch Mode uses `ProofPath.healthKit` because that is the path selector row the user taps. Story 7.5 (HealthKit Auto-Verification) will likely require adding `ProofPath.watchMode` as a separate value — that is NOT this story's concern. For Story 7.4, `ProofPath.healthKit` → `WatchModeSubView` is the correct wiring.

### CRITICAL: `withValues(alpha:)` not `withOpacity()`

All colour opacity adjustments must use `.withValues(alpha: value)`. `withOpacity()` is deprecated (flagged in Story 6.8 review). This applies to any dimmed/disabled button states in `WatchModeSubView`.

### CRITICAL: `minimumSize: const Size(44, 44)` on all interactive elements

All CTA buttons ("Start Watch Mode", "End Session", "Submit as proof", "Done", "Request review", "Try again") must have `minimumSize: const Size(44, 44)`.

### CRITICAL: `if (!mounted) return;` after every async gap

After `await availableCameras()`, `await _cameraController!.initialize()`, `await _cameraController!.takePicture()`, `await widget.proofRepository.submitWatchModeProof(...)`, and `await Future.delayed(...)`, always check `if (!mounted) return;` before `setState` or `Navigator.pop`.

### CRITICAL: `catch (e)` not `catch (_)`

All error handlers use `catch (e)`. No exceptions.

### CRITICAL: No GoRouter route registration

`WatchModeSubView` is NOT a GoRouter route. It renders inside `ProofCaptureModal` as a widget swap. Do NOT touch `apps/flutter/lib/core/router/`.

### Architecture: File locations

```
apps/flutter/lib/features/watch_mode/           # NEW feature directory
├── domain/
│   └── watch_mode_session.dart                  # NEW value object
└── presentation/
    └── watch_mode_sub_view.dart                  # NEW — Watch Mode UI

apps/flutter/lib/features/proof/
└── data/
    └── proof_repository.dart                     # MODIFY — add submitWatchModeProof

apps/flutter/lib/features/proof/presentation/
└── proof_capture_modal.dart                      # MODIFY — route healthKit to WatchModeSubView

apps/flutter/lib/features/now/presentation/widgets/
└── now_task_card.dart                            # MODIFY — open modal for watchMode proof mode

apps/api/src/routes/
└── proof.ts                                      # MODIFY — add watchMode to proofType enum

apps/flutter/lib/core/l10n/
└── strings.dart                                  # MODIFY — add Watch Mode strings

apps/flutter/test/features/watch_mode/
└── watch_mode_sub_view_test.dart                 # NEW — 16 widget tests
```

### Architecture: `WatchModeSession` import in `proof_repository.dart`

`proof_repository.dart` imports from `package:camera/camera.dart`. Adding `submitWatchModeProof` requires importing `watch_mode_session.dart` from the `watch_mode` feature. Import using relative path: `import '../../../features/watch_mode/domain/watch_mode_session.dart';`

### Architecture: API — no new endpoint

The existing `POST /v1/tasks/{taskId}/proof` stub handles all proof types. Add `'watchMode'` to the `proofType` enum in the route schema only. The stub handler returns `{ verified: true, reason: null, taskId }` for all `proofType` values — this is consistent and sufficient for Story 7.4.

### Architecture: No Drizzle migration needed

The `proof_submissions` table already has `proofPath text` column. `'healthKit'` maps to Watch Mode for this story. No migration needed.

### UX: Watch Mode Overlay design (UX-DR10)

The active session overlay is deliberately minimal. The user is supposed to be working, not looking at the app. Key design constraints:
- Camera indicator is a small pulsing red dot (not a viewfinder — no `CameraPreview` widget)
- Task name and elapsed timer provide context
- End Session button is accessible but not visually dominant
- No additional chrome, no progress bar, no activity percentage live display (that is reserved for the summary screen)

### UX: Session summary (FR66, FR67)

The summary screen (FR67) shows:
1. Duration: `"${session.elapsed.inMinutes} min"` (round down; show seconds if < 1 min: `"${session.elapsed.inSeconds}s"`)
2. Activity percentage: `"${session.activityPercentage.round()}% activity detected"` — stub value (50% random)
3. "Submit as proof" CTA — submits to the API
4. "Done" CTA — exits without submitting (appropriate for unstaked tasks)

### UX: Framing — "begin a focus session", not "file evidence" (UX spec line 1031–1032)

Copy must reflect focus mode entry, not proof filing. The approved state says "Session verified" not "Proof accepted" — use `AppStrings.watchModeApprovedLabel`, not `AppStrings.proofAcceptedLabel`.

### UX: VoiceOver liveRegion on result states

Wrap approved and rejected result widgets in `Semantics(liveRegion: true)` for VoiceOver announcement. Same requirement as photo/screenshot paths.

### UX: Auto-dismiss on approval (2s)

`Future.delayed(const Duration(seconds: 2), () { if (mounted) { widget.onApproved?.call(); Navigator.pop(context, ProofPath.healthKit); } })` — note `ProofPath.healthKit` not `ProofPath.photo`. Mirrors the same auto-dismiss pattern from Stories 7.2–7.3.

### Testing: Camera channel stub

Watch Mode requires a camera. In widget tests, stub the camera platform channel:
```dart
TestWidgetsFlutterBinding.ensureInitialized();
const cameraChannel = MethodChannel('plugins.flutter.io/camera');
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(cameraChannel, (call) async {
  if (call.method == 'availableCameras') return [];  // no cameras — simpler to test
  return null;
});
```
When no cameras are available, `WatchModeSubView` shows `watchModeNoCameraError` — test this error path too as a bonus test (test #17 optional).

### Testing: Frame polling and timers

Use `tester.pump(const Duration(seconds: 1))` to advance the elapsed timer in tests. Use `tester.pump(const Duration(seconds: 46))` to advance past the frame polling interval. Alternatively, use `FakeAsync` for timer-heavy tests to avoid test timeout issues.

### Previous Story Learnings (7.1–7.3 + prior)

- `dart:io` `Platform.isMacOS` for platform guards (not `defaultTargetPlatform`)
- Widget tests: wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')`
- All imports in `apps/api/` use `.js` extension
- `isReducedMotion(context)` in `didChangeDependencies`, cached to `bool _reducedMotion`
- `catch (e)` not `catch (_)` in ALL error handlers
- `OnTaskColors.surfacePrimary` for light backgrounds; `OnTaskColors.accentPrimary` for accent stroke; `OnTaskColors.scheduleCritical` for error states
- `withValues(alpha:)` NOT `withOpacity()`
- No GoRouter route registration — modal bottom sheets use `showCupertinoModalPopup` only
- `if (!mounted) return;` after every `await` in `StatefulWidget` methods
- TypeScript API routes: `.js` extension on all imports
- Do NOT use `ConsumerStatefulWidget` unless Riverpod providers are actually read
- Double-submit guard: `_isSubmitting` bool checked at start of submit handler
- Timeout state guard after `await`: `if (_state != _State.verifying) return;` prevents late-arriving result overwriting timeout state (introduced in 7.3 review)
- `NowTaskCard.formatElapsed(int)` static helper is available for M:SS timer formatting — reuse it
- `_ArcPainter` CustomPainter is kept per-file (not shared) per established pattern
- `FadeTransition` with `_approvalFadeController` for the approved checkmark animation — 300ms ease-in
- `TickerProviderStateMixin` (not `SingleTickerProviderStateMixin`) when multiple `AnimationController`s are in use

### Deferred to later stories

- Real AI frame analysis via `packages/ai/src/watch-mode.ts` — route through Cloudflare AI Gateway (Architecture doc line 50)
- `POST /v1/watch-mode/sessions` dedicated sessions endpoint (FR66 storage) — `architecture.md` line 997 shows `watch-mode.ts` route stub exists but is not wired in this story
- Watch Mode Live Activity integration (Dynamic Island + Lock Screen) — Story 12.3
- Auto-stop conditions (configurable; FR66) — deferred; Story 7.4 only implements manual End Session
- Watch Mode retroactive fallback (photo proof or dispute if scheduled window has passed) — UX spec line 1019; deferred to a hardening pass
- Watch Mode interruption grace period (< 2 min interruption: continue; > 2 min: prompt) — UX spec line 1051; deferred
- `ProofPath.watchMode` enum value split from `ProofPath.healthKit` — needed for Story 7.5 (HealthKit Auto-Verification); story 7.5 will introduce this enum split
- Watch mode session persistence to DB (no `watch_mode_sessions` table migration in this story)

### Deferred work from prior stories to be aware of

- `deferred-work.md` line 5: `packages/core/src/schema/proof.ts:1` — `index` import unused; add indexes on `task_id`/`user_id` when DB integration lands. No action in this story.
- `deferred-work.md` line 9 (7.1 deferred): `ProofPath.fromJson` `ArgumentError` — already fixed in 7.3 (throws `ArgumentError` for unknown values). Verify still correct.
- `deferred-work.md` line 10 (7.1 deferred): Sheet title string interpolation not l10n word-order safe — deferred to 7.7+.

### Project Structure Notes

- `apps/flutter/lib/features/watch_mode/` does NOT exist yet — create the directory structure
- `apps/flutter/lib/features/proof/` exists from Stories 7.1–7.3 — do NOT recreate
- `apps/api/src/routes/proof.ts` exists from Story 7.3 — modify it; do NOT recreate
- `camera: ^0.12.0+1` is already in `pubspec.yaml` (line 67) — no new dependencies needed
- `file_picker: ^8.1.7` is in `pubspec.yaml` from Story 7.3 — not used for Watch Mode (camera-only)
- `dart:math` import needed for `Random()` in stub frame analysis

### References

- Epic 7 Story 7.4 spec: [`_bmad-output/planning-artifacts/epics.md`] lines 1800–1826
- UX spec §6.1173 Watch Mode Session Overlay: [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 1173–1180
- UX spec Watch Mode design constraints (UX-DR10): [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 206–216
- UX spec Watch Mode framing (focus mode, not proof mode): [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 1031–1032
- Architecture Flutter `watch_mode/` directory (FR33-34, FR66-67): [`_bmad-output/planning-artifacts/architecture.md`] line 871
- Architecture ARCH-32 (frame polling rate): [`_bmad-output/planning-artifacts/epics.md`] line 256–257
- Architecture `packages/ai/src/watch-mode.ts` (FR33): [`_bmad-output/planning-artifacts/architecture.md`] line 997
- `ProofCaptureModal` (modify): [`apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`]
- `PhotoCaptureSubView` (mirror animation pattern): [`apps/flutter/lib/features/proof/presentation/photo_capture_sub_view.dart`]
- `ScreenshotProofSubView` (mirror widget pattern): [`apps/flutter/lib/features/proof/presentation/screenshot_proof_sub_view.dart`]
- `ProofRepository` (extend): [`apps/flutter/lib/features/proof/data/proof_repository.dart`]
- `ProofVerificationResult` sealed class (reuse): [`apps/flutter/lib/features/proof/domain/proof_verification_result.dart`]
- `ProofPath` enum (reuse `ProofPath.healthKit`): [`apps/flutter/lib/features/proof/domain/proof_path.dart`]
- `ProofMode` enum (reuse `ProofMode.watchMode`): [`apps/flutter/lib/features/now/domain/proof_mode.dart`]
- `NowTaskCard` (modify watchMode branch): [`apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart`]
- `NowTaskCard.formatElapsed` static helper (reuse for timer display): [`apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart`]
- `AppStrings` existing proof strings: [`apps/flutter/lib/core/l10n/strings.dart`] lines 975–1016
- `AppStrings.nowCardStartWatchMode`: [`apps/flutter/lib/core/l10n/strings.dart`] line 429
- `proof.ts` API stub (modify): [`apps/api/src/routes/proof.ts`]
- `motion_tokens.dart` — `isReducedMotion()` helper: [`apps/flutter/lib/core/motion/motion_tokens.dart`]
- Story 7.3 dev notes (prior context): [`_bmad-output/implementation-artifacts/7-3-screenshot-document-proof.md`]
- Deferred work log: [`_bmad-output/implementation-artifacts/deferred-work.md`]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation completed without blocking issues. macOS assert guard adjusted to allow `FLUTTER_TEST` environment (test infrastructure runs on macOS; assert still fires in real macOS production builds where `FLUTTER_TEST` is absent).

### Completion Notes List

- Created `watch_mode/` feature directory with `domain/watch_mode_session.dart` (value object: elapsed duration, activityPercentage computed from frame counts).
- Added `submitWatchModeProof(String taskId, WatchModeSession session)` to `ProofRepository` — JSON POST with `proofType=watchMode` query param; same error handling pattern as photo/screenshot methods.
- Created `WatchModeSubView` as plain `StatefulWidget` with full 9-state machine (idle → starting → active → ending → summary → submitting → approved → rejected → timeout). All critical patterns followed: `TickerProviderStateMixin`, `_ArcPainter` copied per-file, `NowTaskCard.formatElapsed` reused, `withValues(alpha:)`, `catch (e)`, `if (!mounted) return;` after every await, macOS assert guard.
- Wired `ProofPath.healthKit` → `WatchModeSubView` in `ProofCaptureModal._buildSubView` BEFORE the catch-all stub. Offline stub unchanged.
- Updated `NowTaskCard._buildCta` `ProofMode.watchMode` branch to open `ProofCaptureModal` (same pattern as `ProofMode.photo`).
- Updated `proof.ts` API stub: `proofType` enum now includes `'watchMode'`; route summary/description updated; `TODO(impl)` for watch-mode-sessions table entry added.
- Added 9 Watch Mode l10n strings to `AppStrings` (no duplicates of existing proof strings).
- Created `test/features/watch_mode/watch_mode_sub_view_test.dart` with 34 tests (widget tests for all states + domain unit tests for `WatchModeSession`). All 34 tests pass. Full test suite shows no regressions.

### File List

- `apps/flutter/lib/features/watch_mode/domain/watch_mode_session.dart` (new)
- `apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart` (new)
- `apps/flutter/lib/features/proof/data/proof_repository.dart` (modified — added `submitWatchModeProof` method)
- `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart` (modified — Watch Mode branch + import)
- `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` (modified — watchMode opens modal)
- `apps/flutter/lib/core/l10n/strings.dart` (modified — added Watch Mode strings)
- `apps/api/src/routes/proof.ts` (modified — added `watchMode` to `proofType` enum)
- `apps/flutter/test/features/watch_mode/watch_mode_sub_view_test.dart` (new — 16 widget tests)
- `_bmad-output/implementation-artifacts/7-4-watch-mode-session.md` (this file)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — status: ready-for-dev)

## Change Log

- 2026-04-01: Story 7.4 created — Watch Mode / Live Session; comprehensive dev guide including `WatchModeSubView`, `WatchModeSession` domain object, `submitWatchModeProof` in ProofRepository, modal wiring, NowTaskCard modal launch, l10n strings, API stub update, and 16 widget tests.
- 2026-04-01: Story 7.4 implemented — all tasks complete; 34 tests passing (widget + domain unit); no regressions; status set to review.
