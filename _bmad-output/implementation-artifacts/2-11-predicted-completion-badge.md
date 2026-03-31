# Story 2.11: Predicted Completion Badge

Status: in-progress

## Story

As a user,
I want to see a predicted completion date on any task, section, or list,
So that I know whether my current workload is realistic before deadlines sneak up on me.

## Acceptance Criteria

1. **Given** a task, section, or list is shown **When** the prediction is available **Then** an inline date badge shows the predicted completion date (FR6, UX-DR17) **And** the badge is green if the prediction is before the due date, amber if it's close, and red if it will miss the deadline

2. **Given** the user taps the Predicted Completion Badge **When** the detail opens **Then** the forecast reasoning is shown: tasks remaining, estimated durations, available time windows **And** the reasoning loads within 1 second (NFR-P5)

3. **Given** tasks are completed or rescheduled **When** the schedule is recalculated **Then** the badge updates in real time without requiring a manual refresh

## Tasks / Subtasks

- [x] Add prediction API endpoints (AC: 1, 2, 3)
  - [x] `apps/api/src/routes/tasks.ts` -- MODIFY: add `GET /v1/tasks/{id}/prediction` route:
    - Route MUST be registered BEFORE `GET /v1/tasks/{id}` in the file (Hono route ordering rule)
    - Path param: `id` (UUID)
    - Response schema `taskPredictionSchema`:
      ```ts
      const taskPredictionSchema = z.object({
        taskId: z.string().uuid(),
        predictedDate: z.string().datetime().nullable(),
        status: z.enum(['on_track', 'at_risk', 'behind', 'unknown']),
        tasksRemaining: z.number().int(),
        estimatedMinutesRemaining: z.number().int(),
        availableWindowsCount: z.number().int(),
        reasoning: z.string(),
      })
      ```
    - Use `ok()` response helper
    - Stub: return a plausible stub prediction — `status: 'on_track'`, `predictedDate` = 7 days from now, `tasksRemaining: 3`, `estimatedMinutesRemaining: 90`, `availableWindowsCount: 5`, `reasoning: 'At current pace, this task will be completed before its due date.'`
    - 404 if task ID not found (stub: always return data for valid UUID)
  - [x] `apps/api/src/routes/lists.ts` -- MODIFY: add `GET /v1/lists/{id}/prediction` route:
    - Route MUST be registered BEFORE `GET /v1/lists/{id}` (Hono route ordering rule — check existing route order in this file)
    - Path param: `id` (UUID)
    - Response schema: same `listPredictionSchema` shape as task prediction but with `listId` instead of `taskId`
    - Stub: `status: 'at_risk'`, `predictedDate` = 14 days from now, `tasksRemaining: 12`, `estimatedMinutesRemaining: 420`, `availableWindowsCount: 8`, `reasoning: 'Some tasks in this list may be tight given current available time windows.'`
  - [x] `apps/api/src/routes/sections.ts` -- MODIFY: add `GET /v1/sections/{id}/prediction` route:
    - Route MUST be registered BEFORE any `GET /v1/sections/{id}` parameterised route
    - Same prediction schema shape with `sectionId` instead of `taskId`
    - Stub: `status: 'behind'`, `predictedDate` = 30 days from now, `tasksRemaining: 7`, `estimatedMinutesRemaining: 300`, `availableWindowsCount: 4`, `reasoning: 'At current pace, this section will miss its target date.'`
  - [x] `apps/api/test/routes/prediction.test.ts` -- NEW:
    - GET /v1/tasks/{id}/prediction: verify returns 200 with prediction envelope
    - GET /v1/tasks/{id}/prediction: verify `status` is one of on_track/at_risk/behind/unknown
    - GET /v1/tasks/{id}/prediction: verify `predictedDate` is valid datetime or null
    - GET /v1/tasks/{id}/prediction: verify `reasoning` string is non-empty
    - GET /v1/lists/{id}/prediction: verify returns 200 with list prediction
    - GET /v1/sections/{id}/prediction: verify returns 200 with section prediction

