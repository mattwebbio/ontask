import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok } from '../lib/response.js'
// TODO(impl): import { createDb } from '../db/index.js'
// TODO(impl): import { liveActivityTokensTable } from '@ontask/core'
// TODO(impl): import { eq, and } from 'drizzle-orm'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schemas ───────────────────────────────────────────────────────────────────

const RegisterLiveActivityTokenRequestSchema = z.object({
  taskId: z.string().uuid().nullable(),             // null for non-task activities
  activityType: z.enum(['task_timer', 'commitment_countdown', 'watch_mode']),
  pushToken: z.string().min(1),                     // ActivityKit push token
  expiresAt: z.string().datetime(),                 // ISO timestamp — max 8h from now
})
const RegisterLiveActivityTokenResponseSchema = z.object({
  data: z.object({ registered: z.boolean() }),
})
const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/live-activities/token ────────────────────────────────────────────
// Upserts an ActivityKit push token for the authenticated user.
// Called automatically by the Flutter live_activities plugin when an activity starts
// and on token refresh (background push token updates — ARCH-28).
// Upserts on (userId, taskId, activityType) — safe to call on every activity start.

const registerLiveActivityTokenRoute = createRoute({
  method: 'post',
  path: '/v1/live-activities/token',
  tags: ['Live Activities'],
  summary: 'Register ActivityKit push token',
  description:
    'Upserts an ActivityKit push token for the authenticated user. ' +
    'activityType: task_timer | commitment_countdown | watch_mode. ' +
    'taskId is null for watch_mode activities without an associated task. ' +
    'Upserts on (userId, taskId, activityType) — safe to call on every activity start or token refresh.',
  request: {
    body: {
      content: {
        'application/json': { schema: RegisterLiveActivityTokenRequestSchema },
      },
    },
  },
  responses: {
    200: {
      content: {
        'application/json': { schema: RegisterLiveActivityTokenResponseSchema },
      },
      description: 'Token registered',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid request body',
    },
  },
})

app.openapi(registerLiveActivityTokenRoute, async (c) => {
  const body = c.req.valid('json')
  const { taskId, activityType, pushToken, expiresAt } = body

  const databaseUrl = c.env?.DATABASE_URL
  if (databaseUrl) {
    // TODO(impl): const db = createDb(databaseUrl)
    // TODO(impl): const userId = c.get('jwtPayload').sub
    // TODO(impl): await db
    //   .insert(liveActivityTokensTable)
    //   .values({ userId, taskId: taskId ?? null, activityType, pushToken, expiresAt: new Date(expiresAt) })
    //   .onConflictDoUpdate({
    //     target: [liveActivityTokensTable.userId, liveActivityTokensTable.taskId, liveActivityTokensTable.activityType],
    //     set: { pushToken, createdAt: new Date(), expiresAt: new Date(expiresAt) },
    //   })
  }
  // Stub: return registered: true regardless of DB availability.
  // TODO(impl): Replace stub with real DB upsert when DATABASE_URL available.
  void taskId; void activityType; void pushToken; void expiresAt
  return c.json(ok({ registered: true }))
})

export { app as liveActivitiesRouter }
