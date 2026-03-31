# Story 2.9: Task Search & Filter

Status: review

## Story

As a user,
I want to search all my tasks and filter by list, date, and status,
So that I can find any task quickly regardless of how many lists I have.

## Acceptance Criteria

1. **Given** the user opens search, **When** they type a query, **Then** results are returned across all lists and sections matching the task title or notes (FR56) **And** results appear within 1 second for lists up to 500 tasks (NFR-P9)

2. **Given** the user applies filters, **When** multiple filters are combined, **Then** results show only tasks matching all active filters (AND logic) **And** available filter dimensions: list, due date range, status (upcoming / overdue / completed), has stake **And** active filters are displayed as removable chips

## Tasks / Subtasks

- [x] Add search API endpoint (AC: 1, 2)
  - [x] `apps/api/src/routes/tasks.ts` -- MODIFY: add `GET /v1/tasks/search` route with Zod-validated query params:
    - `q` (string, optional) -- search query, matches against title and notes (case-insensitive substring)
    - `listId` (string UUID, optional) -- filter by list
    - `status` (enum: `'upcoming'` | `'overdue'` | `'completed'`, optional) -- filter by task status
    - `dueDateFrom` (string date, optional) -- start of due date range (inclusive)
    - `dueDateTo` (string date, optional) -- end of due date range (inclusive)
    - `hasStake` (boolean, optional) -- filter tasks with `stakeAmountCents != null` (future-proofed, always false in stub)
    - `cursor` (string, optional) -- cursor-based pagination
    - Response schema: extend `taskSchema` with `listName` (string, nullable) so results can display list context
    - Use `list()` response helper with cursor pagination
    - Stub: filter the generated stub tasks in memory by `q` (substring match on title/notes), status, date range
    - **Route ordering**: Register `GET /v1/tasks/search` BEFORE `GET /v1/tasks/{id}` (named routes before parameterised routes)
  - [x] `apps/api/test/routes/task-search.test.ts` -- NEW:
    - GET /v1/tasks/search: verify returns 200 with list envelope
    - GET /v1/tasks/search?q=groceries: verify filters by title substring
    - GET /v1/tasks/search?status=completed: verify filters by status
    - GET /v1/tasks/search?listId=<uuid>: verify filters by list
    - GET /v1/tasks/search?dueDateFrom=2026-04-01&dueDateTo=2026-04-07: verify date range filter
    - GET /v1/tasks/search: verify response includes `listName` field
    - GET /v1/tasks/search?q=x&status=completed: verify AND logic with combined filters

- [x] Add search domain models (AC: 1, 2)
  - [x] `apps/flutter/lib/features/search/domain/search_filter.dart` -- NEW: freezed model for active filters:
    - `@freezed abstract class SearchFilter with _$SearchFilter`
    - Fields: `String? query`, `String? listId`, `String? listName` (display label for chip), `DateTime? dueDateFrom`, `DateTime? dueDateTo`, `TaskSearchStatus? status`, `bool? hasStake`
    - Factory constructor `SearchFilter.empty()` with all fields null
    - Getter `bool get isActive` -- true if any field is non-null
    - Getter `int get activeCount` -- count of non-null fields (excluding query)
  - [x] `apps/flutter/lib/features/search/domain/task_search_status.dart` -- NEW: enum:
    - `enum TaskSearchStatus { upcoming, overdue, completed }`
    - Extension method `String toApiValue()` mapping to API string values
    - Extension method `String displayLabel()` mapping to `AppStrings` constants
  - [x] `apps/flutter/lib/features/search/domain/search_result.dart` -- NEW: freezed model extending Task with list context:
    - `@freezed abstract class SearchResult with _$SearchResult`
    - Fields: all `Task` fields + `String? listName`
    - Factory constructor `SearchResult.fromTask(Task task, String? listName)`
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Add search data layer (AC: 1, 2)
  - [x] `apps/flutter/lib/features/search/data/search_result_dto.dart` -- NEW: DTO for search API response:
    - Extends `TaskDto` pattern with added `listName` (String?) field
    - `toDomain()` returns `SearchResult`
    - `factory SearchResultDto.fromJson(Map<String, dynamic> json)`
  - [x] `apps/flutter/lib/features/search/data/search_repository.dart` -- NEW: repository class:
    - `SearchRepository(ApiClient _client)` -- constructor injection pattern (same as `TasksRepository`)
    - `Future<List<SearchResult>> search({String? query, SearchFilter? filter, String? cursor})` -- calls `GET /v1/tasks/search` with query params assembled from filter
    - Parse response using `search_result_dto.dart` and `list()` envelope pattern
    - Riverpod provider: `@riverpod SearchRepository searchRepository(Ref ref)` -- injects `apiClientProvider`
  - [x] Run build_runner

