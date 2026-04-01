# Story 6.3: Charity Selection

Status: review

## Story

As a user,
I want to choose where my missed stakes go from a catalog of nonprofits,
So that the consequence of missing a commitment supports a cause I actually care about.

## Acceptance Criteria

1. **Given** the commitment flow reaches the charity selection step
   **When** the catalog is shown
   **Then** a searchable list of nonprofits is presented sourced from the Every.org API (FR26)
   **And** nonprofits can be browsed by category and searched by name

2. **Given** the user selects a charity
   **When** they confirm
   **Then** the selection is persisted as their default charity for future stakes

3. **Given** the user has a default charity set
   **When** they open a new commitment flow
   **Then** their default charity is pre-selected, and they can change it

## Tasks / Subtasks

### Backend: DB schema — add `charityId` and `charityName` columns to `commitment_contracts` table (AC: 2, 3)

- [x] Modify `packages/core/src/schema/commitment-contracts.ts` (AC: 2, 3)
  - [x] Add column: `charityId: text()` — nullable; Every.org nonprofit ID (slug); null means no default charity set
  - [x] Add column: `charityName: text()` — nullable; display name cached from Every.org; avoids re-fetch on every render
  - [x] Place after `hasActiveStakes` and before `setupSessionToken` — follow existing column ordering
  - [x] Use `text()` for both — charityId is an alphanumeric slug, charityName is a display string
  - [x] No `.notNull()` — charity selection is optional; users can set a stake without selecting a charity (Story 6.8 handles the full commitment lock flow)

- [x] Generate migration `packages/core/src/schema/migrations/0014_charity_selection.sql` (AC: 2, 3)
  - [x] Run `pnpm drizzle-kit generate` from `apps/api/` (where `drizzle.config.ts` lives — NOT `packages/core/`)
  - [x] Commit generated SQL, updated `meta/_journal.json`, and `meta/0014_snapshot.json`
  - [x] Migration: `ALTER TABLE commitment_contracts ADD COLUMN charity_id text; ALTER TABLE commitment_contracts ADD COLUMN charity_name text;`

### Backend: API — charity endpoints in `apps/api/src/routes/commitment-contracts.ts` (AC: 1, 2, 3)

- [x] Add charity schemas (AC: 1, 2, 3)
  ```typescript
  const nonprofitSchema = z.object({
    id: z.string(),           // Every.org nonprofit slug (e.g. 'american-red-cross')
    name: z.string(),
    description: z.string().nullable(),
    logoUrl: z.string().nullable(),
    categories: z.array(z.string()),
  })

  const nonprofitListSchema = z.object({
    nonprofits: z.array(nonprofitSchema),
    total: z.number().int(),
  })

  const charitySelectionRequestSchema = z.object({
    charityId: z.string(),
    charityName: z.string(),
  })

  const charitySelectionResponseSchema = z.object({
    charityId: z.string().nullable(),
    charityName: z.string().nullable(),
  })
  ```

- [x] Add `GET /v1/charities` — search/browse nonprofits from Every.org (AC: 1)
  - [x] Query params: `search?: string`, `category?: string`
  - [x] Request schema: `z.object({ search: z.string().optional(), category: z.string().optional() })`
  - [x] Response 200: `{ data: nonprofitListSchema }`
  - [x] Tag: `'Charity'`
  - [x] Stub: return hardcoded list of 5 nonprofits (Red Cross, Doctors Without Borders, WWF, UNICEF, EFF)
  - [x] Add `TODO(impl): proxy to Every.org search API — GET https://api.every.org/v0.2/search/{query}?apiKey=ENV; fallback to browse endpoint for empty query; filter by category if provided`

- [x] Add `GET /v1/charities/default` — get the user's current default charity (AC: 3)
  - [x] Response 200: `{ data: charitySelectionResponseSchema }`
  - [x] Stub: return `{ charityId: null, charityName: null }`
  - [x] Tag: `'Charity'`
  - [x] Add `TODO(impl): query commitment_contracts for userId = JWT sub; return charityId + charityName`
  - [x] **CRITICAL registration order**: register `GET /v1/charities/default` BEFORE `GET /v1/charities/:charityId` (specific before parameterized)

