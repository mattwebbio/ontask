import type { CalendarEvent, ScheduledBlock } from '@ontask/core'
import { calendarConnectionsTable, taskCalendarBlocksTable } from '@ontask/core'
import { and, eq } from 'drizzle-orm'
import { createDb } from '../../db/index.js'
import { fetchGoogleCalendarEvents, writeTaskBlock, updateTaskBlock } from './google.js'

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
// ── syncScheduledBlocksToCalendar ─────────────────────────────────────────────

/**
 * Writes or updates scheduled task blocks to all write-enabled Google Calendar
 * connections for the user.
 *
 * For each write-enabled Google connection, for each scheduled block:
 *   - If no existing row: POST a new calendar event and store the mapping
 *   - If existing row with same times: skip (no-op)
 *   - If existing row with different times: PATCH the event with new times
 *   - If PATCH fails (event externally deleted): fall back to POST + upsert
 *
 * Partial failure tolerant: errors per-block are caught and logged; scheduling
 * never fails because calendar write fails.
 *
 * @param userId - User whose write-enabled connections to write to
 * @param scheduledBlocks - Engine output blocks to sync
 * @param tasks - Task objects for title lookup (currently stub — pass [])
 * @param env - Cloudflare worker bindings
 */
export async function syncScheduledBlocksToCalendar(
  userId: string,
  scheduledBlocks: ScheduledBlock[],
  tasks: Array<{ id: string; title: string }>,
  env: CloudflareBindings,
): Promise<void> {
  if (scheduledBlocks.length === 0) return

  try {
    const db = createDb(env.DATABASE_URL ?? '')

    // Query write-enabled Google connections
    const writeConnections = await db
      .select({
        id: calendarConnectionsTable.id,
      })
      .from(calendarConnectionsTable)
      .where(
        and(
          eq(calendarConnectionsTable.userId, userId),
          eq(calendarConnectionsTable.isWrite, true),
          eq(calendarConnectionsTable.provider, 'google'),
        ),
      )

    if (writeConnections.length === 0) return

    for (const connection of writeConnections) {
      for (const block of scheduledBlocks) {
        try {
          // Build task title from task list (stub: use taskId if not found)
          const task = tasks.find((t) => t.id === block.taskId)
          const taskTitle = task?.title ?? `Task ${block.taskId}`

          // Look up existing block mapping
          const existing = await db
            .select({
              id: taskCalendarBlocksTable.id,
              googleEventId: taskCalendarBlocksTable.googleEventId,
              scheduledStartTime: taskCalendarBlocksTable.scheduledStartTime,
              scheduledEndTime: taskCalendarBlocksTable.scheduledEndTime,
            })
            .from(taskCalendarBlocksTable)
            .where(
              and(
                eq(taskCalendarBlocksTable.taskId, block.taskId),
                eq(taskCalendarBlocksTable.connectionId, connection.id),
              ),
            )
            .limit(1)

          if (existing.length > 0) {
            const row = existing[0]

            // Check if times match — if so, skip
            const startMatch = row.scheduledStartTime.getTime() === block.startTime.getTime()
            const endMatch = row.scheduledEndTime.getTime() === block.endTime.getTime()
            if (startMatch && endMatch) continue

            // Times differ — attempt PATCH
            const updated = await updateTaskBlock(
              {
                connectionId: connection.id,
                userId,
                googleEventId: row.googleEventId,
                startTime: block.startTime,
                endTime: block.endTime,
              },
              env,
            )

            if (updated) {
              await db
                .update(taskCalendarBlocksTable)
                .set({
                  scheduledStartTime: block.startTime,
                  scheduledEndTime: block.endTime,
                  updatedAt: new Date(),
                })
                .where(eq(taskCalendarBlocksTable.id, row.id))
            } else {
              // PATCH failed (event may have been deleted externally) — create new
              const newEventId = await writeTaskBlock(
                {
                  connectionId: connection.id,
                  userId,
                  taskId: block.taskId,
                  taskTitle,
                  startTime: block.startTime,
                  endTime: block.endTime,
                },
                env,
              )
              if (newEventId) {
                await db
                  .update(taskCalendarBlocksTable)
                  .set({
                    googleEventId: newEventId,
                    scheduledStartTime: block.startTime,
                    scheduledEndTime: block.endTime,
                    updatedAt: new Date(),
                  })
                  .where(eq(taskCalendarBlocksTable.id, row.id))
              }
            }
          } else {
            // No existing row — create new calendar event
            const newEventId = await writeTaskBlock(
              {
                connectionId: connection.id,
                userId,
                taskId: block.taskId,
                taskTitle,
                startTime: block.startTime,
                endTime: block.endTime,
              },
              env,
            )

            if (newEventId) {
              await db.insert(taskCalendarBlocksTable).values({
                taskId: block.taskId,
                userId,
                connectionId: connection.id,
                googleEventId: newEventId,
                scheduledStartTime: block.startTime,
                scheduledEndTime: block.endTime,
              })
            }
          }
        } catch (blockError) {
          console.error(
            `[calendar] syncScheduledBlocksToCalendar: Error for task ${block.taskId} on connection ${connection.id}:`,
            blockError,
          )
          // Continue to next block — partial failure tolerant
        }
      }
    }
  } catch (error) {
    console.error('[calendar] syncScheduledBlocksToCalendar: Failed to load connections:', error)
    // Never throw — scheduling must not fail because calendar write fails
  }
}

export async function fetchAllCalendarEvents(
  userId: string,
  windowStart: Date,
  windowEnd: Date,
  env: CloudflareBindings,
): Promise<CalendarEvent[]> {
  try {
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
  } catch (error) {
    console.error('[calendar] Failed to load connections:', error)
    return []
  }
}
