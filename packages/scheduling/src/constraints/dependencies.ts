import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

/**
 * Stub — applyDependencyConstraint (FR73)
 * Full implementation: Story 3.2
 *
 * Ensures a task's slot starts only after all dependsOnTaskIds are scheduled.
 */
export function applyDependencyConstraint(
  _task: ScheduleTask,
  _allTasks: ScheduleTask[],
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  return slots
}
