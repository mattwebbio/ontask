# Story 6.4: Impact Dashboard

Status: review

## Story

As a user,
I want to see a visual record of what my kept (and missed) commitments have produced,
So that I have tangible evidence of growth rather than just a list of tasks completed.

## Acceptance Criteria

1. **Given** the user has had at least one staked task resolve (charged or verified complete)
   **When** they open the Impact Dashboard
   **Then** milestone cells are shown using the "evidence of who you've become" framing — not a raw stats list (FR27, UX-DR19)
   **And** cells represent meaningful milestones: first donation, first commitment kept, $100 total donated, streak of kept commitments
   **And** total amount donated and charity breakdown are accessible as secondary information

2. **Given** a milestone cell is tapped
   **When** the detail expands
   **Then** a natural sharing moment is presented: the user can share the milestone via native share sheet
   **And** copy is affirming for both kept and missed commitments — no punitive language (UX-DR36)

## Tasks / Subtasks

### Backend: API — impact endpoint in `apps/api/src/routes/commitment-contracts.ts` (AC: 1, 2)

- [x] Add impact schemas (AC: 1, 2)
  ```typescript
  const milestoneSchema = z.object({
    id: z.string(),                   // e.g. 'first-donation', 'first-kept', 'hundred-donated'
    title: z.string(),                // milestone label — affirming framing
    body: z.string(),                 // New York voice copy — "evidence of who you've become"
    earnedAt: z.string(),             // ISO 8601 UTC string
    shareText: z.string(),            // pre-composed share copy for native share sheet
  })

  const impactSummarySchema = z.object({
    totalDonatedCents: z.number().int(),
    commitmentsKept: z.number().int(),
    commitmentsMissed: z.number().int(),
    charityBreakdown: z.array(z.object({
      charityName: z.string(),
      donatedCents: z.number().int(),
    })),
    milestones: z.array(milestoneSchema),
  })
  ```

- [x] Add `GET /v1/impact` — fetch impact summary and earned milestones (AC: 1, 2)
  - [x] No query params
  - [x] Response 200: `{ data: impactSummarySchema }`
  - [x] Tag: `'Impact'`
  - [x] Stub: return hardcoded summary with 3 milestones (see stub data below)
  - [x] Add `TODO(impl): query commitment_contracts and task_stakes for userId = JWT sub; aggregate totalDonatedCents, commitmentsKept, commitmentsMissed; query charity breakdown; resolve earned milestones`

- [x] Route registration in `commitment-contracts.ts` — add impact route after existing charity routes
  - Register AFTER the existing `GET /v1/charities` route
  - No change to `apps/api/src/index.ts` — `commitmentContractsRouter` is already mounted

### Flutter: Domain model — `ImpactMilestone` and `ImpactSummary` in `apps/flutter/lib/features/commitment_contracts/domain/` (AC: 1, 2)

