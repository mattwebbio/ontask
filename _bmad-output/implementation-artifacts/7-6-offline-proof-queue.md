# Story 7.6: Offline Proof Queue

Status: in-progress

## Story

As a user,
I want to submit proof while offline and have it sync automatically when I reconnect,
So that I'm not charged just because I was somewhere without signal when I finished a task.

## Acceptance Criteria

1. **Given** the user submits proof while offline (any proof type: photo, screenshot, HealthKit, or a manual "Save for Later" offline submission)
   **When** the proof is captured
   **Then** it is queued in the local `pending_operations` Drift table with `clientTimestamp` set at the moment of capture — not at sync time (FR37, ARCH-26)
   **And** the app shows visible confirmation: "Proof saved — will sync when you're back online" (NFR-UX1)

2. **Given** the device reconnects to the network
   **When** the offline queue is processed
   **Then** queued proof is submitted with its original `clientTimestamp`
   **And** if the `clientTimestamp` predates the task deadline, any pending charge is reversed

3. **Given** a sync attempt fails
   **When** retries are exhausted
   **Then** the operation is retried up to 3 times with exponential backoff (ARCH-26)
   **And** after 3 failures, status is set to `failed` and the user is notified — the proof is never silently dropped (NFR-R5)

4. **Given** the user taps the offline row in the Proof Capture Modal (shown only when `_isOffline == true`)
   **When** they confirm their offline submission
   **Then** `OfflineProofSubView` handles the flow for `ProofPath.offline`
   **And** the sub-view queues the operation and shows the confirmation

## Tasks / Subtasks

---

### Flutter: Create `OfflineProofSubView` widget (AC: 1, 4)

- [x] Create `apps/flutter/lib/features/proof/presentation/offline_proof_sub_view.dart`
  - [x] `StatefulWidget` (NOT `ConsumerStatefulWidget` — consistent with `PhotoCaptureSubView`, `ScreenshotProofSubView`, `WatchModeSubView`, `HealthKitProofSubView`)
  - [x] Constructor params:
    ```dart
    class OfflineProofSubView extends StatefulWidget {
      const OfflineProofSubView({
        super.key,
        required this.taskId,
        required this.taskName,
        required this.proofRepository,
        this.onQueued,
      });
      final String taskId;
      final String taskName;
      final ProofRepository proofRepository;
      final VoidCallback? onQueued;
    }
    ```
  - [x] State machine — `_OfflineProofState { idle, queuing, queued, error }`:
    - `idle` — initial state; shows task name, explanation copy, and "Save for Later" CTA
    - `queuing` — brief in-progress; shows `CupertinoActivityIndicator`
    - `queued` — success; shows confirmation copy (`AppStrings.offlineProofQueuedConfirmation`) + checkmark icon + "Done" button that pops with `ProofPath.offline`
    - `error` — shows error copy + "Try again" CTA to return to `idle`
  - [x] **`_onSaveForLater()` method:**
    - Set state to `queuing`
    - Call `await widget.proofRepository.enqueueOfflineProof(widget.taskId)` (see ProofRepository task below)
    - `if (!mounted) return;` after the await
    - On success: set state to `queued`, call `widget.onQueued?.call()`
    - On `catch (e)` (NOT `catch (_)`): set state to `error`, `debugPrint('OfflineProofSubView: enqueue error: $e')`
  - [x] **Idle state layout:**
    - Back button (chevron left, `minimumSize: const Size(44, 44)`) → `Navigator.pop(context, null)` (returns to path selector)
    - Title: `AppStrings.offlineProofTitle` ("Save for Later")
    - Body copy: `AppStrings.offlineProofBody` ("Your proof will be saved on this device and submitted automatically when you're back online.")
    - Task name displayed in a secondary text style
    - Primary CTA: `AppStrings.offlineProofSaveCta` ("Save for Later") — `minimumSize: const Size(44, 44)`, `color: colors.accentPrimary`
  - [x] **Queuing state:**
    - `CupertinoActivityIndicator(color: colors.accentPrimary)`
    - Copy: `AppStrings.offlineProofQueueingCopy` ("Saving\u2026")
  - [x] **Queued state:**
    - `Semantics(liveRegion: true)` wrapper on the checkmark icon and confirmation text
    - `CupertinoIcons.checkmark_circle_fill`, `colors.stakeZoneLow`, 48pt
    - Confirmation text: `AppStrings.offlineProofQueuedConfirmation` ("Proof saved — will sync when you're back online")
    - "Done" button: pops with `Navigator.pop(context, ProofPath.offline)` (so the modal parent `ProofCaptureModal` can call `onQueued?.call()`)
    - `minimumSize: const Size(44, 44)` on all buttons
  - [x] **Error state:**
    - `CupertinoIcons.exclamationmark_circle`, `colors.scheduleCritical`, 48pt
    - `Semantics(liveRegion: true)` wrapper
    - Copy: `AppStrings.offlineProofErrorCopy` ("Couldn't save your proof. Please try again.")
    - "Try again" CTA (`AppStrings.watchModeTryAgainCta` — reuse existing string): returns to `idle` state
    - `minimumSize: const Size(44, 44)` on the CTA
  - [x] **No `AnimationController` needed** — offline queuing does not use the pulsing arc; it's an instant local write with no submission animation
  - [x] **`didChangeDependencies`** not required (no `isReducedMotion` check needed — no animations in this sub-view)
  - [x] **No macOS guard required** — offline path is available on all platforms (not behind `!Platform.isMacOS`)
  - [x] **Import list (no unused imports):**
    - `package:flutter/cupertino.dart`
    - `package:flutter/material.dart` show `Theme`
    - `package:flutter/foundation.dart` show `debugPrint`
    - `'../../../core/l10n/strings.dart'`
    - `'../../../core/theme/app_spacing.dart'`
    - `'../../../core/theme/app_theme.dart'`
    - `'../data/proof_repository.dart'`
    - `'../domain/proof_path.dart'`

