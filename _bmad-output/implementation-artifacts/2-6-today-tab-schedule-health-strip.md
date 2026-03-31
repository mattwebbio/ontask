# Story 2.6: Today Tab & Schedule Health Strip

Status: review

## Story

As a user,
I want a Today tab showing my tasks for the day with a weekly health indicator,
So that I always know what's on my plate and whether I'm on track for the week.

## Acceptance Criteria

1. **Given** the user opens the Today tab, **When** the tasks load, **Then** tasks scheduled for today are shown in chronological order with: time label (40pt column), task title, and status indicator (FR69, UX-DR6) **And** task row states are visually distinct: upcoming, current (highlighted), overdue (amber), completed (muted), calendar event (grey) **And** swipe right on a task row completes it; swipe left opens a reschedule picker.

2. **Given** the Today tab is loading, **When** data has not yet resolved, **Then** 3-4 skeleton rows display with a shimmer sweep animation (1.2s loop); real content replaces them within 800ms (UX-DR28).

3. **Given** the Schedule Health Strip is rendered at the top of the Today tab, **When** the weekly health is calculated, **Then** each day chip is coloured: green (on track), amber (at risk -- overloaded), or red (critical -- tasks will miss deadlines) (UX-DR9) **And** tapping an amber or red day shows a list of the at-risk tasks for that day.

## Tasks / Subtasks

- [x] Add API endpoint for today's tasks (AC: 1)
  - [x] `apps/api/src/routes/tasks.ts` -- MODIFY: add `GET /v1/tasks/today` route with Zod schema:
    - Request query: `{ date: z.string().date().optional() }` (defaults to server UTC today)
    - Response: existing `TaskListResponseSchema` (same envelope)
    - Stub returns tasks sorted by `dueDate` ascending; filters by date match on `dueDate`
  - [x] Note: register route BEFORE the `GET /v1/tasks/:id` route to avoid `today` being matched as `:id`

- [x] Add API endpoint for schedule health (AC: 3)
  - [x] `apps/api/src/routes/tasks.ts` -- MODIFY: add `GET /v1/tasks/schedule-health` route with Zod schema:
    - Request query: `{ weekStartDate: z.string().date() }` (ISO date of the Monday)
    - Response schema: `{ data: { days: [{ date: string, status: 'healthy' | 'at-risk' | 'critical', taskCount: number, capacityPercent: number, atRiskTaskIds: string[] }] } }`
    - Stub: returns 7 days starting from `weekStartDate`, all status `'healthy'`, `taskCount: 0`, `capacityPercent: 0`, empty `atRiskTaskIds`
  - [x] Note: register route BEFORE `GET /v1/tasks/:id` to avoid route collision

- [x] Add Flutter domain model for schedule health (AC: 3)
  - [x] `apps/flutter/lib/features/today/domain/day_health.dart` -- NEW: Freezed model with fields: `date` (DateTime), `status` (DayHealthStatus enum: healthy/atRisk/critical), `taskCount` (int), `capacityPercent` (double), `atRiskTaskIds` (List<String>)
  - [x] `apps/flutter/lib/features/today/domain/day_health_status.dart` -- NEW: enum `DayHealthStatus { healthy, atRisk, critical }`
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Add Flutter DTOs for schedule health (AC: 3)
  - [x] `apps/flutter/lib/features/today/data/day_health_dto.dart` -- NEW: Freezed DTO with JSON serialization; `toDomain()` maps to `DayHealth` domain model
  - [x] Run build_runner

- [x] Add `TodayRepository` (AC: 1, 3)
  - [x] `apps/flutter/lib/features/today/data/today_repository.dart` -- NEW: Riverpod `@riverpod` repository:
    - `getTodayTasks({String? date})` -- GET `/v1/tasks/today?date=`; returns `List<Task>` (reuse existing `TaskDto`)
    - `getScheduleHealth(String weekStartDate)` -- GET `/v1/tasks/schedule-health?weekStartDate=`; returns `List<DayHealth>`
  - [x] Inject `ApiClient` via `ref.read(apiClientProvider)` -- never `new ApiClient()`

