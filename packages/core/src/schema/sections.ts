import { pgTable, uuid, text, timestamp, integer } from 'drizzle-orm/pg-core'
import { listsTable } from './lists.js'

// ── Sections table ──────────────────────────────────────────────────────────
// Sections are organisational groups within a list. They support infinite
// nesting via the parentSectionId self-reference.
// Sections can have a default due date inherited by tasks (FR3).

export const sectionsTable = pgTable('sections', {
  id: uuid().primaryKey().defaultRandom(),
  listId: uuid().notNull().references(() => listsTable.id),
  parentSectionId: uuid(), // Self-reference for infinite nesting — FK added via migration
  title: text().notNull(),
  defaultDueDate: timestamp({ withTimezone: true }),
  position: integer().default(0).notNull(),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
