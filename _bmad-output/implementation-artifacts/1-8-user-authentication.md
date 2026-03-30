# Story 1.8: User Authentication

Status: review

## Story

As a user,
I want to sign in with Apple, Google, or email and password,
so that I can securely access my On Task account across all my devices.

## Acceptance Criteria

1. **Given** the app is launched for the first time or after sign-out, **When** the authentication screen is shown, **Then** Sign in with Apple, Sign in with Google, and email/password options are all visible, **And** Sign in with Apple is the topmost option on iOS per Apple HIG

2. **Given** a user successfully authenticates, **When** the server issues tokens, **Then** the access token is a short-lived JWT (≤ 15 minutes expiry), **And** the refresh token is rotated on every use — the previous token is immediately invalidated (NFR-S5), **And** both tokens are stored in the iOS Keychain — not in NSUserDefaults or unprotected storage

3. **Given** a user's access token has expired mid-session, **When** the app makes an API request, **Then** the 401 interceptor from Story 1.4 silently refreshes the token and retries once with no user-visible interruption

4. **Given** a user enters an incorrect email or password, **When** authentication fails, **Then** a plain-language error message is shown with a recovery action link to reset the password, **And** no technical error codes or internal identifiers are visible to the user (NFR-UX2)

5. **Given** any data is transmitted between app and API, **When** the connection is established, **Then** TLS 1.3 minimum is enforced (NFR-S1)

## Tasks / Subtasks

- [x] Add auth dependencies to `pubspec.yaml` (AC: 1, 2)
  - [x] Add `sign_in_with_apple: ^6.1.2` to `dependencies`
  - [x] Add `google_sign_in: ^6.2.2` to `dependencies`
  - [x] Add `flutter_secure_storage: ^9.2.2` to `dependencies`
  - [x] Run `flutter pub get` to resolve
  - [x] Configure iOS entitlements: add `com.apple.developer.applesignin` to `ios/Runner/Runner.entitlements`
  - [x] Configure `Info.plist` for Google Sign In: add `CFBundleURLSchemes` entry with reversed client ID
  - [x] Note: `shared_preferences` is already installed but tokens MUST use `flutter_secure_storage` (Keychain-backed) — NOT `shared_preferences`

- [x] Create auth API endpoint stubs in Hono worker (AC: 2, 5)
  - [x] Create `apps/api/src/routes/auth.ts` with `@hono/zod-openapi` schemas
  - [x] `POST /v1/auth/apple` — body: `{ identityToken: string, authorizationCode: string }` → returns `{ data: { accessToken, refreshToken, userId } }`
  - [x] `POST /v1/auth/google` — body: `{ idToken: string }` → returns `{ data: { accessToken, refreshToken, userId } }`
  - [x] `POST /v1/auth/email` — body: `{ email: string, password: string }` → returns `{ data: { accessToken, refreshToken, userId } }` or `{ error: { code: "INVALID_CREDENTIALS", message: "..." } }`
  - [x] `POST /v1/auth/refresh` — body: `{ refreshToken: string }` → returns `{ data: { accessToken, refreshToken } }` (old token invalidated)
  - [x] Register all routes in the Hono app entry point
  - [x] TLS 1.3 is enforced at Cloudflare edge — no app-level TLS config needed; document this in code comments

