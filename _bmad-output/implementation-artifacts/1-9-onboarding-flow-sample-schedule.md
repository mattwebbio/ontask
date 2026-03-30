# Story 1.9: Onboarding Flow & Sample Schedule

Status: review

## Story

As a new user,
I want to experience a demo schedule before connecting my calendar or creating any tasks,
so that I understand what On Task will feel like before committing time to setup.

## Acceptance Criteria

1. **Given** a user completes authentication for the first time, **When** onboarding begins, **Then** the Now tab displays a pre-populated sample schedule sourced from `lib/core/fixtures/demo_schedule.dart` — no API call is made before showing this (UX-DR27), **And** the demo tasks use the "past self / future self" narrative voice and warm tone (UX-DR32, UX-DR36), **And** no calendar permission or any system permission is requested before the user sees the sample schedule.

2. **Given** the user has seen the sample schedule, **When** they proceed through onboarding, **Then** they are guided through: calendar connection (Google Calendar OAuth), energy preference setup (peak hours, low-energy hours, wind-down time), and preferred working hours, **And** each step has a clearly labelled "Set this up later" affordance, **And** skipping any step does not block access to the app.

3. **Given** a user completes or fully skips onboarding, **When** they arrive at the main app for real use, **Then** demo fixture data is replaced by their real tasks (or a fresh empty state), **And** onboarding completion state is persisted server-side so re-launching the app never restarts the onboarding flow, **And** the Now tab empty state shown during the sample schedule phase uses the onboarding fixture (UX-DR27) — once onboarding is complete or skipped, the standard Now tab empty state renders instead.

## Tasks / Subtasks

- [x] Create `lib/core/fixtures/demo_schedule.dart` (AC: 1)
  - [x] Define a `DemoTask` data class (plain Dart — not `@freezed`, not connected to the real tasks domain model)
  - [x] Populate 4–6 sample tasks using the "past self / future self" warm narrative voice — titles written in first-person scheduling language (e.g., "Review the project brief", "Call Mum back", "30-minute walk")
  - [x] Each task has: `title`, `scheduledTime` (TimeOfDay), `durationMinutes`, `isCompleted` (bool)
  - [x] One task is already marked `isCompleted: true` to show the "done" visual state in the demo
  - [x] No real network calls, no Riverpod providers — this is a pure static fixture file
  - [x] `lib/core/fixtures/` is a new directory; create it

- [x] Add onboarding state tracking to `AuthStateNotifier` (AC: 1, 3)
  - [x] Add `kOnboardingCompleted` const string key to `auth_provider.dart` alongside `kAuthWasAuthenticated`
  - [x] Add `bool get isOnboardingCompleted` getter that reads from `_prefs` synchronously (same SharedPreferences instance already pre-warmed)
  - [x] Add `Future<void> completeOnboarding()` method that sets the key to `true` AND calls `PATCH /v1/users/me` → `{ onboardingCompleted: true }` server-side
  - [x] Read `kOnboardingCompleted` in `build()` and expose as initial state (synchronous read, same pattern as `kAuthWasAuthenticated`)
  - [x] Do NOT add a new Riverpod provider — piggyback on the existing `AuthStateNotifier`; expose via a separate method, not a new state type

- [x] Create `lib/features/onboarding/` feature folder (AC: 1, 2, 3)
  - [x] `lib/features/onboarding/domain/onboarding_step.dart` — plain Dart enum: `sampleSchedule`, `calendarConnection`, `energyPreferences`, `workingHours`, `complete`
  - [x] `lib/features/onboarding/presentation/onboarding_flow.dart` — `ConsumerStatefulWidget` that manages step transitions
  - [x] `lib/features/onboarding/presentation/steps/sample_schedule_step.dart` — the demo Now tab view (AC: 1)
  - [x] `lib/features/onboarding/presentation/steps/calendar_connection_step.dart` — Google Calendar OAuth prompt (AC: 2)
  - [x] `lib/features/onboarding/presentation/steps/energy_preferences_step.dart` — peak hours, low-energy hours, wind-down time pickers (AC: 2)
  - [x] `lib/features/onboarding/presentation/steps/working_hours_step.dart` — preferred start/end time for working day (AC: 2)