- [x] Add prediction domain model (AC: 1, 2)
  - [x] `apps/flutter/lib/features/prediction/domain/completion_prediction.dart` -- NEW: freezed model:
    ```dart
    enum PredictionStatus { onTrack, atRisk, behind, unknown }

    @freezed
    abstract class CompletionPrediction with _$CompletionPrediction {
      const factory CompletionPrediction({
        required String entityId,
        required DateTime? predictedDate,
        required PredictionStatus status,
        required int tasksRemaining,
        required int estimatedMinutesRemaining,
        required int availableWindowsCount,
        required String reasoning,
      }) = _CompletionPrediction;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Add prediction data layer (AC: 1, 2)
  - [x] `apps/flutter/lib/features/prediction/data/completion_prediction_dto.dart` -- NEW: DTO:
    - `@freezed` with `fromJson` factory
    - Fields mirror API schema: `entityId` (mapped from `taskId`/`listId`/`sectionId` — use a `fromJson` that accepts all three keys), `predictedDate` (String?), `status` (String), `tasksRemaining`, `estimatedMinutesRemaining`, `availableWindowsCount`, `reasoning`
    - `toDomain()` method: convert `status` string to `PredictionStatus` enum (`'on_track'` → `PredictionStatus.onTrack`, etc.; unknown value → `PredictionStatus.unknown`)
    - `predictedDate` string → `DateTime.tryParse()` (nullable)
  - [x] `apps/flutter/lib/features/prediction/data/prediction_repository.dart` -- NEW: repository:
    - `PredictionRepository(ApiClient _client)` — same constructor injection pattern as `SearchRepository`, `TasksRepository`
    - `Future<CompletionPrediction> fetchTaskPrediction(String taskId)` — GET `/v1/tasks/{taskId}/prediction`
    - `Future<CompletionPrediction> fetchListPrediction(String listId)` — GET `/v1/lists/{listId}/prediction`
    - `Future<CompletionPrediction> fetchSectionPrediction(String sectionId)` — GET `/v1/sections/{sectionId}/prediction`
    - Each method parses response `data` field using `CompletionPredictionDto.fromJson()` then calls `.toDomain()`
    - Riverpod provider: `@riverpod PredictionRepository predictionRepository(Ref ref)` — injects `apiClientProvider`
  - [x] Run build_runner

- [x] Add prediction providers (AC: 1, 2, 3)
  - [x] `apps/flutter/lib/features/prediction/presentation/prediction_provider.dart` -- NEW:
    - `@riverpod Future<CompletionPrediction> taskPrediction(Ref ref, String taskId)` — calls `predictionRepository.fetchTaskPrediction(taskId)`. Auto-invalidates when `tasksProvider` changes (use `ref.watch(tasksProvider(listId: null))` if available, or `ref.invalidate(taskPredictionProvider(taskId))` pattern).
    - `@riverpod Future<CompletionPrediction> listPrediction(Ref ref, String listId)` — calls `predictionRepository.fetchListPrediction(listId)`. Auto-invalidates when `listsProvider` or `tasksProvider` changes.
    - `@riverpod Future<CompletionPrediction> sectionPrediction(Ref ref, String sectionId)` — calls `predictionRepository.fetchSectionPrediction(sectionId)`.
    - **Real-time update strategy (stub-appropriate):** For the stub, use `ref.invalidateSelf()` after a 30-second `Timer` in each provider to simulate real-time updates. This satisfies AC3 without requiring WebSockets. In production, the scheduling engine pushes invalidations — the timer approach is forward-compatible.
    - Do NOT use `keepAlive: true` on these providers — they are per-entity and should dispose when the widget unmounts.
  - [x] Run build_runner

- [x] Build PredictionBadge widget (AC: 1, 2)
  - [x] `apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge.dart` -- NEW: the core reusable badge widget:
    - **Anatomy per UX-DR17**: Small pill badge: calendar icon + predicted date text ("On track · Jun 30" / "At risk · Jul 14" / "Behind · Aug 2"). Icon + text — NEVER colour alone (NFR-A4 accessibility rule established by ScheduleHealthStrip).
    - Constructor: `PredictionBadge({required CompletionPrediction prediction, super.key})`
    - **Colour logic**: Use `AppColors.scheduleHealthy` (green), `AppColors.scheduleAtRisk` (amber), `AppColors.scheduleCritical` (red/terracotta) — SAME tokens used by `ScheduleHealthStrip` in `apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart`. Access via `Theme.of(context).extension<OnTaskColors>()!`
    - **Status → colour/icon mapping**:
      - `onTrack` → `AppColors.scheduleHealthy`, `CupertinoIcons.calendar_badge_plus`
      - `atRisk` → `AppColors.scheduleAtRisk`, `CupertinoIcons.exclamationmark_triangle`
      - `behind` → `AppColors.scheduleCritical`, `CupertinoIcons.exclamationmark_circle`
      - `unknown` → `colors.textSecondary`, `CupertinoIcons.calendar` (render "—" as text)
    - **Date formatting**: Use existing month constants from `AppStrings` (`AppStrings.monthJan` etc.) — do NOT import `intl` package or use `DateFormat`. Format as "MMM d" using existing constants. See `apps/flutter/lib/core/l10n/strings.dart` for `monthJan` through `monthDec`.
    - **Layout**: `Row` with icon (14pt) + `SizedBox(width: 4)` + `Text` (use `Theme.of(context).textTheme.bodySmall`)
    - Wrap in `Container` with `BoxDecoration(borderRadius: BorderRadius.circular(12), color: badgeColor.withValues(alpha: 0.12))` and `Padding(all: AppSpacing.xs)` — pill shape
    - **Tap handler**: `GestureDetector` wrapping the pill → calls `_showReasoningSheet(context, prediction)`
    - `_showReasoningSheet`: `showCupertinoModalPopup` presenting a `CupertinoActionSheet`:
      - Title: `AppStrings.predictionBadgeSheetTitle`
      - Message: prediction reasoning text + tasks remaining / estimated minutes / available windows
      - Cancel button: `AppStrings.actionDone`
    - **VoiceOver**: `Semantics(label: '...', button: true)` — label format: `AppStrings.predictionBadgeVoiceOver` template
    - **Stateless** — receives `CompletionPrediction` directly; callers are responsible for async loading

- [x] Build loading/error wrapper widget (AC: 1, 3)
  - [x] `apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge_async.dart` -- NEW: async wrapper:
    - Three variants: `TaskPredictionBadge({required String taskId})`, `ListPredictionBadge({required String listId})`, `SectionPredictionBadge({required String sectionId})`
    - Each is a `ConsumerWidget` that watches the appropriate provider
    - Loading state: `SizedBox(width: 60, height: 20)` shimmer placeholder (use `Container` with `colors.surfaceSecondary` background and `BorderRadius.circular(12)`)
    - Error state: `SizedBox.shrink()` — badge silently absent on error (non-critical UI, never crash)
    - Data state: render `PredictionBadge(prediction: data)`

- [x] Integrate badge into section headers (AC: 1, 3)
  - [x] `apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart` -- MODIFY: add `SectionPredictionBadge` to section header row:
    - In the `Row` children of the section header (line ~69-88), add `SectionPredictionBadge(sectionId: widget.section.id)` as a trailing widget after the `Expanded` title
    - Wrap in `Padding(padding: EdgeInsets.only(right: AppSpacing.sm))` to maintain spacing

- [x] Integrate badge into list header (AC: 1, 3)
  - [x] `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart` -- MODIFY: add `ListPredictionBadge` to list navigation bar or list header area:
    - Add `ListPredictionBadge(listId: widget.listId)` below the `CupertinoNavigationBar`, above the first section/task content
    - Placement: in the `CustomScrollView` or `SliverList` header area, not inside the navigation bar (navigation bar space is constrained)
    - Wrap in `Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm))`

- [x] Integrate badge into task rows (AC: 1, 3)
  - [x] `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` -- MODIFY: add `TaskPredictionBadge` as an optional trailing element:
    - Add optional `showPrediction` parameter (default `false`) to `TaskRow`
    - When `showPrediction: true`, show `TaskPredictionBadge(taskId: task.id)` in the trailing area of the row
    - Default to `false` to avoid adding network calls to every task row — the badge is shown when explicitly requested (list detail view only, not search results or Today tab)

- [x] Add strings to AppStrings (AC: 1, 2)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` -- MODIFY: add new string constants:
    - `predictionBadgeOnTrack` = `'On track · {date}'`
    - `predictionBadgeAtRisk` = `'At risk · {date}'`
    - `predictionBadgeBehind` = `'Behind · {date}'`
    - `predictionBadgeUnknown` = `'—'`
    - `predictionBadgeSheetTitle` = `'Forecast'`
    - `predictionBadgeTasksRemaining` = `'{count} tasks remaining'`
    - `predictionBadgeEstimatedTime` = `'{minutes} min estimated'`
    - `predictionBadgeAvailableWindows` = `'{count} time windows available'`
    - `predictionBadgeVoiceOver` = `'Predicted completion {status}. {date}. Tap for forecast reasoning.'`
    - `predictionBadgeVoiceOverUnknown` = `'Predicted completion unknown. Tap for forecast reasoning.'`

