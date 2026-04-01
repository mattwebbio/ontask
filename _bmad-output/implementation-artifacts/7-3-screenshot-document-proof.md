# Story 7.3: Screenshot & Document Proof

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to submit a screenshot or document as proof for tasks with digital outputs,
so that completing tasks like "send the report" or "finish the design" can be verified.

## Acceptance Criteria

1. **Given** the user selects Screenshot/Document in the Proof Capture Modal
   **When** they upload a file
   **Then** supported formats are PNG, JPG, and PDF with a maximum size of 25 MB (FR36)
   **And** the file is stored in private Backblaze B2 storage scoped to the task owner (NFR-S4 — stub only in this story, same as photo proof stub)

2. **Given** the file is submitted
   **When** AI verification runs
   **Then** the same verification pipeline and animation as Story 7.2 is used
   **And** the user is shown the verification result with the same pass/fail/timeout flows

## Tasks / Subtasks

### Flutter: Add `file_picker` package to pubspec (AC: 1)

- [x] Add `file_picker: ^8.x` (or latest stable) to `apps/flutter/pubspec.yaml`
  - [x] `file_picker` allows PNG, JPG, PDF import from system Files / share sheet — this is the correct library for document/screenshot import (NOT `image_picker` which is gallery-only, NOT `camera` which is viewfinder-only)
  - [x] Run `flutter pub get` and commit updated `pubspec.yaml` and `pubspec.lock`
  - [x] Do NOT add `image_picker` — that would violate FR31 (gallery import prohibited for the photo path); `file_picker` is the distinct package used only for the screenshot/document path

### Flutter: Add `submitScreenshotProof` to `ProofRepository` (AC: 1, 2)

- [x] Modify `apps/flutter/lib/features/proof/data/proof_repository.dart`
  - [x] Add method `Future<ProofVerificationResult> submitScreenshotProof(String taskId, XFile mediaFile)`
  - [x] Identical implementation to `submitPhotoProof` — POST multipart/form-data with `media` field to `POST /v1/tasks/{taskId}/proof` (same endpoint; the stub does not distinguish by proof path type)
  - [x] Use `dio`'s `FormData` with `MultipartFile.fromFile(mediaFile.path, filename: mediaFile.name)` — same pattern as `submitPhotoProof`
  - [x] On `DioException` catch `(e)`: wrap in `ProofVerificationError` — do NOT use `catch (_)`
  - [x] On unexpected catch `(e)`: wrap in `ProofVerificationError` — do NOT use `catch (_)`
  - [x] Note: `XFile` is already imported via `package:camera/camera.dart` in `proof_repository.dart`; verify it re-exports `XFile` or add `import 'package:cross_file/cross_file.dart'` if needed (cross_file is a transitive dependency of both camera and file_picker)

### Flutter: Create `ScreenshotProofSubView` widget (AC: 1, 2)

