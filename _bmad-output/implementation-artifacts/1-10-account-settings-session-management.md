# Story 1.10: Account Settings & Session Management

Status: review

## Story

As a user,
I want to manage my app appearance, view active sessions, and revoke device access remotely,
So that I have full control over how On Task looks and who can access my account.

## Acceptance Criteria

1. **Given** the user opens Settings → Appearance, **When** they adjust the theme, **Then** they can select from four themes: Clay, Slate, Dusk, Monochrome **And** they can toggle light, dark, or system (automatic) mode **And** they can adjust text size with at least three increments above the system default (NFR-A5) **And** all changes apply immediately with no restart required (FR77).

2. **Given** the user opens Settings → Security → Active Sessions, **When** the sessions list loads, **Then** each session shows: device name, approximate location (city/country), and last-active timestamp **And** the current session is labelled "This device" **And** every other session has a "Sign out this device" action (FR91).

3. **Given** the user taps "Sign out this device" for a non-current session, **When** the action is confirmed, **Then** that session's refresh token is immediately invalidated server-side **And** the signed-out device will receive a 401 on its next API call and be forced to re-authenticate.

4. **Given** the user is offline and makes changes, then reconnects, **When** sync occurs and a conflict exists between offline and server-side changes to the same task, **Then** server state wins for structural properties (list membership, assignment) **And** client state wins for content properties (title, notes) if the client timestamp is more recent than the server's last-modified timestamp **And** resolved conflicts are communicated to the user in plain language (NFR-UX2, FR94).

## Tasks / Subtasks

- [x] Create `lib/features/settings/` feature folder (AC: 1, 2, 3)
  - [x] `lib/features/settings/presentation/settings_screen.dart` — root Settings screen, `ConsumerStatefulWidget`; lists navigable sections: Appearance, Scheduling Preferences, Security (including Active Sessions), Notifications (stub), Account (stub for Story 1.11)
  - [x] `lib/features/settings/presentation/appearance_settings_screen.dart` — theme picker + mode toggle + text size increments
  - [x] `lib/features/settings/presentation/sessions_screen.dart` — active sessions list with revoke action
  - [x] `lib/features/settings/domain/session_model.dart` — `@freezed` model: `sessionId`, `deviceName`, `location`, `lastActiveAt`, `isCurrentDevice`
  - [x] `lib/features/settings/data/settings_repository.dart` — `GET /v1/auth/sessions` and `DELETE /v1/auth/sessions/:sessionId`

- [x] Implement Appearance Settings (AC: 1)
  - [x] Theme picker: `CupertinoSegmentedControl` or a custom tile list for Clay, Slate, Dusk, Monochrome; tapping a tile immediately updates the active `themeVariantProvider`
  - [x] Mode toggle: `CupertinoSegmentedControl` — "Light", "Dark", "Automatic"; updates a new `themeModeProvider` in `theme_provider.dart`; persisted to `shared_preferences` key `theme_mode`; maps to Flutter `ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`
  - [x] Text size: three increments above system default — implement as a `CupertinoSlider` (or segmented control) that updates a `textScaleIncrementProvider`; persisted to `shared_preferences` key `text_scale_increment`; applied to `MaterialApp.router` via `builder:` wrapping `MediaQuery` with adjusted `textScaler`
  - [x] All changes apply immediately (no "Save" button) via Riverpod state updates flowing up to `main.dart`
  - [x] Strings in `AppStrings` — no inline literals

- [x] Extend `theme_provider.dart` for mode and text scale (AC: 1)
  - [x] Add `@riverpod Future<ThemeMode> themeMode(ThemeModeRef ref)` — reads `shared_preferences` key `theme_mode`, defaults to `ThemeMode.system`
  - [x] Add `@riverpod Future<double> textScaleIncrement(TextScaleIncrementRef ref)` — reads `theme_text_scale_increment`, defaults to `0.0`
  - [x] Add `setThemeVariant(ThemeVariant)`, `setThemeMode(ThemeMode)`, `setTextScaleIncrement(double)` methods (or use `StateNotifier` pattern if mutations are needed — keep consistent with the existing `themeVariantProvider` approach)
  - [x] Wire `themeMode` and `textScaler` into `main.dart` `OnTaskApp.build()` alongside the existing `theme:`/`darkTheme:` — use `builder:` to inject adjusted `MediaQuery` for text scale

