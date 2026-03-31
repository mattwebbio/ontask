# Story 2.12: Schedule Change Banner & Overbooking Warning

Status: review

## Story

As a user,
I want to be notified when my schedule regenerates and warned when I'm overloaded,
So that I can respond to changes before they become missed deadlines.

## Acceptance Criteria

1. **Given** the scheduling engine regenerates while the user is in the Today tab **When** the new schedule differs meaningfully from the current view **Then** an in-app banner appears at the top of the Today tab content area (below navigation bar): "Your schedule has been updated" with a "See what changed" action and a dismiss (×) action (UX-DR18)

2. **Given** the Schedule Change Banner is visible **When** the user taps "See what changed" **Then** a bottom sheet opens showing a diff of moved/removed tasks (task title + old time → new time, or "removed")

3. **Given** the Schedule Change Banner is visible and the user does not interact **When** 8 seconds elapse **Then** the banner auto-dismisses (slides out)

4. **Given** the Today tab loads **When** the schedule is overloaded **Then** an Overbooking Warning banner appears inline in the Today tab **And** the severity is shown: amber for at-risk, red for critical (UX-DR16) **And** the banner uses icon + text — never colour alone (NFR-A4)

5. **Given** the Overbooking Warning banner is shown **When** the user views available actions **Then** three actions are available: Reschedule, Extend deadline, Acknowledge

6. **Given** the Overbooking Warning banner is shown **And** the overloaded task has a stake **When** the user views available actions **Then** an additional action is shown: "Request deadline extension from partner"

7. **Given** the Schedule Change Banner appears **Then** `HapticFeedback.lightImpact()` fires once on banner appearance (UX haptic map)

## Tasks / Subtasks

- [x] Add schedule-change and overbooking API endpoints (AC: 1, 2, 4, 5, 6)
  - [x] `apps/api/src/routes/tasks.ts` — MODIFY: add `GET /v1/tasks/schedule-changes` route:
    - Route MUST be registered BEFORE `GET /v1/tasks/{id}` (Hono route ordering rule — already established)
    - Register AFTER existing named routes: `today`, `schedule-health`, `current`, `search` — before the `/{id}` param routes
    - Query params: none required (stub returns latest change set)
    - Response schema `scheduleChangesSchema`:
      ```ts
      const scheduleChangeItemSchema = z.object({
        taskId: z.string().uuid(),
        taskTitle: z.string(),
        changeType: z.enum(['moved', 'removed']),
        oldTime: z.string().datetime().nullable(),  // null for 'removed' with no prior time
        newTime: z.string().datetime().nullable(),  // null for 'removed'
      })
      const scheduleChangesSchema = z.object({
        hasMeaningfulChanges: z.boolean(),
        changeCount: z.number().int(),
        changes: z.array(scheduleChangeItemSchema),
      })
      ```
    - Response envelope: `z.object({ data: scheduleChangesSchema })`
    - Use `ok()` response helper
    - Stub: return `hasMeaningfulChanges: true`, `changeCount: 2`, two changes:
      - `{ taskId: 'a0000000-0000-4000-8000-000000000001', taskTitle: 'Morning review', changeType: 'moved', oldTime: '<today>T09:00:00.000Z', newTime: '<today>T14:00:00.000Z' }`
      - `{ taskId: 'a0000000-0000-4000-8000-000000000002', taskTitle: 'Team sync prep', changeType: 'removed', oldTime: '<today>T11:00:00.000Z', newTime: null }`
  - [x] `apps/api/src/routes/tasks.ts` — MODIFY: add `GET /v1/tasks/overbooking-status` route:
    - Also BEFORE `/{id}` parameterised routes (same ordering rule)
    - Response schema `overbookingStatusSchema`:
      ```ts
      const overbookedTaskSchema = z.object({
        taskId: z.string().uuid(),
        taskTitle: z.string(),
        hasStake: z.boolean(),
        durationMinutes: z.number().int(),
      })
      const overbookingStatusSchema = z.object({
        isOverbooked: z.boolean(),
        severity: z.enum(['none', 'at_risk', 'critical']),
        capacityPercent: z.number(),
        overbookedTasks: z.array(overbookedTaskSchema),
      })
      ```
    - Response envelope: `z.object({ data: overbookingStatusSchema })`
    - Use `ok()` response helper
    - Stub: `isOverbooked: true`, `severity: 'at_risk'`, `capacityPercent: 115`, `overbookedTasks`:
      - `{ taskId: 'a0000000-0000-4000-8000-000000000001', taskTitle: 'Deep work block', hasStake: true, durationMinutes: 120 }`
  - [x] `apps/api/test/routes/schedule-change.test.ts` — NEW:
    - GET /v1/tasks/schedule-changes: verify returns 200 with changes envelope
    - GET /v1/tasks/schedule-changes: verify `hasMeaningfulChanges` is boolean
    - GET /v1/tasks/schedule-changes: verify `changes` array items have `taskId`, `taskTitle`, `changeType`
    - GET /v1/tasks/schedule-changes: verify `changeType` is one of `moved`/`removed`
    - GET /v1/tasks/overbooking-status: verify returns 200 with overbooking envelope
    - GET /v1/tasks/overbooking-status: verify `severity` is one of `none`/`at_risk`/`critical`
    - GET /v1/tasks/overbooking-status: verify `overbookedTasks` array items have `taskId`, `hasStake`

