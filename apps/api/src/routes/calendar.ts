import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { eq } from 'drizzle-orm'
import { calendarConnectionsTable, calendarConnectionsGoogleTable } from '@ontask/core'
import { ok, err } from '../lib/response.js'
import { createDb } from '../db/index.js'
import { encryptToken } from '../lib/crypto.js'

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
