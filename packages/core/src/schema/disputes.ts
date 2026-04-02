import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Verification disputes table ───────────────────────────────────────────────
// Stores user-filed disputes against AI verification results (FR39-40, Story 7.8).
// status: 'pending' | 'approved' | 'rejected'
// 'pending' = under human review; charge hold in effect.
// 'approved' = operator ruled in user's favour; charge cancelled.
// 'rejected' = operator confirmed AI decision; charge processed.
// Operator resolution handled in Story 7.9 / Story 11.2.

export const verificationDisputesTable = pgTable('verification_disputes', {
  id: uuid().primaryKey().defaultRandom(),
  taskId: uuid().notNull(),              // FK to tasks — add .references() when importable
  userId: uuid().notNull(),              // FK to users
  proofSubmissionId: uuid(),             // FK to proof_submissions — nullable if no prior submission
  status: text().default('pending').notNull(), // 'pending' | 'approved' | 'rejected'
  operatorNote: text(),                  // internal note from operator at resolution (Story 7.9)
  resolvedAt: timestamp({ withTimezone: true }), // null until operator resolves
  resolvedByUserId: uuid(),              // operator userId at resolution (Story 7.9)
  filedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
