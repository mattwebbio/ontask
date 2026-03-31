# Story 2.13: Chapter Break Screen & iPad Layout

Status: review

## Story

As a user,
I want meaningful transition moments after milestones and an app that works acceptably on iPad,
So that completion feels celebrated and I can use On Task on any device I own.

## Acceptance Criteria

1. **Given** a significant milestone occurs (task commitment locked, task completed, missed commitment recovery) **When** the transition screen is shown **Then** the Chapter Break Screen displays with recovery framing: "that one's done — what does your future self need now?" (UX-DR13)

2. **Given** the Chapter Break Screen appears **When** animating in **Then** "The chapter break" motion token plays: 50ms fade + slight upward shift (`Offset(0, 0.04)` → `Offset(0, 0)`)

3. **Given** "Reduce Motion" is enabled (`MediaQuery.of(context).disableAnimations == true`) **When** the Chapter Break Screen appears **Then** the transition is an instant cut with no animation (zero-duration, no offset shift)

4. **Given** the app is running on iPad **When** the UI renders **Then** the phone layout renders acceptably centred on iPad screen — no broken layouts, no clipped content (UX-DR35)

5. **Given** the app is running on any iPad size **When** any screen renders **Then** the app does not crash or display blank screens

6. **Given** the codebase is reviewed **When** the Chapter Break Screen feature is implemented **Then** a code comment in `app_router.dart` and/or a dedicated `// TODO(v1.1-ipad):` comment in `app_shell.dart` documents the V1.1 upgrade path: `LayoutBuilder` breakpoint at 600pt → two-column layout (sidebar 240pt + content fills)

## Tasks / Subtasks