- [x] Create `apps/flutter/lib/features/commitment_contracts/domain/impact_milestone.dart`
  - [x] Freezed model:
    ```dart
    @freezed
    class ImpactMilestone with _$ImpactMilestone {
      const factory ImpactMilestone({
        required String id,
        required String title,
        required String body,
        required DateTime earnedAt,
        required String shareText,
      }) = _ImpactMilestone;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit generated `impact_milestone.freezed.dart`

- [x] Create `apps/flutter/lib/features/commitment_contracts/domain/impact_summary.dart`
  - [x] Freezed model:
    ```dart
    @freezed
    class ImpactSummary with _$ImpactSummary {
      const factory ImpactSummary({
        required int totalDonatedCents,
        required int commitmentsKept,
        required int commitmentsMissed,
        @Default([]) List<CharityDonation> charityBreakdown,
        @Default([]) List<ImpactMilestone> milestones,
      }) = _ImpactSummary;
    }

    @freezed
    class CharityDonation with _$CharityDonation {
      const factory CharityDonation({
        required String charityName,
        required int donatedCents,
      }) = _CharityDonation;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit generated `impact_summary.freezed.dart`

### Flutter: Repository — impact method in `CommitmentContractsRepository` (AC: 1, 2)

- [x] Extend `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`
  - [x] Add method: `Future<ImpactSummary> getImpactSummary()` — `GET /v1/impact`
    - Parse:
      ```dart
      final data = response.data!['data'] as Map<String, dynamic>;
      final milestones = (data['milestones'] as List<dynamic>).map((e) {
        final m = e as Map<String, dynamic>;
        return ImpactMilestone(
          id: m['id'] as String,
          title: m['title'] as String,
          body: m['body'] as String,
          earnedAt: DateTime.parse(m['earnedAt'] as String),
          shareText: m['shareText'] as String,
        );
      }).toList();
      final breakdown = (data['charityBreakdown'] as List<dynamic>).map((e) {
        final m = e as Map<String, dynamic>;
        return CharityDonation(
          charityName: m['charityName'] as String,
          donatedCents: m['donatedCents'] as int,
        );
      }).toList();
      return ImpactSummary(
        totalDonatedCents: data['totalDonatedCents'] as int,
        commitmentsKept: data['commitmentsKept'] as int,
        commitmentsMissed: data['commitmentsMissed'] as int,
        charityBreakdown: breakdown,
        milestones: milestones,
      );
      ```
  - [x] Use `_client.dio.get<Map<String, dynamic>>(...)` pattern (same as existing methods)
  - [x] Re-run `dart run build_runner build --delete-conflicting-outputs` — regenerates `commitment_contracts_repository.g.dart`
  - [x] Commit updated `commitment_contracts_repository.g.dart`

### Flutter: `ImpactDashboardScreen` — main screen (AC: 1, 2)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/impact_dashboard_screen.dart`
  - [x] `ConsumerStatefulWidget` — needs `commitmentContractsRepositoryProvider`
  - [x] **State**:
    - `_summary`: `ImpactSummary?` — loaded on init
    - `_isLoading`: `bool` — controls loading indicator
  - [x] **On init** (`initState`): call `_loadImpact()`
  - [x] **`_loadImpact()`**:
    - Set `_isLoading = true`
    - Call `repository.getImpactSummary()`
    - On success: set `_summary` + `_isLoading = false`
    - On error: use `catch (e)` (NOT `catch (_)`); show `CupertinoAlertDialog` with `AppStrings.dialogErrorTitle` + `AppStrings.impactLoadError`; set `_isLoading = false`
  - [x] **Navigation bar**: `CupertinoNavigationBar` with `AppStrings.impactDashboardTitle`; `backgroundColor: colors.surfacePrimary`
  - [x] **Loading state**: `CupertinoActivityIndicator` centred when `_isLoading == true`
  - [x] **Empty state**: if `!_isLoading && _summary != null && _summary!.milestones.isEmpty`: show `AppStrings.impactEmptyMessage` in New York serif 20pt Regular + `colors.textSecondary`
  - [x] **Body layout** (`CustomScrollView` or `ListView`):
    - **Primary stat cells** (full-width): `commitmentsKept` and `totalDonatedCents` displayed as large stat cells — New York 34pt Regular (the number) + SF Pro 13pt `colors.textSecondary` (the label)
    - **Milestone cells** (`ImpactMilestoneCell` widget — see below) listed below primary stats
    - **Charity breakdown section**: `AppStrings.impactCharityBreakdownTitle` section header + list of `charityName: $amount` rows (SF Pro 15pt Regular)
  - [x] Background: `colors.surfacePrimary`
  - [x] **NO progress bars. NO percentage-to-goal. NO streaks.** (UX-DR19 design principle)
  - [x] Added to `app_router.dart` as `/settings/impact` sub-route under the settings branch (see routing section)

### Flutter: `ImpactMilestoneCell` — milestone display cell (AC: 1, 2)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/widgets/impact_milestone_cell.dart`
  - [x] `StatelessWidget` (pure display — caller passes data and callbacks)
  - [x] Constructor:
    ```dart
    const ImpactMilestoneCell({
      super.key,
      required this.milestone,    // ImpactMilestone
      required this.onShare,      // VoidCallback
    });
    ```
  - [x] **Anatomy** (per UX-DR19 + UX spec section 15):
    - Milestone `title` in New York 20pt Regular (voice copy — `FontFamily.newYork`)
    - Milestone `body` in New York 15pt Regular italic — emotional voice layer
    - `earnedAt` formatted as `'MMM d, yyyy'` (SF Pro 13pt `colors.textSecondary`)
    - Share button: `CupertinoButton` with `CupertinoIcons.share` + `AppStrings.impactShareButton`; `minimumSize: const Size(44, 44)`; calls `onShare`
  - [x] Cell background: `colors.surfacePrimary`; `16pt` horizontal padding; `12pt` vertical padding; separator line at bottom
  - [x] Copy is affirming — `title` and `body` use warm, non-punitive framing (UX-DR36). Even for missed commitments: no accusation, no shame. Examples:
    - Kept: "Your word is your bond." / "You showed up when it mattered."
    - Missed: "You put something on the line. That takes courage." / "One chapter closed. The next begins."
  - [x] Do NOT use streak language or progress-to-goal framing anywhere in this widget

### Flutter: `SettingsScreen` — add Impact Dashboard entry point (AC: 1)

- [x] Extend `apps/flutter/lib/features/settings/presentation/settings_screen.dart`
  - [x] Add `_SettingsTile` entry for Impact Dashboard below the Payments tile:
    ```dart
    // ── Impact Dashboard (Epic 6, Story 6.4) ────────────────────────────────────
    _SettingsTile(
      label: AppStrings.settingsImpact,
      icon: CupertinoIcons.heart_fill,
      onTap: () => context.push('/settings/impact'),
    ),
    ```
  - [x] Import `go_router` — use `context.push('/settings/impact')` (GoRouter navigation), NOT `Navigator.of(context).push`
  - [x] Comment: `// ── Impact Dashboard (Epic 6, Story 6.4) ────────────────────────────────────`

### Flutter: `app_router.dart` — add `/settings/impact` route (AC: 1)

- [x] Extend `apps/flutter/lib/core/router/app_router.dart`
  - [x] Add import for `ImpactDashboardScreen`
  - [x] Add sub-route inside the existing `/settings` `GoRoute.routes` list:
    ```dart
    GoRoute(
      path: 'impact',
      builder: (context, state) => const ImpactDashboardScreen(),
    ),
    ```
  - [x] Place after the existing `account` sub-route (before the closing `]` of `routes`)
  - [x] Regenerate `app_router.g.dart` via `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit updated `app_router.g.dart`

### Flutter: l10n strings (AC: 1, 2)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Impact Dashboard (FR27, UX-DR19) ──` section after the existing charity selection block
  - [x] `static const String impactDashboardTitle = 'Your impact';`
  - [x] `static const String impactLoadError = 'Could not load your impact data. Please try again.';`
  - [x] `static const String impactEmptyMessage = 'Your story is just beginning. Complete your first staked commitment to see your impact here.';`
  - [x] `static const String impactShareButton = 'Share';`
  - [x] `static const String impactCharityBreakdownTitle = 'Where your money went';`
  - [x] `static const String impactTotalDonatedLabel = 'donated to charity';`
  - [x] `static const String impactCommitmentsKeptLabel = 'commitments kept';`
  - [x] `static const String settingsImpact = 'Impact';`
  - [x] NOTE: `AppStrings.dialogErrorTitle` already exists — do NOT recreate

### Tests

- [x] Unit tests for `CommitmentContractsRepository.getImpactSummary()` in `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart`
  - [x] Add to existing test file (do NOT create a new one — extend the Stories 6.1/6.2/6.3 test file)
  - [x] Test: `getImpactSummary()` fires `GET /v1/impact` and maps `totalDonatedCents`, `commitmentsKept`, `commitmentsMissed`
  - [x] Test: `getImpactSummary()` maps `milestones` list with correct `id`, `title`, `body`, `earnedAt` (as `DateTime`), `shareText`
  - [x] Test: `getImpactSummary()` maps `charityBreakdown` list with correct `charityName` and `donatedCents`
  - [x] Use same `mocktail` + `MockDio` pattern from Stories 6.1/6.2/6.3

- [x] Widget tests for `ImpactMilestoneCell` in `apps/flutter/test/features/commitment_contracts/impact_milestone_cell_test.dart`
  - [x] New test file
  - [x] Test: renders milestone `title` and `body` text
  - [x] Test: renders `earnedAt` formatted date
  - [x] Test: share button calls `onShare` callback
  - [x] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors`

- [x] Widget tests for `ImpactDashboardScreen` in `apps/flutter/test/features/commitment_contracts/impact_dashboard_screen_test.dart`
  - [x] New test file
  - [x] Test: `CupertinoActivityIndicator` shown on initial load (before data arrives)
  - [x] Test: primary stat cells rendered with correct values after data loads
  - [x] Test: milestone cells rendered for each milestone in summary
  - [x] Test: empty state message shown when `milestones` is empty
  - [x] Override `commitmentContractsRepositoryProvider` — same `ProviderContainer` pattern as Stories 5.4/5.6/6.1/6.2/6.3
  - [x] Use `pump()` (NOT `pumpAndSettle()`) when `_isLoading=true` to avoid `CupertinoActivityIndicator` timeout (same issue as `charity_sheet_screen_test.dart`)

## Dev Notes

### CRITICAL: This is Epic 6, Story 4 — impact endpoint is a stub with TODO(impl) markers

Per Epic 6 pattern established in Stories 6.1–6.3: all impact API endpoints are stubs returning hardcoded fixture data. The actual database aggregation (querying `commitment_contracts` + `task_stakes` for totals) is deferred — Story 6.5 (Automated Charge Processing) is when real charge data exists. Add `TODO(impl)` comments per the established pattern.

### CRITICAL: Stub data for `GET /v1/impact`

```typescript
{
  totalDonatedCents: 2500,          // $25.00
  commitmentsKept: 3,
  commitmentsMissed: 1,
  charityBreakdown: [
    { charityName: 'American Red Cross', donatedCents: 2500 },
  ],
  milestones: [
    {
      id: 'first-kept',
      title: 'First commitment kept.',
      body: 'You showed up when it mattered.',
      earnedAt: new Date().toISOString(),
      shareText: "I kept my first commitment with On Task. Your past self makes plans. Your future self keeps them.",
    },
    {
      id: 'first-donation',
      title: 'First donation made.',
      body: 'Even a missed commitment moved something good into the world.',
      earnedAt: new Date().toISOString(),
      shareText: "I donated $25 to the American Red Cross through On Task accountability.",
    },
    {
      id: 'hundred-donated',
      title: '$100 donated.',
      body: 'Look how far you\'ve come.',
      earnedAt: new Date().toISOString(),
      shareText: "I've donated over $100 to charity through On Task. Accountability that does good.",
    },
  ],
}
```

### CRITICAL: No `index.ts` change needed

`commitmentContractsRouter` is already mounted in `apps/api/src/index.ts` at `app.route('/', commitmentContractsRouter)`. All new impact routes live in `commitment-contracts.ts` and are automatically included.

### CRITICAL: Route registration in `commitment-contracts.ts`

Register `GET /v1/impact` AFTER the existing `GET /v1/charities` route (the last charity route). Follow the same `createRoute` + `OpenAPIHono` handler pattern used for `getCharitiesRoute`, `getDefaultCharityRoute`, `putDefaultCharityRoute`. Tag: `'Impact'`.

### CRITICAL: `@hono/zod-openapi` — always use `createRoute` pattern

```typescript
const getImpactRoute = createRoute({
  method: 'get',
  path: '/v1/impact',
  tags: ['Impact'],
  summary: 'Get user impact summary',
  description: '...',
  responses: {
    200: {
      content: { 'application/json': { schema: ImpactResponseSchema } },
      description: 'Impact summary with milestones',
    },
  },
})

app.openapi(getImpactRoute, (c) => {
  // TODO(impl): query commitment_contracts + task_stakes for userId = JWT sub
  return c.json({ data: stubImpactData })
})
```

### CRITICAL: TypeScript local imports use `.js` extensions

```typescript
import { ok, err } from '../lib/response.js'
// New schemas live in the same file — no import needed
```

### CRITICAL: `drizzle-kit generate` runs from `apps/api/` (not `packages/core/`)

No DB schema changes in this story — `GET /v1/impact` aggregates existing columns (`charityId`, `charityName`, `stakeAmountCents`). No migration needed. Do NOT run `drizzle-kit generate` unless a schema change is explicitly required.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

After adding `ImpactMilestone` and `ImpactSummary` models and extending `CommitmentContractsRepository`:
```
dart run build_runner build --delete-conflicting-outputs
```
Commit ALL generated files. No `build_runner` in CI.

Files needing generation/regeneration in this story:
- `impact_milestone.freezed.dart` — new Freezed model (new file)
- `impact_summary.freezed.dart` — new Freezed model (new file)
- `commitment_contracts_repository.g.dart` — updated (new method added to existing `@riverpod` class)
- `app_router.g.dart` — updated (new route added)

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

Use `colors.surfacePrimary` for screen and cell backgrounds. `backgroundPrimary` does not exist.
Access: `final colors = Theme.of(context).extension<OnTaskColors>()!;`

### CRITICAL: `minimumSize: const Size(44, 44)` on ALL `CupertinoButton` instances

Every new `CupertinoButton` in `ImpactDashboardScreen` and `ImpactMilestoneCell` (including the share button) must include `minimumSize: const Size(44, 44)`.

### CRITICAL: All UI strings in `AppStrings` — no hardcoded strings

All static UI copy (title, labels, errors, empty state) must be in `AppStrings`. The milestone `title`, `body`, and `shareText` values come from the API response — they are NOT in `AppStrings`.

### CRITICAL: `catch (e)` not `catch (_)` in all error handlers

Use `catch (e)` in `_loadImpact()`. Check `DioException` type if distinguishing network vs. unexpected errors. Never use bare `catch (_)`.

### CRITICAL: No DB changes — no migration needed

The impact summary aggregates data already stored across existing tables (`commitment_contracts.charityId`, `commitment_contracts.charityName`, and `task_stakes.stakeAmountCents`). All column changes landed in Stories 6.2 and 6.3. Next migration (if ever needed) would be `0015_*.sql`.

### CRITICAL: `ImpactDashboardScreen` IS added to `app_router.dart`

Unlike `CharitySheetScreen` (modal popup — NOT in router) and `StakeSheetScreen` (modal popup — NOT in router), `ImpactDashboardScreen` is a full navigable screen accessible from Settings. It IS added to `app_router.dart` as `/settings/impact`. Use `context.push('/settings/impact')` from `SettingsScreen` (GoRouter, not `Navigator.push`).

### CRITICAL: `use_null_aware_elements` linter info

If building `List<Map<String, String>>` query params with nullable-conditional entries, use `if (x != null) 'key': x` form (NOT `?'key': value` null-aware form) — same pattern established in Story 6.3 repository methods. Null-aware map elements produce `Map<String, String?>` type mismatch.

### Typography: New York serif for milestone text

Per UX spec (line 716, 729):
- Milestone `title`: New York 20pt Regular (`const TextStyle(fontFamily: 'NewYork', fontSize: 20, fontWeight: FontWeight.w400)`)
- Milestone `body`: New York 15pt Regular italic (`const TextStyle(fontFamily: 'NewYork', fontSize: 15, fontStyle: FontStyle.italic)`)
- Large stat number (kept/donated): New York 34pt Regular
- Stat label: SF Pro 13pt `colors.textSecondary`

New York is a system font on all supported Apple devices — zero bundle cost. Use `fontFamily: 'NewYork'` (matches existing pattern from `NowEmptyState` and `ChapterBreakScreen`).

### UX: Impact Dashboard is NOT a stats page

Per UX-DR19 and UX spec lines 249–258 and 341–347:
- No progress bars
- No percentage-to-goal
- No streak mechanics (On Task deliberately avoids streaks — UX spec line 422)
- Milestones accumulate — they never reset
- The framing is "evidence of who you've become" — a record, not a scoreboard

### UX: Share sheet — native iOS sharing via `share_plus`

`share_plus: ^10.0.0` is already in `apps/flutter/pubspec.yaml`. Use `Share.share(milestone.shareText)` from the `share_plus` package. No additional dependency needed.

```dart
import 'package:share_plus/share_plus.dart';

// In ImpactMilestoneCell or ImpactDashboardScreen:
Share.share(milestone.shareText);
```

The share sheet is the system iOS share sheet — no custom UI needed. Just call `Share.share(text)`.

### UX: Copy must be affirming even for missed commitments (UX-DR36)

"Copy is affirming for both kept and missed commitments — no punitive language." From the UX spec (line 335): "Recovery UI = 'gentle hand on the shoulder' — never a transaction summary." Even a missed stake that generated a donation is framed positively. Stub milestone copy must reflect this.

### UX: Location — accessible from Settings (profile icon)

UX spec (line 258): "Location: accessible from the profile/account icon." In On Task's nav structure this means Settings (the profile/account branch). The `SettingsScreen` tile navigates to `/settings/impact`. No new top-level tab — it is a sub-screen of Settings.

### UX: `pumpAndSettle` timeout with `CupertinoActivityIndicator`

Known issue from Story 6.3 (`charity_sheet_screen_test.dart`): `pumpAndSettle()` times out when `_isLoading=true` and a `CupertinoActivityIndicator` is visible (spinner animation keeps ticking). Use `pump()` instead of `pumpAndSettle()` in that specific test case.

### Existing routes in `commitment-contracts.ts` — do NOT modify

Currently registered (from Stories 6.1 + 6.2 + 6.3):
- `GET /v1/payment-method`
- `POST /v1/payment-method/setup-session`
- `POST /v1/payment-method/confirm`
- `DELETE /v1/payment-method`
- `GET /v1/tasks/:taskId/stake`
- `PUT /v1/tasks/:taskId/stake`
- `DELETE /v1/tasks/:taskId/stake`
- `GET /v1/charities/default`
- `PUT /v1/charities/default`
- `GET /v1/charities`

Add `GET /v1/impact` after these.

### Previous story learnings carried forward (Stories 6.1–6.3)

- `drizzle-kit generate` runs from `apps/api/` (not `packages/core/`)
- Generated `.freezed.dart` and `.g.dart` files must be committed
- Use `catch (e)` not `catch (_)` in all error handlers
- `OnTaskColors.surfacePrimary` for sheet/card/screen backgrounds (not `backgroundPrimary`)
- `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances
- `commitmentContractsRouter` is already mounted — no `index.ts` changes needed
- All UI strings in `AppStrings` (no hardcoded strings)
- Widget tests: wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors`
- Repository tests: extend existing `commitment_contracts_repository_test.dart` file (do NOT create a new one)
- All routes use `createRoute` pattern with `@hono/zod-openapi`
- TypeScript imports use `.js` extensions
- `pumpAndSettle()` times out with `CupertinoActivityIndicator` — use `pump()` instead

### Deferred items from Story 6.3 that may impact this story

- **Stale search results in `CharitySheetScreen`** — deferred; not applicable to this story
- **Review finding**: `catch (_)` in `_loadDefaultCharity` patched in 6.3 review — ensure `catch (e)` is used everywhere in this story from the start

### Project Structure — files to create/modify

New files:
- `apps/flutter/lib/features/commitment_contracts/domain/impact_milestone.dart`
- `apps/flutter/lib/features/commitment_contracts/domain/impact_milestone.freezed.dart` (generate)
- `apps/flutter/lib/features/commitment_contracts/domain/impact_summary.dart`
- `apps/flutter/lib/features/commitment_contracts/domain/impact_summary.freezed.dart` (generate)
- `apps/flutter/lib/features/commitment_contracts/presentation/impact_dashboard_screen.dart`
- `apps/flutter/lib/features/commitment_contracts/presentation/widgets/impact_milestone_cell.dart`
- `apps/flutter/test/features/commitment_contracts/impact_milestone_cell_test.dart`
- `apps/flutter/test/features/commitment_contracts/impact_dashboard_screen_test.dart`

Modified files:
- `apps/api/src/routes/commitment-contracts.ts` — add `GET /v1/impact` route + schemas
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` — add `getImpactSummary()` method
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart` — regenerate
- `apps/flutter/lib/features/settings/presentation/settings_screen.dart` — add Impact tile
- `apps/flutter/lib/core/router/app_router.dart` — add `/settings/impact` route
- `apps/flutter/lib/core/router/app_router.g.dart` — regenerate
- `apps/flutter/lib/core/l10n/strings.dart` — add impact UI strings

### References

- Epic 6 story definition: `_bmad-output/planning-artifacts/epics.md` lines 1573–1591
- UX Impact Dashboard spec: `_bmad-output/planning-artifacts/ux-design-specification.md` lines 249–258
- UX Identity narrative + impact framing: `_bmad-output/planning-artifacts/ux-design-specification.md` lines 337–347
- UX Impact Dashboard Cells (component 15): `_bmad-output/planning-artifacts/ux-design-specification.md` lines 1298–1308
- UX Typography — New York for milestones: `_bmad-output/planning-artifacts/ux-design-specification.md` lines 715–731
- UX No streaks by design: `_bmad-output/planning-artifacts/ux-design-specification.md` line 422
- UX-DR36 (no punitive language): `_bmad-output/planning-artifacts/epics.md` line 317
- Architecture Flutter feature path: `_bmad-output/planning-artifacts/architecture.md` line 869
- Architecture `commitment_contracts` feature location: `apps/flutter/lib/features/commitment_contracts/`
- `share_plus` in pubspec: `apps/flutter/pubspec.yaml`
- Existing routes (6.1–6.3): `apps/api/src/routes/commitment-contracts.ts`
- Existing repository: `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`
- Settings screen (entry point): `apps/flutter/lib/features/settings/presentation/settings_screen.dart`
- App router (route registration): `apps/flutter/lib/core/router/app_router.dart`
- Previous story patterns: `_bmad-output/implementation-artifacts/6-3-charity-selection.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `Container` with both `color` and `decoration` in `ImpactMilestoneCell` — moved color inside `BoxDecoration`.
- `intl` package not in pubspec — used manual month-name formatter in `ImpactMilestoneCell._formatDate()`.
- Loading state test used `Completer<ImpactSummary>` (resolved at end of test) instead of `Future.delayed` to avoid pending-timer assertion failure.

### Completion Notes List

- Implemented `GET /v1/impact` stub endpoint in `commitment-contracts.ts` with `milestoneSchema` + `impactSummarySchema` Zod schemas; returns hardcoded 3-milestone fixture per Epic 6 stub pattern.
- Created Freezed domain models `ImpactMilestone` and `ImpactSummary` (with nested `CharityDonation`); generated `.freezed.dart` files.
- Added `getImpactSummary()` to `CommitmentContractsRepository`; regenerated `.g.dart`.
- Created `ImpactDashboardScreen` (`ConsumerStatefulWidget`) with loading/empty/loaded states, New York serif typography, no progress bars/streaks (UX-DR19), `catch (e)` error handling.
- Created `ImpactMilestoneCell` (`StatelessWidget`) with New York serif title + italic body, manual date formatter, affirming copy framing (UX-DR36), `minimumSize: Size(44, 44)` on share button.
- Added `settingsImpact` tile to `SettingsScreen` using GoRouter `context.push('/settings/impact')`.
- Registered `/settings/impact` sub-route in `app_router.dart`; regenerated `app_router.g.dart`.
- Added 8 l10n strings to `AppStrings` under `// ── Impact Dashboard (FR27, UX-DR19) ──` section.
- All tests pass: 3 repository unit tests, 3 `ImpactMilestoneCell` widget tests, 4 `ImpactDashboardScreen` widget tests; full regression suite passes (exit code 0).

### File List

apps/api/src/routes/commitment-contracts.ts
apps/flutter/lib/features/commitment_contracts/domain/impact_milestone.dart
apps/flutter/lib/features/commitment_contracts/domain/impact_milestone.freezed.dart
apps/flutter/lib/features/commitment_contracts/domain/impact_summary.dart
apps/flutter/lib/features/commitment_contracts/domain/impact_summary.freezed.dart
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart
apps/flutter/lib/features/commitment_contracts/presentation/impact_dashboard_screen.dart
apps/flutter/lib/features/commitment_contracts/presentation/widgets/impact_milestone_cell.dart
apps/flutter/lib/features/settings/presentation/settings_screen.dart
apps/flutter/lib/core/router/app_router.dart
apps/flutter/lib/core/router/app_router.g.dart
apps/flutter/lib/core/l10n/strings.dart
apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart
apps/flutter/test/features/commitment_contracts/impact_milestone_cell_test.dart
apps/flutter/test/features/commitment_contracts/impact_dashboard_screen_test.dart

### Change Log

- 2026-04-01: Story 6.4 Impact Dashboard implemented — `GET /v1/impact` stub endpoint, `ImpactMilestone`/`ImpactSummary` Freezed models, `getImpactSummary()` repository method, `ImpactDashboardScreen`, `ImpactMilestoneCell`, Settings tile, router sub-route, l10n strings, and full test coverage (10 new tests).
