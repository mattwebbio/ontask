import type { ScheduleInput, ScheduleOutput } from '@ontask/core'

/**
 * Stub — leastBusyStrategy (FR17)
 * Full implementation: Story 3.2
 *
 * Places tasks in the time windows with fewest existing calendar events.
 */
export function leastBusyStrategy(input: ScheduleInput): ScheduleOutput {
  return {
    scheduledBlocks: [],
    unscheduledTaskIds: input.tasks.map((t) => t.id),
    generatedAt: input.windowStart,
  }
}
