import type { ScheduleTask, ScheduledBlock } from '@ontask/core'

// Time window boundaries in hours (UTC-local agnostic — uses Date hours directly)
const MORNING_START = 6
const MORNING_END = 12
const AFTERNOON_START = 12
const AFTERNOON_END = 17
const EVENING_START = 17
const EVENING_END = 21

/**
 * applyTimeOfDayConstraint — filters slots to match the task's timeWindow.
 * morning = 06:00–12:00, afternoon = 12:00–17:00, evening = 17:00–21:00,
 * custom = task.timeWindowStart–task.timeWindowEnd (HH:mm).
 * If timeWindow is not set or undefined, passes all slots through unchanged.
 */
export function applyTimeOfDayConstraint(
  task: ScheduleTask,
  slots: ScheduledBlock[],
): ScheduledBlock[] {
  if (!task.timeWindow) {
    return slots
  }

  if (task.timeWindow === 'custom') {
    if (!task.timeWindowStart || !task.timeWindowEnd) {
      // No custom range defined — pass through
      return slots
    }
    const [startHour, startMin] = task.timeWindowStart.split(':').map(Number)
    const [endHour, endMin] = task.timeWindowEnd.split(':').map(Number)
    const startMinutes = startHour * 60 + startMin
    const endMinutes = endHour * 60 + endMin

    return slots.filter((slot) => {
      const slotStartMinutes = slot.startTime.getUTCHours() * 60 + slot.startTime.getUTCMinutes()
      return slotStartMinutes >= startMinutes && slotStartMinutes < endMinutes
    })
  }

  const windowBounds: Record<string, [number, number]> = {
    morning: [MORNING_START, MORNING_END],
    afternoon: [AFTERNOON_START, AFTERNOON_END],
    evening: [EVENING_START, EVENING_END],
  }

  const [windowStart, windowEnd] = windowBounds[task.timeWindow]

  return slots.filter((slot) => {
    const slotHour = slot.startTime.getUTCHours()
    return slotHour >= windowStart && slotHour < windowEnd
  })
}
