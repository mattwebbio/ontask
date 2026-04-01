# Story 6.1: Payment Method Setup

Status: ready-for-dev

## Story

As a user,
I want to set up a payment method through a secure web flow,
so that On Task can charge me if I miss a commitment without ever handling my card details.

## Acceptance Criteria

1. **Given** a user initiates the commitment flow for the first time (or has no stored payment method) **When** they are directed to the payment setup step **Then** the app opens `ontaskhq.com/setup` via Universal Link using the associated domain `ontaskhq.com` (Story 13.1 is a prerequisite for end-to-end testing) **And** the setup page uses Stripe.js with a SetupIntent — raw card data never reaches On Task servers (NFR-S2, PCI SAQ A) **And** on successful setup, the app receives the Universal Link callback (`https://ontaskhq.com/payment-setup-complete?sessionToken=xxx`) and confirms to the user that a payment method is stored (FR23)

2. **Given** a payment method is stored **When** the user opens Settings → Payments **Then** they can view the stored method (last 4 digits and card type) **And** they can update it (opens `ontaskhq.com/setup` again) or remove it (FR64) **And** removing a payment method is blocked if there are active staked tasks

## Tasks / Subtasks

### Backend: DB schema — create `commitment_contracts` table with payment method fields in `packages/core/src/schema/commitment-contracts.ts` (AC: 1, 2)

- [ ] Create `packages/core/src/schema/commitment-contracts.ts` — new file (AC: 1, 2)
  - [ ] Export `commitmentContractsTable` using Drizzle pgTable
  - [ ] Columns (camelCase in schema, Drizzle generates snake_case DDL automatically):
    - `id: uuid().primaryKey().defaultRandom()`
    - `userId: uuid().notNull()` — FK to users (enforce in impl; stub omits FK constraint)
    - `stripeCustomerId: text()` — nullable; Stripe customer ID (set on first payment method setup)
    - `stripePaymentMethodId: text()` — nullable; stored payment method ID (set after SetupIntent completes)
    - `paymentMethodLast4: text()` — nullable; last 4 digits for display
    - `paymentMethodBrand: text()` — nullable; card brand string (e.g. `'visa'`, `'mastercard'`)
    - `hasActiveStakes: boolean().default(false).notNull()` — true when user has active staked tasks; blocks removal
    - `setupSessionToken: text()` — nullable; short-lived token generated before redirect; exchanged on return
    - `setupSessionExpiresAt: timestamp()` — nullable; token expiry (5-minute TTL)
    - `createdAt: timestamp().defaultNow().notNull()`
    - `updatedAt: timestamp().defaultNow().notNull()`
  - [ ] Follow existing Drizzle pattern: `import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'`
  - [ ] No manual `name()` overrides — `casing: 'camelCase'` handles the camelCase→snake_case transformation

- [ ] Export from `packages/core/src/schema/index.ts` (AC: 1, 2)
  - [ ] Add: `export { commitmentContractsTable } from './commitment-contracts.js'`

- [ ] Generate migration `packages/core/src/schema/migrations/0012_commitment_contracts.sql` (AC: 1, 2)
  - [ ] Run `pnpm drizzle-kit generate` from `packages/core/` to produce the migration
  - [ ] Commit generated SQL, updated `meta/_journal.json`, and `meta/0012_snapshot.json`
  - [ ] Migration creates `commitment_contracts` table with all columns above

### Backend: API — create `apps/api/src/routes/commitment-contracts.ts` (AC: 1, 2)

- [ ] Create `apps/api/src/routes/commitment-contracts.ts` — new file (AC: 1, 2)
  - [ ] Use `OpenAPIHono` + `createRoute` pattern (same as `users.ts`, `sharing.ts`) — no untyped routes
  - [ ] Import pattern: `import { ok, err } from '../lib/response.js'` — `.js` extensions on all local imports
  - [ ] Define `paymentMethodSchema`:
    ```typescript
    const paymentMethodSchema = z.object({
      last4: z.string().nullable(),
      brand: z.string().nullable(),
    })
    ```
  - [ ] Define `paymentStatusSchema` (returned by GET /v1/payment-method):
    ```typescript
    const paymentStatusSchema = z.object({
      hasPaymentMethod: z.boolean(),
      paymentMethod: paymentMethodSchema.nullable(),
      hasActiveStakes: z.boolean(),
    })
    ```
  - [ ] Export `commitmentContractsRouter`

