import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── Live Activity Tokens table ────────────────────────────────────────────────
// Stores ActivityKit push tokens for server-initiated Live Activity updates.
// (Epic 12, Story 12.1, ARCH-28)
//
// IMPORTANT: These are ActivityKit push tokens — NOT the same as APNs device
// tokens stored in device_tokens. Each Live Activity instance has its own token.
// Tokens are scoped per (userId, taskId, activityType) — upsert on this triple.
// Tokens expire when the activity ends (iOS max 8 hours).
//
// apns-push-type for server updates: 'liveactivity' (NOT 'alert')
// apns-topic for server updates: 'com.ontaskhq.ontask.push-type.liveactivity'
//
// Upsert strategy: on conflict (userId, taskId, activityType) DO UPDATE SET
//   pushToken, createdAt, expiresAt
// Stale token handling: on APNs HTTP 410 response, DELETE the row (Story 12.4).

export const liveActivityTokensTable = pgTable('live_activity_tokens', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),                          // FK → users
  taskId: uuid(),                                    // FK → tasks; null for non-task activities
  activityType: text().notNull(),                    // 'task_timer' | 'commitment_countdown' | 'watch_mode'
  pushToken: text().notNull(),                       // ActivityKit push token from client
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp({ withTimezone: true }).notNull(), // ActivityKit tokens expire with the activity (max 8h)
})
