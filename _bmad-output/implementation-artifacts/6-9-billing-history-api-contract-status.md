# Story 6.9: Billing History & API Contract Status

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user and API consumer,
I want to view my charge history in the app and read contract status from the API,
so that I have full visibility into my financial activity with On Task.

## Acceptance Criteria

1. **Given** the user opens Settings → Payments → Billing History
   **When** the history loads
   **Then** each entry shows: date, task name, amount charged, disbursement status (pending/completed/failed), and charity (FR65)
   **And** cancelled stakes are listed separately as "cancelled — no charge"

2. **Given** an authenticated API consumer makes a request
   **When** they call `GET /v1/contracts/:id/status`
   **Then** the response includes: status (active / charged / cancelled / disputed), stake amount, and charge timestamp if charged (FR71)
   **And** the endpoint is scoped to the authenticated user's contracts only — no cross-user access

## Tasks / Subtasks

### API: `GET /v1/billing-history` endpoint (AC: 1)

- [x] Add to `apps/api/src/routes/commitment-contracts.ts` (AC: 1)
  - [x] Define Zod schema `billingEntrySchema` with fields:
    ```typescript
    const billingEntrySchema = z.object({
      id: z.string().uuid(),
      taskName: z.string(),
      date: z.string().datetime(),           // ISO 8601 UTC — charge date or cancellation date
      amountCents: z.number().int().nullable(), // null for cancelled entries
      disbursementStatus: z.enum(['pending', 'completed', 'failed', 'cancelled']),
      charityName: z.string().nullable(),    // null for cancelled entries
    })
    const billingHistoryResponseSchema = z.object({ data: z.object({ entries: z.array(billingEntrySchema) }) })
    ```
  - [x] Register `GET /v1/billing-history` route with `@hono/zod-openapi`; tags: `['Billing']`
  - [x] Stub handler returns realistic-looking list data:
    - One charged entry (disbursementStatus: `'completed'`)
    - One pending entry (disbursementStatus: `'pending'`)
    - One cancelled entry (amountCents: null, disbursementStatus: `'cancelled'`, charityName: null)
  - [x] Add `TODO(impl)`: query `charge_events` joined to `tasks` for `userId = JWT sub`, order by `date` descending; return cancelled stakes from `tasks` where `stakeAmountCents` was set then nulled via `POST /v1/tasks/:taskId/stake/cancel`

### API: `GET /v1/contracts/:id/status` endpoint (AC: 2)

