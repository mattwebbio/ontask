# Story 1.4: Flutter Architecture Foundation

Status: review

## Story

As a developer,
I want a feature-first clean architecture scaffold with Riverpod, go_router, drift, and freezed configured,
So that all feature development follows consistent patterns across data, domain, and presentation layers.

## Acceptance Criteria

1. **Given** the Flutter project exists, **When** the architecture scaffold is complete, **Then** `lib/features/` contains an example feature folder with `data/`, `domain/`, and `presentation/` subdirectories and documented conventions
2. `flutter_riverpod` and `riverpod_annotation` are installed; all async providers return `AsyncValue<T>` — never raw `Future<T>`
3. `go_router` is installed and a root `AppRouter` provider is configured
4. `drift` is installed for local SQLite storage with a `PendingOperations` table defined per architecture spec
5. `freezed` and `json_serializable` are installed; generated `*.g.dart` and `*.freezed.dart` files are committed to the repo; `build_runner` is documented as local-only — never runs in CI
6. **Given** the API client pattern is established, **When** any feature makes an API call, **Then** it uses a shared `ApiClient` class injected via a Riverpod provider — never instantiated directly as a singleton
7. A global 401 interceptor in `ApiClient` silently refreshes the token and retries the request once; on a second consecutive 401 it forces a full sign-out
8. **Given** a domain model is created, **When** it uses a union or sealed type, **Then** `freezed` union types (sealed classes) live only in `domain/` — never in `data/`

## Tasks / Subtasks

- [x] Add all required pub dependencies to `pubspec.yaml` (AC: 2, 3, 4, 5)
  - [x] Add `flutter_riverpod: ^3.3.0` to dependencies
  - [x] Add `riverpod_annotation: ^4.0.0` to dependencies (updated from ^2.6.1 — v4 is compatible with flutter_riverpod ^3.3.0)
  - [x] Add `go_router: ^15.1.2` to dependencies
  - [x] Add `dio: ^5.7.0` to dependencies
  - [x] Add `drift: ^2.22.1` to dependencies
  - [x] Add `sqlite3_flutter_libs: ^0.5.28` to dependencies (native SQLite for iOS/macOS)
  - [x] Add `path_provider: ^2.1.4` to dependencies (database file path)
  - [x] Add `path: ^1.9.1` to dependencies
  - [x] Add `freezed_annotation: ^3.0.0` to dependencies (updated from ^2.4.4 — v3 compatible with riverpod_generator v4)
  - [x] Add `json_annotation: ^4.9.0` to dependencies
  - [x] Add `shared_preferences: ^2.3.3` to dependencies
  - [x] Add `mocktail: ^1.0.4` to dev_dependencies
  - [x] Add `build_runner: ^2.4.13` to dev_dependencies
  - [x] Add `riverpod_generator: ^4.0.0` to dev_dependencies (updated from ^2.6.2 — v4 matches riverpod_annotation v4)
  - [x] Add `drift_dev: ^2.22.1` to dev_dependencies
  - [x] Add `freezed: ^3.0.0` to dev_dependencies (updated from ^2.5.7 — v3 compatible)
  - [x] Add `json_serializable: ^6.8.0` to dev_dependencies
  - [x] Run `flutter pub get` to verify no conflicts

- [x] Set up core directory structure (AC: 1)
  - [x] Create `lib/core/config/app_config.dart` — env-based API URL, feature flags
  - [x] Create `lib/core/network/api_client.dart` — dio wrapper, `@riverpod ApiClient apiClient(...)` provider
  - [x] Create `lib/core/network/interceptors/auth_interceptor.dart` — 401 silent refresh → retry → logout (AC: 7)
  - [x] Create `lib/core/network/interceptors/logging_interceptor.dart` — dev-only request/response logging
  - [x] Create `lib/core/storage/database.dart` — drift `AppDatabase` instance with `@riverpod` provider
  - [x] Create `lib/core/storage/pending_operations.dart` — `PendingOperations` drift table definition (offline queue schema)
  - [x] Create `lib/core/router/app_router.dart` — `@riverpod AppRouter appRouter(...)` go_router provider
  - [x] Create `lib/core/utils/.gitkeep` — placeholder

