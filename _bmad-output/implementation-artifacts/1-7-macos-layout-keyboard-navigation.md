# Story 1.7: macOS Layout & Keyboard Navigation

Status: review

## Story

As a macOS user,
I want a three-pane layout with keyboard shortcuts and a native toolbar,
so that On Task feels at home on desktop and I can navigate without lifting my hands from the keyboard.

## Acceptance Criteria

1. **Given** the app launches on macOS with window width ≥ 900pt, **When** the main layout renders, **Then** a three-pane layout is shown: sidebar at 260pt fixed width, detail panel at minimum 320pt, main content area filling remaining space
2. **Given** the window width is ≤ 1100pt, **When** the layout renders, **Then** two-pane mode activates: sidebar (260pt) + main content; detail panel is hidden
3. **Given** the macOS app launches, **When** the window is shown, **Then** the minimum window size is enforced at 900×600pt — the window cannot be resized smaller
4. **Given** the macOS layout is active, **When** the toolbar renders, **Then** a "New Task" button appears in the window toolbar (replacing the Add tab concept), and the four navigation sections (Now, Today, Lists, Settings) appear as sidebar items with no bottom tab bar
5. **Given** the macOS app has focus, **When** the user presses ⌘N, **Then** the new task creation flow opens
6. **Given** the macOS app has focus, **When** the user presses ⌘↩, **Then** the focused task is marked complete
7. **Given** the macOS app has focus, **When** the user presses Space, **Then** the timer starts or stops for the focused task
8. **Given** the macOS app has focus, **When** the user presses ⌘K, **Then** the command palette opens
9. **Given** the macOS app has focus, **When** the user presses ⌘1 through ⌘4, **Then** focus navigates to the corresponding sidebar section (Now=1, Today=2, Lists=3, Settings=4)
10. **Given** the macOS app has focus, **When** the user presses ⌘,, **Then** the Settings pane opens
11. **Given** the macOS layout is rendered, **When** the user presses Tab, **Then** keyboard focus cycles between the three panes in order: sidebar → detail panel → main area (NFR-A2, UX-DR23)

## Tasks / Subtasks

- [x] Add `window_manager` package and configure minimum window size (AC: 3)
  - [x] Add `window_manager: ^0.3.9` to `dependencies` in `apps/flutter/pubspec.yaml`
  - [x] Run `flutter pub get` to resolve
  - [x] In `macos/Runner/AppDelegate.swift` (or equivalent macOS entrypoint), set minimum window size to 900×600pt using `windowManager.setMinimumSize(const Size(900, 600))`; alternatively configure via `window_manager` in `main.dart` macOS-guarded block
  - [x] Ensure `window_manager.ensureInitialized()` is called before `runApp` on macOS (guard with `Platform.isMacOS`)

- [x] Create `MacosShell` widget — platform-aware shell dispatcher (AC: 1, 2, 4)
  - [x] Create `lib/features/shell/presentation/macos_shell.dart` — the macOS-specific navigation host
  - [x] `MacosShell` uses `LayoutBuilder` to detect pane mode: width > 1100pt → three-pane; 900pt–1100pt → two-pane (detail hidden)
  - [x] Sidebar: fixed 260pt `SizedBox` containing `MacosSidebar` widget; sidebar items: Now, Today, Lists, Settings (no bottom tab bar on macOS)
  - [x] Detail panel: `AnimatedContainer` collapsing to 0pt width in two-pane mode (do NOT use `Visibility` — preserve state with `Offstage` or width-collapse)
  - [x] Main content area: `Expanded` fill

- [x] Create `MacosSidebar` widget (AC: 4, 9, 10)
  - [x] Create `lib/features/shell/presentation/macos_sidebar.dart`
  - [x] Four navigation items: Now, Today, Lists, Settings — using `ListTile` or custom styled row matching design tokens
  - [x] Active item highlighted with `OnTaskColors.accentPrimary`; selected state tracked via `selectedIndex` passed from `MacosShell`
  - [x] "New Task" button at top of sidebar (above nav items) — tapping opens `AddTaskSheet` (same sheet used by iOS Add tab); uses `OnTaskColors.accentPrimary` fill

- [x] Update `AppShell` to dispatch iOS vs macOS shell (AC: 1, 4)
  - [x] In `lib/features/shell/presentation/app_shell.dart`, add `Platform.isMacOS` check
  - [x] If macOS → render `MacosShell`; if iOS → existing `CupertinoTabScaffold` unchanged
  - [x] Import `dart:io` for `Platform` — NOT `flutter/foundation.dart` `defaultTargetPlatform` (use `dart:io` `Platform.isMacOS` for runtime, `kIsWeb` guard not needed since web is not a target)

