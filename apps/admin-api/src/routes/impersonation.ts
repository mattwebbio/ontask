import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'
import { getDb } from '../db/index.js'
import { operatorImpersonationLogsTable } from '@ontask/core'

// ── Operator impersonation router ─────────────────────────────────────────────
// Admin endpoints for starting/ending impersonation sessions and logging actions.
// Immutable audit trail for all impersonation activity (NFR-S6).
// (Epic 11, Story 11.4, FR53, NFR-S6)
//
// POST /admin/v1/users/:userId/impersonate              — start an impersonation session (AC: 1)
// POST /admin/v1/impersonation/:sessionId/end           — end an impersonation session (AC: 3)
// POST /admin/v1/impersonation/:sessionId/log-action    — log an action during impersonation (AC: 2)

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

const StartImpersonationResponseSchema = z.object({
  data: z.object({
    sessionId: z.string(),         // UUID for this impersonation session
    userId: z.string(),            // the user being impersonated
    operatorEmail: z.string(),     // echoed back for banner display
    userEmail: z.string(),         // TODO(impl): fetch from users table once queryable
    expiresAt: z.string(),         // ISO timestamp: now + 30 minutes
    startedAt: z.string(),         // ISO timestamp
  }),
})

const EndImpersonationRequestSchema = z.object({
  userId: z.string().uuid().optional(), // SPA passes impersonated userId from sessionStorage
  reason: z.enum(['operator_ended', 'session_timeout']).optional(),
})

const EndImpersonationResponseSchema = z.object({
  data: z.object({
    sessionId: z.string(),
    endedAt: z.string(),
    reason: z.enum(['operator_ended', 'session_timeout']),
  }),
})

const LogActionRequestSchema = z.object({
  userId: z.string(),                                    // user being impersonated in this session
  actionDetail: z.string().min(1, 'Action detail is required'),
  // TODO(impl): Once sessions table exists, look up userId from sessionId instead of requiring it in body.
})

const LogActionResponseSchema = z.object({
  data: z.object({
    logId: z.string(),
    sessionId: z.string(),
    loggedAt: z.string(),
  }),
})

// ── POST /admin/v1/users/:userId/impersonate ──────────────────────────────────
// Starts an impersonation session. Logs session_start to operator_impersonation_logs.
// The /admin/v1/users/* auth guard in index.ts covers this path.

const startImpersonationRoute = createRoute({
  method: 'post',
  path: '/admin/v1/users/{userId}/impersonate',
  tags: ['Impersonation'],
  summary: 'Start an impersonation session for a user',
  description:
    'Creates an impersonation session for the given userId. ' +
    'Logs a session_start entry to operator_impersonation_logs (NFR-S6). ' +
    'Returns sessionId, operatorEmail, expiresAt (now + 30 min). ' +
    '(AC: 1, FR53)',
  request: {
    params: z.object({ userId: z.string().min(1) }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: StartImpersonationResponseSchema } },
      description: 'Impersonation session started successfully',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Operator email not found in auth context',
    },
  },
})

