import { pgTable, uuid, text, timestamp, unique, integer } from 'drizzle-orm/pg-core'
import { listsTable } from './lists.js'

// ── List members table ───────────────────────────────────────────────────────
// Tracks which users are members of a shared list (FR15, FR16, FR62, FR75).
// A list starts with one implicit owner (the creator); sharing adds members.

export const listMembersTable = pgTable('list_members', {
  id: uuid().primaryKey().defaultRandom(),
  listId: uuid()
    .notNull()
    .references(() => listsTable.id, { onDelete: 'cascade' }),
  // TODO(story-TBD): Add FK constraint to users table when it exists
  userId: uuid().notNull(),
  role: text().notNull().default('member'), // 'owner' | 'member'
  roundRobinIndex: integer().default(0).notNull(), // 0-based position in round-robin rotation sequence
  joinedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('list_members_list_id_user_id_unique').on(table.listId, table.userId),
])