- [x] Implement `SampleScheduleStep` — the emotional hook screen (AC: 1)
  - [x] Render the list of `DemoTask` items from `demo_schedule.dart` as Now-tab-style task cards
  - [x] Use New York serif for the welcome headline: "Here's what a day with On Task could look like." (emotional voice layer — UX-DR32)
  - [x] Use SF Pro for all task card copy and metadata
  - [x] Completed demo task must visually render as done (opacity reduction or strikethrough — match the existing `NowEmptyState` visual language established in Story 1.6)
  - [x] CTA at bottom: `CupertinoButton.filled` "Let's set it up" → advances to `calendarConnection`
  - [x] Secondary CTA: text button "Skip setup — take me to the app" → calls `completeOnboarding()` and routes to `/now`
  - [x] No Riverpod providers for demo data — load directly from the static fixture

- [x] Implement `CalendarConnectionStep` (AC: 2)
  - [x] Headline (SF Pro, 22pt semibold): "Connect your calendar"
  - [x] Subhead (SF Pro, 15pt, `color.text.secondary`): "So your future self isn't ambushed by what past you already committed to."
  - [x] CTA: `CupertinoButton.filled` "Connect Google Calendar" — this is a stub in this story (the actual Google Calendar OAuth flow is deferred to Epic 3); button shows a `CupertinoActivityIndicator` on tap then shows a success confirmation after 1s (simulate for now)
  - [x] "Set this up later" text button → advance to `energyPreferences`
  - [x] Add a `TODO(story-3.x): Replace stub with real Google Calendar OAuth` comment in the implementation

- [x] Implement `EnergyPreferencesStep` (AC: 2)
  - [x] Three time-range pickers: "Peak focus hours", "Low-energy hours", "Wind-down time"
  - [x] Use `CupertinoTimerPicker` or `showCupertinoModalPopup` with time selection for start/end of each range
  - [x] Persist selections locally in `SharedPreferences` using keys: `pref_peak_start`, `pref_peak_end`, `pref_low_energy_start`, `pref_low_energy_end`, `pref_wind_down_start`, `pref_wind_down_end` (stored as ISO 8601 time strings, e.g., `"09:00"`)
  - [x] Do NOT call the API to persist these yet — that is deferred to the Settings feature (Story 1.10 / Epic 2)
  - [x] "Set this up later" text button → advance to `workingHours`

- [x] Implement `WorkingHoursStep` (AC: 2)
  - [x] Two time pickers: "Work starts" and "Work ends"
  - [x] Persist locally: `pref_work_start`, `pref_work_end` in `SharedPreferences`
  - [x] CTA: `CupertinoButton.filled` "Done — show me my plan" → calls `completeOnboarding()` then routes to `/now`
  - [x] "Set this up later" text button → same action as CTA

- [x] Add API stub: `PATCH /v1/users/me` in Hono worker (AC: 3)
  - [x] Add to `apps/api/src/routes/` — create `users.ts` (this file is listed in architecture as `apps/api/src/routes/users.ts` covering FR60, FR61, FR64, FR65, FR81, FR85, FR87)
  - [x] `PATCH /v1/users/me` — body: `{ onboardingCompleted?: boolean }` → returns `{ data: { userId: string, onboardingCompleted: boolean } }`
  - [x] Use `@hono/zod-openapi` schema — no untyped routes (ARCH rule)
  - [x] Add `TODO(impl): Upsert user fields via Drizzle` comment — stub only in this story
  - [x] Register `users.ts` routes in `apps/api/src/index.ts`