- [x] Create the Chapter Break Screen widget (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/chapter_break/presentation/chapter_break_screen.dart` — NEW:
    - `ChapterBreakScreen({required String taskTitle, String? stakeAmount, required VoidCallback onContinue, super.key})` — `StatefulWidget` (needs `AnimationController`)
    - Uses `TickerProviderStateMixin` for animation
    - **Entry animation — "The chapter break" motion token** (UX-DR20, UX-DR35):
      - Full animation: 50ms fade (`FadeTransition` opacity 0 → 1) + slight upward shift (`SlideTransition` from `Offset(0, 0.04)` to `Offset(0, 0)`)
      - IMPORTANT: The story specifies 50ms fade + upward shift. The UX doc table says "slow fade rise, 800ms" for full animation but the AC for this story explicitly defines 50ms — **the AC takes precedence**. Use 50ms.
      - Reduced motion: `MediaQuery.of(context).disableAnimations` check in `initState`; if true → `controller.value = 1.0` immediately (no animation)
      - Animation controller: `AnimationController(duration: const Duration(milliseconds: 50), vsync: this)`; call `controller.forward()` in `initState` (or set value=1.0 if reduced motion)
    - **Layout** (full-screen, no shell chrome):
      - Background: `CupertinoColors.systemBackground`
      - Centred column with generous padding (EdgeInsets.symmetric(horizontal: 32, vertical: 64))
      - Top section: New York serif headline using `AppTextStyles.impactMilestone` (34pt serif) — text: `AppStrings.chapterBreakHeadline`
      - Sub-copy using `AppTextStyles.voiceCopyPrimary` (20pt serif): `AppStrings.chapterBreakSubcopy`
      - Task title display using `AppTextStyles.body`: task title passed in constructor
      - If `stakeAmount != null`: show stake amount in `AppTextStyles.secondary`
      - CTA button: `CupertinoButton.filled` label `AppStrings.chapterBreakCta` → calls `onContinue`
      - **No Material widgets**: CupertinoButton only
    - **VoiceOver** (UX spec §Accessibility):
      - `Semantics(liveRegion: true)` wrapping the screen heading
      - Screen uses `SemanticsService.announce()` in `initState` via `WidgetsBinding.instance.addPostFrameCallback`: announce `AppStrings.chapterBreakVoiceOverAnnounce`
      - Note: `SemanticsService.announce()` IS used here per the UX spec §9.6 which explicitly calls it out for the chapter break screen. This is the ONE exception to the "no SemanticsService.announce()" rule (the ban is on using it instead of `liveRegion`; here both are used as specified)
      - VoiceOver reading order: heading → task title → CTA
    - `dispose()`: `controller.dispose()`

- [x] Create the chapter_break feature module (AC: 1)
  - [x] `apps/flutter/lib/features/chapter_break/` — NEW feature directory:
    - `domain/chapter_break_trigger.dart` — NEW: `enum ChapterBreakTrigger { taskCompleted, commitmentLocked, missedCommitmentRecovery }`
    - `presentation/chapter_break_screen.dart` — (see task above)
  - No data layer or repository needed — this is a pure UI screen with no API calls in V1

- [x] Add go_router route for Chapter Break Screen (AC: 1)
  - [x] `apps/flutter/lib/core/router/app_router.dart` — MODIFY:
    - Add import for `ChapterBreakScreen`
    - Add a TOP-LEVEL `GoRoute` (outside `StatefulShellRoute`, like `/auth/sign-in`) for path `/chapter-break`:
      ```dart
      GoRoute(
        path: '/chapter-break',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChapterBreakScreen(
            taskTitle: extra?['taskTitle'] as String? ?? '',
            stakeAmount: extra?['stakeAmount'] as String?,
            onContinue: () => context.go('/now'),
          );
        },
      ),
      ```
    - Place BEFORE the `StatefulShellRoute.indexedStack` route
    - Add V1.1 iPad upgrade path comment:
      ```dart
      // TODO(v1.1-ipad): When implementing two-column iPad layout, add a
      // LayoutBuilder breakpoint check at 600pt logical width in AppShell.
      // Below 600pt → phone layout (current). Above 600pt → two-column:
      // sidebar (240pt fixed) + content (fills). Touch-optimised — not macOS
      // sidebar semantics. No architectural changes required; clean upgrade path.
      ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/` to regenerate `app_router.g.dart`

- [x] Wire Chapter Break Screen trigger from NowScreen (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/now/presentation/now_screen.dart` — MODIFY:
    - In `onComplete` callback (line ~93), after calling `ref.read(nowProvider.notifier).completeTask(task.id)`, navigate to the chapter break screen:
      ```dart
      onComplete: () {
        ref.read(nowProvider.notifier).completeTask(task.id);
        context.push('/chapter-break', extra: {
          'taskTitle': task.title,
          'stakeAmount': null, // Stake amount available in Epic 6
        });
      },
      ```
    - Use `context.push` (not `context.go`) so the user can navigate back if needed via system back gesture
    - Import `package:go_router/go_router.dart`

- [x] Add V1.1 iPad layout comment to AppShell (AC: 6)
  - [x] `apps/flutter/lib/features/shell/presentation/app_shell.dart` — MODIFY:
    - Add a prominent doc comment at the top of the `AppShell` class body:
      ```dart
      // iPad V1: Phone layout rendered centred — acceptable for V1 (UX-DR35).
      // No LayoutBuilder breakpoint; single-column layout on all screen sizes.
      //
      // TODO(v1.1-ipad): Two-column layout upgrade path:
      // Use LayoutBuilder(builder: (context, constraints) {
      //   if (constraints.maxWidth >= 600) {
      //     return _iPadTwoColumnShell(navigationShell); // sidebar 240pt + content
      //   }
      //   return _phoneShell(navigationShell); // current implementation
      // });
      ```

