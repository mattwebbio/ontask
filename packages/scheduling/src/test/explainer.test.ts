import { describe, it, expect } from 'vitest'
import type { ScheduleInput, ScheduleOutput } from '@ontask/core'
import { explain } from '../explainer.js'

const baseInput: ScheduleInput = {
  tasks: [],
  calendarEvents: [],
  windowStart: new Date('2026-04-01T09:00:00.000Z'),
  windowEnd: new Date('2026-04-15T18:00:00.000Z'),
}

const baseOutput: ScheduleOutput = {
  scheduledBlocks: [],
  unscheduledTaskIds: [],
  generatedAt: new Date('2026-04-01T09:00:00.000Z'),
}

describe('explain', () => {
  it('explain_emptyInput_returnsEmptyReasons', () => {
    const result = explain(baseInput, baseOutput)
    expect(result).toEqual({ reasons: [] })
  })

  it('explain_withTasksAndBlocks_returnsEmptyReasons', () => {
    // Stub always returns empty reasons regardless of input
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [{ id: 'task-1', title: 'Some task' }],
    }
    const output: ScheduleOutput = {
      ...baseOutput,
      unscheduledTaskIds: ['task-1'],
    }
    const result = explain(input, output)
    expect(result.reasons).toEqual([])
  })
})
