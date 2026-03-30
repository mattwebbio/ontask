# Story 1.1: Monorepo & Project Scaffold

Status: done

## Story

As a developer,
I want a complete monorepo scaffold with Flutter, API worker, MCP worker, admin API worker, admin SPA, and shared packages initialized under pnpm workspaces,
So that all packages share consistent tooling, TypeScript config, and gitignore rules from day one.

## Acceptance Criteria

1. **Given** an empty repository, **When** monorepo setup is complete, **Then** workspace root contains `pnpm-workspace.yaml` listing `apps/*` and `packages/*`
2. `tsconfig.base.json` exists at root with shared compiler options extended by all apps and packages
3. `apps/api/` contains a Hono worker scaffolded via `npm create hono@latest -- --template cloudflare-workers`
4. `apps/mcp/` contains a Hono worker scaffolded via `npm create hono@latest -- --template cloudflare-workers`
5. `apps/flutter/` contains a Flutter project created with `flutter create --org com.ontaskhq --platforms=ios,macos --project-name ontask`
6. Root `.gitignore` does **NOT** include entries for `*.g.dart` or `*.freezed.dart` — generated Dart files are committed
7. `pnpm install` from root succeeds with no errors
8. All apps and packages listed in the canonical directory tree exist as scaffolded directories (see Dev Notes)

## Tasks / Subtasks

- [x] Initialize workspace root (AC: 1, 2, 6)
  - [x] Create `pnpm-workspace.yaml` with `packages: ['apps/*', 'packages/*']`
  - [x] Create `package.json` at root marking `"private": true` with `"workspaces"` field
  - [x] Create `tsconfig.base.json` with shared strict TS options (target ES2022, module NodeNext, strict, skipLibCheck)
  - [x] Create `.gitignore` — include standard Node/Flutter ignores but explicitly **exclude** `*.g.dart` and `*.freezed.dart` patterns
  - [x] Create `README.md` with minimal project description
- [x] Scaffold Hono Workers (AC: 3, 4)
  - [x] Run `npm create hono@latest -- --template cloudflare-workers` in `apps/api/`; add `tsconfig.json` extending `../../tsconfig.base.json`
  - [x] Run `npm create hono@latest -- --template cloudflare-workers` in `apps/mcp/`; add `tsconfig.json` extending `../../tsconfig.base.json`
  - [x] Create minimal `apps/admin-api/` Hono worker scaffold (same template); add `tsconfig.json` extending base
  - [x] Create placeholder `apps/admin/` Vite + React SPA scaffold; add `tsconfig.json` extending base
- [x] Create Flutter app (AC: 5)
  - [x] Run `flutter create --org com.ontaskhq --platforms=ios,macos --project-name ontask` inside `apps/flutter/`
  - [x] Verify `ios/Runner/Info.plist` bundle ID is `com.ontaskhq.ontask`
  - [x] Verify macOS target is present under `macos/`
- [x] Scaffold shared packages (AC: 7, 8)
  - [x] Create `packages/core/` with `package.json`, `tsconfig.json` (extends base), and `src/index.ts` stub
  - [x] Create `packages/scheduling/` with `package.json`, `tsconfig.json`, and `src/index.ts` stub
  - [x] Create `packages/ai/` with `package.json`, `tsconfig.json`, and `src/index.ts` stub
- [x] Verify workspace (AC: 7)
  - [x] Run `pnpm install` from root — must succeed with zero errors

### Review Findings

