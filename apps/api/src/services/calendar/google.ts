import type { CalendarEvent } from '@ontask/core'
import { calendarConnectionsTable, calendarConnectionsGoogleTable } from '@ontask/core'
import { eq } from 'drizzle-orm'
import { createDb } from '../../db/index.js'
import { decryptToken, encryptToken } from '../../lib/crypto.js'

// ── Google Calendar write types ───────────────────────────────────────────────

export interface WriteTaskBlockParams {
  connectionId: string
  userId: string
  taskId: string
  taskTitle: string
  startTime: Date
  endTime: Date
}

export interface UpdateTaskBlockParams {
  connectionId: string
  userId: string
  googleEventId: string
  startTime: Date
  endTime: Date
}

// ── writeTaskBlock ────────────────────────────────────────────────────────────

/**
 * Creates a Google Calendar event for a scheduled task block.
 *
 * Uses the same token decrypt + refresh pattern as fetchGoogleCalendarEvents.
 * Returns the new Google Calendar event ID on success, or null on any failure
 * (partial failure tolerant — never throws).
 *
 * @param params - Connection, user, task, and time information
 * @param env - Cloudflare worker bindings
 * @returns Google Calendar event ID string, or null on failure
 */
export async function writeTaskBlock(
  params: WriteTaskBlockParams,
  env: CloudflareBindings,
): Promise<string | null> {
  const calendarTokenKey = env.CALENDAR_TOKEN_KEY
  if (!calendarTokenKey) {
    console.error('[calendar/google] writeTaskBlock: CALENDAR_TOKEN_KEY not set')
    return null
  }

  try {
    const tokenResult = await loadAndRefreshToken(params.connectionId, params.userId, env, calendarTokenKey)
    if (!tokenResult) return null

    const { accessToken, calendarId } = tokenResult

    const eventBody = {
      summary: params.taskTitle,
      description: `Scheduled by On Task · Task ID: ${params.taskId}`,
      start: { dateTime: params.startTime.toISOString(), timeZone: 'UTC' },
      end: { dateTime: params.endTime.toISOString(), timeZone: 'UTC' },
    }

    const encodedCalendarId = encodeURIComponent(calendarId)
    const response = await fetch(
      `https://www.googleapis.com/calendar/v3/calendars/${encodedCalendarId}/events`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(eventBody),
      },
    )

    if (!response.ok) {
      console.error(
        `[calendar/google] writeTaskBlock: Google Calendar API returned ${response.status} for connection ${params.connectionId}`,
      )
      return null
    }

    const data = (await response.json()) as { id?: string }
    if (!data.id) {
      console.error('[calendar/google] writeTaskBlock: Response missing event id')
      return null
    }

    return data.id
  } catch (error) {
    console.error(`[calendar/google] writeTaskBlock: Unexpected error for connection ${params.connectionId}:`, error)
    return null
  }
}

// ── updateTaskBlock ───────────────────────────────────────────────────────────

/**
 * Updates the time fields of an existing Google Calendar event.
 *
 * Uses PATCH to update only start/end times (partial update).
 * Returns true on success, false on any failure (partial failure tolerant).
 *
 * @param params - Connection, user, event ID, and new time information
 * @param env - Cloudflare worker bindings
 * @returns true on success, false on failure
 */
