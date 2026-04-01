import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { and, eq } from 'drizzle-orm'
import { calendarConnectionsTable, calendarConnectionsGoogleTable } from '@ontask/core'
import { ok, err } from '../lib/response.js'
import { createDb } from '../db/index.js'
import { encryptToken } from '../lib/crypto.js'
import { fetchAllCalendarEvents } from '../services/calendar/index.js'
import { registerWebhookChannel } from '../services/calendar/google.js'
import { runScheduleForUser } from '../services/scheduling.js'

// ── Calendar router ──────────────────────────────────────────────────────────
// Routes for Google Calendar OAuth connection and listing connections (FR46).

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const ConnectCalendarBodySchema = z.object({
  provider: z.enum(['google']).openapi({ example: 'google' }),
  authorizationCode: z.string().min(1).openapi({ example: 'authorization-code-from-google' }),
  redirectUri: z
    .string()
    .url()
    .openapi({ example: 'https://app.ontaskhq.com/oauth/google/callback' }),
})

const ConnectCalendarResponseSchema = z.object({
  data: z.object({
    connectionId: z.string().uuid(),
    calendarId: z.string(),
    displayName: z.string(),
  }),
})

const CalendarConnectionSchema = z.object({
  id: z.string().uuid(),
  provider: z.enum(['google', 'outlook', 'apple']),
  calendarId: z.string(),
  displayName: z.string(),
  isRead: z.boolean(),
  isWrite: z.boolean(),
})