- [x] Add strings to AppStrings (AC: 1)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` — MODIFY: add new constants:
    - `chapterBreakHeadline` = `"that one's done."`
    - `chapterBreakSubcopy` = `"What does your future self need now?"`
    - `chapterBreakCta` = `"Keep going"`
    - `chapterBreakVoiceOverAnnounce` = `"A task has been completed. You're on a roll."`
    - `chapterBreakTaskLabel` = `"Completed task"`
    - `chapterBreakStakeLabel` = `"Stake returned"`

- [x] Write tests (AC: 1, 2, 3, 4, 5)
  - [x] `apps/flutter/test/features/chapter_break/chapter_break_screen_test.dart` — NEW:
    - `ChapterBreakScreen`: verify headline text renders (`AppStrings.chapterBreakHeadline`)
    - `ChapterBreakScreen`: verify sub-copy text renders (`AppStrings.chapterBreakSubcopy`)
    - `ChapterBreakScreen`: verify task title is displayed
    - `ChapterBreakScreen`: verify stake amount is shown when provided
    - `ChapterBreakScreen`: verify stake amount is NOT shown when null
    - `ChapterBreakScreen`: verify CTA button is present with label `AppStrings.chapterBreakCta`
    - `ChapterBreakScreen`: verify tapping CTA fires `onContinue` callback
    - `ChapterBreakScreen (reduced motion)`: verify no AnimationController forward called — screen renders immediately at full opacity when `disableAnimations: true` in MediaQuery
    - `ChapterBreakScreen`: verify `Semantics(liveRegion: true)` wraps the heading
    - `ChapterBreakScreen`: verify no Material widgets used (find no `AlertDialog`, `ElevatedButton`, `TextButton`)
    - **Test setup pattern** (mirrors all prior stories):
      ```dart
      setUp(() {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      });
      ```
    - Wrap widgets in `ProviderScope(overrides: [...])` + `CupertinoApp` (NOT `MaterialApp`)
    - Reduced motion test: wrap in `MediaQuery(data: MediaQueryData(disableAnimations: true), child: ...)`
  - [x] `apps/flutter/test/features/chapter_break/` directory must be created

## Dev Notes

### Feature Module Placement

The Chapter Break Screen is a new feature, not a sub-component of an existing one. Place it in:
```
apps/flutter/lib/features/chapter_break/
├── domain/
│   └── chapter_break_trigger.dart          ← NEW: ChapterBreakTrigger enum
└── presentation/
    └── chapter_break_screen.dart            ← NEW: full-screen transition widget
```

No `data/` layer needed — V1 is a pure UI screen triggered by navigation. No repository, no API calls.

### Animation Implementation — "The Chapter Break" Motion Token

Per UX-DR20 and the story AC, the motion token is: **50ms fade + slight upward shift**.

```dart
// In ChapterBreakScreen State:
late final AnimationController _controller;
late final Animation<double> _opacity;
late final Animation<Offset> _slide;