- [ ] Add `GET /v1/payment-method` — get current user's stored payment method status (AC: 2)
  - [ ] Response 200: `{ data: paymentStatusSchema }`
  - [ ] Stub: return `{ hasPaymentMethod: false, paymentMethod: null, hasActiveStakes: false }`
  - [ ] Add `TODO(impl): query commitment_contracts for userId = JWT sub; return real values`
  - [ ] Tag: `'PaymentMethod'`

- [ ] Add `POST /v1/payment-method/setup-session` — generate session token and return setup URL (AC: 1)
  - [ ] Request body: empty `{}`
  - [ ] Response 201: `{ data: { setupUrl: z.string(), sessionToken: z.string() } }`
  - [ ] `setupUrl` = `https://ontaskhq.com/setup?sessionToken=xxx`
  - [ ] Stub: return `{ setupUrl: 'https://ontaskhq.com/setup?sessionToken=stub-token', sessionToken: 'stub-token' }`
  - [ ] Add `TODO(impl): generate cryptographically random token, store in commitment_contracts.setupSessionToken with 5-minute expiry, build real URL`
  - [ ] Tag: `'PaymentMethod'`

- [ ] Add `POST /v1/payment-method/confirm` — exchange session token after Universal Link callback (AC: 1)
  - [ ] Request body schema: `{ sessionToken: z.string() }`
  - [ ] Response 200: `{ data: paymentStatusSchema }`
  - [ ] Response 404: session token not found or expired
  - [ ] Stub: return 200 with `{ hasPaymentMethod: true, paymentMethod: { last4: '4242', brand: 'visa' }, hasActiveStakes: false }`
  - [ ] Add `TODO(impl): validate sessionToken against commitment_contracts.setupSessionToken + setupSessionExpiresAt; call Stripe API to retrieve PaymentMethod from SetupIntent; store stripePaymentMethodId, paymentMethodLast4, paymentMethodBrand`
  - [ ] Tag: `'PaymentMethod'`

- [ ] Add `DELETE /v1/payment-method` — remove stored payment method (AC: 2)
  - [ ] Request body: empty `{}`
  - [ ] Response 200: `{ data: { removed: z.boolean() } }`
  - [ ] Response 422: `{ error: { code: 'ACTIVE_STAKES_PREVENT_REMOVAL', message: '...' } }` — blocked if `hasActiveStakes = true`
  - [ ] Stub: return 200 with `{ removed: true }`
  - [ ] Add `TODO(impl): check hasActiveStakes for userId; if true return 422; else null out stripePaymentMethodId, paymentMethodLast4, paymentMethodBrand in commitment_contracts; detach from Stripe API`
  - [ ] Tag: `'PaymentMethod'`

- [ ] Route registration order (specific before parameterized rule applies even within this router):
  - Order: `GET /v1/payment-method`, `POST /v1/payment-method/setup-session`, `POST /v1/payment-method/confirm`, `DELETE /v1/payment-method`
  - No parameterized routes in this story — order is informational

### Backend: Register router in `apps/api/src/index.ts` (AC: 1, 2)

- [ ] Import `commitmentContractsRouter` from `'./routes/commitment-contracts.js'`
- [ ] Mount: `app.route('/', commitmentContractsRouter)` — same pattern as other routers
- [ ] Position: add after existing route registrations (no ordering conflict — unique paths)

### Flutter: Domain model — `CommitmentPaymentStatus` in `apps/flutter/lib/features/commitment_contracts/domain/` (AC: 1, 2)

- [ ] Create directory `apps/flutter/lib/features/commitment_contracts/` with full feature anatomy:
  ```
  lib/features/commitment_contracts/
  ├── data/
  │   ├── commitment_contracts_repository.dart
  │   └── commitment_contracts_repository.g.dart   # generated
  ├── domain/
  │   └── commitment_payment_status.dart            # freezed model
  │   └── commitment_payment_status.freezed.dart    # generated
  └── presentation/
      ├── payment_settings_screen.dart
      └── payment_settings_screen.dart              # see Flutter tasks below
  ```

- [ ] Create `apps/flutter/lib/features/commitment_contracts/domain/commitment_payment_status.dart` (AC: 2)
  - [ ] Freezed model with fields:
    - `bool hasPaymentMethod`
    - `String? last4` — nullable
    - `String? brand` — nullable
    - `bool hasActiveStakes`
  - [ ] Add `@freezed` annotation; generate `commitment_payment_status.freezed.dart`
  - [ ] Run `dart run build_runner build --delete-conflicting-outputs` and commit generated file