export async function updateTaskBlock(
  params: UpdateTaskBlockParams,
  env: CloudflareBindings,
): Promise<boolean> {
  const calendarTokenKey = env.CALENDAR_TOKEN_KEY
  if (!calendarTokenKey) {
    console.error('[calendar/google] updateTaskBlock: CALENDAR_TOKEN_KEY not set')
    return false
  }

  try {
    const tokenResult = await loadAndRefreshToken(params.connectionId, params.userId, env, calendarTokenKey)
    if (!tokenResult) return false

    const { accessToken, calendarId } = tokenResult

    const patchBody = {
      start: { dateTime: params.startTime.toISOString(), timeZone: 'UTC' },
      end: { dateTime: params.endTime.toISOString(), timeZone: 'UTC' },
    }

    const encodedCalendarId = encodeURIComponent(calendarId)
    const response = await fetch(
      `https://www.googleapis.com/calendar/v3/calendars/${encodedCalendarId}/events/${params.googleEventId}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(patchBody),
      },
    )

    if (!response.ok) {
      console.error(
        `[calendar/google] updateTaskBlock: Google Calendar API returned ${response.status} for event ${params.googleEventId}`,
      )
      return false
    }

    return true
  } catch (error) {
    console.error(`[calendar/google] updateTaskBlock: Unexpected error for connection ${params.connectionId}:`, error)
    return false
  }
}

// ── Shared token loading helper ───────────────────────────────────────────────

interface TokenResult {
  accessToken: string
  calendarId: string
}

/**
 * Loads and optionally refreshes the access token for a connection.
 * Mirrors the token pattern from fetchGoogleCalendarEvents.
 * Returns null on any failure.
 */
async function loadAndRefreshToken(
  connectionId: string,
  userId: string,
  env: CloudflareBindings,
  calendarTokenKey: string,
): Promise<TokenResult | null> {
  const db = createDb(env.DATABASE_URL ?? '')

  const rows = await db
    .select({
      calendarId: calendarConnectionsTable.calendarId,
      userId: calendarConnectionsTable.userId,
      accessToken: calendarConnectionsGoogleTable.accessToken,
      refreshToken: calendarConnectionsGoogleTable.refreshToken,
      tokenExpiry: calendarConnectionsGoogleTable.tokenExpiry,
    })
    .from(calendarConnectionsGoogleTable)
    .innerJoin(
      calendarConnectionsTable,
      eq(calendarConnectionsGoogleTable.connectionId, calendarConnectionsTable.id),
    )
    .where(eq(calendarConnectionsTable.id, connectionId))
    .limit(1)

  if (rows.length === 0) {
    console.error(`[calendar/google] loadAndRefreshToken: Connection not found: ${connectionId}`)
    return null
  }

  const row = rows[0]

  if (row.userId !== userId) {
    console.error(`[calendar/google] loadAndRefreshToken: Connection ${connectionId} does not belong to user ${userId}`)
    return null
  }

  let accessToken = await decryptToken(row.accessToken, calendarTokenKey)

  const expiryMs = row.tokenExpiry.getTime()
  const nowMs = Date.now()
  if (expiryMs - nowMs < 60_000) {
    const refreshToken = await decryptToken(row.refreshToken, calendarTokenKey)
    const refreshed = await refreshGoogleToken(refreshToken, env)
    if (!refreshed) {
      console.error(`[calendar/google] loadAndRefreshToken: Token refresh failed for connection ${connectionId}`)
      return null
    }

    accessToken = refreshed.accessToken

    const encryptedAccess = await encryptToken(refreshed.accessToken, calendarTokenKey)
    const newExpiry = new Date(Date.now() + refreshed.expiresIn * 1000)

    await db
      .update(calendarConnectionsGoogleTable)
      .set({ accessToken: encryptedAccess, tokenExpiry: newExpiry })
      .where(eq(calendarConnectionsGoogleTable.connectionId, connectionId))
  }

  return { accessToken, calendarId: row.calendarId }
}

// ── Google Calendar REST API client ─────────────────────────────────────────
// Uses fetch() directly — the `googleapis` npm package pulls in Node.js-native
// code incompatible with the Workers edge runtime (see Dev Notes).

/**
 * Fetches Google Calendar events for a single connection within a time window.
 *
 * Handles token refresh automatically if the stored access token has expired.
 * On partial failure (connection not found, Google API error) returns an empty
 * array and logs the error — never throws (partial failure tolerant).
 *
 * @param connectionId - UUID of the calendarConnections row
 * @param userId - Used for authorization check (ensure connection belongs to user)
 * @param windowStart - Start of scheduling window (inclusive)
 * @param windowEnd - End of scheduling window (exclusive)
 * @param env - Cloudflare worker bindings
 * @returns Flat array of CalendarEvent objects ready for the scheduling engine
 */
export async function fetchGoogleCalendarEvents(
  connectionId: string,
  userId: string,
  windowStart: Date,
  windowEnd: Date,
  env: CloudflareBindings,
): Promise<CalendarEvent[]> {
  const calendarTokenKey = env.CALENDAR_TOKEN_KEY
  if (!calendarTokenKey) {
    console.error('[calendar/google] CALENDAR_TOKEN_KEY not set')
    return []
  }

  try {
    const db = createDb(env.DATABASE_URL ?? '')

    // Load connection + Google provider row in a single query
    const rows = await db
      .select({
        calendarId: calendarConnectionsTable.calendarId,
        userId: calendarConnectionsTable.userId,
        accessToken: calendarConnectionsGoogleTable.accessToken,
        refreshToken: calendarConnectionsGoogleTable.refreshToken,
        tokenExpiry: calendarConnectionsGoogleTable.tokenExpiry,
      })
      .from(calendarConnectionsGoogleTable)
      .innerJoin(
        calendarConnectionsTable,
        eq(calendarConnectionsGoogleTable.connectionId, calendarConnectionsTable.id),
      )
      .where(eq(calendarConnectionsTable.id, connectionId))
      .limit(1)

    if (rows.length === 0) {
      console.error(`[calendar/google] Connection not found: ${connectionId}`)
      return []
    }

    const row = rows[0]

    // Safety check — connection must belong to requesting user
    if (row.userId !== userId) {
      console.error(`[calendar/google] Connection ${connectionId} does not belong to user ${userId}`)
      return []
    }

    let accessToken = await decryptToken(row.accessToken, calendarTokenKey)

    // Token refresh: if the access token is expired (or within 60s of expiry), refresh it
    const expiryMs = row.tokenExpiry.getTime()
    const nowMs = Date.now()
    if (expiryMs - nowMs < 60_000) {
      const refreshToken = await decryptToken(row.refreshToken, calendarTokenKey)
      const refreshed = await refreshGoogleToken(refreshToken, env)
      if (!refreshed) {
        console.error(`[calendar/google] Token refresh failed for connection ${connectionId}`)
        return []
      }

      accessToken = refreshed.accessToken

      // Persist re-encrypted tokens back to DB
      const encryptedAccess = await encryptToken(refreshed.accessToken, calendarTokenKey)
      const newExpiry = new Date(Date.now() + refreshed.expiresIn * 1000)

      await db
        .update(calendarConnectionsGoogleTable)
        .set({ accessToken: encryptedAccess, tokenExpiry: newExpiry })
        .where(eq(calendarConnectionsGoogleTable.connectionId, connectionId))
    }

    // Fetch calendar events from Google Calendar REST API v3
    const calendarId = encodeURIComponent(row.calendarId)
    const url =
      `https://www.googleapis.com/calendar/v3/calendars/${calendarId}/events` +
      `?timeMin=${windowStart.toISOString()}` +
      `&timeMax=${windowEnd.toISOString()}` +
      `&singleEvents=true` +
      `&orderBy=startTime`

    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    })

    if (!response.ok) {
      console.error(
        `[calendar/google] Google Calendar API returned ${response.status} for connection ${connectionId}`,
      )
      return []
    }

    const data = (await response.json()) as GoogleCalendarEventsResponse

    const validItems = (data.items ?? []).filter((item) => {
      const hasStart = item.start.dateTime || item.start.date
      const hasEnd = item.end.dateTime || item.end.date
      if (!hasStart || !hasEnd) {
        console.error(`[calendar/google] Skipping event ${item.id} — missing start or end time`)
        return false
      }
      return true
    })

    return validItems.map((item) => mapGoogleEventToCalendarEvent(item))
  } catch (error) {
    console.error(`[calendar/google] Unexpected error for connection ${connectionId}:`, error)
    return []
  }
}

