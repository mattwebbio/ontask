import type { ScheduledBlock } from '@ontask/core'

/**
 * Stub — applySuggestedDateConstraint (FR14)
 * Full implementation: Story 3.2
 *
 * Nudges slot selection toward a user-suggested date for a given task.
 */
export function applySuggestedDateConstraint(
  _suggested: Date | undefined,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  return slots
}
