# Story 7.7: Proof Retention Settings

Status: review

## Story

As a user,
I want control over whether my submitted proof is kept as a permanent record,
So that I can keep meaningful evidence without accumulating storage I don't want.

## Acceptance Criteria

1. **Given** the user is submitting proof (any proof type)
   **When** the proof is being confirmed (after AI verification succeeds or HealthKit/offline queuing completes)
   **Then** they are offered two options: "Keep as completion record" or "Submit and discard" (FR38)
   **And** the currently-selected option reflects their global default preference stored in `SharedPreferences` (key: `'proof_retain_default'`, default: `true` — keep)

2. **Given** the user changes their default in Settings → Privacy
   **When** they toggle the "Keep proof by default" setting
   **Then** the new default is persisted to `SharedPreferences` key `'proof_retain_default'`
   **And** future proof submissions pre-select the new default

3. **Given** the user chooses to retain proof
   **When** verification succeeds (or queuing completes for offline)
   **Then** the proof is stored in private Backblaze B2 scoped to the task owner (NFR-S4)
   **And** `proofRetained = true` is set on the task record (tasks table `proof_retained` column, already in schema)
   **And** retained proof persists until the parent task is permanently deleted (NFR-R8)
   **And** retained proof is accessible from task history and shared list proof view (FR21)

4. **Given** the user chooses to discard proof
   **When** verification succeeds
   **Then** `proofRetained = false` is set on the task record
   **And** the API schedules media deletion from B2 storage within 24 hours of successful processing

## Tasks / Subtasks

---

### Flutter: Add `proofRetainDefault` SharedPreferences provider (AC: 1, 2)

- [x]Modify `apps/flutter/lib/core/theme/theme_provider.dart` OR create a new file `apps/flutter/lib/features/proof/data/proof_prefs_provider.dart`
  - [x]Prefer a **new file** `apps/flutter/lib/features/proof/data/proof_prefs_provider.dart` to keep concerns separate from theme
  - [x]Follow the exact pattern of `themeVariantProvider` in `theme_provider.dart` — `@Riverpod(keepAlive: true)` async provider reading from `SharedPreferences`
  - [x]Read provider:
    ```dart
    /// Async provider that loads the user's proof retention default from
    /// [SharedPreferences].
    ///
    /// Defaults to `true` (keep proof) if no preference has been stored.
    /// SharedPreferences key: `'proof_retain_default'`
    ///
    /// keepAlive: prevents repeated SharedPreferences reads on every rebuild.
    @Riverpod(keepAlive: true)
    Future<bool> proofRetainDefault(Ref ref) async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('proof_retain_default') ?? true;
    }
    ```
  - [x]Notifier for writing:
    ```dart
    @Riverpod(keepAlive: true)
    class ProofRetainSettings extends _$ProofRetainSettings {
      @override
      void build() {}

      Future<void> setRetainDefault(bool retain) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('proof_retain_default', retain);
        ref.invalidate(proofRetainDefaultProvider);
      }
    }
    ```
  - [x]Add `part 'proof_prefs_provider.g.dart';` and run `build_runner` to generate
  - [x]**Imports needed:**
    - `package:riverpod_annotation/riverpod_annotation.dart`
    - `package:shared_preferences/shared_preferences.dart`
    - `package:flutter_riverpod/flutter_riverpod.dart` (for `Ref`)

---

### Flutter: Add retention choice to `PhotoCaptureSubView` approved state (AC: 1, 3, 4)