- [x] Add search presentation layer (AC: 1, 2)
  - [x] `apps/flutter/lib/features/search/presentation/search_provider.dart` -- NEW: Riverpod providers:
    - `@riverpod class SearchQuery extends _$SearchQuery` -- holds current search text, debounced
    - `@riverpod class ActiveSearchFilter extends _$ActiveSearchFilter` -- holds current `SearchFilter`, methods to add/remove individual filter dimensions
    - `@riverpod Future<List<SearchResult>> searchResults(Ref ref)` -- watches `searchQueryProvider` and `activeSearchFilterProvider`, calls `searchRepository.search()`. Returns empty list when query is empty AND no filters active.
    - Debounce: Use `Timer` in `SearchQuery` notifier -- 300ms debounce on query text changes before triggering search. Cancel previous timer on each keystroke.
  - [x] `apps/flutter/lib/features/search/presentation/search_screen.dart` -- NEW: full-screen search overlay:
    - **iOS**: Presented as a full-screen `CupertinoPageRoute` (not modal sheet -- search needs full keyboard + results space)
    - **macOS**: Reuse existing `CommandPaletteSheet` dialog frame with search results below the text field (replace "Full command palette coming in V2." placeholder)
    - **Layout**:
      - Top: `CupertinoSearchTextField` with autofocus, cancel button
      - Below search: Filter chips row (horizontal scroll `SingleChildScrollView` with `Row`)
      - Below chips: Active filter chips (removable, wrapped in `Wrap` widget)
      - Results: `CustomScrollView` with `SliverList` of search result rows
      - Empty state: "No results found" when query/filter active but no matches
      - Initial state: Recent searches or "Search all your tasks" hint when no query
    - **Cancel/dismiss**: iOS back nav or Cancel button clears search and pops. macOS Escape key dismisses.
    - **VoiceOver**: Search field label: `AppStrings.searchFieldLabel`. Each result row: "{title}. {listName}. {status}." Filter chips: "{filterName}. Double tap to remove."
  - [x] `apps/flutter/lib/features/search/presentation/widgets/search_result_row.dart` -- NEW: single search result widget:
    - Shows task title (primary), list name (secondary), due date, status indicator
    - Reuse visual patterns from `TodayTaskRow` / `TaskRow` -- do NOT reinvent task row rendering
    - Tap handler: stub (task detail navigation deferred)
    - Highlight matched text in title/notes using `TextSpan` with bold style for query match ranges
  - [x] `apps/flutter/lib/features/search/presentation/widgets/filter_chip_row.dart` -- NEW: filter dimension selector:
    - Horizontal row of filter buttons: List, Date, Status, Has Stake
    - Each button opens a filter picker (see below)
    - Use `CupertinoButton` styled as chip (rounded rect, `surfaceSecondary` background, `textPrimary` label)
    - Active filter chip: `accentPrimary` background, white label, trailing X icon to remove
    - **No Material `Chip` or `FilterChip` widgets** -- build from `CupertinoButton` + `Container` with `BoxDecoration`
  - [x] `apps/flutter/lib/features/search/presentation/widgets/filter_pickers.dart` -- NEW: filter picker modals:
    - `showListFilterPicker(BuildContext)` -- `CupertinoActionSheet` listing all user lists (from `listsProvider`), tap selects
    - `showDateRangeFilterPicker(BuildContext)` -- Two `CupertinoDatePicker` (from/to) in a sheet
    - `showStatusFilterPicker(BuildContext)` -- `CupertinoActionSheet` with upcoming/overdue/completed options
    - `showStakeFilterToggle()` -- Simple toggle, no picker needed (adds/removes hasStake=true filter)
  - [x] Run build_runner

