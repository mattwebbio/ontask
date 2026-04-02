import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Operator impersonation log ─────────────────────────────────────────────────
// Immutable append-only audit log for all operator-initiated impersonation sessions
// and actions taken within them.
// Rows are NEVER updated or deleted (NFR-S6 immutable audit trail).

export const operatorImpersonationLogsTable = pgTable('operator_impersonation_logs', {
  id: uuid().primaryKey().defaultRandom(),
  sessionId: uuid().notNull(),              // groups all events for one impersonation session
  userId: uuid().notNull(),                 // the user being impersonated
  operatorEmail: text().notNull(),          // (c as any).get('operatorEmail') — email string
  // TODO(impl): operatorEmail stores text string — no operator UUID yet (same pattern as operator_refund_logs)
  actionType: text().notNull(),             // 'session_start' | 'session_end' | 'session_timeout' | 'action_taken'
  actionDetail: text(),                     // optional description of what action was taken
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  // NOTE: No updatedAt — row is intentionally immutable. Never add UPDATE logic to this table.
})