- [x] Add domain models (AC: 1, 2, 4, 5, 6)
  - [x] `apps/flutter/lib/features/today/domain/schedule_change.dart` — NEW: freezed models:
    ```dart
    enum ScheduleChangeType { moved, removed }

    @freezed
    abstract class ScheduleChangeItem with _$ScheduleChangeItem {
      const factory ScheduleChangeItem({
        required String taskId,
        required String taskTitle,
        required ScheduleChangeType changeType,
        required DateTime? oldTime,
        required DateTime? newTime,
      }) = _ScheduleChangeItem;
    }

    @freezed
    abstract class ScheduleChanges with _$ScheduleChanges {
      const factory ScheduleChanges({
        required bool hasMeaningfulChanges,
        required int changeCount,
        required List<ScheduleChangeItem> changes,
      }) = _ScheduleChanges;
    }
    ```
  - [x] `apps/flutter/lib/features/today/domain/overbooking_status.dart` — NEW: freezed models:
    ```dart
    enum OverbookingSeverity { none, atRisk, critical }

    @freezed
    abstract class OverbookedTask with _$OverbookedTask {
      const factory OverbookedTask({
        required String taskId,
        required String taskTitle,
        required bool hasStake,
        required int durationMinutes,
      }) = _OverbookedTask;
    }

    @freezed
    abstract class OverbookingStatus with _$OverbookingStatus {
      const factory OverbookingStatus({
        required bool isOverbooked,
        required OverbookingSeverity severity,
        required double capacityPercent,
        required List<OverbookedTask> overbookedTasks,
      }) = _OverbookingStatus;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Add data layer DTOs (AC: 1, 2, 4, 5, 6)
  - [x] `apps/flutter/lib/features/today/data/schedule_change_dto.dart` — NEW: `@freezed` DTOs with `fromJson`:
    - `ScheduleChangeItemDto`: fields `taskId`, `taskTitle`, `changeType` (String), `oldTime` (String?), `newTime` (String?)
    - `toDomain()`: convert `changeType` string to `ScheduleChangeType` (`'moved'` → `ScheduleChangeType.moved`, `'removed'` → `ScheduleChangeType.removed`); parse `oldTime`/`newTime` via `DateTime.tryParse()`
    - `ScheduleChangesDto`: fields `hasMeaningfulChanges`, `changeCount`, `changes` (List)
    - `toDomain()` on `ScheduleChangesDto` converts each item
  - [x] `apps/flutter/lib/features/today/data/overbooking_status_dto.dart` — NEW: `@freezed` DTOs with `fromJson`:
    - `OverbookedTaskDto`: fields `taskId`, `taskTitle`, `hasStake`, `durationMinutes`
    - `toDomain()`: direct mapping
    - `OverbookingStatusDto`: fields `isOverbooked`, `severity` (String), `capacityPercent`, `overbookedTasks` (List)
    - `toDomain()`: convert `severity` string: `'at_risk'` → `OverbookingSeverity.atRisk`, `'critical'` → `OverbookingSeverity.critical`, anything else → `OverbookingSeverity.none`
  - [x] Run build_runner

- [x] Extend TodayRepository (AC: 1, 2, 4)
  - [x] `apps/flutter/lib/features/today/data/today_repository.dart` — MODIFY: add two methods:
    - `Future<ScheduleChanges> getScheduleChanges()` — GET `/v1/tasks/schedule-changes`, parses `data` with `ScheduleChangesDto.fromJson()` then `.toDomain()`
    - `Future<OverbookingStatus> getOverbookingStatus()` — GET `/v1/tasks/overbooking-status`, parses `data` with `OverbookingStatusDto.fromJson()` then `.toDomain()`
  - [x] Run build_runner (update `.g.dart` for `TodayRepository` if needed — check if `today_repository.g.dart` needs regeneration)

- [x] Add Riverpod providers (AC: 1, 3, 4)
  - [x] `apps/flutter/lib/features/today/presentation/schedule_change_provider.dart` — NEW:
    - `@riverpod Future<ScheduleChanges> scheduleChanges(Ref ref)` — calls `todayRepositoryProvider.getScheduleChanges()`
    - `@riverpod class ScheduleChangeBannerVisible extends _$ScheduleChangeBannerVisible` — `AsyncNotifier<bool>`:
      - `build()`: fetches schedule changes; returns `true` if `hasMeaningfulChanges == true`
      - `void dismiss()`: sets state to `AsyncData(false)`
      - On dismiss: does NOT re-show until next app session (no persistence needed — stub behaviour)
    - Auto-dismiss timer: in `TodayScreen._TodayScreenState`, use `ref.listen(scheduleChangeBannerVisibleProvider, ...)` to start an 8-second timer when banner becomes visible; call `ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss()` on expiry; `ref.onDispose(timer.cancel)` — CRITICAL timer disposal
  - [x] `apps/flutter/lib/features/today/presentation/overbooking_provider.dart` — NEW:
    - `@riverpod Future<OverbookingStatus> overbookingStatus(Ref ref)` — calls `todayRepositoryProvider.getOverbookingStatus()`
    - `@riverpod class OverbookingBannerDismissed extends _$OverbookingBannerDismissed` — simple `bool` notifier, default `false`; `void dismiss()` sets `state = true`
  - [x] Run build_runner

- [x] Build Schedule Change Banner widget (AC: 1, 2, 3, 7)
  - [x] `apps/flutter/lib/features/today/presentation/widgets/schedule_change_banner.dart` — NEW:
    - `ScheduleChangeBanner` — `ConsumerStatefulWidget` (needs `initState` for haptic + timer wiring):
      - On first build when banner is visible: fire `HapticFeedback.lightImpact()` exactly once (use a `bool _hapticFired` flag in state)
      - **Anatomy per UX-DR18**: Banner row pinned at top of Today content area (below nav bar), above ScheduleHealthStrip:
        - Icon: `CupertinoIcons.arrow_2_circlepath` (or `CupertinoIcons.arrow_counterclockwise` — closest Cupertino to `arrow.triangle.2.circlepath`)
        - Message: `AppStrings.scheduleChangeBannerMessage` (e.g. `'{count} tasks rescheduled'`)
        - "See what changed" action: `CupertinoButton` with text `AppStrings.scheduleChangeSeeWhat`
        - Dismiss (×): `CupertinoButton` with `CupertinoIcons.xmark` icon, `AppStrings.scheduleChangeDismissVoiceOver` as semantics label
      - **Animation**: slides in from top with `AnimatedContainer`/`AnimatedSlide` — 0.3s, slides out on dismiss
      - Uses `colors.scheduleAtRisk` (amber) tint for background fill: `colors.scheduleAtRisk.withValues(alpha: 0.12)`
      - Tapping "See what changed": calls `_showChangesSheet(context, changes)` — `showCupertinoModalPopup` presenting a `CupertinoActionSheet`:
        - Title: `AppStrings.scheduleChangesSheetTitle`
        - Actions: one per change item — `CupertinoActionSheetAction` with text showing `taskTitle` + change summary
        - Cancel: `AppStrings.actionDone`
      - Dismiss button: calls `ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss()`
      - **VoiceOver**: `Semantics(liveRegion: true)` wrapping the banner — use `liveRegion: true` NOT `SemanticsService.announce()` (deprecated Flutter 3.41)
      - **No Material widgets**: `CupertinoButton` only — never `TextButton`/`ElevatedButton`

- [x] Build Overbooking Warning Banner widget (AC: 4, 5, 6)
  - [x] `apps/flutter/lib/features/today/presentation/widgets/overbooking_warning_banner.dart` — NEW:
    - `OverbookingWarningBanner({required OverbookingStatus status, super.key})` — `StatelessWidget` (receives domain model; callers handle async)
    - **Anatomy per UX-DR16**: `AnimatedContainer` banner row, inline in Today content:
      - Icon: `CupertinoIcons.exclamationmark_triangle` for `atRisk`; `CupertinoIcons.exclamationmark_circle` for `critical`
      - Severity colour: `colors.scheduleAtRisk` (amber) for `atRisk`; `colors.scheduleCritical` (red/terracotta) for `critical`
      - Background: `severityColor.withValues(alpha: 0.12)`
      - Message: `AppStrings.overbookingWarningMessage` (e.g. `'Schedule overloaded · {percent}% capacity'`)
      - Action row: three `CupertinoButton` compact CTAs:
        1. `AppStrings.overbookingReschedule` → calls `onReschedule`
        2. `AppStrings.overbookingExtendDeadline` → calls `onExtendDeadline`
        3. `AppStrings.overbookingAcknowledge` → calls `onAcknowledge`
      - If `status.overbookedTasks.any((t) => t.hasStake)`: show fourth action `AppStrings.overbookingRequestExtension` → calls `onRequestExtension`
    - Constructor callbacks: `VoidCallback? onReschedule`, `VoidCallback? onExtendDeadline`, `VoidCallback? onAcknowledge`, `VoidCallback? onRequestExtension`
    - **Icon + text — never colour alone** (NFR-A4): always show icon alongside colour change
    - **Semantics**: `Semantics(label: AppStrings.overbookingWarningVoiceOver, liveRegion: true)` wrapping the banner
    - `OverbookingWarningBannerAsync` — `ConsumerWidget` async wrapper:
      - Watches `overbookingStatusProvider` and `overbookingBannerDismissedProvider`
      - If `dismissed == true` or `isOverbooked == false`: `SizedBox.shrink()`
      - Loading: `SizedBox.shrink()` (non-critical — silent absence)
      - Error: `SizedBox.shrink()`
      - Data (overbooked, not dismissed): `OverbookingWarningBanner(status: data, onAcknowledge: () => ref.read(overbookingBannerDismissedProvider.notifier).dismiss(), ...)`
      - `onReschedule`/`onExtendDeadline`/`onRequestExtension`: show `CupertinoAlertDialog` with `AppStrings.actionNotImplemented` (stub — real Epic 3 impl)

- [x] Integrate banners into TodayScreen (AC: 1, 4)
  - [x] `apps/flutter/lib/features/today/presentation/today_screen.dart` — MODIFY:
    - In `_TodayScreenState`, add `ref.listen` for `scheduleChangeBannerVisibleProvider` to manage auto-dismiss timer:
      ```dart
      Timer? _autoDismissTimer;
      // In build() or initState via ref.listen:
      ref.listen<AsyncValue<bool>>(scheduleChangeBannerVisibleProvider, (prev, next) {
        if (next.value == true) {
          _autoDismissTimer?.cancel();
          _autoDismissTimer = Timer(const Duration(seconds: 8), () {
            ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss();
          });
        }
      });
      // In dispose:
      @override void dispose() { _autoDismissTimer?.cancel(); super.dispose(); }
      ```
    - In `_TodayContent.build()`, add banners as `SliverToBoxAdapter` entries at the TOP of the `CustomScrollView` sliver list, BEFORE `ScheduleHealthStrip`:
      ```
      // Order in CustomScrollView slivers:
      1. ScheduleChangeBannerSliver (SliverToBoxAdapter wrapping ScheduleChangeBannerAsync)
      2. OverbookingWarningBannerSliver (SliverToBoxAdapter wrapping OverbookingWarningBannerAsync)
      3. ScheduleHealthStrip (existing)
      4. Overdue section (existing)
      5. Morning / Afternoon / Evening sections (existing)
      ```
    - `ScheduleChangeBannerAsync` — `ConsumerWidget` wrapper:
      - Watches `scheduleChangeBannerVisibleProvider` and `scheduleChangesProvider`
      - If banner not visible: `SizedBox.shrink()`
      - If visible + changes loaded: `ScheduleChangeBanner(changes: changesData)`
      - Loading/error: `SizedBox.shrink()`

- [x] Add strings to AppStrings (AC: 1, 2, 4, 5, 6)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` — MODIFY: add new string constants:
    - `scheduleChangeBannerMessage` = `'Your schedule has been updated'`
    - `scheduleChangeSeeWhat` = `'See what changed'`
    - `scheduleChangeBannerDismiss` = `'Dismiss'`
    - `scheduleChangeDismissVoiceOver` = `'Dismiss schedule change banner'`
    - `scheduleChangesSheetTitle` = `'Schedule changes'`
    - `scheduleChangeMovedFormat` = `'{title} · moved to {time}'`
    - `scheduleChangeRemovedFormat` = `'{title} · removed from schedule'`
    - `scheduleChangeBannerVoiceOver` = `'Schedule updated. {count} tasks changed. Double-tap to see what changed.'`
    - `overbookingWarningMessage` = `'Schedule overloaded · {percent}% capacity'`
    - `overbookingWarningAtRisk` = `'At risk'`
    - `overbookingWarningCritical` = `'Critical'`
    - `overbookingReschedule` = `'Reschedule'`
    - `overbookingExtendDeadline` = `'Extend deadline'`
    - `overbookingAcknowledge` = `'Acknowledge'`
    - `overbookingRequestExtension` = `'Request deadline extension from partner'`
    - `overbookingWarningVoiceOver` = `'Schedule overloaded at {percent}% capacity. Available actions: Reschedule, Extend deadline, Acknowledge.'`
    - `actionNotImplemented` = `'This action is not yet available in this version.'`