@override
void initState() {
  super.initState();
  final disableAnimations = MediaQuery.of(context).disableAnimations;

  _controller = AnimationController(
    duration: const Duration(milliseconds: 50),
    vsync: this,
  );

  _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  if (disableAnimations) {
    _controller.value = 1.0; // instant cut — no animation
  } else {
    _controller.forward();
  }

  // VoiceOver announcement per UX spec §9 (chapter break screen)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SemanticsService.announce(
      AppStrings.chapterBreakVoiceOverAnnounce,
      TextDirection.ltr,
    );
  });
}
```

Note: `SemanticsService.announce()` is used here intentionally. The UX spec §Accessibility explicitly requires it for the chapter break screen (it appears without user initiation). This is distinct from banner widgets where `liveRegion: true` is used instead. Both are used in this screen: `announce()` for the initial announcement + `Semantics(liveRegion: true)` on the heading.

### Widget Tree

```dart
FadeTransition(
  opacity: _opacity,
  child: SlideTransition(
    position: _slide,
    child: CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading — New York serif, 34pt
              Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  AppStrings.chapterBreakHeadline,
                  style: AppTextStyles.impactMilestone,
                ),
              ),
              const SizedBox(height: 16),
              // Sub-copy — New York serif, 20pt
              Text(
                AppStrings.chapterBreakSubcopy,
                style: AppTextStyles.voiceCopyPrimary,
              ),
              const SizedBox(height: 32),
              // Task title — body, SF Pro
              Text(widget.taskTitle, style: AppTextStyles.body),
              // Stake amount (conditional)
              if (widget.stakeAmount != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.chapterBreakStakeLabel}: ${widget.stakeAmount}',
                  style: AppTextStyles.secondary,
                ),
              ],
              const Spacer(),
              // CTA
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: widget.onContinue,
                  child: Text(AppStrings.chapterBreakCta),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
)
```

### iPad Layout — V1 Acceptance Criteria

V1 requires only that the phone layout **does not break** on iPad. No adaptive layout code is needed — Flutter automatically centres the phone layout on iPad. The acceptance criteria that matter:

1. **No broken layouts / no clipped content**: verify by checking that `SafeArea` is used (already present in existing screens) and no widgets use hardcoded pixel widths that would clip on a wider screen.
2. **No crashes on any iPad size**: the stub chapter break screen is simple enough to render on any size. Existing screens already tested via CI.
3. **V1.1 comment in codebase**: add `// TODO(v1.1-ipad):` comments to `app_router.dart` and `app_shell.dart` as specified in the tasks.

**No LayoutBuilder code is added in V1.** The LayoutBuilder and two-column layout is documented via code comments only — "a note in the codebase" per the AC.

### go_router Navigation Pattern

The Chapter Break Screen is a **top-level route** (outside `StatefulShellRoute`), like `/auth/sign-in` and `/farewell`. This means:
- No shell chrome (no tab bar) during the chapter break moment
- Navigate via `context.push('/chapter-break', extra: {...})` so back gesture works
- `onContinue` calls `context.go('/now')` (not `context.pop()`) to ensure clean stack

Existing top-level routes for reference: `/auth/sign-in`, `/auth/2fa-verify`, `/farewell`, `/onboarding`

Source: `apps/flutter/lib/core/router/app_router.dart`

### Triggering Points — V1 Scope

Per AC 1: the Chapter Break Screen triggers on three milestones. V1 implementation scope:

| Trigger | V1 Implementation |
|---|---|
| Task completed | `NowScreen.onComplete` callback (wired in this story) |
| Commitment locked | Stub — Epic 6 (commitment flow not yet built) |
| Missed commitment recovery | Stub — Epic 6/7 (charge flow not yet built) |

Only the "task completed" trigger is wired in this story. The other two triggers are deferred to Epic 6. Add `// TODO(epic-6): trigger chapter break from commitment lock flow` and `// TODO(epic-6): trigger chapter break from missed commitment recovery` comments in `now_screen.dart` to document deferred triggers.

### Typography — New York Serif

The chapter break screen uses New York serif throughout the headline and sub-copy — consistent with "high-stakes emotional moments" rule (UX spec §Typography):
- Headline: `AppTextStyles.impactMilestone` (34pt, regular serif) — same style as impact dashboard milestones
- Sub-copy: `AppTextStyles.voiceCopyPrimary` (20pt, regular serif)
- Task title: `AppTextStyles.body` (17pt, SF Pro — functional info, not emotional copy)

Fonts are resolved via `AppTheme.buildTheme()` using `FontConfig.serifFamily` — no inline `fontFamily` values needed.