---

### Flutter: Add `enqueueOfflineProof` to `ProofRepository` (AC: 1)

- [x] Modify `apps/flutter/lib/features/proof/data/proof_repository.dart`
  - [x] Add constructor parameter for the Drift database:
    ```dart
    class ProofRepository {
      ProofRepository(this._client, this._db);

      final ApiClient _client;
      final AppDatabase _db;
    }
    ```
    **IMPORTANT:** `AppDatabase` is at `apps/flutter/lib/core/storage/database.dart` (`import '../../../core/storage/database.dart'`). The `PendingOperations` table accessor is `_db.pendingOperations`.
  - [x] Add import: `'dart:convert' show jsonEncode;`
  - [x] Add import: `'package:drift/drift.dart' show Value;`
  - [x] Add import: `'../../../core/storage/database.dart';`
  - [x] Add new method `enqueueOfflineProof`:
    ```dart
    /// Enqueues a proof submission for offline sync.
    ///
    /// Writes a 'SUBMIT_PROOF' pending operation to the local Drift database
    /// with [clientTimestamp] set at the moment of enqueueing — NEVER updated
    /// at sync time (ARCH-26, FR37).
    ///
    /// The [SyncManager] will pick up this operation on reconnect and call
    /// the API via [applyOperation] with the preserved [clientTimestamp].
    Future<void> enqueueOfflineProof(String taskId) async {
      final now = DateTime.now();
      final payload = jsonEncode({'taskId': taskId, 'proofType': 'offline'});

      await _db.into(_db.pendingOperations).insert(
        PendingOperationsCompanion.insert(
          type: 'SUBMIT_PROOF',
          payload: payload,
          createdAt: now,
          clientTimestamp: now,
          // status defaults to 'pending' via column default
        ),
      );
    }
    ```
  - [x] The existing `submitPhotoProof`, `submitScreenshotProof`, `submitWatchModeProof`, `submitHealthKitProof` methods must NOT be touched
  - [x] **`PendingOperationsCompanion`** is the Drift-generated companion class — it lives in `database.g.dart` and is accessible via the `AppDatabase` import. Do NOT manually define it.

---

### Flutter: Add `submitOfflineProof` to `ProofRepository` for use by `SyncManager` (AC: 2–3)

- [x] In the same `proof_repository.dart` modification, add a method for the sync path:
  ```dart
  /// Submits a previously-queued offline proof to the API during sync.
  ///
  /// Called by [SyncManager.processQueue]'s [applyOperation] callback when
  /// the 'SUBMIT_PROOF' operation type is processed on reconnect.
  ///
  /// The [clientTimestamp] is the original capture time, preserved from the
  /// [PendingOperations] row — not the current time. This ensures the API
  /// receives the timestamp predating the task deadline for charge reversal.
  Future<void> submitOfflineProof(
    String taskId,
    DateTime clientTimestamp,
  ) async {
    final body = {
      'clientTimestamp': clientTimestamp.toIso8601String(),
    };

    await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/$taskId/proof',
      data: body,
      queryParameters: {'proofType': 'offline'},
    );
    // Throws DioException on network/server failure — caller (SyncManager)
    // handles retry and status update.
  }
  ```
  - No `try/catch` here — exceptions propagate to `SyncManager.processQueue` which handles retry counting and marking `failed` after 3 attempts (ARCH-26)
  - `catch (e)` NOT `catch (_)` if error handling is ever added to this method

---

### Flutter: Add exponential-backoff retry guard to `SyncManager.processQueue` for `SUBMIT_PROOF` ops (AC: 3)