- [x]Modify `apps/flutter/lib/features/proof/presentation/photo_capture_sub_view.dart`
  - [x]Change from `StatefulWidget` to `ConsumerStatefulWidget` (needs Riverpod to read `proofRetainDefaultProvider`)
    - **IMPORTANT:** All other proof sub-views that do NOT need the pref can remain `StatefulWidget`. Only sub-views that show the retain choice need `ConsumerStatefulWidget`.
  - [x]Add a `bool _retainProof` field initialized from the pref in `didChangeDependencies` (or `initState` using `ref.read`):
    ```dart
    @override
    void initState() {
      super.initState();
      // Read synchronously from provider cache — keepAlive provider is pre-loaded.
      // Falls back to true if not yet resolved.
      _retainProof = ref.read(proofRetainDefaultProvider).valueOrNull ?? true;
    }
    ```
  - [x]In the approved state UI (after AI verification succeeds, `ProofVerificationApproved` case), **before** auto-dismissing or calling `onApproved`, present the retention choice inline:
    - A `CupertinoSwitch` (or equivalent toggle row) labeled `AppStrings.proofRetainLabel` ("Keep as completion record")
    - A secondary label: `AppStrings.proofRetainSubtitle` ("Proof stays attached to this task")
    - A "Confirm" CTA (`AppStrings.proofRetainConfirmCta`) that fires `_onConfirmRetention()`
    - **Do NOT auto-dismiss** after verification — wait for user to tap Confirm
  - [x]`_onConfirmRetention()` method:
    ```dart
    Future<void> _onConfirmRetention() async {
      try {
        await widget.proofRepository.setProofRetention(
          widget.taskId,
          retain: _retainProof,
        );
        if (!mounted) return;
        widget.onApproved?.call();
      } catch (e) {
        debugPrint('PhotoCaptureSubView: setProofRetention error: $e');
        if (!mounted) return;
        // Show error state — reuse proofRetakeCta or add new error string
      }
    }
    ```
  - [x]`minimumSize: const Size(44, 44)` on the Confirm CTA
  - [x]`if (!mounted) return;` after every `await`

---

### Flutter: Add retention choice to `ScreenshotProofSubView` approved state (AC: 1, 3, 4)

- [x]Modify `apps/flutter/lib/features/proof/presentation/screenshot_proof_sub_view.dart`
  - [x]Same pattern as `PhotoCaptureSubView`: change to `ConsumerStatefulWidget`, read `proofRetainDefaultProvider`, add retention toggle in approved state, call `proofRepository.setProofRetention()` before `onApproved`

---

### Flutter: Add retention choice to `HealthKitProofSubView` approved state (AC: 1, 3, 4)

- [x]Modify `apps/flutter/lib/features/proof/presentation/health_kit_proof_sub_view.dart`
  - [x]Same pattern as above — add retention toggle to the approved/verified state before calling `onApproved`

---

### Flutter: Add retention choice to `WatchModeSubView` approved state (AC: 1, 3, 4)

- [x]Modify `apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart`
  - [x]Same pattern — add retention toggle before calling `onApproved`
  - [x]**Note:** `WatchModeSubView._onDone()` has a known deferred bug (pops with non-null value even without proof submission — see `deferred-work.md`). Do NOT replicate this bug in the retention flow. The retention choice only appears when `_verificationState == _VerificationState.approved` (i.e., actual AI verification succeeded).

---

### Flutter: Add `setProofRetention` to `ProofRepository` (AC: 3, 4)

- [x]Modify `apps/flutter/lib/features/proof/data/proof_repository.dart`
  - [x]Add new method:
    ```dart
    /// Sets the proof retention preference for a submitted task.
    ///
    /// Calls PATCH /v1/tasks/{taskId}/proof-retention with `{ retain: bool }`.
    /// When retain=true, proof media is kept in B2 storage as a completion record (FR38, NFR-R8).
    /// When retain=false, media is scheduled for deletion within 24 hours (FR38).
    ///
    /// Sets proofRetained on the task record server-side.
    Future<void> setProofRetention(String taskId, {required bool retain}) async {
      await _client.dio.patch<void>(
        '/v1/tasks/$taskId/proof-retention',
        data: {'retain': retain},
      );
    }
    ```
  - [x]No `try/catch` in repository — exceptions propagate to the caller (sub-views handle error state)
  - [x]`catch (e)` NOT `catch (_)` if error handling is ever added here

---

### Flutter: Add Privacy section to `SettingsScreen` (AC: 2)

