import { describe, it, expect } from 'vitest'
import { schedule, explain } from '../index.js'

describe('@ontask/scheduling index', () => {
  it('schedule_export_isFunction', () => {
    expect(typeof schedule).toBe('function')
  })

  it('explain_export_isFunction', () => {
    expect(typeof explain).toBe('function')
  })
})