- [x] Add `PUT /v1/charities/default` — set the user's default charity (AC: 2)
  - [x] Request body schema: `charitySelectionRequestSchema`
  - [x] Response 200: `{ data: charitySelectionResponseSchema }`
  - [x] Stub: return `{ charityId: body.charityId, charityName: body.charityName }`
  - [x] Tag: `'Charity'`
  - [x] Add `TODO(impl): upsert commitment_contracts.charityId and commitment_contracts.charityName for userId = JWT sub`

- [x] Route registration order in `commitment-contracts.ts` — add charity routes after existing stake routes:
  - Order: `GET /v1/charities/default` → `PUT /v1/charities/default` → `GET /v1/charities`
  - Register AFTER the existing DELETE stake route
  - No change to `apps/api/src/index.ts` — `commitmentContractsRouter` is already mounted

### Flutter: Domain model — `Nonprofit` in `apps/flutter/lib/features/commitment_contracts/domain/` (AC: 1)

- [x] Create `apps/flutter/lib/features/commitment_contracts/domain/nonprofit.dart`
  - [x] Freezed model:
    ```dart
    @freezed
    class Nonprofit with _$Nonprofit {
      const factory Nonprofit({
        required String id,         // Every.org slug
        required String name,
        String? description,
        String? logoUrl,
        @Default([]) List<String> categories,
      }) = _Nonprofit;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit generated `nonprofit.freezed.dart`

### Flutter: Domain model — `CharitySelection` in `apps/flutter/lib/features/commitment_contracts/domain/` (AC: 2, 3)

- [x] Create `apps/flutter/lib/features/commitment_contracts/domain/charity_selection.dart`
  - [x] Freezed model:
    ```dart
    @freezed
    class CharitySelection with _$CharitySelection {
      const factory CharitySelection({
        String? charityId,     // null = no default set
        String? charityName,
      }) = _CharitySelection;
    }
    ```
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Commit generated `charity_selection.freezed.dart`

### Flutter: Repository — charity methods in `CommitmentContractsRepository` (AC: 1, 2, 3)

- [x] Extend `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`
  - [x] Add method: `Future<List<Nonprofit>> searchCharities({ String? query, String? category })` — `GET /v1/charities`
    - Build query params: `{ if (query != null) 'search': query, if (category != null) 'category': category }`
    - Parse: `data['nonprofits'] as List` → map each to `Nonprofit(id: ..., name: ..., description: ..., logoUrl: ..., categories: ...)`
  - [x] Add method: `Future<CharitySelection> getDefaultCharity()` — `GET /v1/charities/default`
    - Parse: `CharitySelection(charityId: data['charityId'] as String?, charityName: data['charityName'] as String?)`
  - [x] Add method: `Future<CharitySelection> setDefaultCharity(String charityId, String charityName)` — `PUT /v1/charities/default`
    - Body: `{ 'charityId': charityId, 'charityName': charityName }`
    - Parse: same as `getDefaultCharity`
  - [x] Use `_client.dio.get/put<Map<String, dynamic>>(...)` pattern (same as existing methods)
  - [x] Re-run `dart run build_runner build --delete-conflicting-outputs` — regenerates `commitment_contracts_repository.g.dart`
  - [x] Commit updated `commitment_contracts_repository.g.dart`

### Flutter: `CharitySearchDelegate` — search widget (AC: 1)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/widgets/charity_search_delegate.dart`
  - [x] `StatefulWidget` (no Riverpod — pure UI display, caller passes data and callbacks)
  - [x] Constructor:
    ```dart
    const CharitySearchDelegate({
      super.key,
      required this.nonprofits,         // List<Nonprofit> — current results to display
      required this.isLoading,          // bool — show loading indicator
      required this.onSearchChanged,    // (String query) → void
      required this.onCategoryChanged,  // (String? category) → void
      required this.onSelected,         // (Nonprofit) → void
      this.selectedCharityId,           // String? — currently selected (for checkmark)
    });
    ```
  - [x] **Category filter row**: horizontal scrollable `CupertinoSlidingSegmentedControl`-style row with category chips
    - Categories (hardcoded): "All", "Health", "Environment", "Education", "Human Rights", "Animals"
    - Tapping a category calls `onCategoryChanged(category)` (null for "All")
    - Active chip: `colors.surfacePrimary` background with `colors.accentPrimary` border; inactive: light grey
  - [x] **Search input**: `CupertinoSearchTextField` at top of widget
    - On change: call `onSearchChanged(query)` — debounce in parent (`_CharitySheetScreenState`)
    - `placeholder: AppStrings.charitySearchPlaceholder`
  - [x] **Results list**: `ListView.builder` of nonprofit rows
    - Each row: nonprofit logo (if `logoUrl != null` use `cached_network_image` via `Image.network`; else `CupertinoIcons.heart_fill` fallback in `colors.accentPrimary`) + name (16pt Medium) + description snippet (13pt, `colors.textSecondary`, max 2 lines)
    - Selected indicator: `CupertinoIcons.checkmark_circle_fill` in `colors.accentPrimary` at trailing
    - Tap: call `onSelected(nonprofit)`
    - `minimumSize: const Size(44, 44)` is not directly applicable on `GestureDetector`/`InkWell` — ensure tap target height is ≥ 44pt via padding
  - [x] **Loading state**: `CupertinoActivityIndicator` centred when `isLoading == true` and `nonprofits.isEmpty`
  - [x] **Empty state**: if `!isLoading && nonprofits.isEmpty`: show `AppStrings.charitySearchEmpty` in `colors.textSecondary`
  - [x] Background: `colors.surfacePrimary`