- [x] Modify `apps/flutter/lib/core/sync/sync_manager.dart`
  - [x] The existing `processQueue` logic already marks `retryCount + 1` and sets `status = 'failed'` on error (line 150–159). **Extend** it to enforce the 3-retry limit from ARCH-26:
    - In the `catch (_)` block at line 150, after incrementing `retryCount`, check `if (op.retryCount + 1 >= 3)` and set `status = 'failed'` AND call `_onOperationFailed(op)` (see below)
    - If `retryCount + 1 < 3`, set `status = 'pending'` (stays in queue for next sync cycle) with `retryCount` incremented
    - Add exponential backoff: `nextRetryAt` is not tracked in the table for this story (deferred to a hardening pass); the 3-retry count limit is sufficient for ARCH-26 compliance in this story
  - [x] Add `_onOperationFailed` private method stub:
    ```dart
    /// Called when an operation exceeds max retries.
    /// Story 7.6: logs the failure. Real push notification deferred to Story 11.x.
    void _onOperationFailed(PendingOperation op) {
      debugPrint(
        'SyncManager: operation ${op.type} (id=${op.id}) '
        'exceeded max retries and is marked failed (ARCH-26, NFR-R5).',
      );
      // TODO(11.x): push a local notification to the user via flutter_local_notifications
    }
    ```
  - [x] Add import `package:flutter/foundation.dart` show `debugPrint` if not already present
  - [x] **IMPORTANT:** The `catch (_)` at line 150 is existing code — do NOT change it to `catch (e)`. The rule "catch(e) not catch(_)" applies to new code written for Story 7.6 features. Modifying existing `SyncManager` internals is a separate refactor.

---

### Flutter: Wire `OfflineProofSubView` into `ProofCaptureModal` (AC: 4)

- [x] Modify `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`
  - [x] Add import: `'offline_proof_sub_view.dart'`
  - [x] In `_buildSubView`, add a branch for `ProofPath.offline` BEFORE the catch-all stub (which currently handles it):
    ```dart
    // ── Offline path — real implementation (Story 7.6) ────────────────────
    if (path == ProofPath.offline) {
      assert(
        widget.taskId != null && widget.proofRepository != null,
        'ProofCaptureModal: taskId and proofRepository are required for offline path.',
      );
      if (widget.taskId != null && widget.proofRepository != null) {
        return OfflineProofSubView(
          taskId: widget.taskId!,
          taskName: widget.taskName,
          proofRepository: widget.proofRepository!,
          onQueued: () {
            setState(() {
              _submissionState = const ProofSubmissionSubmitted();
            });
          },
        );
      }
    }
    ```
  - [x] The `onQueued` callback and `ProofSubmissionSubmitted` wiring must match photo, screenshot, watchMode, and healthKit paths exactly
  - [x] The `_isOffline` check that gates the offline row in `_buildPathSelector` (line 199–207) must NOT be touched — it already correctly shows the row only when offline
  - [x] The catch-all stub block at the bottom of `_buildSubView` remains for any future paths; the comment should be updated from `// ── Other paths — stub placeholder (Stories 7.4–7.6) ─────` to `// ── Other paths — stub placeholder (Stories 7.7+) ─────`

---

### Flutter: Wire `connectivity_plus` reconnect to trigger `SyncManager.processQueue` (AC: 2–3)

- [x] Create `apps/flutter/lib/core/sync/connectivity_sync_listener.dart`
  - [x] `ConsumerStatefulWidget` that can be placed high in the widget tree (e.g., in the app shell)
  - [x] Constructor: no required params; uses `ref.read(syncManagerProvider.notifier)` and `ref.read(proofRepositoryProvider)` (see proofRepositoryProvider task below)
  - [x] In `initState`, subscribe to `Connectivity().onConnectivityChanged`:
    ```dart
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline && !_wasPreviouslyOnline) {
          _wasPreviouslyOnline = true;
          _triggerSync();
        } else if (!isOnline) {
          _wasPreviouslyOnline = false;
        }
      },
    );
    ```
  - [x] `_wasPreviouslyOnline` bool field, initialized by checking current connectivity in `initState` (call `Connectivity().checkConnectivity()` on init and set `_wasPreviouslyOnline` from the result)
  - [x] `_triggerSync()` method:
    ```dart
    Future<void> _triggerSync() async {
      if (!mounted) return;
      try {
        final proofRepo = ref.read(proofRepositoryProvider);
        final syncManager = ref.read(syncManagerProvider.notifier);
        await syncManager.processQueue(
          serverStateResolver: (type, payload) async {
            if (type == 'SUBMIT_PROOF') {
              // Proof submission: task always exists on server (no tombstone logic).
              // Return a sentinel state so conflict resolution treats as noConflict.
              return {'lastModifiedAt': null};
            }
            return null; // Unknown type — drop the operation.
          },
          applyOperation: (type, payload) async {
            if (type == 'SUBMIT_PROOF') {
              final taskId = payload['taskId'] as String;
              final clientTs = DateTime.parse(
                payload['clientTimestamp'] as String? ??
                    DateTime.now().toIso8601String(),
              );
              await proofRepo.submitOfflineProof(taskId, clientTs);
            }
          },
        );
      } catch (e) {
        debugPrint('ConnectivitySyncListener: sync error: $e');
      }
    }
    ```
  - [x] `dispose()`: cancel the connectivity stream subscription
  - [x] `build()` returns `widget.child` (this widget wraps the app shell)
  - [x] **`if (!mounted) return;` after every async gap**
  - [x] **Imports:**
    - `package:connectivity_plus/connectivity_plus.dart`
    - `package:flutter/cupertino.dart` (for Widget)
    - `package:flutter/foundation.dart` show `debugPrint`
    - `package:flutter_riverpod/flutter_riverpod.dart`
    - `package:riverpod_annotation/riverpod_annotation.dart`
    - `'../storage/database.dart'` (for `appDatabaseProvider`)
    - `'sync_manager.dart'`
    - `'../../features/proof/data/proof_repository.dart'`
  - [x] Constructor:
    ```dart
    const ConnectivitySyncListener({
      super.key,
      required this.child,
    });
    final Widget child;
    ```