// ── Google OAuth token refresh ───────────────────────────────────────────────

interface RefreshedTokens {
  accessToken: string
  expiresIn: number
}

async function refreshGoogleToken(
  refreshToken: string,
  env: CloudflareBindings,
): Promise<RefreshedTokens | null> {
  try {
    const body = new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: env.GOOGLE_CLIENT_ID ?? '',
      client_secret: env.GOOGLE_CLIENT_SECRET ?? '',
    })

    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    })

    if (!response.ok) {
      console.error(`[calendar/google] Token refresh HTTP ${response.status}`)
      return null
    }

    const data = (await response.json()) as { access_token?: string; expires_in?: number }
    if (!data.access_token) {
      console.error('[calendar/google] Token refresh response missing access_token')
      return null
    }

    return {
      accessToken: data.access_token,
      expiresIn: data.expires_in ?? 3600,
    }
  } catch (error) {
    console.error('[calendar/google] Token refresh request failed:', error)
    return null
  }
}

// ── Google Calendar API response types ───────────────────────────────────────

interface GoogleCalendarEventStart {
  dateTime?: string
  date?: string
}

interface GoogleCalendarEventItem {
  id: string
  summary?: string
  start: GoogleCalendarEventStart
  end: GoogleCalendarEventStart
}

interface GoogleCalendarEventsResponse {
  items?: GoogleCalendarEventItem[]
}

// ── Mapping ──────────────────────────────────────────────────────────────────

function mapGoogleEventToCalendarEvent(item: GoogleCalendarEventItem): CalendarEvent {
  const isAllDay = !item.start.dateTime

  return {
    id: item.id,
    startTime: new Date(item.start.dateTime ?? item.start.date ?? ''),
    endTime: new Date(item.end.dateTime ?? item.end.date ?? ''),
    isAllDay,
  }
}
