import { pgTable, uuid } from 'drizzle-orm/pg-core'
import { calendarConnectionsTable } from './calendar-connections.js'

// ── Calendar Connections — Apple provider row ─────────────────────────────────
// v2 — EventKit native, no tokens
// Apple Calendar access uses EventKit on-device (no server-side OAuth tokens required).
// This stub table exists for schema consistency; actual implementation is in the Flutter layer.

export const calendarConnectionsAppleTable = pgTable('calendar_connections_apple', {
  connectionId: uuid()
    .primaryKey()
    .references(() => calendarConnectionsTable.id),
})