- [x] Create `lib/features/auth/domain/` models (AC: 1, 2)
  - [x] Create `lib/features/auth/domain/auth_result.dart` — `@freezed` sealed class: `authenticated(userId, accessToken, refreshToken)` | `unauthenticated()` | `error(message)`
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` and commit generated `auth_result.freezed.dart`

- [x] Create `lib/features/auth/data/` — token storage and auth repository (AC: 2, 3)
  - [x] Create `lib/features/auth/data/token_storage.dart` — wraps `flutter_secure_storage`; exposes `saveTokens(accessToken, refreshToken)`, `getAccessToken()`, `getRefreshToken()`, `clearTokens()`; use `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` for Keychain access
  - [x] Create `lib/features/auth/data/auth_repository.dart` — `@riverpod`-annotated; depends on `ApiClient` via `ref.watch(apiClientProvider)` (never instantiate `ApiClient` directly); implements `signInWithApple()`, `signInWithGoogle()`, `signInWithEmail(email, password)`, `signOut()`
  - [x] `signInWithApple()` calls `SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName])`, then posts `identityToken` + `authorizationCode` to `POST /v1/auth/apple`
  - [x] `signInWithGoogle()` calls `GoogleSignIn().signIn()`, obtains `idToken` from `GoogleSignInAuthentication`, then posts to `POST /v1/auth/google`
  - [x] Both social flows and email flow call `TokenStorage.saveTokens()` on success
  - [x] `signOut()` calls `TokenStorage.clearTokens()` and sets auth state to unauthenticated

- [x] Update `AuthInterceptor` to use `flutter_secure_storage` (AC: 3)
  - [x] `apps/flutter/lib/core/network/interceptors/auth_interceptor.dart` currently uses `shared_preferences` for token storage — REPLACE with `TokenStorage` (inject via constructor parameter for testability)
  - [x] Remove `SharedPreferences` import; replace `prefs.getString(kAccessToken)` with `await tokenStorage.getAccessToken()`
  - [x] Implement the `TODO(story-1.8)` in `_tryRefreshToken()`: call `POST /v1/auth/refresh` with the stored refresh token; on success persist new tokens via `TokenStorage.saveTokens()` and return `true`; on failure return `false`
  - [x] Implement the `TODO(story-1.8)` in `_forceSignOut()`: after clearing tokens, emit sign-out via Riverpod auth provider (invalidate `authStateProvider`)
  - [x] Keep `kAccessToken` / `kRefreshToken` constants in the file for documentation clarity but stop using SharedPreferences

- [x] Create auth state Riverpod provider (AC: 1, 2, 3)
  - [x] Create `lib/features/auth/presentation/auth_provider.dart` — `@riverpod` `AuthResult authState(AuthStateRef ref)` that exposes current authentication state
  - [x] Provider initializes by reading stored access token from `TokenStorage` — if token exists → `AuthResult.authenticated()`; else → `AuthResult.unauthenticated()`
  - [x] `AuthInterceptor._forceSignOut()` must call `ref.invalidate(authStateProvider)` to reset to unauthenticated (inject `ProviderContainer` or use a `StreamController` / `Notifier` pattern)
  - [x] Recommended: use `@riverpod` `AuthNotifier extends Notifier<AuthResult>` for mutable state

- [x] Create auth gate in router — redirect unauthenticated users (AC: 1)
  - [x] In `apps/flutter/lib/core/router/app_router.dart`, add a `redirect` callback to the `GoRouter` that watches `authStateProvider`
  - [x] If `authState` is `unauthenticated` and current location is not `/auth/*` → redirect to `/auth/sign-in`
  - [x] If `authState` is `authenticated` and current location is `/auth/*` → redirect to `/now`
  - [x] Add `/auth/sign-in` route (not inside `StatefulShellRoute`) as a top-level `GoRoute` pointing to `AuthScreen`
  - [x] Do NOT add the auth route inside the existing `StatefulShellRoute.indexedStack` — it must render without the shell (no tab bar, no sidebar)

- [x] Create `AuthScreen` — authentication UI (AC: 1, 4)
  - [x] Create `lib/features/auth/presentation/auth_screen.dart` — `ConsumerStatefulWidget`
  - [x] Layout: centred column; On Task wordmark (SF Pro, 28pt, `color.text.primary`); subtitle in New York serif (`color.text.secondary`) — "your past self is counting on you" or equivalent warm onboarding copy
  - [x] Sign in with Apple button — use `SignInWithApple.buildSignInWithAppleButton()` (the standard Apple-provided button — do NOT use a custom widget); this MUST be the topmost sign-in option (Apple HIG requirement)
  - [x] Sign in with Google button — `CupertinoButton` with Google logo asset + "Sign in with Google" label; `OnTaskColors.accentPrimary` is NOT used here — use standard Google branding (`#4285F4` text on white, or system default)
  - [x] Email/password section — `CupertinoTextField` for email, `CupertinoTextField` for password (obscureText: true); "Sign In" `CupertinoButton.filled`; "Forgot password?" text button below
  - [x] All button labels and field placeholders in `AppStrings` (do NOT hardcode strings inline)
  - [x] Error display: inline below the sign-in form, SF Pro 14pt, `color.schedule.risk` (warning tint); plain language only — never expose error codes (NFR-UX2); error is dismissed on next sign-in attempt
  - [x] Loading state: `CupertinoActivityIndicator` replaces the active sign-in button while a request is in flight; other sign-in options remain interactive
  - [x] No New York serif in error messages or button labels — New York is only for emotional/voice copy (UX spec constraint)

- [x] Add strings for auth screen to `AppStrings` (AC: 4)
  - [x] `lib/core/l10n/strings.dart` — add constants: `authSignInWithApple`, `authSignInWithGoogle`, `authEmailLabel`, `authPasswordLabel`, `authSignInButton`, `authForgotPassword`, `authErrorInvalidCredentials`, `authErrorGeneric`, `authSubtitle`
  - [x] `authErrorInvalidCredentials` = "That email or password isn't quite right. Try again or reset your password." (plain language, no codes)

- [x] Write unit tests for auth repository and token storage (AC: 1–5)
  - [x] `test/features/auth/auth_repository_test.dart`:
    - Mock `ApiClient` using `mocktail`; verify `signInWithEmail` posts to `/v1/auth/email` and stores tokens via `TokenStorage` on success
    - Verify `signInWithEmail` returns `AuthResult.error(message)` when server returns `{ error: { code: "INVALID_CREDENTIALS", ... } }`
    - Verify `signOut` clears tokens from `TokenStorage`
  - [x] `test/core/network/auth_interceptor_test.dart` (extend existing tests):
    - Verify `_tryRefreshToken()` calls `POST /v1/auth/refresh` and stores new tokens on success
    - Verify `_tryRefreshToken()` returns false when no refresh token is stored
    - Verify `_forceSignOut()` clears tokens AND invalidates `authStateProvider`
  - [x] `test/features/auth/auth_screen_test.dart`:
    - Pump `AuthScreen` → verify Sign in with Apple button is the topmost sign-in element (higher Y position than Google / email)
    - Verify error message appears below the form and contains no code words when `AuthResult.error()` is active
    - Verify `CupertinoActivityIndicator` is visible during loading state
  - [x] Run `flutter test` — all 15+ existing tests must continue passing (129 tests pass)

- [x] Run `build_runner` and commit generated files (ARCH-4)
  - [x] `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x] Commit `auth_result.freezed.dart`, `auth_repository.g.dart`, `auth_provider.g.dart`

## Dev Notes

### Critical Architecture Constraints

**Token storage — `flutter_secure_storage` REQUIRED, NOT `shared_preferences`:**
The AC explicitly requires tokens in the iOS Keychain. The architecture document lists `shared_preferences` as handling "auth token storage" — this is a documentation simplification. The Story 1.8 AC overrides it: tokens MUST use `flutter_secure_storage` (Keychain-backed on iOS, encrypted on macOS). `shared_preferences` stores data in `NSUserDefaults` on iOS which is NOT Keychain storage.

```dart
// lib/features/auth/data/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage();
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _accessTokenKey);
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
```

**Do NOT use `shared_preferences` for tokens.** It remains in use for non-sensitive settings (theme preference, etc.).

**`AuthInterceptor` already exists in Story 1.4 — do NOT recreate it:**
`apps/flutter/lib/core/network/interceptors/auth_interceptor.dart` already handles the 401 flow with `TODO(story-1.8)` placeholders. This story COMPLETES those TODOs:
- `_tryRefreshToken()`: replace the `return false` stub with a real call to `POST /v1/auth/refresh`
- `_forceSignOut()`: add Riverpod provider invalidation after token clear

The constants `kAccessToken`, `kRefreshToken`, `kRetryHeader` are defined in `auth_interceptor.dart`. Keep them for documentation but stop reading/writing via SharedPreferences.

**ApiClient injection — never singleton:**
```dart
// auth_repository.dart pattern
@riverpod
class AuthRepository extends _$AuthRepository {
  @override
  FutureOr<void> build() {}

  Future<AuthResult> signInWithEmail(String email, String password) async {
    final client = ref.read(apiClientProvider); // inject via ref, never new ApiClient()
    // ...
  }
}
```

**Auth route must be OUTSIDE `StatefulShellRoute`:**
The existing router has one `StatefulShellRoute.indexedStack` with 5 branches. The `/auth/sign-in` route must be a sibling of `StatefulShellRoute` at the top level of `routes:`, not nested inside it. Otherwise the tab bar / sidebar shell renders on top of the auth screen.

```dart
// app_router.dart structure:
GoRouter(
  initialLocation: '/now',
  redirect: (context, state) { /* auth gate */ },
  routes: [
    GoRoute(path: '/auth/sign-in', builder: (_, __) => const AuthScreen()),  // TOP LEVEL
    StatefulShellRoute.indexedStack(  // existing shell
      ...branches...
    ),
  ],
);
```

**Router redirect must watch auth state reactively:**
```dart
GoRouter(
  refreshListenable: authStateNotifier, // or use redirect with ref.watch
  redirect: (context, state) {
    final isAuthenticated = /* read auth state */;
    final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
    if (!isAuthenticated && !isOnAuthRoute) return '/auth/sign-in';
    if (isAuthenticated && isOnAuthRoute) return '/now';
    return null;
  },
  ...
)
```
Use a `ChangeNotifier` wrapper around the `authStateProvider` as the `refreshListenable` to trigger router re-evaluation when auth state changes.

**Sign in with Apple — Apple HIG compliance:**
- The `sign_in_with_apple` package provides `SignInWithApple.buildSignInWithAppleButton()` — use this standard button, not a custom widget
- Apple requires this button to be the TOPMOST sign-in option when Apple Sign In is offered — verified in AC #1
- The package handles the native ASAuthorizationController presentation automatically

**Sign in with Google — `google_sign_in` package:**
- `GoogleSignIn` requires configuration of `REVERSED_CLIENT_ID` in `Info.plist` (iOS) from Google Cloud Console credentials
- `GoogleSignInAccount.authentication` returns `GoogleSignInAuthentication` with `idToken` — post this to `POST /v1/auth/google`
- On macOS, Google Sign In uses a web-based flow; the `google_sign_in` package handles this transparently

**Hono auth routes — API side:**
- Each auth route in `apps/api/src/routes/auth.ts` MUST have a `@hono/zod-openapi` schema definition — no untyped routes (ARCH rule)
- Use Drizzle with `casing: 'camelCase'` — no manual field mapping
- JWT access token: 15-minute expiry. Refresh token: rotate on every use, invalidate previous immediately (NFR-S5)
- TLS 1.3 is enforced at Cloudflare edge — no app-level TLS configuration needed; add a code comment explaining this for future maintainers
- Error responses follow the envelope: `{ "error": { "code": "INVALID_CREDENTIALS", "message": "..." } }` — code is `SCREAMING_SNAKE_CASE`, never numeric

**macOS-specific note:**
- `flutter_secure_storage` uses the macOS Keychain on macOS — same API, different underlying store; no platform guard needed
- `sign_in_with_apple` works on macOS via `ASWebAuthenticationSession` — no separate implementation required
- The `AuthScreen` renders without the shell (no sidebar), which is correct for both iOS and macOS

### File Locations — Exact Paths

```
apps/
├── api/
│   └── src/
│       └── routes/
│           └── auth.ts              ← NEW: POST /v1/auth/apple|google|email|refresh
├── flutter/
│   ├── pubspec.yaml                 ← UPDATE: add sign_in_with_apple, google_sign_in, flutter_secure_storage
│   ├── ios/
│   │   └── Runner/
│   │       ├── Runner.entitlements  ← UPDATE: add com.apple.developer.applesignin
│   │       └── Info.plist           ← UPDATE: add Google CFBundleURLSchemes
│   └── lib/
│       ├── core/
│       │   ├── l10n/
│       │   │   └── strings.dart     ← UPDATE: add auth string constants
│       │   ├── network/
│       │   │   └── interceptors/
│       │   │       └── auth_interceptor.dart  ← UPDATE: complete TODO(story-1.8) stubs; switch to TokenStorage
│       │   └── router/
│       │       └── app_router.dart  ← UPDATE: add /auth/sign-in route + redirect guard
│       └── features/
│           └── auth/                ← NEW folder (FR48, FR82, FR87-88, FR91-92)
│               ├── data/
│               │   ├── auth_repository.dart        ← NEW
│               │   ├── auth_repository.g.dart       ← NEW (generated)
│               │   └── token_storage.dart           ← NEW
│               ├── domain/
│               │   ├── auth_result.dart             ← NEW (@freezed sealed)
│               │   └── auth_result.freezed.dart     ← NEW (generated)
│               └── presentation/
│                   ├── auth_provider.dart           ← NEW (AuthNotifier)
│                   ├── auth_provider.g.dart         ← NEW (generated)
│                   └── auth_screen.dart             ← NEW (AuthScreen widget)
└── test/
    ├── core/
    │   └── network/
    │       └── auth_interceptor_test.dart   ← UPDATE: extend existing tests
    └── features/
        └── auth/
            ├── auth_repository_test.dart    ← NEW
            └── auth_screen_test.dart        ← NEW
