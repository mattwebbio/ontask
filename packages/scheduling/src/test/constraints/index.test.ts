import { describe, it, expect } from 'vitest'
import {
  applyCalendarEventConstraint,
  applyDependencyConstraint,
  applyDueDateConstraint,
  applyEnergyPreferenceConstraint,
  applySuggestedDateConstraint,
  applyTimeOfDayConstraint,
} from '../../constraints/index.js'

describe('@ontask/scheduling constraints barrel', () => {
  it('schedule_publicApi_applyCalendarEventConstraint_isExported', () => {
    expect(typeof applyCalendarEventConstraint).toBe('function')
  })

  it('schedule_publicApi_applyDependencyConstraint_isExported', () => {
    expect(typeof applyDependencyConstraint).toBe('function')
  })

  it('schedule_publicApi_applyDueDateConstraint_isExported', () => {
    expect(typeof applyDueDateConstraint).toBe('function')
  })

  it('schedule_publicApi_applyEnergyPreferenceConstraint_isExported', () => {
    expect(typeof applyEnergyPreferenceConstraint).toBe('function')
  })

  it('schedule_publicApi_applySuggestedDateConstraint_isExported', () => {
    expect(typeof applySuggestedDateConstraint).toBe('function')
  })

  it('schedule_publicApi_applyTimeOfDayConstraint_isExported', () => {
    expect(typeof applyTimeOfDayConstraint).toBe('function')
  })
})