- [x] Create `apps/flutter/lib/features/proof/presentation/screenshot_proof_sub_view.dart`
  - [x] `StatefulWidget` (NOT `ConsumerStatefulWidget` — no Riverpod reads; same pattern as `PhotoCaptureSubView`)
  - [x] Constructor params: `taskId` (required String), `taskName` (required String), `proofRepository` (required ProofRepository), `onApproved` (optional `VoidCallback?`) — mirror `PhotoCaptureSubView` constructor exactly
  - [x] State machine: `_ScreenshotState { picking, preview, verifying, approved, rejected, timeout }` — six states parallel to `PhotoCaptureSubView._CaptureState`
    - `picking` — initial state; shows the "import a file" CTA button and format/size constraints
    - `preview` — file chosen; shows thumbnail/PDF icon + "Submit" and "Choose another" buttons
    - `verifying` — same pulsing arc + "Reviewing your proof…" copy as photo path (UX-DR30)
    - `approved` — green checkmark fade-in + "Proof accepted" + 2s auto-dismiss (same as photo path)
    - `rejected` — error icon + plain-language reason + "Try another" and "Request review" buttons
    - `timeout` — timeout copy + "Try again" CTA (same as photo path)
  - [x] **Picking state:**
    - CTA button: `AppStrings.proofScreenshotPickCta` (new string — see l10n task)
    - Subtitle copy: `AppStrings.proofScreenshotPickSubtitle` showing accepted formats and 25 MB limit
    - On tap: call `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'], withData: false, withReadStream: false)` — this opens the system Files picker / share sheet
    - On `FilePickerResult` returned: validate `files.single.size` ≤ 25 × 1024 × 1024 (25 MB); if over limit → show `_showFileTooLargeAlert`; else → wrap as `XFile(result.files.single.path!)` and transition to `preview` state
    - On null result (user cancelled): stay in `picking` state — do not pop the modal
    - `if (!mounted) return;` after every `await`
    - Back button top-left: pops modal path selector (calls `Navigator.pop(context, null)` — same as photo path "back" semantics)
  - [x] **File size validation:** `_showFileTooLargeAlert(BuildContext context)` — show `CupertinoAlertDialog` with title `AppStrings.proofScreenshotFileTooLargeTitle` and message `AppStrings.proofScreenshotFileTooLargeMessage`; single "OK" action; stay in `picking` state after dismiss
  - [x] **Preview state:**
    - For PNG/JPG: show `Image.file(File(xFile.path))` thumbnail (do NOT use `Image.network` — this is a local file path, same patch applied in 7.2 review)
    - For PDF: show `CupertinoIcons.doc_fill` icon (large, `color.accent.primary`, 64pt) with filename text below — no PDF rendering required in this story
    - Detect format from file extension: `xFile.path.toLowerCase().endsWith('.pdf')`
    - "Choose another" button (secondary): returns to `picking` state, clears `_pickedFile`
    - "Submit" button (primary, `color.accent.primary`): double-submit guard via `_isSubmitting` bool (same pattern as `PhotoCaptureSubView._onSubmit`) — transition to `verifying`
    - Both buttons: `minimumSize: const Size(44, 44)`
  - [x] **Verifying state (UX-DR30 — MUST reuse `PhotoCaptureSubView` animation pattern exactly):**
    - Stack: file thumbnail/icon + pulsing arc `CustomPainter` overlay
    - Arc: `CustomPainter` with animated sweep angle `0 → 2π`, `color.accent.primary` stroke (3pt), 1.5s loop via `AnimationController.repeat()`
    - `isReducedMotion(context)` check in `didChangeDependencies`, cached to `bool _reducedMotion` — if true, static arc (no animation)
    - Copy: `AppStrings.proofVerifyingCopy` ("Reviewing your proof…") — reuse the EXISTING string, do NOT add a new one
    - 10s timeout `Timer` on enter; cancel on exit
    - Call `widget.proofRepository.submitScreenshotProof(widget.taskId, _pickedFile!)` during this state
    - `if (!mounted) return;` after the await
  - [x] **Approved state:** Reuse EXACT same pattern as `PhotoCaptureSubView`:
    - `CupertinoIcons.checkmark_circle_fill`, `color.stake.low`, 48pt; `FadeTransition` with `_approvalFadeController`
    - `AppStrings.proofAcceptedLabel` — reuse EXISTING string
    - `Semantics(liveRegion: true)` wrapper for VoiceOver announcement
    - `Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context, ProofPath.screenshot); })`
    - Call `widget.onApproved?.call()` before delayed pop
  - [x] **Rejected state:** Same pattern as photo path:
    - `CupertinoIcons.exclamationmark_circle`, `color.schedule.critical`
    - `Semantics(liveRegion: true)` wrapper
    - Plain-language reason from API response
    - "Try another" button (`AppStrings.proofScreenshotRetakeCta` — new string): return to `picking` state
    - "Request review" button (`AppStrings.proofDisputeCta` — reuse EXISTING string): pop modal with `null`; add `// TODO(7.8): wire dispute flow` comment
  - [x] **Timeout state:**
    - `AppStrings.proofTimeoutCopy` — reuse EXISTING string
    - "Try again" CTA: return to `picking` state
  - [x] AnimationController lifecycle: `initState` → `_arcController`, `_approvalFadeController`; `dispose` → cancel timer, dispose both controllers; same `TickerProviderStateMixin` as `PhotoCaptureSubView`

### Flutter: Wire `ScreenshotProofSubView` into `ProofCaptureModal` (AC: 1, 2)

