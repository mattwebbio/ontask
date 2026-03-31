import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'
import { runScheduleForUser } from '../services/scheduling.js'

// ── Scheduling router ────────────────────────────────────────────────────────
// Routes for triggering the scheduling engine (FR44).

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const ScheduledBlockSchema = z.object({
  taskId: z.string().openapi({ example: 'a0000000-0000-4000-8000-000000000001' }),
  startTime: z.string().datetime().openapi({ example: '2026-04-01T09:00:00.000Z' }),
  endTime: z.string().datetime().openapi({ example: '2026-04-01T09:30:00.000Z' }),
  isLocked: z.boolean().openapi({ example: false }),
  isAtRisk: z.boolean().openapi({ example: false }),
})

const ScheduleResponseSchema = z.object({
  data: ScheduledBlockSchema,
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/tasks/:id/schedule ──────────────────────────────────────────────

const postTaskScheduleRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{id}/schedule',
  tags: ['Scheduling'],
  summary: 'Trigger scheduling engine for a task',
  description:
    'Runs the auto-scheduling engine for the task owner\'s full schedule and returns ' +
    'the resulting scheduled block for the requested task (FR44). ' +
    'Returns 404 if the task is not present in the schedule output.',
  request: {
    params: z.object({
      id: z.string().openapi({ example: 'a0000000-0000-4000-8000-000000000001' }),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ScheduleResponseSchema } },
      description: 'Scheduled block for the requested task',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Task not found in schedule output',
    },
  },
})

app.openapi(postTaskScheduleRoute, async (c) => {
  // Auth middleware stub: extract userId from x-user-id header (consistent with other routes)
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  const { id: taskId } = c.req.valid('param')

  const scheduleOutput = await runScheduleForUser(userId, c.env)

  const block = scheduleOutput.scheduledBlocks.find((b) => b.taskId === taskId)

  if (!block) {
    return c.json(err('NOT_FOUND', `Task ${taskId} was not scheduled`), 404)
  }

  return c.json(
    ok({
      taskId: block.taskId,
      startTime: block.startTime.toISOString(),
      endTime: block.endTime.toISOString(),
      isLocked: block.isLocked,
      isAtRisk: block.isAtRisk,
    }),
    200,
  )
})

export const schedulingRouter = app
