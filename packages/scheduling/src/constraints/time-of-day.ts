import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

/**
 * Stub — applyTimeOfDayConstraint
 * Full implementation: Story 3.2
 *
 * Filters slots to respect a task's timeWindow preference (morning/afternoon/evening/custom).
 */
export function applyTimeOfDayConstraint(
  _task: ScheduleTask,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  return slots
}
