import { describe, it, expect } from 'vitest'
import type { ScheduleInput, ScheduleOutput, ScheduleTask, ScheduledBlock } from '@ontask/core'
import { explain } from '../explainer.js'

// ── Fixtures ──────────────────────────────────────────────────────────────────

const WINDOW_START = new Date('2026-04-01T09:00:00.000Z')
const WINDOW_END = new Date('2026-04-15T18:00:00.000Z')

const TASK_ID = 'task-1'
const DEP_TASK_ID = 'task-dep'

function makeInput(
  taskOverrides: Partial<ScheduleTask> = {},
  inputOverrides: Partial<ScheduleInput> = {},
): ScheduleInput {
  const task: ScheduleTask = { id: TASK_ID, title: 'Test Task', ...taskOverrides }
  return {
    tasks: [task],
    calendarEvents: [],
    windowStart: WINDOW_START,
    windowEnd: WINDOW_END,
    ...inputOverrides,
  }
}

function makeBlock(overrides: Partial<ScheduledBlock> = {}): ScheduledBlock {
  return {
    taskId: TASK_ID,
    startTime: new Date('2026-04-01T10:00:00.000Z'),
    endTime: new Date('2026-04-01T10:30:00.000Z'),
    isLocked: false,
    isAtRisk: false,
    ...overrides,
  }
}

function makeOutput(
  blockOverrides: Partial<ScheduledBlock> = {},
  outputOverrides: Partial<ScheduleOutput> = {},
): ScheduleOutput {
  return {
    scheduledBlocks: [makeBlock(blockOverrides)],
    unscheduledTaskIds: [],
    generatedAt: WINDOW_START,
    ...outputOverrides,
  }
}