- [x] Update `app_router.dart` to add macOS routes (AC: 4)
  - [x] Add `/settings` route branch under `StatefulShellRoute` (macOS sidebar item 4 navigates to it)
  - [x] `MacosShell` manages which branch is active via its own `currentIndex`; `go_router` `StatefulShellRoute` routes drive content in the main area
  - [x] No changes to existing iOS branches (`/now`, `/today`, `/add`, `/lists`)

- [x] Create placeholder `SettingsScreen` (AC: 4, 10)
  - [x] Create `lib/features/settings/presentation/settings_screen.dart` — empty scaffold placeholder (real content in Story 1.10)
  - [x] Route path: `/settings`

- [x] Implement keyboard shortcuts (AC: 5, 6, 7, 8, 9, 10, 11)
  - [x] Create `lib/features/shell/presentation/macos_keyboard_shortcuts.dart`
  - [x] Wrap `MacosShell` body in Flutter's `Shortcuts` + `Actions` widget pair
  - [x] Define `SingleActivator` instances for all shortcuts:
    - `⌘N` → `NewTaskIntent`
    - `⌘Return` → `CompleteTaskIntent`
    - `Space` → `ToggleTimerIntent` (key: `LogicalKeyboardKey.space`)
    - `⌘K` → `CommandPaletteIntent`
    - `⌘1` → `NavigateSectionIntent(section: 0)` (Now)
    - `⌘2` → `NavigateSectionIntent(section: 1)` (Today)
    - `⌘3` → `NavigateSectionIntent(section: 2)` (Lists)
    - `⌘4` → `NavigateSectionIntent(section: 3)` (Settings)
    - `⌘Comma` → `OpenSettingsIntent`
  - [x] For Tab pane cycling: use `FocusTraversalGroup` on each pane, `FocusTraversalPolicy` ordered sidebar → detail → main
  - [x] `Actions` handlers in `MacosShell`: `NewTaskIntent` opens `AddTaskSheet`; navigation intents call `setState` to update `selectedIndex`; `CompleteTaskIntent` and `ToggleTimerIntent` dispatch to placeholder no-ops (real logic in future task stories)
  - [x] `CommandPaletteIntent` opens a placeholder `CommandPaletteSheet` (minimal implementation — full command palette is V2; this story just wires the shortcut to a dismissible overlay)
  - [x] Guard all shortcut registration with `Platform.isMacOS` — do NOT register macOS shortcuts on iOS

- [x] Configure macOS toolbar (AC: 4)
  - [x] Add "New Task" `NSToolbarItem` via method channel OR use Flutter's `PlatformMenuBar` / `ToolbarItem` APIs
  - [x] Preferred approach: use `macos_ui` package's `ToolBar` widget if added, OR implement as a styled `Container` at the top of `MacosShell` within Flutter (native NSToolbar integration is V2 polish — V1 toolbar is a Flutter-rendered bar at window top using `appBar: PreferredSizeWidget`)
  - [x] "New Task" button in toolbar uses `OnTaskColors.accentPrimary`; calls same `AddTaskSheet` handler

- [x] Create placeholder `CommandPaletteSheet` (AC: 8)
  - [x] Create `lib/features/shell/presentation/command_palette_sheet.dart`
  - [x] Minimal: a modal sheet/overlay with a search text field and empty results list — placeholder for V2 full implementation
  - [x] Opens via `showModalBottomSheet` or `showDialog` (use `showDialog` on macOS — bottom sheets feel wrong on desktop)
  - [x] Dismissed by Escape key or clicking outside

- [x] Accessibility: Tab pane focus traversal (AC: 11)
  - [x] Wrap sidebar, detail panel, and main area each in `FocusTraversalGroup`
  - [x] Set `FocusTraversalGroup.policy` to `OrderedTraversalPolicy` with sidebar order=1, detail order=2, main order=3
  - [x] Ensure each pane has at least one `Focus` widget as an anchor so Tab lands on the pane frame before descending into child elements

