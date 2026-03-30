# Deferred Work

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