- [x] Write tests (AC: 1, 2, 3)
  - [x] `apps/flutter/test/features/prediction/prediction_badge_test.dart` -- NEW:
    - PredictionBadge: verify on_track renders green colour and calendar icon
    - PredictionBadge: verify at_risk renders amber colour and warning icon
    - PredictionBadge: verify behind renders red colour and critical icon
    - PredictionBadge: verify unknown renders "—" text and grey colour
    - PredictionBadge: verify date is formatted as "MMM d" (e.g. "Apr 7")
    - PredictionBadge: verify tapping opens reasoning sheet
    - PredictionBadge: verify reasoning sheet shows tasks remaining count
    - PredictionBadge: verify VoiceOver label includes status and date
    - PredictionBadgeAsync (TaskPredictionBadge): verify loading state renders shimmer placeholder
    - PredictionBadgeAsync (TaskPredictionBadge): verify error state renders SizedBox.shrink
    - PredictionBadgeAsync (TaskPredictionBadge): verify data state renders PredictionBadge
  - [x] `apps/flutter/test/features/prediction/prediction_provider_test.dart` -- NEW:
    - taskPredictionProvider: verify calls repository with correct taskId
    - listPredictionProvider: verify calls repository with correct listId
    - sectionPredictionProvider: verify calls repository with correct sectionId
    - CompletionPredictionDto: verify `'on_track'` → `PredictionStatus.onTrack` conversion
    - CompletionPredictionDto: verify `'at_risk'` → `PredictionStatus.atRisk` conversion
    - CompletionPredictionDto: verify `'behind'` → `PredictionStatus.behind` conversion
    - CompletionPredictionDto: verify unknown status string → `PredictionStatus.unknown`
    - CompletionPredictionDto: verify `predictedDate` null when API returns null