- [x]Modify `apps/flutter/lib/features/settings/presentation/settings_screen.dart`
  - [x]Change from `ConsumerStatefulWidget` to `ConsumerStatefulWidget` if not already (it is already a `ConsumerStatefulWidget`)
  - [x]Add a "Privacy" tile in the settings list (after Notifications, before Account is a logical placement):
    ```dart
    // ── Privacy ─────────────────────────────────────────────────────────────
    _SettingsTile(
      label: AppStrings.settingsPrivacy,
      icon: CupertinoIcons.hand_raised,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => const PrivacySettingsScreen(),
        ),
      ),
    ),
    ```
  - [x]Add import: `'privacy_settings_screen.dart'`

---

### Flutter: Create `PrivacySettingsScreen` (AC: 2)

- [x]Create `apps/flutter/lib/features/settings/presentation/privacy_settings_screen.dart`
  - [x]`ConsumerStatefulWidget` — reads and writes `proofRetainDefaultProvider` and `ProofRetainSettingsProvider`
  - [x]`CupertinoPageScaffold` with `CupertinoNavigationBar` title: `AppStrings.settingsPrivacy` ("Privacy")
  - [x]Content: a single toggle row using `CupertinoListTile` or custom layout:
    - Label: `AppStrings.privacyKeepProofByDefault` ("Keep proof by default")
    - Sublabel: `AppStrings.privacyKeepProofSubtitle` ("Proof photos and files are kept as completion records. Turn off to discard after verification.")
    - `CupertinoSwitch` bound to `proofRetainDefaultProvider` value; on change, calls `ref.read(proofRetainSettingsProvider.notifier).setRetainDefault(value)`
  - [x]Handle `AsyncValue` loading state — show `CupertinoActivityIndicator` while provider loads
  - [x]Follow the exact pattern of `AppearanceSettingsScreen` for layout and navigation bar style
  - [x]Imports:
    - `package:flutter/cupertino.dart`
    - `package:flutter_riverpod/flutter_riverpod.dart`
    - `'../../../core/l10n/strings.dart'`
    - `'../../../core/theme/app_theme.dart'`
    - `'../../proof/data/proof_prefs_provider.dart'`

---

### API: Add `PATCH /v1/tasks/{taskId}/proof-retention` route stub (AC: 3, 4)

- [x]Modify `apps/api/src/routes/proof.ts`
  - [x]Add new route stub for `PATCH /v1/tasks/{taskId}/proof-retention`:
    ```typescript
    const setProofRetentionRoute = createRoute({
      method: 'patch',
      path: '/v1/tasks/{taskId}/proof-retention',
      tags: ['Proof'],
      summary: 'Set proof retention preference for a submitted task',
      description:
        'Sets whether the submitted proof media is retained as a completion record on the task (FR38). ' +
        'retain=true: proof stored in B2 for task lifetime (NFR-R8, NFR-S4). ' +
        'retain=false: media scheduled for deletion within 24 hours of verification. ' +
        'Updates proof_retained column in tasks table. ' +
        'Stub implementation (Story 7.7) — real B2 deletion scheduling deferred.',
      request: {
        params: z.object({ taskId: z.string().min(1) }),
        body: {
          content: {
            'application/json': {
              schema: z.object({ retain: z.boolean() }),
            },
          },
        },
      },
      responses: {
        204: { description: 'Retention preference updated' },
        400: {
          content: { 'application/json': { schema: ErrorSchema } },
          description: 'Bad request',
        },
      },
    })
    ```
  - [x]Stub handler:
    ```typescript
    app.openapi(setProofRetentionRoute, async (c) => {
      // TODO(impl): update tasks.proof_retained column in DB for taskId
      // TODO(impl): if retain=false, enqueue B2 media deletion job (delete within 24h of verification)
      // TODO(impl): if retain=true, ensure B2 media is preserved; update proof_submissions.mediaUrl
      return c.body(null, 204)
    })
    ```
  - [x]Update top-of-file comment to include `Stories 7.2–7.7` and `FR38`
  - [x]Update `submitProofRoute` description to note FR38 retention choice presented post-verification

