import { schedule } from '@ontask/scheduling'
import type { ScheduleOutput } from '@ontask/core'

/**
 * runScheduleForUser — orchestrates the scheduling engine for a single user.
 *
 * This is the ONLY place in the codebase that calls `new Date()` for `generatedAt`.
 * The engine itself uses `input.windowStart` as the pure-function stand-in (NFR-Q1).
 *
 * @param userId - The user ID to schedule tasks for (unused until Story 3.3 loads real DB data)
 * @param env - Cloudflare worker bindings (unused until Story 3.3)
 */
export async function runScheduleForUser(
  userId: string,
  env: CloudflareBindings,
): Promise<ScheduleOutput> {
  void userId
  void env

  // TODO(story-3.3): load real calendar events from DB (Google Calendar integration)
  // TODO(story-impl): load real tasks from DB using userId
  const now = new Date()
  const windowEnd = new Date(now.getTime() + 14 * 24 * 60 * 60_000) // 14 days ahead

  const result = schedule({
    tasks: [],
    calendarEvents: [],
    windowStart: now,
    windowEnd,
  })

  // The API service layer sets generatedAt — the engine never calls new Date()
  return { ...result, generatedAt: new Date() }
}