- [x] Wire onboarding gate into the router (AC: 1, 3)
  - [x] In `app_router.dart`, extend the `redirect` callback: after confirming `isAuthenticated`, check `ref.read(authStateNotifierProvider.notifier).isOnboardingCompleted`
  - [x] If authenticated AND onboarding NOT completed AND not already on `/onboarding/*` → redirect to `/onboarding`
  - [x] If authenticated AND onboarding complete AND on `/onboarding/*` → redirect to `/now`
  - [x] Add `/onboarding` as a top-level `GoRoute` (sibling of `/auth/sign-in`, NOT inside `StatefulShellRoute`)
  - [x] `/onboarding` route renders `OnboardingFlow` widget

- [x] Add strings to `AppStrings` (AC: 1, 2)
  - [x] `lib/core/l10n/strings.dart` — add constants: `onboardingWelcomeHeadline`, `onboardingSkipAll`, `onboardingLetSetItUp`, `onboardingCalendarTitle`, `onboardingCalendarSubtitle`, `onboardingCalendarConnect`, `onboardingCalendarSkip`, `onboardingEnergyTitle`, `onboardingEnergyPeakLabel`, `onboardingEnergyLowLabel`, `onboardingEnergyWindDownLabel`, `onboardingWorkingHoursTitle`, `onboardingWorkingStartLabel`, `onboardingWorkingEndLabel`, `onboardingDoneButton`
  - [x] All strings follow the warm narrative voice (UX-DR32, UX-DR36); no punitive language; no "ADHD-specific" framing; frame around "executive dysfunction" broadly

- [x] Write unit and widget tests (AC: 1–3)
  - [x] `test/core/fixtures/demo_schedule_test.dart`: verify fixture has 4–6 tasks, at least one completed, all have non-empty titles and positive duration
  - [x] `test/features/onboarding/sample_schedule_step_test.dart`: pump `SampleScheduleStep` → verify welcome headline uses New York serif; verify demo tasks render; verify "Skip setup" button is present; verify no `ApiClient` is called during render
  - [x] `test/features/onboarding/onboarding_flow_test.dart`: verify tapping "Set this up later" advances through steps; verify `completeOnboarding()` is called when user finishes or skips all; verify router redirects to `/now` after completion
  - [x] `test/features/auth/auth_provider_test.dart`: extend existing tests — verify `isOnboardingCompleted` returns `false` by default; verify `completeOnboarding()` sets the SharedPreferences key
  - [x] Run `flutter test` — all 129 existing tests must continue passing (152 tests pass total, 23 new)

- [x] Run `build_runner` and commit generated files
  - [x] `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x] Commit any new `*.g.dart` or `*.freezed.dart` generated files if new `@riverpod` or `@freezed` annotations were added

## Dev Notes

### Critical Architecture Constraints

**Demo data is a static fixture — zero API calls before onboarding completes:**
Per UX-DR27 and AC #1: `lib/core/fixtures/demo_schedule.dart` is a pure static Dart file with no Riverpod providers, no `ApiClient` calls, no `drift` queries. Load it directly in `SampleScheduleStep` via a simple function call:
```dart
// lib/core/fixtures/demo_schedule.dart
class DemoTask {
  const DemoTask({required this.title, required this.scheduledTime, required this.durationMinutes, this.isCompleted = false});
  final String title;
  final TimeOfDay scheduledTime;
  final int durationMinutes;
  final bool isCompleted;
}

