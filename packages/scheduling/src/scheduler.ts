import type { ScheduleInput, ScheduleOutput, ScheduleTask, ScheduledBlock } from '@ontask/core'
import { applyCalendarEventConstraint } from './constraints/calendar-events.js'
import { applyTimeOfDayConstraint } from './constraints/time-of-day.js'
import { applyEnergyPreferenceConstraint } from './constraints/energy-preferences.js'
import { applyDueDateConstraint } from './constraints/due-date.js'
import { applyDependencyConstraint } from './constraints/dependencies.js'
import { applySuggestedDateConstraint } from './constraints/suggested-dates.js'

const SLOT_DURATION_MINUTES = 30
const MS_PER_MINUTE = 60_000

/**
 * schedule — pure function scheduling engine entry point.
 *
 * Contracts:
 * - No side effects, no external calls, no randomness.
 * - No `new Date()` or `Date.now()` — use `input.windowStart` as "now".
 * - Given identical inputs, always produces identical outputs (NFR-Q1).
 * - `output.generatedAt` must be supplied by the caller (API service layer),
 *   not generated here. Pass `input.windowStart` as a stand-in until the
 *   caller sets it before returning to clients.
 *
 * Algorithm: greedy-earliest selection.
 * 1. Sort tasks by dueDate ascending (null/undefined → end), then priority descending.
 * 2. For each task, generate 30-min candidate slots across [windowStart, windowEnd].
 * 3. Run constraint pipeline to filter/sort candidates.
 * 4. Pick the first remaining slot; mark it occupied.
 * 5. Tasks without a valid slot go to unscheduledTaskIds.
 */
export function schedule(input: ScheduleInput): ScheduleOutput {
  const { tasks, calendarEvents, windowStart, windowEnd, suggestedDates } = input

  const sortedTasks = sortTasks(tasks)

  const scheduledBlocks: ScheduledBlock[] = []
  const unscheduledTaskIds: string[] = []

  // Track occupied time ranges to prevent double-booking
  const occupiedSlots: Array<{ startTime: Date; endTime: Date }> = []

  for (const task of sortedTasks) {
    // Locked tasks bypass the pipeline entirely
    if (task.lockedStartTime) {
      const durationMs =
        (task.estimatedDurationMinutes ?? SLOT_DURATION_MINUTES) * MS_PER_MINUTE
      const block: ScheduledBlock = {
        taskId: task.id,
        startTime: task.lockedStartTime,
        endTime: new Date(task.lockedStartTime.getTime() + durationMs),
        isLocked: true,
        isAtRisk: false,
      }
      scheduledBlocks.push(block)
      occupiedSlots.push({ startTime: block.startTime, endTime: block.endTime })
      continue
    }

    const durationMs =
      (task.estimatedDurationMinutes ?? SLOT_DURATION_MINUTES) * MS_PER_MINUTE

    // Generate candidate slots
    let candidates = generateCandidateSlots(task, windowStart, windowEnd, durationMs)

    // Remove already-occupied slots
    candidates = candidates.filter((slot) => !isOccupied(slot, occupiedSlots))

    // Apply dependency constraint first (uses already-scheduled blocks)
    if (task.dependsOnTaskIds && task.dependsOnTaskIds.length > 0) {
      candidates = applyDependencyConstraint(task, scheduledBlocks, candidates)
    }

    // Apply suggested date nudge (soft reorder)
    const suggested = suggestedDates?.[task.id]
    if (suggested !== undefined) {
      candidates = applySuggestedDateConstraint(suggested, candidates)
    }

    // Apply the main constraint pipeline
    candidates = applyCalendarEventConstraint(calendarEvents, candidates)
    candidates = applyTimeOfDayConstraint(task, candidates)
    candidates = applyEnergyPreferenceConstraint(task, candidates)
    candidates = applyDueDateConstraint(task, candidates)

    if (candidates.length === 0) {
      unscheduledTaskIds.push(task.id)
      continue
    }

    // The due-date constraint may mark all remaining slots as at-risk if no slot
    // falls before the due date. If all candidates are at-risk, take the first one.
    const firstCandidate = candidates[0]

    // Check if this is an at-risk scenario (due date constraint returned at-risk slots)
    if (firstCandidate.isAtRisk) {
      // Task cannot be placed before its due date — mark as unscheduled if all at risk
      // but we do schedule it at the first available slot with isAtRisk = true
      const block: ScheduledBlock = {
        ...firstCandidate,
        taskId: task.id,
        isLocked: false,
      }
      scheduledBlocks.push(block)
      occupiedSlots.push({ startTime: block.startTime, endTime: block.endTime })
      continue
    }

    const block: ScheduledBlock = {
      taskId: task.id,
      startTime: firstCandidate.startTime,
      endTime: firstCandidate.endTime,
      isLocked: false,
      isAtRisk: false,
    }
    scheduledBlocks.push(block)
    occupiedSlots.push({ startTime: block.startTime, endTime: block.endTime })
  }

  return {
    scheduledBlocks,
    unscheduledTaskIds,
    // generatedAt must be set by the caller; we use windowStart as the
    // pure-function-safe stand-in so the engine never calls new Date().
    generatedAt: windowStart,
  }
}

/**
 * Generate candidate ScheduledBlock slots for a task across [windowStart, windowEnd].
 * Slots are 30-minute increments (or estimatedDurationMinutes if > 30).
 */
function generateCandidateSlots(
  task: ScheduleTask,
  windowStart: Date,
  windowEnd: Date,
  durationMs: number,
): ScheduledBlock[] {
  const slots: ScheduledBlock[] = []
  const stepMs = SLOT_DURATION_MINUTES * MS_PER_MINUTE

  let current = windowStart.getTime()
  const end = windowEnd.getTime()

  while (current + durationMs <= end) {
    slots.push({
      taskId: task.id,
      startTime: new Date(current),
      endTime: new Date(current + durationMs),
      isLocked: false,
      isAtRisk: false,
    })
    current += stepMs
  }

  return slots
}

/**
 * Check if a candidate slot overlaps any already-occupied slot.
 */
function isOccupied(
  slot: ScheduledBlock,
  occupied: Array<{ startTime: Date; endTime: Date }>,
): boolean {
  for (const occ of occupied) {
    if (slot.startTime < occ.endTime && slot.endTime > occ.startTime) {
      return true
    }
  }
  return false
}

const PRIORITY_ORDER: Record<string, number> = {
  critical: 3,
  high: 2,
  normal: 1,
}

// Sentinel value used as sort key for tasks with no due date (sorts to end)
const NO_DUE_DATE_SENTINEL = Number.MAX_SAFE_INTEGER

/**
 * Sort tasks: dueDate ascending (undefined → end), then priority descending.
 */
function sortTasks(tasks: ScheduleTask[]): ScheduleTask[] {
  return [...tasks].sort((a, b) => {
    // Assign a numeric sort key: actual epoch ms, or sentinel for no-due-date
    const aTime = a.dueDate ? a.dueDate.getTime() : NO_DUE_DATE_SENTINEL
    const bTime = b.dueDate ? b.dueDate.getTime() : NO_DUE_DATE_SENTINEL

    if (aTime !== bTime) return aTime - bTime

    // Same due date (or both have none) → sort by priority descending
    const aPriority = PRIORITY_ORDER[a.priority ?? 'normal']
    const bPriority = PRIORITY_ORDER[b.priority ?? 'normal']
    return bPriority - aPriority
  })
}
