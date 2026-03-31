import { describe, it, expect } from 'vitest'
import type { ScheduleTask } from '@ontask/core'
import { applyDependencyConstraint } from '../../constraints/dependencies.js'

describe('applyDependencyConstraint', () => {
  it('schedule_dependency_noSlots_returnsEmpty', () => {
    const task: ScheduleTask = {
      id: 'task-2',
      title: 'Dependent task',
      dependsOnTaskIds: ['task-1'],
    }
    const allTasks: ScheduleTask[] = [
      { id: 'task-1', title: 'Prerequisite' },
      task,
    ]
    expect(applyDependencyConstraint(task, allTasks, [])).toEqual([])
  })

  it('schedule_dependency_withSlots_returnsSlots', () => {
    const task: ScheduleTask = {
      id: 'task-2',
      title: 'Dependent task',
      dependsOnTaskIds: ['task-1'],
    }
    const allTasks: ScheduleTask[] = [
      { id: 'task-1', title: 'Prerequisite' },
      task,
    ]
    const slots = [
      {
        taskId: 'task-2',
        startTime: new Date('2026-04-02T11:00:00.000Z'),
        endTime: new Date('2026-04-02T12:00:00.000Z'),
        isLocked: false,
        isAtRisk: false,
      },
    ]
    expect(applyDependencyConstraint(task, allTasks, slots)).toEqual(slots)
  })
})
