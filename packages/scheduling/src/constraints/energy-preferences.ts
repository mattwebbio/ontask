import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

/**
 * Stub — applyEnergyPreferenceConstraint
 * Full implementation: Story 3.2
 *
 * Prioritises or filters slots based on a task's energyRequirement.
 */
export function applyEnergyPreferenceConstraint(
  _task: ScheduleTask,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  return slots
}