### Flutter: Repository — `CommitmentContractsRepository` (AC: 1, 2)

- [ ] Create `apps/flutter/lib/features/commitment_contracts/data/commitment_contracts_repository.dart` (AC: 1, 2)
  - [ ] `@riverpod` annotation on class — generates `commitmentContractsRepositoryProvider`
  - [ ] Constructor: `CommitmentContractsRepository(this._client)` where `_client` is `ApiClient` injected via `ref.watch(apiClientProvider)`
  - [ ] Methods:
    - `Future<CommitmentPaymentStatus> getPaymentStatus()` — `GET /v1/payment-method`
    - `Future<Map<String, dynamic>> createSetupSession()` — `POST /v1/payment-method/setup-session`; returns raw map with `setupUrl` and `sessionToken`
    - `Future<CommitmentPaymentStatus> confirmSetup(String sessionToken)` — `POST /v1/payment-method/confirm`
    - `Future<void> removePaymentMethod()` — `DELETE /v1/payment-method`; throws on 422 (active stakes)
  - [ ] Use `_client.dio.get/post/delete<Map<String, dynamic>>(...)` pattern (same as `SharingRepository`)
  - [ ] Parse response: `CommitmentPaymentStatus(hasPaymentMethod: data['hasPaymentMethod'], last4: data['paymentMethod']?['last4'], brand: data['paymentMethod']?['brand'], hasActiveStakes: data['hasActiveStakes'])`
  - [ ] Commit generated `commitment_contracts_repository.g.dart`

### Flutter: Presentation — `PaymentSettingsScreen` (AC: 1, 2)

- [ ] Create `apps/flutter/lib/features/commitment_contracts/presentation/payment_settings_screen.dart` (AC: 1, 2)
  - [ ] `ConsumerStatefulWidget` — fetches `commitmentContractsRepositoryProvider` and `getPaymentStatus()`
  - [ ] Use `FutureProvider` or `ref.watch` with `AsyncValue<CommitmentPaymentStatus>` — never raw `Future<T>`
  - [ ] **When `hasPaymentMethod == false`**: Show `CupertinoButton` "Set up payment method" (primary styled)
    - On tap: call `repository.createSetupSession()` → receive `setupUrl` → open via `url_launcher` package (`launchUrl(Uri.parse(setupUrl), mode: LaunchMode.externalApplication)`)
    - Add `// TODO(impl): deep link handler in AppRouter will intercept ontaskhq.com/payment-setup-complete Universal Link; call confirmSetup(sessionToken)`
  - [ ] **When `hasPaymentMethod == true`**: Show stored method display row: `'${brand?.toUpperCase() ?? 'Card'} ending in $last4'`
    - "Update payment method" `CupertinoButton` → same setup flow as above
    - "Remove payment method" `CupertinoButton` (destructive) — show only when `!hasActiveStakes`
    - When `hasActiveStakes == true`: show disabled "Remove" button with note `AppStrings.paymentRemoveBlockedByStakes`
    - Removal: show `CupertinoAlertDialog` confirm → title `AppStrings.paymentRemoveConfirmTitle`, message `AppStrings.paymentRemoveConfirmMessage`, actions: Cancel + `AppStrings.actionDelete` (destructive) → call `repository.removePaymentMethod()` → refresh
  - [ ] Loading state: `_isLoading` bool (same `setState` pattern as `ListSettingsScreen._isManagingMember`)
  - [ ] Error state: `CupertinoAlertDialog` with `AppStrings.dialogErrorTitle` + `AppStrings.paymentSetupError`
  - [ ] Background: `colors.surfacePrimary`
  - [ ] `minimumSize: const Size(44, 44)` on all `CupertinoButton` instances

### Flutter: Deep link handler stub — Universal Link return (AC: 1)

- [ ] Add `// TODO(impl): register ontaskhq.com/payment-setup-complete deep link handler in AppRouter` comment in `apps/flutter/lib/features/commitment_contracts/presentation/payment_settings_screen.dart`
  - Architecture note: Universal Link `https://ontaskhq.com/payment-setup-complete?sessionToken=xxx` and fallback URL scheme `ontaskhq://payment-setup-complete?sessionToken=xxx` are already registered in `Info.plist` and `Runner.entitlements` (architecture.md Gap 1 resolved). The AppRouter deep link handler that intercepts this URL and calls `confirmSetup(sessionToken)` is deferred to when AASA is deployed (Story 13.1).
  - Add `TODO(impl): when deep link received, extract sessionToken from URI query params, call commitmentContractsRepository.confirmSetup(sessionToken), navigate to PaymentSettingsScreen` in relevant location