```

Note: `lib/features/auth/` does NOT exist yet — create the full folder structure.

### Dependency Versions (Latest Stable as of Q1 2026)

| Package | Version | Notes |
|---|---|---|
| `sign_in_with_apple` | `^6.1.2` | Wraps ASAuthorizationController; iOS + macOS |
| `google_sign_in` | `^6.2.2` | Web-based flow on macOS; Firebase-free |
| `flutter_secure_storage` | `^9.2.2` | iOS Keychain + macOS Keychain; no Android config needed for this project |

These packages are well-maintained and have no known breaking changes for Flutter 3.x / Dart 3.x. The `flutter_secure_storage` v9.x API is unchanged from v8.x for the methods used here.

### Access to Design Tokens

```dart
// In AuthScreen — access theme tokens:
final colors = Theme.of(context).extension<OnTaskColors>()!;
// Available: colors.accentPrimary, colors.surfacePrimary, colors.textPrimary, colors.textSecondary

// Text styles:
Theme.of(context).textTheme.bodyMedium   // SF Pro for all UI chrome
Theme.of(context).textTheme.displaySmall // New York serif for voice/emotional copy only
```

Do NOT hardcode any color hex values. Do NOT use New York serif for error messages, button labels, or field labels — only for emotional voice copy (UX spec constraint: "It must never appear in UI chrome, error messages, or any functional element").

### Pattern: `@riverpod` Notifier for Auth State

```dart
// lib/features/auth/presentation/auth_provider.dart
@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthResult build() {
    // Read stored token synchronously at init — if present, assume authenticated
    // (token validity checked by interceptor on first API call)
    return AuthResult.unauthenticated(); // override with async init if needed
  }

  void setAuthenticated(String userId) =>
      state = AuthResult.authenticated(userId: userId);

  void setUnauthenticated() => state = const AuthResult.unauthenticated();
}
```

`AuthInterceptor._forceSignOut()` must call `setUnauthenticated()` on this notifier. Since `AuthInterceptor` is created before Riverpod (in `ApiClient` constructor), inject the notifier's setter as a callback:

```dart
// Option: pass a callback into AuthInterceptor
class AuthInterceptor extends Interceptor {
  AuthInterceptor({Dio? dio, this.onSignOut}) : _dio = dio ?? Dio();
  final VoidCallback? onSignOut;
  // ...
  Future<void> _forceSignOut() async {
    await _tokenStorage.clearTokens();
    onSignOut?.call();
  }
}

