// ── Notification scheduler ─────────────────────────────────────────────────────
// Runs on every cron tick (*/5 * * * *) to find tasks needing reminder or
// deadline push notifications and dispatches them via sendPush().
// (FR42, FR72, Story 8.2, AC: 1–4)
//
// Three notification types:
//   'reminder'         — task dueDate is within the next REMINDER_LEAD_MINUTES (15 min)
//   'deadline_today'   — task dueDate is today (same calendar date, user's local time)
//   'deadline_tomorrow'— task dueDate is tomorrow
//   'stake_warning'    — task has active stake AND dueDate is within STAKE_WARNING_HOURS (2 h)
//
// Idempotency: INSERT INTO scheduled_notifications (userId, taskId, notificationType, windowKey)
//   ON CONFLICT DO NOTHING — if the row already exists, skip sending.
// CRITICAL: always check scheduled_notifications BEFORE calling sendPush().
//
// Preference enforcement order (AC: 4):
//   1. global off  → skip all notifications for user
//   2. task off    → skip this task's notifications for user
//   3. device off  → skip that specific device token

export const REMINDER_LEAD_MINUTES = 15
export const STAKE_WARNING_HOURS = 2

// ── Pure helper functions (testable, no DB) ────────────────────────────────────

/**
 * Format a timestamp into a human-readable time string (e.g. "9:00 AM").
 * Used in reminder notification body copy.
 */
export function formatTime(date: Date): string {
  const hours = date.getUTCHours()
  const minutes = date.getUTCMinutes()
  const period = hours < 12 ? 'AM' : 'PM'
  const displayHour = hours % 12 === 0 ? 12 : hours % 12
  const paddedMinutes = minutes.toString().padStart(2, '0')
  return `${displayHour}:${paddedMinutes} ${period}`
}

/**
 * Format stake amount in cents to a dollar string (e.g. 1000 → "$10").
 * Used in stake warning notification body copy.
 */
export function formatDollars(cents: number): string {
  const dollars = Math.floor(cents / 100)
  const remainingCents = cents % 100
  if (remainingCents === 0) {
    return `$${dollars}`
  }
  return `$${dollars}.${remainingCents.toString().padStart(2, '0')}`
}

/**
 * Calculate hours until a given future date from now.
 * Used in stake warning copy.
 */
export function hoursUntil(date: Date): number {
  const diffMs = date.getTime() - Date.now()
  return Math.max(0, Math.floor(diffMs / (1000 * 60 * 60)))
}

/**
 * Build the reminder notification body copy.
 * AC 1: "[Task title] is coming up at [time]"
 */
export function buildReminderBody(taskTitle: string, dueDate: Date): string {
  return `${taskTitle} is coming up at ${formatTime(dueDate)}`
}

/**
 * Build the deadline notification body copy.
 * AC 2: "[Task title] is due today" or "[Task title] is due tomorrow"
 */
export function buildDeadlineBody(taskTitle: string, type: 'deadline_today' | 'deadline_tomorrow'): string {
  if (type === 'deadline_today') {
    return `${taskTitle} is due today`
  }
  return `${taskTitle} is due tomorrow`
}

/**
 * Build the stake warning notification body copy (warm tone, UX-DR32).
 * AC 3: "⚠ [Task title] — $[amount] staked, deadline in [X hours]. [Charity] gets half if it's not done."
 */
export function buildStakeWarningBody(
  stakeAmountCents: number,
  hoursRemaining: number,
  charityName: string
): string {
  return `${formatDollars(stakeAmountCents)} staked, deadline in ${hoursRemaining}h. ${charityName} gets half if it's not done.`
}

/**
 * Build the charge notification body copy (affirming tone, UX-DR36).
 * AC 1: "[Task title] — $[amount] charged. [Charity] receives $[charity amount]. Thanks for trying."
 */
export function buildChargeNotificationBody(
  taskTitle: string,
  amountCents: number,
  charityName: string,
  charityAmountCents: number
): string {
  return `${taskTitle} — ${formatDollars(amountCents)} charged. ${charityName} receives ${formatDollars(charityAmountCents)}. Thanks for trying.`
}

/**
 * Build the verification approved notification body copy.
 * AC 2: "[Task title] — proof accepted. Your $[amount] stake is safe."
 */