### Flutter: Settings screen — add Payments tile (AC: 2)

- [ ] Extend `apps/flutter/lib/features/settings/presentation/settings_screen.dart` (AC: 2)
  - [ ] Import `payment_settings_screen.dart`
  - [ ] Add `_SettingsTile` for `AppStrings.settingsPayments` with `CupertinoIcons.creditcard` icon
  - [ ] Navigate: `CupertinoPageRoute` → `PaymentSettingsScreen()`
  - [ ] Position: below the "Account" tile, above any stub tiles at the bottom
  - [ ] Comment: `// ── Payments (Epic 6) ───────────────────────────────────────`

### Flutter: l10n strings (AC: 1, 2)

- [ ] Add to `apps/flutter/lib/core/l10n/strings.dart` under a new `// ── Payment method setup (FR23, FR64) ──` section (AC: 1, 2)
  - [ ] `static const String settingsPayments = 'Payments';` — Settings tile label
  - [ ] `static const String paymentSetupTitle = 'Payment Method';` — screen title
  - [ ] `static const String paymentSetupButton = 'Set up payment method';` — CTA when no method stored
  - [ ] `static const String paymentUpdateButton = 'Update payment method';` — CTA when method exists
  - [ ] `static const String paymentRemoveButton = 'Remove payment method';` — destructive action
  - [ ] `static const String paymentRemoveConfirmTitle = 'Remove payment method?';`
  - [ ] `static const String paymentRemoveConfirmMessage = 'Your stored card will be removed. You will need to set up a new payment method before adding a commitment stake.';`
  - [ ] `static const String paymentRemoveBlockedByStakes = 'You have active commitment stakes. Remove all stakes before removing your payment method.';`
  - [ ] `static const String paymentSetupError = 'Could not complete payment setup. Please try again.';`
  - [ ] `static const String paymentMethodDisplay = 'Payment method';` — section label
  - [ ] NOTE: `AppStrings.actionDelete`, `AppStrings.dialogErrorTitle`, `AppStrings.actionCancel` already exist — do NOT recreate

### Tests

- [ ] Unit test for `CommitmentContractsRepository` in `apps/flutter/test/features/commitment_contracts/commitment_contracts_repository_test.dart` (AC: 1, 2)
  - [ ] Create new test file — this is the first Epic 6 test
  - [ ] Test: `getPaymentStatus()` fires `GET /v1/payment-method` and maps `hasPaymentMethod`, `last4`, `brand`, `hasActiveStakes`
  - [ ] Test: `createSetupSession()` fires `POST /v1/payment-method/setup-session` and returns `setupUrl` + `sessionToken`
  - [ ] Test: `confirmSetup('stub-token')` fires `POST /v1/payment-method/confirm` with body `{'sessionToken': 'stub-token'}`
  - [ ] Test: `removePaymentMethod()` fires `DELETE /v1/payment-method`
  - [ ] Use same `mocktail` + `MockDio` pattern established in `sharing_repository_test.dart` (Story 5.3)

- [ ] Widget test for `PaymentSettingsScreen` in `apps/flutter/test/features/commitment_contracts/payment_settings_screen_test.dart` (AC: 1, 2)
  - [ ] Test: "Set up payment method" button renders when `hasPaymentMethod == false`
  - [ ] Test: card display row renders when `hasPaymentMethod == true` (shows last4 and brand)
  - [ ] Test: "Remove payment method" button renders when `hasPaymentMethod == true` AND `hasActiveStakes == false`
  - [ ] Test: "Remove" button is absent or disabled when `hasActiveStakes == true`
  - [ ] Override `commitmentContractsRepositoryProvider` with a stub — same `ProviderContainer` pattern as Stories 5.4/5.6
  - [ ] Wrap in `MaterialApp` with `OnTaskTheme` to resolve `OnTaskColors` extension

## Dev Notes

### CRITICAL: This is Epic 6, Story 1 — all Stripe calls are stubs with TODO(impl) markers

Per Epic 6 note: Story 13.1 (AASA + payment pages) must be deployed before Epic 6 can be tested end-to-end. All payment endpoints are implemented as stubs that return plausible fixture data. Stripe API calls are `TODO(impl)` — do NOT attempt to integrate the real Stripe SDK in this story.