const CalendarConnectionsListResponseSchema = z.object({
  data: z.array(CalendarConnectionSchema),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/calendar/connect ────────────────────────────────────────────────

const postCalendarConnectRoute = createRoute({
  method: 'post',
  path: '/v1/calendar/connect',
  tags: ['Calendar'],
  summary: 'Connect a Google Calendar via OAuth',
  description:
    'Exchanges a Google OAuth authorization code for tokens, fetches the primary ' +
    'calendar, and stores the connection. Tokens are encrypted with AES-256-GCM ' +
    'before storage (NFR-S4). Base row and provider row are inserted in a single ' +
    'transaction (AC 6).',
  request: {
    body: {
      content: { 'application/json': { schema: ConnectCalendarBodySchema } },
      required: true,
    },
  },
  responses: {
    201: {
      content: { 'application/json': { schema: ConnectCalendarResponseSchema } },
      description: 'Calendar connected successfully',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid request or OAuth exchange failed',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Internal server error',
    },
  },
})

app.openapi(postCalendarConnectRoute, async (c) => {
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  const body = c.req.valid('json')

  const calendarTokenKey = c.env.CALENDAR_TOKEN_KEY
  if (!calendarTokenKey) {
    return c.json(err('INTERNAL_ERROR', 'Calendar token key not configured'), 500)
  }

  // Exchange authorization code for Google OAuth tokens
  const tokenResponse = await exchangeGoogleCode(
    body.authorizationCode,
    body.redirectUri,
    c.env,
  )

  if (!tokenResponse) {
    return c.json(err('OAUTH_EXCHANGE_FAILED', 'Failed to exchange authorization code with Google'), 400)
  }

  // Fetch the primary calendar info (calendarId, summary) from Google
  const calendarInfo = await fetchGooglePrimaryCalendar(tokenResponse.accessToken)

  if (!calendarInfo) {
    return c.json(err('CALENDAR_FETCH_FAILED', 'Failed to fetch calendar info from Google'), 400)
  }

  const db = createDb(c.env.DATABASE_URL ?? '')

  // Encrypt tokens before storage (NFR-S4)
  const encryptedAccess = await encryptToken(tokenResponse.accessToken, calendarTokenKey)
  const encryptedRefresh = await encryptToken(tokenResponse.refreshToken, calendarTokenKey)
  const tokenExpiry = new Date(Date.now() + tokenResponse.expiresIn * 1000)

  // Insert base row + provider row in a single Drizzle transaction (AC 6)
  let connectionId: string
  try {
    connectionId = await db.transaction(async (tx) => {
      const [base] = await tx
        .insert(calendarConnectionsTable)
        .values({
          userId,
          provider: 'google',
          calendarId: calendarInfo.calendarId,
          displayName: calendarInfo.displayName,
          isRead: true,
          isWrite: false,
        })
        .returning({ id: calendarConnectionsTable.id })

      await tx.insert(calendarConnectionsGoogleTable).values({
        connectionId: base.id,
        accountEmail: tokenResponse.email,
        accessToken: encryptedAccess,
        refreshToken: encryptedRefresh,
        tokenExpiry,
      })

      return base.id
    })
  } catch (error) {
    console.error('[calendar/connect] Transaction failed:', error)
    return c.json(err('INTERNAL_ERROR', 'Failed to store calendar connection'), 500)
  }

  // Fire-and-forget webhook channel registration — do NOT block the connect response
  try { c.executionCtx.waitUntil(registerWebhookChannel(connectionId, userId, c.env)) } catch { /* no executionCtx in test */ }

  return c.json(
    ok({
      connectionId,
      calendarId: calendarInfo.calendarId,
      displayName: calendarInfo.displayName,
    }),
    201,
  )
})

// ── GET /v1/calendar/connections ─────────────────────────────────────────────

const getCalendarConnectionsRoute = createRoute({
  method: 'get',
  path: '/v1/calendar/connections',
  tags: ['Calendar'],
  summary: 'List calendar connections',
  description:
    'Returns all calendar connections for the authenticated user. ' +
    'Tokens are never included in the response (AC 7).',
  responses: {
    200: {
      content: { 'application/json': { schema: CalendarConnectionsListResponseSchema } },
      description: 'List of calendar connections',
    },
  },
})

app.openapi(getCalendarConnectionsRoute, async (c) => {
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'

  const db = createDb(c.env.DATABASE_URL ?? '')

  const connections = await db
    .select({
      id: calendarConnectionsTable.id,
      provider: calendarConnectionsTable.provider,
      calendarId: calendarConnectionsTable.calendarId,
      displayName: calendarConnectionsTable.displayName,
      isRead: calendarConnectionsTable.isRead,
      isWrite: calendarConnectionsTable.isWrite,
    })
    .from(calendarConnectionsTable)
    .where(eq(calendarConnectionsTable.userId, userId))

  return c.json(
    ok(
      connections.map((conn) => ({
        id: conn.id,
        provider: conn.provider as 'google' | 'outlook' | 'apple',
        calendarId: conn.calendarId,
        displayName: conn.displayName,
        isRead: conn.isRead,
        isWrite: conn.isWrite,
      })),
    ),
    200,
  )
})

// ── PATCH /v1/calendar/connections/:id ───────────────────────────────────────

const PatchCalendarConnectionParamsSchema = z.object({
  id: z.string().uuid(),
})

const PatchCalendarConnectionBodySchema = z
  .object({
    isWrite: z.boolean().optional(),
  })
  .refine((data) => data.isWrite !== undefined, {
    message: 'At least one patchable field must be provided (isWrite)',
  })

const PatchCalendarConnectionResponseSchema = z.object({
  data: z.object({
    id: z.string().uuid(),
    isWrite: z.boolean(),
  }),
})

const patchCalendarConnectionRoute = createRoute({
  method: 'patch',
  path: '/v1/calendar/connections/{id}',
  tags: ['Calendar'],
  summary: 'Update a calendar connection (e.g. enable write access)',
  description:
    'Patches a calendar connection. Currently only `isWrite` is patchable. ' +
    'Returns 404 if the connection does not exist or does not belong to the user. ' +
    'Returns 400 if the request body contains no patchable fields (AC5).',
  request: {
    params: PatchCalendarConnectionParamsSchema,
    body: {
      content: { 'application/json': { schema: PatchCalendarConnectionBodySchema } },
      required: true,
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: PatchCalendarConnectionResponseSchema } },
      description: 'Connection updated successfully',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Bad request — empty body or no patchable fields',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Connection not found or not owned by user',
    },
  },
})