export function buildVerificationApprovedBody(taskTitle: string, amountCents: number): string {
  return `${taskTitle} — proof accepted. Your ${formatDollars(amountCents)} stake is safe.`
}

/**
 * Build the dispute filed notification body copy.
 * AC 3: "[Task title] — dispute filed. Your stake is on hold while we review."
 */
export function buildDisputeFiledBody(taskTitle: string): string {
  return `${taskTitle} — dispute filed. Your stake is on hold while we review.`
}

/**
 * Build the social completion notification body copy (AC: 1, FR42).
 * "[Name] completed [task title]"
 * Example: "Jordan completed Morning workout"
 */
export function buildSocialCompletionBody(completedByName: string, taskTitle: string): string {
  return `${completedByName} completed ${taskTitle}`
}

/**
 * Build the schedule change notification body copy (AC: 2, FR42).
 * "Your schedule was updated — [X] tasks were rescheduled"
 * Example: "Your schedule was updated — 3 tasks were rescheduled"
 */
export function buildScheduleChangeBody(rescheduledCount: number): string {
  return `Your schedule was updated — ${rescheduledCount} tasks were rescheduled`
}

/**
 * Build the dispute resolved notification body copy (affirming in both outcomes, UX-DR36).
 * AC 4 — approved: "[Task title] — dispute approved. Your $[amount] stake has been cancelled."
 *         rejected: "[Task title] — dispute reviewed. $[amount] charged. [Charity] receives $[charity amount]. Thanks for trying."
 */
export function buildDisputeResolvedBody(
  taskTitle: string,
  approved: boolean,
  amountCents: number,
  charityName: string,
  charityAmountCents: number
): string {
  if (approved) {
    return `${taskTitle} — dispute approved. Your ${formatDollars(amountCents)} stake has been cancelled.`
  }
  return `${taskTitle} — dispute reviewed. ${formatDollars(amountCents)} charged. ${charityName} receives ${formatDollars(charityAmountCents)}. Thanks for trying.`
}

/**
 * Check if a user's preferences allow sending a notification to a specific device.
 * Returns true if the notification should be sent (preference is ON or absent).
 *
 * Preference enforcement order (AC: 4, FR43):
 *   1. global off → skip ALL notifications for user
 *   2. task off   → skip this task's notifications for user
 *   3. device off → skip this specific device token
 */
export function shouldSendNotification(
  preferences: Array<{ scope: string; deviceId: string | null; taskId: string | null; enabled: boolean }>,
  taskId: string,
  deviceToken: string
): boolean {
  // Level 1: global scope — if disabled, suppress all
  const globalPref = preferences.find(p => p.scope === 'global' && p.deviceId === null && p.taskId === null)
  if (globalPref && !globalPref.enabled) {
    return false
  }

  // Level 2: task scope — if this task is disabled, suppress
  const taskPref = preferences.find(p => p.scope === 'task' && p.taskId === taskId)
  if (taskPref && !taskPref.enabled) {
    return false
  }

  // Level 3: device scope — if this device token is disabled, suppress
  const devicePref = preferences.find(p => p.scope === 'device' && p.deviceId === deviceToken)
  if (devicePref && !devicePref.enabled) {
    return false
  }

  return true
}

// ── Scheduled dispatch functions ───────────────────────────────────────────────
// These functions use DB queries and sendPush() — they cannot be unit-tested
// without a real DB. Follow the triggerOverdueCharges() stub pattern:
// the query logic is fully documented in TODO(impl) comments.

/**
 * Send reminder notifications for tasks due in the next REMINDER_LEAD_MINUTES minutes.
 * (AC: 1)
 */