- [x] Modify `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`
  - [x] Import `screenshot_proof_sub_view.dart`
  - [x] In `_buildSubView`, add a branch for `ProofPath.screenshot` BEFORE the catch-all stub:
    ```dart
    if (path == ProofPath.screenshot) {
      assert(
        widget.taskId != null && widget.proofRepository != null,
        'ProofCaptureModal: taskId and proofRepository are required for screenshot path.',
      );
      if (widget.taskId != null && widget.proofRepository != null) {
        return ScreenshotProofSubView(
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
  - [x] The `onComplete` callback pattern and `ProofSubmissionSubmitted` wiring must match the photo path exactly (see lines 217-228 of current `proof_capture_modal.dart`)
  - [x] Keep the catch-all stub for `healthKit` and `offline` paths — do NOT remove them

### Flutter: Fix deferred review patches from Story 7.2 (no new AC — regression fixes)

The following are open review patches from Story 7.2 that must be fixed in this story:

- [x] **[Patch] `catch (_)` in `_tryCreateProofRepository`** — `apps/flutter/lib/features/now/presentation/now_screen.dart:138` uses `catch (_)` which violates the project convention. Change to `catch (e)`. **ALREADY FIXED** in the Story 7.2 review commit (87ebdec). Verified at line 138: `catch (e)`.
- [x] **[Patch] `ProofSubmissionSubmitted` never set** — Verify/fix: the `onApproved` callback in `proof_capture_modal.dart` now correctly sets `_submissionState = const ProofSubmissionSubmitted()` (was marked as `// ignore: unused_field`). **PARTIALLY FIXED** in 7.2 review: field is correctly set for photo path at lines 222-226. Removed the stale `// ignore: unused_field` comment in this story; field is now also set for the screenshot path via `onApproved` callback.
- [x] **[Patch] `permission_handler` dead dependency** — `apps/flutter/pubspec.yaml:67` has `permission_handler: ^11.3.1` added in Story 7.2 but it is never imported or used. Remove it from `pubspec.yaml` and `pubspec.lock`. **ALREADY REMOVED** in the Story 7.2 review commit (87ebdec). `permission_handler` is not present in `pubspec.yaml`.
- [x] **[Patch] Double-submit guard missing in photo path** — `apps/flutter/lib/features/proof/presentation/photo_capture_sub_view.dart:170`: verify `_isSubmitting` guard is correctly set to `true` before transitioning to `verifying` state. **ALREADY FIXED** in the Story 7.2 review commit (87ebdec). Guard `if (_isSubmitting) return;` is in place at line 181 of `photo_capture_sub_view.dart`.

### Flutter: l10n strings (AC: 1, 2)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Screenshot & Document Proof (FR36, Story 7.3) ──` section:
  ```dart
  // ── Screenshot & Document Proof (FR36, Story 7.3) ──────────────────────────
  /// CTA to open the system file picker.
  static const String proofScreenshotPickCta = 'Choose a file';

  /// Subtitle below the pick CTA showing accepted formats and size limit.
  static const String proofScreenshotPickSubtitle =
      'PNG, JPG, or PDF — up to 25 MB';

  /// "Choose another file" button in preview state.
  static const String proofScreenshotRetakeCta = 'Choose another';

  /// Alert title when the chosen file exceeds the 25 MB limit.
  static const String proofScreenshotFileTooLargeTitle = 'File too large';

  /// Alert message shown when the chosen file exceeds the 25 MB limit.
  static const String proofScreenshotFileTooLargeMessage =
      'Please choose a file smaller than 25 MB.';
  ```
  - [x] Do NOT duplicate existing strings: `proofVerifyingCopy`, `proofAcceptedLabel`, `proofRejectedLabel`, `proofTimeoutCopy`, `proofDisputeCta`, `proofSubmitCta` already exist — reuse them

### API: Update `proof.ts` stub to acknowledge screenshot/document path (AC: 1, 2)

- [x] Modify `apps/api/src/routes/proof.ts`
  - [x] The existing `POST /v1/tasks/{taskId}/proof` endpoint already serves both photo and screenshot proof — no new endpoint needed
  - [x] Update the OpenAPI `summary` to "Submit photo or screenshot/document proof for AI verification"
  - [x] Update the `description` to note FR36 (screenshot/document) in addition to FR31 (photo)
  - [x] Add a `proofType` optional query param `z.enum(['photo', 'screenshot']).optional()` to the route request schema — this allows `?proofType=screenshot` in tests to differentiate calls; stub handler ignores it but it documents the intent
  - [x] Update `// Stub endpoint for AI-verified photo proof submission (Epic 7, Story 7.2)` comment to include `Story 7.3` and `FR36`
  - [x] Do NOT create a separate endpoint — the proof submission pipeline is unified