app.openapi(patchCalendarConnectionRoute, async (c) => {
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')

  // Validate at least one patchable field is present (belt-and-suspenders after Zod refine)
  if (body.isWrite === undefined) {
    return c.json(err('BAD_REQUEST', 'At least one patchable field must be provided'), 400)
  }

  const db = createDb(c.env.DATABASE_URL ?? '')

  // Ownership check — connection must exist and belong to this user
  const rows = await db
    .select({ id: calendarConnectionsTable.id, isWrite: calendarConnectionsTable.isWrite })
    .from(calendarConnectionsTable)
    .where(
      and(
        eq(calendarConnectionsTable.id, id),
        eq(calendarConnectionsTable.userId, userId),
      ),
    )
    .limit(1)

  if (rows.length === 0) {
    return c.json(err('NOT_FOUND', 'Calendar connection not found'), 404)
  }

  // Apply the patch
  await db
    .update(calendarConnectionsTable)
    .set({ isWrite: body.isWrite, updatedAt: new Date() })
    .where(eq(calendarConnectionsTable.id, id))

  return c.json(ok({ id, isWrite: body.isWrite }), 200)
})

// ── GET /v1/calendar/events ───────────────────────────────────────────────────

const CalendarEventSchema = z.object({
  id: z.string(),
  startTime: z.string().datetime(),
  endTime: z.string().datetime(),
  isAllDay: z.boolean(),
  summary: z.string().optional(),
})

const CalendarEventsResponseSchema = z.object({
  data: z.array(CalendarEventSchema),
})

const GetCalendarEventsQuerySchema = z.object({
  windowStart: z.string().datetime().optional(),
  windowEnd: z.string().datetime().optional(),
})

const getCalendarEventsRoute = createRoute({
  method: 'get',
  path: '/v1/calendar/events',
  tags: ['Calendar'],
  summary: 'Fetch calendar events within a window',
  description:
    'Returns all calendar events for the authenticated user within the given time window. ' +
    'Used by the Flutter Today tab to display calendar event blocks on the timeline (AC6).',
  request: {
    query: GetCalendarEventsQuerySchema,
  },
  responses: {
    200: {
      content: { 'application/json': { schema: CalendarEventsResponseSchema } },
      description: 'List of calendar events',
    },
  },
})

app.openapi(getCalendarEventsRoute, async (c) => {
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  const query = c.req.valid('query')

  const now = new Date()
  const windowStart = query.windowStart ? new Date(query.windowStart) : now
  const windowEnd = query.windowEnd
    ? new Date(query.windowEnd)
    : new Date(now.getTime() + 24 * 60 * 60_000) // default: next 24 hours

  const events = await fetchAllCalendarEvents(userId, windowStart, windowEnd, c.env)

  return c.json(
    ok(
      events.map((event) => ({
        id: event.id,
        startTime: event.startTime.toISOString(),
        endTime: event.endTime.toISOString(),
        isAllDay: event.isAllDay,
      })),
    ),
    200,
  )
})

// ── POST /v1/calendar/webhook ─────────────────────────────────────────────────

const WebhookResponseSchema = z.object({
  data: z.object({}),
})

const postCalendarWebhookRoute = createRoute({
  method: 'post',
  path: '/v1/calendar/webhook',
  tags: ['Calendar'],
  summary: 'Google Calendar push notification receiver',
  description:
    'Receives Google Calendar push notifications. Validates the channel token ' +
    'and triggers rescheduling for the affected user. Returns 200 immediately ' +
    '(Google requires fast acknowledgment). Returns 401 on invalid token (AC 1).',
  responses: {
    200: {
      content: { 'application/json': { schema: WebhookResponseSchema } },
      description: 'Notification acknowledged',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid or missing channel token',
    },
  },
})