- [x] Create example feature scaffold with full anatomy (AC: 1)
  - [x] Create `lib/features/example/data/example_repository.dart` — implements `IExampleRepository`
  - [x] Create `lib/features/example/data/example_dto.dart` — API ↔ domain mapping with `json_serializable`
  - [x] Create `lib/features/example/domain/example.dart` — domain model with `freezed`
  - [x] Create `lib/features/example/domain/example_state.dart` — freezed union/sealed type (domain-only per ARCH rule)
  - [x] Create `lib/features/example/domain/i_example_repository.dart` — repository interface
  - [x] Create `lib/features/example/presentation/example_screen.dart` — screen widget
  - [x] Create `lib/features/example/presentation/example_provider.dart` — Riverpod provider returning `AsyncValue<T>`
  - [x] Create `lib/features/example/presentation/widgets/example_card.dart` — example widget

- [x] Run build_runner locally and commit generated files (AC: 5)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x] Verify `*.g.dart` and `*.freezed.dart` files are generated (no `.gitignore` entries blocking them)
  - [x] Confirm `.gitignore` at monorepo root does NOT ignore `*.g.dart` or `*.freezed.dart`
  - [x] Commit all generated files to the repo

- [x] Wire up `main.dart` with ProviderScope and go_router (AC: 2, 3)
  - [x] Wrap `runApp()` with `ProviderScope`
  - [x] Replace `MaterialApp` with `MaterialApp.router` using `appRouter.config()`
  - [x] Remove the demo counter scaffold entirely

- [x] Write tests for the API client interceptor and example provider (AC: 2, 6, 7)
  - [x] Create `test/core/network/api_client_test.dart` — verify `ApiClient` is Riverpod-injected, never singleton
  - [x] Create `test/core/network/auth_interceptor_test.dart` — 401 silent refresh test; 401 on retry → logout test
  - [x] Create `test/features/example/example_provider_test.dart` — provider test using `ProviderContainer` + `mocktail`
  - [x] Run `flutter test` from `apps/flutter/` — all tests must pass (14/14 passed)

- [x] Document build_runner as local-only (AC: 5)
  - [x] Add a comment block in `apps/flutter/README.md` documenting that `build_runner` runs locally only — CI does NOT run it; generated files are committed to the repo
  - [x] Verify `ci.yml` `flutter-tests` job does NOT call `build_runner` (confirmed; added `flutter pub get` step)

## Dev Notes

### Package Versions — Use Exact Versions Listed

The architecture doc specifies `flutter_riverpod ^3.3.0`. Use the versions listed in the Tasks above (sourced from latest stable as of March 2026). If `flutter pub get` reports incompatibilities, resolve using the published versions on pub.dev rather than downgrading. Do NOT pin to exact versions (`==`) — use `^` (compatible semver).

**Riverpod 3.x note:** Riverpod 3 introduced compile-time provider safety via `riverpod_annotation` + `build_runner`. Always use the `@riverpod` annotation pattern for code-generated providers — do NOT use the legacy `Provider(...)` constructor pattern for new providers.

### `pubspec.yaml` Current State

The Flutter project at `apps/flutter/` is a vanilla `flutter create` scaffold with only `cupertino_icons` and `flutter_lints`. `lib/main.dart` contains the demo counter app. Replace/refactor both — do NOT keep the demo counter widget.

### Feature-First Clean Architecture — Exact Anatomy

Every feature follows this exact structure (no deviations):

```
lib/features/{feature}/
├── data/
│   ├── {feature}_repository.dart     # implements domain interface
│   └── {feature}_dto.dart            # API ↔ domain mapping (json_serializable)
├── domain/
│   ├── {feature}.dart                # domain model (freezed data class)
│   ├── {feature}_state.dart          # freezed union/sealed types — domain concepts ONLY
│   └── i_{feature}_repository.dart  # interface (abstract class)
└── presentation/
    ├── {feature}_screen.dart
    ├── {feature}_provider.dart       # Riverpod @riverpod provider
    └── widgets/
```