// In ApiClient provider:
@riverpod
ApiClient apiClient(Ref ref) {
  final notifier = ref.read(authStateNotifierProvider.notifier);
  return ApiClient(
    baseUrl: AppConfig.apiUrl,
    onSignOut: notifier.setUnauthenticated,
  );
}
```

### Testing Pattern for Secure Storage

`flutter_secure_storage` requires platform channels and cannot be tested with the standard Flutter test runner without a mock. Use `FlutterSecureStorage`'s built-in `setMockInitialValues()` for unit tests:

```dart
// In test setUp:
FlutterSecureStorage.setMockInitialValues({});
```

This enables testing `TokenStorage` without needing a real Keychain.

### Previous Story Learnings (from Story 1.7)

- `dart:io` `Platform.isMacOS` / `Platform.isIOS` for runtime platform checks — NOT `defaultTargetPlatform` or `kIsWeb`
- `ConsumerStatefulWidget` / `ConsumerWidget` for all widgets that need Riverpod access
- `AppStrings` in `lib/core/l10n/strings.dart` — add all new strings here; never inline string literals in widgets
- `build_runner` is local-only; generated `*.g.dart` and `*.freezed.dart` files are committed to the repo
- Feature-first architecture: new feature = new folder under `lib/features/<feature>/` with `data/`, `domain/`, `presentation/` subfolders
- `AuthInterceptor` has `TODO(story-1.8)` markers in both `_tryRefreshToken()` and `_forceSignOut()` — these are the exact integration points for this story
- Test baseline after Story 1.7: 15+ test files; all must continue passing

### Project Structure Notes

- Feature-first architecture: `lib/features/auth/` is the correct location for all auth code (data sources, domain models, UI, providers)
- `auth_interceptor.dart` stays in `lib/core/network/interceptors/` — it is a cross-cutting infrastructure concern, not a feature
- `TokenStorage` belongs in `lib/features/auth/data/` because it is auth-specific; it is not a generic storage utility
- Snake_case filenames, PascalCase class names — consistent with existing codebase

### References

- Story 1.4 AC for auth interceptor: [Source: _bmad-output/planning-artifacts/epics.md — Story 1.4, line ~568]
- Auth feature folder: [Source: _bmad-output/planning-artifacts/architecture.md — Flutter directory tree, line ~858]
- Auth pattern (JWT, 15min, refresh rotation): [Source: _bmad-output/planning-artifacts/architecture.md — Auth Pattern section, line ~563]
- 401 interceptor flow: [Source: _bmad-output/planning-artifacts/architecture.md — line ~576]
- NFR-S1 (TLS 1.3): [Source: _bmad-output/planning-artifacts/architecture.md — line ~40]
- NFR-UX2 (plain-language errors): [Source: epics.md — Story 1.8 AC, error message criteria]
- NFR-S5 (refresh token rotation): [Source: epics.md — Story 1.8 AC, token storage criteria]
- Flutter package stack: [Source: architecture.md — Package stack table, line ~102]
- UX serif constraint: [Source: _bmad-output/planning-artifacts/ux-design-specification.md — line ~1475, "Everything else is SF Pro"]
- Token storage in Keychain: [Source: epics.md — Story 1.8 AC #2]
- Existing `auth_interceptor.dart`: `apps/flutter/lib/core/network/interceptors/auth_interceptor.dart`
- Existing `api_client.dart`: `apps/flutter/lib/core/network/api_client.dart`
- Strings: `apps/flutter/lib/core/l10n/strings.dart`
- Theme tokens: `apps/flutter/lib/core/theme/app_colors.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Generated provider name is `authStateProvider` (not `authStateNotifierProvider`) — always check .g.dart for actual provider names after build_runner
- `api_client_test.dart` and `widget_test.dart` needed `TestWidgetsFlutterBinding.ensureInitialized()` because `AuthStateNotifier.build()` calls `TokenStorage` (platform channel) at init
- Existing `auth_interceptor_test.dart` used `SharedPreferences.setMockInitialValues` — updated to use `FlutterSecureStorage.setMockInitialValues` after interceptor was migrated to TokenStorage
- `widget_test.dart` needed auth state override (`authStateProvider.overrideWithValue(authenticated)`) since auth gate redirects to `/auth/sign-in` when unauthenticated

