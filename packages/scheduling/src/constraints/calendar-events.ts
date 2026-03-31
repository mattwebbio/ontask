import type { CalendarEvent, ScheduledBlock } from '@ontask/core'

/**
 * Stub — applyCalendarEventConstraint
 * Full implementation: Story 3.2
 *
 * Removes slots that overlap with existing calendar events.
 */
export function applyCalendarEventConstraint(
  _events: CalendarEvent[],
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  return slots
}
