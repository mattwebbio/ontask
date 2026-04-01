import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'

// ── Proof submissions table ───────────────────────────────────────────────────
// Stores per-task proof submission records for AI verification (Epic 7, Story 7.2).
// mediaUrl is null until Backblaze B2 upload completes (deferred to Story 7.3+).
// verified is null until AI verification completes (null = pending).

export const proofSubmissions = pgTable('proof_submissions', {
  id: uuid('id').primaryKey().defaultRandom(),
  taskId: uuid('task_id').notNull(),        // FK to tasks — add .references(() => tasks.id) when tasks schema is importable
  userId: uuid('user_id').notNull(),
  proofPath: text('proof_path').notNull(),  // 'photo' | 'screenshot' | 'healthKit' | 'offline'
  mediaUrl: text('media_url'),              // nullable — null until B2 upload completes
  verified: boolean('verified'),            // null = pending, true = approved, false = rejected
  verificationReason: text('verification_reason'), // AI failure explanation or null
  clientTimestamp: timestamp('client_timestamp', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})