export async function triggerReminderNotifications(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): Query for tasks where:
  //   dueDate BETWEEN NOW() AND NOW() + INTERVAL '15 minutes'
  //   AND completedAt IS NULL
  //   AND archivedAt IS NULL
  //   JOIN device_tokens ON device_tokens.userId = tasks.userId
  //   LEFT JOIN scheduled_notifications sn ON sn.taskId = tasks.id
  //     AND sn.notificationType = 'reminder'
  //     AND sn.windowKey = tasks.dueDate::text
  //   WHERE sn.id IS NULL  -- not yet sent
  //
  // TODO(impl): For each matching task + device token:
  //   1. Query notificationPreferencesTable WHERE userId = task.userId
  //   2. Call shouldSendNotification(prefs, task.id, deviceToken.token)
  //   3. If allowed:
  //      a. INSERT INTO scheduled_notifications
  //           (userId, taskId, notificationType='reminder', windowKey=task.dueDate.toISOString())
  //         ON CONFLICT (userId, taskId, notificationType, windowKey) DO NOTHING
  //         — if 0 rows inserted, skip (already sent)
  //      b. Call sendPush({
  //           deviceToken: deviceToken.token,
  //           environment: deviceToken.environment,
  //           payload: {
  //             title: task.title,
  //             body: buildReminderBody(task.title, task.dueDate),
  //             data: { taskId: task.id, type: 'reminder' },
  //           }
  //         }, env)
  void env
}

/**
 * Send deadline notifications for tasks due today or tomorrow.
 * (AC: 2)
 */
export async function triggerDeadlineNotifications(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): Query tasks where:
  //   DATE(dueDate) = CURRENT_DATE (deadline_today)
  //   OR DATE(dueDate) = CURRENT_DATE + 1 (deadline_tomorrow)
  //   AND completedAt IS NULL
  //   AND archivedAt IS NULL
  //   JOIN device_tokens ON device_tokens.userId = tasks.userId
  //
  // TODO(impl): Idempotency windowKey:
  //   deadline_today:    dueDate.toISOString().split('T')[0] (YYYY-MM-DD)
  //   deadline_tomorrow: dueDate.toISOString().split('T')[0]
  //
  // TODO(impl): For each matching task + device token:
  //   1. Enforce preferences (global → task → device) using shouldSendNotification()
  //   2. INSERT INTO scheduled_notifications
  //        (userId, taskId, notificationType='deadline_today'|'deadline_tomorrow', windowKey)
  //      ON CONFLICT DO NOTHING
  //   3. Call sendPush({
  //        deviceToken: deviceToken.token,
  //        environment: deviceToken.environment,
  //        payload: {
  //          title: task.title,
  //          body: buildDeadlineBody(task.title, notificationType),
  //          data: { taskId: task.id, type: notificationType },
  //        }
  //      }, env)
  void env
}

/**
 * Send stake warning notifications for tasks with active stakes due within STAKE_WARNING_HOURS.
 * (AC: 3) — warm tone per UX-DR32, not punitive.
 */
export async function triggerStakeWarningNotifications(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): Query tasks where:
  //   stakeAmountCents IS NOT NULL
  //   AND dueDate BETWEEN NOW() AND NOW() + INTERVAL '2 hours'
  //   AND completedAt IS NULL
  //   AND archivedAt IS NULL
  //   JOIN device_tokens ON device_tokens.userId = tasks.userId
  //   JOIN commitment_contracts cc ON cc.userId = tasks.userId
  //   LEFT JOIN scheduled_notifications sn ON sn.taskId = tasks.id
  //     AND sn.notificationType = 'stake_warning'
  //     AND sn.windowKey = tasks.dueDate::text
  //   WHERE sn.id IS NULL  -- not yet sent
  //
  // TODO(impl): Idempotency windowKey: task.dueDate.toISOString()
  //
  // TODO(impl): For each matching task + device token:
  //   1. Enforce preferences (global → task → device) using shouldSendNotification()
  //   2. INSERT INTO scheduled_notifications
  //        (userId, taskId, notificationType='stake_warning', windowKey=task.dueDate.toISOString())
  //      ON CONFLICT DO NOTHING
  //   3. Call sendPush({
  //        deviceToken: deviceToken.token,
  //        environment: deviceToken.environment,
  //        payload: {
  //          title: `⚠ ${task.title}`,
  //          body: buildStakeWarningBody(
  //            task.stakeAmountCents,
  //            hoursUntil(task.dueDate),
  //            cc.charityName
  //          ),
  //          data: { taskId: task.id, type: 'stake_warning' },
  //        }
  //      }, env)
  void env
}