### Completion Notes List

- All 10 story tasks completed and tested
- 129 tests pass (0 failures) — includes 14 new auth tests + 2 updated widget tests + expanded interceptor tests
- `AuthInterceptor` fully migrated from `SharedPreferences` to `TokenStorage` (Keychain-backed); both `TODO(story-1.8)` stubs implemented
- Auth gate wired into GoRouter via `refreshListenable` (`_AuthRefreshListenable` ChangeNotifier); redirects reactive to auth state changes
- `AuthScreen` layout: Apple → Google → email/password (Apple HIG order enforced and widget-tested)
- All auth strings in `AppStrings` — no inline literals in UI
- API auth route stubs (`auth.ts`) use `@hono/zod-openapi` schemas with full OpenAPI documentation; `TODO(impl)` markers indicate where real server-side logic goes
- Info.plist `CFBundleURLSchemes` placeholder added for Google Sign In (requires real reversed client ID from Google Cloud Console)
- `flutter_secure_storage` v9.2.4 resolved (slightly above `^9.2.2` floor — compatible)

### File List

apps/api/src/index.ts
apps/api/src/routes/auth.ts
apps/flutter/ios/Runner/Info.plist
apps/flutter/ios/Runner/Runner.entitlements
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/lib/core/network/api_client.dart
apps/flutter/lib/core/network/api_client.g.dart
apps/flutter/lib/core/network/interceptors/auth_interceptor.dart
apps/flutter/lib/core/router/app_router.dart
apps/flutter/lib/core/router/app_router.g.dart
apps/flutter/lib/features/auth/data/auth_repository.dart
apps/flutter/lib/features/auth/data/auth_repository.g.dart
apps/flutter/lib/features/auth/data/token_storage.dart
apps/flutter/lib/features/auth/domain/auth_result.dart
apps/flutter/lib/features/auth/domain/auth_result.freezed.dart
apps/flutter/lib/features/auth/presentation/auth_provider.dart
apps/flutter/lib/features/auth/presentation/auth_provider.g.dart
apps/flutter/lib/features/auth/presentation/auth_screen.dart
apps/flutter/macos/Flutter/GeneratedPluginRegistrant.swift
apps/flutter/pubspec.lock
apps/flutter/pubspec.yaml
apps/flutter/test/core/network/api_client_test.dart
apps/flutter/test/core/network/auth_interceptor_test.dart
apps/flutter/test/features/auth/auth_repository_test.dart
apps/flutter/test/features/auth/auth_screen_test.dart
apps/flutter/test/widget_test.dart

## Change Log

- 2026-03-30: Story 1.8 implemented — User Authentication complete. Added Sign in with Apple, Sign in with Google, and email/password auth flows. Created TokenStorage (Keychain), AuthRepository, AuthStateNotifier, AuthScreen, and auth gate router. Completed AuthInterceptor TODO stubs (token refresh + sign-out). All 129 tests pass.
