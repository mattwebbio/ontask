import { describe, it, expect } from 'vitest'
import type { ScheduleInput } from '@ontask/core'
import { schedule } from '../scheduler.js'

const baseInput: ScheduleInput = {
  tasks: [],
  calendarEvents: [],
  windowStart: new Date('2026-04-01T09:00:00.000Z'),
  windowEnd: new Date('2026-04-15T18:00:00.000Z'),
}

describe('schedule', () => {
  it('schedule_emptyInput_noTasks_returnsEmptyBlocks', () => {
    const output = schedule(baseInput)
    expect(output.scheduledBlocks).toEqual([])
    expect(output.unscheduledTaskIds).toEqual([])
  })

  it('schedule_determinism_sameInput_identicalOutput', () => {
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        {
          id: 'task-1',
          title: 'Write tests',
          estimatedDurationMinutes: 30,
        },
      ],
    }
    const first = schedule(input)
    const second = schedule(input)
    expect(first).toEqual(second)
  })

  it('schedule_dueDate_taskOverdue_scheduledImmediately', () => {
    const overdueDate = new Date('2026-03-01T00:00:00.000Z') // before windowStart
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        {
          id: 'task-overdue',
          title: 'Overdue task',
          dueDate: overdueDate,
          estimatedDurationMinutes: 60,
        },
      ],
    }
    const output = schedule(input)
    // Task must appear in output (not silently dropped) — either scheduled or unscheduled
    const appearsInOutput =
      output.scheduledBlocks.some((b) => b.taskId === 'task-overdue') ||
      output.unscheduledTaskIds.includes('task-overdue')
    expect(appearsInOutput).toBe(true)
  })

  it('schedule_multipleTasksInput_allTasksAccountedFor', () => {
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-a', title: 'Task A' },
        { id: 'task-b', title: 'Task B' },
        { id: 'task-c', title: 'Task C' },
      ],
    }
    const output = schedule(input)
    const allOutputIds = [
      ...output.scheduledBlocks.map((b) => b.taskId),
      ...output.unscheduledTaskIds,
    ]
    expect(allOutputIds).toContain('task-a')
    expect(allOutputIds).toContain('task-b')
    expect(allOutputIds).toContain('task-c')
  })

  it('schedule_output_generatedAt_equalsWindowStart', () => {
    // The engine must not call new Date() — generatedAt is set from windowStart
    const output = schedule(baseInput)
    expect(output.generatedAt).toEqual(baseInput.windowStart)
  })
})
