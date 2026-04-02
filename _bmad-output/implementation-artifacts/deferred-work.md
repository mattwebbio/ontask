# Deferred Work

## Deferred from: code review of 7-8-ai-verification-dispute-filing — Story 7.8 (2026-04-01)

- **Dispute CTA integration test is shallow** — `photo_capture_sub_view_test.dart` mocks `fileDispute` directly rather than tapping the button from the rejected state. Getting to the rejected state requires complex camera mocking. `DisputeConfirmationView` itself has 7 separate tests; the gap is the sub-view state transition. Address when camera mocking infrastructure is added. [`apps/flutter/test/features/proof/photo_capture_sub_view_test.dart`]
- **`WatchModeSubView._onDone()` deferred bug — pops with non-null `ProofPath.watchMode` even without verified proof** — Pre-existing, unchanged by Story 7.8. Same as prior entries.

## Deferred from: code review of 7-8-ai-verification-dispute-filing (2026-04-01)

- **`stakeAmountCents` absent from `TaskDto` and `toDomain()`** — `Task` domain model declares `int? stakeAmountCents` (added in Story 6.2) but `TaskDto` does not map the field, so the value is silently lost on API deserialization. Address when stake display or charge logic is wired to the task list. [`apps/flutter/lib/features/tasks/data/task_dto.dart`]
- **`catch (_)` in `_parseDaysOfWeek` swallows parse errors silently** — Malformed JSON in the `recurrence_days_of_week` API field returns `null` with no log or user feedback. Low severity for now; consider logging or surfacing once recurrence editing lands. [`apps/flutter/lib/features/tasks/data/task_dto.dart:102`]

## Deferred from: code review of 7-7-proof-retention-settings (2026-04-01)

- **`WatchModeSubView._onDone()` deferred bug — pops with non-null `ProofPath.watchMode` even without verified proof** — Pre-existing from Story 7.4 (previously logged under 7-5 review). This story preserves the bug intentionally; `_onDone()` remains unchanged per story dev notes. Address when `WatchModeSubView` is revisited for a future story or when `NowTaskCard` handles proof-path return values more granularly. [`apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart`]

## Deferred from: code review of 7-5-healthkit-auto-verification (2026-04-01)

- **`WatchModeSubView._onDone()` pops with non-null value, triggering `onComplete` when user exits without submitting proof** — `_onDone` returns `ProofPath.watchMode` (non-null), which causes `NowTaskCard` to call `onComplete?.call()` even when the user dismissed without submitting proof. Pre-existing from Story 7.4; this story only changed the enum value (healthKit → watchMode). Address when `WatchModeSubView` is revisited or when `NowTaskCard` handles proof-path return values more granularly. [`apps/flutter/lib/features/watch_mode/presentation/watch_mode_sub_view.dart:323`]
- **Zero-duration HealthKit data points submitted to API** — When HealthKit returns a data point where `dateFrom == dateTo`, `durationSeconds` is 0, which is submitted to the API as valid proof data. Low severity; real API implementation should validate `durationSeconds > 0`. [`apps/flutter/lib/features/proof/presentation/health_kit_proof_sub_view.dart:161`]

## Deferred from: code review of 7-2-photo-video-proof-with-ai-verification (2026-04-01)

- **`index` listed in story spec schema imports but not imported or used** — `packages/core/src/schema/proof.ts` imports `pgTable, uuid, text, boolean, timestamp` from `drizzle-orm/pg-core` but not `index`; no indexes are defined on `proof_submissions`. Story spec listed `index` in the import tuple. Low impact — add indexes (e.g., on `task_id`, `user_id`) when DB integration is wired in a later story. [`packages/core/src/schema/proof.ts:1`]

## Deferred from: code review of 7-1-proof-capture-modal-foundation (2026-04-01)