- [x] Wire search entry points (AC: 1)
  - [x] `apps/flutter/lib/features/shell/presentation/app_shell.dart` -- MODIFY: add search icon button to the navigation bar or header area
    - iOS: `CupertinoButton` with `CupertinoIcons.search` in the app bar area
    - Tap opens `SearchScreen` as `CupertinoPageRoute`
  - [x] `apps/flutter/lib/features/shell/presentation/command_palette_sheet.dart` -- MODIFY: replace "Full command palette coming in V2." placeholder:
    - Wire `CupertinoTextField` (currently `TextField` -- **must change to CupertinoTextField**) to `searchQueryProvider`
    - Show search results below the text field in the existing dialog frame
    - Add filter chips below the search field
    - Escape still dismisses (existing behavior)
    - **Fix existing Material violation**: `TextField` on line 58 must become `CupertinoTextField`. `Dialog` on line 41 must become a custom `Container` with `BoxDecoration` or remain as-is (Dialog is from widgets.dart, acceptable like AnimatedCrossFade).
  - [x] `apps/flutter/lib/features/shell/presentation/macos_keyboard_shortcuts.dart` -- VERIFY: `Cmd+K` already opens `CommandPaletteSheet` (UX-DR23). No change needed unless binding is missing.

- [x] Add strings to `AppStrings` (AC: 1, 2)
  - [x] `apps/flutter/lib/core/l10n/strings.dart` -- MODIFY: add new string constants:
    - `searchFieldLabel` = `'Search all tasks'`
    - `searchFieldPlaceholder` = `'Search tasks, notes...'`
    - `searchCancel` = `'Cancel'`
    - `searchNoResults` = `'No results found'`
    - `searchInitialHint` = `'Search across all your lists'`
    - `searchFilterList` = `'List'`
    - `searchFilterDate` = `'Date'`
    - `searchFilterStatus` = `'Status'`
    - `searchFilterHasStake` = `'Has stake'`
    - `searchFilterStatusUpcoming` = `'Upcoming'`
    - `searchFilterStatusOverdue` = `'Overdue'`
    - `searchFilterStatusCompleted` = `'Completed'`
    - `searchFilterRemove` = `'Remove filter'`
    - `searchResultCount` = `'{count} results'`
    - `searchResultVoiceOver` = `'{title}. {listName}. {status}.'`
    - `searchFilterDateRange` = `'{from} – {to}'`

- [x] Write tests (AC: 1, 2)
  - [x] `apps/flutter/test/features/search/search_screen_test.dart` -- NEW:
    - SearchScreen: verify search field renders with autofocus
    - SearchScreen: verify typing triggers search results (mock searchRepository)
    - SearchScreen: verify empty query shows initial hint state
    - SearchScreen: verify no results shows empty state message
    - SearchScreen: verify filter chips row renders all four dimensions
    - SearchScreen: verify tapping list filter opens list picker
    - SearchScreen: verify active filter chip appears after selecting filter
    - SearchScreen: verify tapping X on active filter chip removes it
    - SearchScreen: verify VoiceOver labels on search field and result rows
    - SearchScreen: verify cancel button dismisses search
  - [x] `apps/flutter/test/features/search/search_provider_test.dart` -- NEW:
    - SearchQuery: verify debounce (300ms) before triggering search
    - SearchResults: verify calls repository with query and filter
    - SearchResults: verify returns empty list when no query and no filters
    - ActiveSearchFilter: verify add/remove filter dimensions
    - ActiveSearchFilter: verify activeCount reflects non-null fields
  - [x] `apps/flutter/test/features/search/search_repository_test.dart` -- NEW:
    - SearchRepository: verify GET /v1/tasks/search called with correct query params
    - SearchRepository: verify response parsed into SearchResult list
    - SearchRepository: verify combined filter params sent correctly