- [x] Write widget tests (AC: 1–11)
  - [x] `test/features/shell/macos_shell_test.dart`:
    - Pump `MacosShell` at 1200pt width → verify three-pane layout (sidebar, detail, main all visible)
    - Pump `MacosShell` at 1000pt width → verify two-pane layout (detail panel hidden/zero width)
    - Verify sidebar contains four navigation items: Now, Today, Lists, Settings
    - Verify "New Task" button present in sidebar/toolbar area
  - [x] `test/features/shell/macos_keyboard_shortcuts_test.dart`:
    - Simulate `⌘N` key event → verify `AddTaskSheet` open callback fired
    - Simulate `⌘1` → verify `selectedIndex` changes to 0 (Now)
    - Simulate `⌘4` → verify Settings navigation triggered
    - Simulate `⌘,` → verify Settings navigation triggered
  - [x] Run `flutter test` from `apps/flutter/` — all existing tests plus new tests must pass (baseline: 69+ tests from Story 1.6)

- [x] Run build_runner and commit generated files (ARCH-4)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`
  - [x] Commit any newly generated `*.g.dart` files

## Dev Notes

### Critical Architecture Decisions

**Platform dispatch in `AppShell`**: Story 1.6 built `AppShell` as a `ConsumerStatefulWidget` rendering `CupertinoTabScaffold`. Do NOT rewrite `AppShell` — instead, add a platform branch at the TOP of its `build` method:

```dart
@override
Widget build(BuildContext context) {
  if (Platform.isMacOS) {
    return MacosShell(navigationShell: widget.navigationShell);
  }
  // existing iOS CupertinoTabScaffold code below — unchanged
  ...
}
```

This is the minimum-change, regression-safe integration point. The macOS shell is completely isolated.

**`AppShell` is a `ConsumerStatefulWidget`** — `MacosShell` must also be a `ConsumerStatefulWidget` (or `ConsumerWidget`) so it can access Riverpod providers (e.g., `openAddSheetRequestProvider` for cross-screen Add sheet triggers). Follow the same pattern from Story 1.6.

**Do NOT add macOS platform to iOS-only guards**: The existing `Platform.isIOS` guard around `live_activities` must remain unchanged. macOS build correctly ignores Live Activities. No new guards needed for this story beyond the main `Platform.isMacOS` shell dispatch.

**`go_router` integration for macOS**: `MacosShell` receives the same `StatefulNavigationShell` from go_router as `AppShell` does. The macOS layout uses it differently — instead of a tab bar driving branch selection, the sidebar drives it. Call `navigationShell.goBranch(index)` from sidebar item taps, same API as iOS.

**Adding `/settings` route**: Story 1.6 set up four branches (now=0, today=1, add=2, lists=3). macOS needs a fifth branch for settings (index=4). This requires adding a new `StatefulShellBranch` to `app_router.dart`. The iOS shell is unaffected because it never navigates to branch 4 — the Add tab stub at index 2 means iOS tab indices stay at 0–3 mapped to their existing branches.

**Toolbar approach for V1**: Do NOT attempt native `NSToolbar` integration via method channels in this story — that is V2 polish. Implement the "toolbar" as a Flutter `PreferredSizeWidget` (e.g., `AppBar` or custom container) at the top of `MacosShell`. Height approximately 52pt, background `OnTaskColors.surfacePrimary`, "New Task" button right-aligned. This renders correctly on macOS and feels native enough for V1.

**Keyboard shortcuts — use Flutter `Shortcuts`+`Actions`, not `RawKeyboard`**: `RawKeyboard` is deprecated in Flutter 3.x. Use:
- `Shortcuts` widget with `Map<ShortcutActivator, Intent>`
- `Actions` widget with `Map<Type, Action<Intent>>`
- `SingleActivator(LogicalKeyboardKey.keyN, meta: true)` for ⌘N on macOS (use `meta: true` for Command key, NOT `control: true`)

On macOS, the Command key maps to `meta` in Flutter's key system. iOS does not use `meta`. Guarding with `Platform.isMacOS` before registering shortcuts prevents any iOS impact.

**Tab pane focus traversal**: Use `FocusTraversalGroup` around each pane. The `Tab` key handling is built into Flutter's focus system — you just need to set the group order. The Tab key on macOS advances to the next `FocusTraversalGroup` by default. Do NOT intercept `Tab` manually via `Shortcuts`.

**Minimum window size**: Use the `window_manager` package. Initialize before `runApp`:

```dart
// main.dart
import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(900, 600),
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
  }
  runApp(const ProviderScope(child: OnTaskApp()));
}
```

`main.dart` currently does NOT have `async` or `WidgetsFlutterBinding.ensureInitialized()` — you MUST add both. The existing `runApp(const ProviderScope(child: OnTaskApp()))` line moves inside the `main()` body after the macOS guard.

**`window_manager` package version**: Use `^0.3.9` (latest stable as of early 2026). This package is well-maintained and is the standard Flutter solution for desktop window management.

**Detail panel collapse strategy**: Use `AnimatedContainer` with width transitioning between `320.0` and `0.0` based on `_isTwoPane` state. Do NOT use `Visibility(visible: false)` or conditional rendering — this destroys widget state. Width-collapse via `AnimatedContainer` or `Offstage(offstage: !visible)` preserves state.

### File Locations — Exact Paths

```
apps/flutter/
├── lib/
│   ├── core/
│   │   └── router/
│   │       └── app_router.dart         ← UPDATE: add /settings branch (index 4)
│   └── features/
│       ├── shell/
│       │   └── presentation/
│       │       ├── app_shell.dart      ← UPDATE: add Platform.isMacOS dispatch
│       │       ├── macos_shell.dart    ← NEW: macOS three/two-pane layout host
│       │       ├── macos_sidebar.dart  ← NEW: sidebar nav items + New Task button
│       │       ├── macos_keyboard_shortcuts.dart  ← NEW: Shortcuts/Actions/Intents
│       │       └── command_palette_sheet.dart ← NEW: placeholder ⌘K overlay
│       └── settings/
│           └── presentation/
│               └── settings_screen.dart ← NEW: placeholder screen
├── test/
│   └── features/
│       └── shell/
│           ├── macos_shell_test.dart   ← NEW
│           └── macos_keyboard_shortcuts_test.dart ← NEW
├── macos/
│   └── Runner/
│       └── (no changes needed — window_manager handles NSWindow config via Flutter)
└── pubspec.yaml                        ← UPDATE: add window_manager dependency
```

Do NOT create `lib/generated/` — generated files co-locate with source (ARCH-4).
Do NOT modify `macos/Runner/AppDelegate.swift` — `window_manager` handles this via its own plugin.

### Layout Breakpoint Logic

```dart
// lib/features/shell/presentation/macos_shell.dart
class MacosShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MacosShell({required this.navigationShell, super.key});
  ...
}