### Flutter: `CharitySheetScreen` — modal bottom sheet (AC: 1, 2, 3)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/charity_sheet_screen.dart` (AC: 1, 2, 3)
  - [x] `ConsumerStatefulWidget` — needs `commitmentContractsRepositoryProvider`
  - [x] Constructor: `CharitySheetScreen({ this.currentCharityId })`
    - `currentCharityId` is the already-selected charityId (if any), used to pre-select in list
  - [x] Presented as a modal bottom sheet — caller uses `showCupertinoModalPopup` or `showModalBottomSheet`
    - **NOT pushed onto navigation stack** — do NOT add to `app_router.dart`
  - [x] **State**:
    - `_nonprofits`: `List<Nonprofit>` — current search results
    - `_isLoading`: `bool` — controls loading indicator
    - `_selectedCharity`: `Nonprofit?` — current selection
    - `_searchQuery`: `String` — debounced
    - `_selectedCategory`: `String?`
  - [x] **On init** (`initState`):
    - Call `_loadCharities()` with no query — loads default catalog
    - If no existing default, pre-select nothing; if `currentCharityId != null`, mark as selected when results load
  - [x] **`_loadCharities()`**:
    - Set `_isLoading = true`
    - Call `repository.searchCharities(query: _searchQuery.isEmpty ? null : _searchQuery, category: _selectedCategory)`
    - On success: set `_nonprofits` + `_isLoading = false`
    - On error: `CupertinoAlertDialog` with `AppStrings.dialogErrorTitle` + `AppStrings.charityLoadError`; set `_isLoading = false`
  - [x] **Search debounce**: 400ms debounce on `onSearchChanged` — use `Timer` from `dart:async`; cancel previous timer before starting new one
  - [x] **Confirm button**: `CupertinoButton` primary style at bottom, `AppStrings.charityConfirmButton`
    - Disabled when `_selectedCharity == null`
    - `minimumSize: const Size(44, 44)`
    - On tap: call `repository.setDefaultCharity(_selectedCharity!.id, _selectedCharity!.name)` with `_isLoading` guard
    - On success: `Navigator.pop(context, _selectedCharity)` — returns `Nonprofit?` to caller
    - On error: `CupertinoAlertDialog` with `AppStrings.dialogErrorTitle` + `AppStrings.charitySetError`
  - [x] **Header**: sheet title `AppStrings.charitySheetTitle`, close `CupertinoButton` with `CupertinoIcons.xmark`
  - [x] Background: `colors.surfacePrimary`
  - [x] `_isLoading` bool for save state — `setState` pattern (same as `StakeSheetScreen`)

### Flutter: `StakeSheetScreen` — add charity selection entry point (AC: 1, 2, 3)

- [x] Extend `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart`
  - [x] Add charity selection row below the `StakeSliderWidget`:
    - When no charity selected: `CupertinoButton` with `CupertinoIcons.heart` + `AppStrings.charitySelectCta`
    - When charity selected: show charity name + `CupertinoIcons.checkmark_circle_fill` in `colors.accentPrimary` + tap to change
  - [x] On tap: open `CharitySheetScreen` via `showCupertinoModalPopup<Nonprofit?>`:
    ```dart
    final selected = await showCupertinoModalPopup<Nonprofit?>(
      context: context,
      builder: (_) => CharitySheetScreen(
        currentCharityId: _selectedCharity?.id,
      ),
    );
    if (selected != null) setState(() => _selectedCharity = selected);
    ```
  - [x] Add `_selectedCharity: Nonprofit?` to `StakeSheetScreen` state
  - [x] On init: call `repository.getDefaultCharity()` to pre-populate `_selectedCharity` if one exists
  - [x] Comment: `// ── Charity selection (Epic 6, Story 6.3) ────────────────────`