const List<DemoTask> kDemoSchedule = [
  DemoTask(title: 'Review the project brief', scheduledTime: TimeOfDay(hour: 9, minute: 0), durationMinutes: 45),
  DemoTask(title: 'Call Mum back', scheduledTime: TimeOfDay(hour: 10, minute: 30), durationMinutes: 20, isCompleted: true),
  DemoTask(title: '30-minute walk', scheduledTime: TimeOfDay(hour: 12, minute: 30), durationMinutes: 30),
  DemoTask(title: 'Respond to team messages', scheduledTime: TimeOfDay(hour: 14, minute: 0), durationMinutes: 25),
  DemoTask(title: 'Prep for tomorrow', scheduledTime: TimeOfDay(hour: 17, minute: 0), durationMinutes: 20),
];
```

**Onboarding route MUST be outside `StatefulShellRoute`:**
Same pattern as `/auth/sign-in` from Story 1.8. The onboarding screens must render without the shell (no tab bar, no sidebar). Add `/onboarding` as a sibling at the top of `routes:`, not nested inside `StatefulShellRoute.indexedStack`.

```dart
// app_router.dart — add alongside /auth/sign-in:
GoRoute(
  path: '/onboarding',
  builder: (context, state) => const OnboardingFlow(),
),
```

**Router redirect order matters — check onboarding after auth:**
The existing redirect first checks auth state. Extend it:
```dart
redirect: (context, state) {
  final authState = ref.read(authStateProvider);
  final isAuthenticated = authState is Authenticated;
  final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
  final isOnOnboardingRoute = state.matchedLocation.startsWith('/onboarding');

  if (!isAuthenticated && !isOnAuthRoute) return '/auth/sign-in';
  if (isAuthenticated && isOnAuthRoute) return '/now';

  // Onboarding gate (only for authenticated users):
  final notifier = ref.read(authStateNotifierProvider.notifier);
  if (isAuthenticated && !notifier.isOnboardingCompleted && !isOnOnboardingRoute) {
    return '/onboarding';
  }
  if (isAuthenticated && notifier.isOnboardingCompleted && isOnOnboardingRoute) {
    return '/now';
  }

  return null;
},
```

**`authStateProvider` actual generated name warning (from Story 1.8 debug log):**
The `@riverpod` code generator names the provider `authStateProvider` (NOT `authStateNotifierProvider`). Always check the generated `.g.dart` after `build_runner` to confirm the exact provider name before using it in tests or router. This bit the Story 1.8 dev — don't repeat.

**`AuthStateNotifier` is `keepAlive: true` — do NOT remove this annotation:**
Added in Story 1.8 (D2 decision) to prevent the stale-callback problem. Any new methods added to `AuthStateNotifier` (e.g., `completeOnboarding()`, `isOnboardingCompleted`) will benefit from this stability automatically.

**SharedPreferences for onboarding state — same pre-warmed instance:**
The `AuthStateNotifier._prefs` static field is already pre-warmed in `main()` before `runApp()`. Use this same instance for reading/writing `kOnboardingCompleted`. Do NOT call `SharedPreferences.getInstance()` again inside `completeOnboarding()` — use `_prefs`:

```dart
// In AuthStateNotifier:
static const kOnboardingCompleted = 'onboarding_completed';

bool get isOnboardingCompleted => _prefs?.getBool(kOnboardingCompleted) ?? false;

Future<void> completeOnboarding() async {
  await _prefs?.setBool(kOnboardingCompleted, true);
  // API call: PATCH /v1/users/me with onboardingCompleted: true
  // Use ref.read(apiClientProvider) — never new ApiClient()
  try {
    final client = ref.read(apiClientProvider);
    await client.patch('/v1/users/me', data: {'onboardingCompleted': true});
  } catch (_) {
    // Non-fatal: local state is source of truth for re-launch guard;
    // server-side flag is a belt-and-suspenders for multi-device scenarios.
    // Log silently — do not surface error to user (onboarding UX must be frictionless).
  }
}
```

**Server-side onboarding state is belt-and-suspenders in this story:**
The AC says "persisted server-side so re-launching the app never restarts". In this story, the server-side write is a stub (`TODO(impl)` in `users.ts`). The local `SharedPreferences` flag is sufficient to prevent re-launch restart. The server-side persistence becomes load-bearing when multi-device support arrives. Document this clearly in the stub.

**Energy preferences — local-only in this story:**
Store energy preference times in `SharedPreferences` with the keys specified in the task. The scheduling engine (Epic 3) and Settings (Story 1.10) will migrate these to the server later. Keep the keys in a constants file or at the top of `energy_preferences_step.dart`.

**Typography rules — New York serif is ONLY for the welcome headline:**
Per UX-DR32 and UX-DR36 and the hard rule from the UX spec: "It must never appear in UI chrome, error messages, or any functional element." In onboarding:
- Welcome headline on `SampleScheduleStep`: New York serif — this is the "emotional voice layer"
- All step titles, subtitles, button labels, picker labels: SF Pro
- Demo task titles: SF Pro (these are UI elements, not voice copy)
- "Set this up later" links: SF Pro

```dart
// Correct usage in SampleScheduleStep:
Text(
  AppStrings.onboardingWelcomeHeadline,
  style: Theme.of(context).textTheme.displaySmall, // New York serif
),