class _MacosShellState extends ConsumerState<MacosShell> {
  int _selectedIndex = 0;  // 0=Now, 1=Today, 2=Lists, 3=Settings

  static const double _sidebarWidth = 260.0;
  static const double _detailMinWidth = 320.0;
  static const double _twoPaneBreakpoint = 1100.0;

  void _onSidebarItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // Map sidebar index to go_router branch
    // Sidebar: 0=Now(branch 0), 1=Today(branch 1), 2=Lists(branch 3), 3=Settings(branch 4)
    final branchIndex = index == 2 ? 3 : index == 3 ? 4 : index;
    widget.navigationShell.goBranch(branchIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoPane = constraints.maxWidth <= _twoPaneBreakpoint;
        return Row(
          children: [
            SizedBox(
              width: _sidebarWidth,
              child: MacosSidebar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onSidebarItemTapped,
                onNewTask: _openAddSheet,
              ),
            ),
            if (!isTwoPane)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isTwoPane ? 0 : _detailMinWidth,
                child: const MacosDetailPanel(),  // placeholder in this story
              ),
            Expanded(child: widget.navigationShell),
          ],
        );
      },
    );
  }
}
```

**Note on sidebar index ↔ go_router branch mapping:**
- iOS branches: now=0, today=1, add=2 (stub), lists=3
- After this story: settings=4 (new branch)
- macOS sidebar index 0 (Now) → branch 0; index 1 (Today) → branch 1; index 2 (Lists) → branch 3; index 3 (Settings) → branch 4
- The Add stub (branch 2) is never navigated to on macOS — "New Task" opens a sheet

### Keyboard Shortcut Implementation Pattern

```dart
// lib/features/shell/presentation/macos_keyboard_shortcuts.dart

// Intents
class NewTaskIntent extends Intent { const NewTaskIntent(); }
class CompleteTaskIntent extends Intent { const CompleteTaskIntent(); }
class ToggleTimerIntent extends Intent { const ToggleTimerIntent(); }
class CommandPaletteIntent extends Intent { const CommandPaletteIntent(); }
class NavigateSectionIntent extends Intent {
  final int section;
  const NavigateSectionIntent(this.section);
}
class OpenSettingsIntent extends Intent { const OpenSettingsIntent(); }

