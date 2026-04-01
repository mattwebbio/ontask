import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'

// ── Calendar Connections table ────────────────────────────────────────────────
// Base table for calendar provider connections. Each row represents a single
// calendar connected by a user. Provider-specific details (tokens etc.) live in
// separate child tables (calendar-connections-google.ts etc.).
//
// isRead  — scheduling engine reads events from this calendar (default: true)
// isWrite — scheduling engine may write task blocks to this calendar (default: false; Story 3.4+)

export const calendarConnectionsTable = pgTable('calendar_connections', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),
  provider: text().notNull(), // 'google' | 'outlook' | 'apple'
  calendarId: text().notNull(),
  displayName: text().notNull(),
  isRead: boolean().default(true).notNull(),
  isWrite: boolean().default(false).notNull(),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
