import type { ScheduleInput, ScheduleOutput } from '@ontask/core'

/**
 * Stub — aiAssistedStrategy (FR17)
 * Full implementation: Story 3.2
 *
 * Uses AI-derived scoring to rank time slots for each task.
 * NOTE: The strategy itself remains a pure function — the AI scores are
 * pre-computed and passed in via ScheduleInput; this function has no external calls.
 */
export function aiAssistedStrategy(_input: ScheduleInput): ScheduleOutput {
  return {
    scheduledBlocks: [],
    unscheduledTaskIds: _input.tasks.map((t) => t.id),
    generatedAt: _input.windowStart,
  }
}
