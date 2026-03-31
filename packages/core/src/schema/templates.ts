import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Templates table ──────────────────────────────────────────────────────────
// Stores reusable task templates created from lists or sections.
// The full structure (sections, tasks, hierarchy) is captured as a JSON
// snapshot in `templateData` — no relational join needed at apply time.

export const templatesTable = pgTable('templates', {
  id: uuid().primaryKey().defaultRandom(),
  // TODO(story-TBD): Add FK constraint when users table is created
  userId: uuid().notNull(),
  title: text().notNull(),
  sourceType: text().notNull(), // 'list' | 'section'
  templateData: text().notNull(), // JSON string containing full structure snapshot
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
