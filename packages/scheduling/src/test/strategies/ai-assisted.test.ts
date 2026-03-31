import { describe, it, expect } from 'vitest'
import type { ScheduleInput } from '@ontask/core'
import { aiAssistedStrategy } from '../../strategies/ai-assisted.js'

const baseInput: ScheduleInput = {
  tasks: [],
  calendarEvents: [],
  windowStart: new Date('2026-04-01T09:00:00.000Z'),
  windowEnd: new Date('2026-04-15T18:00:00.000Z'),
}

describe('aiAssistedStrategy', () => {
  it('schedule_aiAssisted_noTasks_returnsEmptyBlocks', () => {
    const output = aiAssistedStrategy(baseInput)
    expect(output.scheduledBlocks).toEqual([])
    expect(output.unscheduledTaskIds).toEqual([])
  })

  it('schedule_aiAssisted_withTasks_returnsUnscheduled', () => {
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-1', title: 'Task 1' },
        { id: 'task-2', title: 'Task 2' },
      ],
    }
    const output = aiAssistedStrategy(input)
    expect(output.unscheduledTaskIds).toContain('task-1')
    expect(output.unscheduledTaskIds).toContain('task-2')
  })
})
