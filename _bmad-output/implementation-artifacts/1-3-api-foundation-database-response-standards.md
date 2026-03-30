# Story 1.3: API Foundation — Database & Response Standards

Status: done

## Story

As a developer,
I want a configured Drizzle ORM database layer and enforced API response standards,
so that all routes share a consistent schema, response envelope, and pagination contract.

## Acceptance Criteria

1. **Given** the API worker is initialized, **When** the database layer is configured, **Then** `@neondatabase/serverless` is installed using HTTP transport only — no `pg`, no connection pooling; `drizzle-orm` is installed from `drizzle-orm/neon-http`; every Drizzle instance is initialized with `casing: 'camelCase'`
2. All schema migrations are Drizzle Kit SQL files committed to `packages/core/schema/migrations/` — no upfront bulk schema; tables are created only in the story that first uses them
3. **Given** a Hono route returns a successful single-object response, **When** the response is received, **Then** the body is `{ "data": { ... } }`
4. **Given** a Hono route returns a successful list response, **When** the response is received, **Then** the body is `{ "data": [...], "pagination": { "cursor": "...", "hasMore": true } }` — cursor-based only, no offset/limit anywhere
5. **Given** a Hono route encounters an error, **When** the error response is returned, **Then** the body is `{ "error": { "code": "SCREAMING_SNAKE_CASE", "message": "...", "details": {} } }`; all date fields are ISO 8601 UTC strings; all JSON field names are camelCase
6. CORS is scoped only to `/admin/v1/*` and payment setup endpoints — NOT global; `/v1/*` routes have no CORS middleware
7. **Given** a new Hono route is created, **When** it is registered, **Then** it has a `@hono/zod-openapi` schema definition — no untyped routes accepted

## Tasks / Subtasks

- [x] Install and configure database dependencies (AC: 1)
  - [x] Add `@neondatabase/serverless`, `drizzle-orm` to `packages/core/package.json`
  - [x] Add `drizzle-kit` as devDependency to `packages/core/package.json`
  - [x] Add `@neondatabase/serverless`, `drizzle-orm` to `apps/api/package.json`
  - [x] Create `apps/api/src/db/index.ts` — exports `createDb(databaseUrl: string)` factory using `neon` + `drizzle(..., { casing: 'camelCase' })`
  - [x] Add `drizzle.config.ts` at `apps/api/` root — points to `packages/core/src/schema/` for schema, `packages/core/src/schema/migrations/` for out
  - [x] Add `DATABASE_URL` binding to `apps/api/wrangler.jsonc` vars section (placeholder value, real value set in Cloudflare dashboard)

- [x] Set up `packages/core` schema structure (AC: 2)
  - [x] Create `packages/core/src/schema/` directory with `index.ts` (empty export for now — no tables until the story that first uses them)
  - [x] Create `packages/core/src/schema/migrations/` directory with `.gitkeep`
  - [x] Create `packages/core/src/types/api.ts` — exports `DataResponse<T>`, `ListResponse<T>`, `ErrorResponse` TypeScript types
  - [x] Create `packages/core/src/types/index.ts` — re-exports from `api.ts`
  - [x] Create `packages/core/src/constants/index.ts` — placeholder export (`export {}` for now)
  - [x] Update `packages/core/src/index.ts` — export from `./schema`, `./types`, `./constants`

- [x] Install and wire `@hono/zod-openapi` into the API worker (AC: 7)
  - [x] Add `@hono/zod-openapi`, `zod` to `apps/api/package.json` dependencies
  - [x] Refactor `apps/api/src/index.ts` to use `OpenAPIHono` from `@hono/zod-openapi` instead of plain `Hono`
  - [x] Mount OpenAPI doc endpoint at `/v1/doc` (JSON spec) and `/v1/ui` (Scalar/Swagger UI) using `app.doc()` and `app.openapi()` pattern
  - [x] Remove the stub `app.get('/', ...)` hello-world handler

- [x] Create response envelope helpers (AC: 3, 4, 5)
  - [x] Create `apps/api/src/lib/response.ts` — exports `ok<T>(data: T)`, `list<T>(data: T[], cursor: string | null, hasMore: boolean)`, `err(code: string, message: string, details?: Record<string, unknown>)` helper functions that produce the standard envelope shapes
  - [x] Create `apps/api/src/lib/errors.ts` — exports typed `AppError` class with `code: string` and `httpStatus: number`; includes named subclasses: `NotFoundError` (404), `ValidationError` (400), `UnauthorizedError` (401), `ForbiddenError` (403), `ConflictError` (409), `BusinessLogicError` (422)