### Flutter: Tests (AC: 1, 2)

- [x] Create `apps/flutter/test/features/proof/screenshot_proof_sub_view_test.dart`
  - [x] Follow the EXACT test scaffold from `photo_capture_sub_view_test.dart`:
    - Wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')` (pattern from `billing_history_screen_test.dart:34-35`)
    - Mock `ProofRepository` using `mocktail` (`class MockProofRepository extends Mock implements ProofRepository`)
    - No camera channel stubbing needed — this widget uses `file_picker` instead
    - Stub `FilePicker` platform: `FilePicker.platform = MockFilePicker()` (see note in Dev Notes)
  - [x] Tests (minimum 10 widget tests):
    1. Picking state renders `proofScreenshotPickCta` CTA button
    2. Picking state renders `proofScreenshotPickSubtitle` format hint
    3. Tapping "Choose a file" when picker returns null stays in picking state
    4. Tapping "Choose a file" when picker returns a PNG file transitions to preview state
    5. Preview state for PNG shows `Image.file` widget
    6. Preview state for PDF shows `CupertinoIcons.doc_fill` icon (not Image.file)
    7. File over 25 MB shows `proofScreenshotFileTooLargeTitle` in alert
    8. Tapping "Choose another" in preview state returns to picking state
    9. Tapping "Submit" in preview state shows `proofVerifyingCopy` (verifying state)
    10. Verifying state — when repo returns `ProofVerificationApproved` — shows `proofAcceptedLabel`
    11. Verifying state — when repo returns `ProofVerificationRejected` — shows rejection reason text
    12. Verifying state — when repo returns `ProofVerificationRejected` — shows `proofDisputeCta` button
    13. "Try another" in rejected state returns to picking state
    14. Timeout state shows `proofTimeoutCopy` after 10s
  - [x] `MockProofRepository.submitScreenshotProof` must be registered as a stub in each test that reaches verifying state

## Dev Notes

### CRITICAL: `file_picker` is the correct package — NOT `image_picker`, NOT `camera`

The screenshot/document path must use `file_picker` (pub.dev/packages/file_picker). It opens the native system Files sheet allowing the user to select from iCloud Drive, On My iPhone, etc. `image_picker` only accesses the Photo Library (prohibited by FR31). `camera` is the in-app camera viewfinder (photo path only). `file_picker` does NOT require any permission declarations in `Info.plist` for Files access on iOS — the system Files picker is permission-free.

### CRITICAL: `ScreenshotProofSubView` is a near-mirror of `PhotoCaptureSubView`

The verification flow (verifying → approved/rejected/timeout states) is IDENTICAL to `PhotoCaptureSubView`. Do NOT reinvent the arc animation, reduced-motion check, approval fade, or timeout pattern. Copy the relevant state machine sections from `photo_capture_sub_view.dart` and adapt only what differs (the file-picking initial state instead of the camera viewfinder).

Key differences from `PhotoCaptureSubView`:
- No camera init, no `CameraController`, no `CameraPreview` widget
- Initial state is `picking` (a CTA button) instead of `camera` (a viewfinder)
- PDF files show an icon, not a thumbnail
- "Choose another" replaces "Retake"
- File size validation step before transitioning to `preview`

### CRITICAL: `StatefulWidget` not `ConsumerStatefulWidget`

`ScreenshotProofSubView` must be a plain `StatefulWidget`. No Riverpod reads at widget level. ProofRepository is injected via constructor. Pattern established in Story 7.2 (7.1 review patch).

### CRITICAL: `withValues(alpha:)` not `withOpacity()`

All colour opacity adjustments must use `.withValues(alpha: value)`. `withOpacity()` is deprecated (flagged in Story 6.8 review).

### CRITICAL: `minimumSize: const Size(44, 44)` on all interactive elements

All CTA buttons ("Choose a file", "Submit", "Choose another", "Try again", "Request review") must have `minimumSize: const Size(44, 44)`.

### CRITICAL: `if (!mounted) return;` after every async gap

