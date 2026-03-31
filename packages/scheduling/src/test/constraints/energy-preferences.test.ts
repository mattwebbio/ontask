import { describe, it, expect } from 'vitest'
import type { ScheduleTask } from '@ontask/core'
import { applyEnergyPreferenceConstraint } from '../../constraints/energy-preferences.js'

describe('applyEnergyPreferenceConstraint', () => {
  it('schedule_energyPreference_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'high_focus' }
    expect(applyEnergyPreferenceConstraint(task, [])).toEqual([])
  })

  it('schedule_energyPreference_withSlots_returnsSlots', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'low_energy' }
    const slots = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T15:00:00.000Z'),
        endTime: new Date('2026-04-02T16:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyEnergyPreferenceConstraint(task, slots)).toEqual(slots)
  })
})
