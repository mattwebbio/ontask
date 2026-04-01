import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'
import { calendarConnectionsTable } from './calendar-connections.js'

// ── Calendar Connections — Google provider row ────────────────────────────────
// Stores Google-specific OAuth tokens for a calendar connection.
// Tokens are AES-256-GCM encrypted at the application layer before insert
// and decrypted after read — never stored in plaintext.
//
// connectionId is both the PK and FK to calendarConnectionsTable (1:1 relationship).

export const calendarConnectionsGoogleTable = pgTable('calendar_connections_google', {
  connectionId: uuid()
    .primaryKey()
    .references(() => calendarConnectionsTable.id),
  accountEmail: text().notNull(),
  accessToken: text().notNull(), // AES-256-GCM encrypted at application layer
  refreshToken: text().notNull(), // AES-256-GCM encrypted at application layer
  tokenExpiry: timestamp({ withTimezone: true }).notNull(),
})