- [x] Add to `apps/api/src/routes/commitment-contracts.ts` (AC: 2)
  - [x] Define Zod schema `contractStatusSchema`:
    ```typescript
    const contractStatusSchema = z.object({
      id: z.string().uuid(),
      status: z.enum(['active', 'charged', 'cancelled', 'disputed']),
      stakeAmountCents: z.number().int().nullable(),
      chargeTimestamp: z.string().datetime().nullable(), // ISO 8601 UTC; null unless status='charged'
    })
    const ContractStatusResponseSchema = z.object({ data: contractStatusSchema })
    ```
  - [x] Register `GET /v1/contracts/:id/status` with params `z.object({ id: z.string().uuid() })`; tags: `['Contracts']`
  - [x] Stub handler returns status `'active'`, stakeAmountCents 2500, chargeTimestamp null
  - [x] Add `TODO(impl)`: query `commitment_contracts` where `id = :id AND userId = JWT sub`; return 404 if not found; return 403 if found but `userId != JWT sub` (NEVER return another user's contract)
  - [x] Add 404 and 403 response schemas to the `createRoute` definition

### API: Tests for new endpoints (AC: 1, 2)

- [x] Create `apps/api/test/routes/billing-history.test.ts` (new file)
  ```typescript
  import { describe, expect, it } from 'vitest'
  const app = (await import('../../src/index.js')).default
  describe('GET /v1/billing-history', () => {
    it('returns 200 with entries array', async () => { ... })
    it('entries array contains at least one cancelled entry with amountCents=null', async () => { ... })
    it('disbursementStatus values are one of: pending/completed/failed/cancelled', async () => { ... })
  })
  ```
- [x] Create `apps/api/test/routes/contract-status.test.ts` (new file)
  ```typescript
  describe('GET /v1/contracts/:id/status', () => {
    it('returns 200 with status/stakeAmountCents/chargeTimestamp', async () => { ... })
    it('returns 400 on non-UUID id', async () => { ... })
    it('chargeTimestamp is null when status is active', async () => { ... })
  })
  ```

### Flutter: `BillingEntry` domain model (AC: 1)

- [x] Create `apps/flutter/lib/features/commitment_contracts/domain/billing_entry.dart`
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  part 'billing_entry.freezed.dart';

  @freezed
  class BillingEntry with _$BillingEntry {
    const factory BillingEntry({
      required String id,
      required String taskName,
      required DateTime date,
      int? amountCents,
      required String disbursementStatus, // 'pending' | 'completed' | 'failed' | 'cancelled'
      String? charityName,
    }) = _BillingEntry;
  }
  ```
- [x] Run `dart run build_runner build --delete-conflicting-outputs` and commit `billing_entry.freezed.dart`

### Flutter: `getBillingHistory()` in `CommitmentContractsRepository` (AC: 1)

- [x] Add method to `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`:
  ```dart
  // ── Billing history (FR65, Story 6.9) ─────────────────────────────────────

  /// Fetches the authenticated user's charge and cancellation history.
  ///
  /// `GET /v1/billing-history`
  /// Returns entries ordered newest-first. Cancelled stakes have amountCents=null
  /// and disbursementStatus='cancelled'.
  Future<List<BillingEntry>> getBillingHistory() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/billing-history',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['entries'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return BillingEntry(
        id: m['id'] as String,
        taskName: m['taskName'] as String,
        date: DateTime.parse(m['date'] as String).toLocal(),
        amountCents: m['amountCents'] != null
            ? (m['amountCents'] as num).toInt()
            : null,
        disbursementStatus: m['disbursementStatus'] as String,
        charityName: m['charityName'] as String?,
      );
    }).toList();
  }
  ```

### Flutter: `BillingHistoryScreen` (AC: 1)

- [x] Create `apps/flutter/lib/features/commitment_contracts/presentation/billing_history_screen.dart`
  - [x] `ConsumerStatefulWidget`, loads `_billingHistory` list via `repository.getBillingHistory()` in `initState`
  - [x] Loading state: `CupertinoActivityIndicator` centered
  - [x] Error state: centred text using `AppStrings.billingHistoryLoadError`, `colors.textSecondary`
  - [x] Empty state: centred text using `AppStrings.billingHistoryEmpty`
  - [x] Loaded state: `ListView` with one `_BillingEntryRow` per entry; newest first
  - [x] `_BillingEntryRow` widget anatomy:
    - Leading: formatted date `DateFormat('MMM d, y').format(entry.date)` — use `intl` package
    - Title: `entry.taskName` in `colors.textPrimary`, fontSize 17
    - Subtitle: charity name or "cancelled — no charge" when `entry.disbursementStatus == 'cancelled'`
    - Trailing: formatted amount or empty when cancelled
      - Use `CommitmentRow.formatAmount(entry.amountCents!)` for charged/pending entries
      - For cancelled: no amount shown
    - Disbursement badge: small text chip showing status
      - `'completed'` → `colors.accentCompletion` text: "Donated"
      - `'pending'` → `colors.textSecondary` text: "Pending"
      - `'failed'` → `CupertinoColors.destructiveRed` text: "Failed"
      - `'cancelled'` → `colors.textSecondary` text: "Cancelled"
  - [x] Screen navigation bar title: `AppStrings.billingHistoryTitle`
  - [x] Background: `colors.surfacePrimary`

### Flutter: Wire `BillingHistoryScreen` into `PaymentSettingsScreen` (AC: 1)

- [x] Modify `apps/flutter/lib/features/commitment_contracts/presentation/payment_settings_screen.dart`:
  - [x] Add a "Billing History" `_SettingsTile`-style list row (or `CupertinoButton`) below the payment method display
  - [x] Navigation: `Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const BillingHistoryScreen()))`
  - [x] Import `billing_history_screen.dart` at the top
  - [x] The row label is `AppStrings.billingHistoryNavLabel`; icon: `CupertinoIcons.clock`
  - [x] Show the row regardless of `hasPaymentMethod` — even if no payment method, history may show cancelled entries

### Flutter: l10n strings (AC: 1)

- [x] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Billing history (FR65, Story 6.9) ──` section:
  ```dart
  // ── Billing history (FR65, Story 6.9) ────────────────────────────────────────
  /// Navigation entry label in PaymentSettingsScreen.
  static const String billingHistoryNavLabel = 'Billing History';

  /// Screen title for BillingHistoryScreen navigation bar.
  static const String billingHistoryTitle = 'Billing History';

  /// Empty state message when no billing entries exist.
  static const String billingHistoryEmpty =
      'No charges or cancellations yet.';

  /// Error message shown when billing history fails to load.
  static const String billingHistoryLoadError =
      'Could not load billing history. Please try again.';

  /// Disbursement status label — charge forwarded to charity.
  static const String billingStatusDonated = 'Donated';

  /// Disbursement status label — charge awaiting processing.
  static const String billingStatusPending = 'Pending';

  /// Disbursement status label — charge processing failed.
  static const String billingStatusFailed = 'Failed';

  /// Disbursement status label — stake was cancelled, no charge.
  static const String billingStatusCancelled = 'Cancelled';

  /// Subtitle shown for cancelled stake entries in billing history.
  static const String billingCancelledNoCharge = 'cancelled — no charge';
  ```