app.openapi(postCalendarWebhookRoute, async (c) => {
  // Validate the channel token — Google echoes back our registered token
  const channelToken = c.req.header('X-Goog-Channel-Token')
  if (!channelToken || channelToken !== c.env.CALENDAR_WEBHOOK_SECRET) {
    return c.json(err('UNAUTHORIZED', 'Invalid channel token'), 401)
  }

  const resourceState = c.req.header('X-Goog-Resource-State')

  // 'sync' is the initial handshake — acknowledge but do NOT trigger rescheduling
  if (resourceState === 'sync') {
    return c.json(ok({}), 200)
  }

  // 'exists' (event created/updated) and 'not_exists' (event deleted) → trigger rescheduling
  // Look up userId from the channel ID (= connectionId registered at watch time)
  const channelId = c.req.header('X-Goog-Channel-Id')

  if (channelId) {
    const db = createDb(c.env.DATABASE_URL ?? '')
    const rows = await db
      .select({ userId: calendarConnectionsTable.userId })
      .from(calendarConnectionsTable)
      .where(eq(calendarConnectionsTable.id, channelId))
      .limit(1)

    if (rows.length > 0) {
      const { userId } = rows[0]
      // Fire-and-forget — return 200 immediately, rescheduling completes within Worker lifetime
      try { c.executionCtx.waitUntil(runScheduleForUser(userId, c.env)) } catch { /* no executionCtx in test */ }
    }
  }

  return c.json(ok({}), 200)
})

// ── Google OAuth helpers ──────────────────────────────────────────────────────

interface GoogleTokenResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
  email: string
}

async function exchangeGoogleCode(
  code: string,
  redirectUri: string,
  env: CloudflareBindings,
): Promise<GoogleTokenResponse | null> {
  try {
    const body = new URLSearchParams({
      code,
      redirect_uri: redirectUri,
      client_id: env.GOOGLE_CLIENT_ID ?? '',
      client_secret: env.GOOGLE_CLIENT_SECRET ?? '',
      grant_type: 'authorization_code',
    })

    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    })

    if (!response.ok) {
      console.error(`[calendar/connect] Token exchange HTTP ${response.status}`)
      return null
    }

    const data = (await response.json()) as {
      access_token?: string
      refresh_token?: string
      expires_in?: number
    }

    if (!data.access_token || !data.refresh_token) {
      console.error('[calendar/connect] Token exchange response missing tokens')
      return null
    }

    // Fetch user email from Google userinfo endpoint
    const userInfoResponse = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: { Authorization: `Bearer ${data.access_token}` },
    })

    let email = ''
    if (userInfoResponse.ok) {
      const userInfo = (await userInfoResponse.json()) as { email?: string }
      email = userInfo.email ?? ''
    }

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresIn: data.expires_in ?? 3600,
      email,
    }
  } catch (error) {
    console.error('[calendar/connect] Token exchange failed:', error)
    return null
  }
}

interface GoogleCalendarInfo {
  calendarId: string
  displayName: string
}

async function fetchGooglePrimaryCalendar(
  accessToken: string,
): Promise<GoogleCalendarInfo | null> {
  try {
    const response = await fetch(
      'https://www.googleapis.com/calendar/v3/users/me/calendarList/primary',
      { headers: { Authorization: `Bearer ${accessToken}` } },
    )

    if (!response.ok) {
      console.error(`[calendar/connect] Calendar list HTTP ${response.status}`)
      return null
    }

    const data = (await response.json()) as { id?: string; summary?: string }

    if (!data.id) {
      console.error('[calendar/connect] Calendar list response missing id')
      return null
    }

    return {
      calendarId: data.id,
      displayName: data.summary ?? data.id,
    }
  } catch (error) {
    console.error('[calendar/connect] Calendar fetch failed:', error)
    return null
  }
}

export const calendarRouter = app
