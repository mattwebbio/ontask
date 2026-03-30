# Story 1.2: CI/CD Pipeline & Staging Environments

Status: done

## Story

As a developer,
I want automated CI checks on every PR and ephemeral staging environments,
So that broken code is caught before merging and features can be tested against real infrastructure.

## Acceptance Criteria

1. **Given** a pull request is opened or synchronized, **When** the CI pipeline runs, **Then** a GitHub Actions workflow executes: Flutter unit + widget tests, scheduling engine tests with 100% coverage gate, lint + typecheck for all TypeScript packages, and a Wrangler dry-run bundle size check that fails if either Worker exceeds 8MB
2. A Neon ephemeral database branch is created for the PR on open/synchronize
3. The ephemeral branch is deleted when the PR is closed or merged
4. `apps/api/wrangler.jsonc` defines a `staging` environment with route `api.staging.ontaskhq.com/*`
5. `apps/mcp/wrangler.jsonc` defines a `staging` environment with route `mcp.staging.ontaskhq.com/*`
6. A Fastlane `Fastfile` exists in `apps/flutter/fastlane/` with a `beta` lane that auto-increments build number and uploads to TestFlight

## Tasks / Subtasks

- [x] Implement `ci.yml` — full CI pipeline (AC: 1, 2, 3)
  - [x] Replace stub `ci.yml` with real pipeline triggered on `pull_request` (types: opened, synchronize, reopened, closed)
  - [x] Add job: `lint-typecheck` — runs `pnpm -r typecheck` across all workspace packages; uses `pnpm install --frozen-lockfile`
  - [x] Add job: `scheduling-tests` — runs `pnpm test` in `packages/scheduling` with 100% coverage gate (vitest with `--coverage` and `coverage.thresholds.lines: 100`)
  - [x] Add job: `flutter-tests` — runs `flutter test` in `apps/flutter/`
  - [x] Add job: `bundle-size` — runs `pnpm --filter @ontask/api wrangler deploy --dry-run` and `pnpm --filter @ontask/mcp wrangler deploy --dry-run`; fails if either exceeds 8MB; parses output to extract compressed size
  - [x] Add job: `neon-branch-create` — on PR open/synchronize/reopen (not closed); calls Neon API to create ephemeral branch named `${{ github.head_ref }}`
  - [x] Add job: `neon-branch-delete` — on PR closed only; calls Neon API to delete ephemeral branch
- [x] Add vitest + coverage to `packages/scheduling` (AC: 1)
  - [x] Add `vitest` and `@vitest/coverage-v8` as devDependencies to `packages/scheduling/package.json`
  - [x] Add `vitest.config.ts` to `packages/scheduling/` with `coverage: { provider: 'v8', thresholds: { lines: 100, functions: 100, branches: 100 } }`
  - [x] Confirm `pnpm test` in `packages/scheduling/` runs vitest (package already has `"test": "vitest run"` script — verify or add)
- [x] Add staging environments to wrangler configs (AC: 4, 5)
  - [x] Add `[env.staging]` block to `apps/api/wrangler.jsonc` with `name: "ontask-api-staging"` and route `api.staging.ontaskhq.com/*`
  - [x] Add `[env.staging]` block to `apps/mcp/wrangler.jsonc` with `name: "ontask-mcp-staging"` and route `mcp.staging.ontaskhq.com/*`
- [x] Add Fastlane Fastfile (AC: 6)
  - [x] Create `apps/flutter/fastlane/Fastfile` with a `beta` lane: increment build number from App Store Connect, build IPA with `flutter build ipa`, upload to TestFlight via `upload_to_testflight`
  - [x] Create `apps/flutter/fastlane/Appfile` with `app_identifier("com.ontaskhq.ontask")` and `apple_id` placeholder

## Dev Notes

### Previous Story Context (Story 1.1)

**Critical learning — wrangler.jsonc not wrangler.toml:**
The Hono scaffold (create-hono v0.19.4) generates `wrangler.jsonc`, not `wrangler.toml`. Wrangler 4.x uses JSONC by default. The epics spec says `wrangler.toml` but the actual files are `wrangler.jsonc`. Use JSONC format throughout — do NOT convert to TOML.

**pnpm workspace packages:**
- `@ontask/api` → `apps/api/`
- `@ontask/mcp` → `apps/mcp/`
- `@ontask/admin-api` → `apps/admin-api/`
- `@ontask/admin` → `apps/admin/`
- `@ontask/core`, `@ontask/scheduling`, `@ontask/ai` → `packages/*/`