### Flutter: Tests (AC: 1)

- [x] Create `apps/flutter/test/features/commitment_contracts/billing_history_screen_test.dart` (new file)
  - [ ] Wrap in `MaterialApp` with `OnTaskTheme.light()` (established pattern from Stories 6.7, 6.8)
  - [ ] Use `ProviderContainer` override for `commitmentContractsRepositoryProvider`
  - [ ] Tests:
    ```dart
    testWidgets('shows CupertinoActivityIndicator while loading', (tester) async { ... })
    testWidgets('renders charged entry with formatted amount and Donated badge', (tester) async { ... })
    testWidgets('renders cancelled entry showing billingCancelledNoCharge and no amount', (tester) async { ... })
    testWidgets('renders pending entry with Pending badge', (tester) async { ... })
    testWidgets('shows empty state text when entries list is empty', (tester) async { ... })
    testWidgets('shows error text when getBillingHistory throws', (tester) async { ... })
    ```
- [x] Extend `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart` (do NOT create new file):
  - [ ] Add group `'CommitmentContractsRepository.getBillingHistory (AC1)'`:
    - Verify fires `GET /v1/billing-history`
    - Verify maps charged entry (amountCents via `.toInt()`, date via `DateTime.parse`, charityName)
    - Verify maps cancelled entry with `amountCents == null`, disbursementStatus `'cancelled'`

### MCP: `get-commitment-status` tool (AC: 2)

- [x] Create `apps/mcp/src/tools/get-commitment-status.ts` (new file — referenced in architecture but not yet implemented)
  - [ ] Use Cloudflare Service Binding (`env.API`) to call `GET /v1/contracts/:id/status` on the API Worker — **never make HTTP calls to the public API URL**
  - [ ] Tool definition:
    ```typescript
    // Tool name: get_commitment_status
    // Description: Reads the status of a commitment contract by its ID.
    //              Returns status (active/charged/cancelled/disputed), stake amount,
    //              and charge timestamp if charged. Scoped to authenticated user's contracts only.
    // Input: { id: string } — UUID of the contract
    // Output: { id, status, stakeAmountCents, chargeTimestamp }
    ```
  - [ ] Add `TODO(impl)`: wire OAuth per-client scoping (FR93) — this is a stub that uses Service Binding
  - [ ] Stub returns the `GET /v1/contracts/:id/status` response body directly
  - [ ] Mount the tool in `apps/mcp/src/index.ts` alongside future tools (structure for discoverability)

## Dev Notes

### CRITICAL: Both `GET /v1/billing-history` and `GET /v1/contracts/:id/status` go into the EXISTING file