Source: `apps/flutter/lib/core/theme/app_text_styles.dart`

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| No Material widgets | `CupertinoButton`, `CupertinoPageScaffold` only | All prior stories |
| No inline strings | All copy in `AppStrings` | All prior stories |
| `withValues(alpha:)` not `withOpacity()` | `withOpacity()` deprecated in Flutter 3.41 | Stories 2.9–2.12 learnings |
| `liveRegion: true` for dynamic banners | Use on Semantics wrapper for in-place updates | Stories 2.11–2.12 learnings |
| `SemanticsService.announce()` for screens appearing without user action | Specifically required for chapter break (UX spec §9.6) | UX design spec |
| `MediaQuery.of(context).disableAnimations` for Reduce Motion | Check once per frame; no app restart required | UX spec §Reduced Motion |
| New York serif for emotional moments | `AppTextStyles.impactMilestone` / `voiceCopyPrimary` | UX spec §Typography |
| `minimumSize: Size.zero` for icon-only CupertinoButton | Not `minSize: 0` | Story 2.10 learning |
| `WidgetsBinding.instance.addPostFrameCallback` | For post-frame side effects (announce, haptic) | Stories 2.10–2.12 patterns |
| build_runner generated files committed | `*.g.dart` / `*.freezed.dart` in version control | All prior stories |

### Test Setup Pattern (All Flutter Widget Tests)

Every test file MUST include in `setUp()`:
```dart
setUp(() {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({'onboarding_completed': true});
});
```

Wrap test widgets in:
```dart
ProviderScope(
  overrides: [...],
  child: CupertinoApp(
    home: ChapterBreakScreen(...),
  ),
)
```

**Never use `MaterialApp` in tests** — use `CupertinoApp`.

### Reduced Motion Test Pattern

```dart
testWidgets('renders immediately without animation when Reduce Motion enabled', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: CupertinoApp(
        home: ChapterBreakScreen(
          taskTitle: 'Test task',
          onContinue: () {},
        ),
      ),
    ),
  );
  await tester.pump(); // single frame — no animation to flush
  expect(find.text(AppStrings.chapterBreakHeadline), findsOneWidget);
});
```

### Timer Flush Pattern in Tests

If any test uses providers with async disposal, flush with:
```dart
await tester.pump(const Duration(milliseconds: 500));
```
This prevents "pending timer" errors in tests with Riverpod dispose timers.

### Accessibility — VoiceOver Reading Order

Per UX spec §9.6 (Chapter Break Screen), VoiceOver reading order must be:
1. Screen heading (headline)
2. Task title and stake amount
3. CTA button ("Keep going")

Achieve this via widget tree order (Flutter reads Semantics nodes in tree order by default). No explicit `Semantics(sortKey:)` needed if the `Column` order matches the reading order above.

### Feature Module Structure

```
apps/
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   ├── l10n/
    │   │   │   └── strings.dart                      ← MODIFY: add 6 new strings
    │   │   └── router/
    │   │       └── app_router.dart                   ← MODIFY: add /chapter-break route + V1.1 comment
    │   └── features/
    │       ├── chapter_break/                        ← NEW feature module
    │       │   ├── domain/
    │       │   │   └── chapter_break_trigger.dart    ← NEW: ChapterBreakTrigger enum
    │       │   └── presentation/
    │       │       └── chapter_break_screen.dart     ← NEW: animated full-screen widget
    │       ├── now/
    │       │   └── presentation/
    │       │       └── now_screen.dart               ← MODIFY: wire onComplete → /chapter-break
    │       └── shell/
    │           └── presentation/
    │               └── app_shell.dart                ← MODIFY: add V1.1 iPad TODO comment
    └── test/
        └── features/
            └── chapter_break/
                └── chapter_break_screen_test.dart    ← NEW
```

### Project Structure Notes

- The chapter_break feature module follows the standard feature-first clean architecture: `lib/features/{feature}/{data,domain,presentation}/`
- No `data/` subdirectory needed for this story — no repository, no DTOs
- The `domain/` subdirectory contains only the `ChapterBreakTrigger` enum for future extensibility when Epic 6 wires the other triggers
- `app_router.g.dart` will be regenerated by build_runner when the route is added — commit the regenerated file

### References