- [x] Write tests (AC: 1, 2, 3, 4, 5, 6, 7)
  - [x] `apps/flutter/test/features/today/schedule_change_banner_test.dart` — NEW:
    - ScheduleChangeBanner: verify banner renders with message text
    - ScheduleChangeBanner: verify dismiss button calls dismiss callback
    - ScheduleChangeBanner: verify "See what changed" button is present
    - ScheduleChangeBanner: verify tapping "See what changed" shows changes sheet (find CupertinoActionSheet)
    - ScheduleChangeBanner: verify changes sheet shows moved task title
    - ScheduleChangeBanner: verify changes sheet shows removed task title
    - ScheduleChangeBannerAsync: verify renders SizedBox.shrink when banner not visible
    - ScheduleChangeBannerAsync: verify renders ScheduleChangeBanner when visible and data loaded
    - ScheduleChangeBannerAsync: verify renders SizedBox.shrink on loading state
    - ScheduleChangeBannerVisible notifier: verify dismiss() sets state to false
    - ScheduleChangeBannerVisible notifier: verify initial state true when hasMeaningfulChanges is true
  - [x] `apps/flutter/test/features/today/overbooking_warning_banner_test.dart` — NEW:
    - OverbookingWarningBanner (atRisk): verify amber colour token used (`scheduleAtRisk`)
    - OverbookingWarningBanner (atRisk): verify warning triangle icon present
    - OverbookingWarningBanner (critical): verify red colour token used (`scheduleCritical`)
    - OverbookingWarningBanner (critical): verify circle icon present
    - OverbookingWarningBanner: verify "Reschedule" action present
    - OverbookingWarningBanner: verify "Extend deadline" action present
    - OverbookingWarningBanner: verify "Acknowledge" action present
    - OverbookingWarningBanner: verify "Request deadline extension from partner" NOT shown when hasStake is false
    - OverbookingWarningBanner: verify "Request deadline extension from partner" shown when hasStake is true
    - OverbookingWarningBanner: verify tapping Acknowledge fires onAcknowledge callback
    - OverbookingWarningBannerAsync: verify SizedBox.shrink when isOverbooked false
    - OverbookingWarningBannerAsync: verify SizedBox.shrink when dismissed

