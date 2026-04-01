import { schedule } from '@ontask/scheduling'
import type { ScheduleOutput } from '@ontask/core'
import { fetchAllCalendarEvents } from './calendar/index.js'

/**
 * runScheduleForUser — orchestrates the scheduling engine for a single user.
 *
 * This is the ONLY place in the codebase that calls `new Date()` for `generatedAt`.
 * The engine itself uses `input.windowStart` as the pure-function stand-in (NFR-Q1).
 *
 * @param userId - The user ID to schedule tasks for
 * @param env - Cloudflare worker bindings
 */
export async function runScheduleForUser(
  userId: string,
  env: CloudflareBindings,
): Promise<ScheduleOutput> {
  // TODO(story-impl): load real tasks from DB using userId
  const now = new Date()
  const windowEnd = new Date(now.getTime() + 14 * 24 * 60 * 60_000) // 14 days ahead

  const calendarEvents = await fetchAllCalendarEvents(userId, now, windowEnd, env)

  const result = schedule({
    tasks: [],
    calendarEvents,
    windowStart: now,
    windowEnd,
  })

  // The API service layer sets generatedAt — the engine never calls new Date()
  return { ...result, generatedAt: new Date() }
}
