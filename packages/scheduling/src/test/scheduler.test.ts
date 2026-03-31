import { describe, it, expect } from 'vitest'
import type { ScheduleInput, CalendarEvent } from '@ontask/core'
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

  // ── New algorithm tests (Story 3.2) ─────────────────────────────────────

  it('schedule_singleTask_noConstraints_placedAtWindowStart', () => {
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [{ id: 'task-1', title: 'Task', estimatedDurationMinutes: 30 }],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(1)
    expect(output.scheduledBlocks[0].taskId).toBe('task-1')
    expect(output.scheduledBlocks[0].startTime).toEqual(baseInput.windowStart)
    expect(output.unscheduledTaskIds).toEqual([])
  })

  it('schedule_singleTask_calendarBlocked_placedAfterEvent', () => {
    // Event blocks 09:00–09:30 (windowStart) — task should be placed at 09:30
    const event: CalendarEvent = {
      id: 'event-1',
      startTime: new Date('2026-04-01T09:00:00.000Z'),
      endTime: new Date('2026-04-01T09:30:00.000Z'),
      isAllDay: false,
    }
    const input: ScheduleInput = {
      ...baseInput,
      calendarEvents: [event],
      tasks: [{ id: 'task-1', title: 'Task', estimatedDurationMinutes: 30 }],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(1)
    expect(output.scheduledBlocks[0].startTime).toEqual(new Date('2026-04-01T09:30:00.000Z'))
  })

  it('schedule_singleTask_dueDateBeforeWindow_markedAtRisk', () => {
    // Task is due before windowStart — all slots are after due date, so isAtRisk = true
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        {
          id: 'task-1',
          title: 'Overdue',
          estimatedDurationMinutes: 30,
          dueDate: new Date('2026-03-15T00:00:00.000Z'), // before windowStart
        },
      ],
    }
    const output = schedule(input)
    // Task should be placed somewhere (at-risk) not unscheduled
    expect(output.scheduledBlocks).toHaveLength(1)
    expect(output.scheduledBlocks[0].isAtRisk).toBe(true)
    expect(output.unscheduledTaskIds).not.toContain('task-1')
  })

  it('schedule_singleTask_lockedStartTime_placedExactly', () => {
    const lockedTime = new Date('2026-04-03T14:00:00.000Z')
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        {
          id: 'task-locked',
          title: 'Locked task',
          estimatedDurationMinutes: 60,
          lockedStartTime: lockedTime,
        },
      ],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(1)
    expect(output.scheduledBlocks[0].taskId).toBe('task-locked')
    expect(output.scheduledBlocks[0].startTime).toEqual(lockedTime)
    expect(output.scheduledBlocks[0].isLocked).toBe(true)
    expect(output.unscheduledTaskIds).toEqual([])
  })

  it('schedule_singleTask_lockedStartTime_noDuration_usesDefaultDuration', () => {
    // Locked task with no estimatedDurationMinutes — uses 30-min default
    const lockedTime = new Date('2026-04-03T10:00:00.000Z')
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        {
          id: 'task-locked-default',
          title: 'Locked task no duration',
          lockedStartTime: lockedTime,
          // No estimatedDurationMinutes — should default to 30 min
        },
      ],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(1)
    const block = output.scheduledBlocks[0]
    expect(block.startTime).toEqual(lockedTime)
    expect(block.isLocked).toBe(true)
    // Default duration is 30 minutes
    const expectedEnd = new Date(lockedTime.getTime() + 30 * 60_000)
    expect(block.endTime).toEqual(expectedEnd)
  })

  it('schedule_multipleTask_dependencyOrder_taskBAfterTaskA', () => {
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-a', title: 'Task A', estimatedDurationMinutes: 30 },
        {
          id: 'task-b',
          title: 'Task B',
          estimatedDurationMinutes: 30,
          dependsOnTaskIds: ['task-a'],
        },
      ],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(2)
    const blockA = output.scheduledBlocks.find((b) => b.taskId === 'task-a')!
    const blockB = output.scheduledBlocks.find((b) => b.taskId === 'task-b')!
    expect(blockB.startTime >= blockA.endTime).toBe(true)
  })

  it('schedule_singleTask_morningWindow_slotsFilteredToMorning', () => {
    // windowStart is 09:00 UTC (morning). Task has morning timeWindow.
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        {
          id: 'task-morning',
          title: 'Morning task',
          estimatedDurationMinutes: 30,
          timeWindow: 'morning',
        },
      ],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(1)
    const block = output.scheduledBlocks[0]
    // Block must start in morning window (06:00–12:00 UTC)
    const startHour = block.startTime.getUTCHours()
    expect(startHour).toBeGreaterThanOrEqual(6)
    expect(startHour).toBeLessThan(12)
  })

  it('schedule_singleTask_noSlotAvailable_inUnscheduledTaskIds', () => {
    // Block the entire window with a calendar event
    const event: CalendarEvent = {
      id: 'event-mega',
      startTime: new Date('2026-04-01T09:00:00.000Z'),
      endTime: new Date('2026-04-15T18:00:00.000Z'), // covers entire window
      isAllDay: false,
    }
    const input: ScheduleInput = {
      ...baseInput,
      calendarEvents: [event],
      tasks: [{ id: 'task-blocked', title: 'Blocked', estimatedDurationMinutes: 30 }],
    }
    const output = schedule(input)
    expect(output.scheduledBlocks.some((b) => b.taskId === 'task-blocked')).toBe(false)
    expect(output.unscheduledTaskIds).toContain('task-blocked')
  })

  it('schedule_taskOrdering_withDueDate_scheduledBeforeNoDueDate', () => {
    // Task with dueDate should be sorted before task without dueDate
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-noduedate', title: 'No due date' },
        {
          id: 'task-withduedate',
          title: 'Has due date',
          dueDate: new Date('2026-04-05T00:00:00.000Z'),
        },
      ],
    }
    const output = schedule(input)
    // task-withduedate should be scheduled first (earlier slot)
    const blockWithDue = output.scheduledBlocks.find((b) => b.taskId === 'task-withduedate')!
    const blockNoDue = output.scheduledBlocks.find((b) => b.taskId === 'task-noduedate')!
    expect(blockWithDue.startTime.getTime()).toBeLessThan(blockNoDue.startTime.getTime())
  })

  it('schedule_taskOrdering_noDueDate_scheduledAfterWithDueDate', () => {
    // Task without dueDate should be sorted after tasks with dueDate
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-noduedate', title: 'No due date' },
        { id: 'task-withduedate', title: 'Has due date', dueDate: new Date('2026-04-10T00:00:00.000Z') },
      ],
    }
    const output = schedule(input)
    const blockWithDue = output.scheduledBlocks.find((b) => b.taskId === 'task-withduedate')!
    const blockNoDue = output.scheduledBlocks.find((b) => b.taskId === 'task-noduedate')!
    expect(blockNoDue.startTime.getTime()).toBeGreaterThan(blockWithDue.startTime.getTime())
  })

  it('schedule_suggestedDate_taskNudgedToSuggestedDate', () => {
    // Task with suggestedDate should be nudged toward that date
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [{ id: 'task-1', title: 'Nudged task', estimatedDurationMinutes: 30 }],
      suggestedDates: { 'task-1': new Date('2026-04-05T00:00:00.000Z') },
    }
    const output = schedule(input)
    expect(output.scheduledBlocks).toHaveLength(1)
    // Task should be placed on or after the suggested date
    const block = output.scheduledBlocks[0]
    expect(block.startTime.getTime()).toBeGreaterThanOrEqual(
      new Date('2026-04-05T00:00:00.000Z').getTime()
    )
  })

  it('schedule_taskOrdering_sameDueDate_sortsByPriority', () => {
    // Two tasks with same dueDate — should be sorted by priority descending
    const dueDate = new Date('2026-04-05T00:00:00.000Z')
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-normal', title: 'Normal', dueDate, priority: 'normal' },
        { id: 'task-critical', title: 'Critical', dueDate, priority: 'critical' },
      ],
    }
    const output = schedule(input)
    const blockCritical = output.scheduledBlocks.find((b) => b.taskId === 'task-critical')!
    const blockNormal = output.scheduledBlocks.find((b) => b.taskId === 'task-normal')!
    // Critical should be scheduled first (earlier slot)
    expect(blockCritical.startTime.getTime()).toBeLessThan(blockNormal.startTime.getTime())
  })

  it('schedule_taskOrdering_noDueDateTaskAfterDueDateTask_sortedCorrectly', () => {
    // Verify that a task without dueDate is placed AFTER a task with dueDate
    // (covers the !a.dueDate && b.dueDate → return 1 branch)
    const input: ScheduleInput = {
      ...baseInput,
      tasks: [
        { id: 'task-noduedate', title: 'No due date' },
        { id: 'task-withduedate', title: 'Has due date', dueDate: new Date('2026-04-03T00:00:00.000Z') },
      ],
    }
    const output = schedule(input)
    const blockWithDue = output.scheduledBlocks.find((b) => b.taskId === 'task-withduedate')!
    const blockNoDue = output.scheduledBlocks.find((b) => b.taskId === 'task-noduedate')!
    expect(blockWithDue.startTime.getTime()).toBeLessThan(blockNoDue.startTime.getTime())
  })
})
