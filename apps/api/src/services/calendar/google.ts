import type { CalendarEvent } from '@ontask/core'
import { calendarConnectionsTable, calendarConnectionsGoogleTable } from '@ontask/core'
import { eq } from 'drizzle-orm'
import { createDb } from '../../db/index.js'
import { decryptToken, encryptToken } from '../../lib/crypto.js'

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