- **`ProofSubmissionState` sealed class defined but unused** — Modal uses raw `ProofPath?` nullable state; the sealed class is dead code until Stories 7.2–7.6 wire up real sub-view logic. Address when the first concrete sub-view (Story 7.2 photo capture) is implemented. [`apps/flutter/lib/features/proof/domain/proof_submission_state.dart`]
- **`ProofPath.fromJson` silently defaults unknown/null values to `ProofPath.photo`** — Receiving an unrecognised API string silently becomes `photo`; this will corrupt data when the proof API lands in Story 7.2. Change to throw `ArgumentError` or return nullable and let callers decide the fallback. [`apps/flutter/lib/features/proof/domain/proof_path.dart:14-26`]
- **Sheet title string interpolation not l10n word-order safe** — `'${AppStrings.proofModalTitle} ${widget.taskName}'` hard-codes English word order. Use a placeholder-based string pattern when the app is localised. [`apps/flutter/lib/features/proof/presentation/proof_capture_modal.dart:113`]

## Deferred from: code review of 6-9-billing-history-api-contract-status (2026-04-01)

- **Billing history stub entry IDs use version-nibble-0 UUIDs** — `00000000-0000-0000-0000-000000000011/12/13` in the `/v1/billing-history` stub do not pass RFC-4122 UUID validation (version nibble must be 1–5). Pre-existing pattern throughout `commitment-contracts.ts` stub data (e.g., lines 626, 636, 677–679, 734–736). hono/zod-openapi does not validate response bodies by default, so tests pass. Replace with valid RFC-4122 UUIDs when real DB integration lands or if strict response validation is ever enabled.

## Deferred from: code review of 6-8-full-commitment-lock-flow-animation (2026-04-01)

- **`minSize` deprecated in `task_edit_inline.dart` (lines 670, 694)** — Pre-existing before Story 6.8 (present in HEAD commit `d5f79a4`); Story 6.8 shifts line numbers by +1 only. Replace `minSize` with `minimumSize` in a future task_edit_inline refactor pass.
- **`deadline` hardcoded as `DateTime.now().add(const Duration(days: 30))` in `StakeSheetScreen._onConfirm`** — Documented in story Deferred Items. Ceremony card shows a fake deadline. Wire real task deadline when task detail API integration lands.

## Deferred from: code review of 6-7-group-commitment-arrangements-pool-mode (2026-04-01)

- **`status` column uses unconstrained text, no DB-level enum/CHECK** — `group_commitments.status` allows any string. Application-level enforcement only; add `pgEnum` or CHECK constraint in a future schema hardening pass.
- **`proposedByUserId` and `group_commitment_members.userId` have no FK constraints** — Orphaned rows possible if users are deleted. Add `references()` in a future schema hardening pass (consistent with how other user-ref columns are treated).
- **No unique constraint on `(listId, taskId)` in `group_commitments`** — Multiple concurrent proposals for the same task are not prevented at the DB layer. Enforce at the application layer in real `TODO(impl)` handlers.
- **`GroupCommitmentReviewScreen` displays `member.userId` (UUID) instead of display name** — Real implementation should call `SharingRepository.getListMembers(listId)` to resolve names/avatars. Deferred until SharingRepository integration is wired.
- **`_poolModeOptIn` not seeded from current user's member row** — Requires auth context (current userId) not available in the widget stub. Seed correctly in real implementation when auth context is threaded through.
- **No widget tests for `GroupCommitmentProposalScreen`** — Loading state and error/pop path have no test coverage. Add in a future test hardening pass.
- **`approveGroupCommitment` has no idempotency guard in UI** — Already-approved user can tap "Approve" again; stub API doesn't prevent re-approval. Add guard in real implementation.
- **`setPoolModeOptIn` discards server response** — Optimistic update only; server disagreement is silently ignored. Use returned `poolModeOptIn` value in real implementation.
- **`groupCommitmentMemberSchema` `stakeAmountCents.min(500).nullable()` ordering** — `.nullable()` after `.min(500)` may reject null depending on Zod version. Fix to `z.union([z.null(), z.number().int().min(500)])` in real implementation.