After `await FilePicker.platform.pickFiles(...)` and after `await widget.proofRepository.submitScreenshotProof(...)` and after `await Future.delayed(...)`, always check `if (!mounted) return;` before `setState` or `Navigator.pop`.

### CRITICAL: `catch (e)` not `catch (_)`

All error handlers use `catch (e)`. This is also the fix needed in `now_screen.dart:138` deferred from 7.2.

### CRITICAL: No GoRouter route registration

`ScreenshotProofSubView` is NOT a GoRouter route. It renders inside `ProofCaptureModal` as a widget swap (the `_selectedPath == ProofPath.screenshot` branch). Do NOT touch `apps/flutter/lib/core/router/`.

### Architecture: File locations

```
apps/flutter/lib/features/proof/
├── data/
│   └── proof_repository.dart              # MODIFY — add submitScreenshotProof
├── presentation/
│   ├── proof_capture_modal.dart           # MODIFY — route screenshot path to ScreenshotProofSubView
│   └── screenshot_proof_sub_view.dart     # NEW — file picker + verification UI

apps/api/src/routes/
└── proof.ts                               # MODIFY — update description/summary for FR36
```

### Architecture: `XFile` import in `proof_repository.dart`

`proof_repository.dart` currently imports `package:camera/camera.dart` for `XFile`. The `file_picker` package wraps results as `PlatformFile`, not `XFile`. Convert to `XFile` using `XFile(result.files.single.path!)`. `XFile` itself is from the `cross_file` package which is a transitive dependency of both `camera` and `file_picker` — no direct import of `cross_file` is needed. Verify after adding `file_picker` that `XFile` is still resolvable without a direct `cross_file` import; if not, add `import 'package:cross_file/cross_file.dart';` to `screenshot_proof_sub_view.dart`.

### Architecture: `ProofCaptureModal` constructor

`ProofCaptureModal` already has `taskId` and `proofRepository` optional params (added in Story 7.2). The screenshot path uses those same params. No constructor changes needed on `ProofCaptureModal`.

### Architecture: API stub — no changes to response structure

The existing `POST /v1/tasks/{taskId}/proof` stub in `apps/api/src/routes/proof.ts` handles both photo and screenshot proof identically at the stub level. Do NOT create a new endpoint. Only update descriptions and add `proofType` query param for documentation purposes.

### Architecture: No Drizzle migration needed

The `proof_submissions` table already has a `proofPath` text column (`'photo' | 'screenshot' | 'healthKit' | 'offline'`). The value `'screenshot'` is already valid. No new migration required.

### Architecture: `pnpm --filter @ontask/core drizzle-kit generate` not applicable

No schema changes in this story. If you accidentally trigger drizzle-kit it will produce no output (no changes to `proof_submissions`).

### UX: File picker opens system sheet — no custom gallery UI

The picking state is a single CTA button that opens the system file picker via `FilePicker.platform.pickFiles(...)`. There is no custom file browser, no grid of thumbnails, no search. The system sheet handles the file browsing experience.

### UX: Approval auto-dismiss (same as 7.2)

`Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context, ProofPath.screenshot); })` — note `ProofPath.screenshot` not `ProofPath.photo`. This is the key difference from `PhotoCaptureSubView`'s dismiss call.

### UX: Rejected state persists until user acts

Do not auto-dismiss on rejection. "Request review" pops modal with `null` — add `// TODO(7.8): wire dispute flow` comment. Same pattern as photo path.

### UX: VoiceOver liveRegion on result states

Wrap approved and rejected result widgets in `Semantics(liveRegion: true)` for VoiceOver announcement. Same requirement as photo path (UX spec §7 line 1197).

### Testing: Mock `FilePicker` platform

`file_picker` exposes `FilePicker.platform` as a settable field for testing. In tests:
```dart
class MockFilePicker extends Mock implements FilePicker {}
// In setUp:
FilePicker.platform = MockFilePicker();
```
Use `when(() => mockFilePicker.pickFiles(...)).thenAnswer(...)` to return a `FilePickerResult` or `null`. Import: `import 'package:file_picker/file_picker.dart';`.

For a 0-byte PNG result in tests: `PlatformFile(name: 'proof.png', size: 1024, path: '/tmp/proof.png', bytes: null)`.