- [x] Add scoped CORS middleware (AC: 6)
  - [x] Add `hono/cors` (ships with Hono — no extra package needed) to `apps/api/src/middleware/cors.ts`
  - [x] Apply CORS middleware ONLY on route groups: `/admin/v1/*` and the payment setup endpoint — NOT on `/v1/*` generally; document this explicitly in the file

- [x] Add a typed health-check route as the first `@hono/zod-openapi` route (AC: 7)
  - [x] Create `apps/api/src/routes/health.ts` — `GET /v1/health` returning `{ "data": { "status": "ok" } }` with full `@hono/zod-openapi` schema; this validates the wiring works end-to-end

- [x] Update typecheck and verify (AC: all)
  - [x] Run `pnpm --filter @ontask/core typecheck` — must pass
  - [x] Run `pnpm --filter @ontask/api typecheck` — must pass
  - [x] Run `pnpm -r typecheck` from root — must pass with no errors

## Dev Notes

### Critical: Database Driver — HTTP Transport Only

`@neondatabase/serverless` must use HTTP transport. Standard `pg` connection pooling is incompatible with the Cloudflare Workers edge runtime. The exact import path is `drizzle-orm/neon-http` (not `drizzle-orm/neon-serverless`).

```typescript
// apps/api/src/db/index.ts
import { neon } from '@neondatabase/serverless'
import { drizzle } from 'drizzle-orm/neon-http'

export function createDb(databaseUrl: string) {
  const sql = neon(databaseUrl)
  return drizzle(sql, { casing: 'camelCase' })
}
```

`DATABASE_URL` arrives via Cloudflare Worker bindings (`env.DATABASE_URL`), not `process.env`. The `createDb` factory takes the URL as a parameter so it can be called with `c.env.DATABASE_URL` inside route handlers.

### Critical: Drizzle `casing: 'camelCase'`

This is NON-NEGOTIABLE. Every Drizzle instance MUST be initialized with `{ casing: 'camelCase' }`. This makes the ORM automatically transform DB `snake_case` column names to `camelCase` in query results — no manual field mapping ever. Do not skip this or add manual `.as()` aliases.

### `@hono/zod-openapi` — No Untyped Routes

Every route from this story forward MUST be defined using `createRoute` from `@hono/zod-openapi`, not plain `app.get()`. The pattern:

```typescript
import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

const healthRoute = createRoute({
  method: 'get',
  path: '/v1/health',
  responses: {
    200: {
      content: { 'application/json': { schema: z.object({ data: z.object({ status: z.string() }) }) } },
      description: 'Health check',
    },
  },
})

app.openapi(healthRoute, (c) => {
  return c.json({ data: { status: 'ok' } })
})
```

Reference: https://hono.dev/examples/zod-openapi

### Response Envelope — Standard Shapes

All API responses use these exact shapes. No deviations.

**Success single object:** `{ "data": { ...fields } }`
**Success list:** `{ "data": [...], "pagination": { "cursor": "...", "hasMore": true } }`
**Error:** `{ "error": { "code": "SCREAMING_SNAKE_CASE", "message": "human-readable", "details": {} } }`

Rules:
- JSON field names: always `camelCase` (handled automatically by Drizzle `casing: 'camelCase'`)
- Dates: ISO 8601 UTC (`2026-03-29T12:00:00Z`) — never Unix timestamps
- Pagination: cursor-based only — NO offset/limit, anywhere, ever
- Error codes: `SCREAMING_SNAKE_CASE` strings — never numeric codes

HTTP status codes to enforce:
| Code | When |
|---|---|
| `200` | Successful GET, PATCH |
| `201` | Successful POST (resource created) |
| `204` | Successful DELETE (no body) |
| `400` | Validation failure (Zod parse error) |
| `401` | Missing/invalid auth token |
| `403` | Authenticated but insufficient permission |
| `404` | Resource not found |
| `409` | Conflict (duplicate, state violation) |
| `422` | Business logic error (e.g. deadline already passed) |
| `429` | Rate limit exceeded |
| `500` | Unexpected server error |

### CORS Scope — Critical

`/v1/*` routes have NO CORS middleware. The Flutter client is a native HTTP client — it doesn't need CORS. CORS is applied ONLY to:
- `/admin/v1/*` — for the browser-based admin SPA at `admin.ontaskhq.com`
- Payment setup endpoints — for web-based payment flow

Do NOT add global CORS middleware. It expands attack surface unnecessarily.

### `packages/core` Schema Design Principles