- [x] Add Active Sessions API routes in Hono (AC: 2, 3)
  - [x] `apps/api/src/routes/auth.ts` — ADD: `GET /v1/auth/sessions` → returns list of sessions for the authenticated user; each session: `{ sessionId, deviceName, location, lastActiveAt, isCurrentDevice }`
  - [x] `apps/api/src/routes/auth.ts` — ADD: `DELETE /v1/auth/sessions/:sessionId` → invalidates (deletes) the specified refresh token; returns 204 on success; returns 404 if not found; returns 403 if attempting to delete current session
  - [x] Use `@hono/zod-openapi` schemas for both routes — no untyped routes (ARCH rule)
  - [x] Use `ok()` / `err()` helpers from `apps/api/src/lib/response.ts`
  - [x] Add `TODO(impl): Query and delete from refresh_tokens table via Drizzle` — stub only; return fixture data for `GET`, return 204 for `DELETE`
  - [x] Sessions schema must include `deviceName` (from User-Agent), `location` (stub: "Unknown location"), `lastActiveAt` (ISO 8601), `isCurrentDevice` (compare session ID in JWT claim)

- [x] Implement Sessions Screen (AC: 2, 3)
  - [x] `GET /v1/auth/sessions` via `SettingsRepository.getSessions()` → exposes via `@riverpod AsyncValue<List<SessionModel>> activeSessions()`
  - [x] Render each session as a `CupertinoListTile`-style row: device name (bold), location + last active (secondary text), "This device" badge for current session
  - [x] "Sign out this device" is a `CupertinoButton` (destructive styling, NOT `CupertinoButton.filled`) — shown only on non-current-session rows
  - [x] Tapping "Sign out this device" shows a `CupertinoAlertDialog` confirmation: "Sign out [device name]?" with Cancel and "Sign out" actions
  - [x] On confirmation: call `DELETE /v1/auth/sessions/:sessionId` → on success, remove that session from the list (optimistic update or refetch)
  - [x] Error state: use plain-language error message via `AppStrings` (NFR-UX2) — no technical error codes surfaced

- [x] Implement offline conflict resolution bootstrap (AC: 4)
  - [x] Create `lib/core/sync/sync_manager.dart` — this file is listed in the architecture as the home of FR94 conflict resolution logic
  - [x] `SyncManager` is a `@riverpod` class; listens for connectivity changes (use `connectivity_plus` package — already needed); on reconnect, processes `pending_operations` table via FIFO
  - [x] Apply conflict resolution policy per the architecture: task title/notes/due date/priority → last-write-wins with `clientTimestamp`; structural properties (list membership) → server wins
  - [x] After conflict resolution, if any conflict was detected, surface a plain-language `SnackBar`/`CupertinoAlertDialog` — strings in `AppStrings` (NFR-UX2); no technical details
  - [x] Add `connectivity_plus` to `pubspec.yaml` if not already present
  - [x] `lib/core/storage/sync_manager.dart` test: `test/core/sync/sync_manager_test.dart` — already listed in architecture's test directory; write conflict resolution boundary tests

- [x] Add Settings navigation (AC: 1, 2)
  - [x] Add profile/account icon button to navigation header (UX spec: "Settings accessible via profile/account icon in the navigation header")
  - [x] On tap, push Settings screen as a modal sheet or full navigation route — use `CupertinoPageRoute` or `showCupertinoModalPopup` consistent with UX spec
  - [x] Add `/settings` GoRoute to `app_router.dart` — inside `StatefulShellRoute` so the tab bar persists, or as a modal presentation if UX spec indicates modal
  - [x] macOS: Settings accessible via `⌘,` keyboard shortcut (UX-DR23) — wire this in `app_router.dart` or the macOS menu system

- [x] Add strings to `AppStrings` (AC: 1, 2, 3, 4)
  - [x] Settings section titles: `settingsTitle`, `settingsAppearance`, `settingsSecurity`, `settingsActiveSessions`, `settingsScheduling`, `settingsAccount`, `settingsNotifications`
  - [x] Appearance: `appearanceThemeLabel`, `appearanceThemeClay`, `appearanceThemeSlate`, `appearanceThemeDusk`, `appearanceThemeMonochrome`, `appearanceModeLight`, `appearanceModeDark`, `appearanceModeSystem`, `appearanceTextSizeLabel`
  - [x] Sessions: `sessionsTitle`, `sessionsCurrentDevice`, `sessionsSignOut`, `sessionsSignOutConfirmTitle`, `sessionsSignOutConfirmMessage`, `sessionsSignOutCancel`, `sessionsSignOutConfirm`, `sessionsLastActive`, `sessionsSignOutSuccessMessage`, `sessionsSignOutErrorMessage`
  - [x] Sync: `syncConflictResolvedMessage`

