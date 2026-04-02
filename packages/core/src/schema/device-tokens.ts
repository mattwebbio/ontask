import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Device tokens table ───────────────────────────────────────────────────────
// Stores APNs device tokens for push notification delivery (FR42, Story 8.1).
// platform: 'ios' | 'macos' — derived from build target, never guessed
// environment: 'development' | 'production' — debug builds use development;
//   TestFlight and App Store use production (DEPLOY-4).
// Upsert strategy: on conflict (userId, token) DO UPDATE SET environment, updatedAt.
// Tokens become stale when user reinstalls or revokes permissions —
//   handle apns error UNREGISTERED by deleting the row in push service.

export const deviceTokensTable = pgTable('device_tokens', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),                          // FK → users
  token: text().notNull(),                           // APNs device push token
  platform: text().notNull(),                        // 'ios' | 'macos'
  environment: text().notNull(),                     // 'development' | 'production'
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
