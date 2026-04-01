import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'
import { listsTable } from './lists.js'
import { tasksTable } from './tasks.js'

// ── Group commitments table ─────────────────────────────────────────────────
// Represents a shared commitment arrangement across members of a shared list.
// Activates only when all members have explicitly approved (FR29, Story 6.7).
export const groupCommitmentsTable = pgTable('group_commitments', {
  id: uuid().primaryKey().defaultRandom(),
  listId: uuid().notNull().references(() => listsTable.id, { onDelete: 'cascade' }),
  taskId: uuid().notNull().references(() => tasksTable.id, { onDelete: 'cascade' }),
  proposedByUserId: uuid().notNull(),   // user who initiated the group commitment proposal
  status: text().notNull().default('pending'), // 'pending' | 'active' | 'cancelled'
  // 'pending'  = awaiting unanimous approval
  // 'active'   = all members approved; charges may be triggered
  // 'cancelled' = proposal withdrawn or list dissolved
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