**Build scripts ignored at install:** `pnpm install` warns about ignored build scripts for `esbuild`, `workerd`, `sharp`. CI must run `pnpm approve-builds` OR use `pnpm install --frozen-lockfile` with a pre-approved `.pnpm/build-scripts-allowlist` OR simply run `pnpm install --frozen-lockfile --ignore-scripts=false` to allow native builds.

### CI Pipeline Design (ci.yml)

The pipeline runs on `pull_request` with types `[opened, synchronize, reopened, closed]`. Jobs are conditional on `github.event.action != 'closed'` where appropriate.

**Recommended job structure:**

```yaml
name: CI

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

jobs:
  lint-typecheck:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: '10.33.0'
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm -r typecheck

  scheduling-tests:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: '10.33.0'
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter @ontask/scheduling test --coverage
        # vitest exits non-zero if thresholds not met

  flutter-tests:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest  # or macos-latest for full platform fidelity
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.0'
          channel: 'stable'
      - run: flutter test
        working-directory: apps/flutter

  bundle-size:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: '10.33.0'
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - name: Check API worker bundle size
        run: |
          OUTPUT=$(pnpm --filter @ontask/api exec wrangler deploy --dry-run --outdir /tmp/api-bundle 2>&1)
          echo "$OUTPUT"
          # Wrangler dry-run outputs bundle size; fail if > 8MB
          # Parse the compressed size from wrangler output
      - name: Check MCP worker bundle size
        run: |
          OUTPUT=$(pnpm --filter @ontask/mcp exec wrangler deploy --dry-run --outdir /tmp/mcp-bundle 2>&1)
          echo "$OUTPUT"

  neon-branch-create:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - name: Create Neon branch
        run: |
          curl -X POST https://console.neon.tech/api/v1/projects/${{ secrets.NEON_PROJECT_ID }}/branches \
            -H "Authorization: Bearer ${{ secrets.NEON_API_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{"branch": {"name": "${{ github.head_ref }}"}}'

  neon-branch-delete:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - name: Get Neon branch ID
        id: get-branch
        run: |
          BRANCH_ID=$(curl -s https://console.neon.tech/api/v1/projects/${{ secrets.NEON_PROJECT_ID }}/branches \
            -H "Authorization: Bearer ${{ secrets.NEON_API_KEY }}" \
            | jq -r '.branches[] | select(.name == "${{ github.head_ref }}") | .id')
          echo "branch_id=$BRANCH_ID" >> $GITHUB_OUTPUT
      - name: Delete Neon branch
        if: steps.get-branch.outputs.branch_id != ''
        run: |
          curl -X DELETE "https://console.neon.tech/api/v1/projects/${{ secrets.NEON_PROJECT_ID }}/branches/${{ steps.get-branch.outputs.branch_id }}" \
            -H "Authorization: Bearer ${{ secrets.NEON_API_KEY }}"
```

**Note:** The Neon API body format uses `{"branch": {"name": "..."}}` not just `{"name": "..."}` — the architecture doc shows a simplified version. Verify against actual Neon API docs if you hit 422 errors.

### Bundle Size Check — Wrangler Dry-Run

`wrangler deploy --dry-run --outdir <dir>` writes the bundled output to `<dir>` without deploying. The compressed size appears in the wrangler stdout output. As of Wrangler 4.x, the output includes a line like:

```
Total Upload: 1.23 MiB / gzip: 0.45 MiB
```

Parse the gzip value and compare to 8MB (8192 KiB). A simple shell approach:

```bash
GZIP_SIZE=$(echo "$OUTPUT" | grep -oP 'gzip: \K[\d.]+(?= MiB)')
if (( $(echo "$GZIP_SIZE > 8" | bc -l) )); then
  echo "ERROR: Bundle exceeds 8MB compressed ($GZIP_SIZE MiB)"
  exit 1
fi
```

**Important:** `pnpm approve-builds` is required to allow esbuild/workerd native builds. In CI, add this step before `wrangler deploy --dry-run`:

```yaml
- run: pnpm install --frozen-lockfile
- run: pnpm approve-builds --yes || true  # approve native builds non-interactively
```

Alternatively, commit a `.npmrc` or `pnpm-workspace.yaml` `onlyBuiltDependencies` allowlist.

### Vitest Config for packages/scheduling

```typescript
// packages/scheduling/vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      thresholds: {
        lines: 100,
        functions: 100,
        branches: 100,
        statements: 100,
      },
    },
  },
})
```