---

### Flutter: Add l10n strings (AC: 1, 2)

- [x]Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Proof Retention Settings (FR38, Story 7.7) ──` section after the Offline Proof Queue section:
  ```dart
  // ── Proof Retention Settings (FR38, NFR-R8, Story 7.7) ──────────────────────

  /// Toggle label on the proof confirmation screen.
  static const String proofRetainLabel = 'Keep as completion record';

  /// Secondary label explaining retention on the proof confirmation screen.
  static const String proofRetainSubtitle =
      'Proof stays attached to this task until it\u2019s deleted';

  /// Secondary label explaining discard on the proof confirmation screen.
  static const String proofDiscardSubtitle =
      'Proof will be deleted within 24 hours of verification';

  /// Confirm CTA after choosing retention preference.
  static const String proofRetainConfirmCta = 'Done';

  /// Settings screen Privacy tile label.
  static const String settingsPrivacy = 'Privacy';

  /// Privacy settings: keep proof toggle label.
  static const String privacyKeepProofByDefault = 'Keep proof by default';

  /// Privacy settings: keep proof toggle subtitle.
  static const String privacyKeepProofSubtitle =
      'Proof photos and files are kept as completion records. Turn off to discard after verification.';
  ```

---

### Flutter: Tests (AC: 1–4)

- [x]Create `apps/flutter/test/features/proof/privacy_settings_screen_test.dart`
  - [x]Follow the pattern of `appearance_settings_screen_test.dart` — use `ProviderScope` overrides
  - [x]**Minimum 4 tests:**
    1. Screen renders "Keep proof by default" toggle
    2. Toggle reflects `proofRetainDefaultProvider` value (default: `true`)
    3. Tapping toggle calls `ProofRetainSettings.setRetainDefault(false)` when previously true
    4. `CupertinoActivityIndicator` shown while `proofRetainDefaultProvider` is loading

- [x]Modify `apps/flutter/test/features/proof/photo_capture_sub_view_test.dart` (if it exists — check `apps/flutter/test/features/proof/`)
  - [x]Add test: approved state shows retention toggle pre-set to `proofRetainDefaultProvider` value
  - [x]Add test: tapping Confirm in approved state calls `proofRepository.setProofRetention(taskId, retain: true)`
  - [x]Add test: toggling to discard then Confirm calls `proofRepository.setProofRetention(taskId, retain: false)`
  - [x]Mock `ProofRepository` using `mocktail`:
    ```dart
    when(() => mockRepo.setProofRetention(any(), retain: any(named: 'retain')))
        .thenAnswer((_) async {});
    ```

- [x]Update `apps/flutter/test/features/settings/settings_screen_test.dart` (if exists)
  - [x]Add test: Privacy tile is present and taps navigate to `PrivacySettingsScreen`

## Dev Notes

### CRITICAL: `proofRetained` column already exists in DB schema — do NOT recreate

The `tasks` table already has `proofRetained: boolean().default(false).notNull()` at `packages/core/src/schema/tasks.ts:35`. The `TaskDto` and `Task` domain model already carry this field (`task_dto.dart:52`, `task.dart:53`). The `task_row.dart` widget already renders a "Proof submitted" badge when `task.completedAt != null && task.proofRetained` (`task_row.dart:141,341`). Do NOT add a duplicate column or field.

### CRITICAL: `StatefulWidget` → `ConsumerStatefulWidget` migration for sub-views

Stories 7.2–7.6 established that proof sub-views are plain `StatefulWidget`. Story 7.7 is the **first story** that requires sub-views to read a Riverpod provider (`proofRetainDefaultProvider`). Each sub-view that presents the retention choice must be migrated to `ConsumerStatefulWidget`. The pattern is the same as `ConnectivitySyncListener` from Story 7.6 — `ConsumerStatefulWidget` + `ConsumerState`.

**Updated import requirement:** Add `package:flutter_riverpod/flutter_riverpod.dart` to each migrated sub-view.

### CRITICAL: `withValues(alpha:)` not `withOpacity()`

Consistent with Stories 7.2–7.6. Any colour opacity adjustments use `.withValues(alpha: value)`. `withOpacity()` is deprecated.

### CRITICAL: `minimumSize: const Size(44, 44)` on all interactive elements

Every `CupertinoButton` and interactive element in the retention UI must have `minimumSize: const Size(44, 44)`.

### CRITICAL: `if (!mounted) return;` after every async gap

In `_onConfirmRetention()` and any async method in `PrivacySettingsScreen`, add `if (!mounted) return;` after every `await`.

### CRITICAL: `catch (e)` not `catch (_)` for new code

All new error handlers use `catch (e)`. Do not use `catch (_)`.

### CRITICAL: No GoRouter route registration

`PrivacySettingsScreen` is pushed via `CupertinoPageRoute` from `SettingsScreen` — NOT added to `AppRouter`. Do not touch `apps/flutter/lib/core/router/app_router.dart`.

### Architecture: SharedPreferences pattern follows `theme_provider.dart`

The `proof_prefs_provider.dart` file follows the identical pattern to `theme_provider.dart`:
- `@Riverpod(keepAlive: true)` async read provider
- `@Riverpod(keepAlive: true)` notifier class with write method
- `ref.invalidate(proofRetainDefaultProvider)` after writing to refresh UI

SharedPreferences key: `'proof_retain_default'` (bool, defaults to `true`).

### Architecture: Retention choice appears in the approved state, not before submission

The retention toggle is presented **after AI verification succeeds** (or after offline queuing succeeds). It is not a pre-submission option. The flow:

1. User submits proof → AI verification spins
2. AI returns approved → Approved state shows retention toggle
3. User chooses retain/discard → taps Confirm → `setProofRetention()` API call
4. On success → `onApproved?.call()` → modal closes

This differs from the PRD description ("offered a checkbox: 'Attach to completed task'") — the implementation post-dates the PRD's wording and places the choice at the confirmation moment. The UX spec (UX design doc line 195) confirms: "Proof retention (FR38) — user chooses whether proof is kept as a completion record."

### Architecture: API route `PATCH /v1/tasks/{taskId}/proof-retention`

New route in `apps/api/src/routes/proof.ts`. Stub returns 204 with a TODO to update DB and enqueue B2 deletion job. The real implementation (deferred) must:
1. Update `tasks.proof_retained = retain` in Neon DB via Drizzle ORM
2. If `retain = false`, enqueue a Cloudflare Queue message to delete the B2 object within 24 hours (using `proof-verification-consumer.ts` pattern or a new `proof-cleanup-consumer.ts`)

### Architecture: File locations

```
apps/flutter/lib/features/proof/
├── data/
│   ├── proof_repository.dart               # MODIFY — add setProofRetention method
│   └── proof_prefs_provider.dart           # NEW — proofRetainDefaultProvider + ProofRetainSettings
│   └── proof_prefs_provider.g.dart         # GENERATE — via build_runner
└── presentation/
    ├── photo_capture_sub_view.dart          # MODIFY — ConsumerStatefulWidget, retention toggle in approved state
    ├── screenshot_proof_sub_view.dart       # MODIFY — ConsumerStatefulWidget, retention toggle
    ├── health_kit_proof_sub_view.dart       # MODIFY — ConsumerStatefulWidget, retention toggle
    └── offline_proof_sub_view.dart          # NO CHANGE — offline queuing has no AI result to gate on

