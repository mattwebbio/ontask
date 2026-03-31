import type { ScheduleInput, ScheduleOutput } from '@ontask/core'

/**
 * Stub — roundRobinStrategy (FR17)
 * Full implementation: Story 3.2
 *
 * Distributes tasks evenly across available time slots in a round-robin fashion.
 */
export function roundRobinStrategy(_input: ScheduleInput): ScheduleOutput {
  return {
    scheduledBlocks: [],
    unscheduledTaskIds: _input.tasks.map((t) => t.id),
    generatedAt: _input.windowStart,
  }
}
