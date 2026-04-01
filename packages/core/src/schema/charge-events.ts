import { pgTable, uuid, text, integer, timestamp } from 'drizzle-orm/pg-core'

// ── Charge events table ──────────────────────────────────────────────────────
// Records every commitment charge attempt and disbursement result.
// Idempotency key (charge-{taskId}-{userId}) prevents double-charging across
// Cloudflare Queue retries and Stripe webhook re-deliveries (NFR-R1, NFR-R2).

export const chargeEventsTable = pgTable('charge_events', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),
  taskId: uuid().notNull(),
  idempotencyKey: text().notNull().unique(), // prevents double-charge; format: `charge-{taskId}-{userId}`
  stripePaymentIntentId: text(),             // set after Stripe confirms
  amountCents: integer().notNull(),          // total charge amount
  charityAmountCents: integer().notNull(),   // 50% of amountCents
  platformAmountCents: integer().notNull(),  // 50% of amountCents
  charityId: text().notNull(),               // Every.org nonprofit identifier
  charityName: text().notNull(),             // display name for reporting
  status: text().notNull(),                  // 'pending' | 'charged' | 'failed' | 'disbursed' | 'disbursement_failed'
  stripeError: text(),                       // last Stripe error message (if failed)
  disbursementError: text(),                 // last Every.org error message (if disbursement_failed)
  chargedAt: timestamp({ withTimezone: true }),     // when Stripe charge succeeded
  disbursedAt: timestamp({ withTimezone: true }),   // when Every.org disbursement succeeded
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