// Step titles — SF Pro:
Text(
  AppStrings.onboardingCalendarTitle,
  style: Theme.of(context).textTheme.headlineSmall, // SF Pro
),
```

**`CupertinoButton` and `CupertinoButton.filled` for all CTAs:**
Consistent with the pattern established across Story 1.5–1.8. Do NOT use `ElevatedButton` or `TextButton` — use `CupertinoButton` for "Set this up later" links and `CupertinoButton.filled` for primary CTAs.

**Do NOT use `accentPrimary` colour for the "Connect Google Calendar" button:**
Per the UX spec and Story 1.8 precedent for Google branding — Google's own brand guidelines apply for their button. Use `CupertinoButton.filled` with the system default or Google-branded colours, not `OnTaskColors.accentPrimary`.

**Feature folder location:**
```
apps/flutter/lib/features/onboarding/
├── domain/
│   └── onboarding_step.dart        ← plain Dart enum
└── presentation/
    ├── onboarding_flow.dart         ← ConsumerStatefulWidget, step router
    └── steps/
        ├── sample_schedule_step.dart
        ├── calendar_connection_step.dart
        ├── energy_preferences_step.dart
        └── working_hours_step.dart
```

No `data/` subfolder for onboarding — there is no repository layer. The feature writes directly to `SharedPreferences` (via `AuthStateNotifier`) and the API (via `ApiClient`).

**`ConsumerStatefulWidget` for all widgets that need Riverpod:**
Same pattern from Stories 1.5–1.8. `OnboardingFlow` needs `ref.read(authStateNotifierProvider.notifier)` to call `completeOnboarding()` and `ref.watch(authStateProvider)` in the router. Use `ConsumerStatefulWidget`.

**Testing: `FlutterSecureStorage.setMockInitialValues({})` in all test `setUp`:**
Any test that indirectly constructs `AuthStateNotifier` (e.g., via router or auth gate) will trigger the Keychain platform channel. Call `FlutterSecureStorage.setMockInitialValues({})` and `SharedPreferences.setMockInitialValues({})` in test setUp. This pattern was established in Story 1.8.

**Widget test override for auth and onboarding state:**
Tests for `OnboardingFlow` and `SampleScheduleStep` must override both `authStateProvider` and the onboarding flag to avoid being redirected by the router:
```dart
// In test setUp:
FlutterSecureStorage.setMockInitialValues({});
SharedPreferences.setMockInitialValues({'auth_was_authenticated': true});
// Override provider in test:
ProviderScope(
  overrides: [
    authStateProvider.overrideWithValue(const AuthResult.authenticated(userId: 'test')),
  ],
  child: const OnboardingFlow(),
)
```

**Hono API route — `users.ts` is NEW in this story:**
`apps/api/src/routes/users.ts` does not exist yet (only `auth.ts` and `health.ts` exist). Create it fresh. Register it in `apps/api/src/index.ts`. Follow the exact same `@hono/zod-openapi` pattern as `auth.ts`. Use `casing: 'camelCase'` in Drizzle when the real impl arrives (stub only in this story).

**API response envelope — always `{ data: { ... } }` or `{ error: { ... } }`:**
Every API response follows the envelope. The `PATCH /v1/users/me` stub returns:
```json
{ "data": { "userId": "stub_user_id", "onboardingCompleted": true } }
```
Use the existing `ok()` / `err()` helpers from `apps/api/src/lib/response.ts` (same as `auth.ts`).

### File Locations — Exact Paths

```
apps/
├── api/
│   └── src/
│       ├── index.ts                  ← UPDATE: register users.ts routes
│       └── routes/
│           └── users.ts              ← NEW: PATCH /v1/users/me
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   ├── fixtures/             ← NEW directory
    │   │   │   └── demo_schedule.dart  ← NEW: static demo task fixture
    │   │   ├── l10n/
    │   │   │   └── strings.dart      ← UPDATE: add onboarding string constants
    │   │   └── router/
    │   │       └── app_router.dart   ← UPDATE: add /onboarding route + onboarding gate
    │   └── features/
    │       ├── auth/
    │       │   └── presentation/
    │       │       └── auth_provider.dart  ← UPDATE: add kOnboardingCompleted, isOnboardingCompleted, completeOnboarding()
    │       └── onboarding/           ← NEW feature folder
    │           ├── domain/
    │           │   └── onboarding_step.dart  ← NEW enum
    │           └── presentation/
    │               ├── onboarding_flow.dart  ← NEW
    │               └── steps/
    │                   ├── sample_schedule_step.dart       ← NEW
    │                   ├── calendar_connection_step.dart   ← NEW
    │                   ├── energy_preferences_step.dart    ← NEW
    │                   └── working_hours_step.dart         ← NEW
    └── test/
        ├── core/
        │   └── fixtures/
        │       └── demo_schedule_test.dart   ← NEW
        └── features/
            ├── auth/
            │   └── auth_provider_test.dart   ← UPDATE: extend for onboarding methods
            └── onboarding/
                ├── onboarding_flow_test.dart   ← NEW
                └── sample_schedule_step_test.dart  ← NEW
