import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok } from '../lib/response.js'

// ── Bulk Operations router ────────────────────────────────────────────────
// Bulk task operations: reschedule, complete, delete (FR74).
// Uses dedicated /v1/tasks/bulk/{operation} paths.
// Response uses partial-success model: succeeded[] + failed[].

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const bulkRescheduleSchema = z.object({
  taskIds: z.array(z.string().uuid()).min(1).openapi({
    example: ['a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002'],
  }),
  dueDate: z.string().datetime().openapi({
    example: '2026-04-15T09:00:00.000Z',
    description: 'New due date to apply to all selected tasks',
  }),
})

const bulkCompleteSchema = z.object({
  taskIds: z.array(z.string().uuid()).min(1).openapi({
    example: ['a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002'],
  }),
})

const bulkDeleteSchema = z.object({
  taskIds: z.array(z.string().uuid()).min(1).openapi({
    example: ['a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002'],
  }),
})

const bulkResultSchema = z.object({
  data: z.object({
    succeeded: z.array(z.string().uuid()),
    failed: z.array(z.object({
      id: z.string().uuid(),
      error: z.string(),
    })),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/tasks/bulk/reschedule ──────────────────────────────────────────

const bulkRescheduleRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/bulk/reschedule',
  tags: ['Bulk Operations'],
  summary: 'Reschedule multiple tasks to a new due date',
  request: {
    body: { content: { 'application/json': { schema: bulkRescheduleSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: bulkResultSchema } }, description: 'Bulk reschedule result' },
  },
})

app.openapi(bulkRescheduleRoute, async (c) => {
  const body = c.req.valid('json')
  // TODO(impl): update dueDate for each task via Drizzle
  return c.json(
    ok({
      succeeded: body.taskIds,
      failed: [] as { id: string; error: string }[],
    }),
    200,
  )
})

// ── POST /v1/tasks/bulk/complete ────────────────────────────────────────────

const bulkCompleteRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/bulk/complete',
  tags: ['Bulk Operations'],
  summary: 'Mark multiple tasks as completed',
  request: {
    body: { content: { 'application/json': { schema: bulkCompleteSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: bulkResultSchema } }, description: 'Bulk complete result' },
  },
})

app.openapi(bulkCompleteRoute, async (c) => {
  const body = c.req.valid('json')
  // TODO(impl): set completedAt = now() for each task via Drizzle
  return c.json(
    ok({
      succeeded: body.taskIds,
      failed: [] as { id: string; error: string }[],
    }),
    200,
  )
})

// ── POST /v1/tasks/bulk/delete ──────────────────────────────────────────────

const bulkDeleteRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/bulk/delete',
  tags: ['Bulk Operations'],
  summary: 'Archive multiple tasks (soft delete per FR59)',
  description: 'Sets archivedAt = now() for all specified tasks. Soft delete only — no hard deletes.',
  request: {
    body: { content: { 'application/json': { schema: bulkDeleteSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: bulkResultSchema } }, description: 'Bulk delete result' },
  },
})

app.openapi(bulkDeleteRoute, async (c) => {
  const body = c.req.valid('json')
  // TODO(impl): set archivedAt = now() for each task via Drizzle (FR59 soft delete)
  return c.json(
    ok({
      succeeded: body.taskIds,
      failed: [] as { id: string; error: string }[],
    }),
    200,
  )
})

export { app as bulkOperationsRouter }
