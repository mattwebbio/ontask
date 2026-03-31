import { describe, it, expect } from 'vitest'
import type { ScheduleTask, ScheduledBlock } from '@ontask/core'
import { applyTimeOfDayConstraint } from '../../constraints/time-of-day.js'

const makeSlot = (startHourUTC: number): ScheduledBlock => {
  const start = new Date(`2026-04-02T${String(startHourUTC).padStart(2, '0')}:00:00.000Z`)
  const end = new Date(start.getTime() + 30 * 60_000)
  return { taskId: 'task-1', startTime: start, endTime: end, isLocked: false, isAtRisk: false }
}

describe('applyTimeOfDayConstraint', () => {
  it('schedule_timeConstraint_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', timeWindow: 'morning' }
    expect(applyTimeOfDayConstraint(task, [])).toEqual([])
  })

  it('schedule_timeOfDay_noWindow_passesThrough', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test' }
    const slots = [makeSlot(9), makeSlot(14), makeSlot(19)]
    expect(applyTimeOfDayConstraint(task, slots)).toEqual(slots)
  })

  it('schedule_timeOfDay_morningWindow_filtersToMorning', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', timeWindow: 'morning' }
    // morning = 06:00–12:00 UTC
    const morning = makeSlot(6)   // 06:00 — in morning
    const late = makeSlot(9)      // 09:00 — in morning
    const noon = makeSlot(12)     // 12:00 — NOT in morning (exclusive end)
    const afternoon = makeSlot(14) // 14:00 — not morning
    const result = applyTimeOfDayConstraint(task, [morning, late, noon, afternoon])
    expect(result).toEqual([morning, late])
  })

  it('schedule_timeOfDay_afternoonWindow_filtersToAfternoon', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', timeWindow: 'afternoon' }
    // afternoon = 12:00–17:00 UTC
    const morning = makeSlot(9)    // not afternoon
    const noon = makeSlot(12)      // 12:00 — in afternoon
    const afternoon = makeSlot(14) // 14:00 — in afternoon
    const evening = makeSlot(17)   // 17:00 — NOT afternoon (exclusive end)
    const result = applyTimeOfDayConstraint(task, [morning, noon, afternoon, evening])
    expect(result).toEqual([noon, afternoon])
  })

  it('schedule_timeOfDay_eveningWindow_filtersToEvening', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', timeWindow: 'evening' }
    // evening = 17:00–21:00 UTC
    const afternoon = makeSlot(14)  // not evening
    const evening = makeSlot(17)    // 17:00 — in evening
    const lateEvening = makeSlot(20) // 20:00 — in evening
    const night = makeSlot(21)       // 21:00 — NOT evening (exclusive end)
    const result = applyTimeOfDayConstraint(task, [afternoon, evening, lateEvening, night])
    expect(result).toEqual([evening, lateEvening])
  })

  it('schedule_timeOfDay_customWindow_filtersToRange', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Test',
      timeWindow: 'custom',
      timeWindowStart: '08:00',
      timeWindowEnd: '10:00',
    }
    const before = makeSlot(7)   // 07:00 — before range
    const start = makeSlot(8)    // 08:00 — in range
    const mid = makeSlot(9)      // 09:00 — in range
    const end = makeSlot(10)     // 10:00 — NOT in range (exclusive end)
    const after = makeSlot(11)   // 11:00 — after range
    const result = applyTimeOfDayConstraint(task, [before, start, mid, end, after])
    expect(result).toEqual([start, mid])
  })

  it('schedule_timeOfDay_customWindowNoRange_passesThrough', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Test',
      timeWindow: 'custom',
      // No timeWindowStart/timeWindowEnd set
    }
    const slots = [makeSlot(9), makeSlot(14)]
    expect(applyTimeOfDayConstraint(task, slots)).toEqual(slots)
  })
})
