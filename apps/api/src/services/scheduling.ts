import { schedule } from '@ontask/scheduling'
import type { ScheduleInput, ScheduleOutput } from '@ontask/core'
import { fetchAllCalendarEvents, syncScheduledBlocksToCalendar, removeStaleCalendarBlocks } from './calendar/index.js'

/**
 * RunScheduleResult — the full result of running the scheduling engine,
 * including both the schedule output and the input used to generate it.
 *
 * The GET /v1/tasks/:id/schedule route needs access to both the schedule
 * output and the original input so it can call explain() per-task request.
 */
export interface RunScheduleResult {
  schedule: ScheduleOutput
  scheduleInput: ScheduleInput
}

/**
 * RunScheduleOptions — optional parameters for runScheduleForUser.
 */
export interface RunScheduleOptions {
  /**
   * Optional map of taskId → suggested date from a pre-processed NLP nudge.
   *
   * Merged into ScheduleInput.suggestedDates before the scheduling engine runs.
   * Used by the nudge endpoint (POST /v1/tasks/:id/schedule/nudge) to propose
   * a new time without modifying the task's lockedStartTime (FR14, ARCH-21).
   */
  suggestedDates?: Record<string, Date>
  /**
   * When true, skips the removeStaleCalendarBlocks and syncScheduledBlocksToCalendar
   * calls. Used by the nudge proposal endpoint (POST /v1/tasks/:id/schedule/nudge)
   * to compute a schedule preview without touching the user's calendar (FR14).
   *
   * The confirm endpoint (POST /nudge/confirm) uses the default (false) so the
   * calendar is updated when the change is committed.
   */
  dryRun?: boolean
}

/**
 * runScheduleForUser — orchestrates the scheduling engine for a single user.
 *
 * This is the ONLY place in the codebase that calls `new Date()` for `generatedAt`.
 * The engine itself uses `input.windowStart` as the pure-function stand-in (NFR-Q1).
 *
 * @param userId - The user ID to schedule tasks for
 * @param env - Cloudflare worker bindings
 * @param options - Optional overrides (e.g. suggestedDates from NLP nudge)
 */
export async function runScheduleForUser(
  userId: string,
  env: CloudflareBindings,
  options?: RunScheduleOptions,
): Promise<RunScheduleResult> {
  // TODO(story-impl): load real tasks from DB using userId
  const now = new Date()
  const windowEnd = new Date(now.getTime() + 14 * 24 * 60 * 60_000) // 14 days ahead

  const calendarEvents = await fetchAllCalendarEvents(userId, now, windowEnd, env)

  const scheduleInput: ScheduleInput = {
    tasks: [],
    calendarEvents,
    windowStart: now,
    windowEnd,
    // Merge in any NLP-resolved suggested dates from options (FR14)
    ...(options?.suggestedDates ? { suggestedDates: options.suggestedDates } : {}),
  }

  const result = schedule(scheduleInput)

  if (!options?.dryRun) {
    // Remove blocks for tasks no longer in the schedule (deleted/completed tasks)
    // TODO(story-impl): pass real task IDs when task loading is wired
    const activeTaskIds = result.scheduledBlocks.map((b) => b.taskId)
    await removeStaleCalendarBlocks(userId, activeTaskIds, env)

    // Write scheduled blocks to write-enabled Google Calendar connections (AC1, AC2, NFR-I2)
    // TODO(story-impl): pass real tasks array when task loading is wired (Story 3.4 stub: tasks: [])
    await syncScheduledBlocksToCalendar(userId, result.scheduledBlocks, [], env)
  }

  // The API service layer sets generatedAt — the engine never calls new Date()
  return {
    schedule: { ...result, generatedAt: new Date() },
    scheduleInput,
  }
}
