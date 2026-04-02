import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok } from '../lib/response.js'

// ── Notifications router ──────────────────────────────────────────────────────
// Device token registration and notification preference management.
// (Epic 8, Story 8.1, FR42-43, FR72)
// APNs push delivery service: apps/api/src/services/push.ts
// Stub endpoints — real DB writes deferred to Story 8.2 integration.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schemas ───────────────────────────────────────────────────────────────────

const RegisterDeviceTokenRequestSchema = z.object({
  token: z.string().min(1),                                         // APNs device token hex string
  platform: z.enum(['ios', 'macos']),
  environment: z.enum(['development', 'production']),              // debug=development; TestFlight/AppStore=production
})
const RegisterDeviceTokenResponseSchema = z.object({
  data: z.object({ registered: z.boolean() }),
})
const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

const NotificationPreferenceSchema = z.object({
  scope: z.enum(['global', 'device', 'task']),
  deviceId: z.string().nullable(),
  taskId: z.string().nullable(),
  enabled: z.boolean(),
})
const NotificationPreferenceResponseSchema = z.object({ data: NotificationPreferenceSchema })
const NotificationPreferencesListResponseSchema = z.object({
  data: z.array(NotificationPreferenceSchema),
})

// ── POST /v1/notifications/device-token ───────────────────────────────────────

const registerDeviceTokenRoute = createRoute({
  method: 'post',
  path: '/v1/notifications/device-token',
  tags: ['Notifications'],
  summary: 'Register device push token',
  description:
    'Upserts an APNs device token for the authenticated user. ' +
    'platform: ios | macos. ' +
    'environment: development (debug builds) | production (TestFlight + App Store, DEPLOY-4). ' +
    'Upserts on (userId, token) — safe to call on every app launch. ' +
    'Stub implementation (Story 8.1) — real DB upsert deferred.',
  request: {
    body: { content: { 'application/json': { schema: RegisterDeviceTokenRequestSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: RegisterDeviceTokenResponseSchema } },
      description: 'Token registered',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid token or platform',
    },
  },
})

app.openapi(registerDeviceTokenRoute, async (c) => {
  const { token, platform, environment } = c.req.valid('json')
  // TODO(impl): db = getDb(c.env.DATABASE_URL)
  // TODO(impl): await db.insert(deviceTokensTable)
  //   .values({ userId: jwtUserId, token, platform, environment, updatedAt: new Date() })
  //   .onConflictDoUpdate({
  //     target: [deviceTokensTable.userId, deviceTokensTable.token],
  //     set: { environment, updatedAt: new Date() },
  //   })
  void token
  void platform
  void environment
  return c.json(ok({ registered: true }))
})

// ── GET /v1/notifications/preferences ────────────────────────────────────────

const getPreferencesRoute = createRoute({
  method: 'get',
  path: '/v1/notifications/preferences',
  tags: ['Notifications'],
  summary: 'Get notification preferences',
  description:
    'Returns all notification preferences for the authenticated user. ' +
    'Stub implementation (Story 8.1) — real impl queries notification_preferences WHERE userId = jwtUserId.',
  responses: {
    200: {
      content: { 'application/json': { schema: NotificationPreferencesListResponseSchema } },
      description: 'List of notification preferences',
    },
  },
})

app.openapi(getPreferencesRoute, async (c) => {
  // TODO(impl): db = getDb(c.env.DATABASE_URL)
  // TODO(impl): SELECT * FROM notification_preferences WHERE userId = jwtUserId
  return c.json({ data: [] })
})

// ── PUT /v1/notifications/preferences ────────────────────────────────────────

const putPreferencesRoute = createRoute({
  method: 'put',
  path: '/v1/notifications/preferences',
  tags: ['Notifications'],
  summary: 'Set notification preference',
  description:
    'Upserts a notification preference at any of the three levels (FR43): ' +
    "scope='global' — all notifications on/off. " +
    "scope='device' — per-device preference (pass deviceId). " +
    "scope='task' — per-task preference (pass taskId). " +
    'Stub implementation (Story 8.1) — returns request body.',
  request: {
    body: { content: { 'application/json': { schema: NotificationPreferenceSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: NotificationPreferenceResponseSchema } },
      description: 'Preference updated',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid preference',
    },
  },
})

app.openapi(putPreferencesRoute, async (c) => {
  const body = c.req.valid('json')
  // TODO(impl): UPSERT notification_preferences on (userId, scope, deviceId, taskId)
  // TODO(impl): db = getDb(c.env.DATABASE_URL)
  // TODO(impl): await db.insert(notificationPreferencesTable)
  //   .values({ userId: jwtUserId, ...body, updatedAt: new Date() })
  //   .onConflictDoUpdate({
  //     target: [notificationPreferencesTable.userId, notificationPreferencesTable.scope,
  //              notificationPreferencesTable.deviceId, notificationPreferencesTable.taskId],
  //     set: { enabled: body.enabled, updatedAt: new Date() },
  //   })
  return c.json(ok(body))
})

export { app as notificationsRouter }
