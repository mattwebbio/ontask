import { pgTable, uuid, text, timestamp, integer } from 'drizzle-orm/pg-core'

// ── Lists table ─────────────────────────────────────────────────────────────
// A list is a top-level container for tasks and sections.
// Lists belong to a user and can have a default due date that is inherited
// by tasks created within them (FR3).

export const listsTable = pgTable('lists', {
  id: uuid().primaryKey().defaultRandom(),
  // TODO(story-TBD): Add FK constraint when users table is created
  userId: uuid().notNull(),
  title: text().notNull(),
  defaultDueDate: timestamp({ withTimezone: true }),
  position: integer().default(0).notNull(),
  archivedAt: timestamp({ withTimezone: true }),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
