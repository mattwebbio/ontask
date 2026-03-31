import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

/**
 * applyDueDateConstraint — removes slots whose endTime is after the task's dueDate.
 * If no slots remain after filtering, marks the task as at-risk via constraintNotes.
 * If task has no dueDate, passes all slots through unchanged.
 */
export function applyDueDateConstraint(
  task: ScheduleTask,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  if (!task.dueDate) {
    return slots
  }

  const validSlots = slots.filter((slot) => slot.endTime <= task.dueDate!)

  if (validSlots.length === 0 && slots.length > 0) {
    // No valid slot before due date — mark all remaining slots as at-risk
    return slots.map((slot) => ({
      ...slot,
      isAtRisk: true,
      constraintNotes: `No slot available before due date ${task.dueDate!.toISOString()}`,
    }))
  }

  return validSlots
}