### CRITICAL: New route file `commitment-contracts.ts` — not added to existing files

This story creates `apps/api/src/routes/commitment-contracts.ts` as a new file. Do NOT add payment method endpoints to `users.ts` or any other existing route file. Architecture specifies commitment contracts live in `apps/api/src/routes/commitment-contracts.ts` (architecture.md line ~735).

### CRITICAL: `commitment_contracts` DB table is new — migration `0012_...`

The `packages/core/src/schema/` directory has no `commitment-contracts.ts` file yet and `index.ts` does not export it. This story creates both. Migration numbering: `0011` was used in Story 5.5 (`0011_shared_proof_visibility.sql`). Next migration is `0012_commitment_contracts.sql`.

### CRITICAL: Flutter feature directory `commitment_contracts/` does not exist yet

`apps/flutter/lib/features/` currently has: `auth`, `chapter_break`, `example`, `lists`, `now`, `onboarding`, `prediction`, `scheduling`, `search`, `settings`, `shell`, `tasks`, `templates`, `today`. There is no `commitment_contracts/` directory — create it from scratch following the standard feature anatomy (data/, domain/, presentation/).

### CRITICAL: Universal Link return flow — architecture already resolved

Architecture Gap 1 (architecture.md line ~1026) is resolved: Universal Link `https://ontaskhq.com/payment-setup-complete?sessionToken=xxx` (primary) and URL scheme `ontaskhq://payment-setup-complete?sessionToken=xxx` (fallback) are already registered in `Info.plist` and `Runner.entitlements`. The Flutter AppRouter deep link handler that intercepts this URL is NOT implemented in this story — it requires Story 13.1 (AASA + payment pages) to be deployed first. Stub the handler path with `TODO(impl)` comments.

### CRITICAL: Session token design (architecture-mandated)

The session token flow is:
1. App calls `POST /v1/payment-method/setup-session` → API returns `{ setupUrl, sessionToken }`
2. App opens `setupUrl` (includes `?sessionToken=xxx` as query param) via `url_launcher`
3. After Stripe SetupIntent completes on the web page, it redirects to `https://ontaskhq.com/payment-setup-complete?sessionToken=xxx`
4. iOS intercepts this URL via Universal Link → app receives it → calls `POST /v1/payment-method/confirm` with the token
5. API validates token, retrieves the completed SetupIntent from Stripe, stores the PaymentMethod

In this stub story: step 4 is not wired (requires AASA). The `confirmSetup()` repository method exists and is tested but is not automatically called by deep link. The UI stub can show a "Tap to confirm setup" button for testing purposes with `TODO(impl): replace with automatic deep link handler`.

### CRITICAL: TypeScript NodeNext — `.js` extensions on all local imports

```typescript
// Correct — always .js extension for local imports in apps/api/src/
import { ok, err } from '../lib/response.js'
import { commitmentContractsRouter } from './routes/commitment-contracts.js'
```

### CRITICAL: `z.record()` requires two arguments

If any schema uses `z.record(...)`, use `z.record(z.string(), valueType)` — two args required.

### CRITICAL: `@hono/zod-openapi` — always use `createRoute` pattern

Every route in `commitment-contracts.ts` must use `createRoute({ method, path, tags, request, responses })`. No untyped Hono routes. Reference existing pattern in `apps/api/src/routes/users.ts`.

### CRITICAL: Drizzle `casing: 'camelCase'`

Write schema in camelCase (`stripeCustomerId`, `paymentMethodLast4`). Drizzle generates snake_case DDL (`stripe_customer_id`, `payment_method_last4`) automatically. Do NOT add manual `.name()` overrides.

### CRITICAL: Generated `.freezed.dart` and `.g.dart` files must be committed

After any Dart model or `@riverpod` annotation changes, run:
```
dart run build_runner build --delete-conflicting-outputs
```
Commit ALL generated files. No `build_runner` in CI.

Files needing generation in this story:
- `commitment_payment_status.freezed.dart` — new Freezed model
- `commitment_contracts_repository.g.dart` — new `@riverpod` class

### CRITICAL: `OnTaskColors.surfacePrimary` (not `backgroundPrimary`)

Use `colors.surfacePrimary` for screen/sheet backgrounds. `backgroundPrimary` does not exist.

### CRITICAL: `minimumSize: const Size(44, 44)` on `CupertinoButton`

