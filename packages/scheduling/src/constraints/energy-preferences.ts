import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

/**
 * applyEnergyPreferenceConstraint — reorders (not filters) slots based on energyRequirement.
 * high_focus: prefer slots before noon (first half of day — sorted earliest first)
 * low_energy: prefer afternoon/evening (sorted latest in day first, i.e. >= 12:00)
 * flexible or unset: passes all slots through unchanged (no reorder)
 *
 * This is a soft preference — no slots are dropped.
 */
export function applyEnergyPreferenceConstraint(
  task: ScheduleTask,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  if (!task.energyRequirement || task.energyRequirement === 'flexible') {
    return slots
  }

  if (task.energyRequirement === 'high_focus') {
    // Sort: morning slots (before 12:00 UTC) first, then the rest in chronological order.
    return [...slots].sort((a, b) => {
      const aIsMorning = a.startTime.getUTCHours() < 12
      const bIsMorning = b.startTime.getUTCHours() < 12
      // morning slots come before non-morning slots; within each group sort by time
      if (aIsMorning !== bIsMorning) return aIsMorning ? -1 : 1
      return a.startTime.getTime() - b.startTime.getTime()
    })
  }

  // low_energy: sort afternoon/evening slots (>= 12:00 UTC) first
  return [...slots].sort((a, b) => {
    const aIsAfternoon = a.startTime.getUTCHours() >= 12
    const bIsAfternoon = b.startTime.getUTCHours() >= 12
    // afternoon slots come before morning slots; within each group sort by time
    if (aIsAfternoon !== bIsAfternoon) return aIsAfternoon ? -1 : 1
    return a.startTime.getTime() - b.startTime.getTime()
  })
}
