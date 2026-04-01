import { pgTable, uuid, text, timestamp, unique } from 'drizzle-orm/pg-core'
import { calendarConnectionsTable } from './calendar-connections.js'

// ── Task Calendar Blocks table ────────────────────────────────────────────────
// Bidirectional link between a ScheduledBlock (engine output) and a Google
// Calendar event. One row per (taskId, connectionId) pair — a task can have
// blocks on multiple calendars if the user has multiple write-enabled connections.
//
// googleEventId — the Google Calendar event's `id` field returned from the
//   POST .../events create response. Used to identify the event for subsequent
//   PATCH updates when the task is rescheduled.
//
// scheduledStartTime / scheduledEndTime — the last-written times. Used to detect
//   when a reschedule has changed the block times so the service can PATCH instead
//   of re-creating.

export const taskCalendarBlocksTable = pgTable(
  'task_calendar_blocks',
  {
    id: uuid().primaryKey().defaultRandom(),
    taskId: uuid().notNull(), // no FK yet — pending tasks-users join (Story 3.4 design note)
    userId: uuid().notNull(),
    connectionId: uuid()
      .notNull()
      .references(() => calendarConnectionsTable.id),
    googleEventId: text().notNull(),
    scheduledStartTime: timestamp({ withTimezone: true }).notNull(),
    scheduledEndTime: timestamp({ withTimezone: true }).notNull(),
    createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    // One block per task per calendar connection — prevents duplicate events
    unique('task_calendar_blocks_task_connection_unique').on(
      table.taskId,
      table.connectionId,
    ),
  ],
)
