import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'

// ── Sections router ─────────────────────────────────────────────────────────
// CRUD routes for section management (FR2, FR3 section-level).
// Stub responses with TODO(impl) markers for real Drizzle implementation.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const createSectionSchema = z.object({
  title: z.string().min(1).openapi({ example: 'Sprint backlog' }),
  listId: z.string().uuid(),
  parentSectionId: z.string().uuid().nullable().optional(),
  defaultDueDate: z.string().datetime().nullable().optional(),
})

const updateSectionSchema = z.object({
  title: z.string().min(1).optional(),
  defaultDueDate: z.string().datetime().nullable().optional(),
})

const sectionSchema = z.object({
  id: z.string().uuid(),
  listId: z.string().uuid(),
  parentSectionId: z.string().uuid().nullable(),
  title: z.string(),
  defaultDueDate: z.string().datetime().nullable(),
  position: z.number().int(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

const SectionResponseSchema = z.object({ data: sectionSchema })

const SectionListResponseSchema = z.object({
  data: z.array(sectionSchema),
  pagination: z.object({
    cursor: z.string().nullable(),
    hasMore: z.boolean(),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── Stub fixtures ───────────────────────────────────────────────────────────

const now = '2026-03-30T12:00:00.000Z'

function stubSection(overrides: Partial<z.infer<typeof sectionSchema>> = {}): z.infer<typeof sectionSchema> {
  return {
    id: 'c0000000-0000-4000-8000-000000000001',
    listId: 'b0000000-0000-4000-8000-000000000001',
    parentSectionId: null,
    title: 'Sprint backlog',
    defaultDueDate: null,
    position: 0,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  }
}

// ── POST /v1/sections ───────────────────────────────────────────────────────

const postSectionRoute = createRoute({
  method: 'post',
  path: '/v1/sections',
  tags: ['Sections'],
  summary: 'Create a new section',
  request: {
    body: { content: { 'application/json': { schema: createSectionSchema } }, required: true },
  },
  responses: {
    201: { content: { 'application/json': { schema: SectionResponseSchema } }, description: 'Section created' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(postSectionRoute, async (c) => {
  // TODO(impl): validate listId exists, insert via Drizzle
  const body = c.req.valid('json')
  return c.json(
    ok(stubSection({
      title: body.title,
      listId: body.listId,
      parentSectionId: body.parentSectionId ?? null,
      defaultDueDate: body.defaultDueDate ?? null,
    })),
    201,
  )
})

// ── GET /v1/sections ────────────────────────────────────────────────────────

const getSectionsRoute = createRoute({
  method: 'get',
  path: '/v1/sections',
  tags: ['Sections'],
  summary: 'Get sections for a given list',
  request: {
    query: z.object({
      listId: z.string().uuid(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: SectionListResponseSchema } }, description: 'Sections list' },
  },
})

app.openapi(getSectionsRoute, async (c) => {
  // TODO(impl): filter by listId, verify list ownership
  const { listId } = c.req.valid('query')
  return c.json(list([stubSection({ listId })], null, false), 200)
})

// ── PATCH /v1/sections/:id ──────────────────────────────────────────────────

const patchSectionRoute = createRoute({
  method: 'patch',
  path: '/v1/sections/{id}',
  tags: ['Sections'],
  summary: 'Update section properties',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: updateSectionSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: SectionResponseSchema } }, description: 'Section updated' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Section not found' },
  },
})

app.openapi(patchSectionRoute, async (c) => {
  // TODO(impl): upsert via Drizzle, validate ownership
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')
  return c.json(ok(stubSection({ id, ...body, defaultDueDate: body.defaultDueDate ?? null })), 200)
})

// ── DELETE /v1/sections/:id ─────────────────────────────────────────────────

const deleteSectionRoute = createRoute({
  method: 'delete',
  path: '/v1/sections/{id}',
  tags: ['Sections'],
  summary: 'Delete a section',
  description: 'Cascade delete/archive tasks in section.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'Section deleted' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Section not found' },
  },
})

app.openapi(deleteSectionRoute, async (c) => {
  // TODO(impl): cascade delete/archive tasks in section
  return new Response(null, { status: 204 })
})

export { app as sectionsRouter }