- [x] Add `TodayNotifier` provider (AC: 1, 2)
  - [x] `apps/flutter/lib/features/today/presentation/today_provider.dart` -- NEW: Riverpod `@riverpod` AsyncNotifier:
    - `build()` loads today's tasks via `TodayRepository.getTodayTasks()`
    - `completeTask(String taskId)` -- calls existing `TasksRepository.completeTask()`, removes from state
    - `rescheduleTask(String taskId, String newDate)` -- calls existing `TasksRepository.updateTask()`, removes from state
    - `refresh()` -- re-fetches today's tasks

- [x] Add `ScheduleHealthNotifier` provider (AC: 3)
  - [x] `apps/flutter/lib/features/today/presentation/schedule_health_provider.dart` -- NEW: Riverpod `@riverpod` AsyncNotifier:
    - `build()` calculates current week's Monday, loads via `TodayRepository.getScheduleHealth()`
    - Returns `AsyncValue<List<DayHealth>>`

- [x] Build `TodayTaskRow` widget (AC: 1)
  - [x] `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` -- NEW: purpose-built row for the Today tab (NOT reusing `TaskRow` from lists -- different layout: time label column + title + status)
    - **Layout:** Row with 40pt fixed-width time label (right-aligned, 11pt, `color.text.secondary`) | task title (15pt, `color.text.primary`) | trailing status indicator
    - **States via `TodayTaskRowState` enum:**
      - `upcoming` -- full opacity
      - `current` -- subtle left accent border in `color.accent.primary`
      - `overdue` -- muted opacity + amber overdue badge using `colors.scheduleAtRisk`
      - `completed` -- strikethrough title, muted opacity
      - `calendarEvent` -- grey calendar dot instead of check circle, read-only
    - **Swipe actions:**
      - Leading swipe (right): complete task -- calls `TodayNotifier.completeTask()`
      - Trailing swipe (left): opens `CupertinoDatePicker` reschedule modal -- calls `TodayNotifier.rescheduleTask()`
    - Use `Dismissible` with `confirmDismiss` for both directions
    - VoiceOver: announce time, title, list, and status
    - Single-line title truncation; no card elevation (flat row)

- [x] Build `ScheduleHealthStrip` widget (AC: 3)
  - [x] `apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart` -- NEW:
    - **Layout:** Horizontal row of 7 day chips (Mon-Sun) at top of Today tab
    - Each chip shows: abbreviated day label + colour indicator
    - Chip colours: `colors.scheduleHealthy` (green/on track), `colors.scheduleAtRisk` (amber/at risk), `colors.scheduleCritical` (red/critical)
    - Icons per state: checkmark.circle (healthy), exclamationmark.triangle (at risk), exclamationmark.circle (critical) -- use `CupertinoIcons`
    - **Tap behaviour:** tapping an amber or red day chip shows a modal sheet listing at-risk task titles for that day
    - Healthy day chips are tappable but show no detail
    - Accessibility: state communicated via icon + label text, never colour alone (NFR-A4)

