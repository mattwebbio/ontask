import { describe, it, expect } from 'vitest'
import type { ScheduleTask, ScheduledBlock } from '@ontask/core'
import { applyDependencyConstraint } from '../../constraints/dependencies.js'

describe('applyDependencyConstraint', () => {
  it('schedule_dependency_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = {
      id: 'task-2',
      title: 'Dependent task',
      dependsOnTaskIds: ['task-1'],
    }
    const scheduledBlocks: ScheduledBlock[] = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T09:00:00.000Z'),
        endTime: new Date('2026-04-02T09:30:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyDependencyConstraint(task, scheduledBlocks, [])).toEqual([])
  })

  it('schedule_dependency_dependencyScheduled_blockStartsAfter', () => {
    const task: ScheduleTask = {
      id: 'task-2',
      title: 'Dependent task',
      dependsOnTaskIds: ['task-1'],
    }
    // task-1 ends at 10:00 — task-2 slots starting at or after 10:00 should be kept
    const scheduledBlocks: ScheduledBlock[] = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T09:30:00.000Z'),
        endTime: new Date('2026-04-02T10:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    const slots: ScheduledBlock[] = [
      {
        taskId: 'task-2',
        startTime: new Date('2026-04-02T09:00:00.000Z'), // Before dep end — should be removed
        endTime: new Date('2026-04-02T09:30:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
      {
        taskId: 'task-2',
        startTime: new Date('2026-04-02T10:00:00.000Z'), // At dep end — should be kept
        endTime: new Date('2026-04-02T10:30:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
      {
        taskId: 'task-2',
        startTime: new Date('2026-04-02T11:00:00.000Z'), // After dep end — should be kept
        endTime: new Date('2026-04-02T11:30:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    const result = applyDependencyConstraint(task, scheduledBlocks, slots)
    expect(result).toHaveLength(2)
    expect(result[0].startTime).toEqual(new Date('2026-04-02T10:00:00.000Z'))
    expect(result[1].startTime).toEqual(new Date('2026-04-02T11:00:00.000Z'))
  })

  it('schedule_dependency_dependencyUnscheduled_returnsEmpty', () => {
    const task: ScheduleTask = {
      id: 'task-2',
      title: 'Dependent task',
      dependsOnTaskIds: ['task-1'],
    }
    // task-1 is NOT in scheduledBlocks — constraint is unresolvable
    const scheduledBlocks: ScheduledBlock[] = []
    const slots: ScheduledBlock[] = [
      {
        taskId: 'task-2',
        startTime: new Date('2026-04-02T11:00:00.000Z'),
        endTime: new Date('2026-04-02T12:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyDependencyConstraint(task, scheduledBlocks, slots)).toEqual([])
  })

  it('schedule_dependency_noDependencies_passesThrough', () => {
    const task: ScheduleTask = {
      id: 'task-1',
      title: 'Independent task',
    }
    const slots: ScheduledBlock[] = [
      {
        taskId: 'task-1',
        startTime: new Date('2026-04-02T09:00:00.000Z'),
        endTime: new Date('2026-04-02T09:30:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyDependencyConstraint(task, [], slots)).toEqual(slots)
  })

  it('schedule_dependency_multipleDependencies_usesLatestEndTime', () => {
    // Two deps: dep-A ends at 09:30, dep-B ends at 10:00 — latest is 10:00
    const task: ScheduleTask = {
      id: 'task-c',
      title: 'Task C',
      dependsOnTaskIds: ['dep-a', 'dep-b'],
    }
    const scheduledBlocks: ScheduledBlock[] = [
      {
        taskId: 'dep-a',
        startTime: new Date('2026-04-02T09:00:00.000Z'),
        endTime: new Date('2026-04-02T09:30:00.000Z'), // earlier end
        isLocked: false,
        isAtRisk: false,
      },
      {
        taskId: 'dep-b',
        startTime: new Date('2026-04-02T09:30:00.000Z'),
        endTime: new Date('2026-04-02T10:00:00.000Z'), // later end
        isLocked: false,
        isAtRisk: false,
      },
    ]
    const slots: ScheduledBlock[] = [
      {
        taskId: 'task-c',
        startTime: new Date('2026-04-02T09:30:00.000Z'), // before latest dep end — removed
        endTime: new Date('2026-04-02T10:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
      {
        taskId: 'task-c',
        startTime: new Date('2026-04-02T10:00:00.000Z'), // at latest dep end — kept
        endTime: new Date('2026-04-02T10:30:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    const result = applyDependencyConstraint(task, scheduledBlocks, slots)
    expect(result).toHaveLength(1)
    expect(result[0].startTime).toEqual(new Date('2026-04-02T10:00:00.000Z'))
  })
})