## Deferred from: code review of 6-6-stake-modification-cancellation (2026-04-01)

- **Widget test `findsAtLeastNWidgets(1)` for `IgnorePointer` is a loose assertion** — `stake_sheet_screen_test.dart` verifies the locked slider wrapping using `findsAtLeastNWidgets(1)` which can match Flutter's own internal `IgnorePointer` instances. Acceptable for current test coverage; tighten the assertion (e.g., match only the `IgnorePointer` that wraps `StakeSliderWidget`) in a future test hardening pass.

## Deferred from: code review of 6-5-automated-charge-processing-charity-disbursement (2026-04-01)

- **`charge-scheduler.ts` query is a stub** — `triggerOverdueCharges()` has a `TODO(impl)` DB query; the cron fires but does nothing until the query is wired. Implement when real task/stake DB data is available in a future hardening story.
- **No integration tests for queue consumers** — Unit tests mock Stripe/Every.org; end-to-end queue flow (enqueue → consume → DB state transition) is not tested. Add integration tests when a test queue environment is available.
- **`POST /v1/webhooks/stripe` webhook event routing incomplete** — Handler verifies the Stripe signature and parses the event, but only adds a `TODO(impl)` comment for routing `payment_intent.succeeded` / `payment_intent.payment_failed`. Full event routing deferred to a dedicated webhooks story.
- **`charge-trigger-consumer.ts` has no test for `disbursement_failed` idempotency ack** — The patch (added in review) is not covered by a specific test. Add in a future test hardening pass.

## Deferred from: code review of 6-4-impact-dashboard (2026-04-01)

- **No repository test for `getImpactSummary()` error path** — Happy-path tests cover mapping; network failure and malformed response paths are untested. Add in a future test hardening pass when Epic 6 error handling is formalized.
- **`_formatDate` untestable as private static in `ImpactMilestoneCell`** — Date formatting logic is buried as a `static` in the widget class. Extract to `apps/flutter/lib/core/utils/time_format.dart` when that file is created (flagged in Stories 2.7/2.8 deferred work).
- **No test for `SettingsScreen` impact tile or `/settings/impact` navigation integration** — Settings tile added without test coverage. Add when SettingsScreen test suite is expanded.
- **`GET /v1/impact` OpenAPI definition missing `security` field** — Route does not declare bearer token security requirement in the OpenAPI spec. Pre-existing pattern across Epic 6 routes; address in a future OpenAPI hardening pass.

## Deferred from: code review of 6-3-charity-selection (2026-04-01)

- **Stale search results visible during subsequent loads** — `_nonprofits` is not cleared when a new search begins in `CharitySheetScreen._loadCharities`; old results remain visible while `_isLoading=true` but `nonprofits.isNotEmpty`. The `CharitySearchDelegate` loading indicator only triggers when both `isLoading && nonprofits.isEmpty`, so during re-searches the list appears static with no loading feedback. Not a spec bug; address when UX polish pass lands on the charity sheet.

## Deferred from: code review of 6-2-stake-setting-ui (2026-04-01)

- **`_openStakeSheet` future unawaited on `GestureDetector.onTap`** — `task_edit_inline.dart` assigns an `async` method returning `Future<void>` to `onTap`. Errors thrown inside (e.g. if `showCupertinoModalPopup` throws) are silently swallowed. Pre-existing pattern across the entire file; address when `task_edit_inline.dart` is refactored or when error reporting is hardened across the task-editing flow.

## Deferred from: code review of 6-1-payment-method-setup (2026-04-01)