## Dev Notes

### UX Specification Details

**UX-DR18 — Schedule Change Banner:**
- Anatomy: banner (top of Now or Today content area, below navigation bar) → icon (`arrow.triangle.2.circlepath`) → message (`'{count} tasks rescheduled to tomorrow'`) → dismiss (×) → `'View changes'` secondary action
- States: Visible (slides in from top, 0.3s) · Dismissed (slides out) · Auto-dismissed after 8s if not interacted with
- Note: UX-DR18 is marked V1.1 in the roadmap ("Schedule change banner — V1: system notification; in-app banner V1.1"), but Story 2.12 AC explicitly includes it — implement as specified in the AC
- Haptic: `HapticFeedback.lightImpact()` on banner appearance (UX haptic event map)

**UX-DR16 — Overbooking Warning:**
- UX-DR16 spec describes the Add flow context ("Adding this puts you at 108% today"), but Story 2.12 AC places the overbooking warning inline on the Today tab. Use the inline Today tab placement as the canonical AC.
- Severity: amber (`colors.scheduleAtRisk`) for at-risk, red (`colors.scheduleCritical`) for critical
- Actions: Reschedule, Extend deadline, Acknowledge (stub implementations using `CupertinoAlertDialog`)
- Stake-conditional action: "Request deadline extension from partner" — only if `overbookedTasks.any((t) => t.hasStake)`