**ARCH RULE (ARCH-19): `freezed` union types (sealed classes) live ONLY in `domain/` — never in `data/`.**
DTOs in `data/` use plain `freezed` data classes for immutability, not union/sealed types.

### Riverpod Provider Pattern — MANDATORY

**ARCH RULE (ARCH-17): All async providers return `AsyncValue<T>` — never raw `Future<T>`.**

Correct pattern:
```dart
// lib/features/example/presentation/example_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/example.dart';
import '../domain/i_example_repository.dart';

part 'example_provider.g.dart';

@riverpod
Future<List<Example>> examples(ExamplesRef ref) async {
  // build_runner generates ExamplesRef from the class name
  final repository = ref.watch(exampleRepositoryProvider);
  return repository.fetchAll();
}
```

Riverpod wraps the returned `Future<T>` into `AsyncValue<T>` automatically — the widget accesses it via `ref.watch(examplesProvider)` which returns `AsyncValue<List<Example>>`.

**Provider naming convention:**
- `{entity}Provider` — for single-entity providers (e.g., `tasksProvider`, `taskDetailProvider`)
- `{entity}NotifierProvider` — for stateful notifiers

### ApiClient — Riverpod Injection (NEVER Singleton)

**ARCH RULE:** `ApiClient` is injected via Riverpod, never instantiated as a singleton. This is critical for testability — singleton breaks `ProviderContainer` overrides in tests.

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import '../config/app_config.dart';

part 'api_client.g.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

@riverpod
ApiClient apiClient(ApiClientRef ref) => ApiClient(baseUrl: AppConfig.apiUrl);
```

Every repository receives `ApiClient` via `ref.watch(apiClientProvider)` — never `ApiClient()` directly.

### 401 Interceptor — Exact Flow (ARCH-20)

**ARCH RULE (ARCH-20):** 401 interceptor behavior: silent token refresh → retry once → force logout on second consecutive 401.

```dart
// lib/core/network/interceptors/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt silent token refresh
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry original request once with new token
        final retryResponse = await _retryRequest(err.requestOptions);
        if (retryResponse.statusCode == 401) {
          // Second consecutive 401 — force sign-out
          _forceSignOut();
          return handler.reject(err);
        }
        return handler.resolve(retryResponse);
      }
      // Refresh failed — force sign-out
      _forceSignOut();
    }
    handler.next(err);
  }
}
```

The user NEVER sees a 401 error directly — all 401s are either silently recovered or converted to a sign-out navigation action.

### Drift Setup — AppDatabase and PendingOperations

**Architecture-defined offline queue table** — implement exactly this schema:

```dart
// lib/core/storage/pending_operations.dart
import 'package:drift/drift.dart';

class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'COMPLETE_TASK', 'SUBMIT_PROOF', etc.
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get clientTimestamp => dateTime()();
  // clientTimestamp = set at operation CREATION, NEVER at sync time
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // status: 'pending' | 'failed'
}
```

**CRITICAL:** `clientTimestamp` is always set at operation creation time — never updated when sync happens. This is a non-negotiable constraint for commitment contract timestamp integrity (FR94).

```dart
// lib/core/storage/database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'pending_operations.dart';

part 'database.g.dart';

@DriftDatabase(tables: [PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ontask.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
```

Note: `AppDatabase` provider uses `keepAlive: true` — the database must not be closed/recreated during the app lifecycle.

### go_router AppRouter Setup

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Placeholder(), // replaced in Story 1.6
      ),
    ],
  );
}
```

In `main.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: OnTaskApp()));
}

class OnTaskApp extends ConsumerWidget {
  const OnTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(routerConfig: router);
  }
}
```

### AppConfig — Environment-Based API URL

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.ontaskhq.com/v1',
  );
}
```

The `--dart-define=API_URL=https://api.staging.ontaskhq.com/v1` flag overrides for staging builds.