```

### Previous Story Learnings (from Story 1.8)

- **Provider name gotcha**: The generated provider name is `authStateProvider` (not `authStateNotifierProvider`). Check `.g.dart` after `build_runner` to confirm exact names. Use `authStateNotifierProvider.notifier` for accessing methods.
- **`keepAlive: true`** is on `AuthStateNotifier` — any new methods added inherit this stability; callbacks captured by `ApiClient` stay live.
- **`TestWidgetsFlutterBinding.ensureInitialized()`** is required in any test that triggers platform channel calls (Keychain, SharedPreferences) at widget pump time.
- **`FlutterSecureStorage.setMockInitialValues({})`** + **`SharedPreferences.setMockInitialValues({})`** must both be called in `setUp` of any test that touches `AuthStateNotifier`.
- **`widget_test.dart`** needed `authStateProvider.overrideWithValue(authenticated)` after Story 1.8 introduced the auth gate — the onboarding gate added in this story will require the same pattern PLUS the `kOnboardingCompleted` flag to be set.
- **Auth route is outside `StatefulShellRoute`** — follow same pattern for `/onboarding`.
- **`ApiClient` injection via `ref.read(apiClientProvider)`** — never `new ApiClient()`. This applies to `completeOnboarding()` call to `PATCH /v1/users/me`.
- **`AppStrings` in `lib/core/l10n/strings.dart`** — add all new strings here; never inline string literals in widgets.
- **Feature-first architecture**: new feature = `lib/features/<feature>/` with `domain/`, `presentation/` subfolders (no `data/` for onboarding since there is no repository layer).
- **`build_runner` is local-only**; generated `*.g.dart` and `*.freezed.dart` files are committed to the repo.
- **Test baseline after Story 1.8**: 129 tests pass. All must continue passing.

### Pattern: `_AuthRefreshListenable` subscription (deferred issue from Story 1.8)

Story 1.8 noted that `_AuthRefreshListenable` subscription is never cancelled. Do NOT fix this in 1.9 (deferred). Just be aware that the pattern is architecturally imprecise but harmless in practice.

### Design Constraints — Exact References

| Constraint | Rule | Source |
|---|---|---|
| New York serif | ONLY for `onboardingWelcomeHeadline` on `SampleScheduleStep` | UX spec line ~1469–1475 |
| Brand voice | Warm, non-punitive; no "ADHD-specific" framing; "executive dysfunction" broadness; "calm, not clinical" | UX-DR36 |
| "Set this up later" | Every onboarding step must have this affordance | Epics AC #2 |
| Demo schedule — no API | Load from static fixture only; no network before onboarding complete | UX-DR27, AC #1 |
| Onboarding must be non-blocking | Skipping any/all steps lands user in the app with no degraded experience | Epics AC #2, #3 |
| Permission timing | No system permissions (calendar, etc.) before user sees sample schedule | Epics AC #1 |

### References

- Story 1.9 AC and user story: [Source: _bmad-output/planning-artifacts/epics.md — Story 1.9, line ~696]
- UX-DR27 (demo schedule fixture): [Source: _bmad-output/planning-artifacts/epics.md — line ~307]
- UX-DR32 (past self / future self voice): [Source: _bmad-output/planning-artifacts/epics.md — line ~316]
- UX-DR36 (brand voice constraints): [Source: _bmad-output/planning-artifacts/epics.md — line ~317]
- UX-DR14 (first Now tab empty state is onboarding magic moment): [Source: _bmad-output/planning-artifacts/epics.md — line ~286]
- Onboarding flow design intent ("show the magic first, then ask for data"): [Source: _bmad-output/planning-artifacts/ux-design-specification.md — line ~222]
- Flow 3 — First-Run Onboarding mermaid: [Source: _bmad-output/planning-artifacts/ux-design-specification.md — line ~929]
- Feature folder structure: [Source: _bmad-output/planning-artifacts/architecture.md — Flutter directory tree, line ~857]
- `users.ts` API route coverage (FR60, FR61, FR64, FR65, FR81, FR85, FR87): [Source: _bmad-output/planning-artifacts/architecture.md — line ~730]
- Energy preferences (FR5, FR61): [Source: _bmad-output/planning-artifacts/epics.md — line ~48, 117]
- New York serif usage constraint: [Source: _bmad-output/planning-artifacts/ux-design-specification.md — line ~1469–1475]
- `@hono/zod-openapi` requirement (every route must have schema): [Source: _bmad-output/planning-artifacts/architecture.md — line ~456]
- Drizzle `casing: 'camelCase'` (never manual field mapping): [Source: _bmad-output/planning-artifacts/architecture.md — line ~437]
- API envelope `ok()` / `err()` helpers: `apps/api/src/lib/response.ts`
- `AuthStateNotifier` (keepAlive, prewarmPrefs, SharedPreferences hint pattern): `apps/flutter/lib/features/auth/presentation/auth_provider.dart`
- Existing router (`app_router.dart`): `apps/flutter/lib/core/router/app_router.dart`
- `AppStrings`: `apps/flutter/lib/core/l10n/strings.dart`
- Theme tokens: `apps/flutter/lib/core/theme/app_colors.dart`
- Existing `NowScreen` (for visual reference of card/empty state patterns): `apps/flutter/lib/features/now/presentation/now_screen.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- **Provider notifier access with value overrides**: `ref.read(authStateProvider.notifier)` throws when the provider is overridden with `overrideWithValue(...)` in tests (Riverpod v3 restriction). Fixed by adding a static `isOnboardingCompletedFromPrefs` getter on `AuthStateNotifier` that reads directly from the pre-warmed `_prefs` instance, and using try-catch in the router redirect to fall back to this static accessor.
- **widget_test.dart needed onboarding prewarm**: After adding the onboarding gate to the router, the existing smoke test that overrides auth state to `Authenticated` was being redirected to `/onboarding`. Fixed by calling `SharedPreferences.setMockInitialValues({kOnboardingCompleted: true})` + `AuthStateNotifier.prewarmPrefs(prefs)` in setUp for the authenticated test case.
- **build_runner**: No new `@riverpod` or `@freezed` annotations were added — existing generated files unchanged.