Use `minimumSize: const Size(44, 44)`, NOT the deprecated `minSize`. Applies to all new `CupertinoButton` instances in `PaymentSettingsScreen`.

### CRITICAL: `AppStrings` existing strings — do NOT recreate

Already exist and must be reused:
- `AppStrings.actionDelete` — destructive confirmation action label
- `AppStrings.actionCancel` — cancel label
- `AppStrings.actionOk` — OK/dismiss action label
- `AppStrings.dialogErrorTitle` — 'Error' for alert dialogs
- `AppStrings.actionDone` — done action label

### CRITICAL: Riverpod `AsyncValue<T>` — never raw `Future<T>`

All async providers must return `AsyncValue<T>`. Widget `build()` method handles `AsyncValue.when(data:, loading:, error:)`.

### CRITICAL: Settings screen tile pattern

`SettingsScreen` uses `_SettingsTile(label, icon, onTap)` — a private widget defined in the same file. Follow this pattern exactly (see `apps/flutter/lib/features/settings/presentation/settings_screen.dart`).

### Architecture: `url_launcher` dependency

The `launchUrl` call for opening `ontaskhq.com/setup` requires `url_launcher` package. Verify it is already in `apps/flutter/pubspec.yaml`. If not, add `url_launcher: ^6.x.x`. Use `LaunchMode.externalApplication` so Safari opens the setup page (not an in-app WebView).

### Deferred: real Stripe implementation

For each stub endpoint, `TODO(impl)` notes:
- `POST /v1/payment-method/setup-session`: create Stripe Customer (if not exists), create SetupIntent, store `setupSessionToken` with 5-minute expiry
- `POST /v1/payment-method/confirm`: validate token, retrieve SetupIntent from Stripe API, extract PaymentMethod, store `stripePaymentMethodId + last4 + brand`
- `DELETE /v1/payment-method`: check `hasActiveStakes`; if false, detach PaymentMethod from Stripe, null out fields
- All Stripe SDK calls go in `apps/api/src/services/stripe.ts` (already planned in architecture)

### PCI SAQ A compliance note

Raw card data never reaches On Task servers. The Stripe SetupIntent/PaymentIntent pattern means all card entry happens on Stripe-hosted elements at `ontaskhq.com/setup`. On Task stores only `paymentMethodId`, `last4`, and `brand` — never raw card numbers. This is by design (NFR-S2).

### Existing route state in `apps/api/src/index.ts`

Currently registered routers (do NOT modify registration of existing routers):
- `authRouter` from `./routes/auth.js`
- `usersRouter` from `./routes/users.js`
- `tasksRouter` from `./routes/tasks.js`
- `listsRouter` from `./routes/lists.js`
- `sharingRouter` from `./routes/sharing.js`
- `schedulingRouter` from `./routes/scheduling.js`

Add `commitmentContractsRouter` after these.

### Project Structure Notes

- New API route file: `apps/api/src/routes/commitment-contracts.ts` (create)
- New schema file: `packages/core/src/schema/commitment-contracts.ts` (create)
- New migration: `packages/core/src/schema/migrations/0012_commitment_contracts.sql` (generate)
- New Flutter feature: `apps/flutter/lib/features/commitment_contracts/` (create)
- Modify: `packages/core/src/schema/index.ts` (add export)
- Modify: `apps/api/src/index.ts` (mount new router)
- Modify: `apps/flutter/lib/features/settings/presentation/settings_screen.dart` (add Payments tile)
- Modify: `apps/flutter/lib/core/l10n/strings.dart` (add payment strings)

### References

- Epic 6 story definition: `_bmad-output/planning-artifacts/epics.md` lines 1500–1520
- Architecture payment setup flow (Gap 1 resolved): `_bmad-output/planning-artifacts/architecture.md` lines 1026–1035
- Architecture route locations: `_bmad-output/planning-artifacts/architecture.md` lines 735, 1009
- Architecture Flutter feature structure: `_bmad-output/planning-artifacts/architecture.md` lines 495–511
- Architecture Stripe service location: `_bmad-output/planning-artifacts/architecture.md` line 749
- Architecture testing patterns: `_bmad-output/planning-artifacts/architecture.md` lines 648–668
- Drizzle casing pattern: established in all previous stories; `db/index.ts` uses `casing: 'camelCase'`
- Previous story patterns: `_bmad-output/implementation-artifacts/5-6-member-management-shared-ownership.md`
- Settings screen: `apps/flutter/lib/features/settings/presentation/settings_screen.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