### Generated Files — MUST Be Committed (ARCH-4)

**ARCH RULE (ARCH-4): Generated files (`*.g.dart`, `*.freezed.dart`) MUST be committed to the repo. `build_runner` is a local-only dev command — it does NOT run in CI.**

Verify:
1. Root `.gitignore` does NOT contain `*.g.dart` or `*.freezed.dart` entries
2. `apps/flutter/.gitignore` (if it exists) does NOT ignore generated files
3. The CI `flutter-tests` job in `.github/workflows/ci.yml` does NOT call `build_runner`

After generating files locally, commit them as part of this story's PR. All generated files are normal source code as far as the repo is concerned.

**local build_runner command (run from `apps/flutter/` directory):**
```bash
dart run build_runner build --delete-conflicting-outputs
```

If you add new annotated files later, run the same command again. Do NOT use `watch` mode in CI or automated contexts.

### Dart Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `task_card.dart`, `tasks_provider.dart` |
| Classes | `PascalCase` | `TaskCard`, `TasksNotifier` |
| Variables/functions | `camelCase` | `fetchTasks()`, `taskId` |
| Riverpod providers | `{entity}Provider` | `tasksProvider`, `taskDetailProvider` |
| Drift table classes | `{Entity}Table` | `TasksTable` — but `PendingOperations` is the architecture-defined name |

### Testing Pattern — ProviderContainer (Not WidgetTester)

Provider business logic is always tested with `ProviderContainer` + `mocktail`, not `WidgetTester` alone:

```dart
// test/features/example/example_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  test('examples provider loads correctly', () async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(examplesProvider.future);
    expect(result, isA<List<Example>>());
  });
}
```

### Project Structure Notes

**Flutter project location:** `apps/flutter/` in the monorepo root.

**Current state of `apps/flutter/`:**
- `lib/main.dart` — vanilla counter demo (replace entirely)
- `pubspec.yaml` — only `cupertino_icons` + `flutter_lints` (add all required deps)
- `test/widget_test.dart` — counter widget test (remove or replace)
- No `lib/core/`, `lib/features/` directories exist yet

**Generated files location:** The architecture doc shows `lib/generated/` as a dedicated folder for build_runner output. In practice, Riverpod generator and drift_dev generate files alongside the source files (e.g., `example_provider.g.dart` next to `example_provider.dart`). The `lib/generated/` folder reference in the architecture is a notation for the concept — actual generated files co-locate with source files. Do NOT create a separate `lib/generated/` folder.

**CI flutter-tests job context** (from Story 1.2):
```yaml
flutter-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.41.0'
        channel: 'stable'
    - run: flutter test
      working-directory: apps/flutter
```
This job runs `flutter test` directly — it does NOT run `flutter pub get` first when using `subosito/flutter-action`. If it starts failing after this story's deps are added, add a `flutter pub get` step before `flutter test`.

**macOS target:** Flutter project targets iOS and macOS (`--platforms=ios,macos`). Drift and sqlite3_flutter_libs both support macOS. No macOS-specific drift config needed beyond the standard setup.

**Live Activities guard (future stories):** Any use of `live_activities` plugin (not in this story) must be guarded with `if (Platform.isIOS)`. macOS does not support Live Activities. This is not relevant for Story 1.4 but be aware of it when the example feature scaffold is referenced in later stories.

### Scope Boundaries — What Is NOT In This Story

| Item | Belongs To |
|---|---|
| Auth screen, sign-in flow | Story 1.8 |
| Theme / colour system | Story 1.5 |
| Tab bar navigation shell (Cupertino) | Story 1.6 |
| macOS three-pane layout | Story 1.7 |
| Actual API endpoints / data | Story 1.8+ |
| PostHog analytics initialization | Story 1.12 |
| GlitchTip / Sentry error tracking | Story 1.12 |
| Live Activities (live_activities plugin) | Story 12.1 |
| Patrol E2E tests | Deferred — add when E2E stories exist |
| iOS Keychain token storage | Story 1.8 (use `shared_preferences` placeholder for now) |
| Real `AppConfig.apiUrl` production/staging wiring | After auth and real endpoints exist |