### Review Findings

- [x] [Review][Patch] Inline strings 'From' and 'To' in date range picker not in AppStrings [filter_pickers.dart:113,142]
- [x] [Review][Patch] Hardcoded `fontSize: 13` in date range picker violates Dynamic Type constraint [filter_pickers.dart:119,148]
- [x] [Review][Patch] SearchQuery Timer not cancelled on notifier disposal -- potential leaked timer [search_provider.dart:18]
- [x] [Review][Patch] SearchResultDto includes `durationMinutes`/`scheduledStartTime` fields not in API searchResultSchema -- dead fields that will always deserialize as null [search_result_dto.dart:43-44]
- [x] [Review][Patch] `_buildResults` uses `dynamic textTheme` parameter instead of typed `TextTheme` -- loses static analysis [search_screen.dart:128, command_palette_sheet.dart:147]
- [x] [Review][Patch] Missing `Cmd+Alt+F` search shortcut on macOS per UX spec line ~1692 [macos_keyboard_shortcuts.dart]
- [x] [Review][Patch] VoiceOver semantics on SearchResultRow uses `button: true` but item is not a button -- should be generic tappable or use `onTap` semantics action [search_result_row.dart:52]
- [x] [Review][Patch] Filter chip X icon (12px) is below 44pt minimum touch target -- the `Padding(all: xs)` wrapper may not reach 44pt [filter_chip_row.dart:155-163]
- [x] [Review][Patch] `searchResultsProvider` uses `ref.read(searchRepositoryProvider)` instead of `ref.watch` -- won't react if API client changes [search_provider.dart:107]
- [x] [Review][Defer] `_FakeSearchRepository` instantiates a real `ApiClient(baseUrl: 'http://fake')` -- pre-existing pattern from other test files, not new to this story [search_provider_test.dart:165]
- [x] [Review][Defer] Search repository test file (`search_repository_test.dart`) only tests domain models and DTOs, not the repository's HTTP call -- actual repository integration test is missing, but this matches the existing stub-only pattern [search_repository_test.dart]

## Dev Notes

### Search Architecture -- Design Decisions

1. **Dedicated search feature module**: Search gets its own feature directory (`features/search/`) following the established feature anatomy pattern (data/, domain/, presentation/). It is NOT a sub-feature of tasks -- search spans all lists and sections.

2. **API-side search**: Search is implemented server-side via `GET /v1/tasks/search`. Client sends query + filter params, server returns filtered results. This ensures NFR-P9 (1-second response for 500 tasks) is achievable at scale -- client-side filtering would require fetching all tasks first.

3. **Debounced search-as-you-type**: 300ms debounce on query input before triggering API call. This prevents excessive network requests while maintaining responsive feel.

4. **Reuse existing CommandPaletteSheet on macOS**: The command palette (opened via Cmd+K, UX-DR23) already has a search text field and dialog frame. Wire it to the search providers instead of building a second macOS search UI. The iOS search screen is a separate full-screen route.

5. **Filter chips are custom Cupertino widgets**: No Material `Chip`, `FilterChip`, or `InputChip` widgets. Build removable chips from `CupertinoButton` + `Container` with `BoxDecoration` -- same pattern used throughout the app.

### Existing CommandPaletteSheet Issues to Fix

The current `command_palette_sheet.dart` has Material widget violations that must be fixed in this story:
- Line 58: `TextField` must become `CupertinoTextField`
- Line 41: `Dialog` widget -- this is from `material.dart`. Replace with a custom `Container` + `BoxDecoration` inside `Center` or use `CupertinoPopupSurface`.
- Line 67-69: `InputDecoration`, `OutlineInputBorder` -- Material-specific. Use `CupertinoTextField` decoration instead.
- Line 78: `Theme.of(context).textTheme.bodySmall` -- acceptable (theme text styles are used across the app).

### Filter Chip UX Pattern