app.openapi(startImpersonationRoute, async (c) => {
  const { userId } = c.req.valid('param')
  const databaseUrl = c.env?.DATABASE_URL

  const sessionId = crypto.randomUUID()
  const startedAt = new Date().toISOString()
  const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString()

  if (databaseUrl) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    if (!operatorEmail) {
      return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)
    }

    const db = getDb(databaseUrl)

    // TODO(impl): Fetch userEmail from users table WHERE id = :userId — return 404 USER_NOT_FOUND if missing
    // TODO(impl): Replace stub userEmail with real users table lookup

    // Insert session_start log entry (immutable audit log — NFR-S6)
    await db.insert(operatorImpersonationLogsTable).values({
      sessionId,
      userId,
      operatorEmail,
      actionType: 'session_start',
      actionDetail: null,
    })

    return c.json(ok({
      sessionId,
      userId,
      operatorEmail,
      userEmail: 'user@example.com', // TODO(impl): fetch from users table
      expiresAt,
      startedAt,
    }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — returns stub session data for UI development.
  // TODO(impl): Replace stub userEmail with real users table lookup
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const stubOperatorEmail = ((c as any).get('operatorEmail') as string | undefined) ?? 'operator@ontaskhq.com'
  return c.json(ok({
    sessionId,
    userId,
    operatorEmail: stubOperatorEmail,
    userEmail: 'user@example.com', // TODO(impl): fetch from users table
    expiresAt,
    startedAt,
  }))
})

// ── POST /admin/v1/impersonation/:sessionId/end ───────────────────────────────
// Ends an impersonation session. Logs session_end to operator_impersonation_logs.

const endImpersonationRoute = createRoute({
  method: 'post',
  path: '/admin/v1/impersonation/{sessionId}/end',
  tags: ['Impersonation'],
  summary: 'End an active impersonation session',
  description:
    'Logs a session_end entry to operator_impersonation_logs (NFR-S6). ' +
    'NOTE: No server-side session state in this story — sessionId is treated as opaque. ' +
    'TODO(impl): In a real implementation, maintain a sessions table to validate active sessions. ' +
    '(AC: 3, FR53)',
  request: {
    params: z.object({ sessionId: z.string().min(1) }),
    body: { content: { 'application/json': { schema: EndImpersonationRequestSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: EndImpersonationResponseSchema } },
      description: 'Impersonation session ended successfully',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Operator email not found in auth context',
    },
  },
})

app.openapi(endImpersonationRoute, async (c) => {
  const { sessionId } = c.req.valid('param')
  const body = c.req.valid('json')
  const impersonatedUserId = body?.userId
  const endReason = body?.reason ?? 'operator_ended'
  const databaseUrl = c.env?.DATABASE_URL

  const endedAt = new Date().toISOString()

  if (databaseUrl) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    if (!operatorEmail) {
      return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)
    }

    const db = getDb(databaseUrl)

    // TODO(impl): Validate that session is still active once sessions table exists
    await db.insert(operatorImpersonationLogsTable).values({
      sessionId,
      // SPA passes impersonatedUserId from sessionStorage; fall back to sessionId (valid UUID)
      // with a clear TODO so audit reviewers know the lookup is pending a sessions table
      userId: impersonatedUserId ?? sessionId, // TODO(impl): look up from sessions table
      operatorEmail,
      actionType: 'session_end',
      actionDetail: endReason,
    })

    return c.json(ok({
      sessionId,
      endedAt,
      reason: endReason,
    }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  return c.json(ok({
    sessionId,
    endedAt,
    reason: endReason,
  }))
})

// ── POST /admin/v1/impersonation/:sessionId/log-action ────────────────────────
// Logs an operator action taken during an impersonation session.

const logActionRoute = createRoute({
  method: 'post',
  path: '/admin/v1/impersonation/{sessionId}/log-action',
  tags: ['Impersonation'],
  summary: 'Log an action taken during an impersonation session',
  description:
    'Appends an action_taken entry to operator_impersonation_logs (NFR-S6). ' +
    'actionDetail is required and must be non-empty. ' +
    'userId must be supplied by the admin SPA (TODO: look up from sessions table once available). ' +
    '(AC: 2, NFR-S6)',
  request: {
    params: z.object({ sessionId: z.string().min(1) }),
    body: { content: { 'application/json': { schema: LogActionRequestSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: LogActionResponseSchema } },
      description: 'Action logged successfully',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'actionDetail is empty or missing',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Operator email not found in auth context',
    },
  },
})

app.openapi(logActionRoute, async (c) => {
  const { sessionId } = c.req.valid('param')
  const { userId, actionDetail } = c.req.valid('json')
  const databaseUrl = c.env?.DATABASE_URL

  const loggedAt = new Date().toISOString()

  if (databaseUrl) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    if (!operatorEmail) {
      return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)
    }

    const db = getDb(databaseUrl)

    const inserted = await db.insert(operatorImpersonationLogsTable).values({
      sessionId,
      userId,
      operatorEmail,
      actionType: 'action_taken',
      actionDetail,
    }).returning({ id: operatorImpersonationLogsTable.id })

    const logId = inserted[0]?.id ?? crypto.randomUUID()

    return c.json(ok({
      logId,
      sessionId,
      loggedAt,
    }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  return c.json(ok({
    logId: crypto.randomUUID(),
    sessionId,
    loggedAt,
  }))
})

export { app as impersonationRouter }