### Previous Story Intelligence

**From Story 1.2 (CI/CD):**
- Flutter CI uses `subosito/flutter-action@v2` with `flutter-version: '3.41.0'` and `channel: 'stable'`
- `flutter test` runs in `apps/flutter/` working directory
- Generated files are committed to repo — CI does NOT run `build_runner`

**From Story 1.3 (API Foundation):**
- `@ontask/core` is the shared TypeScript types package — not relevant to Flutter directly but confirms the API contract types exist in `packages/core/src/types/api.ts` (`DataResponse<T>`, `ListResponse<T>`, `ErrorResponse`)
- The API response envelope shapes the Flutter DTO parsing: `{ "data": { ... } }` for single objects, `{ "data": [...], "pagination": { "cursor": "...", "hasMore": true } }` for lists
- API URL base: `https://api.ontaskhq.com/v1` (production), `https://api.staging.ontaskhq.com/v1` (staging)
- All API field names are `camelCase` (Drizzle `casing: 'camelCase'` handles the DB transform) — Dart DTOs can deserialize directly from JSON without aliasing

**From Story 1.1 (Monorepo):**
- Flutter bundle ID: `com.ontaskhq.ontask`
- Flutter project initialized with `--platforms=ios,macos`
- Dart package name (pubspec `name`): `ontask`

### References