- [x] Write tests (AC: 1–4)
  - [x] `test/features/settings/appearance_settings_test.dart`: pump `AppearanceSettingsScreen` → verify four theme tiles render; verify tapping a tile updates `themeVariantProvider`; verify mode toggle updates `themeModeProvider`; verify changes apply immediately (no save button)
  - [x] `test/features/settings/sessions_screen_test.dart`: mock `SettingsRepository`; verify sessions render with device name + location + last-active; verify current session shows "This device" badge; verify non-current session shows "Sign out this device"; verify confirmation dialog appears on tap; verify `DELETE` is called on confirmation
  - [x] `test/core/sync/sync_manager_test.dart`: conflict resolution boundary tests — server wins for structural props; client wins for content props when `clientTimestamp` is newer; plain-language message surfaced when conflict detected; no message when no conflict
  - [x] Run `flutter test` — all 152 existing tests must continue passing

- [x] Run `build_runner` and commit generated files
  - [x] `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x] Commit any new `*.g.dart` files for new `@riverpod` or `@freezed` annotations

## Dev Notes

### Critical Architecture Constraints

**Settings feature folder location:**
```
apps/flutter/lib/features/settings/
├── data/
│   └── settings_repository.dart      ← GET /v1/auth/sessions, DELETE /v1/auth/sessions/:id
├── domain/
│   └── session_model.dart             ← @freezed model
└── presentation/
    ├── settings_screen.dart           ← root settings list
    ├── appearance_settings_screen.dart
    └── sessions_screen.dart
