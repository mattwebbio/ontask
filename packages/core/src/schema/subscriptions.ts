import { pgTable, text, timestamp } from 'drizzle-orm/pg-core'

// Subscription / trial state for each user.
// One row per user — upserted on account creation (trial) and on subscription activation.
// FR82: trial starts at account creation; FR85: data retained 30 days post-trial expiry.
export const subscriptionsTable = pgTable('subscriptions', {
  userId: text('user_id').primaryKey(),                            // FK to users (add FK when users table created)
  status: text('status').notNull(),                               // 'trialing' | 'active' | 'cancelled' | 'expired' | 'grace_period'
  trialStartedAt: timestamp('trial_started_at', { withTimezone: true }).notNull(),
  trialEndsAt: timestamp('trial_ends_at', { withTimezone: true }).notNull(),
  // Populated on subscription activation (Story 9.3 / 13.1):
  stripeCustomerId: text('stripe_customer_id'),              // Stripe customer ID (may mirror commitment_contracts)
  stripeSubscriptionId: text('stripe_subscription_id'),
  stripePriceId: text('stripe_price_id'),
  tier: text('tier'),                                        // 'individual' | 'couple' | 'family'
  currentPeriodStart: timestamp('current_period_start', { withTimezone: true }),
  currentPeriodEnd: timestamp('current_period_end', { withTimezone: true }),
  cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
  // 30-day data retention window after trial expires (FR85):
  dataRetentionDeadline: timestamp('data_retention_deadline', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
})