- **Manual "Tap to confirm setup" stub button absent** — Dev Notes for Story 6.1 suggest a manual confirm button in `PaymentSettingsScreen` so testers can invoke `confirmSetup()` before Story 13.1 deep links are live. Screen omits this. Revisit in Story 13.1 or add as a debug-only affordance before Epic 6 QA.
- **`catch (_)` in `_removePaymentMethod` gives generic error on 422** — If cached `hasActiveStakes` is stale, a server-side 422 `ACTIVE_STAKES_PREVENT_REMOVAL` is swallowed into the generic `paymentSetupError` dialog. Add 422-specific error handling when Epic 6 real Stripe integration lands.
- **Widget test missing `onPressed == null` assertion for disabled Remove button** — `payment_settings_screen_test.dart` verifies the blocked-by-stakes note text but does not assert `CupertinoButton.onPressed == null`. Add explicit assertion when the screen is hardened in Epic 6.

## Deferred from: code review of 1-1-monorepo-project-scaffold (2026-03-29)

- **tsconfig.base.json NodeNext/ESNext tension** — Base config sets `module: NodeNext` / `moduleResolution: NodeNext` which all app tsconfigs override with `ESNext` / `Bundler`. Packages inherit NodeNext. Matches spec today but will create real type-resolution tension when packages get actual code in Story 1.3. Revisit when adding imports to packages/core.
- **Stub CI/CD workflows always pass** — ci.yml, deploy-staging.yml, deploy-production.yml are live and trivially succeed (echo only), giving false green in branch protection. Intentional per Story 1.1 scope; full implementation in Story 1.2.
- **`/static/style.css` 404 in admin renderer** — `apps/admin/src/renderer.tsx` references `/static/style.css` which does not exist. Silent 404 in dev/prod. Stub app; addressed when admin SPA is developed in a later story.
- **`ci.yml` only triggers on `pull_request`** — Direct pushes to `main` (squash-merges) bypass CI entirely while staging deploy triggers. Stub workflow; correct triggers implemented in Story 1.2.

## Deferred from: code review of 1-2-cicd-pipeline-staging-environments (2026-03-30)

- **Flutter CI on `ubuntu-latest`** — iOS platform tests can't execute on Linux; flutter widget tests with platform channels may produce false passes. Known tradeoff; consider switching to `macos-latest` when platform-channel tests are added.
- **100% coverage trivially passes on empty module** — `packages/scheduling/src/index.ts` has no executable code; thresholds pass vacuously. Intentional per dev notes. Threshold becomes meaningful in Epic 3 when real scheduling logic lands.
- **Fastlane auth/race condition** — `app_store_build_number` requires App Store Connect credentials not yet wired up; `increment_build_number` may be reset by `flutter build ipa`. Deferred until Fastlane CI integration story.
- **IPA path hardcoded as `ontask.ipa`** — Flutter outputs the IPA under the `name` field from `pubspec.yaml`; if that differs from `ontask`, `upload_to_testflight` will fail with file-not-found. Deferred until Fastlane runs in CI.
- **`pnpm -r typecheck` silently skips packages without `typecheck` script** — New packages added to the monorepo without a `typecheck` script are silently excluded from CI typechecking. Consider adding a guard or standardizing the script in workspace package templates.
- **`jq` multi-match in `neon-branch-delete`** — If `jq` somehow returns multiple branch IDs (name collision across environments), only the first is deleted. Very unlikely given `pr-N` naming convention; revisit if Neon project structure becomes more complex.

## Deferred from: code review of 1-4-flutter-architecture-foundation (2026-03-30)

- **`_tryRefreshToken()` is a stub (always returns false)** — The refresh-success → retry path is dead code and untested. Story 1.8 will implement the real token refresh endpoint and replace this stub.
- **`_forceSignOut()` clears tokens but does not navigate** — UI remains on the current screen after forced sign-out. Story 1.8 will wire up Riverpod auth state so sign-out triggers navigation to the login screen.
- **`AuthInterceptor` retries through the same `Dio` instance** — Retry requests re-enter the full interceptor pipeline including `AuthInterceptor` again. The `kRetryHeader` guards against infinite loops but the tight coupling is architecturally fragile. Consider using a separate Dio instance for token refresh in Story 1.8.
- **`onRequest` does not attach `Authorization` header** — All initial requests go out unauthenticated; the 401 refresh cycle is the only path to auth. Story 1.8 will implement proper token attachment on outgoing requests.
- **No test for refresh-succeeds → retry-succeeds happy path** — `_tryRefreshToken()` is intentionally stubbed in Story 1.4. Story 1.8 must add tests for the successful token refresh and retry flow.

