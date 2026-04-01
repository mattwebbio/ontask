import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'
import { listsTable } from './lists.js'

// ── List invitations table ───────────────────────────────────────────────────
// Stores pending email invitations for list sharing (FR15, FR16).
// Token is a secure random string included in the deep-link URL.

export const listInvitationsTable = pgTable('list_invitations', {
  id: uuid().primaryKey().defaultRandom(),
  listId: uuid()
    .notNull()
    .references(() => listsTable.id, { onDelete: 'cascade' }),
  // TODO(story-TBD): Add FK constraint to users table when it exists
  invitedByUserId: uuid().notNull(),
  inviteeEmail: text().notNull(),
  token: text().notNull().unique(),
  status: text().notNull().default('pending'), // 'pending' | 'accepted' | 'declined'
  expiresAt: timestamp({ withTimezone: true }).notNull(),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