const EMPTY_OUTPUT: ScheduleOutput = {
  scheduledBlocks: [],
  unscheduledTaskIds: [],
  generatedAt: WINDOW_START,
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('explain', () => {
  // ── Empty / missing task ─────────────────────────────────────────────────

  it('explain_emptyInput_returnsEmptyReasons', () => {
    const input: ScheduleInput = {
      tasks: [],
      calendarEvents: [],
      windowStart: WINDOW_START,
      windowEnd: WINDOW_END,
    }
    const result = explain(input, EMPTY_OUTPUT, TASK_ID)
    expect(result).toEqual({ reasons: [] })
  })

  it('explain_noScheduledBlock_returnsEmpty', () => {
    // Task exists in input but is not in scheduledBlocks or unscheduledTaskIds
    const input = makeInput()
    const result = explain(input, EMPTY_OUTPUT, TASK_ID)
    expect(result.reasons).toEqual([])
  })

  it('explain_taskNotInInput_returnsEmpty', () => {
    const input = makeInput()
    const output = makeOutput()
    // Ask for a task that doesn't exist in input
    const result = explain(input, output, 'unknown-task')
    expect(result.reasons).toEqual([])
  })

  // ── Unscheduled ──────────────────────────────────────────────────────────

  it('explain_unscheduled_returnsNoSlotReason', () => {
    const input = makeInput()
    const output: ScheduleOutput = {
      scheduledBlocks: [],
      unscheduledTaskIds: [TASK_ID],
      generatedAt: WINDOW_START,
    }
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toEqual(['No available slot found in the scheduling window'])
  })

  // ── Manual override / locked ─────────────────────────────────────────────

  it('explain_lockedTask_returnsManualOverrideReason', () => {
    const input = makeInput()
    const output = makeOutput({ isLocked: true })
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toEqual(['You pinned this task to this time'])
  })

  it('explain_lockedTask_onlyReturnsOneReason', () => {
    // Even if other properties are set, locked returns only the pin reason
    const input = makeInput({
      dueDate: new Date('2026-04-10'),
      energyRequirement: 'high_focus',
    })
    const output = makeOutput({ isLocked: true })
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toHaveLength(1)
    expect(result.reasons[0]).toBe('You pinned this task to this time')
  })

  // ── Due date constraint ──────────────────────────────────────────────────

  it('explain_dueDateConstraint_slotBeforeDueDate_returnsDueDateReason', () => {
    const dueDate = new Date('2026-04-10')
    const input = makeInput({ dueDate })
    const output = makeOutput({ isAtRisk: false })
    const result = explain(input, output, TASK_ID)
    const formattedDate = dueDate.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    })
    expect(result.reasons).toContain(`Placed before your due date on ${formattedDate}`)
  })

  it('explain_dueDateConstraint_atRisk_returnsAtRiskReason', () => {
    const input = makeInput({ dueDate: new Date('2026-04-02') })
    const output = makeOutput({ isAtRisk: true })
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain(
      'No slot available before your due date — placed at the earliest available time',
    )
  })

  // ── Energy preference ────────────────────────────────────────────────────

  it('explain_energyPreference_highFocus_returnsEnergyReason', () => {
    const input = makeInput({ energyRequirement: 'high_focus' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Matched your high-focus preference')
  })

  it('explain_energyPreference_lowEnergy_returnsEnergyReason', () => {
    const input = makeInput({ energyRequirement: 'low_energy' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Matched your low-energy preference')
  })

  it('explain_energyPreference_flexible_omitsEnergyReason', () => {
    const input = makeInput({ energyRequirement: 'flexible' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('preference') && r.includes('focus'))).toBe(false)
    expect(result.reasons.some((r) => r.includes('low-energy'))).toBe(false)
  })

  it('explain_energyPreference_unset_omitsEnergyReason', () => {
    // No energyRequirement set
    const input = makeInput()
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('focus') || r.includes('low-energy'))).toBe(false)
  })

  // ── Time window preference ───────────────────────────────────────────────

  it('explain_timeWindow_morning_returnsTimeWindowReason', () => {
    const input = makeInput({ timeWindow: 'morning' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Scheduled during your preferred morning window')
  })

  it('explain_timeWindow_afternoon_returnsTimeWindowReason', () => {
    const input = makeInput({ timeWindow: 'afternoon' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Scheduled during your preferred afternoon window')
  })

  it('explain_timeWindow_evening_returnsTimeWindowReason', () => {
    const input = makeInput({ timeWindow: 'evening' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Scheduled during your preferred evening window')
  })

  it('explain_timeWindow_custom_returnsTimeWindowReason', () => {
    const input = makeInput({ timeWindow: 'custom' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Scheduled during your preferred custom window')
  })

  // ── Dependency constraint ────────────────────────────────────────────────

  it('explain_dependency_blockExists_returnsDependencyReason', () => {
    const depTask: ScheduleTask = { id: DEP_TASK_ID, title: 'Dependency Task' }
    const input: ScheduleInput = {
      tasks: [
        { id: TASK_ID, title: 'Test Task', dependsOnTaskIds: [DEP_TASK_ID] },
        depTask,
      ],
      calendarEvents: [],
      windowStart: WINDOW_START,
      windowEnd: WINDOW_END,
    }
    const depBlock: ScheduledBlock = {
      taskId: DEP_TASK_ID,
      startTime: new Date('2026-04-01T08:00:00.000Z'),
      endTime: new Date('2026-04-01T09:00:00.000Z'),
      isLocked: false,
      isAtRisk: false,
    }
    const output: ScheduleOutput = {
      scheduledBlocks: [makeBlock(), depBlock],
      unscheduledTaskIds: [],
      generatedAt: WINDOW_START,
    }
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain(
      `Scheduled after 'Dependency Task' which must complete first`,
    )
  })

  it('explain_dependency_noBlockForDep_omitsDependencyReason', () => {
    const input: ScheduleInput = {
      tasks: [{ id: TASK_ID, title: 'Test Task', dependsOnTaskIds: [DEP_TASK_ID] }],
      calendarEvents: [],
      windowStart: WINDOW_START,
      windowEnd: WINDOW_END,
    }
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('must complete first'))).toBe(false)
  })

  it('explain_dependency_depTaskNotInInput_usesFallbackId', () => {
    // Dependency task has a block but is NOT listed in input.tasks — title falls back to taskId
    const input: ScheduleInput = {
      tasks: [{ id: TASK_ID, title: 'Test Task', dependsOnTaskIds: [DEP_TASK_ID] }],
      // DEP_TASK_ID is NOT in tasks list
      calendarEvents: [],
      windowStart: WINDOW_START,
      windowEnd: WINDOW_END,
    }
    const depBlock: ScheduledBlock = {
      taskId: DEP_TASK_ID,
      startTime: new Date('2026-04-01T08:00:00.000Z'),
      endTime: new Date('2026-04-01T09:00:00.000Z'),
      isLocked: false,
      isAtRisk: false,
    }
    const output: ScheduleOutput = {
      scheduledBlocks: [makeBlock(), depBlock],
      unscheduledTaskIds: [],
      generatedAt: WINDOW_START,
    }
    const result = explain(input, output, TASK_ID)
    // Falls back to using DEP_TASK_ID as the title
    expect(result.reasons).toContain(`Scheduled after '${DEP_TASK_ID}' which must complete first`)
  })

  // ── Calendar conflict avoidance ──────────────────────────────────────────

  it('explain_calendarConflict_avoided_returnsCalendarReason', () => {
    // Calendar event exists, and the block does NOT overlap it
    const calendarEvent = {
      id: 'cal-1',
      startTime: new Date('2026-04-01T08:00:00.000Z'),
      endTime: new Date('2026-04-01T09:00:00.000Z'),
      isAllDay: false,
    }
    const input = makeInput({}, { calendarEvents: [calendarEvent] })
    // Block is at 10:00 — does not overlap 08:00-09:00
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('your calendar was clear'))).toBe(true)
  })

  it('explain_calendarConflict_overlaps_omitsCalendarReason', () => {
    // Calendar event that overlaps with the block — should NOT produce calendar reason
    const calendarEvent = {
      id: 'cal-1',
      startTime: new Date('2026-04-01T09:30:00.000Z'),
      endTime: new Date('2026-04-01T11:00:00.000Z'),
      isAllDay: false,
    }
    const input = makeInput({}, { calendarEvents: [calendarEvent] })
    // Block is 10:00-10:30 — overlaps with 09:30-11:00
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('your calendar was clear'))).toBe(false)
  })

  it('explain_noCalendarEvents_omitsCalendarReason', () => {
    const input = makeInput()
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('your calendar was clear'))).toBe(false)
  })

  // ── Priority ordering ────────────────────────────────────────────────────

  it('explain_highPriority_returnsReason', () => {
    const input = makeInput({ priority: 'high' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Prioritised because this task is marked high')
  })

  it('explain_criticalPriority_returnsReason', () => {
    const input = makeInput({ priority: 'critical' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons).toContain('Prioritised because this task is marked critical')
  })

  it('explain_normalPriority_omitsReason', () => {
    const input = makeInput({ priority: 'normal' })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('Prioritised'))).toBe(false)
  })

  it('explain_unsetPriority_omitsReason', () => {
    const input = makeInput()
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    expect(result.reasons.some((r) => r.includes('Prioritised'))).toBe(false)
  })

  // ── Multiple reasons ─────────────────────────────────────────────────────

  it('explain_multipleReasons_allReturned', () => {
    const dueDate = new Date('2026-04-10')
    const input = makeInput({
      dueDate,
      energyRequirement: 'high_focus',
      timeWindow: 'morning',
    })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    const formattedDate = dueDate.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    })
    expect(result.reasons).toContain(`Placed before your due date on ${formattedDate}`)
    expect(result.reasons).toContain('Matched your high-focus preference')
    expect(result.reasons).toContain('Scheduled during your preferred morning window')
    expect(result.reasons.length).toBeGreaterThanOrEqual(3)
  })

  // ── Date formatting ──────────────────────────────────────────────────────

  it('explain_dueDateFormatting_usesLocaleDateString', () => {
    // Ensure the date is formatted as "Mon, Apr 6" style — no ISO strings exposed
    const dueDate = new Date('2026-04-06T00:00:00.000Z')
    const input = makeInput({ dueDate })
    const output = makeOutput()
    const result = explain(input, output, TASK_ID)
    // Must not contain raw ISO date strings
    expect(result.reasons.some((r) => r.includes('2026-04-06'))).toBe(false)
    // Must contain a human-readable date
    expect(result.reasons.some((r) => r.includes('Apr'))).toBe(true)
  })
})
