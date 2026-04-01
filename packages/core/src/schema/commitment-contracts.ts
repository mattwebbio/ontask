import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'

// ── Commitment contracts table ───────────────────────────────────────────────
// Stores per-user payment method metadata for commitment stakes (Epic 6).
// Raw card data never stored — only Stripe references and display metadata
// (last4, brand) for PCI SAQ A compliance (NFR-S2).

export const commitmentContractsTable = pgTable('commitment_contracts', {
  id: uuid().primaryKey().defaultRandom(),
  // TODO(story-TBD): Add FK constraint to users table when it exists
  userId: uuid().notNull(),
  stripeCustomerId: text(),
  stripePaymentMethodId: text(),
  paymentMethodLast4: text(),
  paymentMethodBrand: text(),
  hasActiveStakes: boolean().default(false).notNull(),
  charityId: text(),
  charityName: text(),
  setupSessionToken: text(),
  setupSessionExpiresAt: timestamp({ withTimezone: true }),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
