import type { CalendarEvent, ScheduledBlock } from '@ontask/core'

/**
 * applyCalendarEventConstraint — removes slots that overlap any calendar event.
 * Overlap condition: slot.startTime < event.endTime && slot.endTime > event.startTime
 */
export function applyCalendarEventConstraint(
  events: CalendarEvent[],
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  if (events.length === 0) {
    return slots
  }

  return slots.filter((slot) => {
    for (const event of events) {
      const overlaps = slot.startTime < event.endTime && slot.endTime > event.startTime
      if (overlaps) {
        return false
      }
    }
    return true
  })
}