## Deferred from: code review of 1-6-ios-navigation-shell-loading-states (2026-03-30)

- **`nowEmptySubtitleTemplate` constant is never used** — `AppStrings.nowEmptySubtitleTemplate` is defined in `strings.dart` but `NowEmptyState` uses inline interpolation `'Next: $nextTaskHint'` directly instead of the template. No functional impact today. Clean up or consume the constant when real task data arrives in Story 1.8+. [apps/flutter/lib/core/l10n/strings.dart:10]

## Deferred from: code review of 1-9-onboarding-flow-sample-schedule (2026-03-30)

- **Fragile serif font resolution in SampleScheduleStep** — `serifFamily` is read from `textTheme.displayLarge?.fontFamily` and then applied to `displaySmall`. If those two slots are ever assigned different font families in the theme, the wrong font silently applies. Pre-existing pattern from `NowEmptyState`. [apps/flutter/lib/features/onboarding/presentation/steps/sample_schedule_step.dart:35]
- **TimeOfDay formatting duplicated across 3 files** — Identical `padLeft(2, '0')` hour/minute formatting logic exists in `SampleScheduleStep._DemoTaskCard`, `EnergyPreferencesStep._formatTime()`, and `WorkingHoursStep._formatTime()`. No shared utility exists. Not blocking; extract to a shared helper when the next story touches these files. [apps/flutter/lib/features/onboarding/presentation/steps/]

## Deferred from: code review of 2-1-task-list-crud (2026-03-30)

- **Missing `userId` FK constraint on `listsTable` and `tasksTable`** — commented as `TODO(story-TBD)` pending users table availability in the core schema. Pre-existing architectural decision; add FK when user table lands.
- **Test pass verification pending** — Unable to run `flutter test` or `pnpm test` in review context. Story requires all 206 pre-existing tests + new tests pass. Verify in CI.

## Deferred from: code review of 2-2-task-properties-scheduling-hints (2026-03-30)

- **`lists_provider.g.dart` hash changed without lists code changes** — `build_runner` regeneration side-effect changed the hash in `lists_provider.g.dart` despite no lists-related source changes in Story 2.2. Not harmful; monitor for similar drift in future stories.

## Deferred from: code review of 2-4-task-templates (2026-03-30)

- **API stub `offsetDate` does not recurse into `childSections` for due dates** — The `offsetDate` helper in the apply template stub only scans top-level `sections[].tasks` and `rootTasks` for `minDate` calculation, missing tasks in nested `childSections`. This is a stub-only issue that will be addressed when real implementation replaces stubs.

## Deferred from: code review of 2-5-task-dependencies-bulk-operations (2026-03-30)

- **Bulk operation errors silently swallowed** — `_bulkReschedule`, `_bulkComplete`, `_bulkDelete` in `list_detail_screen.dart` catch all exceptions with `// Error handling deferred to real implementation`; user sees no error feedback on failure. Stub-only issue; address when real implementation replaces stubs.

## Deferred from: code review of 2-7-now-tab-task-card (2026-03-30)

- **`_formatDeadline()` time-formatting logic duplicated** — A third copy of deadline-formatting logic now exists in `now_task_card.dart` alongside `today_screen.dart`. Story dev notes (from Story 1.9) call for extraction to `apps/flutter/lib/core/utils/time_format.dart`. Should be consolidated when touching either screen.
- **VoiceOver label `parts.join(', ')` embeds task-title commas** — If a task title contains a comma, the VoiceOver separator becomes ambiguous. Low severity design limitation; address if/when VoiceOver copy is refined.
- **`CommitmentRow.formatAmount()` has no guard for negative values** — `formatAmount(-100)` returns `'$-1'`. Not reachable while stub API returns null; guard when Epic 6 real stake data is wired.

