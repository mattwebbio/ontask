import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'
import { calendarConnectionsTable } from './calendar-connections.js'

// ── Calendar Events table ─────────────────────────────────────────────────────
// Cached calendar events fetched from provider APIs.
// The scheduling engine uses this data as immovable blocks (FR10).
//
// Events are re-fetched on each scheduling request (pull-on-schedule-request pattern;
// NFR-I1 60s propagation met by freshness of each schedule call).

export const calendarEventsTable = pgTable('calendar_events', {
  id: uuid().primaryKey().defaultRandom(),
  connectionId: uuid()
    .notNull()
    .references(() => calendarConnectionsTable.id),
  userId: uuid().notNull(),
  googleEventId: text().notNull(),
  startTime: timestamp({ withTimezone: true }).notNull(),
  endTime: timestamp({ withTimezone: true }).notNull(),
  isAllDay: boolean().notNull(),
  summary: text(), // nullable — event title; not exposed to scheduling engine
  syncedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
