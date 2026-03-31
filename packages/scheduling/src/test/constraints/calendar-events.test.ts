import { describe, it, expect } from 'vitest'
import type { CalendarEvent, ScheduledBlock } from '@ontask/core'
import { applyCalendarEventConstraint } from '../../constraints/calendar-events.js'

const makeSlot = (start: string, end: string): ScheduledBlock => ({
  taskId: 'task-1',
  startTime: new Date(start),
  endTime: new Date(end),
  isLocked: false,
  isAtRisk: false,
})

const makeEvent = (start: string, end: string): CalendarEvent => ({
  id: 'event-1',
  startTime: new Date(start),
  endTime: new Date(end),
  isAllDay: false,
})

describe('applyCalendarEventConstraint', () => {
  it('schedule_calendarEvents_noSlots_returnsEmpty', () => {
    expect(applyCalendarEventConstraint([], [])).toEqual([])
  })

  it('schedule_calendarEvents_noEvents_passesThrough', () => {
    const slots = [makeSlot('2026-04-02T09:00:00.000Z', '2026-04-02T09:30:00.000Z')]
    expect(applyCalendarEventConstraint([], slots)).toEqual(slots)
  })

  it('schedule_calendarEvent_overlappingSlot_removed', () => {
    // Event: 09:00–10:00. Slot: 09:00–09:30 — overlaps → removed
    const event = makeEvent('2026-04-02T09:00:00.000Z', '2026-04-02T10:00:00.000Z')
    const slot = makeSlot('2026-04-02T09:00:00.000Z', '2026-04-02T09:30:00.000Z')
    const result = applyCalendarEventConstraint([event], [slot])
    expect(result).toHaveLength(0)
  })

  it('schedule_calendarEvent_partialOverlapSlot_removed', () => {
    // Event: 09:15–10:00. Slot: 09:00–09:30 — partial overlap → removed
    const event = makeEvent('2026-04-02T09:15:00.000Z', '2026-04-02T10:00:00.000Z')
    const slot = makeSlot('2026-04-02T09:00:00.000Z', '2026-04-02T09:30:00.000Z')
    const result = applyCalendarEventConstraint([event], [slot])
    expect(result).toHaveLength(0)
  })

  it('schedule_calendarEvent_adjacentSlot_retained', () => {
    // Event: 09:00–10:00. Slot: 10:00–10:30 — adjacent, no overlap → kept
    const event = makeEvent('2026-04-02T09:00:00.000Z', '2026-04-02T10:00:00.000Z')
    const slot = makeSlot('2026-04-02T10:00:00.000Z', '2026-04-02T10:30:00.000Z')
    const result = applyCalendarEventConstraint([event], [slot])
    expect(result).toEqual([slot])
  })

  it('schedule_calendarEvent_slotBeforeEvent_retained', () => {
    // Event: 10:00–11:00. Slot: 09:00–09:30 — before event → kept
    const event = makeEvent('2026-04-02T10:00:00.000Z', '2026-04-02T11:00:00.000Z')
    const slot = makeSlot('2026-04-02T09:00:00.000Z', '2026-04-02T09:30:00.000Z')
    const result = applyCalendarEventConstraint([event], [slot])
    expect(result).toEqual([slot])
  })
})