```
This is a clean architecture feature folder — `data/` is needed here because there IS a repository layer (unlike onboarding which had no API calls).

**`theme_provider.dart` already exists — extend it, do NOT recreate it:**
Story 1.5 created `apps/flutter/lib/core/theme/theme_provider.dart` with:
- `@riverpod Future<ThemeVariant> themeVariant(...)` — reads `shared_preferences` key `theme_variant`, defaults to `ThemeVariant.clay`
- SharedPreferences key: `'theme_variant'` (string)

This story adds `themeMode` and `textScaleIncrement` to the same file. Use the exact same provider pattern as `themeVariant`. SharedPreferences keys for new providers: `'theme_mode'` and `'theme_text_scale_increment'`.

**`ThemeVariant` enum is in `app_theme.dart` — four values:**
```dart
enum ThemeVariant { clay, slate, dusk, monochrome }
```
Note: UX spec calls the fourth theme "Forge" (Slate & Gold), but the code enum value used in Story 1.5 is `ThemeVariant.slate` and the UX-facing label is "Slate". The `Monochrome` theme is a separate fourth variant. The enum is: `clay`, `slate`, `dusk`, `monochrome`. Do NOT rename or add values — match what exists in `app_theme.dart`.

**Theme changes must apply immediately — wire into `main.dart`:**
Story 1.5 already wired `themeVariantProvider` into `MaterialApp.router`. The `theme:` and `darkTheme:` properties are already derived from the active `ThemeVariant`. For text scale, add a `builder:` property to `MaterialApp.router`:

```dart
// In main.dart — add builder: for text scale
builder: (context, child) {
  final increment = ref.watch(textScaleIncrementProvider).valueOrNull ?? 0.0;
  final currentScale = MediaQuery.of(context).textScaler;
  // Apply increment as an additive factor — minimum 1.0, increment by 0.1 per step
  final newScale = TextScaler.linear(
    (currentScale.scale(1.0) + increment).clamp(1.0, 3.0)
  );
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: newScale),
    child: child!,
  );
},
```

**Sessions are in `auth.ts` — do NOT create a separate `sessions.ts`:**
Per architecture: `apps/api/src/routes/auth.ts` covers `FR48, FR91, FR92`. The `GET /v1/auth/sessions` and `DELETE /v1/auth/sessions/:sessionId` routes belong in `auth.ts`, not a new file. The existing `auth.ts` file already exists from Story 1.8 — extend it.

**Hono route additions — follow exact same `@hono/zod-openapi` pattern as existing auth routes:**
No untyped routes (ARCH rule). Use `@hono/zod-openapi` schemas. Use `ok()` / `err()` from `apps/api/src/lib/response.ts`. Same envelope: `{ data: { ... } }` for success, `{ error: { ... } }` for errors.

**Session revocation mechanics — JWT is short-lived; refresh token revocation is what matters:**
Per architecture: "Access token lifetime: 15 minutes; refresh tokens rotated on every use, revocable per session." Revoking a session = deleting the refresh token from the DB. The access token for the revoked device will expire naturally within 15 minutes. This is the correct and documented behaviour — do NOT try to invalidate access tokens directly (no blocklist needed for this story).

**`DELETE /v1/auth/sessions/:sessionId` must check for current session:**
Return `403 Forbidden` if the `sessionId` matches the current authenticated session (prevents self-lockout). Compare against the session ID encoded in the JWT claim. Add `UserErrorSchema` 403 response path.

**Offline conflict resolution — `sync_manager.dart` is a NEW file:**
`apps/flutter/lib/core/sync/sync_manager.dart` does not exist yet. Create it. Architecture lists it at this exact path (line ~855 of architecture.md). The test file `test/core/sync/sync_manager_test.dart` is also new. This is the first time `drift` + `pending_operations` table is exercised for conflict resolution. The `pending_operations` drift table schema was defined in Story 1.3 (see architecture section).

**`connectivity_plus` for sync manager:**
Check if `connectivity_plus` is already in `pubspec.yaml`. If not, add it. It is a standard Flutter plugin for network connectivity status — use it to trigger sync on reconnect.

**Conflict resolution policy (exact from architecture FR94):**
| Data Type | Policy |
|---|---|
| Task properties (title, notes, due date, priority) | Last-write-wins with client timestamp |
| Task completion status | Client timestamp preserved |
| Structural (list membership, assignment) | Server wins |
| Schedule / calendar blocks | Server-authoritative |

**Plain-language conflict communication (NFR-UX2):**
When a conflict is resolved, surface a single non-technical message — e.g., `AppStrings.syncConflictResolvedMessage` = "Some changes were updated to match what's on the server." Do NOT surface technical details about which field won or lost.

**Energy preferences migration deferred:**
Story 1.9 stored energy preferences (peak hours, low-energy hours, wind-down time, work start/end) locally in `SharedPreferences` with keys: `pref_peak_start`, `pref_peak_end`, `pref_low_energy_start`, `pref_low_energy_end`, `pref_wind_down_start`, `pref_wind_down_end`, `pref_work_start`, `pref_work_end`. This story adds Settings → Scheduling Preferences as a stub/navigation entry. The full energy preferences API persistence is deferred — do NOT call a new endpoint in this story. Display the stored local values but leave server sync for when the scheduling API is built (Epic 3).

**`CupertinoButton` for all CTAs — destructive variant for Sign Out:**
Use `CupertinoButton` (not `ElevatedButton`) consistent with the pattern from Stories 1.5–1.9. For the "Sign out this device" action, use destructive red styling:
```dart
CupertinoButton(
  onPressed: _confirmSignOut,
  child: Text(AppStrings.sessionsSignOut, style: TextStyle(color: CupertinoColors.destructiveRed)),
)
```

**No new feature colour — use semantic tokens:**
All colours must use semantic tokens from `AppColors` / `Theme.of(context)`. Never hardcode hex values in feature widgets. `CupertinoColors.destructiveRed` is acceptable for destructive actions as a system-semantic colour.

**TimeOfDay formatting utility — fix deferred issue from Story 1.9:**
Story 1.9 deferred a note that `_formatTime()` is duplicated across 3 files. If this story touches any of those files, extract the shared utility to `apps/flutter/lib/core/utils/time_format.dart`. If not touching those files, leave the deferred issue as-is.

**Settings navigation — modal presentation or pushed route:**
UX spec says "Settings accessible via profile/account icon in the navigation header (persistent across all tabs)." Use `CupertinoPageRoute` pushed from the profile icon tap. The profile icon should be in the navigation bar (via `CupertinoNavigationBar.trailing` or equivalent). This does NOT need to be inside `StatefulShellRoute` — a modal push is appropriate since Settings is not a primary tab.

**macOS keyboard shortcut `⌘,` for Settings (UX-DR23):**
Per UX spec, `⌘,` opens Settings on macOS. Wire this in the macOS menu or as a keyboard shortcut in `app_router.dart`. Cupertino apps on macOS automatically create an Application menu — `⌘,` may map to a `PlatformMenuBar` or `SingleActivator`. Check if the existing macOS shell from Story 1.7 has any keyboard shortcut infrastructure to extend.

### File Locations — Exact Paths

```
apps/
├── api/
│   └── src/
│       └── routes/
│           └── auth.ts               ← UPDATE: add GET /v1/auth/sessions + DELETE /v1/auth/sessions/:id
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   ├── l10n/
    │   │   │   └── strings.dart      ← UPDATE: add settings/appearance/sessions strings
    │   │   ├── router/
    │   │   │   └── app_router.dart   ← UPDATE: add /settings route
    │   │   ├── sync/                 ← NEW directory
    │   │   │   └── sync_manager.dart ← NEW: FR94 conflict resolution
    │   │   └── theme/
    │   │       └── theme_provider.dart ← UPDATE: add themeMode + textScaleIncrement providers
    │   ├── features/
    │   │   └── settings/             ← NEW feature folder
    │   │       ├── data/
    │   │       │   └── settings_repository.dart
    │   │       ├── domain/
    │   │       │   └── session_model.dart
    │   │       └── presentation/
    │   │           ├── settings_screen.dart
    │   │           ├── appearance_settings_screen.dart
    │   │           └── sessions_screen.dart
    │   └── main.dart                 ← UPDATE: wire themeMode + textScaler builder
    └── test/
        ├── core/
        │   └── sync/
        │       └── sync_manager_test.dart  ← NEW
        └── features/
            └── settings/
                ├── appearance_settings_test.dart  ← NEW
                └── sessions_screen_test.dart      ← NEW