- [Source: architecture.md — Flutter Client] — package stack with versions, project structure, `flutter create` initialization
- [Source: architecture.md — Project Structure — `apps/flutter/`] — full directory tree, core/ layout, feature anatomy
- [Source: architecture.md — Implementation Patterns — Flutter/Dart] — naming conventions
- [Source: architecture.md — Auth Pattern] — `ApiClient` Riverpod injection, 401 interceptor flow
- [Source: architecture.md — Flutter Offline Queue] — `PendingOperations` table schema
- [Source: architecture.md — Enforcement] — ARCH rules: AsyncValue<T>, freezed in domain/, ApiClient injection
- [Source: architecture.md — CI/CD] — generated files committed to repo, build_runner local-only
- [Source: architecture.md — Error Handling — Flutter] — AsyncValue<T> rule, user-facing error strings in l10n
- [Source: epics.md — Story 1.4] — acceptance criteria
- [Source: 1-2-cicd-pipeline-staging-environments.md — Dev Notes] — flutter-tests CI job, flutter-version 3.41.0
- [Source: 1-3-api-foundation-database-response-standards.md — Dev Notes] — API response envelope shapes, camelCase JSON

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- riverpod_generator v4 changed the `*Ref` type names — provider functions now use plain `Ref` from `package:riverpod/riverpod.dart` instead of the generated `ApiClientRef`, `ExamplesRef`, etc. All provider function signatures updated accordingly.
- `Interceptor.onError` signature is `void`, not `Future<void>`. The async 401 logic was moved to a private `_handleError` method (called from `onError`) and a public `handleError` method exposed for direct test assertions.
- `riverpod_annotation ^2.6.1` is incompatible with `flutter_riverpod ^3.3.0` (requires riverpod 2.x vs 3.x). Updated to `riverpod_annotation: ^4.0.0` and `riverpod_generator: ^4.0.0`. Also updated `freezed_annotation` to `^3.0.0` and `freezed` to `^3.0.0` (required by riverpod_generator v4's dependency on build ^4.x).

### Completion Notes List

- All 14 flutter tests pass (`flutter test` from `apps/flutter/`).
- pubspec.yaml updated with all required dependencies; exact versions resolved from pub.dev for March 2026 compatibility.
- Core directory structure created: `lib/core/config/`, `lib/core/network/`, `lib/core/storage/`, `lib/core/router/`, `lib/core/utils/`.
- Example feature scaffold demonstrates full feature anatomy: data (DTO + repository), domain (model + sealed state + interface), presentation (screen + provider + widget).
- ARCH rules enforced: freezed union types in domain/ only (ARCH-19), all async providers return AsyncValue<T> via Riverpod wrapping (ARCH-17), ApiClient injected via Riverpod never singleton (ARCH-20), 401 interceptor: silent refresh → retry once → force logout on second 401.
- Generated files (`*.g.dart`, `*.freezed.dart`) committed to repo. CI flutter-tests job does NOT call build_runner; `flutter pub get` step added to CI before `flutter test`.
- `main.dart` replaced: demo counter removed, `ProviderScope` wraps `OnTaskApp`, `MaterialApp.router` uses go_router.
- `apps/flutter/README.md` updated with build_runner local-only documentation.

### File List

- `apps/flutter/pubspec.yaml` — updated with all required dependencies
- `apps/flutter/pubspec.lock` — dependency lock file
- `apps/flutter/README.md` — updated with build_runner documentation
- `apps/flutter/lib/main.dart` — replaced demo counter with ProviderScope + MaterialApp.router
- `apps/flutter/lib/core/config/app_config.dart` — env-based API URL
- `apps/flutter/lib/core/network/api_client.dart` — Dio wrapper + Riverpod provider
- `apps/flutter/lib/core/network/api_client.g.dart` — generated
- `apps/flutter/lib/core/network/interceptors/auth_interceptor.dart` — 401 silent refresh → retry → logout
- `apps/flutter/lib/core/network/interceptors/logging_interceptor.dart` — dev-only logging
- `apps/flutter/lib/core/storage/database.dart` — drift AppDatabase + Riverpod provider
- `apps/flutter/lib/core/storage/database.g.dart` — generated
- `apps/flutter/lib/core/storage/pending_operations.dart` — PendingOperations drift table
- `apps/flutter/lib/core/router/app_router.dart` — go_router GoRouter + Riverpod provider
- `apps/flutter/lib/core/router/app_router.g.dart` — generated
- `apps/flutter/lib/core/utils/.gitkeep` — placeholder
- `apps/flutter/lib/features/example/data/example_dto.dart` — API DTO with json_serializable
- `apps/flutter/lib/features/example/data/example_dto.freezed.dart` — generated
- `apps/flutter/lib/features/example/data/example_dto.g.dart` — generated
- `apps/flutter/lib/features/example/data/example_repository.dart` — implements IExampleRepository
- `apps/flutter/lib/features/example/data/example_repository.g.dart` — generated
- `apps/flutter/lib/features/example/domain/example.dart` — freezed domain model
- `apps/flutter/lib/features/example/domain/example.freezed.dart` — generated
- `apps/flutter/lib/features/example/domain/example_state.dart` — freezed sealed union (domain-only)
- `apps/flutter/lib/features/example/domain/example_state.freezed.dart` — generated
- `apps/flutter/lib/features/example/domain/i_example_repository.dart` — repository interface
- `apps/flutter/lib/features/example/presentation/example_provider.dart` — Riverpod async provider
- `apps/flutter/lib/features/example/presentation/example_provider.g.dart` — generated
- `apps/flutter/lib/features/example/presentation/example_screen.dart` — ConsumerWidget screen
- `apps/flutter/lib/features/example/presentation/widgets/example_card.dart` — example widget
- `apps/flutter/test/widget_test.dart` — updated smoke test (replaced counter test)
- `apps/flutter/test/core/network/api_client_test.dart` — ApiClient Riverpod injection tests
- `apps/flutter/test/core/network/auth_interceptor_test.dart` — 401 interceptor tests
- `apps/flutter/test/features/example/example_provider_test.dart` — provider + AsyncValue tests
- `.github/workflows/ci.yml` — added `flutter pub get` step before `flutter test`

### Change Log

- 2026-03-30: Implemented Story 1.4 Flutter Architecture Foundation. Set up feature-first clean architecture scaffold with Riverpod 3.x + riverpod_generator v4, go_router, drift, freezed v3, and json_serializable. Created example feature demonstrating full anatomy. Wired main.dart with ProviderScope + MaterialApp.router. Generated all *.g.dart and *.freezed.dart files and committed them. All 14 tests pass.