// Shortcuts map (used in MacosShell build)
static final Map<ShortcutActivator, Intent> macosShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyN, meta: true): const NewTaskIntent(),
  SingleActivator(LogicalKeyboardKey.enter, meta: true): const CompleteTaskIntent(),
  SingleActivator(LogicalKeyboardKey.space): const ToggleTimerIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, meta: true): const CommandPaletteIntent(),
  SingleActivator(LogicalKeyboardKey.digit1, meta: true): const NavigateSectionIntent(0),
  SingleActivator(LogicalKeyboardKey.digit2, meta: true): const NavigateSectionIntent(1),
  SingleActivator(LogicalKeyboardKey.digit3, meta: true): const NavigateSectionIntent(2),
  SingleActivator(LogicalKeyboardKey.digit4, meta: true): const NavigateSectionIntent(3),
  SingleActivator(LogicalKeyboardKey.comma, meta: true): const OpenSettingsIntent(),
};
```

Wrap the `MacosShell` scaffold body in:
```dart
Shortcuts(
  shortcuts: macosShortcuts,
  child: Actions(
    actions: {
      NewTaskIntent: CallbackAction<NewTaskIntent>(onInvoke: (_) => _openAddSheet()),
      NavigateSectionIntent: CallbackAction<NavigateSectionIntent>(
          onInvoke: (intent) => _onSidebarItemTapped(intent.section)),
      OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
          onInvoke: (_) => _onSidebarItemTapped(3)),
      CommandPaletteIntent: CallbackAction<CommandPaletteIntent>(
          onInvoke: (_) => _openCommandPalette()),
      // CompleteTaskIntent, ToggleTimerIntent: no-op placeholders for now
      CompleteTaskIntent: CallbackAction<CompleteTaskIntent>(onInvoke: (_) => null),
      ToggleTimerIntent: CallbackAction<ToggleTimerIntent>(onInvoke: (_) => null),
    },
    child: Focus(
      autofocus: true,
      child: _buildLayout(constraints),
    ),
  ),
)
```

### Access to Design Tokens

Always access colors via:
```dart
final colors = Theme.of(context).extension<OnTaskColors>()!;
```
`OnTaskColors` is defined in `lib/core/theme/app_colors.dart`. Available tokens include `accentPrimary`, `surfacePrimary`, `surfaceSecondary`, `textPrimary`, `textSecondary`. Do NOT hardcode color values.

Access spacing via `AppSpacing` constants in `lib/core/theme/app_spacing.dart`.

### Testing Approach

For macOS layout tests, set the surface size to simulate different window widths:
```dart
await tester.binding.setSurfaceSize(const Size(1200, 800));  // three-pane
await tester.binding.setSurfaceSize(const Size(1000, 700));  // two-pane
```

For keyboard shortcut tests, use `tester.sendKeyDownEvent` + `tester.sendKeyUpEvent` with `LogicalKeyboardKey.meta` modifier, or use `tester.sendKeyEvent` with `isMetaPressed: true` via `KeyEventSimulator`.

Existing test baseline from Story 1.6: 69+ passing tests. Do NOT break any existing tests. The `Platform.isMacOS` check in `AppShell` will evaluate to `false` in standard Flutter widget tests (which run on Linux in CI), so existing `AppShell` tests continue to exercise the iOS path without changes.

### Reduced Motion

On macOS, respect `MediaQuery.of(context).disableAnimations` for the detail panel collapse animation. If true, set `AnimatedContainer` duration to `Duration.zero`.

### macOS-Specific Considerations

- **HealthKit is iOS-only** — macOS receives no HealthKit functionality. `Platform.isIOS` guards already in place from architecture (ARCH decision). No new guards needed in this story.
- **Live Activities are iOS-only** — existing `Platform.isIOS` guard in shell providers remains unchanged.
- **Window decoration**: macOS renders its own title bar above the Flutter view. The Flutter "toolbar" sits below the native macOS traffic-light buttons. Do NOT attempt to hide the native title bar in V1.
- **`dart:io` vs `flutter/foundation.dart`**: Use `import 'dart:io' show Platform;` for `Platform.isMacOS`. Do NOT use `defaultTargetPlatform == TargetPlatform.macOS` — that approach is for non-io environments like web, which is not a target platform for this project.

### Project Structure Notes

- Feature-first architecture: `lib/features/shell/` owns all shell variants. The `settings` feature gets its own folder: `lib/features/settings/`.
- All new Dart files follow existing naming: snake_case filenames, `PascalCase` widget class names.
- No new code-generation annotations in this story (no new `@riverpod`, `@freezed`, or `@JsonSerializable` classes expected) — `build_runner` step is precautionary.
- `AppStrings` in `lib/core/l10n/strings.dart` (established Story 1.6): add any new macOS-specific strings (e.g., toolbar button label "New Task", sidebar section labels) as constants there, not inline.

### References

- UX spec macOS layout: [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Platform Strategy, macOS (V1 secondary), line ~1605]
- UX spec keyboard shortcuts: [Source: ux-design-specification.md — Keyboard focus on macOS, line ~1691]
- UX spec breakpoints: [Source: ux-design-specification.md — Breakpoints table, line ~1621]
- Architecture Flutter stack: [Source: _bmad-output/planning-artifacts/architecture.md — Flutter Client section]
- Architecture macOS guard pattern: [Source: architecture.md — iOS only section, line ~215]
- Story 1.6 app_shell.dart: `apps/flutter/lib/features/shell/presentation/app_shell.dart`
- Story 1.6 app_router.dart: `apps/flutter/lib/core/router/app_router.dart`
- Theme tokens: `apps/flutter/lib/core/theme/app_colors.dart`, `app_spacing.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No blocking issues encountered.