## Dev Notes

### UX Specification (UX-DR17)

From the UX design doc, the badge anatomy is:

> Small pill badge: calendar icon + predicted date ("On track · Jun 30" / "At risk · Jul 14" / "Behind · Aug 2"). Colour follows schedule health token family. Icon + text — never colour alone.

**States:**
- On track (`AppColors.scheduleHealthy` = `Color(0xFF6B9E78)`, green sage)
- At risk (`AppColors.scheduleAtRisk` = `Color(0xFFC98A2E)`, amber)
- Behind (`AppColors.scheduleCritical` = `Color(0xFFC4623A)`, terracotta)
- Unknown (insufficient data — show "—", use `textSecondary` colour)

**Placement:** List header row (trailing) · Section header row (trailing). Tappable — opens brief explanation popover.

**Key UX principle:** Honest and calm — never falsely optimistic.

### Reuse Existing Colour Tokens — Do NOT Reinvent

The `ScheduleHealthStrip` widget (`apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart`) already uses the exact same colour/icon/status pattern:

```dart
// Pattern to reuse EXACTLY in PredictionBadge:
final colors = Theme.of(context).extension<OnTaskColors>()!;
// colors.scheduleHealthy — green
// colors.scheduleAtRisk  — amber
// colors.scheduleCritical — red
```

Copy this pattern verbatim — same semantic tokens, same `OnTaskColors` extension access.

### Date Formatting — Use Existing Month Strings

Do NOT add `intl` package or `DateFormat`. Use existing `AppStrings.monthJan` through `AppStrings.monthDec` constants in `apps/flutter/lib/core/l10n/strings.dart`. Example helper:

```dart
String _formatDate(DateTime date) {
  final months = [
    AppStrings.monthJan, AppStrings.monthFeb, AppStrings.monthMar,
    AppStrings.monthApr, AppStrings.monthMay, AppStrings.monthJun,
    AppStrings.monthJul, AppStrings.monthAug, AppStrings.monthSep,
    AppStrings.monthOct, AppStrings.monthNov, AppStrings.monthDec,
  ];
  return '${months[date.month - 1]} ${date.day}';
}
```

### Real-Time Updates — Polling Strategy for Stub

AC3 requires badge updates "without manual refresh". The real production implementation uses the scheduling engine to push invalidations. For this stub story, implement a self-invalidating timer in each prediction provider:

```dart
@riverpod
Future<CompletionPrediction> taskPrediction(Ref ref, String taskId) async {
  // Re-fetch every 30 seconds to simulate real-time in stub
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel); // CRITICAL: cancel on dispose to prevent leaks
  return ref.watch(predictionRepositoryProvider).fetchTaskPrediction(taskId);
}
```

This is the same pattern used by `nowProvider` — check `apps/flutter/lib/features/now/presentation/now_provider.dart` for the existing reference.

### API Route Ordering — Critical

Hono matches routes in registration order. The `/prediction` sub-resource routes MUST be registered BEFORE the `/{id}` parameterised routes. In each router file:

