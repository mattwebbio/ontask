import { pgTable, uuid } from 'drizzle-orm/pg-core'
import { calendarConnectionsTable } from './calendar-connections.js'

// ── Calendar Connections — Outlook provider row ───────────────────────────────
// v2 — stub
// Microsoft Graph OAuth token storage will be implemented in a future story.

export const calendarConnectionsOutlookTable = pgTable('calendar_connections_outlook', {
  connectionId: uuid()
    .primaryKey()
    .references(() => calendarConnectionsTable.id),
})
