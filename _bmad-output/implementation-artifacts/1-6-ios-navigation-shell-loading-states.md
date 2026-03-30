# Story 1.6: iOS Navigation Shell & Loading States

Status: done

## Story

As an iOS user,
I want a four-tab navigation shell with skeleton loading and context-aware empty states,
So that the app structure is immediately familiar and loading never shows a blank screen.

## Acceptance Criteria

1. **Given** the app launches on iOS, **When** the main shell renders, **Then** a Cupertino tab bar displays four tabs in order: Now, Today, Add, Lists — and tapping the Add tab opens the task capture UI (modal/sheet), not a persistent content screen
2. **Given** any tab is selected, **When** the tab bar renders, **Then** the selected tab item uses `OnTaskColors.accentPrimary` for its icon/label colour — not the default iOS blue
3. **Given** the Today tab is loading with no cached data, **When** data has not resolved within the first render frame, **Then** 3–4 skeleton task rows display with a shimmer sweep animation (1.2s loop, left-to-right gradient, `color.surface.secondary` fill at 40% opacity)
4. **Given** the Now tab is loading, **When** data has not resolved, **Then** the card area shows a skeleton matching approximate Now tab card proportions with the same shimmer animation
5. **Given** data resolves, **When** real content replaces skeletons, **Then** there is no flash of an empty state — real content renders directly (NFR-P1: cold launch ≤ 2s)
6. **Given** skeleton is displayed, **When** 800ms passes without real content, **Then** real content or an error state appears — skeletons never persist beyond 800ms
7. **Given** the Now tab has no current task, **When** the empty state renders, **Then** it shows unique copy in the warm narrative voice (New York serif, centred, `color.text.secondary`) with optional next-scheduled-task hint — no generic placeholder
8. **Given** the Today tab has no tasks scheduled, **When** the empty state renders, **Then** it shows a distinct nudge ("Nothing scheduled. Add something?") with a single CTA to the Add tab — in SF Pro 17pt, not celebratory
9. **Given** the Lists tab has no lists created, **When** the empty state renders, **Then** it shows a warm invitation to create the first list, distinct from both Now and Today empty states

## Tasks / Subtasks

- [x]Add `shimmer` package to `pubspec.yaml` (AC: 3, 4)
  - [x]Add `shimmer: ^3.0.0` to `dependencies` in `apps/flutter/pubspec.yaml`
  - [x]Run `flutter pub get` locally to verify resolution

- [x]Create shell feature scaffold (AC: 1, 2)
  - [x]Create `lib/features/shell/` with `presentation/` subfolder
  - [x]Create `lib/features/shell/presentation/app_shell.dart` — `CupertinoTabScaffold` with four tabs
  - [x]Create `lib/features/shell/presentation/add_tab_sheet.dart` — modal bottom sheet / full-height sheet opened when Add tab is tapped

- [x]Create placeholder tab screens (AC: 1)
  - [x]Create `lib/features/now/presentation/now_screen.dart` — empty scaffold placeholder (real content in future stories)
  - [x]Create `lib/features/today/presentation/today_screen.dart` — empty scaffold placeholder
  - [x]Create `lib/features/lists/presentation/lists_screen.dart` — empty scaffold placeholder

- [x]Implement skeleton loading widgets (AC: 3, 4, 5, 6)
  - [x]Create `lib/features/today/presentation/widgets/today_skeleton.dart` — 3–4 skeleton rows using `shimmer` package, `RepaintBoundary` wrapped, 1.2s shimmer loop
  - [x]Create `lib/features/now/presentation/widgets/now_card_skeleton.dart` — card-proportioned skeleton for the Now tab hero area
  - [x]Both skeletons use `OnTaskColors.surfaceSecondary` as base fill colour (accessed via `Theme.of(context).extension<OnTaskColors>()!`)

- [x]Implement context-aware empty states (AC: 7, 8, 9)
  - [x]Create `lib/features/now/presentation/widgets/now_empty_state.dart` — New York serif centred copy, `color.text.secondary`, optional next-task hint; no illustration
  - [x]Create `lib/features/today/presentation/widgets/today_empty_state.dart` — SF Pro 17pt, nudge copy, single "Add something" CTA that triggers Add sheet
  - [x]Create `lib/features/lists/presentation/widgets/lists_empty_state.dart` — warm invitation copy distinct from Now/Today