```ts
// CORRECT — prediction registered before /{id}
app.openapi(getPredictionRoute, handler)  // GET /v1/tasks/:id/prediction
app.openapi(getTaskRoute, handler)        // GET /v1/tasks/:id

// WRONG — would match "prediction" as a task ID
app.openapi(getTaskRoute, handler)        // GET /v1/tasks/:id  ← BLOCKS prediction
app.openapi(getPredictionRoute, handler)  // never reached
```

Check current route registration order in `apps/api/src/routes/tasks.ts` — the `search` route is already registered before `/{id}` as precedent.

### currentTaskSchema Enrichment Pattern

The prediction response is a separate endpoint rather than enriching `taskSchema`. This is intentional: predictions are expensive to compute and not needed on every task list response. The separate endpoint follows the same `GET /v1/tasks/current` approach used in Story 2.7.

### Hono Route Schema — Nested Resource Pattern

For nested resource routes (`/v1/tasks/{id}/prediction`), use `createRoute` with the path param:

```ts
const getTaskPredictionRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/{id}/prediction',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: z.object({ data: taskPredictionSchema }) } },
      description: 'Task prediction',
    },
  },
})
```

### Feature Module Structure

```
apps/
├── api/
│   └── src/
│       └── routes/
│           ├── tasks.ts          <- MODIFY: add GET /v1/tasks/{id}/prediction
│           ├── lists.ts          <- MODIFY: add GET /v1/lists/{id}/prediction
│           └── sections.ts       <- MODIFY: add GET /v1/sections/{id}/prediction
│   └── test/
│       └── routes/
│           └── prediction.test.ts  <- NEW
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart    <- MODIFY: add prediction strings
    │   └── features/
    │       ├── prediction/         <- NEW feature module
    │       │   ├── data/
    │       │   │   ├── completion_prediction_dto.dart      <- NEW
    │       │   │   ├── completion_prediction_dto.freezed.dart  <- GENERATED
    │       │   │   ├── completion_prediction_dto.g.dart    <- GENERATED
    │       │   │   ├── prediction_repository.dart          <- NEW
    │       │   │   └── prediction_repository.g.dart        <- GENERATED
    │       │   ├── domain/
    │       │   │   ├── completion_prediction.dart          <- NEW
    │       │   │   └── completion_prediction.freezed.dart  <- GENERATED
    │       │   └── presentation/
    │       │       ├── prediction_provider.dart            <- NEW
    │       │       ├── prediction_provider.g.dart          <- GENERATED
    │       │       └── widgets/
    │       │           ├── prediction_badge.dart           <- NEW (stateless, receives CompletionPrediction)
    │       │           └── prediction_badge_async.dart     <- NEW (async ConsumerWidgets)
    │       ├── lists/
    │       │   └── presentation/
    │       │       ├── list_detail_screen.dart             <- MODIFY: add ListPredictionBadge
    │       │       └── widgets/
    │       │           └── section_widget.dart             <- MODIFY: add SectionPredictionBadge
    │       └── tasks/
    │           └── presentation/
    │               └── widgets/
    │                   └── task_row.dart                   <- MODIFY: add optional showPrediction param
    └── test/
        └── features/
            └── prediction/
                ├── prediction_badge_test.dart              <- NEW
                └── prediction_provider_test.dart           <- NEW
```

### Accessibility — Icon + Colour Required (NFR-A4)

The UX spec explicitly states: "Icon + text — never colour alone." The `ScheduleHealthStrip` establishes this pattern. Each badge state MUST include both a distinct icon AND a colour change. Never rely on colour alone for status communication.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| No Material widgets | `CupertinoActionSheet` for reasoning sheet, `CupertinoButton` if needed | All prior stories |
| No inline strings | All copy in `AppStrings` | All prior stories |
| No `intl` package | Use existing `AppStrings.monthJan`–`monthDec` for date formatting | Project pattern |
| Icon + text | Never colour alone for status (NFR-A4) | UX-DR17, ScheduleHealthStrip |
| 44pt touch target | Badge must be at least 44x44pt tappable area | UX accessibility |
| `withValues(alpha:)` | Never `withOpacity()` — deprecated in Flutter 3.41 | Story 2.9 learnings |
| Stateless badge widget | `PredictionBadge` receives `CompletionPrediction`, no async inside | Clean architecture |
| Separate async wrapper | `TaskPredictionBadge`/`ListPredictionBadge`/`SectionPredictionBadge` as `ConsumerWidget` | Testability |
| Silent error state | Badge returns `SizedBox.shrink()` on error — never crash | UX: non-critical widget |
| `ref.onDispose(timer.cancel)` | ALWAYS cancel timers in `onDispose` to prevent leaks | Story 2.9 review findings |
| Zod v4 UUID test fixtures | Use `a0000000-0000-4000-8000-000000000001` format (RFC-4122, variant bits `[89ab]`) | Story 2.9 learnings |

