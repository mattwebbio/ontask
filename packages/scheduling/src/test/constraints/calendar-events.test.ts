import { describe, it, expect } from 'vitest'
import type { CalendarEvent } from '@ontask/core'
import { applyCalendarEventConstraint } from '../../constraints/calendar-events.js'

describe('applyCalendarEventConstraint', () => {
  it('schedule_calendarEvents_noSlots_returnsEmpty', () => {
    const events: CalendarEvent[] = []
    expect(applyCalendarEventConstraint(events, [])).toEqual([])
  })

  it('schedule_calendarEvents_withBusyEvent_returnsSlots', () => {
    const events: CalendarEvent[] = [
      {
        id: 'event-1',
        startTime: new Date('2026-04-02T10:00:00.000Z'),
        endTime: new Date('2026-04-02T11:00:00.000Z'),
        isAllDay: false,
      },
    ]
    const slots = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T09:00:00.000Z'),
        endTime: new Date('2026-04-02T10:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyCalendarEventConstraint(events, slots)).toEqual(slots)
  })
})
