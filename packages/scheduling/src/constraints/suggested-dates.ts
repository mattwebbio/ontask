import type { ScheduledBlock } from '@ontask/core'

/**
 * applySuggestedDateConstraint (FR14) — nudges slot selection toward a user-suggested date.
 * If suggested is defined, reorders slots so those on or after the suggested date appear first.
 * Slots before the suggested date are NOT filtered out — this is a soft preference.
 * If suggested is undefined, passes all slots through unchanged.
 */
export function applySuggestedDateConstraint(
  suggested: Date | undefined,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  if (!suggested) {
    return slots
  }

  const suggestedTime = suggested.getTime()

  // Stable partition: slots on/after suggested date first, then slots before
  const onOrAfter = slots.filter((slot) => slot.startTime.getTime() >= suggestedTime)
  const before = slots.filter((slot) => slot.startTime.getTime() < suggestedTime)

  return [...onOrAfter, ...before]
}
