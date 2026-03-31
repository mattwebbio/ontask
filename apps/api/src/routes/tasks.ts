import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'

// ── Tasks router ────────────────────────────────────────────────────────────
// CRUD routes for task management (FR1, FR55, FR57, FR58, FR59).
// All routes return stub responses with TODO(impl) markers for real Drizzle
// implementation once auth middleware and database are wired.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const createTaskSchema = z.object({
  title: z.string().min(1).openapi({ example: 'Buy groceries' }),
  notes: z.string().nullable().optional().openapi({ example: 'Milk, eggs, bread' }),
  dueDate: z.string().datetime().nullable().optional().openapi({
    example: '2026-04-01T09:00:00.000Z',
    description: 'If null, due date is inherited from section/list default (FR3).',
  }),
  listId: z.string().uuid().nullable().optional(),
  sectionId: z.string().uuid().nullable().optional(),
  parentTaskId: z.string().uuid().nullable().optional(),
  timeWindow: z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable().optional(),
  timeWindowStart: z.string().nullable().optional().openapi({
    example: '09:00',
    description: 'HH:mm format. Only used when timeWindow = "custom".',
  }),
  timeWindowEnd: z.string().nullable().optional().openapi({
    example: '11:00',
    description: 'HH:mm format. Only used when timeWindow = "custom".',
  }),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional(),
  priority: z.enum(['normal', 'high', 'critical']).nullable().optional(),
})

const updateTaskSchema = z.object({
  title: z.string().min(1).optional(),
  notes: z.string().nullable().optional(),
  dueDate: z.string().datetime().nullable().optional(),
  listId: z.string().uuid().nullable().optional(),
  sectionId: z.string().uuid().nullable().optional(),
  parentTaskId: z.string().uuid().nullable().optional(),
  position: z.number().int().optional(),
  timeWindow: z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable().optional(),
  timeWindowStart: z.string().nullable().optional(),
  timeWindowEnd: z.string().nullable().optional(),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional(),
  priority: z.enum(['normal', 'high', 'critical']).nullable().optional(),
})

const taskSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  listId: z.string().uuid().nullable(),
  sectionId: z.string().uuid().nullable(),
  parentTaskId: z.string().uuid().nullable(),
  title: z.string(),
  notes: z.string().nullable(),
  dueDate: z.string().datetime().nullable(),
  position: z.number().int(),
  timeWindow: z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable(),
  timeWindowStart: z.string().nullable(),
  timeWindowEnd: z.string().nullable(),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable(),
  priority: z.enum(['normal', 'high', 'critical']).nullable(),
  archivedAt: z.string().datetime().nullable(),
  completedAt: z.string().datetime().nullable(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

const TaskResponseSchema = z.object({ data: taskSchema })

const TaskListResponseSchema = z.object({
  data: z.array(taskSchema),
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

function stubTask(overrides: Partial<z.infer<typeof taskSchema>> = {}): z.infer<typeof taskSchema> {
  return {
    id: 'a0000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-a000-000000000001',
    listId: null,
    sectionId: null,
    parentTaskId: null,
    title: 'Buy groceries',
    notes: null,
    dueDate: null,
    position: 0,
    timeWindow: null,
    timeWindowStart: null,
    timeWindowEnd: null,
    energyRequirement: null,
    priority: 'normal',
    archivedAt: null,
    completedAt: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  }
}

// ── POST /v1/tasks ──────────────────────────────────────────────────────────

const postTaskRoute = createRoute({
  method: 'post',
  path: '/v1/tasks',
  tags: ['Tasks'],
  summary: 'Create a new task',
  description:
    'Creates a task with title (required), notes, dueDate, listId, sectionId, parentTaskId. ' +
    'If dueDate is null, server applies due date inheritance (FR3): ' +
    'section defaultDueDate > list defaultDueDate.',
  request: {
    body: { content: { 'application/json': { schema: createTaskSchema } }, required: true },
  },
  responses: {
    201: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task created' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(postTaskRoute, async (c) => {
  // TODO(impl): validate listId/sectionId exist, inherit defaultDueDate from section/list
  // if no dueDate provided (FR3), insert via Drizzle
  const body = c.req.valid('json')
  return c.json(
    ok(stubTask({
      title: body.title,
      notes: body.notes ?? null,
      dueDate: body.dueDate ?? null,
      listId: body.listId ?? null,
      sectionId: body.sectionId ?? null,
      parentTaskId: body.parentTaskId ?? null,
      timeWindow: body.timeWindow ?? null,
      timeWindowStart: body.timeWindowStart ?? null,
      timeWindowEnd: body.timeWindowEnd ?? null,
      energyRequirement: body.energyRequirement ?? null,
      priority: body.priority ?? 'normal',
    })),
    201,
  )
})

// ── GET /v1/tasks ───────────────────────────────────────────────────────────

const getTasksRoute = createRoute({
  method: 'get',
  path: '/v1/tasks',
  tags: ['Tasks'],
  summary: 'Get all tasks for the current user',
  description: 'Returns tasks with cursor-based pagination. Supports filtering by listId, sectionId, archived status.',
  request: {
    query: z.object({
      listId: z.string().uuid().optional(),
      sectionId: z.string().uuid().optional(),
      archived: z.coerce.boolean().optional(),
      cursor: z.string().optional(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskListResponseSchema } }, description: 'Tasks list' },
  },
})

app.openapi(getTasksRoute, async (c) => {
  // TODO(impl): filter by userId from JWT, apply list/section/archive filters, cursor-based pagination
  return c.json(list([stubTask()], null, false), 200)
})

// ── GET /v1/tasks/:id ───────────────────────────────────────────────────────

const getTaskRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/{id}',
  tags: ['Tasks'],
  summary: 'Get a single task',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task found' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(getTaskRoute, async (c) => {
  // TODO(impl): verify ownership via userId
  const { id } = c.req.valid('param')
  return c.json(ok(stubTask({ id })), 200)
})

// ── PATCH /v1/tasks/:id ─────────────────────────────────────────────────────

const patchTaskRoute = createRoute({
  method: 'patch',
  path: '/v1/tasks/{id}',
  tags: ['Tasks'],
  summary: 'Update task properties',
  description: 'Accepts partial update of title, notes, dueDate, listId, sectionId, parentTaskId, position.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: updateTaskSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task updated' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(patchTaskRoute, async (c) => {
  // TODO(impl): upsert via Drizzle, validate ownership
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')
  return c.json(ok(stubTask({ id, ...body, dueDate: body.dueDate ?? null })), 200)
})

// ── DELETE /v1/tasks/:id/archive ────────────────────────────────────────────

const archiveTaskRoute = createRoute({
  method: 'delete',
  path: '/v1/tasks/{id}/archive',
  tags: ['Tasks'],
  summary: 'Archive a task (soft delete — FR59)',
  description: 'Sets archivedAt = now(). NOT a hard delete — archive only per FR59.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'Task archived' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(archiveTaskRoute, async (c) => {
  // TODO(impl): set archivedAt = now() via Drizzle
  return new Response(null, { status: 204 })
})

// ── PATCH /v1/tasks/:id/reorder ─────────────────────────────────────────────

const reorderTaskRoute = createRoute({
  method: 'patch',
  path: '/v1/tasks/{id}/reorder',
  tags: ['Tasks'],
  summary: 'Reorder a task',
  description: 'Updates position, shifts sibling positions.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: {
      content: {
        'application/json': {
          schema: z.object({ position: z.number().int() }),
        },
      },
      required: true,
    },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task reordered' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(reorderTaskRoute, async (c) => {
  // TODO(impl): update position, shift sibling positions
  const { id } = c.req.valid('param')
  const { position } = c.req.valid('json')
  return c.json(ok(stubTask({ id, position })), 200)
})

export { app as tasksRouter }
