# OnTask — Flutter App

Feature-first clean architecture for iOS and macOS built with Flutter 3.41.

## Getting started

```bash
flutter pub get
flutter run
```

## Running tests

```bash
flutter test
```

## Architecture

The app follows feature-first clean architecture with three layers per feature:

```
lib/features/{feature}/
├── data/          # API DTOs, repository implementations
├── domain/        # Models (freezed), repository interfaces, sealed state types
└── presentation/  # Screens, Riverpod providers, widgets
```

### Key patterns

- **State management** — `flutter_riverpod` + `riverpod_annotation` (code-gen providers via `@riverpod`)
- **Navigation** — `go_router` via `appRouterProvider`
- **Local storage** — `drift` (SQLite) with `AppDatabase` provider (`keepAlive: true`)
- **Networking** — `ApiClient` injected via `apiClientProvider` — never instantiated as a singleton
- **Domain models** — `freezed` data classes; sealed/union types live in `domain/` only (ARCH-19)
- **Async providers** — always return `AsyncValue<T>`, never raw `Future<T>` (ARCH-17)

### 401 interceptor (ARCH-20)

`AuthInterceptor` silently refreshes the token and retries the request once.
On a second consecutive 401 it forces a full sign-out. Users never see a raw 401.

### Overriding the API URL

```bash
flutter run --dart-define=API_URL=https://api.staging.ontaskhq.com/v1
```

---

## Code generation — build_runner

**build_runner is a LOCAL-ONLY developer tool. It does NOT run in CI.**

Generated files (`*.g.dart`, `*.freezed.dart`) are committed to the repo so
that `flutter test` in CI works without needing `build_runner`.

When you add or change an `@riverpod` provider, `@freezed` model, `@DriftDatabase`,
or `@JsonSerializable` class, re-run:

```bash
# Run from apps/flutter/
dart run build_runner build --delete-conflicting-outputs
```

Then commit the updated generated files alongside your source changes.

Do NOT use `build_runner watch` in CI or automated contexts.