### Completion Notes List

- Implemented full macOS three/two-pane layout shell (`MacosShell`) with `LayoutBuilder` breakpoints (1100pt threshold).
- `AppShell` dispatches to `MacosShell` on macOS via `Platform.isMacOS` from `dart:io`; iOS path unchanged.
- `MacosSidebar` renders four nav items (Now, Today, Lists, Settings) with `accentPrimary` active highlight and a "New Task" `FilledButton` at top.
- Flutter-rendered toolbar (`_MacosToolbar`, 52pt) placed below native macOS title bar; "New Task" button right-aligned.
- All 9 keyboard shortcuts wired via `Shortcuts`+`Actions` (⌘N, ⌘↩, Space, ⌘K, ⌘1–4, ⌘,); CompleteTask and ToggleTimer are placeholder no-ops for Story 2.x.
- `CommandPaletteSheet` is a placeholder `Dialog` with search field; dismissed by Escape.
- `FocusTraversalGroup`+`OrderedTraversalPolicy` applied to sidebar (order=1), detail (order=2), main (order=3) for Tab pane cycling.
- `window_manager ^0.3.9` added; `main.dart` made `async` with `WidgetsFlutterBinding.ensureInitialized()` and macOS-guarded `windowManager.waitUntilReadyToShow(WindowOptions(minimumSize: Size(900, 600)))`.
- `/settings` branch added as branch index 4 in `app_router.dart`; sidebar index mapping: Now=0→branch 0, Today=1→branch 1, Lists=2→branch 3, Settings=3→branch 4.
- Detail panel uses `Offstage`+`AnimatedContainer` (width 0 in two-pane); respects `MediaQuery.disableAnimations`.
- Existing tests updated to be platform-aware (`app_shell_test.dart`, `widget_test.dart`). 11 new tests added across `macos_shell_test.dart` and `macos_keyboard_shortcuts_test.dart`. All tests pass.
- `build_runner` ran clean; no new generated files from this story's code.

### File List

apps/flutter/pubspec.yaml
apps/flutter/lib/main.dart
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/lib/core/router/app_router.dart
apps/flutter/lib/features/shell/presentation/app_shell.dart
apps/flutter/lib/features/shell/presentation/macos_shell.dart
apps/flutter/lib/features/shell/presentation/macos_sidebar.dart
apps/flutter/lib/features/shell/presentation/macos_keyboard_shortcuts.dart
apps/flutter/lib/features/shell/presentation/command_palette_sheet.dart
apps/flutter/lib/features/settings/presentation/settings_screen.dart
apps/flutter/test/features/shell/app_shell_test.dart
apps/flutter/test/features/shell/macos_shell_test.dart
apps/flutter/test/features/shell/macos_keyboard_shortcuts_test.dart
apps/flutter/test/widget_test.dart
_bmad-output/implementation-artifacts/1-7-macos-layout-keyboard-navigation.md
_bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- Story 1.7 implemented: macOS Layout & Keyboard Navigation (Date: 2026-03-30)