- [x]Wire tab shell into go_router (AC: 1)
  - [x]Update `lib/core/router/app_router.dart` — replace placeholder `GoRoute` at `'/'` with `ShellRoute` (or `StatefulShellRoute`) wrapping the tab navigator
  - [x]Confirm `main.dart` requires no changes — `MaterialApp.router` already set; shell replaces the placeholder route only

- [x]Externalize empty state copy to l10n (AC: 7, 8, 9)
  - [x]Create `lib/l10n/` directory and `app_en.arb` file if not existing
  - [x]Add keys: `nowEmptyTitle`, `nowEmptySubtitle`, `todayEmptyTitle`, `todayEmptyAddCta`, `listsEmptyTitle`, `listsEmptySubtitle`
  - [x]If Flutter gen-l10n is not configured this story, store copy as `const String` constants in a `lib/core/l10n/strings.dart` file — do not hardcode inline in widget trees

- [x]Implement reduced-motion support (AC: 3, 4)
  - [x]Check `MediaQuery.of(context).disableAnimations` in skeleton widgets — if true, render static fill with no shimmer animation

- [x]Write widget tests (AC: 1–9)
  - [x]`test/features/shell/app_shell_test.dart` — pump `AppShell`, verify four tabs rendered; verify Add tab tap calls sheet open callback (not navigation); verify tab labels: Now, Today, Add, Lists
  - [x]`test/features/today/today_skeleton_test.dart` — verify `TodaySkeleton` renders 3–4 `Container` children with correct colours; verify `RepaintBoundary` is present
  - [x]`test/features/now/now_empty_state_test.dart` — verify `NowEmptyState` renders with expected text; verify New York / serif font family applied
  - [x]`test/features/today/today_empty_state_test.dart` — verify nudge text and CTA present
  - [x]`test/features/lists/lists_empty_state_test.dart` — verify text distinct from Now and Today copy
  - [x]Run `flutter test` from `apps/flutter/` — all existing 69 tests plus new tests must pass

- [x]Run build_runner and commit generated files (AC: per ARCH-4)
  - [x]Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x]Commit any newly generated `*.g.dart` files (e.g. if new `@riverpod` providers are added)

## Dev Notes

### Critical Architecture Decisions

**Do NOT switch to `CupertinoApp`**. `main.dart` uses `MaterialApp.router` — keep it. The Cupertino navigation shell is built inside Material via `CupertinoTabScaffold` wrapped in `CupertinoTheme`. This is the pattern used by Things 3 and Fantastical: Material routing + Cupertino widget layer + custom design tokens. Switching to `CupertinoApp` breaks `go_router` integration.

**Add tab is an ACTION tab — not a content tab.** This is a deliberate, non-standard Cupertino divergence documented in the UX spec. Tapping Add MUST open a modal/sheet. The tab must not persist a content screen behind the sheet. Implementation pattern: intercept the tab index change in `CupertinoTabScaffold.onTap`; if `index == 2` (Add), show the sheet and return to the previously active tab index without updating `CupertinoTabController.index`.

**go_router integration with `CupertinoTabScaffold`**: Use go_router's `StatefulShellRoute.indexedStack` (available in go_router ≥ 7.x; already at v15.1.2) to preserve each tab's navigation state independently. Each tab branch gets its own navigator. Add tab branch is a stub — its route simply triggers the Add sheet.

### File Locations — Exact Paths