- UX-DR13 (Chapter Break Screen anatomy): `_bmad-output/planning-artifacts/ux-design-specification.md` §9 "Chapter Break Screen"
- UX-DR20 (Motion tokens): `_bmad-output/planning-artifacts/ux-design-specification.md` §"Motion Design System"
- UX-DR35 (iPad acceptability): `_bmad-output/planning-artifacts/ux-design-specification.md` §"Responsive Design — iPad (V1 supported, not optimised)"
- Motion token reduced-motion table: `_bmad-output/planning-artifacts/ux-design-specification.md` §"Reduced Motion"
- Font rules: `_bmad-output/planning-artifacts/ux-design-specification.md` §"Typography — The SF Pro / New York split"
- Feature structure: `_bmad-output/planning-artifacts/architecture.md` §"Flutter feature anatomy"
- Router: `apps/flutter/lib/core/router/app_router.dart`
- AppTextStyles: `apps/flutter/lib/core/theme/app_text_styles.dart`
- Existing disableAnimations pattern: `apps/flutter/lib/features/today/presentation/widgets/today_skeleton.dart:26`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `MediaQuery.of(context)` call in `initState()` — Flutter forbids calling inherited widget lookups in `initState` before the element is fully mounted. Moved `disableAnimations` check to `didChangeDependencies()` with an `_animationStarted` guard to ensure the animation starts exactly once.

### Completion Notes List

- Created `apps/flutter/lib/features/chapter_break/` feature module with `domain/` (ChapterBreakTrigger enum) and `presentation/` (ChapterBreakScreen) subdirectories.
- ChapterBreakScreen is a StatefulWidget with a 50ms FadeTransition + SlideTransition entry animation ("the chapter break" motion token). Reduce Motion via `MediaQuery.disableAnimations` skips to `_controller.value = 1.0` (instant cut). Animation init moved to `didChangeDependencies()` per Flutter best practice.
- Added 6 new constants to AppStrings: `chapterBreakHeadline`, `chapterBreakSubcopy`, `chapterBreakCta`, `chapterBreakVoiceOverAnnounce`, `chapterBreakTaskLabel`, `chapterBreakStakeLabel`.
- `/chapter-break` top-level GoRoute added to `app_router.dart` before `StatefulShellRoute`, with V1.1 iPad TODO comment. `app_router.g.dart` regenerated via build_runner.
- NowScreen `onComplete` now calls `context.push('/chapter-break', ...)` after completing the task (uses `context.push` not `context.go` for back-gesture support).
- `TODO(v1.1-ipad)` comment added to `AppShell` class doc comment with `LayoutBuilder` breakpoint upgrade path (600pt two-column layout).
- 10 widget tests written and passing: headline, sub-copy, task title, stake amount shown/hidden, CTA label, CTA callback, liveRegion semantics, no Material widgets, reduced motion instant render.
- Full test suite: 0 failures, 0 regressions.

### File List

- apps/flutter/lib/features/chapter_break/domain/chapter_break_trigger.dart (NEW)
- apps/flutter/lib/features/chapter_break/presentation/chapter_break_screen.dart (NEW)
- apps/flutter/lib/core/l10n/strings.dart (MODIFIED)
- apps/flutter/lib/core/router/app_router.dart (MODIFIED)
- apps/flutter/lib/core/router/app_router.g.dart (REGENERATED)
- apps/flutter/lib/features/now/presentation/now_screen.dart (MODIFIED)
- apps/flutter/lib/features/shell/presentation/app_shell.dart (MODIFIED)
- apps/flutter/test/features/chapter_break/chapter_break_screen_test.dart (NEW)
- _bmad-output/implementation-artifacts/sprint-status.yaml (MODIFIED)

## Change Log

- 2026-03-31: Story 2.13 implemented — ChapterBreakScreen widget with 50ms fade+slide entry animation and Reduce Motion support; ChapterBreakTrigger enum; /chapter-break go_router route; NowScreen wired to push /chapter-break on task completion; V1.1 iPad TODO comments in AppShell and app_router; 6 new AppStrings constants; 10 new widget tests; app_router.g.dart regenerated.
