import { pgTable, uuid, text, timestamp, boolean, unique } from 'drizzle-orm/pg-core'

// ── Scheduled notifications table ─────────────────────────────────────────────
// Tracks which notifications have been sent to prevent duplicate delivery
// across cron runs. (FR42, FR72, Story 8.2)
//
// notificationType: 'reminder' | 'deadline_today' | 'deadline_tomorrow' | 'stake_warning'
// Idempotency key: (userId, taskId, notificationType, windowKey)
//   windowKey for 'reminder': ISO date string of the scheduled dueDate (e.g. '2026-04-01T09:00:00Z')
//   windowKey for 'deadline_today'/'deadline_tomorrow': date string of the due date (e.g. '2026-04-01')
//   windowKey for 'stake_warning': ISO date string of the task dueDate
// sentAt: when the notification was dispatched
// failed: true if the send attempt failed (APNs UNREGISTERED or other error)

export const scheduledNotificationsTable = pgTable('scheduled_notifications', {
  id: uuid().primaryKey().defaultRandom(),
  userId: uuid().notNull(),
  taskId: uuid().notNull(),
  notificationType: text().notNull(),  // 'reminder' | 'deadline_today' | 'deadline_tomorrow' | 'stake_warning'
  windowKey: text().notNull(),         // dedup key per notification window
  sentAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  failed: boolean().notNull().default(false),
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('scheduled_notifications_user_task_type_window_unique').on(
    table.userId, table.taskId, table.notificationType, table.windowKey
  ),
])
