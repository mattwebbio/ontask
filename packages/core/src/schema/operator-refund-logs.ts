import { pgTable, uuid, text, integer, timestamp } from 'drizzle-orm/pg-core'

// ── Operator refund log ────────────────────────────────────────────────────────
// Immutable append-only audit log for all operator-initiated refunds.
// Rows are NEVER updated or deleted (NFR-S6 immutable audit trail).

export const operatorRefundLogsTable = pgTable('operator_refund_logs', {
  id: uuid().primaryKey().defaultRandom(),
  chargeEventId: uuid().notNull(),          // FK → charge_events.id
  userId: uuid().notNull(),                 // the user who was charged
  operatorEmail: text().notNull(),          // c.get('operatorEmail') — email string (no operator UUID yet)
  // TODO(impl): resolve operatorEmail to operator UUID once operator accounts table is available
  amountCents: integer().notNull(),         // amount refunded in this action
  reason: text().notNull(),                 // operator-supplied internal reason
  stripeRefundId: text(),                   // TODO(impl): Stripe refunds.id once Stripe is wired
  processedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  // NOTE: No updatedAt — row is intentionally immutable. Never add UPDATE logic to this table.
})
