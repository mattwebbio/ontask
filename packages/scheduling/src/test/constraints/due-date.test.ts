import { describe, it, expect } from 'vitest'
import type { ScheduleTask, ScheduledBlock } from '@ontask/core'
import { applyDueDateConstraint } from '../../constraints/due-date.js'

const makeSlot = (start: string, end: string): ScheduledBlock => ({
  taskId: 'task-1',
  startTime: new Date(start),
  endTime: new Date(end),
  isLocked: false,
  isAtRisk: false,
})

describe('applyDueDateConstraint', () => {
  it('schedule_dueDate_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test' }
    expect(applyDueDateConstraint(task, [])).toEqual([])
  })

  it('schedule_dueDate_noDueDate_passesThrough', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test' }
    const slots = [makeSlot('2026-04-02T09:00:00.000Z', '2026-04-02T09:30:00.000Z')]
    expect(applyDueDateConstraint(task, slots)).toEqual(slots)
  })

  it('schedule_dueDate_slotBeforeDueDate_retained', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Test',
      dueDate: new Date('2026-04-05T00:00:00.000Z'),
    }
    const slot = makeSlot('2026-04-02T09:00:00.000Z', '2026-04-02T09:30:00.000Z')
    expect(applyDueDateConstraint(task, [slot])).toEqual([slot])
  })

  it('schedule_dueDate_slotAfterDueDate_removed', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Test',
      dueDate: new Date('2026-04-05T10:00:00.000Z'),
    }
    // slotGood ends before due date — retained
    const slotGood = makeSlot('2026-04-03T09:00:00.000Z', '2026-04-03T09:30:00.000Z')
    // slotBad ends after due date — removed
    const slotBad = makeSlot('2026-04-05T09:30:00.000Z', '2026-04-05T10:30:00.000Z')
    const result = applyDueDateConstraint(task, [slotGood, slotBad])
    expect(result).toHaveLength(1)
    expect(result[0]).toEqual(slotGood)
  })

  it('schedule_dueDate_noSlotBeforeDue_markedAtRisk', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Test',
      dueDate: new Date('2026-04-02T09:00:00.000Z'),
    }
    // All slots are after the due date — should return them marked as at-risk
    const slot1 = makeSlot('2026-04-03T09:00:00.000Z', '2026-04-03T09:30:00.000Z')
    const slot2 = makeSlot('2026-04-04T09:00:00.000Z', '2026-04-04T09:30:00.000Z')
    const result = applyDueDateConstraint(task, [slot1, slot2])
    expect(result).toHaveLength(2)
    expect(result[0].isAtRisk).toBe(true)
    expect(result[1].isAtRisk).toBe(true)
    expect(result[0].constraintNotes).toContain('No slot available before due date')
  })
})
