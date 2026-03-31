import { describe, it, expect } from 'vitest'
import type { ScheduledBlock } from '@ontask/core'
import { applySuggestedDateConstraint } from '../../constraints/suggested-dates.js'

const makeSlot = (start: string): ScheduledBlock => ({
  taskId: 'task-1',
  startTime: new Date(start),
  endTime: new Date(new Date(start).getTime() + 30 * 60_000),
  isLocked: false,
  isAtRisk: false,
})

describe('applySuggestedDateConstraint', () => {
  it('schedule_suggestedDate_noSlots_returnsEmpty', () => {
    const suggested = new Date('2026-04-03T00:00:00.000Z')
    expect(applySuggestedDateConstraint(suggested, [])).toEqual([])
  })

  it('schedule_suggestedDate_undefined_passesThrough', () => {
    const slots = [makeSlot('2026-04-02T09:00:00.000Z')]
    expect(applySuggestedDateConstraint(undefined, slots)).toEqual(slots)
  })

  it('schedule_suggestedDate_withDate_returnsSlots', () => {
    const suggested = new Date('2026-04-03T00:00:00.000Z')
    const slot = makeSlot('2026-04-03T09:00:00.000Z')
    expect(applySuggestedDateConstraint(suggested, [slot])).toEqual([slot])
  })

  it('schedule_suggestedDate_defined_reordersToSuggestedFirst', () => {
    const suggested = new Date('2026-04-03T00:00:00.000Z')

    const before1 = makeSlot('2026-04-01T09:00:00.000Z')  // before suggested
    const before2 = makeSlot('2026-04-02T09:00:00.000Z')  // before suggested
    const onDay = makeSlot('2026-04-03T09:00:00.000Z')    // on suggested date
    const after = makeSlot('2026-04-04T09:00:00.000Z')    // after suggested

    const result = applySuggestedDateConstraint(suggested, [before1, before2, onDay, after])

    // Slots on/after suggested date should appear first
    expect(result[0].startTime).toEqual(onDay.startTime)
    expect(result[1].startTime).toEqual(after.startTime)
    // Slots before suggested date are still present (not filtered)
    expect(result).toHaveLength(4)
    expect(result[2].startTime).toEqual(before1.startTime)
    expect(result[3].startTime).toEqual(before2.startTime)
  })

  it('schedule_suggestedDate_doesNotFilterSlotsBeforeSuggested', () => {
    // This is a soft nudge — slots before the suggested date must NOT be removed
    const suggested = new Date('2026-04-05T00:00:00.000Z')
    const early = makeSlot('2026-04-01T09:00:00.000Z')
    const slots = [early]
    const result = applySuggestedDateConstraint(suggested, slots)
    expect(result).toHaveLength(1)
    expect(result[0]).toEqual(early)
  })
})