### Completion Notes List

- Implemented `lib/core/fixtures/demo_schedule.dart` — pure static fixture with 5 `DemoTask` items (4 pending + 1 completed). Zero API calls, zero Riverpod.
- Extended `AuthStateNotifier` with `kOnboardingCompleted`, `isOnboardingCompleted` getter, `completeOnboarding()`, and `isOnboardingCompletedFromPrefs` static accessor for test-safe router access.
- Created full `lib/features/onboarding/` feature folder: domain enum, `OnboardingFlow` widget, and 4 step widgets (`SampleScheduleStep`, `CalendarConnectionStep`, `EnergyPreferencesStep`, `WorkingHoursStep`).
- `SampleScheduleStep` uses New York serif for the welcome headline (via `theme.textTheme.displaySmall` with serif fontFamily) and SF Pro for all task card copy. Completed task rendered with opacity reduction + strikethrough.
- `CalendarConnectionStep` implements stub OAuth simulation (1s spinner → success confirmation). `TODO(story-3.x)` comment in place.
- `EnergyPreferencesStep` and `WorkingHoursStep` persist to SharedPreferences with the specified keys. No API calls.
- Created `apps/api/src/routes/users.ts` with `PATCH /v1/users/me` using `@hono/zod-openapi`. `TODO(impl): Upsert via Drizzle` in place. Registered in `index.ts`.
- Router redirect extended with onboarding gate — authenticated users without `kOnboardingCompleted` are redirected to `/onboarding`. `/onboarding` added as sibling of `/auth/sign-in` outside `StatefulShellRoute`.
- 15 new `AppStrings` constants added using warm narrative voice (UX-DR32, UX-DR36).
- 23 new tests added (5 fixture tests, 9 sample schedule widget tests, 5 onboarding flow tests, 4 auth provider tests). All 152 tests pass (129 baseline + 23 new). No regressions.