### Colour Tokens — Reuse Exactly

The same colour pattern already established in `ScheduleHealthStrip` and `PredictionBadge` applies:

```dart
final colors = Theme.of(context).extension<OnTaskColors>()!;
// At-risk (amber):  colors.scheduleAtRisk
// Critical (red):   colors.scheduleCritical
// Background fill:  severityColor.withValues(alpha: 0.12)  // NOT withOpacity() — deprecated
```

Source: `apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart`

### Placement in TodayScreen CustomScrollView

The banners slot into `_TodayContent`'s `CustomScrollView` before the health strip. The `_TodayContent` widget is a `StatelessWidget` — if passing banner callbacks is needed, add them as constructor params. Alternatively, make `_TodayContent` a `ConsumerWidget` to watch banner providers directly. The simpler path: make the async banner wrappers `ConsumerWidget`s that watch their own providers — no callback threading required.

Current sliver order in `_TodayContent.build()` (`apps/flutter/lib/features/today/presentation/today_screen.dart:261-310`):
```
CustomScrollView slivers:
  ScheduleHealthStrip (if healthDays.isNotEmpty)
  Overdue section (if overdue.isNotEmpty)
  Morning / Afternoon / Evening sections
  Bottom padding
```

New order:
```
  ScheduleChangeBannerAsync   ← NEW: always included (hides itself via SizedBox.shrink)
  OverbookingWarningBannerAsync ← NEW: always included (hides itself via SizedBox.shrink)
  ScheduleHealthStrip
  Overdue section
  Morning / Afternoon / Evening sections
  Bottom padding
```

Since `_TodayContent` is a `StatelessWidget`, convert to `ConsumerWidget` OR keep it `StatelessWidget` and make both banner async wrappers self-contained `ConsumerWidget`s (recommended — no prop drilling).

### Auto-Dismiss Timer in TodayScreen

The 8-second auto-dismiss must be managed in `_TodayScreenState` (a `ConsumerStatefulWidget`). Use `ref.listen` in the `build()` method to react to banner visibility changes. Cancel the timer on dispose. Pattern:

```dart
// In _TodayScreenState:
Timer? _autoDismissTimer;

@override
Widget build(BuildContext context) {
  // Listen for banner visibility → start/cancel 8s timer
  ref.listen<AsyncValue<bool>>(
    scheduleChangeBannerVisibleProvider,
    (previous, next) {
      if (next.value == true) {
        _autoDismissTimer?.cancel();
        _autoDismissTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) {
            ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss();
          }
        });
      } else {
        _autoDismissTimer?.cancel();
      }
    },
  );
  // ... rest of build
}

@override
void dispose() {
  _autoDismissTimer?.cancel();  // CRITICAL: always cancel timers
  super.dispose();
}
```

This mirrors the `nowProvider` timer pattern. See `apps/flutter/lib/features/now/presentation/now_provider.dart` for precedent.

