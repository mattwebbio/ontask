import { describe, it, expect } from 'vitest'
import type { ScheduleTask, ScheduledBlock } from '@ontask/core'
import { applyEnergyPreferenceConstraint } from '../../constraints/energy-preferences.js'

const makeSlot = (startHourUTC: number): ScheduledBlock => {
  const start = new Date(`2026-04-02T${String(startHourUTC).padStart(2, '0')}:00:00.000Z`)
  const end = new Date(start.getTime() + 30 * 60_000)
  return { taskId: 'task-1', startTime: start, endTime: end, isLocked: false, isAtRisk: false }
}

describe('applyEnergyPreferenceConstraint', () => {
  it('schedule_energyPreference_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'high_focus' }
    expect(applyEnergyPreferenceConstraint(task, [])).toEqual([])
  })

  it('schedule_energyPreference_flexible_noReorder', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'flexible' }
    const slots = [makeSlot(14), makeSlot(9), makeSlot(18)]
    // flexible — should return same order, no change
    expect(applyEnergyPreferenceConstraint(task, slots)).toEqual(slots)
  })

  it('schedule_energyPreference_noRequirement_passesThrough', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test' }
    const slots = [makeSlot(14), makeSlot(9)]
    expect(applyEnergyPreferenceConstraint(task, slots)).toEqual(slots)
  })

  it('schedule_energyPreference_highFocus_sortsEarliestFirst', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'high_focus' }
    // morning slots (< 12:00) should come first
    const afternoon = makeSlot(14) // 14:00
    const morning = makeSlot(9)    // 09:00
    const evening = makeSlot(18)   // 18:00
    const earlyMorning = makeSlot(7) // 07:00

    const result = applyEnergyPreferenceConstraint(task, [afternoon, morning, evening, earlyMorning])
    // Morning slots should appear first (sorted by time), then afternoon/evening
    expect(result[0].startTime.getUTCHours()).toBeLessThan(12)
    expect(result[1].startTime.getUTCHours()).toBeLessThan(12)
    expect(result[0].startTime.getUTCHours()).toBe(7) // earliest morning first
    expect(result[1].startTime.getUTCHours()).toBe(9)
  })

  it('schedule_energyPreference_highFocus_doesNotFilterSlots', () => {
    // Energy preference must NOT drop slots — only reorder
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'high_focus' }
    const slots = [makeSlot(14), makeSlot(18), makeSlot(9)]
    const result = applyEnergyPreferenceConstraint(task, slots)
    expect(result).toHaveLength(3)
  })

  it('schedule_energyPreference_lowEnergy_sortsAfternoonFirst', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'low_energy' }
    const morning = makeSlot(9)      // 09:00 — not preferred
    const afternoon = makeSlot(13)   // 13:00 — preferred (>= 12:00)
    const evening = makeSlot(18)     // 18:00 — preferred

    const result = applyEnergyPreferenceConstraint(task, [morning, afternoon, evening])
    // Afternoon/evening first, morning last
    expect(result[0].startTime.getUTCHours()).toBeGreaterThanOrEqual(12)
    expect(result[1].startTime.getUTCHours()).toBeGreaterThanOrEqual(12)
    expect(result[2].startTime.getUTCHours()).toBe(9)
  })

  it('schedule_energyPreference_lowEnergy_doesNotFilterSlots', () => {
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'low_energy' }
    const slots = [makeSlot(9), makeSlot(14), makeSlot(19)]
    const result = applyEnergyPreferenceConstraint(task, slots)
    expect(result).toHaveLength(3)
  })

  it('schedule_energyPreference_highFocus_afternoonBeforeMorning_reordersCorrectly', () => {
    // a is NOT morning, b IS morning — morning should come first (return 1 from comparator)
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'high_focus' }
    const afternoon = makeSlot(14) // not morning
    const morning = makeSlot(8)    // morning
    const result = applyEnergyPreferenceConstraint(task, [afternoon, morning])
    // morning should come first
    expect(result[0].startTime.getUTCHours()).toBe(8)
    expect(result[1].startTime.getUTCHours()).toBe(14)
  })

  it('schedule_energyPreference_highFocus_morningBeforeAfternoon_retainsOrder', () => {
    // a IS morning, b is NOT morning — morning stays first (return -1 from comparator)
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'high_focus' }
    const morning = makeSlot(8)    // morning
    const afternoon = makeSlot(14) // not morning
    const result = applyEnergyPreferenceConstraint(task, [morning, afternoon])
    // morning should still come first
    expect(result[0].startTime.getUTCHours()).toBe(8)
    expect(result[1].startTime.getUTCHours()).toBe(14)
  })

  it('schedule_energyPreference_lowEnergy_morningBeforeAfternoon_reordersCorrectly', () => {
    // a is NOT afternoon, b IS afternoon — afternoon should come first (return 1)
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'low_energy' }
    const morning = makeSlot(8)    // not afternoon
    const afternoon = makeSlot(13) // afternoon
    const result = applyEnergyPreferenceConstraint(task, [morning, afternoon])
    // afternoon should come first
    expect(result[0].startTime.getUTCHours()).toBe(13)
    expect(result[1].startTime.getUTCHours()).toBe(8)
  })

  it('schedule_energyPreference_lowEnergy_afternoonBeforeMorning_retainsOrder', () => {
    // a IS afternoon, b is NOT afternoon — afternoon stays first (return -1)
    const task: ScheduleTask = { id: 'task-1', title: 'Test', energyRequirement: 'low_energy' }
    const afternoon = makeSlot(13) // afternoon
    const morning = makeSlot(8)    // not afternoon
    const result = applyEnergyPreferenceConstraint(task, [afternoon, morning])
    // afternoon should stay first
    expect(result[0].startTime.getUTCHours()).toBe(13)
    expect(result[1].startTime.getUTCHours()).toBe(8)
  })
})