### File List

**New files:**
- `apps/flutter/lib/core/fixtures/demo_schedule.dart`
- `apps/flutter/lib/features/onboarding/domain/onboarding_step.dart`
- `apps/flutter/lib/features/onboarding/presentation/onboarding_flow.dart`
- `apps/flutter/lib/features/onboarding/presentation/steps/sample_schedule_step.dart`
- `apps/flutter/lib/features/onboarding/presentation/steps/calendar_connection_step.dart`
- `apps/flutter/lib/features/onboarding/presentation/steps/energy_preferences_step.dart`
- `apps/flutter/lib/features/onboarding/presentation/steps/working_hours_step.dart`
- `apps/api/src/routes/users.ts`
- `apps/flutter/test/core/fixtures/demo_schedule_test.dart`
- `apps/flutter/test/features/onboarding/sample_schedule_step_test.dart`
- `apps/flutter/test/features/onboarding/onboarding_flow_test.dart`
- `apps/flutter/test/features/auth/auth_provider_test.dart`

**Modified files:**
- `apps/flutter/lib/features/auth/presentation/auth_provider.dart`
- `apps/flutter/lib/core/router/app_router.dart`
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/api/src/index.ts`
- `apps/flutter/test/widget_test.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Change Log

- 2026-03-30: Story 1.9 implemented — Onboarding Flow & Sample Schedule. Added static demo fixture, 4-step onboarding flow with "Set this up later" affordances on each step, onboarding gate in router, `PATCH /v1/users/me` API stub, and 23 new tests. All 152 tests pass.