### API Route Ordering — Critical

Both new routes (`/v1/tasks/schedule-changes`, `/v1/tasks/overbooking-status`) are named sub-paths that MUST be registered BEFORE the `/{id}` parameterised route in `tasks.ts`. Current named routes already registered: `/today`, `/schedule-health`, `/current`, `/:id/prediction`, `/search`. Add new routes after search and before `/{id}`:

```ts
// Correct registration order in tasks.ts:
app.openapi(getTodayTasksRoute, handler)           // /today
app.openapi(getScheduleHealthRoute, handler)       // /schedule-health
app.openapi(getCurrentTaskRoute, handler)          // /current
app.openapi(getTaskPredictionRoute, handler)       // /:id/prediction
app.openapi(getSearchRoute, handler)               // /search
app.openapi(getScheduleChangesRoute, handler)      // /schedule-changes  ← NEW
app.openapi(getOverbookingStatusRoute, handler)    // /overbooking-status ← NEW
app.openapi(getTaskRoute, handler)                 // /:id               ← MUST remain last
```

### Feature Module Structure

```
apps/
├── api/
│   └── src/
│       └── routes/
│           └── tasks.ts                              ← MODIFY: add 2 new routes
│   └── test/
│       └── routes/
│           └── schedule-change.test.ts               ← NEW
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart                      ← MODIFY: add 17 new strings
    │   └── features/
    │       └── today/
    │           ├── data/
    │           │   ├── today_repository.dart         ← MODIFY: add 2 methods
    │           │   ├── schedule_change_dto.dart       ← NEW
    │           │   ├── schedule_change_dto.freezed.dart ← GENERATED
    │           │   ├── schedule_change_dto.g.dart    ← GENERATED
    │           │   ├── overbooking_status_dto.dart   ← NEW
    │           │   ├── overbooking_status_dto.freezed.dart ← GENERATED
    │           │   └── overbooking_status_dto.g.dart ← GENERATED
    │           ├── domain/
    │           │   ├── schedule_change.dart          ← NEW
    │           │   ├── schedule_change.freezed.dart  ← GENERATED
    │           │   ├── overbooking_status.dart       ← NEW
    │           │   └── overbooking_status.freezed.dart ← GENERATED
    │           └── presentation/
    │               ├── schedule_change_provider.dart ← NEW
    │               ├── schedule_change_provider.g.dart ← GENERATED
    │               ├── overbooking_provider.dart     ← NEW
    │               ├── overbooking_provider.g.dart   ← GENERATED
    │               ├── today_screen.dart             ← MODIFY: add timer + banner wiring
    │               └── widgets/
    │                   ├── schedule_change_banner.dart   ← NEW
    │                   └── overbooking_warning_banner.dart ← NEW
    └── test/
        └── features/
            └── today/
                ├── schedule_change_banner_test.dart  ← NEW
                └── overbooking_warning_banner_test.dart ← NEW
```

Note: All new domain/DTO models go into the **existing** `today` feature module — NOT a new top-level feature. Both banners are Today tab concerns. This differs from `prediction` which got its own feature module.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| No Material widgets | `CupertinoButton`, `CupertinoActionSheet`, `CupertinoAlertDialog` only | All prior stories |
| No inline strings | All copy in `AppStrings` | All prior stories |
| `withValues(alpha:)` not `withOpacity()` | `withOpacity()` deprecated in Flutter 3.41 | Story 2.9, 2.11 learnings |
| Icon + text | Never colour alone for severity (NFR-A4) | UX-DR16, ScheduleHealthStrip |
| `liveRegion: true` not `SemanticsService.announce()` | `announce()` deprecated in Flutter 3.41 | Story 2.11 learnings |
| Zod v4 UUID format | `a0000000-0000-4000-8000-000000000001` (variant bits `[89ab]`) | Stories 2.9, 2.11 |
| `ref.onDispose(timer.cancel)` | ALWAYS cancel timers — prevents leaks | Story 2.9 review finding |
| `ref.watch` inside providers | Use `ref.watch(todayRepositoryProvider)` inside providers | Story 2.11 learnings |
| build_runner generated files | Commit `*.g.dart` / `*.freezed.dart` | All prior stories |
| Stub: CupertinoAlertDialog for actions | Reschedule/Extend/RequestExtension show "not yet available" dialog | Epic 3 deferred |
| `mounted` guard in async callbacks | Check `if (mounted)` before calling `ref.read` in timer callbacks | Safety pattern |

### Accessibility — VoiceOver & Live Regions

- Banner widgets: wrap with `Semantics(liveRegion: true)` so VoiceOver announces on appearance
- Do NOT use `SemanticsService.announce()` — deprecated in Flutter 3.41
- Dismiss (×) button: set `Semantics(label: AppStrings.scheduleChangeDismissVoiceOver)` explicitly — icon-only buttons need text label
- Overbooking severity communicated by icon + colour + text, never colour alone

### Haptic — Schedule Change Banner