### Previous Story Learnings (7.1, 7.2 + prior)

- `dart:io` `Platform.isMacOS` for platform guards (not `defaultTargetPlatform`)
- Widget tests: wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')`
- All imports in `apps/api/` use `.js` extension
- `(value as num).toInt()` for JSON numeric fields
- `isReducedMotion(context)` in `didChangeDependencies`, cached to `bool _reducedMotion`
- `catch (e)` not `catch (_)` in ALL error handlers — including the deferred fix in `now_screen.dart:138`
- `OnTaskColors.surfacePrimary` for light backgrounds; `OnTaskColors.accentPrimary` for accent stroke
- `withValues(alpha:)` NOT `withOpacity()`
- No GoRouter route registration — modal bottom sheets use `showCupertinoModalPopup` only
- `if (!mounted) return;` after every `await` in `StatefulWidget` methods
- TypeScript API routes: `.js` extension on all imports
- Do NOT use `ConsumerStatefulWidget` unless Riverpod providers are actually read
- `Image.file(File(path))` for local file display — NOT `Image.network` (regression from 7.2 review)
- Double-submit guard: `_isSubmitting` bool checked at start of submit handler

### Deferred to later stories

- Real Backblaze B2 upload and presigned URL generation — NFR-S4 (same `TODO(impl)` markers in `proof.ts`)
- Real AI pipeline call via `packages/ai/src/proof-verification.ts` — Story architecture assigns to Cloudflare AI Gateway
- PDF content extraction / AI analysis (AI needs text or image from the PDF — deferred until real AI pipeline lands)
- File type MIME validation server-side (client-side extension check is stub-grade)
- `ProofPath.fromJson` l10n word-order-safe string interpolation — Story 7.7+
- "Request review" dispute filing — Story 7.8

### Deferred work from prior stories to be aware of

- `deferred-work.md` line 5: `packages/core/src/schema/proof.ts:1` — `index` import unused; add indexes on `task_id`/`user_id` when DB integration lands. No action needed in this story.
- `deferred-work.md` line 9 (7.1 deferred): `ProofSubmissionState` sealed class. Both photo and screenshot paths must set `ProofSubmissionSubmitted` on approval. Verify the `// ignore: unused_field` annotation has been removed from `proof_capture_modal.dart:56` — it should have been removed in 7.2 but the review found it was not wired. Fix in this story if still present.

### Project Structure Notes

- `apps/flutter/lib/features/proof/` exists from Stories 7.1–7.2 — add into it; do NOT recreate
- `apps/api/src/routes/proof.ts` exists from Story 7.2 — modify it; do NOT recreate
- `packages/core/src/schema/proof.ts` exists from Story 7.2 — no changes needed
- `file_picker` is NOT in `pubspec.yaml` as of Story 7.2 — add it
- `permission_handler` IS in `pubspec.yaml` (added erroneously in Story 7.2, never used) — REMOVE it in this story

### References