**Note:** Since `packages/scheduling` currently only has `export {}` as its source, 100% coverage passes trivially. The threshold will become meaningful in Epic 3. Do not add placeholder tests — leave the test directory empty or with a single passing smoke test. The important thing is the coverage gate is wired up correctly.

### wrangler.jsonc Staging Environment Format

JSONC does not support TOML-style `[env.staging]` sections. Wrangler JSONC uses an `"env"` key:

```jsonc
{
  "$schema": "../../node_modules/wrangler/config-schema.json",
  "name": "ontask-api",
  "main": "src/index.ts",
  "compatibility_date": "2026-03-29",
  "env": {
    "staging": {
      "name": "ontask-api-staging",
      "routes": [
        {
          "pattern": "api.staging.ontaskhq.com/*",
          "zone_name": "ontaskhq.com"
        }
      ]
    }
  }
}
```

Apply the same pattern for `apps/mcp/wrangler.jsonc` with `name: "ontask-mcp-staging"` and `api.staging.ontaskhq.com` → `mcp.staging.ontaskhq.com`.

### Fastlane Fastfile

Fastlane must be installed on the developer machine (`gem install fastlane`). The `Fastfile` is for local and CI use:

```ruby
# apps/flutter/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Upload a new beta build to TestFlight"
  lane :beta do
    # Increment build number from App Store Connect
    increment_build_number(
      build_number: app_store_build_number(
        app_identifier: "com.ontaskhq.ontask",
        live: false
      ) + 1
    )

    # Build Flutter IPA
    sh("flutter build ipa --release", chdir: "../")

    # Upload to TestFlight
    upload_to_testflight(
      ipa: "../build/ios/ipa/ontask.ipa",
      skip_waiting_for_build_processing: true,
    )
  end
end
```

```ruby
# apps/flutter/fastlane/Appfile
app_identifier("com.ontaskhq.ontask")
apple_id("") # Set via FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD env var in CI
team_id("")  # Set via FASTLANE_TEAM_ID env var or fastlane env
```

**Fastlane is not run in the CI pipeline for this story** — that is a future story. The `Fastfile` and `Appfile` are created here so they are version-controlled and ready. CI integration (App Store Connect API key setup, codesigning, etc.) is deferred.

### GitHub Actions Secrets Required