`HapticFeedback.lightImpact()` fires once when the banner appears. Use a `bool _hapticFired` state flag in `ScheduleChangeBannerAsync` or fire from `_TodayScreenState` listener:

```dart
ref.listen<AsyncValue<bool>>(
  scheduleChangeBannerVisibleProvider,
  (prev, next) {
    if (prev?.value != true && next.value == true) {
      HapticFeedback.lightImpact();  // fires exactly once on appear
    }
  },
);
```

### Stub Action Handling

Reschedule, Extend deadline, and Request extension are Epic 3 features. For this stub:
```dart
void _showNotImplemented(BuildContext context) {
  showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      content: const Text(AppStrings.actionNotImplemented),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionDone),
        ),
      ],
    ),
  );
}
```

`AppStrings.actionDone` already exists (used in PredictionBadge and ScheduleHealthStrip).

### Scope Boundaries

- **No real scheduling engine integration** — API stubs return static data. Real push-based schedule updates come in Epic 3.
- **No WebSocket/SSE** — banners appear on Today tab load. Real-time push comes in Epic 3.
- **No persistence of dismissed state** — dismiss resets on app restart (stub acceptable).
- **No Now tab integration** — UX-DR18 mentions "Now or Today content area" but AC is Today tab only. Do not add to NowScreen.
- **No notification integration** — Epic 8 covers push notifications for schedule changes.
- **No actual rescheduling** — Reschedule/Extend/RequestExtension actions show stub dialog. Real flows in Epic 3.

### Previous Story Learnings (accumulated from Stories 1.1-2.11)

- **`ref.watch` not `ref.read` for reactive dependencies in providers**: Use `ref.watch(todayRepositoryProvider)` inside providers.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL widget tests.
- **No Material widgets**: `CupertinoActionSheet`, `CupertinoButton`, `CupertinoAlertDialog`. Never `AlertDialog`, `ElevatedButton`, `TextButton`.
- **All strings in `AppStrings`**: Never inline string literals in widgets.
- **Widget tests — override providers in `ProviderScope(overrides: [...])`**: Stub providers with mock data.
- **`withValues(alpha:)` not `withOpacity()`**: `withOpacity()` deprecated in Flutter 3.41.
- **`SemanticsService.announce()` is deprecated in Flutter 3.41**: Use `Semantics(liveRegion: true)` pattern.
- **Hono route ordering**: Named/nested routes BEFORE parameterised routes. ALWAYS.
- **Zod v4 UUID format**: `a0000000-0000-4000-8000-000000000001` (variant bits `[89ab]` at position 1 of group 4).
- **`ref.onDispose(timer.cancel)`**: Always cancel timers to prevent leaks. Story 2.9 review finding.
- **build_runner generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart`.
- **`freezed` union types in `domain/`**: Domain models in `domain/`, DTOs in `data/`.
- **`OnTaskColors` extension access**: `Theme.of(context).extension<OnTaskColors>()!` — same pattern across all colour-using widgets.
- **Test baseline after Story 2.11**: 89 API tests + 490 Flutter tests pass (updated from completion notes — 89 API, 484 Flutter + 6 post-review = ~490). All must continue passing.
- **`find.text()` does not find text inside `RichText/TextSpan`**: Use `find.byType()` or `find.textContaining()`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible()` before tap.
- **`AnimatedCrossFade` is acceptable**: Pre-existing use in `today_screen.dart` — `AnimatedCrossFade` from Material is allowed despite no-Material rule (established exception).
- **Drizzle Kit requires `casing: 'snake_case'`** in `drizzle.config.ts`.

### Open Review Findings from Previous Stories (carry forward, not fixed in 2.12)

From Story 2.11 (open):
- [ ] [Review][Patch] Inline status strings in `_statusStringForVoiceOver` bypass AppStrings in `prediction_badge.dart:126-132`
- [ ] [Review][Patch] Missing async state tests for `ListPredictionBadge` and `SectionPredictionBadge`
- [ ] [Review][Patch] DTO `fromJson` silently produces empty `entityId` — add `FormatException` guard in `completion_prediction_dto.dart:30`

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