/**
 * Send Live Activity push updates for tasks nearing their commitment deadline (within 30 min).
 * Runs on every cron tick (every 5 minutes) with a 25–35 minute look-ahead window.
 * (AC: 2, Story 12.4, ARCH-28)
 */
export async function triggerDeadlineLiveActivityUpdates(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): Query tasks WHERE:
  //   dueDate BETWEEN NOW() + INTERVAL '25 minutes' AND NOW() + INTERVAL '35 minutes'
  //   AND completedAt IS NULL
  //   JOIN live_activity_tokens lat ON lat.taskId = tasks.id
  //     AND lat.activityType IN ('task_timer', 'commitment_countdown')
  //     AND lat.expiresAt > NOW()
  //
  // TODO(impl): For each matching task + token:
  //   const { sendLiveActivityUpdate } = await import('../services/live-activity.js')
  //   const result = await sendLiveActivityUpdate({
  //     pushToken: lat.pushToken,
  //     expiresAt: lat.expiresAt,
  //     event: 'update',
  //     contentState: {
  //       taskTitle: task.title,
  //       deadlineTimestamp: Math.floor(task.dueDate.getTime() / 1000),
  //       stakeAmount: task.stakeAmountCents ? task.stakeAmountCents / 100 : undefined,
  //       activityStatus: 'active',
  //     },
  //     dismissalDate: Math.floor(task.dueDate.getTime() / 1000),
  //   }, env)
  //   If result.tokenExpired → DELETE FROM live_activity_tokens WHERE id = lat.id
  void env
}

/**
 * Delete Live Activity tokens past their expiresAt timestamp.
 * Belt-and-suspenders cleanup — client-side activity end handles most cases,
 * but this catches any tokens left behind when the activity ends unexpectedly.
 * ActivityKit tokens expire with the activity (iOS max 8 hours).
 * Runs on every cron tick (every 5 minutes).
 * (AC: 3, Story 12.4)
 */
export async function cleanupExpiredLiveActivityTokens(env: CloudflareBindings): Promise<void> {
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): DELETE FROM live_activity_tokens WHERE expiresAt < NOW()
  // ActivityKit tokens expire with the activity (max 8h iOS limit).
  // This cleanup runs on every cron tick to prune stale rows.
  void env
}

/**
 * Trigger schedule change notifications when scheduling engine detects ≥ 2 task moves.
 * Called from the scheduling cron / runScheduleForUser post-run hook.
 * (AC: 2, FR42, Story 8.4)
 */
export async function triggerScheduleChangeNotifications(env: CloudflareBindings): Promise<void> {
  // TODO(impl): Trigger schedule change notifications when scheduling engine detects ≥ 2 task moves.
  // This function is called from the scheduling cron / runScheduleForUser post-run hook.
  //
  // TODO(impl): const db = createDb(env.DATABASE_URL)
  // TODO(impl): Query for users whose schedule was regenerated in the last cron window:
  //   - Detect "meaningful changes" = hasMeaningfulChanges=true AND changeCount >= 2
  //     (mirrors the hasMeaningfulChanges field in GET /v1/tasks/schedule-changes)
  //   - Source: compare current schedule snapshot vs. previous snapshot stored per user
  //     (storage mechanism TBD in Epic 3; for now document the intent)
  //
  // TODO(impl): For each user with meaningful changes:
  //   1. Query device_tokens WHERE userId = userId
  //   2. Query notification_preferences WHERE userId = userId
  //   3. For each device token: enforce preferences using shouldSendNotification()
  //      (no taskId for schedule-change notifications — pass null; preference
  //       check at global + device levels only, no per-task level applies here)
  //   4. await sendPush({
  //        deviceToken: token.token,
  //        environment: token.environment,
  //        payload: {
  //          title: 'Schedule Updated',
  //          body: buildScheduleChangeBody(changeCount),
  //          data: { type: 'schedule_change', changeCount: String(changeCount) },
  //        }
  //      }, env)
  //
  // NOTE: Deep-link — data.type='schedule_change' should navigate to Today tab
  //       with ScheduleChangeBannerVisible triggered (see notification_handler.dart).
  // NOTE: Idempotency — store a schedule_change_notified_at timestamp per user
  //       to avoid re-sending if cron fires again before next schedule regeneration.
  void env
}