- Epic 7 Story 7.3 spec: [`_bmad-output/planning-artifacts/epics.md`] lines 1780–1797
- UX spec §7 Proof Capture Modal (screenshot path): [`_bmad-output/planning-artifacts/ux-design-specification.md`]
- UX spec AI proof verification animation (UX-DR30): [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 1590–1591
- UX spec proof approved / rejected states: [`_bmad-output/planning-artifacts/ux-design-specification.md`] lines 1407–1412
- Architecture Flutter `proof/` directory (FR31, FR36): [`_bmad-output/planning-artifacts/architecture.md`] line 870
- Architecture `apps/api/src/routes/proof.ts` (FR31, FR36, FR41): [`_bmad-output/planning-artifacts/architecture.md`] line 736
- `ProofCaptureModal` (existing): [`apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`]
- `PhotoCaptureSubView` (mirror pattern): [`apps/flutter/lib/features/proof/presentation/photo_capture_sub_view.dart`]
- `ProofRepository` (extend): [`apps/flutter/lib/features/proof/data/proof_repository.dart`]
- `ProofVerificationResult` sealed class (reuse): [`apps/flutter/lib/features/proof/domain/proof_verification_result.dart`]
- `ProofPath` enum (reuse `ProofPath.screenshot`): [`apps/flutter/lib/features/proof/domain/proof_path.dart`]
- `ProofSubmissionState` sealed class: [`apps/flutter/lib/features/proof/domain/proof_submission_state.dart`]
- `AppStrings` existing proof strings: [`apps/flutter/lib/core/l10n/strings.dart`] lines 977–998
- `proof.ts` API stub (modify): [`apps/api/src/routes/proof.ts`]
- `proof_submissions` schema (no change): [`packages/core/src/schema/proof.ts`]
- Story 7.2 dev notes (prior context): [`_bmad-output/implementation-artifacts/7-2-photo-video-proof-with-ai-verification.md`]
- Open review patches from 7.2: [`_bmad-output/implementation-artifacts/7-2-photo-video-proof-with-ai-verification.md`] lines 357–364
- Deferred work log: [`_bmad-output/implementation-artifacts/deferred-work.md`] lines 1–11

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Added `file_picker: ^8.1.7` to pubspec.yaml; installed version 8.3.7 (satisfies ^8.x). Used `file_picker` not `image_picker` per FR36 requirements.
- `XFile` is correctly available via `package:camera/camera.dart` re-export; no direct `cross_file` import needed.
- `ScreenshotProofSubView` is a plain `StatefulWidget` mirroring `PhotoCaptureSubView` pattern. Six-state machine: picking → preview → verifying → approved/rejected/timeout. `_ArcPainter` `CustomPainter` is an identical copy from `PhotoCaptureSubView` (not shared to keep files independent as established by photo path).
- Added timeout guard in `_onSubmit`: `if (_screenshotState != _ScreenshotState.verifying) return;` after the await to prevent the late-arriving API result from overwriting a timeout state and creating a stale 2-second auto-dismiss timer.
- `ProofCaptureModal`: Removed stale `// ignore: unused_field` annotation from `_submissionState`. Field is now confirmed used for both photo and screenshot paths.
- Deferred 7.2 patches verification: All four patches were ALREADY applied in the 7.2 review commit (87ebdec): `catch (e)` in now_screen.dart (confirmed), `ProofSubmissionSubmitted` wiring (confirmed for photo path; stale ignore comment removed in this story), `permission_handler` removal (confirmed not in pubspec.yaml), double-submit guard (confirmed at line 181 of photo_capture_sub_view.dart).
- `proof_capture_modal_test.dart` updated: two existing tests that used the screenshot path as a stub navigation test were updated to use the offline path instead, since screenshot now renders the real `ScreenshotProofSubView`.
- `MockFilePicker` uses `MockPlatformInterfaceMixin` to bypass `PlatformInterface.verifyToken` token check.
- 18 new widget tests added; full suite: 792 tests pass (0 failures, 0 regressions). API suite: 195 tests pass.

### File List

- `apps/flutter/pubspec.yaml` (modified — added `file_picker: ^8.1.7`)
- `apps/flutter/pubspec.lock` (modified — updated by `flutter pub get`)
- `apps/flutter/lib/features/proof/data/proof_repository.dart` (modified — added `submitScreenshotProof` method)
- `apps/flutter/lib/features/proof/presentation/screenshot_proof_sub_view.dart` (new)
- `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart` (modified — screenshot branch + import + removed ignore comment)
- `apps/flutter/lib/core/l10n/strings.dart` (modified — added 5 screenshot/document proof strings)
- `apps/api/src/routes/proof.ts` (modified — updated summary/description/comment; added `proofType` query param)
- `apps/flutter/test/features/proof/screenshot_proof_sub_view_test.dart` (new — 18 widget tests)
- `apps/flutter/test/features/proof/proof_capture_modal_test.dart` (modified — updated 2 tests to use offline path instead of screenshot stub path)
- `_bmad-output/implementation-artifacts/7-3-screenshot-document-proof.md` (modified — tasks checked, completion notes, file list, status)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — status: review)


## Change Log

- 2026-04-01: Story 7.3 implemented — `file_picker` added, `ScreenshotProofSubView` created, `submitScreenshotProof` added to `ProofRepository`, screenshot path wired in `ProofCaptureModal`, 5 l10n strings added, API stub updated with `proofType` query param and FR36 description. 18 new widget tests. All 792 Flutter tests and 195 API tests pass. Deferred 7.2 patches verified already applied; stale `// ignore: unused_field` removed from `proof_capture_modal.dart`.