### Flutter: l10n strings (AC: 1, 2, 3)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Charity selection (FR26, UX-DR8) ──` section
  - [x] `static const String charitySheetTitle = 'Choose a cause';`
  - [x] `static const String charitySearchPlaceholder = 'Search nonprofits…';`
  - [x] `static const String charityConfirmButton = 'Confirm';`
  - [x] `static const String charitySelectCta = 'Choose a cause';`
  - [x] `static const String charityChangeCta = 'Change';`
  - [x] `static const String charityLoadError = 'Could not load nonprofits. Please try again.';`
  - [x] `static const String charitySetError = 'Could not save your charity selection. Please try again.';`
  - [x] `static const String charitySearchEmpty = 'No nonprofits found. Try a different search.';`
  - [x] NOTE: `AppStrings.actionCancel`, `AppStrings.dialogErrorTitle` already exist — do NOT recreate

### Tests

- [x] Unit tests for `CommitmentContractsRepository` charity methods in `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart`
  - [x] Add to existing test file (do NOT create a new one — extend Stories 6.1/6.2 test file)
  - [x] Test: `searchCharities()` fires `GET /v1/charities` with no params and maps nonprofit list
  - [x] Test: `searchCharities(query: 'red cross')` fires `GET /v1/charities?search=red+cross`
  - [x] Test: `searchCharities(category: 'Health')` fires `GET /v1/charities?category=Health`
  - [x] Test: `getDefaultCharity()` fires `GET /v1/charities/default` and maps `charityId` + `charityName`
  - [x] Test: `setDefaultCharity('american-red-cross', 'American Red Cross')` fires `PUT /v1/charities/default` with correct body
  - [x] Use same `mocktail` + `MockDio` pattern from Stories 6.1/6.2

- [x] Widget tests for `CharitySearchDelegate` in `apps/flutter/test/features/commitment_contracts/charity_search_delegate_test.dart`
  - [x] New test file
  - [x] Test: renders nonprofit list rows
  - [x] Test: selected nonprofit shows checkmark
  - [x] Test: empty state message shown when `nonprofits` is empty and `!isLoading`
  - [x] Test: `CupertinoActivityIndicator` shown when `isLoading == true` and `nonprofits.isEmpty`
  - [x] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

- [x] Widget tests for `CharitySheetScreen` in `apps/flutter/test/features/commitment_contracts/charity_sheet_screen_test.dart`
  - [x] New test file
  - [x] Test: Confirm button is disabled before selection
  - [x] Test: Confirm button is enabled after selecting a nonprofit
  - [x] Test: selecting a nonprofit updates the checkmark in the list
  - [x] Override `commitmentContractsRepositoryProvider` — same `ProviderContainer` pattern as Stories 5.4/5.6/6.1/6.2

## Dev Notes

### CRITICAL: This is Epic 6, Story 3 — all charity API calls are stubs with TODO(impl) markers

Per Epic 6 note: Story 13.1 (AASA + payment pages) must be deployed before Epic 6 can be tested end-to-end. All charity endpoints are stubs. The actual Every.org API integration (proxy call from the API worker) is deferred — the stub returns fixture data. Story 6.5 (Automated Charge Processing) is where disbursement actually fires.

### CRITICAL: Migration numbering — next is 0014

`0013_stake_amount_cents.sql` was created in Story 6.2. Next migration is `0014_charity_selection.sql`. Run `pnpm drizzle-kit generate` from `apps/api/` (not `packages/core/`) — the `drizzle.config.ts` lives in `apps/api/`.

### CRITICAL: `charityId` and `charityName` go on `commitment_contracts`, NOT `tasks`

`commitment_contracts` stores per-user defaults (payment method + charity). Individual task stakes do NOT carry their own charityId — the user's default charity at charge time is used. This is consistent with the existing `commitment_contracts` schema: one row per user, holding `stripePaymentMethodId`, `hasActiveStakes`, and now `charityId`/`charityName`.