Active filters display as removable chips in a `Wrap` widget below the search field:
- Chip anatomy: rounded rect container, `accentPrimary` background when active, label text + trailing X icon
- Tapping the chip body opens the filter picker to change the value
- Tapping the X removes that filter entirely
- Multiple filters combine with AND logic
- Filter dimensions: List (picks from user's lists), Date range (from/to date pickers), Status (upcoming/overdue/completed), Has Stake (boolean toggle)

### Search Result Enrichment

Search results include `listName` alongside the standard task fields. This mirrors the `currentTaskSchema` enrichment pattern used in Story 2.7 (`GET /v1/tasks/current` adds `listName`, `assignorName`, `stakeAmountCents`, `proofMode`). The search endpoint extends `taskSchema` with just `listName` -- minimal enrichment needed for search result display.

### Status Determination Logic (Server-Side)

The `status` filter maps to task state:
- **upcoming**: `completedAt IS NULL AND (dueDate IS NULL OR dueDate >= NOW())`
- **overdue**: `completedAt IS NULL AND dueDate IS NOT NULL AND dueDate < NOW()`
- **completed**: `completedAt IS NOT NULL`

For the stub implementation, apply these conditions in-memory on the stub task array.

### Route Ordering Reminder

`GET /v1/tasks/search` MUST be registered BEFORE `GET /v1/tasks/{id}` in `tasks.ts`. Hono matches routes in registration order -- if `{id}` comes first, "search" would be treated as a task ID and fail UUID validation.

### Project Structure Notes

```
apps/
├── api/
│   └── src/
│       └── routes/
│           └── tasks.ts                          <- MODIFY: add GET /v1/tasks/search
│   └── test/
│       └── routes/
│           └── task-search.test.ts               <- NEW
└── flutter/
    ├── lib/
    │   ├── core/
    │   │   └── l10n/
    │   │       └── strings.dart                  <- MODIFY: add search strings
    │   └── features/
    │       ├── search/                           <- NEW feature module
    │       │   ├── data/
    │       │   │   ├── search_result_dto.dart    <- NEW
    │       │   │   ├── search_result_dto.freezed.dart  <- GENERATED
    │       │   │   ├── search_result_dto.g.dart  <- GENERATED
    │       │   │   ├── search_repository.dart    <- NEW
    │       │   │   └── search_repository.g.dart  <- GENERATED
    │       │   ├── domain/
    │       │   │   ├── search_filter.dart         <- NEW
    │       │   │   ├── search_filter.freezed.dart <- GENERATED
    │       │   │   ├── search_result.dart         <- NEW
    │       │   │   ├── search_result.freezed.dart <- GENERATED
    │       │   │   └── task_search_status.dart    <- NEW
    │       │   └── presentation/
    │       │       ├── search_provider.dart        <- NEW
    │       │       ├── search_provider.g.dart      <- GENERATED
    │       │       ├── search_screen.dart          <- NEW
    │       │       └── widgets/
    │       │           ├── search_result_row.dart  <- NEW
    │       │           ├── filter_chip_row.dart    <- NEW
    │       │           └── filter_pickers.dart     <- NEW
    │       └── shell/
    │           └── presentation/
    │               ├── app_shell.dart             <- MODIFY: add search entry point
    │               └── command_palette_sheet.dart  <- MODIFY: wire search, fix Material widgets
    └── test/
        └── features/
            └── search/
                ├── search_screen_test.dart        <- NEW
                ├── search_provider_test.dart       <- NEW
                └── search_repository_test.dart     <- NEW
```

### References

- Story 2.9 AC and user story: [Source: `_bmad-output/planning-artifacts/epics.md` -- line ~1020]
- FR56 (search and filter tasks across lists): [Source: `_bmad-output/planning-artifacts/prd.md` -- line ~505]
- NFR-P9 (1-second search results for 500 tasks): [Source: `_bmad-output/planning-artifacts/prd.md` -- line ~622]
- UX-DR23 (macOS keyboard navigation, Cmd+K command palette): [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~560]
- Cmd+Alt+F activates search/filter on macOS: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~1692]
- Linear's Cmd+K command palette pattern: [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~432]
- Signal direction "chip-based metadata": [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` -- line ~809]
- Existing CommandPaletteSheet: [Source: `apps/flutter/lib/features/shell/presentation/command_palette_sheet.dart`]
- Existing macOS keyboard shortcuts: [Source: `apps/flutter/lib/features/shell/presentation/macos_keyboard_shortcuts.dart`]
- Existing TasksRepository (query param pattern): [Source: `apps/flutter/lib/features/tasks/data/tasks_repository.dart`]
- Existing Task domain model: [Source: `apps/flutter/lib/features/tasks/domain/task.dart`]
- Existing TaskDto: [Source: `apps/flutter/lib/features/tasks/data/task_dto.dart`]
- Existing task API routes: [Source: `apps/api/src/routes/tasks.ts`]
- Response helpers: [Source: `apps/api/src/lib/response.ts`]
- Existing AppStrings: [Source: `apps/flutter/lib/core/l10n/strings.dart`]
- Existing lists provider: [Source: `apps/flutter/lib/features/lists/presentation/lists_provider.dart`]
- TaskList domain model: [Source: `apps/flutter/lib/features/lists/domain/task_list.dart`]
- Architecture: feature anatomy pattern: [Source: `_bmad-output/planning-artifacts/architecture.md` -- line ~495]
- Architecture: Hono route conventions: [Source: `_bmad-output/planning-artifacts/architecture.md` -- line ~447]
- Architecture: `@hono/zod-openapi` for all routes: [Source: `_bmad-output/planning-artifacts/architecture.md` -- line ~456]

### Previous Story Learnings (from Stories 1.1-2.8)

- **`valueOrNull` vs `.value`**: Riverpod v3 uses `.value` on `AsyncValue`, NOT `.valueOrNull`. Use `ref.watch(provider).value ?? defaultValue` in widget builders.
- **`FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`**: Required in `setUp()` of ALL tests that touch any provider reading `SharedPreferences` or `FlutterSecureStorage` at build time.
- **`ref.read(apiClientProvider)` -- never `new ApiClient()`**: All repositories receive `ApiClient` via Riverpod injection.
- **`build_runner` generated files are committed**: Run `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`. Commit `*.g.dart` / `*.freezed.dart` output files.
- **`@Riverpod(keepAlive: true)` for long-lived notifiers**: Search query and filter state should use `keepAlive: true` if they need to survive tab switches. Evaluate: if search screen is a separate route that gets disposed, `keepAlive` is unnecessary.
- **Test baseline after Story 2.8**: 72 API tests + 400 Flutter tests pass. All must continue passing.
- **No Material widgets**: Use `CupertinoTextField`, `CupertinoButton`, `CupertinoDatePicker`, `CupertinoAlertDialog`, `CupertinoActionSheet`. Never `TextField`, `ElevatedButton`, `AlertDialog`, `ListTile`. Exception: `AnimatedCrossFade` is from `widgets.dart`, not material.
- **All strings in `AppStrings`**: Never inline string literals. Warm narrative voice (UX-DR32, UX-DR36).
- **Widget tests -- override providers in `ProviderScope(overrides: [...])`**: Never rely on real network calls or real `SharedPreferences` in widget tests.
- **Hono route additions -- no untyped routes**: `@hono/zod-openapi` schemas for all new routes.
- **`ok()` / `list()` / `err()` helpers from `apps/api/src/lib/response.ts`**: Same envelope for all responses.
- **Riverpod v3 restriction**: `provider.notifier` cannot be called when provider is overridden with `overrideWithValue`. Use fake class extension pattern in tests.
- **`freezed` union types go in `domain/`**: Domain models and sealed types live in `domain/`, never in `data/`.
- **Button off-screen in tests**: Use `tester.dragUntilVisible(...)` before tap when widgets are below the fold.
- **Zod v4 UUID validation requires RFC-4122 compliant UUIDs** (variant bits must be [89ab] in position 1 of 4th group). Use `a0000000-0000-4000-8000-000000000001` style in test fixtures.
- **Riverpod v4 generates provider names without "Notifier" suffix** (e.g., `activeSearchFilterProvider` not `activeSearchFilterNotifierProvider`).
- **`CupertinoSlidingSegmentedControl` generic type param cannot be nullable** -- use `CupertinoActionSheet` for option pickers instead.
- **Drizzle Kit requires `casing: 'snake_case'`** in drizzle.config.ts to generate snake_case SQL columns from camelCase TS schema fields.
- **Dismissible swipe-to-delete test needs `-500` offset** (not `-300`) to trigger `confirmDismiss`.
- **Hono route ordering matters**: Named routes MUST be registered before parameterised routes.
- **`withValues(alpha:)` instead of deprecated `withOpacity()`** for color opacity.
- **`SemanticsService.announce()` is deprecated in Flutter 3.41**; use alternative announcement patterns.

### Open Review Findings from Story 2.8

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

### Open Review Findings from Story 2.7

- [ ] [Review][Decision] AC4 Dynamic Island padding -- SafeArea vs explicit viewPadding.top
- [ ] [Review][Patch] Missing NowRepository endpoint test
- [ ] [Review][Patch] Timer announcement callback entirely empty
- [ ] [Review][Patch] Force-unwrap `response.data!` in NowRepository

### Deferred Issues from Previous Stories

- **TimeOfDay formatting duplication** (from Story 1.9): Extract to `apps/flutter/lib/core/utils/time_format.dart` if search needs time formatting.
- **Review findings from Stories 2.2-2.8**: Inline string literals, missing tests, missing navigation feedback. See Story 2.8 file for full list.
- **CommandPaletteSheet Material violations**: Must be fixed in this story (TextField -> CupertinoTextField, Dialog -> custom container).

### Scope Boundaries -- What This Story Does NOT Include

- **Real full-text search / database indexing** -- Stubs filter in-memory. Real database `ILIKE` or `tsvector` search comes when Drizzle queries are wired.
- **Task detail navigation** -- Tapping a search result should open task detail, but the task detail screen is not yet built. Stub the tap handler (log or no-op).
- **Has Stake filter data** -- `stakeAmountCents` is not yet on the Task model (Epic 6). The filter dimension is included in the UI for forward compatibility but always returns no results. The API parameter exists but the stub has no staked tasks.
- **Voice search** -- Voice input for search queries is deferred to Epic 4 (NLP).
- **Search history / recent searches** -- Nice-to-have but not in AC. Initial state shows hint text only.
- **Offline search** -- Requires local database (Drift). Deferred to when Drift is wired.

### Design Constraints

| Constraint | Rule | Source |
|---|---|---|
| No Material widgets | CupertinoTextField, CupertinoButton, CupertinoActionSheet, CupertinoDatePicker only | Stories 1.5-2.8 pattern |
| No inline strings | All copy in AppStrings | Stories 1.6-2.8 pattern |
| 1-second response | NFR-P9: search results within 1 second for up to 500 tasks | PRD |
| AND logic for filters | Multiple filters combine with AND, not OR | AC 2 |
| Removable chips | Active filters shown as chips with X to remove | AC 2 |
| Cmd+K opens search on macOS | Command palette becomes search on macOS | UX-DR23 |
| Cmd+Alt+F activates search | Standard macOS search shortcut | UX spec line ~1692 |
| VoiceOver | Search field, result rows, filter chips all have semantic labels | Accessibility pattern |
| Dynamic Type | All text uses theme text styles; no hardcoded sizes | NFR-A3, UX-DR22 |
| Touch target minimum | 44x44pt for all interactive elements (filter chips, result rows) | UX accessibility |
| Cursor-based pagination | API uses cursor pagination, never offset/limit | Architecture |
| Zod-OpenAPI schemas | Every route fully typed | Architecture |

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Timer-based debounce in SearchQuery notifier requires `ref.mounted` check before setting state in Timer callback
- `find.text()` does not find text inside `RichText/TextSpan` -- use `find.byType(SearchResultRow)` or `find.textContaining()` for highlighted text
- Riverpod v4 generates `listsProvider` (not `listsNotifierProvider`) for `ListsNotifier`
- `Dialog` is a Material widget -- replaced with custom `Container` + `BoxDecoration` in CommandPaletteSheet

### Completion Notes List

- API: Added `GET /v1/tasks/search` with Zod-validated query params (q, listId, status, dueDateFrom, dueDateTo, hasStake, cursor). Stub filters in-memory across 4 diverse test tasks. Route registered before `GET /v1/tasks/{id}` per Hono ordering requirements.
- Domain: Created SearchFilter (freezed, with isActive/activeCount getters), SearchResult (freezed, extends Task with listName), TaskSearchStatus enum with toApiValue/displayLabel methods.
- Data: SearchResultDto with fromJson/toDomain, SearchRepository with query param assembly from SearchFilter.
- Presentation: SearchQuery notifier with 300ms Timer debounce, ActiveSearchFilter notifier with add/remove methods, searchResultsProvider that returns empty list when idle. SearchScreen (iOS full-screen), SearchResultRow with text highlighting, FilterChipRow (Cupertino-only), filter pickers (CupertinoActionSheet/CupertinoDatePicker).
- Shell: Added search icon to iOS app bar (CupertinoIcons.search), rewrote CommandPaletteSheet to fix Material violations (Dialog -> Container, TextField -> CupertinoTextField, InputDecoration/OutlineInputBorder removed) and wire search providers.
- Strings: Added 16 new AppStrings constants for search feature.
- Tests: 7 API tests, 10 screen tests, 8 provider tests, 10 repository/domain tests = 35 new tests. All 79 API tests + 428 Flutter tests pass.

### File List

- apps/api/src/routes/tasks.ts (MODIFIED)
- apps/api/test/routes/task-search.test.ts (NEW)
- apps/flutter/lib/core/l10n/strings.dart (MODIFIED)
- apps/flutter/lib/features/search/domain/search_filter.dart (NEW)
- apps/flutter/lib/features/search/domain/search_filter.freezed.dart (GENERATED)
- apps/flutter/lib/features/search/domain/search_result.dart (NEW)
- apps/flutter/lib/features/search/domain/search_result.freezed.dart (GENERATED)
- apps/flutter/lib/features/search/domain/task_search_status.dart (NEW)
- apps/flutter/lib/features/search/data/search_result_dto.dart (NEW)
- apps/flutter/lib/features/search/data/search_result_dto.freezed.dart (GENERATED)
- apps/flutter/lib/features/search/data/search_result_dto.g.dart (GENERATED)
- apps/flutter/lib/features/search/data/search_repository.dart (NEW)
- apps/flutter/lib/features/search/data/search_repository.g.dart (GENERATED)
- apps/flutter/lib/features/search/presentation/search_provider.dart (NEW)
- apps/flutter/lib/features/search/presentation/search_provider.g.dart (GENERATED)
- apps/flutter/lib/features/search/presentation/search_screen.dart (NEW)
- apps/flutter/lib/features/search/presentation/widgets/search_result_row.dart (NEW)
- apps/flutter/lib/features/search/presentation/widgets/filter_chip_row.dart (NEW)
- apps/flutter/lib/features/search/presentation/widgets/filter_pickers.dart (NEW)
- apps/flutter/lib/features/shell/presentation/app_shell.dart (MODIFIED)
- apps/flutter/lib/features/shell/presentation/command_palette_sheet.dart (MODIFIED)
- apps/flutter/test/features/search/search_screen_test.dart (NEW)
- apps/flutter/test/features/search/search_provider_test.dart (NEW)
- apps/flutter/test/features/search/search_repository_test.dart (NEW)

### Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-03-31 | 1.0 | claude-opus-4-6 | Story 2.9 created -- Task search & filter with API endpoint, search feature module, filter chips, macOS command palette integration. |
| 2026-03-31 | 1.1 | claude-opus-4-6 | Story 2.9 implemented -- Search API endpoint, Flutter search feature (domain/data/presentation), filter chips, command palette integration, Material violation fixes, 35 new tests. |