### Scope Boundaries — What This Story Does NOT Include

- **Actual scheduling engine integration** — stubs return static data. Real computation comes in Epic 3 (Intelligent Scheduling).
- **Push-based real-time updates** — polling timer satisfies AC3 for stub. WebSocket/SSE comes with Epic 3.
- **Prediction on Now tab task card** — the NowTaskCard (`apps/flutter/lib/features/now/presentation/widgets/now_task_card.dart`) is already complex (Stories 2.7, 2.10). Do not add prediction badge to it in this story.
- **Prediction on Today tab rows** — `TodayTaskRow` is in Today tab which is read-only schedule view. Skip it.
- **Prediction on search results** — `SearchResultRow` does not show predictions (search is a quick-lookup context).
- **Prediction on templates** — templates have no scheduling data, so prediction is meaningless.

### Previous Story Learnings (accumulated from Stories 1.1-2.10)

- **`ref.value` not `ref.valueOrNull`**: Riverpod v3 uses `.value` on `AsyncValue`. Pattern: `ref.watch(provider).value ?? default`.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests touching any provider that reads storage at build time.
- **`ref.read(apiClientProvider)` — never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection.
- **build_runner generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output.
- **No Material widgets**: `CupertinoActionSheet`, `CupertinoButton`, `CupertinoDatePicker`, `CupertinoAlertDialog`. Never `AlertDialog`, `ElevatedButton`, `ListTile`. Exception: `AnimatedCrossFade` (from `widgets.dart`) is acceptable.
- **All strings in `AppStrings`**: Never inline string literals.
- **Widget tests — override providers in `ProviderScope(overrides: [...])`**: Never rely on real network calls or real `SharedPreferences` in widget tests.
- **Riverpod v4 generates provider names without "Notifier" suffix**: `predictionRepositoryProvider` not `predictionRepositoryNotifierProvider`.
- **`withValues(alpha:)` not `withOpacity()`**: `withOpacity()` is deprecated in Flutter 3.41.
- **`SemanticsService.announce()` is deprecated in Flutter 3.41**: Use `Semantics(liveRegion: true)` pattern.
- **Hono route ordering**: Named/nested routes BEFORE parameterised routes. ALWAYS.
- **Zod v4 UUID format**: `a0000000-0000-4000-8000-000000000001` (variant bits must be `[89ab]` at position 1 of group 4).
- **`@Riverpod(keepAlive: true)` only for long-lived state**: Per-entity prediction providers do NOT need `keepAlive`.
- **Timer cancellation**: Always `ref.onDispose(timer.cancel)` when using `Timer` in a provider. Story 2.9 review finding: leaked timer if not cancelled.
- **`ref.watch` not `ref.read` for reactive dependencies**: Use `ref.watch(predictionRepositoryProvider)` inside providers, not `ref.read`.
- **Test baseline after Story 2.10**: 83 API tests + 465 Flutter tests pass. All must continue passing.
- **`freezed` union types in `domain/`**: Domain models live in `domain/`, DTOs in `data/`.
- **Drizzle Kit requires `casing: 'snake_case'`** in `drizzle.config.ts`.
- **`find.text()` does not find text inside `RichText/TextSpan`**: Use `find.byType()` or `find.textContaining()`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible()` before tap.

### Open Review Findings from Previous Stories (not yet fixed)

From Story 2.8 (carry forward):
- [ ] [Review][Decision] Touch targets below 44pt minimum for short-duration blocks
- [ ] [Review][Patch] `Paint()` allocation in `paint()`
- [ ] [Review][Patch] `TextStyle` allocations in `paint()`
- [ ] [Review][Patch] `TextSpan` allocations in `paint()`
- [ ] [Review][Patch] `paint.color` mutation corrupts pre-allocated Paint objects
- [ ] [Review][Patch] Mutable `bounds` side-effect inside `paint()`
- [ ] [Review][Patch] Semantic nodes use `Rect.zero` bounds before first paint
- [ ] [Review][Patch] No guard for zero/negative `durationMinutes`
- [ ] [Review][Patch] Tap-on-block test is a no-op
- [ ] [Review][Patch] Hour label VoiceOver string template is misleading

From Story 2.7 (carry forward):
- [ ] [Review][Decision] AC4 Dynamic Island padding — SafeArea vs explicit viewPadding.top
- [ ] [Review][Patch] Missing NowRepository endpoint test
- [ ] [Review][Patch] Timer announcement callback entirely empty
- [ ] [Review][Patch] Force-unwrap `response.data!` in NowRepository

### References

- Story 2.11 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` line ~1065]
- FR6 (predicted completion dates for tasks/sections/lists): [Source: `_bmad-output/planning-artifacts/epics.md` line ~31]
- UX-DR17 (Predicted Completion Badge — anatomy, states, placement): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` line ~1274]
- NFR-P5 (reasoning loads within 1 second): [Source: `_bmad-output/planning-artifacts/epics.md` line ~144]
- Schedule health colours (`scheduleHealthy`, `scheduleAtRisk`, `scheduleCritical`): [Source: `apps/flutter/lib/core/theme/app_colors.dart` lines 106-108]
- `OnTaskColors` extension access pattern: [Source: `apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart`]
- `taskSchema` and existing enrichment pattern: [Source: `apps/api/src/routes/tasks.ts` lines 62-88, 322-331]
- `listSchema` and `sectionSchema`: [Source: `apps/api/src/routes/lists.ts`]
- Hono route ordering precedent (`/search` before `/{id}`): [Source: `apps/api/src/routes/tasks.ts` line ~368]
- `ok()` / `list()` / `err()` response helpers: [Source: `apps/api/src/lib/response.ts`]
- `SectionWidget` (where badge is integrated in section header): [Source: `apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart`]
- `ListDetailScreen` (where list-level badge goes): [Source: `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart`]
- `TaskRow` widget (where per-task badge is added): [Source: `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart`]
- AppStrings month constants: [Source: `apps/flutter/lib/core/l10n/strings.dart`]
- `nowProvider` timer pattern (precedent for self-invalidating): [Source: `apps/flutter/lib/features/now/presentation/now_provider.dart`]
- Timer disposal pattern: [Source: Story 2.9 review finding — timer_cancel on dispose]
- Feature anatomy pattern: [Source: `_bmad-output/planning-artifacts/architecture.md` line ~495]
- Riverpod provider injection: [Source: `_bmad-output/planning-artifacts/architecture.md` line ~567]

### Review Findings

- [ ] [Review][Patch] Inline status strings in `_statusStringForVoiceOver` bypass AppStrings — `'on track'`, `'at risk'`, `'behind'`, `'unknown'` are hardcoded in `prediction_badge.dart:126-132` and injected into the VoiceOver accessibility label. All user-facing strings must be in AppStrings (spec constraint: "No inline literals"). Add `predictionBadgeStatusOnTrack`, `predictionBadgeStatusAtRisk`, `predictionBadgeStatusBehind`, `predictionBadgeStatusUnknown` constants to `AppStrings` and use them in `_statusStringForVoiceOver`. [`apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge.dart:123-134`]
- [ ] [Review][Patch] Missing async state tests for `ListPredictionBadge` and `SectionPredictionBadge` — `prediction_badge_test.dart` only tests `TaskPredictionBadge` for the loading/error/data async states. The spec task list specifies async state tests for the `PredictionBadgeAsync` variants generically. Add equivalent loading, error, and data state tests for `ListPredictionBadge` and `SectionPredictionBadge`. [`apps/flutter/test/features/prediction/prediction_badge_test.dart`]
- [ ] [Review][Patch] DTO `fromJson` silently produces empty `entityId` on unexpected API shape — if all three entity ID keys (`taskId`, `listId`, `sectionId`) are absent, `entityId` defaults to `''` without throwing. This would produce a domain model with an empty entity ID that silently passes through the UI. Add a guard: `if (id.isEmpty) throw FormatException('Missing entity ID in prediction response')`. [`apps/flutter/lib/features/prediction/data/completion_prediction_dto.dart:30`]
- [x] [Review][Defer] `_shimmer` declared as top-level function with leading underscore — leading underscore on a top-level function is unconventional in Dart (it grants library-private visibility, not class-private). Could be a private static method of a helper class. Pre-existing style pattern in this codebase; low risk. [`apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge_async.dart:65`] — deferred, pre-existing convention
- [x] [Review][Defer] Import ordering in `prediction_badge_async.dart` — Material import (`package:flutter/material.dart show Theme`) appears interleaved with local imports rather than in the packages group. Pre-existing style pattern across codebase. [`apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge_async.dart:5`] — deferred, pre-existing convention
- [x] [Review][Defer] `ref.watch` on `predictionRepositoryProvider` in async providers — semantically `ref.read` would be more appropriate for a stable dependency (repository never changes), but `ref.watch` matches the pattern documented in Previous Story Learnings and is functionally correct. [`apps/flutter/lib/features/prediction/presentation/prediction_provider.dart:22,32,42`] — deferred, intentional pattern match to codebase convention

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Removed `part 'completion_prediction_dto.g.dart'` from DTO since custom `fromJson` factory doesn't need json_serializable code generation.
- Fixed test compilation error: added `dart:async` import for `Completer` in prediction_badge_test.dart.
- Simplified SizedBox.shrink error state test to just verify PredictionBadge is absent (not asserting presence of SizedBox.shrink widget, which is unreliable in large widget trees).

### Completion Notes List

- Implemented all 3 prediction API endpoints (tasks, lists, sections) with correct Hono route ordering (sub-resource before parameterised routes).
- Created complete `prediction` feature module: domain model (`CompletionPrediction`, `PredictionStatus`), DTO with multi-key JSON normalisation, repository with Riverpod injection, 3 async providers with 30s self-invalidating timer for AC3 real-time simulation.
- Built `PredictionBadge` (stateless, uses `OnTaskColors` tokens identical to `ScheduleHealthStrip`) and three async wrapper variants (TaskPredictionBadge, ListPredictionBadge, SectionPredictionBadge).
- Integrated `SectionPredictionBadge` into section header row, `ListPredictionBadge` above tasks/sections content in list detail, and optional `showPrediction` parameter in `TaskRow`.
- Added 10 AppStrings constants for badge labels, VoiceOver, and reasoning sheet.
- Generated all freezed/riverpod code via build_runner.
- All tests pass: 89 API tests (6 new prediction tests), 484 Flutter tests (19 new prediction tests).

### File List

- `apps/api/src/routes/tasks.ts` (modified — added GET /v1/tasks/{id}/prediction)
- `apps/api/src/routes/lists.ts` (modified — added GET /v1/lists/{id}/prediction)
- `apps/api/src/routes/sections.ts` (modified — added GET /v1/sections/{id}/prediction)
- `apps/api/test/routes/prediction.test.ts` (new)
- `apps/flutter/lib/features/prediction/domain/completion_prediction.dart` (new)
- `apps/flutter/lib/features/prediction/domain/completion_prediction.freezed.dart` (generated)
- `apps/flutter/lib/features/prediction/data/completion_prediction_dto.dart` (new)
- `apps/flutter/lib/features/prediction/data/completion_prediction_dto.freezed.dart` (generated)
- `apps/flutter/lib/features/prediction/data/prediction_repository.dart` (new)
- `apps/flutter/lib/features/prediction/data/prediction_repository.g.dart` (generated)
- `apps/flutter/lib/features/prediction/presentation/prediction_provider.dart` (new)
- `apps/flutter/lib/features/prediction/presentation/prediction_provider.g.dart` (generated)
- `apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge.dart` (new)
- `apps/flutter/lib/features/prediction/presentation/widgets/prediction_badge_async.dart` (new)
- `apps/flutter/lib/core/l10n/strings.dart` (modified — added prediction badge strings)
- `apps/flutter/lib/features/lists/presentation/widgets/section_widget.dart` (modified — SectionPredictionBadge integration)
- `apps/flutter/lib/features/lists/presentation/list_detail_screen.dart` (modified — ListPredictionBadge integration)
- `apps/flutter/lib/features/tasks/presentation/widgets/task_row.dart` (modified — showPrediction parameter)
- `apps/flutter/test/features/prediction/prediction_badge_test.dart` (new)
- `apps/flutter/test/features/prediction/prediction_provider_test.dart` (new)
- `_bmad-output/implementation-artifacts/2-11-predicted-completion-badge.md` (story file)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status updated)

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-31 | 1.0 | claude-sonnet-4-6 | Story 2.11 created — Predicted Completion Badge with API endpoints, prediction feature module, PredictionBadge widget, section/list/task integration. |
| 2026-03-31 | 1.1 | claude-sonnet-4-6 | Story 2.11 implemented — All AC satisfied. 3 prediction API routes, full prediction feature module, PredictionBadge with OnTaskColors tokens, async wrappers, integration into section/list/task. 89 API tests + 484 Flutter tests all pass. |