### CRITICAL: Route registration order — `GET /v1/charities/default` before `GET /v1/charities/:charityId`

Within `commitment-contracts.ts`, `GET /v1/charities/default` must be registered BEFORE any parameterized `GET /v1/charities/:charityId` route (if added in a future story). Currently this story only adds `GET /v1/charities` (search/list) and `GET /v1/charities/default` + `PUT /v1/charities/default` — no parameterized route. Register in order: `GET /v1/charities/default` → `PUT /v1/charities/default` → `GET /v1/charities`. All after the existing DELETE stake route.

### CRITICAL: `CharitySheetScreen` is NOT added to `app_router.dart`

Like `StakeSheetScreen`, `CharitySheetScreen` is presented as a `CupertinoModalPopup` from within `StakeSheetScreen`. No named route. No AppRouter change. Do NOT add any new route to `app_router.dart`.

### CRITICAL: No `index.ts` change needed

`commitmentContractsRouter` is already mounted in `apps/api/src/index.ts` at `app.route('/', commitmentContractsRouter)`. All new charity routes live in `commitment-contracts.ts` and are automatically included.

### CRITICAL: `@hono/zod-openapi` — always use `createRoute` pattern

All charity routes must use `createRoute({ method, path, tags, request, responses })`. Tag: `'Charity'`. Follow the exact pattern in `commitment-contracts.ts` for `getPaymentMethodRoute`, `getTaskStakeRoute`, etc.

### CRITICAL: TypeScript local imports use `.js` extensions

```typescript
// Correct — already established in commitment-contracts.ts
import { ok, err } from '../lib/response.js'
// New schemas live in the same file — no import needed
```

### CRITICAL: Drizzle `casing: 'camelCase'`

Write new columns as `charityId: text()` and `charityName: text()` in `commitment-contracts.ts`. Drizzle generates `charity_id` and `charity_name` DDL automatically. Do NOT add manual `.name()` overrides.

### CRITICAL: `{ withTimezone: true }` on timestamp columns

New `charityId` and `charityName` columns are `text()` — no timezone concern. The existing timestamp columns in the table already use `{ withTimezone: true }` (established in Story 6.1 patches). Do not touch existing columns.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

After adding `Nonprofit` and `CharitySelection` models and extending `CommitmentContractsRepository`:
```
dart run build_runner build --delete-conflicting-outputs
```
Commit ALL generated files. No `build_runner` in CI.

Files needing generation/regeneration in this story:
- `nonprofit.freezed.dart` — new Freezed model (new file)
- `charity_selection.freezed.dart` — new Freezed model (new file)
- `commitment_contracts_repository.g.dart` — updated (new methods added to existing `@riverpod` class)

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

Use `colors.surfacePrimary` for sheet backgrounds. `backgroundPrimary` does not exist.
Access: `final colors = Theme.of(context).extension<OnTaskColors>()!;`

### CRITICAL: `minimumSize: const Size(44, 44)` on ALL `CupertinoButton` instances

Every new `CupertinoButton` in `CharitySheetScreen` must include `minimumSize: const Size(44, 44)`.

### CRITICAL: All UI strings in `AppStrings` — no hardcoded strings

Category filter labels ("All", "Health", etc.) are the one exception — they are data-driven display values from the API stub. All static UI copy (titles, CTAs, errors, placeholders) must be in `AppStrings`.

### CRITICAL: No `console.log` / no sensitive data in logs

The Every.org API key must NOT appear in any log output. The stub returns hardcoded data so there is no API key in this story, but the `TODO(impl)` comment must note: `// NEVER log apiKey`.

### CRITICAL: `z.record()` requires two arguments (if used)

If any Zod schema uses `z.record(...)`, use `z.record(z.string(), valueType)` — two args required. Not applicable in current schemas but guard against it if extending.

### UX: Charity selection is a modal bottom sheet (from UX spec)

UX spec (line 1452): "Used for: Guided chat input, proof capture, charity selection, payment setup. Standard iOS bottom sheet presentation. Swipe-down to dismiss." `CharitySheetScreen` must be presented as a modal bottom sheet, not pushed onto the nav stack.

### UX: VoiceOver focus — first charity option on sheet open (from UX spec)

UX spec (line 1682): "Charity selection → First charity option". When `CharitySheetScreen` opens, VoiceOver focus should land on the first nonprofit in the list. Use `Semantics` with `focusable: true` on the first list item, or `SemanticsService.announce()` with the first nonprofit name. Ensure the list has a semantic label.

