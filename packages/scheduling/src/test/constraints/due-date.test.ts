import { describe, it, expect } from 'vitest'
import type { ScheduleTask } from '@ontask/core'
import { applyDueDateConstraint } from '../../constraints/due-date.js'

describe('applyDueDateConstraint', () => {
  it('schedule_dueDate_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test' }
    expect(applyDueDateConstraint(task, [])).toEqual([])
  })

  it('schedule_dueDate_withSlots_returnsSlots', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Test',
      dueDate: new Date('2026-04-05T00:00:00.000Z'),
    }
    const slots = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T09:00:00.000Z'),
        endTime: new Date('2026-04-02T10:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyDueDateConstraint(task, slots)).toEqual(slots)
  })
})
