import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'

// ── Lists router ────────────────────────────────────────────────────────────
// CRUD routes for list management (FR15-21, FR62, FR75).
// Stub responses with TODO(impl) markers for real Drizzle implementation.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const createListSchema = z.object({
  title: z.string().min(1).openapi({ example: 'Work tasks' }),
  defaultDueDate: z.string().datetime().nullable().optional().openapi({
    example: '2026-04-01T09:00:00.000Z',
    description: 'Default due date inherited by tasks created in this list (FR3).',
  }),
})

const updateListSchema = z.object({
  title: z.string().min(1).optional(),
  defaultDueDate: z.string().datetime().nullable().optional(),
})

const listSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  title: z.string(),
  defaultDueDate: z.string().datetime().nullable(),
  position: z.number().int(),
  archivedAt: z.string().datetime().nullable(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
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

const ListResponseSchema = z.object({ data: listSchema })
const ListWithSectionsResponseSchema = z.object({
  data: listSchema.extend({ sections: z.array(sectionSchema) }),
})

const ListListResponseSchema = z.object({
  data: z.array(listSchema),
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

function stubList(overrides: Partial<z.infer<typeof listSchema>> = {}): z.infer<typeof listSchema> {
  return {
    id: 'b0000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-a000-000000000001',
    title: 'Work tasks',
    defaultDueDate: null,
    position: 0,
    archivedAt: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  }
}

// ── POST /v1/lists ──────────────────────────────────────────────────────────

const postListRoute = createRoute({
  method: 'post',
  path: '/v1/lists',
  tags: ['Lists'],
  summary: 'Create a new list',
  request: {
    body: { content: { 'application/json': { schema: createListSchema } }, required: true },
  },
  responses: {
    201: { content: { 'application/json': { schema: ListResponseSchema } }, description: 'List created' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(postListRoute, async (c) => {
  // TODO(impl): insert via Drizzle, assign userId from JWT
  const body = c.req.valid('json')
  return c.json(
    ok(stubList({
      title: body.title,
      defaultDueDate: body.defaultDueDate ?? null,
    })),
    201,
  )
})

// ── GET /v1/lists ───────────────────────────────────────────────────────────

const getListsRoute = createRoute({
  method: 'get',
  path: '/v1/lists',
  tags: ['Lists'],
  summary: 'Get all lists for the current user',
  request: {
    query: z.object({
      cursor: z.string().optional(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: ListListResponseSchema } }, description: 'Lists' },
  },
})

app.openapi(getListsRoute, async (c) => {
  // TODO(impl): filter by userId from JWT, cursor-based pagination
  return c.json(list([stubList()], null, false), 200)
})

// ── GET /v1/lists/:id/prediction ────────────────────────────────────────────
// IMPORTANT: This nested resource route MUST be registered BEFORE /v1/lists/{id} —
// Hono matches routes in registration order.

const listPredictionSchema = z.object({
  listId: z.string().uuid(),
  predictedDate: z.string().datetime().nullable(),
  status: z.enum(['on_track', 'at_risk', 'behind', 'unknown']),
  tasksRemaining: z.number().int(),
  estimatedMinutesRemaining: z.number().int(),
  availableWindowsCount: z.number().int(),
  reasoning: z.string(),
})

const ListPredictionResponseSchema = z.object({ data: listPredictionSchema })

const getListPredictionRoute = createRoute({
  method: 'get',
  path: '/v1/lists/{id}/prediction',
  tags: ['Lists'],
  summary: 'Get predicted completion for a list',
  description:
    'Returns predicted completion date, status, and reasoning for all tasks in a list. ' +
    'Stub returns plausible static data; real implementation comes in Epic 3.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: ListPredictionResponseSchema } }, description: 'List prediction' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'List not found' },
  },
})

app.openapi(getListPredictionRoute, async (c) => {
  // TODO(impl): real prediction from scheduling engine (Epic 3)
  const { id } = c.req.valid('param')
  const predictedDate = new Date()
  predictedDate.setUTCDate(predictedDate.getUTCDate() + 14)
  return c.json(
    ok({
      listId: id,
      predictedDate: predictedDate.toISOString(),
      status: 'at_risk' as const,
      tasksRemaining: 12,
      estimatedMinutesRemaining: 420,
      availableWindowsCount: 8,
      reasoning: 'Some tasks in this list may be tight given current available time windows.',
    }),
    200,
  )
})

// ── GET /v1/lists/:id ───────────────────────────────────────────────────────

const getListRoute = createRoute({
  method: 'get',
  path: '/v1/lists/{id}',
  tags: ['Lists'],
  summary: 'Get a single list with its sections',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: ListWithSectionsResponseSchema } }, description: 'List found' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'List not found' },
  },
})

app.openapi(getListRoute, async (c) => {
  // TODO(impl): verify ownership, include sections
  const { id } = c.req.valid('param')
  return c.json(ok({ ...stubList({ id }), sections: [] }), 200)
})

// ── PATCH /v1/lists/:id ─────────────────────────────────────────────────────

const patchListRoute = createRoute({
  method: 'patch',
  path: '/v1/lists/{id}',
  tags: ['Lists'],
  summary: 'Update list properties',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: updateListSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: ListResponseSchema } }, description: 'List updated' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'List not found' },
  },
})

app.openapi(patchListRoute, async (c) => {
  // TODO(impl): upsert via Drizzle, validate ownership
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')
  return c.json(ok(stubList({ id, ...body, defaultDueDate: body.defaultDueDate ?? null })), 200)
})

// ── DELETE /v1/lists/:id/archive ────────────────────────────────────────────

const archiveListRoute = createRoute({
  method: 'delete',
  path: '/v1/lists/{id}/archive',
  tags: ['Lists'],
  summary: 'Archive a list (soft delete)',
  description: 'Sets archivedAt, cascade archive to tasks.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'List archived' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'List not found' },
  },
})

app.openapi(archiveListRoute, async (c) => {
  // TODO(impl): set archivedAt, cascade archive to tasks
  return new Response(null, { status: 204 })
})

export { app as listsRouter }
