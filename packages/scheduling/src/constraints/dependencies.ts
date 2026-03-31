import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

/**
 * applyDependencyConstraint (FR73) — ensures a task's slot starts only after all
 * dependsOnTaskIds have been scheduled. Takes the currently accumulated scheduledBlocks
 * so the constraint knows what has been placed so far.
 *
 * - If a dependency has not been scheduled yet (not in scheduledBlocks), returns []
 *   (task will go to unscheduledTaskIds).
 * - If all dependencies are scheduled, removes any slot that starts before the latest
 *   endTime of all dependency blocks.
 */
export function applyDependencyConstraint(
  task: ScheduleTask,
  scheduledBlocks: ScheduledBlock[],
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  if (!task.dependsOnTaskIds || task.dependsOnTaskIds.length === 0) {
    return slots
  }

  const scheduledBlockMap = new Map<string, ScheduledBlock>()
  for (const block of scheduledBlocks) {
    scheduledBlockMap.set(block.taskId, block)
  }

  let latestDependencyEndTime: Date | null = null

  for (const depId of task.dependsOnTaskIds) {
    const depBlock = scheduledBlockMap.get(depId)
    if (!depBlock) {
      // Dependency not yet scheduled — constraint is unresolvable
      return []
    }
    if (latestDependencyEndTime === null || depBlock.endTime > latestDependencyEndTime) {
      latestDependencyEndTime = depBlock.endTime
    }
  }

  return slots.filter((slot) => slot.startTime >= latestDependencyEndTime!)
}