Document these required secrets (do not set them — that's an ops task):

| Secret | Used by |
|---|---|
| `NEON_PROJECT_ID` | Neon branch create/delete jobs |
| `NEON_API_KEY` | Neon branch create/delete jobs |

These must be set in the GitHub repo Settings → Secrets before the Neon jobs will succeed. The jobs must hard-fail if secrets are missing — do NOT use `continue-on-error` or suppress failures. A failing Neon job should block the CI run so broken infrastructure is immediately visible.

### Scope Boundaries — What Is NOT In This Story

| Item | Belongs To |
|---|---|
| Actual Cloudflare Worker deployment | Story-by-story as features land |
| Drizzle migration runner in CI | Story 1.3 |
| Integration tests against Neon branch | Story 1.3 (needs schema first) |
| App Store Connect API key setup / codesigning | After Fastlane is configured |
| `deploy-staging.yml` real implementation | After first deployable Worker story |
| `apps/admin-api/wrangler.jsonc` staging env | Not required by AC — omit for now |

### Project Structure Notes

- `wrangler.jsonc` is the correct file format — do not create `wrangler.toml` files
- Worker names in `wrangler.jsonc` should be updated to match their `@ontask/` scoped names (e.g., `"name": "ontask-api"`)
- Keep `deploy-staging.yml` and `deploy-production.yml` as stubs — they'll be filled in once Cloudflare account credentials are configured

### References

- [Source: architecture.md — CI/CD] — pipeline steps, bundle size check, Neon branch pattern
- [Source: architecture.md — Domains & Environments] — staging URLs
- [Source: epics.md — Story 1.2] — acceptance criteria
- [Source: story 1-1-monorepo-project-scaffold.md — Debug Log] — wrangler.jsonc format, pnpm build scripts warning

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `pnpm -r typecheck` failed initially — TypeScript not in packages (core/ai/scheduling) own devDependencies. Fixed by adding `typescript: ^5.8.0` to root `package.json` so it's hoisted workspace-wide.
- Wrangler dry-run outputs `gzip: X.XX KiB` (not MiB) for small bundles. Bundle size parser handles both KiB and MiB units.
- `pnpm approve-builds --yes` required in CI before wrangler dry-run to enable native esbuild/workerd builds.
- Vitest 100% coverage gate: `export {}` compiles to 0 coverable statements, so thresholds trivially pass (0/0). Gate becomes meaningful in Epic 3 when real scheduling logic is added.
- Neon API v2 endpoint used (`/api/v2/`) — architecture doc shows v1 but v2 is current. Branch named `pr-{number}` (not `github.head_ref`) to avoid slash characters in branch names.
- Worker names updated: `ontask-api` and `ontask-mcp` in wrangler.jsonc (were `api`/`mcp`).

### Completion Notes List

- ✅ `ci.yml` — 6 jobs: lint-typecheck, scheduling-tests (100% coverage), flutter-tests, bundle-size (KiB+MiB parser, 8MB gate), neon-branch-create, neon-branch-delete; all Neon jobs hard-fail if secrets missing
- ✅ `packages/scheduling` — @vitest/coverage-v8 added, vitest.config.ts with 100% thresholds, smoke test added
- ✅ `apps/api/wrangler.jsonc` — staging env: ontask-api-staging @ api.staging.ontaskhq.com
- ✅ `apps/mcp/wrangler.jsonc` — staging env: ontask-mcp-staging @ mcp.staging.ontaskhq.com
- ✅ `apps/flutter/fastlane/Fastfile` — beta lane with build number increment + TestFlight upload
- ✅ `apps/flutter/fastlane/Appfile` — bundle ID com.ontaskhq.ontask, env-var-driven credentials
- ✅ Root `package.json` — typescript ^5.8.0 added as workspace-level devDependency

### File List

- `.github/workflows/ci.yml`
- `packages/scheduling/package.json`
- `packages/scheduling/vitest.config.ts`
- `packages/scheduling/src/index.test.ts`
- `apps/api/wrangler.jsonc`
- `apps/mcp/wrangler.jsonc`
- `apps/flutter/fastlane/Fastfile`
- `apps/flutter/fastlane/Appfile`
- `package.json`
- `pnpm-lock.yaml`

### Review Findings

- [x] [Review][Patch] Secrets interpolated directly into shell scripts — bind to `env:` block and reference as `$VAR` instead of `${{ secrets.X }}` inline [`.github/workflows/ci.yml` neon jobs]
- [x] [Review][Patch] `curl -sf` in `neon-branch-delete` swallows API errors, masking failures as "branch not found" — use `-s` only and check HTTP status like other steps [`.github/workflows/ci.yml:201`]
- [x] [Review][Patch] Bundle size check silently passes when `GZIP_LINE` is empty (wrangler output format change or build failure) — add guard: `if [ -z "$GZIP_LINE" ]; then exit 1; fi` [`.github/workflows/ci.yml:112`]
- [x] [Review][Patch] `neon-branch-create` creates a duplicate branch on every `synchronize`/`reopened` event — add idempotency: check if branch exists first or treat 409 as success [`.github/workflows/ci.yml:150`]
- [x] [Review][Patch] Neon branch list endpoint is paginated; `jq` only sees page 1 — add `?limit=100` query param or handle pagination to avoid silently missing the target branch [`.github/workflows/ci.yml:202`]
- [x] [Review][Patch] `lint` step missing from `lint-typecheck` job — AC 1 requires both lint and typecheck; add `pnpm -r lint` step [`.github/workflows/ci.yml:20`]
- [x] [Review][Defer] Flutter CI on `ubuntu-latest` — iOS platform tests can't run on Linux; known tradeoff per story notes [`.github/workflows/ci.yml:70`] — deferred, pre-existing
- [x] [Review][Defer] 100% coverage trivially passes on empty module — intentional per dev notes; becomes meaningful when Epic 3 adds real logic [`.github/workflows/ci.yml`, `packages/scheduling/vitest.config.ts`] — deferred, pre-existing
- [x] [Review][Defer] Fastlane auth/race condition concerns — Fastlane not run in CI for this story; defer to TestFlight integration story [`apps/flutter/fastlane/Fastfile`] — deferred, pre-existing
- [x] [Review][Defer] IPA path `ontask.ipa` hardcoded — will fail if pubspec name differs; deferred until Fastlane runs in CI [`apps/flutter/fastlane/Fastfile:12`] — deferred, pre-existing
- [x] [Review][Defer] `pnpm -r typecheck` silently skips packages without a `typecheck` script — pre-existing pnpm behavior, not introduced by this story — deferred, pre-existing
- [x] [Review][Defer] `jq` multi-match in `neon-branch-delete` could produce multi-line `branch_id` — very unlikely edge case [`.github/workflows/ci.yml:205`] — deferred, pre-existing
