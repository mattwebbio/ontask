import { pgTable, uuid, text, timestamp, integer, boolean } from 'drizzle-orm/pg-core'
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
  timeWindow: text(), // 'morning' | 'afternoon' | 'evening' | 'custom'
  timeWindowStart: text(), // HH:mm format, used when timeWindow = 'custom'
  timeWindowEnd: text(), // HH:mm format, used when timeWindow = 'custom'
  energyRequirement: text(), // 'high_focus' | 'low_energy' | 'flexible'
  priority: text().default('normal'), // 'normal' | 'high' | 'critical'
  archivedAt: timestamp({ withTimezone: true }),
  recurrenceRule: text(), // 'daily' | 'weekly' | 'monthly' | 'custom'
  recurrenceInterval: integer(), // for custom interval: number of days between occurrences
  recurrenceDaysOfWeek: text(), // JSON array string of ISO day numbers e.g. '[1,2,5]' (Mon=1..Sun=7)
  recurrenceParentId: uuid(), // self-reference to the original recurring task (series parent)
  // TODO(story-TBD): FK to users table when users schema is finalized
  assignedToUserId: uuid(), // null = unassigned; set by round-robin/least-busy/ai-assisted strategy
  proofMode: text(), // 'standard' | 'photo' | 'watchMode' | 'healthKit' | 'calendarEvent' | null (null = derived from inherited requirement)
  proofModeIsCustom: boolean().default(false).notNull(), // true when proofMode was explicitly set by user, overriding list/section default
  proofRetained: boolean().default(false).notNull(), // true when the user chose "Keep as completion record" (FR38, Story 7.7)
  proofMediaUrl: text(), // nullable; presigned URL or storage path for photo/video/document proof (FR21, NFR-S4)
  stakeAmountCents: integer(), // nullable; stake amount in US cents; null means no stake set (FR22, Story 6.2)
  stakeModificationDeadline: timestamp({ withTimezone: true }), // nullable; set to (dueDate - 24h) when stake is locked; null means unstaked (FR63, Story 6.6)
  completedAt: timestamp({ withTimezone: true }),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