### UX: Non-blocking charity selection

UX spec (line 1038): "Calendar permission, commitment stake, proof mode, charity selection, Guided vs. Quick capture — none of these block the user from completing their goal." Charity selection is presented within `StakeSheetScreen` as an optional enrichment row — the "Lock it in." confirm button in `StakeSheetScreen` should NOT be disabled when no charity is selected. A missing default charity is valid; disbursement destination defaults to a platform-chosen charity in `Story 6.5`.

### UX: `CharitySheetScreen` tone — agency and intentionality (from UX spec)

UX spec (line 333): "Creating a commitment → Agency, intentionality, ceremony." The header `AppStrings.charitySheetTitle = 'Choose a cause'` reflects this. Copy must not feel transactional — this is the user choosing what their money supports, not filling out a form.

### Existing commitment_contracts schema after Story 6.2

Current columns in `commitmentContractsTable` (for reference — do NOT modify existing columns):
- `id`, `userId`, `stripeCustomerId`, `stripePaymentMethodId`, `paymentMethodLast4`, `paymentMethodBrand`
- `hasActiveStakes`, `setupSessionToken`, `setupSessionExpiresAt`
- `createdAt`, `updatedAt`

Add `charityId` and `charityName` after `hasActiveStakes`.

### Existing routes in `commitment-contracts.ts` — do NOT modify

Currently registered (from Stories 6.1 + 6.2):
- `GET /v1/payment-method`
- `POST /v1/payment-method/setup-session`
- `POST /v1/payment-method/confirm`
- `DELETE /v1/payment-method`
- `GET /v1/tasks/:taskId/stake`
- `PUT /v1/tasks/:taskId/stake`
- `DELETE /v1/tasks/:taskId/stake`

Add charity routes after these (in the same file, same export).

### Search debounce implementation

Use `dart:async` `Timer` for debounce in `_CharitySheetScreenState`:
```dart
Timer? _debounceTimer;

void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
    setState(() => _searchQuery = query);
    _loadCharities();
  });
}
```
Cancel `_debounceTimer` in `dispose()` to prevent callbacks after widget destruction.

### Every.org API — stub data for 5 nonprofits

The stub response must return valid-looking nonprofit records so the Flutter UI renders correctly:
```typescript
[
  { id: 'american-red-cross', name: 'American Red Cross', description: 'Emergency response and disaster relief.', logoUrl: null, categories: ['Health'] },
  { id: 'doctors-without-borders', name: 'Doctors Without Borders', description: 'Medical aid in crisis zones.', logoUrl: null, categories: ['Health'] },
  { id: 'world-wildlife-fund', name: 'World Wildlife Fund', description: 'Conservation of nature and wildlife.', logoUrl: null, categories: ['Environment'] },
  { id: 'unicef', name: 'UNICEF', description: 'Children\'s rights and emergency relief worldwide.', logoUrl: null, categories: ['Human Rights'] },
  { id: 'electronic-frontier-foundation', name: 'Electronic Frontier Foundation', description: 'Digital rights and civil liberties.', logoUrl: null, categories: ['Human Rights'] },
]
```

### Deferred items from Story 6.2 that impact this story

- **`catch (_)` giving generic error** — this story introduces two new error paths (`_loadCharities` and `_saveCharity`). Distinguish network errors (Dio status codes) from unexpected errors in both catch blocks. Do not use bare `catch (_)` — use `catch (e)` and check `DioException` type.
- **Widget test missing `onPressed == null` assertion** — in `CharitySheetScreen` tests, explicitly assert `CupertinoButton.onPressed == null` when Confirm is disabled (no selection).

### Project Structure — files to create/modify

New files:
- `packages/core/src/schema/migrations/0014_charity_selection.sql` (generate from `apps/api/`)
- `apps/flutter/lib/features/commitment_contracts/domain/nonprofit.dart`
- `apps/flutter/lib/features/commitment_contracts/domain/nonprofit.freezed.dart` (generate)
- `apps/flutter/lib/features/commitment_contracts/domain/charity_selection.dart`
- `apps/flutter/lib/features/commitment_contracts/domain/charity_selection.freezed.dart` (generate)
- `apps/flutter/lib/features/commitment_contracts/presentation/widgets/charity_search_delegate.dart`
- `apps/flutter/lib/features/commitment_contracts/presentation/charity_sheet_screen.dart`
- `apps/flutter/test/features/commitment_contracts/charity_search_delegate_test.dart`
- `apps/flutter/test/features/commitment_contracts/charity_sheet_screen_test.dart`