## Deferred from: code review of 2-8-timeline-view (2026-03-31)

- **`_formatTime` is 4th duplication of time formatting logic** — `timeline_painter.dart:230` and `today_screen.dart:402` each contain their own copy of 12-hour time formatting. Pre-existing issue flagged in story's own deferred issues section. Extract to `apps/flutter/lib/core/utils/time_format.dart`.

## Deferred from: code review of 2-12-schedule-change-banner-overbooking-warning (2026-03-31)

- **Banners not shown in empty-state path** — `ScheduleChangeBannerAsync` and `OverbookingWarningBannerAsync` live inside `_TodayContent`, which only mounts when `tasks.isNotEmpty`. Schedule-change and overbooking notifications are silently dropped when the task list is empty. Structural limitation of stub; Epic 3 scheduling integration will address triggering mechanism. [`apps/flutter/lib/features/today/presentation/today_screen.dart`]
- **`response.data!` force-unwrap in `getScheduleChanges()` and `getOverbookingStatus()`** — Matches pre-existing pattern throughout `TodayRepository`; will throw `TypeError` on a null or unexpected API response. Add null guard or typed error path when replacing stubs. [`apps/flutter/lib/features/today/data/today_repository.dart`]

## Deferred from: code review of 2-11-predicted-completion-badge (2026-03-31)

- **`_shimmer` declared as top-level function with leading underscore** — Leading underscore on a top-level function in `prediction_badge_async.dart` is unconventional Dart (grants library-private visibility but reads as class-private). Pre-existing codebase style pattern; low risk. Could be a private static method on a helper class if the file grows. [`apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge_async.dart:65`]
- **Import ordering in `prediction_badge_async.dart`** — Material import (`package:flutter/material.dart show Theme`) appears interleaved with local imports rather than grouped with other package imports. Pre-existing style pattern across codebase. [`apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge_async.dart:5`]
- **`ref.watch` on stable `predictionRepositoryProvider` in async providers** — Semantically `ref.read` would be more appropriate for a stable dependency (repository never changes after construction), but `ref.watch` matches the pattern documented in Previous Story Learnings and is functionally correct. [`apps/flutter/lib/features/prediction/presentation/prediction_provider.dart:22,32,42`]

## Deferred from: code review of 3-1-scheduling-engine-foundation (2026-03-31)

- **`constraints/index.ts` undocumented barrel file** — `packages/scheduling/src/constraints/index.ts` was created but not listed in the story's File List or completion notes. It is a valid addition (used by `test/constraints/index.test.ts` to verify all constraint exports), but the story change log does not reflect it. Update story file list if auditing accuracy matters. [`packages/scheduling/src/constraints/index.ts`]

## Deferred from: code review of 2-13-chapter-break-screen-ipad-layout (2026-03-31)

- **Unsafe `state.extra` cast in `/chapter-break` route** — `state.extra as Map<String, dynamic>?` will throw a `TypeError` if the caller passes extra of a wrong type. Pre-existing pattern across all routes in `app_router.dart`; acceptable for V1 internal navigation. [`apps/flutter/lib/core/router/app_router.dart:137`]
- **Optimistic task completion without error handling** — `completeTask(task.id)` is called then `context.push('/chapter-break')` fires immediately regardless of API success. V1 design decision (optimistic UI); error handling deferred to when the task completion API is fully wired with error states. [`apps/flutter/lib/features/now/presentation/now_screen.dart:94`]

## Deferred from: code review of 3-2-basic-auto-scheduling-algorithm (2026-03-31)