```

### Previous Story Learnings (from Stories 1.8, 1.9)

- **Provider name generated by `build_runner`**: Always check `.g.dart` after `build_runner` to confirm exact generated provider names. Pattern: `@riverpod` on `Future<ThemeVariant> themeVariant(...)` → generates `themeVariantProvider`. New providers `themeMode` and `textScaleIncrement` will generate `themeModeProvider` and `textScaleIncrementProvider` respectively.
- **`keepAlive: true` on `AuthStateNotifier`**: Any new provider that needs stability (e.g., a settings notifier that persists state and needs to survive widget rebuilds) should use `@Riverpod(keepAlive: true)`. The existing `themeVariantProvider` from Story 1.5 does NOT have `keepAlive` — check whether it needs mutation. If using a notifier pattern for write operations, use `@riverpod` with a class-based notifier.
- **`@riverpod` on async providers — use `AsyncValue` or `.valueOrNull` in consumers**: When watching async providers (like `themeVariantProvider`, `themeModeProvider`), use `ref.watch(provider).valueOrNull ?? defaultValue` in widget builders to avoid blocking UI on the async load.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})` in all tests**: Any test that touches `AuthStateNotifier` or any provider that reads `SharedPreferences` at build time must call both mocks in `setUp`. Established in Stories 1.8–1.9.
- **`ProviderContainer` for unit testing providers**: Use `ProviderContainer` with `overrides` for provider logic tests — never `WidgetTester` alone for business logic. Pattern from architecture testing section.
- **`ref.read(apiClientProvider)` — never `new ApiClient()`**: `SettingsRepository` must receive `ApiClient` injected via Riverpod, not constructed directly.
- **Feature-first architecture**: `lib/features/settings/` with `data/`, `domain/`, `presentation/` subfolders. Unlike onboarding (no `data/` folder), settings DOES have a repository layer with API calls.
- **All strings in `AppStrings` (`lib/core/l10n/strings.dart`)**: Never inline string literals in widgets. All new strings added to `AppStrings` with warm narrative voice consistent with the product tone (UX-DR36).
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **Test baseline after Story 1.9**: 152 tests pass. All must continue passing.
- **Widget tests for screens with Riverpod**: Override providers in `ProviderScope(overrides: [...])` — do not rely on real network calls or real SharedPreferences in widget tests.
- **`AuthStateNotifier.isOnboardingCompletedFromPrefs` static accessor**: Story 1.9 added a static `isOnboardingCompletedFromPrefs` getter for test-safe router access. If router redirect logic needs settings state, consider the same pattern — avoid calling `.notifier` on a `value`-overridden provider in tests (Riverpod v3 restriction).

