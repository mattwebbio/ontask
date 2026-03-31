import { pgTable, uuid, text, timestamp, integer } from 'drizzle-orm/pg-core'
import { listsTable } from './lists.js'
import { sectionsTable } from './sections.js'

// ── Tasks table ─────────────────────────────────────────────────────────────
// Core task entity. Tasks can belong to a list and/or section, and support
// subtask nesting via parentTaskId self-reference.
// Due date inheritance (FR3): task dueDate > section defaultDueDate > list defaultDueDate.

export const tasksTable = pgTable('tasks', {
  id: uuid().primaryKey().defaultRandom(),
  // TODO(story-TBD): Add FK constraint when users table is created
  userId: uuid().notNull(),
  listId: uuid().references(() => listsTable.id),
  sectionId: uuid().references(() => sectionsTable.id),
  parentTaskId: uuid(), // Self-reference for subtask nesting — FK added via migration
  title: text().notNull(),
  notes: text(),
  dueDate: timestamp({ withTimezone: true }),
  position: integer().default(0).notNull(),
  archivedAt: timestamp({ withTimezone: true }),
  completedAt: timestamp({ withTimezone: true }),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