```
apps/flutter/
├── lib/
│   ├── core/
│   │   ├── router/
│   │   │   └── app_router.dart         ← UPDATE: replace placeholder with StatefulShellRoute
│   │   └── l10n/
│   │       └── strings.dart            ← NEW: empty state copy constants (if gen-l10n not wired)
│   └── features/
│       ├── shell/
│       │   └── presentation/
│       │       ├── app_shell.dart      ← NEW: CupertinoTabScaffold host
│       │       └── add_tab_sheet.dart  ← NEW: Add tab modal sheet (placeholder content)
│       ├── now/
│       │   └── presentation/
│       │       ├── now_screen.dart     ← NEW: placeholder screen
│       │       └── widgets/
│       │           ├── now_card_skeleton.dart  ← NEW
│       │           └── now_empty_state.dart    ← NEW
│       ├── today/
│       │   └── presentation/
│       │       ├── today_screen.dart   ← NEW: placeholder screen
│       │       └── widgets/
│       │           ├── today_skeleton.dart     ← NEW
│       │           └── today_empty_state.dart  ← NEW
│       └── lists/
│           └── presentation/
│               ├── lists_screen.dart   ← NEW: placeholder screen
│               └── widgets/
│                   └── lists_empty_state.dart  ← NEW
├── test/
│   └── features/
│       ├── shell/
│       │   └── app_shell_test.dart     ← NEW
│       ├── now/
│       │   ├── now_skeleton_test.dart  ← NEW
│       │   └── now_empty_state_test.dart ← NEW
│       ├── today/
│       │   ├── today_skeleton_test.dart  ← NEW
│       │   └── today_empty_state_test.dart ← NEW
│       └── lists/
│           └── lists_empty_state_test.dart ← NEW
└── pubspec.yaml                        ← UPDATE: add shimmer dependency
```

Do NOT create `lib/generated/` — generated files co-locate with source (ARCH-4, established Story 1.4).

### go_router Shell Route Pattern

Replace the placeholder `GoRoute` in `app_router.dart` with `StatefulShellRoute.indexedStack`:

```dart
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/now',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/now', builder: (_, __) => const NowScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ]),
          // Add branch — stub; AppShell intercepts tap before navigation occurs
          StatefulShellBranch(routes: [
            GoRoute(path: '/add', builder: (_, __) => const SizedBox.shrink()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/lists', builder: (_, __) => const ListsScreen()),
          ]),
        ],
      ),
    ],
  );
}
```

`AppShell` is the widget that hosts `CupertinoTabScaffold` and intercepts the Add tap.

### Add Tab — Action Tab Implementation

```dart
// lib/features/shell/presentation/app_shell.dart
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({required this.navigationShell, super.key});
}

class _AppShellState extends State<AppShell> {
  void _onTabTapped(int index) {
    if (index == 2) {
      // Add tab: show sheet, do NOT update tab controller
      showCupertinoModalBottomSheet(  // or showModalBottomSheet
        context: context,
        builder: (_) => const AddTabSheet(),
      );
      return;  // <-- critical: do not call navigationShell.goBranch(2)
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: colors.accentPrimary,
        currentIndex: widget.navigationShell.currentIndex > 2
            ? widget.navigationShell.currentIndex
            : widget.navigationShell.currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.clock), label: 'Now'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.add_circled), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.collections), label: 'Lists'),
        ],
      ),
      tabBuilder: (context, index) {
        // Delegate actual screen rendering to go_router's navigationShell
        return widget.navigationShell;
      },
    );
  }
}
```

**Note on `currentIndex` with Add tab (index 2):** Because Add never becomes a real active tab, the `CupertinoTabBar.currentIndex` will never be `2`. When the user is on Lists (index 3), the navigationShell's `currentIndex` is `3`, but the CupertinoTabBar maps that to display index 3. No off-by-one issue occurs because Add is a real branch stub in go_router (it just never navigates there).

**Alternative simpler approach** if `StatefulShellRoute` + `CupertinoTabScaffold` proves complex to combine: Use a plain `Scaffold` with a manually-built `CupertinoTabBar` widget as the `bottomNavigationBar`, and manage the body as an `IndexedStack` of the three real screens. This avoids go_router shell complexity and is perfectly valid for V1 since deep-linking to specific tabs is not a V1 requirement. Prefer `StatefulShellRoute` if straightforward; fall back to `IndexedStack` if not.

### Shimmer Implementation

Use the `shimmer` package (pub.dev). Add to `pubspec.yaml`:

```yaml
dependencies:
  shimmer: ^3.0.0
```

Skeleton row pattern:

```dart
// lib/features/today/presentation/widgets/today_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';

class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reduced motion: skip shimmer animation
    if (MediaQuery.of(context).disableAnimations) {
      return _buildStaticSkeleton(colors);
    }

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.surfaceSecondary,
        highlightColor: colors.surfacePrimary,
        period: const Duration(milliseconds: 1200),
        child: _buildSkeletonRows(colors),
      ),
    );
  }

  Widget _buildStaticSkeleton(OnTaskColors colors) {
    return _buildSkeletonRows(colors);
  }

  Widget _buildSkeletonRows(OnTaskColors colors) {
    return Column(
      children: List.generate(4, (i) => _SkeletonRow(colors: colors)),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final OnTaskColors colors;
  const _SkeletonRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  color: colors.surfaceSecondary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 11,
                  width: 120,
                  color: colors.surfaceSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Now tab card skeleton** matches a taller card proportion (approx 160pt height):

```dart
// lib/features/now/presentation/widgets/now_card_skeleton.dart
class NowCardSkeleton extends StatelessWidget {
  const NowCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    if (MediaQuery.of(context).disableAnimations) {
      return _buildCard(colors);
    }
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: colors.surfaceSecondary,
        highlightColor: colors.surfacePrimary,
        period: const Duration(milliseconds: 1200),
        child: _buildCard(colors),
      ),
    );
  }

  Widget _buildCard(OnTaskColors colors) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      height: 160,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
    );
  }
}
```

### Empty State Copy — Warm Narrative Voice

All copy follows the "past self / future self" voice. No generic placeholders. Externalize to `lib/core/l10n/strings.dart` as constants:

```dart
// lib/core/l10n/strings.dart
class AppStrings {
  // Now tab — rest state
  static const nowEmptyTitle = "You're clear for now.";
  static const nowEmptySubtitleTemplate = "Next: {task} at {time}"; // when known

  // Today tab — no tasks
  static const todayEmptyTitle = "Nothing scheduled.";
  static const todayEmptyAddCta = "Add something?";