apps/flutter/lib/features/watch_mode/
└── presentation/
    └── watch_mode_sub_view.dart             # MODIFY — ConsumerStatefulWidget, retention toggle

apps/flutter/lib/features/settings/
└── presentation/
    ├── settings_screen.dart                 # MODIFY — add Privacy tile
    └── privacy_settings_screen.dart         # NEW — default retention toggle

apps/flutter/lib/core/l10n/
└── strings.dart                             # MODIFY — add proof retention + privacy strings

apps/api/src/routes/
└── proof.ts                                 # MODIFY — add PATCH /v1/tasks/{taskId}/proof-retention route

apps/flutter/test/features/proof/
└── privacy_settings_screen_test.dart        # NEW
```

### Architecture: `OfflineProofSubView` does NOT need the retention toggle

Offline proof does not have an immediate AI verification result — the proof is queued and submitted later. The retention choice for offline proof is shown when the `SyncManager` processes the queue and the server returns a verified result. This is deferred to a future story (post-7.7). For Story 7.7, `OfflineProofSubView` is unchanged.

### Architecture: `proofRetained` on the task card

`task_row.dart` already shows a "Proof submitted" label when `task.proofRetained == true` (lines 341–357). This behavior is preserved — Story 7.7 makes the condition reachable via the new retention flow. No changes to `task_row.dart`.

### Context from Prior Stories

- **`ProofRepository` constructor** — as of Story 7.6, constructor is `ProofRepository(this._client, this._db)`. The `setProofRetention` method only uses `_client` (no Drift DB needed).
- **`proofRepositoryProvider`** — defined in `proof_repository.dart` as a `@Riverpod(keepAlive: true)` provider. Use `ref.read(proofRepositoryProvider)` in sub-views that need it.
- **`WatchModeSubView` deferred bug** — `_onDone()` pops with non-null value even without proof submission (listed in `deferred-work.md`). The retention toggle in `WatchModeSubView` must only appear in the actual verification-approved state — do not trigger it from the `_onDone()` path.
- **Sub-view consistent style** — `CupertinoIcons.checkmark_circle_fill` with `colors.stakeZoneLow` at 48pt for approved state across all sub-views (from Stories 7.2–7.5).
- **`proof_submissions` table** — already has `mediaUrl`, `verified`, `proofPath` columns. `setProofRetention` updates `tasks.proof_retained`, NOT `proof_submissions`. These are separate records: `proof_submissions` is the AI verification record; `tasks.proof_retained` is the user's retention choice.
- **Settings navigation pattern** — all settings sub-screens use `CupertinoPageRoute<void>` pushed from `SettingsScreen`. `PrivacySettingsScreen` follows the same pattern as `AppearanceSettingsScreen` (already in `settings/presentation/`).
- **Build runner** — must be run after creating `proof_prefs_provider.dart` to generate `proof_prefs_provider.g.dart`. Add the generated file to the File List.

### Deferred Items for This Story

- **B2 deletion job** — real Backblaze B2 deletion scheduling on `retain=false` is deferred. The API stub returns 204; no actual object storage operations occur.
- **Offline proof retention choice** — the retention toggle after offline proof sync is deferred; the `SyncManager` path does not surface the UI.
- **Retention for Watch Mode HealthKit auto-verification** — HealthKit-triggered auto-verification (no user interaction) should apply the user's default automatically. Story 7.7 adds the UI for the manual paths; the auto-apply for headless verification is a backend concern, deferred to Story 7.x real implementation.
- **`proof_submissions.mediaUrl` presigned URL** — B2 upload and URL generation are deferred (marked TODO in `proof.ts`). `proofMediaUrl` on the task will remain null until real B2 integration lands.
- **Settings tile ordering** — "Privacy" tile placement in `SettingsScreen` should be reviewed during implementation against the final IA. Suggested placement: after Notifications, before Account.

## Story Checklist

- [x] Story title matches epic definition
- [x] User story statement present (As a / I want / So that)
- [x] Acceptance criteria are testable and complete
- [x] All file paths are absolute/fully qualified
- [x] Constructor/API patterns match established codebase patterns
- [x] `withValues(alpha:)` not `withOpacity()` noted
- [x] `minimumSize: const Size(44, 44)` on all interactive elements noted
- [x] `mounted` check after every `await` noted
- [x] `catch (e)` not `catch (_)` for new code noted
- [x] No GoRouter registration for new screens
- [x] SharedPreferences key documented (`'proof_retain_default'`)
- [x] Existing `proofRetained` DB column noted — no duplication
- [x] `StatefulWidget` → `ConsumerStatefulWidget` migration noted for sub-views
- [x] OfflineProofSubView correctly excluded from scope
- [x] WatchModeSubView deferred bug noted
- [x] Build runner requirement for generated file noted
- [x] Deferred items documented
- [x] Status set to ready-for-dev

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Migrated `PhotoCaptureSubView`, `ScreenshotProofSubView`, `HealthKitProofSubView`, and `WatchModeSubView` from `StatefulWidget` to `ConsumerStatefulWidget` to enable `proofRetainDefaultProvider` reads.
- `initState` uses `ref.read(proofRetainDefaultProvider).value ?? true` (not `.valueOrNull` which does not exist in Riverpod 3.x).
- All four sub-views show a `CupertinoSwitch` retention toggle + "Done" `CupertinoButton` in the approved state before calling `onApproved`.
- `PrivacySettingsScreen` uses `CupertinoPageScaffold` + `CupertinoNavigationBar`, follows `AppearanceSettingsScreen` pattern exactly.
- Privacy tile added to `SettingsScreen` after Notifications, before Account, using `CupertinoPageRoute` (not GoRouter).
- API stub `PATCH /v1/tasks/{taskId}/proof-retention` returns 204 with TODO comments for real B2/DB work.
- All existing test files for the migrated sub-views (`photo_capture_sub_view_test.dart`, `screenshot_proof_sub_view_test.dart`, `health_kit_proof_sub_view_test.dart`, `watch_mode_sub_view_test.dart`) updated with `ProviderScope` overrides and `_FakeProofRetainSettings` fake notifier.
- `build_runner` run to generate `proof_prefs_provider.g.dart`.
- Full test suite: 877 tests, all passed.

### File List

- `apps/flutter/lib/features/proof/data/proof_prefs_provider.dart` — NEW
- `apps/flutter/lib/features/proof/data/proof_prefs_provider.g.dart` — GENERATED
- `apps/flutter/lib/features/proof/data/proof_repository.dart` — MODIFIED (added `setProofRetention`)
- `apps/flutter/lib/features/proof/presentation/photo_capture_sub_view.dart` — MODIFIED (ConsumerStatefulWidget, retention toggle)
- `apps/flutter/lib/features/proof/presentation/screenshot_proof_sub_view.dart` — MODIFIED (ConsumerStatefulWidget, retention toggle)
- `apps/flutter/lib/features/proof/presentation/health_kit_proof_sub_view.dart` — MODIFIED (ConsumerStatefulWidget, retention toggle)
- `apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart` — MODIFIED (ConsumerStatefulWidget, retention toggle)
- `apps/flutter/lib/features/settings/presentation/privacy_settings_screen.dart` — NEW
- `apps/flutter/lib/features/settings/presentation/settings_screen.dart` — MODIFIED (Privacy tile)
- `apps/flutter/lib/core/l10n/strings.dart` — MODIFIED (retention + privacy strings)
- `apps/api/src/routes/proof.ts` — MODIFIED (PATCH /v1/tasks/{taskId}/proof-retention stub)
- `apps/flutter/test/features/proof/privacy_settings_screen_test.dart` — NEW (7 tests)
- `apps/flutter/test/features/proof/photo_capture_sub_view_test.dart` — MODIFIED (ProviderScope wrapping)
- `apps/flutter/test/features/proof/screenshot_proof_sub_view_test.dart` — MODIFIED (ProviderScope wrapping)
- `apps/flutter/test/features/proof/health_kit_proof_sub_view_test.dart` — MODIFIED (ProviderScope wrapping)
- `apps/flutter/test/features/watch_mode/watch_mode_sub_view_test.dart` — MODIFIED (ProviderScope wrapping)