### Deferred Issues from Previous Stories to Address

- **TimeOfDay formatting duplication** (from Story 1.9 review): If this story touches `SampleScheduleStep`, `EnergyPreferencesStep`, or `WorkingHoursStep`, extract the duplicated `_formatTime()` logic to `apps/flutter/lib/core/utils/time_format.dart` as a shared utility. Otherwise leave deferred.

### Design Constraints — Exact References

| Constraint | Rule | Source |
|---|---|---|
| Theme picker | 4 themes: Clay, Slate, Dusk, Monochrome; all have light/dark variants | UX spec §Colour System; Story 1.5 `ThemeVariant` enum |
| Theme mode | Light / Dark / System (automatic) | FR77, NFR-A5, UX spec §Colour System line ~687 |
| Text size | At minimum 3 increments above system default | NFR-A5 |
| Dynamic Type | All text uses theme text styles — no hardcoded sizes | NFR-A3, UX-DR22, Story 1.5 enforcement |
| Session display | Device name + city/country location + last-active timestamp | FR91, AC #2 |
| Current session label | "This device" | FR91, AC #2 |
| Session revocation | Refresh token invalidation; device gets 401 on next API call | FR91, NFR-S5, AC #3 |
| Conflict comms | Plain language, non-technical | NFR-UX2, AC #4 |
| Conflict policy | Server wins structural; client wins content (newer timestamp) | FR94, architecture §Offline Conflict Resolution Policy |
| Colour tokens | Semantic tokens only — no hardcoded hex in feature layer | Story 1.5 architecture decision |
| Button style | `CupertinoButton` / `CupertinoButton.filled` — no `ElevatedButton` | Stories 1.5–1.9 pattern |
| macOS `⌘,` | Opens Settings | UX-DR23 |
| Settings access | Profile/account icon in nav header (persistent across tabs) | UX spec §Navigation, line ~101 |
| AppStrings | All user-facing strings in `lib/core/l10n/strings.dart` | Stories 1.6–1.9 pattern |

### References

- Story 1.10 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` — Story 1.10, line ~724]
- FR77 (appearance customisation): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~118]
- FR91 (session management): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~129]
- FR94 (conflict resolution): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~131]
- NFR-A5 (appearance settings: light/dark/system + text size): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~181]
- NFR-UX2 (plain-language errors): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~186]
- NFR-S5 (short-lived JWTs; refresh tokens rotated and revocable per session): [Source: `_bmad-output/planning-artifacts/epics.md` — line ~157]
- Offline conflict resolution policy table: [Source: `_bmad-output/planning-artifacts/architecture.md` — §Offline Conflict Resolution Policy, line ~184]
- Auth pattern (JWT, 15min access token, refresh rotation): [Source: `_bmad-output/planning-artifacts/architecture.md` — §Auth Pattern, line ~563]
- `auth.ts` covers FR48, FR91, FR92: [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~729]
- `settings/` feature folder: [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~875]
- `sync_manager.dart` path (FR94): [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~855]
- `pending_operations` drift table schema: [Source: `_bmad-output/planning-artifacts/architecture.md` — §Flutter Offline Queue, line ~612]
- `app_theme.dart` (NFR-A4, NFR-A5): [Source: `_bmad-output/planning-artifacts/architecture.md` — line ~843]
- Settings accessible via profile icon: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~101]
- Four themes ship day one; dark mode override in Settings → Appearance: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — line ~687]
- macOS `⌘,` for Settings: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — UX-DR23, line ~299]
- `ThemeVariant` enum + `theme_provider.dart` pattern: `apps/flutter/lib/core/theme/theme_provider.dart`
- `AppTheme.light()` / `AppTheme.dark()` API: `apps/flutter/lib/core/theme/app_theme.dart`
- `AppColors` constants: `apps/flutter/lib/core/theme/app_colors.dart`
- `AppStrings`: `apps/flutter/lib/core/l10n/strings.dart`
- `ApiClient` Riverpod provider: `apps/flutter/lib/core/network/api_client.dart`
- Existing `auth.ts` route: `apps/api/src/routes/auth.ts`
- `ok()` / `err()` helpers: `apps/api/src/lib/response.ts`
- `app_router.dart`: `apps/flutter/lib/core/router/app_router.dart`
- `main.dart`: `apps/flutter/lib/main.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `valueOrNull` → `.value` (Riverpod v3 uses `.value` on `AsyncValue`, not `.valueOrNull`)
- Fixed missing `drift` import (`Value`) in `sync_manager.dart` — imported `package:drift/drift.dart` show `Value`