  // Lists tab — no lists
  static const listsEmptyTitle = "No lists yet.";
  static const listsEmptySubtitle = "Create a list to start organising what matters.";
}
```

**Now tab empty state** (UX spec: New York serif, centred, `color.text.secondary`; no illustration; emptiness is intentional — negative space communicates calm):

```dart
// lib/features/now/presentation/widgets/now_empty_state.dart
class NowEmptyState extends StatelessWidget {
  final String? nextTaskHint; // e.g. "Budget review at 2pm" — null if unknown
  const NowEmptyState({this.nextTaskHint, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    // Resolve serif family from theme (same one wired in main.dart)
    final serifFamily = Theme.of(context).textTheme.displayLarge?.fontFamily;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.nowEmptyTitle,
              style: TextStyle(
                fontFamily: serifFamily,
                fontSize: 22,
                fontWeight: FontWeight.w400,
                height: 1.3,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (nextTaskHint != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Next: $nextTaskHint',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Today tab empty state** (SF Pro 17pt, not celebratory, single CTA):

```dart
// Trigger Add sheet via callback — do NOT use go_router directly from empty state
class TodayEmptyState extends StatelessWidget {
  final VoidCallback onAddTapped;
  const TodayEmptyState({required this.onAddTapped, super.key});
  // ...
}
```

### Skeleton → Content Transition (800ms Gate)

Skeletons are shown while Riverpod providers are in `AsyncLoading`. The 800ms gate is enforced by the provider itself using a timeout or by a `Future.delayed` in the screen widget:

```dart
// Pattern in today_screen.dart (placeholder; real provider added in story that loads tasks)
class TodayScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In this story: always show empty state after 800ms timeout
    // Real data providers added in later stories; skeleton shown until then
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 800)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const TodaySkeleton();
        }
        return const TodayEmptyState(onAddTapped: _openAddSheet);
      },
    );
  }
}
```

When real data providers exist (future stories), replace `FutureBuilder` with Riverpod `AsyncValue.when()` pattern:

```dart
return asyncTasks.when(
  loading: () => const TodaySkeleton(),
  error: (e, st) => ErrorState(...),
  data: (tasks) => tasks.isEmpty ? TodayEmptyState(...) : TodayTaskList(tasks: tasks),
);
```

### Theme Integration — OnTaskColors Access

Access `OnTaskColors` ThemeExtension (set up in Story 1.5, public in `app_theme.dart`):

```dart
final colors = Theme.of(context).extension<OnTaskColors>()!;
```

This is the ONLY way to access OnTask semantic tokens in widgets. Never read from `AppColors.*` directly in widget trees.

Access accent colour for tab bar selected state:
```dart
CupertinoTabBar(
  activeColor: Theme.of(context).extension<OnTaskColors>()!.accentPrimary,
  ...
)
```

### Spacing — Use AppSpacing, Not Literals

```dart
// CORRECT
const SizedBox(height: AppSpacing.lg)      // 16pt
const SizedBox(height: AppSpacing.xl)      // 24pt
const SizedBox(height: AppSpacing.huge)    // 64pt — NOT AppSpacing.max (doesn't exist)

// WRONG — fails code review
const SizedBox(height: 16)
const SizedBox(height: 64)
```

`AppSpacing.huge = 64.0` (renamed from `max` in Story 1.5 to avoid shadowing `dart:math.max`).

### Riverpod v4 — Provider Pattern

If new `@riverpod` providers are created in this story (e.g. a shell state provider to track active tab):

```dart
// Correct v4 pattern — Ref, not ShellStateRef or similar custom type
@riverpod
class ShellNotifier extends _$ShellNotifier {
  @override
  int build() => 0; // active tab index (0=Now, 1=Today, 3=Lists)
}
```

Use `@Riverpod(keepAlive: true)` for the shell state provider (tab index must survive widget rebuilds).

Actual `Ref` usage in function providers:
```dart
@riverpod
SomeData myProvider(Ref ref) { ... }
```

Run `dart run build_runner build --delete-conflicting-outputs` after any new `@riverpod` annotations. Commit all `*.g.dart` outputs.

### Testing Approach

Tests must run in `apps/flutter/` with `flutter test`. Use `flutter_test` + `mocktail`. No `patrol` (deferred to E2E stories).

**Widget test pattern:**

```dart
// test/features/shell/app_shell_test.dart
void main() {
  testWidgets('renders four Cupertino tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AppShell(navigationShell: _fakeShell()),
        ),
      ),
    );
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);
  });

  testWidgets('Add tab tap opens sheet, does not navigate', (tester) async {
    var sheetOpened = false;
    // Verify that goBranch(2) is NOT called when Add is tapped
    // Verify that showModalBottomSheet IS called
    // ... mock navigationShell
  });
}
```

**Skeleton test — verify RepaintBoundary and row count:**

```dart
testWidgets('TodaySkeleton renders 3-4 rows wrapped in RepaintBoundary', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: const TodaySkeleton(),
    ),
  );
  expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
  // Verify 4 rows (or 3-4 range)
  expect(find.byType(_SkeletonRow), findsNWidgets(4));
});
```

### Project Structure — Established Conventions

From Story 1.4:
- Feature-first: `lib/features/{feature}/data/`, `domain/`, `presentation/`
- `presentation/widgets/` for reusable sub-components within a feature
- No `lib/generated/` folder — generated files co-locate with source
- Tests mirror source tree: `test/features/{feature}/...`

From Story 1.5:
- `lib/core/theme/` contains all theme files — do NOT add theme tokens anywhere else
- `OnTaskColors` is declared in `app_theme.dart` (not a separate file)

### Scope Boundaries

| Item | Belongs To |
|---|---|
| Real task data in Now/Today/Lists screens | Story 1.8+ (after auth) |
| macOS three-pane layout | Story 1.7 (next story) |
| Full Add tab / task capture flow | Story 2.x (task creation epic) |
| Settings navigation (profile icon in nav bar) | Story 1.10 |
| Theme selection UI | Story 1.10 |
| Onboarding / auth screens | Story 1.8 |
| Pull-to-refresh | Deliberately excluded — schedule updates are push-driven (UX spec) |
| Swipe-to-delete on committed tasks | Deliberately disabled (UX spec) |
| Full l10n with gen-l10n / ARB pipeline | Deferred — use `AppStrings` constants for now |

### Anti-Patterns — Do Not Do These

- **Do NOT** use `Navigator.push` or `MaterialPageRoute` for tab navigation — all routing goes through go_router
- **Do NOT** use `BottomNavigationBar` (Material) — use `CupertinoTabBar` for iOS feel
- **Do NOT** hardcode `Color(0xFF...)` in any widget — use `OnTaskColors` tokens
- **Do NOT** hardcode `fontSize: 17` — use `AppTextStyles.*` or `Theme.of(context).textTheme.*`
- **Do NOT** hardcode `SizedBox(height: 16)` — use `AppSpacing.lg`
- **Do NOT** use `AppSpacing.max` — it does not exist; the constant is `AppSpacing.huge` (64pt)
- **Do NOT** create a persistent "Add" screen — Add tab is an action tab that opens a sheet
- **Do NOT** show pull-to-refresh anywhere — not used in On Task (UX spec divergence)
- **Do NOT** show a generic "No items" empty state — all empty states must use warm narrative copy
- **Do NOT** allow skeleton to persist beyond 800ms — hard cap enforced
- **Do NOT** run `build_runner` in CI — local only per ARCH-4
- **Do NOT** switch `main.dart` to `CupertinoApp` — keep `MaterialApp.router`

### Previous Story Intelligence

**From Story 1.5 (design system):**
- `OnTaskColors` ThemeExtension is public in `lib/core/theme/app_theme.dart` — access via `Theme.of(context).extension<OnTaskColors>()!`
- `AppSpacing.huge = 64.0` (not `max` — renamed to avoid dart:math conflict)
- `AppTextStyles.*` constants for all text sizes — no inline fontSize
- Riverpod actual note: `riverpod 3.2.1` uses `.value` (nullable) not `.valueOrNull` — confirmed in Story 1.5 dev completion notes
- Provider functions use `Ref` parameter (not generated `*Ref` types for function providers) — but `@riverpod` class notifiers still generate correct `_$ClassName` base
- `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
- 69 tests currently pass — new tests must not break these

**From Story 1.4 (architecture foundation):**
- `app_router.dart` currently has a placeholder `GoRoute` at `'/'` with a `Text('OnTask')` widget — this is exactly what Story 1.6 replaces
- `go_router` is already at `^15.1.2` — `StatefulShellRoute.indexedStack` is available
- `ProviderContainer` + `mocktail` for provider tests; `flutter_test` for widget tests
- Build: `dart run build_runner build --delete-conflicting-outputs`
- Test: `flutter test` from `apps/flutter/`

**From Story 1.5 completion notes:**
- `AsyncValue`: use `.value` (nullable), not `.valueOrNull` — `riverpod 3.2.1` API
- `main.dart` already has `ProviderScope` wrapping `OnTaskApp`; shell widget fits inside existing routing

### References

- [Source: `_bmad-output/planning-artifacts/epics.md#Story 1.6`] — Acceptance criteria source
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md#iOS bottom tab bar`] — Four-tab IA definition (Now/Today/Add/Lists)
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md#Skeleton and Progressive Loading States`] — 3–4 rows, 1.2s shimmer, 800ms max, `color.surface.secondary` fill, 40% opacity shimmer, `RepaintBoundary` wrapped
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md#Empty State Components`] — Now, Today, Lists distinct empty states; Now: New York serif centred, no illustration; Today: SF Pro 17pt nudge + CTA
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md#Cupertino Divergences`] — Add tab is an action tab; pull-to-refresh is intentionally excluded
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md#Component Strategy`] — `CupertinoTabBar` used as-is with semantic token overrides only
- [Source: `_bmad-output/planning-artifacts/architecture.md`] — NFR-P1: 2s cold launch; go_router as navigation; feature-first clean architecture
- [Source: `_bmad-output/implementation-artifacts/1-5-design-system-theme-implementation.md#Dev Agent Record`] — Story 1.5 completion notes: `.value` not `.valueOrNull`, `Ref` provider signature, `AppSpacing.huge`
- [Source: `apps/flutter/lib/core/router/app_router.dart`] — Current placeholder route at `'/'` (to be replaced)
- [Source: `apps/flutter/lib/core/theme/app_theme.dart`] — `OnTaskColors` ThemeExtension public API
- [Source: `apps/flutter/lib/core/theme/app_spacing.dart`] — `AppSpacing.huge = 64.0` confirmed
- [Source: `apps/flutter/pubspec.yaml`] — Current dependency list; `shimmer` not yet added

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- CupertinoTabScaffold manages its own internal controller; must pass explicit `CupertinoTabController` and reset to previous index when Add tab is tapped to prevent the scaffold from marking index 2 as active.
- `StatefulNavigationShell` cannot be directly subclassed for testing; used full `GoRouter` with `StatefulShellRoute.indexedStack` in test fixtures instead.
- `Future.delayed(800ms)` in `NowScreen`/`TodayScreen` creates pending FakeAsync timers in tests; resolved by advancing test clock with `tester.pump(Duration(milliseconds: 900))`.
- Existing `widget_test.dart` expected `Text('OnTask')` from old placeholder route; updated to expect the four tab labels from the new shell.

### Completion Notes List

- Implemented `StatefulShellRoute.indexedStack` with four branches: Now, Today, Add (stub), Lists.
- `AppShell` uses explicit `CupertinoTabController`; intercepts Add tab tap (index 2), shows `AddTabSheet` modal, and resets controller to previous active tab — goBranch(2) is never called.
- `TodaySkeleton` and `NowCardSkeleton` use `shimmer ^3.0.0` with 1.2s period, wrapped in `RepaintBoundary`; reduced-motion support via `MediaQuery.disableAnimations`.
- 800ms hard cap enforced via `FutureBuilder(Future.delayed(800ms))` in placeholder screens.
- All three empty states use distinct warm narrative copy from `AppStrings` constants.
- `NowEmptyState` uses serif font from theme's `displayLarge.fontFamily`; centred; `textSecondary` colour.
- `TodayEmptyState` uses system SF Pro; nudge copy; single Add CTA via `VoidCallback`.
- `ListsEmptyState` uses warm invitation copy distinct from both Now and Today.
- 102 total tests pass (69 pre-existing + 33 new); no regressions.
- `build_runner` run; `app_router.g.dart` regenerated after router changes.

### File List

- apps/flutter/pubspec.yaml (modified — added shimmer ^3.0.0)
- apps/flutter/pubspec.lock (modified — shimmer resolved)
- apps/flutter/lib/core/router/app_router.dart (modified — StatefulShellRoute.indexedStack)
- apps/flutter/lib/core/router/app_router.g.dart (modified — regenerated)
- apps/flutter/lib/core/l10n/strings.dart (new — AppStrings constants)
- apps/flutter/lib/features/shell/presentation/app_shell.dart (new)
- apps/flutter/lib/features/shell/presentation/add_tab_sheet.dart (new)
- apps/flutter/lib/features/now/presentation/now_screen.dart (new)
- apps/flutter/lib/features/now/presentation/widgets/now_card_skeleton.dart (new)
- apps/flutter/lib/features/now/presentation/widgets/now_empty_state.dart (new)
- apps/flutter/lib/features/today/presentation/today_screen.dart (new)
- apps/flutter/lib/features/today/presentation/widgets/today_skeleton.dart (new)
- apps/flutter/lib/features/today/presentation/widgets/today_empty_state.dart (new)
- apps/flutter/lib/features/lists/presentation/lists_screen.dart (new)
- apps/flutter/lib/features/lists/presentation/widgets/lists_empty_state.dart (new)
- apps/flutter/test/widget_test.dart (modified — updated for new shell)
- apps/flutter/test/features/shell/app_shell_test.dart (new)
- apps/flutter/test/features/now/now_skeleton_test.dart (new)
- apps/flutter/test/features/now/now_empty_state_test.dart (new)
- apps/flutter/test/features/today/today_skeleton_test.dart (new)
- apps/flutter/test/features/today/today_empty_state_test.dart (new)
- apps/flutter/test/features/lists/lists_empty_state_test.dart (new)
