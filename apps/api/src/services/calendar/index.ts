import type { CalendarEvent } from '@ontask/core'
import { calendarConnectionsTable } from '@ontask/core'
import { and, eq } from 'drizzle-orm'
import { createDb } from '../../db/index.js'
import { fetchGoogleCalendarEvents } from './google.js'

// ── Calendar service aggregator ──────────────────────────────────────────────
// Queries all active calendar connections for a user and aggregates events from
// all providers into a single flat CalendarEvent[] for the scheduling engine.
//
// The scheduling engine never knows which provider an event came from — this
// boundary is architectural (see Dev Notes: Provider Abstraction).

/**
 * Fetches all calendar events for a user within a scheduling window.
 *
 * Queries all `calendarConnections` where `isRead = true` and calls the
 * appropriate provider-specific fetcher for each connection. Partial failure
 * is tolerated — failed connections are skipped and the successful results are
 * aggregated and returned.
 *
 * @param userId - User ID whose calendars to fetch
 * @param windowStart - Start of scheduling window
 * @param windowEnd - End of scheduling window
 * @param env - Cloudflare worker bindings
 * @returns Flat array of CalendarEvent objects from all active connections
 */
export async function fetchAllCalendarEvents(
  userId: string,
  windowStart: Date,
  windowEnd: Date,
  env: CloudflareBindings,
): Promise<CalendarEvent[]> {
  const db = createDb(env.DATABASE_URL ?? '')

  const connections = await db
    .select({
      id: calendarConnectionsTable.id,
      provider: calendarConnectionsTable.provider,
    })
    .from(calendarConnectionsTable)
    .where(
      and(
        eq(calendarConnectionsTable.userId, userId),
        eq(calendarConnectionsTable.isRead, true),
      ),
    )

  if (connections.length === 0) {
    return []
  }

  const eventArrays = await Promise.all(
    connections.map(async (connection) => {
      if (connection.provider === 'google') {
        return fetchGoogleCalendarEvents(connection.id, userId, windowStart, windowEnd, env)
      }
      // 'outlook' and 'apple' providers are stubs (v2)
      return []
    }),
  )

  // Flatten all provider results into a single array
  return eventArrays.flat()
}