- **No unit tests for `apps/api/src/services/scheduling.ts`** — Pre-existing pattern; no API service unit tests in codebase. Story only requires 100% coverage for `packages/scheduling`. Address when API services get test scaffolding. [`apps/api/src/services/scheduling.ts`]
- **Two separate `new Date()` calls in service layer for `windowStart` and `generatedAt`** — By-design stub pattern per dev notes; `generatedAt` may be a few milliseconds after `windowStart`. Will be resolved in Story 3.3 when real DB data and window calculation are wired. [`apps/api/src/services/scheduling.ts:22,31`]
- **No integration test for morning-window + past-due-date constraint intersection** — 100% branch coverage confirmed. Would be an enhancement test, not a coverage gap. Low priority; consider adding in a future test-quality pass.

## Deferred from: code review of 3-4-google-calendar-write-task-block-relationship (2026-03-31)

- **`loadAndRefreshToken` userId check is in-memory only** — DB query filters by `connectionId` only; userId ownership is validated after the query. Functionally correct but not index-optimal. Pre-existing pattern from `fetchGoogleCalendarEvents`. [`apps/api/src/services/calendar/google.ts:175-200`]
- **`onBlockTapped` override design concern** — `_handleBlockTapped` short-circuits to the injected callback if set, bypassing AC3 navigation. Production `TodayScreen` passes no override so production behavior is correct. Only affects test contexts that inject callbacks. [`apps/flutter/lib/features/today/presentation/widgets/timeline_view.dart:170-173`]
- **Flutter `getCalendarEvents()` errors silently swallowed** — The catch block in `TodayRepository.getCalendarEvents()` returns `[]` with no debug logging. Intentional per partial-failure spec; add `debugPrint` for diagnosability in a future hardening pass. [`apps/flutter/lib/features/today/data/today_repository.dart:112`]

## Deferred from: code review of 3-3-google-calendar-read-available-time (2026-03-31)

- **Empty accountEmail silently stored when Google userinfo call fails** — `exchangeGoogleCode` in `apps/api/src/routes/calendar.ts` sets `email = ''` and continues if the userinfo endpoint returns non-200. The `accountEmail` DB column is `notNull()` so an empty string satisfies the constraint, but data is silently degraded. Non-critical for scheduling correctness; address in a hardening pass when email is used for display or audit purposes.
- **Google refresh token rotation silently discarded** — `refreshGoogleToken` in `apps/api/src/services/calendar/google.ts` does not capture or persist a rotated refresh token if Google issues one in the refresh response. Not standard behavior for server-side OAuth2; acceptable for v1. Revisit if Google credentials become invalid unexpectedly in production.

## Deferred from: code review of 4-2-guided-chat-task-capture (2026-03-31)

- **`_mode` never set to `_AddMode.guided` — dead code on submit button guard** [`apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart`] — Tapping Guided immediately calls `pop()` so `_mode` remains at its previous value; the `if (_mode != _AddMode.guided)` guard on the submit button is unreachable but harmless. No user impact; clean up in a future refactor pass.
- **Widget test `tasksProvider()` override brittle if `listId` is non-null** [`apps/flutter/test/features/shell/guided_chat_sheet_test.dart` line 122] — Pre-existing pattern from Story 4.1; current fixtures keep `listId` null so the override intercepts correctly. Would silently break if a test fixture returned a non-null `listId`. Harden when adding more complete task-creation test scenarios.

## Deferred from: code review of 5-1-list-sharing-invitations (2026-03-31)

- **`SharingRepository.getInvitationDetails` uses field name `inviterName` not `invitedByName`** [`apps/flutter/lib/features/lists/data/sharing_repository.dart:43`] — Coupled to `invitationDetailsSchema` patch (F11); both should be resolved together when the schema is updated to match the spec field names (`listId`, `invitedByName`, `inviteeEmail`, `expiresAt`).

## Deferred from: code review of 5-2-task-assignment-strategies (2026-04-01)