Do NOT create new route files. Both endpoints belong in `apps/api/src/routes/commitment-contracts.ts` (FR65 and FR71 are both in that file's coverage comment). Follow the exact same `createRoute` + `app.openapi` pattern established for all existing endpoints in that file.

### CRITICAL: `(m['amountCents'] as num).toInt()` — always cast via `num` first

JSON numeric values from Dio can arrive as `int` or `double` depending on the JSON parser. Always cast as `(value as num).toInt()`. This is the established pattern in `CommitmentContractsRepository` — see `_groupCommitmentFromJson` at line 276 and `getImpactSummary` at line 329.

### CRITICAL: `CommitmentRow.formatAmount` — reuse for amount display

`apps/flutter/lib/features/now/presentation/widgets/commitment_row.dart` has `CommitmentRow.formatAmount(int cents)` which returns a formatted dollar string (e.g., `'$50'`). Import and use this in `BillingHistoryScreen` for amount display. Do NOT reimplement currency formatting.

### CRITICAL: `intl` package for date formatting

`intl` was added in Story 6.6. Use `DateFormat('MMM d, y').format(entry.date)` for the entry date in `BillingHistoryScreen`. Import: `import 'package:intl/intl.dart';`

### CRITICAL: `withValues(alpha:)` — NOT `withOpacity()`

`withOpacity()` is deprecated. Use `.withValues(alpha: value)` for all colour opacity. This was flagged as a review finding in Story 6.8 (5 instances). Do not repeat the mistake.

### CRITICAL: No new Freezed models without running build_runner

`BillingEntry` uses `@freezed`. After creating the Dart source, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Commit the generated `billing_entry.freezed.dart`. The `.gitignore` must NOT exclude `*.freezed.dart` — this is an architecture invariant.

### CRITICAL: `GET /v1/contracts/:id/status` — scope check is non-negotiable

The endpoint MUST verify `userId = JWT sub` on the contract. The 403 case must be in the `createRoute` responses definition (not just as a comment). A user who guesses another user's contract UUID must receive 403, not 404. Add both 403 and 404 error cases to the route definition and the stub's `TODO(impl)` comment.

### CRITICAL: MCP uses Service Binding — never HTTP

The MCP Worker calls the API Worker via `env.API` (Cloudflare Service Binding) — zero-latency in-process RPC. It must NEVER make HTTP calls to `api.ontaskhq.com`. See `apps/mcp/wrangler.toml` for the `[[services]]` binding config (architecture.md lines 801–827). The current `apps/mcp/src/index.ts` is a minimal stub — the `get-commitment-status` tool adds the first tool to the MCP server.

### CRITICAL: All l10n strings in `AppStrings` — no hardcoded UI strings

Every user-visible string in `BillingHistoryScreen` must come from `AppStrings`. The `'cancelled — no charge'` string must be `AppStrings.billingCancelledNoCharge`. Status badge labels must use the `billingStatus*` constants.

### CRITICAL: `isLoading = false` default; content IS auto-fetched (different from LockConfirmationScreen)

Unlike `LockConfirmationScreen` where `_isLoading = false` because no fetch happens on mount, `BillingHistoryScreen` DOES auto-fetch in `initState`. Set `_isLoading = true` as the initial value (or better: use `_isLoading = false` with a `_history` nullable field, and show `CupertinoActivityIndicator` when both `_isLoading && _history == null`). Follow the `PaymentSettingsScreen` pattern (`apps/flutter/lib/features/commitment_contracts/presentation/payment_settings_screen.dart` lines 37–67) — `_isLoading` starts false and is set true inside the load method before the async call.

### Architecture: BillingHistoryScreen is a full-screen `CupertinoPageRoute`

`PaymentSettingsScreen` navigates to `BillingHistoryScreen` via `Navigator.of(context).push(CupertinoPageRoute(...))` — consistent with the `PaymentSettingsScreen` → any-sub-screen pattern. This is NOT a GoRouter deep-link route. No router changes required.

### Architecture: Disbursement status comes from `charge_events` table (future)

The `disbursementStatus` field in the API response maps to `charge_events.everOrgStatus` (from Story 6.5). For the stub, return: `'completed'` for a charged entry, `'pending'` for an in-flight one, and `'cancelled'` for a cancelled stake. The real query joins `charge_events` to `tasks` on `taskId`.

### Architecture: `GET /v1/billing-history` vs `GET /v1/users/me/billing-history`

The architecture file assigns FR65 to `apps/api/src/routes/users.ts` (line 730) AND to `commitment-contracts.ts` (line 735). Use `commitment-contracts.ts` — all Epic 6 financial endpoints are consolidated there; the `users.ts` assignment is an over-broad coverage annotation. The billing route is logically part of commitment contracts, not user profile management.

### Architecture: `GET /v1/contracts/:id/status` for MCP / external consumers

This endpoint is referenced in the architecture as the FR71 contract status endpoint for the MCP tool `get-commitment-status.ts` (architecture line 822). The route path `/v1/contracts/:id/status` (not `/v1/commitment-contracts/:id/status`) is intentional — it provides a clean, stable public API surface for external consumers.

### Architecture: File locations

New files to create:
```
apps/flutter/lib/features/commitment_contracts/domain/billing_entry.dart
apps/flutter/lib/features/commitment_contracts/domain/billing_entry.freezed.dart  (generated)
apps/flutter/lib/features/commitment_contracts/presentation/billing_history_screen.dart
apps/flutter/test/features/commitment_contracts/billing_history_screen_test.dart
apps/api/test/routes/billing-history.test.ts
apps/api/test/routes/contract-status.test.ts
apps/mcp/src/tools/get-commitment-status.ts
```

Modified files:
```
apps/api/src/routes/commitment-contracts.ts       — add 2 new endpoints
apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart
                                                   — add getBillingHistory() method
apps/flutter/lib/features/commitment_contracts/presentation/payment_settings_screen.dart
                                                   — add Billing History navigation row
apps/flutter/lib/core/l10n/strings.dart            — add billing history strings
apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart
                                                   — extend with getBillingHistory tests
apps/mcp/src/index.ts                              — mount get-commitment-status tool
```

### UX: Billing History entry layout — two types

**Charged/Pending entry:**
- Date (left-aligned, secondary colour, 13pt)
- Task name (primary, 17pt)
- Charity name (secondary, 13pt)
- Amount (trailing, `accentCompletion` for completed, `textPrimary` for pending)
- Status badge (small, right-aligned below amount)

**Cancelled entry:**
- Date (left-aligned, secondary colour, 13pt)
- Task name (primary, 17pt)
- "cancelled — no charge" (secondary italic, 13pt)
- No amount shown; "Cancelled" badge in `textSecondary`

### UX: No UX spec deep-link for Billing History

The UX spec does not describe a `BillingHistoryScreen` in detail beyond its position in the Settings → Payments flow. Implement as a standard `CupertinoPageScaffold` list matching the visual style of `PaymentSettingsScreen` — `surfacePrimary` background, `CupertinoNavigationBar` with back button, `ListView` with `padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20)`.

### Previous story learnings carried forward (Stories 6.1–6.8)

- TypeScript imports use `.js` extensions (established throughout `apps/api/` — see any `import ... from '../lib/response.js'`)
- Generated `.freezed.dart` and `.g.dart` files must be committed after `build_runner`
- Use `catch (e)` not `catch (_)` in all error handlers
- `OnTaskColors.surfacePrimary` for light backgrounds; `OnTaskColors.accentCompletion` for success/donation colour
- `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances
- All UI strings in `AppStrings`
- Widget tests: wrap in `MaterialApp` with `OnTaskTheme.light(ThemeVariant.clay, 'PlayfairDisplay')` (established Story 6.7)
- Repository tests use MockDio / MockApiClient pattern from `commitment_contracts_repository_test.dart` — always extend existing file, never create a parallel test file for the same class
- `isReducedMotion(context)` in `didChangeDependencies` (not relevant here — no animations in billing history)
- `intl` package available for date/currency formatting (added Story 6.6)
- `withValues(alpha:)` NOT `withOpacity()` — `withOpacity()` is deprecated (Story 6.8 review finding)
- `PopScope` not needed — billing history screen is freely dismissible
- No GoRouter route registration — billing history uses `Navigator.push` consistent with other Epic 6 screens
- `(value as num).toInt()` for all JSON numeric fields in Flutter repository methods

### Deferred items (not in scope for Story 6.9)

- Real DB query for `getBillingHistory()` — deferred until charge_events table is populated (Story 6.5 real impl)
- Real DB query for `GET /v1/contracts/:id/status` — deferred until commitment_contracts table has live data
- MCP OAuth per-client scoping for `get_commitment_status` tool (FR93) — deferred to Story 10.4
- `GET /v1/billing-history` pagination — first page only for V1; cursor pagination deferred
- Push notification when disbursement status changes (pending → completed) — Epic 8, Story 8.3
- Story 6.8 review findings (3 outstanding patches): `withOpacity` replacements in `CommitmentCeremonyCard`, `_isLoading` visibility fix in `LockConfirmationScreen`, `PopScope` assertion in test — these are pre-existing from 6.8 review, not in scope here

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Zod UUID validation rejects all-zero UUIDs with version nibble `0` (e.g., `00000000-0000-0000-0000-000000000001`). Contract status test updated to use a valid RFC-4122 UUID (`a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`).
- MCP project tsconfig uses `lib: ["ESNext"]` only — no web/Worker globals. Avoided `Request`/`Response` type references in MCP tool code by using `any` parameter type for the service binding's fetch method.

### Completion Notes List

- Implemented `GET /v1/billing-history` in `commitment-contracts.ts` with `billingEntrySchema`, `billingHistoryResponseSchema`, stub handler with all 3 entry types (completed, pending, cancelled), and `TODO(impl)` for real DB query.
- Implemented `GET /v1/contracts/:id/status` in `commitment-contracts.ts` with `contractStatusSchema`, `ContractStatusResponseSchema`, UUID param validation, stub handler returning `status: 'active'`, and 403/404 response schemas with `TODO(impl)` markers emphasising user-scope enforcement.
- Created `BillingEntry` Freezed domain model and ran `build_runner` to generate `billing_entry.freezed.dart`.
- Added `getBillingHistory()` to `CommitmentContractsRepository` following `(value as num).toInt()` pattern for amountCents per project conventions.
- Created `BillingHistoryScreen` as `ConsumerStatefulWidget` with loading/error/empty/loaded states. Used `intl` `DateFormat('MMM d, y')` for dates, `CommitmentRow.formatAmount()` for amounts, and `_DisbursementBadge` helper using Dart 3 switch expressions. No `withOpacity()` used — no colour opacity needed in this screen.
- Wired `BillingHistoryScreen` into `PaymentSettingsScreen` via `CupertinoButton` row with `CupertinoIcons.clock` icon and `CupertinoPageRoute` navigation. Row is always visible regardless of `hasPaymentMethod`.
- Added 8 l10n strings to `AppStrings` under `// ── Billing history (FR65, Story 6.9) ──` section.
- Created `apps/mcp/src/tools/get-commitment-status.ts` with `getCommitmentStatus()` function using Service Binding (no direct HTTP). Mounted tool in `apps/mcp/src/index.ts` under `GET /tools/get-commitment-status`.
- All tests pass: 192 API tests (vitest), 6 new billing-history + contract-status API tests, 6 new BillingHistoryScreen widget tests, 3 new getBillingHistory repository tests, full Flutter suite green.

### File List

New files:
- `apps/api/test/routes/billing-history.test.ts`
- `apps/api/test/routes/contract-status.test.ts`
- `apps/flutter/lib/features/commitment_contracts/domain/billing_entry.dart`
- `apps/flutter/lib/features/commitment_contracts/domain/billing_entry.freezed.dart`
- `apps/flutter/lib/features/commitment_contracts/presentation/billing_history_screen.dart`
- `apps/flutter/test/features/commitment_contracts/billing_history_screen_test.dart`
- `apps/mcp/src/tools/get-commitment-status.ts`

Modified files:
- `apps/api/src/routes/commitment-contracts.ts`
- `apps/flutter/lib/core/l10n/strings.dart`
- `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart`
- `apps/flutter/lib/features/commitment_contracts/presentation/payment_settings_screen.dart`
- `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart`
- `apps/mcp/src/index.ts`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- Story 6.9 implemented: Billing History screen (AC1) and API contract status endpoint (AC2). Added GET /v1/billing-history and GET /v1/contracts/:id/status to the API, BillingEntry domain model, getBillingHistory() repository method, BillingHistoryScreen Flutter UI, PaymentSettingsScreen navigation integration, l10n strings, and get_commitment_status MCP tool. (Date: 2026-04-01)
