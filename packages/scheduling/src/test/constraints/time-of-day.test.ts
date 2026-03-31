import { describe, it, expect } from 'vitest'
import type { ScheduleTask } from '@ontask/core'
import { applyTimeOfDayConstraint } from '../../constraints/time-of-day.js'

describe('applyTimeOfDayConstraint', () => {
  it('schedule_timeConstraint_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', timeWindow: 'morning' }
    expect(applyTimeOfDayConstraint(task, [])).toEqual([])
  })

  it('schedule_timeConstraint_withSlots_returnsSlots', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', timeWindow: 'afternoon' }
    const slots = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T13:00:00.000Z'),
        endTime: new Date('2026-04-02T14:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyTimeOfDayConstraint(task, slots)).toEqual(slots)
  })
})