- **`console.log` in production API stub handlers** [`apps/api/src/routes/sharing.ts`] — Pre-existing pattern consistent with all other stub handlers in `sharing.ts` and `lists.ts`. Remove when real implementations replace stubs.
- **Fake test repos instantiate real `ApiClient` / `AuthInterceptor`** [`apps/flutter/test/features/lists/list_settings_screen_test.dart`] — `_FakeListsRepository` and `_FakeSharingRepository` call `super(ApiClient(baseUrl: 'http://fake'))`, wiring up `AuthInterceptor` and `LoggingInterceptor`. All repository methods are overridden so no real Dio calls occur, but `AuthInterceptor` init touches `FlutterSecureStorage` (mocked). Pre-existing pattern from Story 5.1. Consider switching to `mocktail` full mocks in a future test hardening pass.
- **`TaskList.assignmentStrategy` not validated as enum in Flutter domain layer** [`apps/flutter/lib/features/lists/domain/task_list.dart`] — Field is `String?` rather than a sealed type / enum. Consistent with project's no-enum-in-domain approach; Zod validates valid values at the API boundary. Revisit when domain modeling is formalized.
- **Brief UI flash after `ref.invalidate(listsProvider)` during strategy update** [`apps/flutter/lib/features/lists/presentation/list_settings_screen.dart`] — After `updateAssignmentStrategy` succeeds, `ref.invalidate` triggers an async reload; the checkmark selection may briefly show the old state before re-render. Minor UX polish; spec does not require optimistic update patterns here.

## Deferred from: code review of 5-4-accountability-settings-cascade (2026-04-01)

- **`_journal.json` missing trailing newline at EOF** [`packages/core/src/schema/migrations/meta/_journal.json`] — `drizzle-kit generate` emits the file without a trailing newline. Pre-existing tool behavior; not caused by this story.

## Deferred from: code review of 6-5-automated-charge-processing-charity-disbursement (2026-04-01)

- **`verifyWebhookSignature` stub permanently returns `false`** — All real Stripe webhooks to `POST /v1/webhooks/stripe` will receive HTTP 400 until the `TODO(impl)` in `apps/api/src/services/stripe.ts` is replaced with real HMAC-SHA256 verification. Tests document the expected behavior once implemented.
- **`disburseDonation` stub permanently returns `{ success: false }`** — Every.org consumer will throw on every disbursement message until `TODO(impl)` in `apps/api/src/services/every-org.ts` is replaced with the real Partner Funds API call.
- **`triggerOverdueCharges` is a full no-op stub** — No tasks will ever be enqueued for charging until the DB query + `CHARGE_TRIGGER_QUEUE.send()` loop in `apps/api/src/lib/charge-scheduler.ts` is implemented. SQL query is fully spec'd in comments.
- **No test file for `everyOrgConsumer`** — The throw-on-failure path (NFR-R4 critical path) is untested. Recommend adding `apps/api/src/queues/every-org-consumer.test.ts` covering: idempotency ack when status=`disbursed`, update to `disbursement_failed` + throw on failure, and success path update to `disbursed`.

## Deferred from: code review of 5-6-member-management-shared-ownership (2026-04-01)

- **`this.context` anti-pattern extended in new code** [`apps/flutter/lib/features/lists/presentation/list_settings_screen.dart`] — 7 new occurrences added (pre-existing count was 5; total now 12). Methods accept a `BuildContext` parameter but internally use `this.context` instead. Pre-existing codebase pattern; functionally safe while `mounted` checks are in place. Clean up in a future refactor pass when touching this file.
- **Empty member list renders enabled Leave List button** [`apps/flutter/lib/features/lists/presentation/list_settings_screen.dart:200`] — When `membersAsync` data is an empty list, `ownerCount == 0`, `isLastOwner == false`, and the Leave List button renders enabled with no members present. Unreachable in production (members list includes at least the current user). Handle defensively when real member data is wired.
