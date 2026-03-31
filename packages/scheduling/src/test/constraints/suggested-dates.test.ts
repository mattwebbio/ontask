import { describe, it, expect } from 'vitest'
import { applySuggestedDateConstraint } from '../../constraints/suggested-dates.js'

describe('applySuggestedDateConstraint', () => {
  it('schedule_suggestedDate_noSlots_returnsEmpty', () => {
    const suggested = new Date('2026-04-03T00:00:00.000Z')
    expect(applySuggestedDateConstraint(suggested, [])).toEqual([])
  })

  it('schedule_suggestedDate_undefined_returnsSlots', () => {
    const slots = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T09:00:00.000Z'),
        endTime: new Date('2026-04-02T10:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applySuggestedDateConstraint(undefined, slots)).toEqual(slots)
  })

  it('schedule_suggestedDate_withDate_returnsSlots', () => {
    const suggested = new Date('2026-04-03T00:00:00.000Z')
    const slots = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-03T09:00:00.000Z'),
        endTime: new Date('2026-04-03T10:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applySuggestedDateConstraint(suggested, slots)).toEqual(slots)
  })
})