- Schema files live in `packages/core/src/schema/` — one file per domain entity (e.g., `users.ts`, `tasks.ts`)
- Migration SQL files go in `packages/core/src/schema/migrations/` and are committed to the repo
- NO tables are created in this story — this story only creates the infrastructure to hold schemas. Tables are added in the story that first uses them.
- Drizzle table export naming: `{entity}Table` (e.g., `tasksTable`, `usersTable`)
- All tables get `created_at` + `updated_at` columns
- Column names: `snake_case` in DB; Drizzle `casing: 'camelCase'` handles the transform
- Foreign keys: `{singular_table}_id` pattern

### `drizzle.config.ts` Location and Format

The Drizzle Kit config lives in `apps/api/` (alongside `wrangler.jsonc`). It points to the shared schema in `packages/core`:

```typescript
// apps/api/drizzle.config.ts
import type { Config } from 'drizzle-kit'

export default {
  schema: '../../packages/core/src/schema/index.ts',
  out: '../../packages/core/src/schema/migrations',
  dialect: 'postgresql',
} satisfies Config
```

### Worker Bindings — `DATABASE_URL`

Cloudflare Workers receive secrets/vars via `env`, not `process.env`. The `wrangler.jsonc` vars section should have a placeholder:

```jsonc
{
  // ... existing config ...
  "vars": {
    "DATABASE_URL": "postgresql://placeholder"
  }
}
```

The real connection string is set in the Cloudflare dashboard (not committed to repo). The `CloudflareBindings` TypeScript interface (generated by `wrangler cf-typegen`) will include `DATABASE_URL: string` once the var is declared.

### File Structure — What to Create

This story establishes these files (architecture-defined locations):

```
apps/api/
├── drizzle.config.ts               # NEW — Drizzle Kit config
├── src/
│   ├── index.ts                    # MODIFY — switch to OpenAPIHono, remove hello-world
│   ├── routes/
│   │   └── health.ts               # NEW — GET /v1/health (first typed route)
│   ├── middleware/
│   │   └── cors.ts                 # NEW — scoped CORS (admin + payment endpoints only)
│   ├── db/
│   │   └── index.ts                # NEW — createDb() factory
│   └── lib/
│       ├── response.ts             # NEW — ok(), list(), err() envelope helpers
│       └── errors.ts               # NEW — AppError + typed subclasses

packages/core/
└── src/
    ├── index.ts                    # MODIFY — export from schema, types, constants
    ├── schema/
    │   ├── index.ts                # NEW — empty export (tables added per-story)
    │   └── migrations/             # NEW — empty dir (.gitkeep)
    ├── types/
    │   ├── api.ts                  # NEW — DataResponse<T>, ListResponse<T>, ErrorResponse
    │   └── index.ts                # NEW — re-exports
    └── constants/
        └── index.ts                # NEW — placeholder export
```

### Previous Story Context (Stories 1.1 & 1.2)

**Critical — wrangler.jsonc not wrangler.toml:**
Architecture docs reference `wrangler.toml` but all actual files are `wrangler.jsonc`. Use JSONC throughout. The `$schema` path must be `../../node_modules/wrangler/config-schema.json` (hoisted).

**pnpm workspace package names:**
- `@ontask/api` → `apps/api/`
- `@ontask/mcp` → `apps/mcp/`
- `@ontask/core` → `packages/core/`
- `@ontask/scheduling` → `packages/scheduling/`
- `@ontask/ai` → `packages/ai/`

**tsconfig tension (deferred in 1.1):**
`tsconfig.base.json` uses `module: NodeNext` / `moduleResolution: NodeNext`. `apps/api/tsconfig.json` overrides to `ESNext` / `Bundler`. `packages/core` inherits NodeNext from base. This is pre-existing — do NOT change tsconfig resolution; work within existing configs.

**`pnpm -r typecheck` notes:**
As of Story 1.2 fix: `pnpm -r typecheck` uses `--if-present` so packages without a `typecheck` script are silently skipped. `packages/core` already has `"typecheck": "tsc --noEmit"` in its package.json — it WILL be checked.

**Native builds:**
`onlyBuiltDependencies` in `pnpm-workspace.yaml` already allows `esbuild`, `sharp`, `workerd`. No additional `pnpm approve-builds` required for Drizzle/Neon packages.

### Scope Boundaries — What Is NOT In This Story

| Item | Belongs To |
|---|---|
| Actual DB tables (users, tasks, etc.) | Story that first uses them |
| Migration runner in CI | Future story (after first table is created) |
| Auth middleware | Story 1.8 |
| Rate limit middleware | Story when first needed |
| MCP worker database setup | Story that first uses it in MCP context |
| Integration tests against Neon | Future (needs schema first) |
| Real `DATABASE_URL` Cloudflare secret | Ops task, not a dev task |