Modified files:
- `packages/core/src/schema/commitment-contracts.ts` — add `charityId`, `charityName` columns
- `packages/core/src/schema/migrations/meta/_journal.json` — updated by drizzle-kit generate
- `packages/core/src/schema/migrations/meta/0014_snapshot.json` — generated by drizzle-kit generate
- `apps/api/src/routes/commitment-contracts.ts` — add 3 charity routes + schemas
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` — add 3 charity methods
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.g.dart` — regenerate
- `apps/flutter/lib/features/commitment_contracts/presentation/stake_sheet_screen.dart` — add charity row
- `apps/flutter/lib/core/l10n/strings.dart` — add charity UI strings

### References

- Epic 6 story definition: `_bmad-output/planning-artifacts/epics.md` lines 1550–1571
- UX modal sheet policy: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1452
- UX VoiceOver focus on open: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1682
- UX non-blocking optionality: `_bmad-output/planning-artifacts/ux-design-specification.md` line 1038
- UX charity selection tone: `_bmad-output/planning-artifacts/ux-design-specification.md` line 333
- Architecture `every-org.ts` service location: `_bmad-output/planning-artifacts/architecture.md` line 750
- Architecture `every-org-consumer.ts` queue: `_bmad-output/planning-artifacts/architecture.md` line 762
- Architecture Flutter feature path: `_bmad-output/planning-artifacts/architecture.md` line 869
- Drizzle `casing: 'camelCase'`: `_bmad-output/planning-artifacts/architecture.md` line 437
- Existing `commitment_contracts` schema: `packages/core/src/schema/commitment-contracts.ts`
- Existing routes (6.1 + 6.2): `apps/api/src/routes/commitment-contracts.ts`
- Previous story patterns: `_bmad-output/implementation-artifacts/6-2-stake-setting-ui.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- drizzle-kit not found via pnpm script; used binary at `node_modules/.pnpm/node_modules/.bin/drizzle-kit` directly. Generated file named `0014_real_skin.sql` — renamed to `0014_charity_selection.sql` and updated `_journal.json` tag accordingly.
- `use_null_aware_elements` linter info on `if (x != null)` map entries — cannot use null-aware syntax `?'key': value` for `Map<String, String>` due to type incompatibility; kept `if` form (2 info hints, no errors/warnings).
- `pumpAndSettle` timeout when `isLoading=true` with `CupertinoActivityIndicator` — fixed by using `pump()` instead of `pumpAndSettle()` in that specific test case.

### Completion Notes List

- Added `charityId: text()` and `charityName: text()` columns to `commitmentContractsTable` after `hasActiveStakes`, before `setupSessionToken`.
- Generated migration `0014_charity_selection.sql`: two `ALTER TABLE` statements adding nullable text columns.
- Added 3 charity routes to `commitment-contracts.ts`: `GET /v1/charities/default`, `PUT /v1/charities/default`, `GET /v1/charities` (in required registration order). All stub implementations with `TODO(impl)` markers. 5-nonprofit stub catalog included.
- Created `Nonprofit` and `CharitySelection` Freezed domain models; generated `.freezed.dart` files.
- Added `searchCharities()`, `getDefaultCharity()`, `setDefaultCharity()` to `CommitmentContractsRepository`; regenerated `.g.dart`.
- Created `CharitySearchDelegate` (StatefulWidget, pure UI, no Riverpod) with category filter chips, search input, results list, loading/empty states.
- Created `CharitySheetScreen` (ConsumerStatefulWidget) as modal bottom sheet with 400ms search debounce, confirm button, error dialogs. NOT added to `app_router.dart`.
- Extended `StakeSheetScreen` with charity selection row (pre-populates from `getDefaultCharity()` on init; opens `CharitySheetScreen` via `showCupertinoModalPopup`). Charity selection is non-blocking — confirm button in stake sheet not disabled when no charity selected.
- Added 8 charity l10n strings to `AppStrings`.
- All 41 commitment_contracts tests pass; full suite (Flutter + API) passes with no regressions.

### Change Log

- 2026-04-01: Story 6.3 implemented — charity selection feature (DB schema, API stubs, Flutter UI, tests). All tasks complete. Status → review.