---

### Flutter: Add `proofRepositoryProvider` Riverpod provider (AC: 2)

- [x] Modify `apps/flutter/lib/features/proof/data/proof_repository.dart`
  - [x] Add Riverpod provider at the bottom of the file (following the pattern of other repository providers in the codebase):
    ```dart
    /// Provides [ProofRepository] with injected [ApiClient] and [AppDatabase].
    ///
    /// keepAlive: true — proof repository must persist across route transitions.
    @Riverpod(keepAlive: true)
    ProofRepository proofRepository(Ref ref) {
      final client = ref.read(apiClientProvider);
      final db = ref.read(appDatabaseProvider);
      return ProofRepository(client, db);
    }
    ```
  - [x] Add imports:
    - `import 'package:riverpod/riverpod.dart';`
    - `import 'package:riverpod_annotation/riverpod_annotation.dart';`
    - `import '../../../core/network/api_client.dart';` (already present)
    - `import '../../../core/storage/database.dart';` (to be added)
  - [x] Add `part 'proof_repository.g.dart';`
  - [x] Run `build_runner` to generate `proof_repository.g.dart` — add to the file list
  - [x] **IMPORTANT:** Existing callers that construct `ProofRepository(ApiClient(...))` directly (tests, `NowTaskCard`, etc.) will need to pass `AppDatabase` as the second argument or use the new provider. Check `ProofCaptureModal` to see if it uses a constructor-injected repo or the provider — if constructor-injected, pass `appDatabaseProvider` through or update callers.
    - `ProofCaptureModal` receives `ProofRepository?` via constructor — callers pass it in. Those callers (e.g., `NowTaskCard`) create `ProofRepository` directly. Update those instantiation sites to pass the database: `ProofRepository(apiClient, ref.read(appDatabaseProvider))`.
    - In tests, update `MockProofRepository` — since it uses `mocktail`, no constructor change needed (mock doesn't call super).

---

### Flutter: Update API stub `proof.ts` to support `proofType=offline` (AC: 2)

- [x] Modify `apps/api/src/routes/proof.ts`
  - [x] Update `proofType` query param enum: `z.enum(['photo', 'screenshot', 'watchMode', 'healthKit', 'offline']).optional()`
  - [x] Update the route `description` to mention FR37 (offline queued proof) in addition to existing references
  - [x] Update top-of-file comment to include `Stories 7.2–7.6`
  - [x] When `proofType === 'offline'`, the existing stub response shape works unchanged (`{ verified: true, reason: null, taskId }`) — add a comment: `// offline path: clientTimestamp validated server-side; charge reversal triggered if predates task deadline`
  - [x] Add: `// TODO(impl): Story 7.6 — read clientTimestamp from request body; compare against task deadline; trigger charge reversal via stripe service if clientTimestamp < deadline`

---

### Flutter: Add l10n strings (AC: 1, 4)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Offline Proof Queue (FR37, ARCH-26, Story 7.6) ──` section:
  ```dart
  // ── Offline Proof Queue (FR37, ARCH-26, Story 7.6) ──────────────────────────

  /// OfflineProofSubView title.
  static const String offlineProofTitle = 'Save for Later';

  /// Body copy explaining offline queuing.
  static const String offlineProofBody =
      'Your proof will be saved on this device and submitted automatically when you\u2019re back online.';

  /// CTA to save proof for later sync.
  static const String offlineProofSaveCta = 'Save for Later';

  /// Copy shown while the enqueue write is in progress.
  static const String offlineProofQueueingCopy = 'Saving\u2026';

  /// Confirmation shown after successful enqueue (NFR-UX1).
  static const String offlineProofQueuedConfirmation =
      'Proof saved \u2014 will sync when you\u2019re back online';

  /// Error copy when enqueue write fails.
  static const String offlineProofErrorCopy =
      'Couldn\u2019t save your proof. Please try again.';
  ```
  - [x] Do NOT duplicate `proofPathOfflineTitle` (`'Save for Later'`) and `proofPathOfflineSubtitle` — those are the PATH SELECTOR strings; `offlineProofTitle` and `offlineProofSaveCta` are the SUB-VIEW strings. They happen to share the same text but are separate constants for separate UI contexts.
  - [x] Reuse existing strings in `OfflineProofSubView`:
    - `AppStrings.proofModalBack` — back button label
    - `AppStrings.watchModeTryAgainCta` — "Try again" CTA in error state

---

### Flutter: Tests (AC: 1–4)

- [x] Create `apps/flutter/test/features/proof/offline_proof_sub_view_test.dart`
  - [x] Follow the EXACT test scaffold from `health_kit_proof_sub_view_test.dart` and `screenshot_proof_sub_view_test.dart`:
    - Wrap in `MaterialApp` with `AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay')`
    - Mock `ProofRepository` using `mocktail` (`class MockProofRepository extends Mock implements ProofRepository {}`)
  - [x] **Minimum 10 widget tests:**
    1. Idle state renders `offlineProofTitle` text
    2. Idle state renders `offlineProofBody` text
    3. Idle state renders `offlineProofSaveCta` button
    4. Idle state renders back button (chevron left) that pops with null
    5. Tapping "Save for Later" transitions to `queuing` state showing activity indicator
    6. After `enqueueOfflineProof` returns successfully — shows `queued` state with `offlineProofQueuedConfirmation`
    7. Queued state renders `CupertinoIcons.checkmark_circle_fill` icon
    8. Tapping "Done" in queued state pops with `ProofPath.offline`
    9. After `enqueueOfflineProof` throws — shows `error` state with `offlineProofErrorCopy`
    10. Tapping "Try again" in error state returns to idle state
    11. `onQueued` callback is invoked after successful enqueue
  - [x] `MockProofRepository.enqueueOfflineProof` must be registered as a stub in each test that reaches queuing state:
    ```dart
    when(() => mockRepo.enqueueOfflineProof(any())).thenAnswer((_) async {});
    ```
  - [x] For error path test, stub to throw:
    ```dart
    when(() => mockRepo.enqueueOfflineProof(any()))
        .thenThrow(Exception('DB write failed'));
    ```

- [x] Create `apps/flutter/test/core/sync/connectivity_sync_listener_test.dart`
  - [x] Mock `SyncManager` and `ProofRepository`
  - [x] Stub `Connectivity` platform channel (use `MethodChannel('dev.fluttercommunity.plus/connectivity')`)
  - [x] **Minimum 4 tests:**
    1. No sync triggered when device stays offline
    2. Sync triggered once when connectivity transitions from none → wifi
    3. Sync NOT triggered again on consecutive online events (debounce: only triggers on transition from offline → online)
    4. Sync error is caught and logged via debugPrint — does not throw or crash the listener

- [x] Update `apps/flutter/test/features/proof/proof_capture_modal_test.dart`
  - [x] Add one test: selecting the offline path (when `_isOffline == true`) renders `OfflineProofSubView` content (shows `offlineProofTitle`)
  - [x] Stub `Connectivity().checkConnectivity()` to return `[ConnectivityResult.none]` in this test to trigger `_isOffline = true`

---

## Dev Notes

### CRITICAL: `OfflineProofSubView` lives in `proof/presentation/` — NOT a new feature directory

Unlike `WatchModeSubView` (which lives in `watch_mode/` per ARCH assignment), the offline proof sub-view is logically part of the proof flow. Place it at `apps/flutter/lib/features/proof/presentation/offline_proof_sub_view.dart` — consistent with `HealthKitProofSubView` and `ScreenshotProofSubView`.

### CRITICAL: `StatefulWidget` not `ConsumerStatefulWidget`

`OfflineProofSubView` must be a plain `StatefulWidget`. No Riverpod reads at widget level. `ProofRepository` is injected via constructor. This pattern is consistent across Stories 7.2–7.5. The only Riverpod usage is in `ConnectivitySyncListener` (which uses `ConsumerStatefulWidget` because it reads providers).

### CRITICAL: `clientTimestamp` is set at enqueue time, NOT at sync time (ARCH-26)

The `PendingOperations.clientTimestamp` column comment explicitly states: "Timestamp captured at operation CREATION — never updated on sync." The `enqueueOfflineProof` method must capture `DateTime.now()` at the moment the user taps "Save for Later" and pass it to `PendingOperationsCompanion.insert(clientTimestamp: now)`. The `SyncManager.processQueue` reads `op.clientTimestamp` from the DB row and passes it to `applyOperation` — it does NOT re-capture `DateTime.now()`.

### CRITICAL: `SyncManager.processQueue` requires callback injection — use `ConnectivitySyncListener`

The `SyncManager` class is a command object with no built-in connectivity awareness — this is by design (see docstring line 75–78): "connectivity_plus integration is wired externally — this class exposes processQueue for the caller to invoke when connectivity is restored." This keeps SyncManager testable. The `ConnectivitySyncListener` widget is the externally-wired caller. It subscribes to `Connectivity().onConnectivityChanged` and invokes `processQueue` when reconnect is detected.

### CRITICAL: `serverStateResolver` for `SUBMIT_PROOF` must NOT return null

In `SyncManager.processQueue`, returning `null` from `serverStateResolver` means "entity deleted server-side — drop the operation." For proof submissions, the task still exists on the server even if we can't verify quickly — return `{'lastModifiedAt': null}` so the conflict resolution falls through to `noConflict` and `applyOperation` is called.

### CRITICAL: Max 3 retries with exponential backoff (ARCH-26)

ARCH-26 specifies: "max 3 retries with exponential backoff; status → `failed` after 3 failures (never silently queue forever)." The `PendingOperations.retryCount` column already tracks attempts. The `SyncManager` already increments `retryCount` and sets `status = 'failed'` on catch. This story extends that logic to check `retryCount + 1 >= 3` → final failure with user notification stub. True exponential backoff delay (wait 1s, 2s, 4s between attempts) is deferred — the 3-attempt limit is enforced per sync cycle.

### CRITICAL: `ProofRepository` constructor now requires `AppDatabase`

Adding `_db` to `ProofRepository` is a breaking constructor change. All existing instantiation sites must be updated:
- `apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart` — find where `ProofRepository` is created and add the second `db` argument
- `apps/flutter/test/features/proof/*_test.dart` — all test files use `MockProofRepository extends Mock implements ProofRepository` via mocktail, so no constructor change needed in test mocks

Check for ALL construction sites:
```bash
grep -rn "ProofRepository(" apps/flutter/lib/ --include="*.dart"
```

### CRITICAL: `withValues(alpha:)` not `withOpacity()`

Consistent with Stories 7.2–7.5. If any colour opacity adjustments are needed in `OfflineProofSubView` or `ConnectivitySyncListener`, use `.withValues(alpha: value)`. `withOpacity()` is deprecated.

### CRITICAL: `minimumSize: const Size(44, 44)` on all interactive elements

Every `CupertinoButton` in `OfflineProofSubView` ("Save for Later", "Done", "Try again", back button) must have `minimumSize: const Size(44, 44)`.

### CRITICAL: `if (!mounted) return;` after every async gap

After `await widget.proofRepository.enqueueOfflineProof(...)`, after any `await` in `ConnectivitySyncListener._triggerSync()`, and after `await Connectivity().checkConnectivity()` in listener init.

### CRITICAL: `catch (e)` not `catch (_)` for new code

All new error handlers in `OfflineProofSubView._onSaveForLater()` and `ConnectivitySyncListener._triggerSync()` use `catch (e)`. The existing `catch (_)` inside `SyncManager.processQueue` (lines 150, 266) is pre-existing — do NOT change it.

### CRITICAL: No GoRouter route registration

`OfflineProofSubView` and `ConnectivitySyncListener` are NOT GoRouter routes. Do NOT touch `apps/flutter/lib/core/router/`.

### Architecture: `SyncManager` classifies `SUBMIT_PROOF` as a content operation

In `SyncManager._classifyOperation`, the `structuralTypes` set does not include `'SUBMIT_PROOF'`, so it defaults to `_PropertyType.content`. Content operations use last-write-wins. Since `serverStateResolver` returns `{'lastModifiedAt': null}` for proof submissions, `_parseServerLastModified` returns `null`, and `_resolveConflict` returns `ConflictResolutionOutcome.noConflict`. This means `applyOperation` is always called for `SUBMIT_PROOF` operations — correct behaviour.

### Architecture: `PendingOperations` payload schema for `SUBMIT_PROOF`

The JSON payload stored in `PendingOperations.payload` for offline proof must include:
```json
{
  "taskId": "abc-123",
  "proofType": "offline",
  "clientTimestamp": "2026-04-01T14:30:00.000Z"
}
```
Wait — the `clientTimestamp` is already stored as a separate Drift column (`PendingOperations.clientTimestamp`). However, to pass it cleanly through `SyncManager.processQueue`'s `applyOperation` callback (which only receives `payload`), also embed it in the JSON payload. This avoids `ConnectivitySyncListener` needing to reach back into the DB row.

Actually, look at `SyncManager.processQueue` — it passes `payload` to `applyOperation` but NOT `op.clientTimestamp` separately. Therefore the `clientTimestamp` MUST be embedded in the payload JSON. Embed it during `enqueueOfflineProof`:
```dart
final payload = jsonEncode({
  'taskId': taskId,
  'proofType': 'offline',
  'clientTimestamp': now.toIso8601String(),
});
```
The Drift column `clientTimestamp` is set to `now` for the `SyncManager`'s conflict resolution logic, and the JSON `clientTimestamp` field is used by `ConnectivitySyncListener.applyOperation` to reconstruct the original timestamp.

### Architecture: File locations

```
apps/flutter/lib/features/proof/
├── data/
│   ├── proof_repository.dart               # MODIFY — add AppDatabase param, enqueueOfflineProof, submitOfflineProof, proofRepositoryProvider
│   └── proof_repository.g.dart             # GENERATE — new file via build_runner
└── presentation/
    ├── proof_capture_modal.dart             # MODIFY — route ProofPath.offline to OfflineProofSubView
    └── offline_proof_sub_view.dart          # NEW — offline queuing UI

apps/flutter/lib/core/sync/
├── sync_manager.dart                        # MODIFY — add 3-retry limit and _onOperationFailed stub
└── connectivity_sync_listener.dart          # NEW — wires connectivity_plus to SyncManager

apps/api/src/routes/
└── proof.ts                                 # MODIFY — add 'offline' to proofType enum

apps/flutter/lib/core/l10n/
└── strings.dart                             # MODIFY — add offline proof strings

apps/flutter/test/features/proof/
├── offline_proof_sub_view_test.dart         # NEW
└── proof_capture_modal_test.dart            # MODIFY — add offline path test

apps/flutter/test/core/sync/
└── connectivity_sync_listener_test.dart     # NEW
```

### Architecture: How `ConnectivitySyncListener` is placed in the widget tree

`ConnectivitySyncListener` should be inserted above the `MaterialApp` or inside the top-level `ProviderScope` wrapper — at the same level as other app-wide listeners. It wraps a `child` and returns it via `build()`. It does not affect the visual tree. Typical placement:

```dart
// In main.dart or app.dart
ProviderScope(
  child: ConnectivitySyncListener(
    child: MaterialApp.router(/* ... */),
  ),
);
```

This ensures the listener is alive for the full app lifecycle and can read Riverpod providers. Check `apps/flutter/lib/main.dart` for the actual widget tree structure before placing.

### Context from Prior Stories

- **`ProofPath.offline` enum value** — already defined in `apps/flutter/lib/features/proof/domain/proof_path.dart` since Story 7.1. `ProofPath.fromJson('offline')` already works.
- **`_isOffline` flag in `ProofCaptureModal`** — already computed via `Connectivity().checkConnectivity()` in `initState` (line 63–78 of `proof_capture_modal.dart`). The offline row is already shown only when `_isOffline == true` (line 199–207). This story only needs to replace the stub sub-view with `OfflineProofSubView`.
- **`PendingOperations` Drift table** — already defined at `apps/flutter/lib/core/storage/pending_operations.dart` with columns: `id` (autoincrement), `type`, `payload`, `createdAt`, `retryCount` (default 0), `clientTimestamp`, `status` (default 'pending').
- **`AppDatabase`** — at `apps/flutter/lib/core/storage/database.dart`. Provider: `appDatabaseProvider`. The `PendingOperations` table accessor is `db.pendingOperations`.
- **`SyncManager`** — at `apps/flutter/lib/core/sync/sync_manager.dart`. Riverpod provider: `syncManagerProvider` (generated via `@Riverpod(keepAlive: true)`). Exposes `processQueue({serverStateResolver, applyOperation})`. Does NOT self-trigger on connectivity — caller must invoke.
- **`ProofRepository` constructor** — currently `ProofRepository(this._client)` with only `ApiClient`. This story changes it to `ProofRepository(this._client, this._db)`. Update all call sites.
- **`WatchModeSubView._onDone()` deferred issue** — from `deferred-work.md`: "pops with non-null value, triggering `onComplete` when user exits without submitting proof." Do NOT replicate this bug. In `OfflineProofSubView`, the back button (idle state) must pop with `null`, and "Done" in the queued state pops with `ProofPath.offline` (which IS a non-null signal of successful queuing — this is intentional and correct).
- **`ProofSubmissionSubmitted` state** — `onQueued` callback in `ProofCaptureModal` sets `_submissionState = const ProofSubmissionSubmitted()`. This is the same wiring used for `onApproved` in all other sub-views. The `ProofSubmissionState` sealed class lives at `apps/flutter/lib/features/proof/domain/proof_submission_state.dart`.

### Deferred Items for This Story

- **`ConnectivitySyncListener` placed but not mount-validated** — the exact insertion point in the widget tree (`main.dart` vs `app.dart`) should be verified during dev; the story spec says "above MaterialApp." Check the actual widget tree.
- **True exponential backoff delay** — ARCH-26 says "exponential backoff" but does not specify delays between sync cycles. For this story, the 3-attempt limit per reconnect cycle satisfies the spec. Proper `nextRetryAt` scheduling (wait 1s/2s/4s) is deferred to a future hardening story.
- **Local push notification on `failed`** — `_onOperationFailed` is a stub with `debugPrint`. Real push notification ("Your offline proof couldn't sync") is deferred to Story 11.x when `flutter_local_notifications` is integrated.
- **`clientTimestamp` in payload vs Drift column redundancy** — the timestamp is stored twice (Drift column + JSON payload). The Drift column is used by `SyncManager` conflict resolution; the JSON field is used by `applyOperation`. This redundancy is acceptable for this story; refactor when conflict resolution is revisited.

## Story Checklist

- [x] Story title matches epic definition
- [x] User story statement present (As a / I want / So that)
- [x] Acceptance criteria are testable and complete
- [x] All file paths are absolute/fully qualified
- [x] Constructor/API patterns match established codebase patterns
- [x] `StatefulWidget` (not `ConsumerStatefulWidget`) for sub-views
- [x] `withValues(alpha:)` not `withOpacity()` noted
- [x] `minimumSize: const Size(44, 44)` on all interactive elements noted
- [x] `mounted` check after every `await` noted
- [x] `catch (e)` not `catch (_)` for new code noted
- [x] No GoRouter registration for sub-view
- [x] Drift/database patterns match existing `pending_operations.dart`
- [x] `SyncManager` callback injection pattern preserved
- [x] `clientTimestamp` immutability (ARCH-26) enforced in spec
- [x] Test scaffold follows `health_kit_proof_sub_view_test.dart` pattern
- [x] Deferred items documented
- [x] Status set to ready-for-dev

### Review Findings

- [ ] [Review][Patch] Remove unused `package:drift/drift.dart show Value` import — `Value` is imported but never called (0 usages of `Value(`)  [`apps/flutter/lib/features/proof/data/proof_repository.dart:5`]
- [ ] [Review][Patch] Remove unused `package:riverpod/riverpod.dart` import — not a direct `pubspec.yaml` dependency; `Ref` is available via `riverpod_annotation` [`apps/flutter/lib/features/proof/data/proof_repository.dart:6`]
- [ ] [Review][Patch] Remove unused `sync_manager.dart` import in test — `SyncManager`/`syncManagerProvider` symbols appear only in a comment, not as callable references [`apps/flutter/test/core/sync/connectivity_sync_listener_test.dart:10`]
- [ ] [Review][Patch] Missing `if (!mounted) return;` before stream subscription in `_initConnectivity` — if `checkConnectivity()` throws and the widget has been disposed, the catch block runs with no mounted guard, then `_connectivitySub` is assigned post-dispose. `dispose()` has already run so the subscription is never cancelled (resource leak). Add `if (!mounted) return;` after the closing `}` of the try/catch, before the `_connectivitySub =` line [`apps/flutter/lib/core/sync/connectivity_sync_listener.dart:56`]
- [ ] [Review][Patch] clientTimestamp fallback uses `DateTime.now()` instead of preserving original capture time — in `_triggerSync` `applyOperation`, if `payload['clientTimestamp']` key is absent the fallback `?? DateTime.now().toIso8601String()` silently uses the current time, defeating ARCH-26. Should use a fallback that preserves intent (e.g., log and skip, or document clearly that this case is unreachable). [`apps/flutter/lib/core/sync/connectivity_sync_listener.dart:81-85`]
- [ ] [Review][Patch] Misleading test comment — "Uses a real SyncManager with in-memory Drift database" but the test overrides `proofRepositoryProvider` with a mock and never exercises real SyncManager DB operations [`apps/flutter/test/core/sync/connectivity_sync_listener_test.dart:16`]

## Dev Agent Record

### Implementation Plan

Implemented all tasks in story order:
1. Added l10n strings (6 new constants under `// ── Offline Proof Queue` section)
2. Created `OfflineProofSubView` — plain `StatefulWidget` with 4-state machine (idle/queuing/queued/error)
3. Modified `ProofRepository` — added `AppDatabase _db` param, `enqueueOfflineProof`, `submitOfflineProof`, and `proofRepositoryProvider` Riverpod provider
4. Updated `now_screen.dart` call site to pass `appDatabaseProvider` as second argument
5. Extended `SyncManager.processQueue` catch block to enforce 3-retry limit (ARCH-26); added `_onOperationFailed` stub
6. Wired `OfflineProofSubView` into `ProofCaptureModal._buildSubView` before the stub catch-all
7. Created `ConnectivitySyncListener` — `ConsumerStatefulWidget` subscribing to `connectivity_plus` stream, triggers `SyncManager.processQueue` on offline→online transition
8. Updated `proof.ts` API stub — added `'offline'` to `proofType` enum, updated description/comments for FR37
9. Placed `ConnectivitySyncListener` in `main.dart` wrapping `OnTaskApp` inside `ProviderScope`
10. Created 11 widget tests for `OfflineProofSubView`, 4 widget tests for `ConnectivitySyncListener`, added 1 test to `proof_capture_modal_test.dart`
11. Ran `build_runner` to generate `proof_repository.g.dart`

### Completion Notes

- All 11 `OfflineProofSubView` tests pass (idle state, queuing/queued/error transitions, onQueued callback)
- All 4 `ConnectivitySyncListener` tests pass (no sync offline, sync on transition, debounce, error caught)
- 1 new `ProofCaptureModal` test added (offline path renders `OfflineProofSubView`)
- 2 existing `ProofCaptureModal` tests updated to reflect `OfflineProofSubView` (no longer stub)
- Full regression suite: 0 failures across all tests
- `clientTimestamp` embedded in both Drift column AND JSON payload (ARCH-26 compliance)
- `ConnectivitySyncListener` placed in `main.dart` above `OnTaskApp`, inside `ProviderScope`
- `_onOperationFailed` is a stub with `debugPrint` per story spec (push notification deferred to Story 11.x)

## File List

### New Files
- `apps/flutter/lib/features/proof/presentation/offline_proof_sub_view.dart`
- `apps/flutter/lib/core/sync/connectivity_sync_listener.dart`
- `apps/flutter/lib/features/proof/data/proof_repository.g.dart`
- `apps/flutter/test/features/proof/offline_proof_sub_view_test.dart`
- `apps/flutter/test/core/sync/connectivity_sync_listener_test.dart`

### Modified Files
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/flutter/lib/features/proof/data/proof_repository.dart`
- `apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart`
- `apps/flutter/lib/core/sync/sync_manager.dart`
- `apps/flutter/lib/features/now/presentation/now_screen.dart`
- `apps/flutter/lib/main.dart`
- `apps/api/src/routes/proof.ts`
- `apps/flutter/test/features/proof/proof_capture_modal_test.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-04-01: Story 7.6 implemented — Offline Proof Queue. New `OfflineProofSubView` widget, `ConnectivitySyncListener`, `enqueueOfflineProof`/`submitOfflineProof` methods on `ProofRepository`, 3-retry limit enforced in `SyncManager`, `proofRepositoryProvider` added, `main.dart` wired with `ConnectivitySyncListener`. 16 new tests added, 2 existing tests updated. All tests pass. Status → review.
