import { pgTable, uuid, text, boolean, timestamp } from 'drizzle-orm/pg-core'

// ── Notification preferences table ───────────────────────────────────────────
// Three-level configurable preferences (FR43, Story 8.1, UX §Notifications):
//   scope='global'  → userId set, deviceId null, taskId null   — all notifications on/off
//   scope='device'  → userId set, deviceId set, taskId null    — per-device preference
//   scope='task'    → userId set, deviceId null, taskId set    — per-task remind/don't
// enabled: true = notifications on; false = suppressed for this scope.
// Unique constraint: (userId, scope, deviceId, taskId) — enforced at application level
// for now (add DB unique index in hardening pass once real data exists).

export const notificationPreferencesTable = pgTable('notification_preferences', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),                          // FK → users
  scope: text().notNull(),                           // 'global' | 'device' | 'task'
  deviceId: text(),                                  // device token or stable device identifier; null for global/task scope
  taskId: uuid(),                                    // FK → tasks; null for global/device scope
  enabled: boolean().notNull().default(true),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
})