- Story 2.12 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` line 1089]
- UX-DR16 (Overbooking Warning): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1262]
- UX-DR18 (Schedule Change Banner): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1286]
- Haptic event map (schedule change banner → lightImpact): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1532]
- `ScheduleHealthStrip` colour pattern (OnTaskColors extension): [Source: `apps/flutter/lib/features/today/presentation/widgets/schedule_health_strip.dart`]
- `TodayScreen` and `_TodayContent` widget structure: [Source: `apps/flutter/lib/features/today/presentation/today_screen.dart`]
- `TodayRepository` pattern for new methods: [Source: `apps/flutter/lib/features/today/data/today_repository.dart`]
- `todayProvider` AsyncNotifier pattern: [Source: `apps/flutter/lib/features/today/presentation/today_provider.dart`]
- `DayHealth` freezed domain model pattern: [Source: `apps/flutter/lib/features/today/domain/day_health.dart`]
- `DayHealthDto` DTO pattern with `toDomain()`: [Source: `apps/flutter/lib/features/today/data/day_health_dto.dart`]
- Existing AppStrings: [Source: `apps/flutter/lib/core/l10n/strings.dart` lines 394-400, 484-498]
- Hono route ordering precedent: [Source: `apps/api/src/routes/tasks.ts` — `/today`, `/schedule-health`, `/current`, `/:id/prediction`, `/search` registered before `/{id}`]
- `ok()` response helper: [Source: `apps/api/src/lib/response.ts`]
- Zod v4 UUID stub pattern: [Source: `apps/api/src/routes/tasks.ts` stub data]
- Timer cancel pattern with `ref.listen`: [Source: `apps/flutter/lib/features/today/presentation/today_screen.dart` — `_skeletonDelay` pattern; nowProvider timer precedent]
- `AnimatedCrossFade` exception: [Source: `apps/flutter/lib/features/today/presentation/today_screen.dart` line 141 — established Material exception]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No blockers. All tasks completed in a single pass.

### Completion Notes List

- Added `GET /v1/tasks/schedule-changes` and `GET /v1/tasks/overbooking-status` API endpoints with Zod schemas and stub responses. Both registered before `/{id}` parameterised route per Hono ordering rule.
- Added 7 new API tests in `schedule-change.test.ts`; all 96 API tests pass.
- Created freezed domain models `ScheduleChanges`/`ScheduleChangeItem` and `OverbookingStatus`/`OverbookedTask` in the `today` feature module.
- Created `@freezed` DTOs `ScheduleChangeDto` and `OverbookingStatusDto` with `toDomain()` methods; string-to-enum conversions for `changeType` and `severity`.
- Extended `TodayRepository` with `getScheduleChanges()` and `getOverbookingStatus()` methods.
- Added `scheduleChangesProvider`, `ScheduleChangeBannerVisible` AsyncNotifier, `overbookingStatusProvider`, and `OverbookingBannerDismissed` Notifier via Riverpod generator.
- Built `ScheduleChangeBanner` (ConsumerWidget) and `ScheduleChangeBannerAsync` (ConsumerStatefulWidget): haptic fires once on appearance via `_hapticFired` flag, slides in/out with `AnimatedContainer`, `CupertinoActionSheet` diff sheet, `Semantics(liveRegion: true)` wrapping, `withValues(alpha:)` not `withOpacity()`.
- Built `OverbookingWarningBanner` (StatelessWidget) and `OverbookingWarningBannerAsync` (ConsumerWidget): triangle/circle icons for at-risk/critical severity, stake-conditional 4th action, stub `CupertinoAlertDialog` for unimplemented actions, `Semantics(liveRegion: true)` wrapping.
- Integrated banners in `TodayScreen`: `ref.listen` auto-dismiss timer (8s) added to `_TodayScreenState` with `dispose()` cancellation; `ScheduleChangeBannerAsync` and `OverbookingWarningBannerAsync` added as `SliverToBoxAdapter` entries before `ScheduleHealthStrip`.
- Added 26 new `AppStrings` constants covering all banner copy.
- All 513 Flutter tests pass (up 23 from baseline of 490). All 96 API tests pass.

### File List

apps/api/src/routes/tasks.ts
apps/api/test/routes/schedule-change.test.ts
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/lib/features/today/data/today_repository.dart
apps/flutter/lib/features/today/data/schedule_change_dto.dart
apps/flutter/lib/features/today/data/schedule_change_dto.freezed.dart
apps/flutter/lib/features/today/data/schedule_change_dto.g.dart
apps/flutter/lib/features/today/data/overbooking_status_dto.dart
apps/flutter/lib/features/today/data/overbooking_status_dto.freezed.dart
apps/flutter/lib/features/today/data/overbooking_status_dto.g.dart
apps/flutter/lib/features/today/domain/schedule_change.dart
apps/flutter/lib/features/today/domain/schedule_change.freezed.dart
apps/flutter/lib/features/today/domain/overbooking_status.dart
apps/flutter/lib/features/today/domain/overbooking_status.freezed.dart
apps/flutter/lib/features/today/presentation/schedule_change_provider.dart
apps/flutter/lib/features/today/presentation/schedule_change_provider.g.dart
apps/flutter/lib/features/today/presentation/overbooking_provider.dart
apps/flutter/lib/features/today/presentation/overbooking_provider.g.dart
apps/flutter/lib/features/today/presentation/today_screen.dart
apps/flutter/lib/features/today/presentation/widgets/schedule_change_banner.dart
apps/flutter/lib/features/today/presentation/widgets/overbooking_warning_banner.dart
apps/flutter/test/features/today/schedule_change_banner_test.dart
apps/flutter/test/features/today/overbooking_warning_banner_test.dart
_bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- 2026-03-31: Story 2.12 implemented — Schedule Change Banner and Overbooking Warning. Added 2 API endpoints, 2 Flutter domain models, 2 DTOs, repository extension, 2 providers, 2 banner widgets, TodayScreen integration, 26 AppStrings, and 23 new tests.
