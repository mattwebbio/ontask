import { describe, it, expect } from 'vitest'
import { schedule, explain } from '../index.js'

describe('@ontask/scheduling index', () => {
  it('schedule_publicApi_schedule_isExported', () => {
    expect(typeof schedule).toBe('function')
  })

  it('schedule_publicApi_explain_isExported', () => {
    expect(typeof explain).toBe('function')
  })
})