### Completion Notes List

- Implemented full `lib/features/settings/` feature folder with clean architecture: `data/`, `domain/`, `presentation/`
- Extended `theme_provider.dart` with `themeModeProvider`, `textScaleIncrementProvider`, and `ThemeSettings` notifier (write gateway)
- Wired `themeMode` + `textScaler builder:` into `main.dart` `OnTaskApp.build()` — all appearance changes apply immediately with no restart (FR77, NFR-A5)
- Added `GET /v1/auth/sessions` and `DELETE /v1/auth/sessions/:sessionId` to `apps/api/src/routes/auth.ts` using `@hono/zod-openapi` schemas — stub implementation with fixture data and TODO(impl) comments (FR91, NFR-S5)
- Created `lib/core/sync/sync_manager.dart` — `@riverpod` class with full conflict resolution policy: content props (title/notes) use last-write-wins with `clientTimestamp`; structural props (list membership, assignment) always server-wins (FR94)
- Added `connectivity_plus: ^6.1.4` to `pubspec.yaml`
- Added profile icon to iOS shell navigation header (`CupertinoNavigationBar.trailing`) pushing `SettingsScreen` via `CupertinoPageRoute`; macOS ⌘, shortcut was already wired in Story 1.7 (`OpenSettingsIntent` in `macos_keyboard_shortcuts.dart`)
- All 29 new tests pass; 181 total (152 pre-existing + 29 new); no regressions
- `build_runner` run and all generated `.g.dart` / `.freezed.dart` files committed

### File List

- `apps/api/src/routes/auth.ts` — UPDATED: added GET /v1/auth/sessions + DELETE /v1/auth/sessions/:sessionId
- `apps/flutter/lib/core/l10n/strings.dart` — UPDATED: added all settings/appearance/sessions/sync strings
- `apps/flutter/lib/core/sync/sync_manager.dart` — NEW: FR94 conflict resolution manager
- `apps/flutter/lib/core/sync/sync_manager.g.dart` — NEW: generated Riverpod provider
- `apps/flutter/lib/core/theme/theme_provider.dart` — UPDATED: added themeModeProvider, textScaleIncrementProvider, ThemeSettings notifier
- `apps/flutter/lib/core/theme/theme_provider.g.dart` — UPDATED: regenerated with new providers
- `apps/flutter/lib/features/settings/data/settings_repository.dart` — NEW: GET sessions + DELETE session
- `apps/flutter/lib/features/settings/data/settings_repository.g.dart` — NEW: generated providers
- `apps/flutter/lib/features/settings/domain/session_model.dart` — NEW: @freezed SessionModel
- `apps/flutter/lib/features/settings/domain/session_model.freezed.dart` — NEW: generated
- `apps/flutter/lib/features/settings/domain/session_model.g.dart` — NEW: generated
- `apps/flutter/lib/features/settings/presentation/appearance_settings_screen.dart` — NEW: theme/mode/text size UI
- `apps/flutter/lib/features/settings/presentation/sessions_screen.dart` — NEW: active sessions + revoke flow
- `apps/flutter/lib/features/settings/presentation/settings_screen.dart` — UPDATED: full implementation (was stub)
- `apps/flutter/lib/features/shell/presentation/app_shell.dart` — UPDATED: added profile icon to iOS navigation header
- `apps/flutter/lib/main.dart` — UPDATED: wired themeMode + textScaler builder
- `apps/flutter/macos/Flutter/GeneratedPluginRegistrant.swift` — UPDATED: connectivity_plus plugin registration
- `apps/flutter/pubspec.yaml` — UPDATED: added connectivity_plus ^6.1.4
- `apps/flutter/pubspec.lock` — UPDATED: locked connectivity_plus dependencies
- `apps/flutter/test/core/sync/sync_manager_test.dart` — NEW: conflict resolution boundary tests (11 tests)
- `apps/flutter/test/features/settings/appearance_settings_test.dart` — NEW: appearance screen tests (8 tests)
- `apps/flutter/test/features/settings/sessions_screen_test.dart` — NEW: sessions screen tests (10 tests)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — UPDATED: story status → review

## Change Log

- 2026-03-30: Story 1.10 implemented — Account Settings & Session Management (claude-sonnet-4-6)