- [x] [Review][Decision] `apps/admin` uses Hono JSX renderer instead of React — resolved: replaced with React + Vite scaffold (React 19, @vitejs/plugin-react, standard SPA entry point)
- [x] [Review][Decision] `packages/*` export raw `.ts` source files — resolved: accepted as-is; source-import is idiomatic for TypeScript-only internal packages consumed by bundlers
- [x] [Review][Patch] `packages/scheduling/package.json` declares `"test": "vitest run"` but `vitest` is not in devDependencies — fixed: added `vitest: ^3.0.0` to devDependencies [packages/scheduling/package.json]
- [x] [Review][Patch] `wrangler.jsonc` `$schema` path `node_modules/wrangler/config-schema.json` won't resolve when wrangler is hoisted — fixed: updated to `../../node_modules/wrangler/config-schema.json` [apps/*/wrangler.jsonc]
- [x] [Review][Patch] Worker/Pages app README files instruct `npm install` / `npm run dev` — fixed: updated to pnpm commands [apps/api/README.md, apps/mcp/README.md, apps/admin-api/README.md]
- [x] [Review][Patch] `apps/flutter/.metadata` not gitignored — fixed: added `.metadata` to Flutter section [.gitignore]
- [x] [Review][Patch] `.gitignore` has duplicate `build/` entry — fixed: removed duplicate from Flutter section [.gitignore]
- [x] [Review][Patch] `compatibility_date: "2026-03-30"` in all `wrangler.jsonc` files is a future date — fixed: updated to `2026-03-29` [apps/*/wrangler.jsonc]
- [x] [Review][Patch] Missing trailing newlines in all Worker app `package.json` files — fixed: rewrote files with proper newlines [apps/api/package.json, apps/mcp/package.json, apps/admin-api/package.json]
- [x] [Review][Patch] `pnpm-workspace.yaml` `apps/*` pattern includes `apps/flutter/` which has no `package.json` — fixed: added `!apps/flutter` exclusion [pnpm-workspace.yaml]
- [x] [Review][Defer] `tsconfig.base.json` sets `module: NodeNext` / `moduleResolution: NodeNext` which all app tsconfigs override with `ESNext` / `Bundler`; packages inherit NodeNext — matches spec today but will create real tension when packages get code in Story 1.3 [tsconfig.base.json] — deferred, pre-existing
- [x] [Review][Defer] Stub CI/CD workflows (ci.yml, deploy-staging.yml, deploy-production.yml) are live and always pass — gives false green in branch protection; intentional scaffold for Story 1.2 [.github/workflows/] — deferred, pre-existing
- [x] [Review][Defer] `apps/admin/src/renderer.tsx` references `/static/style.css` which doesn't exist — will 404 silently; stub app, addressed when admin SPA is developed [apps/admin/src/renderer.tsx:6] — deferred, pre-existing
- [x] [Review][Defer] `ci.yml` only triggers on `pull_request`, not on direct pushes to `main` — bypasses CI on squash-merges; stub workflow, corrected in Story 1.2 [.github/workflows/ci.yml] — deferred, pre-existing

## Dev Notes

### Canonical Directory Tree

The full target structure (architecture-defined) — scaffold ALL of these now even if contents are minimal stubs:

```
ontask/
├── package.json                    # "private": true, pnpm workspaces
├── pnpm-workspace.yaml             # packages: ['apps/*', 'packages/*']
├── tsconfig.base.json              # base TS config extended by all packages
├── .gitignore                      # must NOT ignore *.g.dart / *.freezed.dart
├── README.md
├── .github/
│   └── workflows/
│       ├── ci.yml                  # stub only — implemented in Story 1.2
│       ├── deploy-staging.yml      # stub only
│       └── deploy-production.yml   # stub only
│
├── apps/
│   ├── api/                        # Hono REST API Worker (api.ontaskhq.com/v1/*)
│   ├── admin-api/                  # Hono Operator API Worker (api.ontaskhq.com/admin/v1/*)
│   ├── mcp/                        # Hono MCP Worker (mcp.ontaskhq.com)
│   ├── flutter/                    # Flutter iOS/macOS app (com.ontaskhq)
│   └── admin/                      # Cloudflare Pages admin SPA (admin.ontaskhq.com)
│
└── packages/
    ├── core/                       # shared types + Drizzle schema (populated in Story 1.3)
    ├── scheduling/                 # scheduling engine (populated in Epic 3)
    └── ai/                         # AI pipeline abstraction (populated in Epic 4)
```

### Critical: Generated Dart Files Must Be Committed

**Do NOT add `*.g.dart` or `*.freezed.dart` to `.gitignore`.** These files are generated by `build_runner` (freezed, json_serializable, Riverpod generator) and are committed to the repo. This is intentional — CI does not run `build_runner`, so the generated files must be present in source control.

- If you see a standard Flutter `.gitignore` template that includes `*.g.dart` — remove those lines
- This is a hard architectural constraint [Source: architecture.md — Repository Structure, CI/CD section]

### Hono Worker Scaffold Details

**Version: Hono 4.12.9** [Source: architecture.md — Tech Stack]

Each Worker scaffold via `npm create hono@latest -- --template cloudflare-workers` produces:
- `src/index.ts` — entry point
- `wrangler.toml` — Cloudflare Worker config
- `package.json`
- `tsconfig.json` — update to extend `../../tsconfig.base.json`

**Worker routing (do not configure routing in this story — stub only):**
- `apps/api/` → `api.ontaskhq.com/v1/*` (REST API, heavy deps: Stripe, Google Calendar, Drizzle, AI SDK)
- `apps/admin-api/` → `api.ontaskhq.com/admin/v1/*` (separate Worker for bundle isolation)
- `apps/mcp/` → `mcp.ontaskhq.com` (lighter; communicates with API via Service Binding, not HTTP)

**Bundle size discipline (enforced by CI in Story 1.2):** Each Worker must stay under 8MB compressed. Be mindful when adding dependencies in future stories.

### Flutter Project Details

**Version: Flutter 3.41 stable** [Source: architecture.md — Tech Stack]

Exact scaffold command:
```bash
flutter create --org com.ontaskhq --platforms=ios,macos --project-name ontask
```

Run this **inside** `apps/flutter/` (not from the repo root). The result:
- Bundle ID: `com.ontaskhq.ontask`
- Both iOS and macOS targets present
- No Android or web targets (not in scope)

Do **not** install any Flutter packages in this story (Riverpod, go_router, drift, etc. — those are Story 1.4).

### tsconfig.base.json Recommended Config

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

Each app/package `tsconfig.json` must include `"extends": "../../tsconfig.base.json"` (adjust relative path as needed).

### Scope Boundaries — What Is NOT In This Story

| Item | Belongs To |
|------|-----------|
| GitHub Actions CI pipeline implementation | Story 1.2 |
| Neon ephemeral branch automation | Story 1.2 |
| Fastlane TestFlight setup | Story 1.2 |
| Drizzle ORM, database schema, response standards | Story 1.3 |
| Riverpod, go_router, drift, freezed configuration | Story 1.4 |
| Design tokens, colour system, typography | Story 1.5 |
| Wrangler routing & environment config | Story 1.2 |

Create `.github/workflows/` with stub YAML files so the directory exists, but leave actual CI logic for Story 1.2.

### packages/core, packages/scheduling, packages/ai — Minimal Stubs

These packages are populated in later stories. For this story, create:
- `package.json` with name `@ontask/core` / `@ontask/scheduling` / `@ontask/ai`, `"private": true`, `"main": "src/index.ts"`
- `tsconfig.json` extending `../../tsconfig.base.json`
- `src/index.ts` as an empty export: `export {}`

### Project Structure Notes

- All TypeScript apps and packages must extend `tsconfig.base.json` — no standalone TypeScript configs
- `pnpm-workspace.yaml` must use `packages:` array syntax, not `workspaces:` (pnpm-specific format)
- Do not use `npm` or `yarn` — pnpm workspaces only throughout the project
- The Flutter project sits inside `apps/flutter/` within the monorepo; its own `pubspec.yaml` and Dart tooling are self-contained

### References

- [Source: architecture.md — Repository Structure] — canonical monorepo layout and rationale
- [Source: architecture.md — CI/CD] — generated file commit policy, bundle size discipline
- [Source: architecture.md — Complete Monorepo Directory Tree] — full directory tree
- [Source: architecture.md — `apps/api/`] — Hono Worker structure
- [Source: architecture.md — `apps/flutter/`] — Flutter app structure
- [Source: epics.md — Story 1.1] — acceptance criteria

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `npx create-hono@latest` (v0.19.4) scaffolds `wrangler.jsonc` instead of `wrangler.toml` — this is the current Wrangler v4 format; functionally equivalent. Architecture references `wrangler.toml` but `.jsonc` is correct for Wrangler 4.x.
- Flutter 3.41.0 installed via `asdf install flutter 3.41.0-stable`; `asdf set flutter 3.41.0-stable` wrote version to `.tool-versions`
- Flutter `.gitignore` generated by `flutter create` does not contain `*.g.dart` or `*.freezed.dart` — confirmed clean
- pnpm installed globally via `npm install -g pnpm@10.33.0`; `pnpm install` from workspace root completes in ~2.7s

### Completion Notes List

- ✅ Workspace root: `pnpm-workspace.yaml`, `package.json` (private, packageManager pnpm@10.33.0), `tsconfig.base.json` (ES2022/NodeNext/strict), `.gitignore` (no `*.g.dart` patterns), `README.md`
- ✅ `apps/api/` — Hono 4.12.9 cloudflare-workers template; `@ontask/api`; tsconfig extends base
- ✅ `apps/mcp/` — Hono 4.12.9 cloudflare-workers template; `@ontask/mcp`; tsconfig extends base
- ✅ `apps/admin-api/` — Hono 4.12.9 cloudflare-workers template; `@ontask/admin-api`; tsconfig extends base
- ✅ `apps/admin/` — Hono cloudflare-pages template (Vite-based); `@ontask/admin`; tsconfig extends base
- ✅ `apps/flutter/` — Flutter 3.41.0; `flutter create --org com.ontaskhq --platforms=ios,macos --project-name ontask`; bundle ID `com.ontaskhq.ontask`; iOS + macOS targets present
- ✅ `packages/core/`, `packages/scheduling/`, `packages/ai/` — stub `package.json`, `tsconfig.json` (extends base), `src/index.ts`
- ✅ `.github/workflows/` — stub `ci.yml`, `deploy-staging.yml`, `deploy-production.yml`
- ✅ `.tool-versions` — nodejs 25.8.2, flutter 3.41.0-stable
- ✅ `pnpm install` from root: 8 workspace projects, resolved 158 packages, no errors

### File List

- `package.json`
- `pnpm-workspace.yaml`
- `pnpm-lock.yaml`
- `tsconfig.base.json`
- `.gitignore`
- `.tool-versions`
- `README.md`
- `.github/workflows/ci.yml`
- `.github/workflows/deploy-staging.yml`
- `.github/workflows/deploy-production.yml`
- `apps/api/package.json`
- `apps/api/tsconfig.json`
- `apps/api/wrangler.jsonc`
- `apps/api/src/index.ts`
- `apps/api/README.md`
- `apps/mcp/package.json`
- `apps/mcp/tsconfig.json`
- `apps/mcp/wrangler.jsonc`
- `apps/mcp/src/index.ts`
- `apps/mcp/README.md`
- `apps/admin-api/package.json`
- `apps/admin-api/tsconfig.json`
- `apps/admin-api/wrangler.jsonc`
- `apps/admin-api/src/index.ts`
- `apps/admin-api/README.md`
- `apps/admin/package.json`
- `apps/admin/tsconfig.json`
- `apps/admin/vite.config.ts`
- `apps/admin/wrangler.jsonc`
- `apps/admin/src/` (index.ts + renderer.tsx)
- `apps/flutter/` (79 files generated by flutter create)
- `packages/core/package.json`
- `packages/core/tsconfig.json`
- `packages/core/src/index.ts`
- `packages/scheduling/package.json`
- `packages/scheduling/tsconfig.json`
- `packages/scheduling/src/index.ts`
- `packages/ai/package.json`
- `packages/ai/tsconfig.json`
- `packages/ai/src/index.ts`