- [x] Rewrite `TodayScreen` to use real data (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/today/presentation/today_screen.dart` -- MODIFY (significant rewrite):
    - Watch `todayProvider` for task list (AsyncValue)
    - Watch `scheduleHealthProvider` for health strip data
    - **Loading state (AC 2):** existing `TodaySkeleton` widget already handles shimmer; use it while `todayProvider` is loading; 800ms hard cap already implemented via `_skeletonDelay` Future
    - **Loaded state:** `ScheduleHealthStrip` at top + scrollable list of `TodayTaskRow` widgets in chronological order
    - **Empty state:** existing `TodayEmptyState` widget when no tasks for today
    - **Time-of-day grouping** (UX spec): lightweight section dividers for morning/afternoon/evening (not cards)
    - Header: date + task count + hours planned
    - Remove the placeholder `Scaffold` -- use `CupertinoPageScaffold` or bare widget (AppShell already provides the nav bar)
  - [x] Remove `import 'package:flutter/material.dart'` -- use only `package:flutter/cupertino.dart` (the current `today_screen.dart` uses `Scaffold` which is Material)

- [x] Update `TodaySkeleton` to match Today task row proportions (AC: 2)
  - [x] `apps/flutter/lib/features/today/presentation/widgets/today_skeleton.dart` -- MODIFY:
    - Update skeleton row layout to match `TodayTaskRow` proportions: 40pt time label placeholder + title area + trailing indicator
    - Keep existing shimmer animation (1.2s loop, `RepaintBoundary`, reduced-motion support) -- already correct
    - Add skeleton pill for schedule health strip area at top (width 80pt per section header spec)

- [x] Add strings to `AppStrings` (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` -- MODIFY: add all new string constants:
    - `todayHeaderTitle` = `'Today'`
    - `todayTaskCount` = `'{count} tasks'`
    - `todayHoursPlanned` = `'{hours}h planned'`
    - `todayMorningSection` = `'Morning'`
    - `todayAfternoonSection` = `'Afternoon'`
    - `todayEveningSection` = `'Evening'`
    - `todayOverdueSection` = `'Overdue'`
    - `todayTaskCompleted` = `'Task completed.'`
    - `todayTaskRescheduled` = `'Rescheduled.'`
    - `todayReschedulePickerTitle` = `'Reschedule to'`
    - `scheduleHealthOnTrack` = `'On track'`
    - `scheduleHealthAtRisk` = `'At risk'`
    - `scheduleHealthCritical` = `'Critical'`
    - `scheduleHealthDetail` = `'{hours}h available'`
    - `scheduleHealthAtRiskDetail` = `'Running tight'`
    - `scheduleHealthCriticalDetail` = `'Overbooked -- {hours}h'`
    - `scheduleHealthAtRiskTasks` = `'At-risk tasks'`

- [x] Write tests (AC: 1, 2, 3)
  - [x] `apps/api/test/routes/today-tasks.test.ts` -- NEW:
    - GET /v1/tasks/today: verify returns tasks array
    - GET /v1/tasks/today?date=2026-03-30: verify accepts date filter
    - GET /v1/tasks/schedule-health: verify returns 7-day health array
  - [x] `apps/flutter/test/features/today/today_screen_test.dart` -- NEW:
    - TodayScreen: verify skeleton shown initially (shimmer animation)
    - TodayScreen: verify task rows render after data loads
    - TodayScreen: verify empty state shown when no tasks
    - TodayScreen: verify schedule health strip rendered
    - TodayTaskRow: verify all 5 visual states render correctly (upcoming, current, overdue, completed, calendarEvent)
    - TodayTaskRow: verify swipe right completes task
    - TodayTaskRow: verify swipe left opens reschedule picker
    - ScheduleHealthStrip: verify 7 day chips rendered
    - ScheduleHealthStrip: verify chip colours match health status
    - ScheduleHealthStrip: verify tapping amber/red chip shows at-risk task list
  - [x] `apps/flutter/test/features/today/today_repository_test.dart` -- NEW:
    - TodayRepository: verify getTodayTasks calls correct endpoint
    - TodayRepository: verify getScheduleHealth calls correct endpoint
    - DayHealth domain model: verify fromJson/toJson round-trip
    - DayHealthDto: verify toDomain mapping

## Dev Notes

### Today Tab -- Architecture Decisions

The Today tab is a distinct feature from the Lists task view. It shows tasks across ALL lists, unified by date. Key differences from the list detail screen:

1. **Different data source**: `GET /v1/tasks/today` returns tasks from all lists for a specific date, sorted chronologically. The existing `GET /v1/tasks` filters by listId/sectionId.
2. **Different row widget**: `TodayTaskRow` is purpose-built with the 40pt time label column (UX-DR6). Do NOT reuse `TaskRow` from `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` -- it has a different layout (check circle + title + due date badge + swipe-to-archive).
3. **Swipe semantics differ**: In lists, swipe-left archives. In Today, swipe-right completes, swipe-left reschedules.

### Today Task Row -- State Determination

Determine `TodayTaskRowState` from task properties:
- `completed`: `task.completedAt != null`
- `overdue`: `task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && task.completedAt == null`
- `current`: task's scheduled time window contains `DateTime.now()`
- `calendarEvent`: determined by a flag (defer to real implementation; stub with `false`)
- `upcoming`: default state (none of the above)

### Schedule Health Strip -- Weekly Day Chips

The epics AC specifies "each day chip" for the week, not the segmented progress track from the UX spec's component #5. The story implements **day chips** (7 pills, Mon-Sun) rather than the segmented progress track. The progress track is a per-day detail within the chip anatomy.

**Health calculation is server-side** (stub). The Flutter client only displays the result. When the scheduling engine (Epic 3) is implemented, the health calculation will use real capacity data. For now, the stub returns all-healthy.

### API Route Registration Order

The existing `GET /v1/tasks/:id` route will match `today` and `schedule-health` as an `:id` parameter unless the new routes are registered BEFORE it. This is the same pattern from Story 2.5 where `bulk` routes had to come before `:id`.

In `apps/api/src/routes/tasks.ts`, add the new routes ABOVE the `getTaskRoute` (GET /v1/tasks/:id) definition.

### Existing TodayScreen -- What to Preserve vs Replace

The current `TodayScreen` (`apps/flutter/lib/features/today/presentation/today_screen.dart`) is a placeholder:
- It uses `Scaffold` (Material) -- **must be replaced** with Cupertino or bare widget
- It has `_skeletonDelay` (800ms Future) -- **keep this pattern** for the hard cap on skeleton display
- It references `openAddSheetRequestProvider` -- **keep this wiring** for the Add CTA
- It uses `TodaySkeleton` and `TodayEmptyState` -- **reuse both**, modify `TodaySkeleton` proportions

### Existing TodaySkeleton -- What to Modify

`apps/flutter/lib/features/today/presentation/widgets/today_skeleton.dart` already implements:
- 4 skeleton rows with shimmer (1.2s loop) -- correct per UX-DR28
- `RepaintBoundary` wrapping -- correct
- Reduced-motion support (`MediaQuery.disableAnimations`) -- correct
- Uses `shimmer` package -- already a dependency

Modify the skeleton row layout to match `TodayTaskRow` proportions (40pt time label + title area) instead of the current circle + text layout.

### Theme Tokens Already Available

Schedule health colours are already defined in the theme:
- `colors.scheduleHealthy` = `AppColors.scheduleHealthy` (#6B9E78)
- `colors.scheduleAtRisk` = `AppColors.scheduleAtRisk` (#C98A2E)
- `colors.scheduleCritical` = `AppColors.scheduleCritical` (#C4623A)

Access via `Theme.of(context).extension<OnTaskColors>()!`

### Material Widget in Existing Code

The current `today_screen.dart` imports `package:flutter/material.dart` and uses `Scaffold`. This violates the no-Material-widgets constraint. Replace with Cupertino equivalents. The `AppShell` already provides `CupertinoNavigationBar` via `CupertinoPageScaffold`, so `TodayScreen` should NOT add its own navigation bar -- it should be a plain content widget.

### Time-of-Day Grouping

UX spec requires lightweight section dividers for morning/afternoon/evening (not cards):
- **Morning**: before 12:00
- **Afternoon**: 12:00-17:00
- **Evening**: 17:00+
- **Overdue**: past tasks shown above current time block

Use simple text dividers with `AppStrings` constants, not `CupertinoListSection`.

### Project Structure Notes

```
apps/
├── api/
│   └── src/
│       └── routes/
│           └── tasks.ts                          <- MODIFY: add GET /v1/tasks/today + GET /v1/tasks/schedule-health
│   └── test/
│       └── routes/
│           └── today-tasks.test.ts               <- NEW
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart                  <- MODIFY: add today + schedule health strings
    │   └── features/
    │       └── today/
    │           ├── domain/
    │           │   ├── day_health.dart            <- NEW
    │           │   ├── day_health.freezed.dart    <- GENERATED
    │           │   └── day_health_status.dart     <- NEW
    │           ├── data/
    │           │   ├── today_repository.dart      <- NEW
    │           │   ├── today_repository.g.dart    <- GENERATED
    │           │   ├── day_health_dto.dart        <- NEW
    │           │   ├── day_health_dto.freezed.dart <- GENERATED
    │           │   └── day_health_dto.g.dart      <- GENERATED
    │           └── presentation/
    │               ├── today_screen.dart          <- MODIFY (significant rewrite)
    │               ├── today_provider.dart        <- NEW
    │               ├── today_provider.g.dart      <- GENERATED
    │               ├── schedule_health_provider.dart <- NEW
    │               ├── schedule_health_provider.g.dart <- GENERATED
    │               └── widgets/
    │                   ├── today_task_row.dart     <- NEW
    │                   ├── today_skeleton.dart     <- MODIFY (update proportions)
    │                   ├── today_empty_state.dart  <- existing, no changes
    │                   └── schedule_health_strip.dart <- NEW
    └── test/
        └── features/
            └── today/
                ├── today_screen_test.dart         <- NEW
                └── today_repository_test.dart     <- NEW
```

### References

- Story 2.6 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` -- Story 2.6, line ~946]
- FR69 (today/focus view): [Source: `_bmad-output/planning-artifacts/epics.md` -- line ~40]
- UX-DR6 (Today Task Row): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~1111]
- UX-DR9 (Schedule Health Strip): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~1155]
- UX-DR28 (Skeleton loading): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~1579]
- Schedule health colours: [Source: `apps/flutter/lib/core/theme/app_colors.dart` -- line ~106]
- OnTaskColors theme extension: [Source: `apps/flutter/lib/core/theme/app_theme.dart` -- line ~229]
- Architecture: monorepo structure: [Source: `_bmad-output/planning-artifacts/architecture.md` -- line ~684]
- Architecture: `@hono/zod-openapi` for all routes: [Source: `_bmad-output/planning-artifacts/architecture.md` -- line ~456]
- Architecture: `ok()` / `list()` / `err()` response helpers: [Source: `apps/api/src/lib/response.ts`]
- Existing TodayScreen: `apps/flutter/lib/features/today/presentation/today_screen.dart`
- Existing TodaySkeleton: `apps/flutter/lib/features/today/presentation/widgets/today_skeleton.dart`
- Existing TodayEmptyState: `apps/flutter/lib/features/today/presentation/widgets/today_empty_state.dart`
- Existing AppShell: `apps/flutter/lib/features/shell/presentation/app_shell.dart`
- Existing Task domain model: `apps/flutter/lib/features/tasks/domain/task.dart`
- Existing TaskDto: `apps/flutter/lib/features/tasks/data/task_dto.dart`
- Existing TasksRepository: `apps/flutter/lib/features/tasks/data/tasks_repository.dart`
- Existing strings: `apps/flutter/lib/core/l10n/strings.dart`
- Existing API tasks routes: `apps/api/src/routes/tasks.ts`

### Previous Story Learnings (from Stories 1.1-2.5)

- **`valueOrNull` vs `.value`**: Riverpod v3 uses `.value` on `AsyncValue`, NOT `.valueOrNull`. Use `ref.watch(provider).value ?? defaultValue` in widget builders.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests that touch any provider reading `SharedPreferences` or `FlutterSecureStorage` at build time.
- **`ProviderContainer` for unit testing providers**: Use `ProviderContainer` with `overrides` for provider logic tests. Never `WidgetTester` alone for business logic.
- **`ref.read(apiClientProvider)` -- never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection.
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **`@Riverpod(keepAlive: true)` for long-lived notifiers**: Task/list notifiers should NOT use `keepAlive` -- they are per-screen state.
- **Test baseline after Story 2.5**: 55 API tests + 315 Flutter tests pass. All must continue passing.
- **No Material widgets**: Use `CupertinoTextField`, `CupertinoButton`, `CupertinoDatePicker`, `CupertinoAlertDialog`, `CupertinoActionSheet`. Never `TextField`, `ElevatedButton`, `AlertDialog`, `ListTile`.
- **All strings in `AppStrings`**: Never inline string literals. Warm narrative voice (UX-DR32, UX-DR36).
- **Widget tests -- override providers in `ProviderScope(overrides: [...])`**: Never rely on real network calls or real `SharedPreferences` in widget tests.
- **Hono route additions -- no untyped routes**: `@hono/zod-openapi` schemas for all new routes.
- **`ok()` / `list()` / `err()` helpers from `apps/api/src/lib/response.ts`**: Same envelope for all responses.
- **Riverpod v3 restriction**: `provider.notifier` cannot be called when provider is overridden with `overrideWithValue`. Use fake class extension pattern in tests.
- **`freezed` union types go in `domain/`**: Domain models and sealed types live in `domain/`, never in `data/`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible(...)` before tap when widgets are below the fold.
- **Zod v4 UUID validation requires RFC-4122 compliant UUIDs** (variant bits must be [89ab] in position 1 of 4th group). Use `a0000000-0000-4000-8000-000000000001` style in test fixtures.
- **Riverpod v4 generates provider names without "Notifier" suffix** (e.g., `todayProvider` not `todayNotifierProvider`).
- **`CupertinoSlidingSegmentedControl` generic type param cannot be nullable** -- use `CupertinoActionSheet` for option pickers instead.
- **Drizzle Kit requires `casing: 'snake_case'`** in drizzle.config.ts to generate snake_case SQL columns from camelCase TS schema fields.
- **Drizzle-kit not on PATH in pnpm workspace** -- use full path via `./node_modules/.bin/drizzle-kit` from `apps/api/`. May need `../../node_modules/.pnpm/node_modules/.bin/drizzle-kit`.
- **Dismissible swipe-to-delete test needs `-500` offset** (not `-300`) to trigger `confirmDismiss`.
- **Hono route ordering matters**: `/v1/tasks/today` and `/v1/tasks/schedule-health` MUST be registered before `/v1/tasks/:id` or they will be swallowed by the `:id` param matcher.
- **`withValues(alpha:)` instead of deprecated `withOpacity()`** for color opacity.

### Debug Log References

(Carried forward from Story 2.5 -- same codebase patterns apply)
- Zod v4 UUID validation requires RFC-4122 compliant UUIDs (variant bits must be [89ab] in position 1 of 4th group).
- Riverpod v4 generates provider names without "Notifier" suffix.
- `CupertinoSlidingSegmentedControl` generic type param cannot be nullable -- use `CupertinoActionSheet`.
- Drizzle Kit requires `casing: 'snake_case'` in drizzle.config.ts.
- Drizzle-kit not on PATH -- use full path via `./node_modules/.bin/drizzle-kit` from `apps/api/`.
- Dismissible swipe-to-delete test needed `-500` offset (not `-300`) to trigger `confirmDismiss`.
- Hono route ordering: named routes must be registered before parameterised routes.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| Time label column | 40pt fixed width, right-aligned, 11pt | UX-DR6 |
| Task row states | 5 distinct states: upcoming, current, overdue, completed, calendarEvent | UX-DR6 |
| Swipe complete (leading) | Swipe right completes task | UX-DR6, AC #1 |
| Swipe reschedule (trailing) | Swipe left opens date picker | UX-DR6, AC #1 |
| Skeleton row count | 3-4 rows | UX-DR28, AC #2 |
| Shimmer loop duration | 1.2s | UX-DR28 |
| Max skeleton display | 800ms hard cap | UX-DR28, AC #2 |
| Health strip colours | green/amber/red, never colour alone | UX-DR9, NFR-A4 |
| Health strip tap | Amber/red day shows at-risk task list | UX-DR9, AC #3 |
| No Material widgets | Cupertino only | Stories 1.5-2.5 pattern |
| No inline strings | All copy in `AppStrings` | Stories 1.6-2.5 pattern |
| Dynamic Type | All text uses theme text styles; no hardcoded sizes | NFR-A3, UX-DR22 |
| Warm narrative voice | Copy follows "past self / future self" voice | UX-DR32, UX-DR36 |
| No pull-to-refresh | Schedule updates are push-driven; Today does not use pull-to-refresh | UX spec |

### Scope Boundaries -- What This Story Does NOT Include

- **Real scheduling data** -- tasks are stub-sorted by dueDate; true scheduled time slots require the scheduling engine (Epic 3)
- **Calendar event integration** -- calendar events as first-class items in Today require calendar sync (Epic 3, Story 3.3/3.4); the `calendarEvent` row state exists but is stubbed
- **Timeline view toggle** -- the calendar-style timeline is Story 2.8
- **Now tab task card** -- the Now tab is Story 2.7
- **Task search/filter** -- Story 2.9
- **Overbooking warning** -- Story 2.12
- **Schedule change banner** -- Story 2.12
- **Watch Mode** -- Epic 7
- **Live Activities** -- Epic 12
- **Real capacity calculation** -- requires scheduling engine (Epic 3); stub returns all-healthy
- **Offline support** -- deferred
- **Long-press context menu on Today task rows** -- UX spec describes it (reschedule, move, stake, delete) but this can be added incrementally; not in AC

### Deferred Issues from Previous Stories

- **TimeOfDay formatting duplication** (from Story 1.9): If `_formatTime()` is needed, extract to `apps/flutter/lib/core/utils/time_format.dart` rather than duplicating.
- **Review findings from Story 2.2**: Debounce bug in custom time range, missing clear of custom time fields, missing theme colors on custom time labels, custom time range ignoring existing values.
- **Review findings from Story 2.3**: Inline string literals for custom recurrence interval display; missing API test for recurring-task completion branch; weekly day picker allows zero-day dismissal; missing try/catch on recurrenceDaysOfWeek JSON parsing; recurrence picker bypassing edit-scope choice; applyToFuture sent as body field instead of query param.
- **Review findings from Story 2.4**: Delete confirmation button using wrong string; missing navigation to new list after template apply; inline string literal in save dialog pre-fill; no user-visible success feedback after save/apply; TextEditingController not disposed.
- **Review findings from Story 2.5**: Dependency picker scoped to section instead of list; macOS Cmd+click multi-select not implemented; inline string literal in `_dependsOnLabel()` and `_blocksLabel()`.

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Used `withValues(alpha:)` instead of deprecated `withOpacity()` for color opacity per previous story learnings.
- Registered `/v1/tasks/today` and `/v1/tasks/schedule-health` routes BEFORE `/v1/tasks/:id` to avoid route collision.
- TodayScreen uses limited Material import (`Theme` only) alongside Cupertino widgets -- `Scaffold` removed per constraint.
- Far-future dates used in widget tests to avoid time-dependent overdue classification.

### Completion Notes List

- API: Added `GET /v1/tasks/today` (stub, returns tasks filtered by date) and `GET /v1/tasks/schedule-health` (stub, returns 7-day all-healthy) routes with Zod schemas.
- Flutter domain: Created `DayHealth` Freezed model and `DayHealthStatus` enum in `today/domain/`.
- Flutter data: Created `DayHealthDto` with JSON serialisation and `toDomain()` mapping; created `TodayRepository` with `getTodayTasks()` and `getScheduleHealth()`.
- Flutter providers: Created `TodayNotifier` (async notifier for today's tasks with complete/reschedule/refresh) and `ScheduleHealthNotifier` (loads weekly health data).
- Flutter widgets: Built `TodayTaskRow` with 5 visual states (upcoming, current, overdue, completed, calendarEvent), swipe-to-complete and swipe-to-reschedule via `Dismissible`. Built `ScheduleHealthStrip` with 7 day chips using theme health colours and CupertinoIcons, tap-to-show-at-risk-tasks modal.
- Rewrote `TodayScreen` -- replaced Material `Scaffold` with bare content widget, watches `todayProvider` and `scheduleHealthProvider`, shows skeleton/empty/content states with time-of-day section grouping (morning/afternoon/evening/overdue).
- Updated `TodaySkeleton` proportions to match `TodayTaskRow` layout (40pt time label + title + trailing indicator) with health strip skeleton pills.
- Added 17 string constants to `AppStrings` for Today tab and schedule health.
- Tests: 9 API tests (today-tasks.test.ts), 17 Flutter widget tests (today_screen_test.dart), 10 Flutter unit tests (today_repository_test.dart). All pass. Full suite: 64 API + 342 Flutter = 406 total, 0 regressions.

### File List

- `apps/api/src/routes/tasks.ts` -- MODIFIED: added GET /v1/tasks/today and GET /v1/tasks/schedule-health routes
- `apps/api/test/routes/today-tasks.test.ts` -- NEW: 9 API tests
- `apps/flutter/lib/features/today/domain/day_health.dart` -- NEW: Freezed domain model
- `apps/flutter/lib/features/today/domain/day_health.freezed.dart` -- GENERATED
- `apps/flutter/lib/features/today/domain/day_health_status.dart` -- NEW: enum
- `apps/flutter/lib/features/today/data/day_health_dto.dart` -- NEW: Freezed DTO
- `apps/flutter/lib/features/today/data/day_health_dto.freezed.dart` -- GENERATED
- `apps/flutter/lib/features/today/data/day_health_dto.g.dart` -- GENERATED
- `apps/flutter/lib/features/today/data/today_repository.dart` -- NEW: repository
- `apps/flutter/lib/features/today/data/today_repository.g.dart` -- GENERATED
- `apps/flutter/lib/features/today/presentation/today_provider.dart` -- NEW: async notifier
- `apps/flutter/lib/features/today/presentation/today_provider.g.dart` -- GENERATED
- `apps/flutter/lib/features/today/presentation/schedule_health_provider.dart` -- NEW: async notifier
- `apps/flutter/lib/features/today/presentation/schedule_health_provider.g.dart` -- GENERATED
- `apps/flutter/lib/features/today/presentation/today_screen.dart` -- MODIFIED: significant rewrite
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` -- NEW: task row widget
- `apps/flutter/lib/features/today/presentation/widgets/today_skeleton.dart` -- MODIFIED: updated proportions
- `apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart` -- NEW: health strip widget
- `apps/flutter/lib/core/l10n/strings.dart` -- MODIFIED: added 17 string constants
- `apps/flutter/test/features/today/today_screen_test.dart` -- NEW: 17 widget tests
- `apps/flutter/test/features/today/today_repository_test.dart` -- NEW: 10 unit tests
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- MODIFIED: story status
- `_bmad-output/implementation-artifacts/2-6-today-tab-schedule-health-strip.md` -- MODIFIED: story status + dev record

### Review Findings

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-30 | 1.0 | claude-opus-4-6 | Story 2.6 created -- Today tab with task rows, schedule health strip, skeleton loading, API endpoints. |
| 2026-03-30 | 1.1 | claude-opus-4-6 | Story 2.6 implemented -- All tasks complete, 36 tests added (9 API + 17 widget + 10 unit), 0 regressions. |