### References

- [Source: architecture.md — Database Driver] — `@neondatabase/serverless` HTTP transport, drizzle `casing: 'camelCase'`
- [Source: architecture.md — API Response Format] — envelope shapes, HTTP status codes, rules
- [Source: architecture.md — Naming Conventions] — DB naming, API naming, TS naming
- [Source: architecture.md — `packages/core/` structure] — schema file layout
- [Source: architecture.md — `apps/api/` structure] — db/, lib/response.ts, lib/errors.ts, middleware/cors.ts
- [Source: architecture.md — CORS] — scoped to /admin/v1/* and payment only
- [Source: epics.md — Story 1.3] — acceptance criteria
- [Source: story 1-2-cicd-pipeline-staging-environments.md — Dev Notes] — wrangler.jsonc format, pnpm workspace names, tsconfig tension

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No blocking issues. One note: `drizzle.config.ts` at `apps/api/` root was excluded from the API `tsconfig.json` (added to `exclude` array) because `drizzle-kit` is installed in `packages/core`, not `apps/api`. The config file is consumed only by the `drizzle-kit` CLI, not by the Worker bundle, so excluding it from typecheck is correct. `@ontask/core` was added as a workspace dependency to `apps/api` to enable the import of shared types in `response.ts`.

### Completion Notes List

- Installed `@neondatabase/serverless`, `drizzle-orm` in both `packages/core` and `apps/api`; `drizzle-kit` as devDep in `packages/core` only.
- `createDb()` factory uses `drizzle-orm/neon-http` (HTTP transport) with `{ casing: 'camelCase' }` — matches AC 1 exactly.
- `drizzle.config.ts` placed in `apps/api/` root, excluded from API tsconfig (CLI-only file).
- `packages/core` schema structure established: empty `schema/index.ts`, `schema/migrations/.gitkeep`, `types/api.ts` with `DataResponse<T>`, `ListResponse<T>`, `ErrorResponse`, `constants/index.ts`.
- `packages/core/src/index.ts` re-exports from schema, types, and constants.
- `apps/api/src/index.ts` refactored to `OpenAPIHono`; OpenAPI JSON spec at `/v1/doc`; hello-world stub removed.
- Response envelope helpers `ok()`, `list()`, `err()` in `apps/api/src/lib/response.ts`.
- `AppError` and 6 typed subclasses in `apps/api/src/lib/errors.ts`.
- Scoped CORS in `apps/api/src/middleware/cors.ts`: `/admin/v1/*` + `/v1/payment-setup/*` only; explicitly NOT global.
- Typed health-check `GET /v1/health` using `createRoute` + `app.openapi()` — first fully typed route.
- `pnpm -r typecheck` passes with no errors across all workspace packages.
- `worker-configuration.d.ts` generated via `wrangler cf-typegen` to provide `CloudflareBindings` type with `DATABASE_URL`.

### File List

- `apps/api/drizzle.config.ts` (new)
- `apps/api/package.json` (modified — added dependencies + typecheck script)
- `apps/api/tsconfig.json` (modified — exclude drizzle.config.ts)
- `apps/api/wrangler.jsonc` (modified — added DATABASE_URL vars)
- `apps/api/worker-configuration.d.ts` (generated — CloudflareBindings with DATABASE_URL)
- `apps/api/src/index.ts` (modified — OpenAPIHono, scoped CORS, health route, /v1/doc)
- `apps/api/src/db/index.ts` (new)
- `apps/api/src/lib/response.ts` (new)
- `apps/api/src/lib/errors.ts` (new)
- `apps/api/src/middleware/cors.ts` (new)
- `apps/api/src/routes/health.ts` (new)
- `packages/core/package.json` (modified — added @neondatabase/serverless, drizzle-orm, drizzle-kit)
- `packages/core/src/index.ts` (modified — re-exports schema, types, constants)
- `packages/core/src/schema/index.ts` (new)
- `packages/core/src/schema/migrations/.gitkeep` (new)
- `packages/core/src/types/api.ts` (new)
- `packages/core/src/types/index.ts` (new)
- `packages/core/src/constants/index.ts` (new)

## Change Log

- 2026-03-30: Story 1.3 implemented — DB layer (Neon HTTP transport, drizzle camelCase), core schema structure, response envelopes, typed errors, scoped CORS, OpenAPIHono wiring, typed health-check route. All typechecks pass.
