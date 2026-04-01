import type { ScheduleInput, ScheduleOutput, ExplainOutput } from '@ontask/core'

/**
 * explain — returns human-readable reasons for why a specific task was
 * scheduled at its assigned time.
 *
 * Pure function: no side effects, no external calls, no `new Date()`.
 * Derives plain-language reasons deterministically from ScheduleInput,
 * ScheduleOutput, and the target taskId.
 *
 * 100% branch coverage is enforced in CI (packages/scheduling).
 * Full implementation: Story 3.6 (FR13).
 */
export function explain(
  input: ScheduleInput,
  output: ScheduleOutput,
  taskId: string,
): ExplainOutput {
  const reasons: string[] = []

  const task = input.tasks.find((t) => t.id === taskId)

  // Task not found in input — cannot explain
  if (!task) {
    return { reasons: [] }
  }

  // Task could not be placed in the scheduling window
  if (output.unscheduledTaskIds.includes(taskId)) {
    return { reasons: ['No available slot found in the scheduling window'] }
  }

  const block = output.scheduledBlocks.find((b) => b.taskId === taskId)

  // Task not in either scheduled or unscheduled lists — return empty
  if (!block) {
    return { reasons: [] }
  }

  // ── Manual override / pinned ───────────────────────────────────────────────
  // When a task is locked, that is the primary reason; no other reasons apply.
  if (block.isLocked) {
    reasons.push('You pinned this task to this time')
    return { reasons }
  }

  // ── Calendar conflict avoidance ────────────────────────────────────────────
  // Only include if calendar events exist in the input and the block avoids them.
  if (input.calendarEvents.length > 0) {
    const overlapsWithAny = input.calendarEvents.some(
      (e) => block.startTime < e.endTime && block.endTime > e.startTime,
    )
    if (!overlapsWithAny) {
      const time = block.startTime.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
      })
      const durationMs = block.endTime.getTime() - block.startTime.getTime()
      const durationMin = Math.round(durationMs / 60_000)
      reasons.push(
        `Scheduled at ${time} — your calendar was clear for ${durationMin} minutes starting then`,
      )
    }
  }

  // ── Due date constraint ────────────────────────────────────────────────────
  if (task.dueDate) {
    if (block.isAtRisk) {
      reasons.push(
        'No slot available before your due date — placed at the earliest available time',
      )
    } else {
      const formatted = task.dueDate.toLocaleDateString('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
      })
      reasons.push(`Placed before your due date on ${formatted}`)
    }
  }

  // ── Energy preference ──────────────────────────────────────────────────────
  // 'flexible' or unset: omit entirely (NFR-UX2 — only show meaningful context)
  if (task.energyRequirement === 'high_focus') {
    reasons.push('Matched your high-focus preference')
  } else if (task.energyRequirement === 'low_energy') {
    reasons.push('Matched your low-energy preference')
  }

  // ── Time window preference ─────────────────────────────────────────────────
  if (task.timeWindow) {
    const label =
      task.timeWindow === 'morning'
        ? 'morning'
        : task.timeWindow === 'afternoon'
          ? 'afternoon'
          : task.timeWindow === 'evening'
            ? 'evening'
            : 'custom'
    reasons.push(`Scheduled during your preferred ${label} window`)
  }

  // ── Dependency constraint ──────────────────────────────────────────────────
  if (task.dependsOnTaskIds && task.dependsOnTaskIds.length > 0) {
    for (const depId of task.dependsOnTaskIds) {
      const depBlock = output.scheduledBlocks.find((b) => b.taskId === depId)
      if (depBlock) {
        const depTask = input.tasks.find((t) => t.id === depId)
        const depTitle = depTask?.title ?? depId
        reasons.push(`Scheduled after '${depTitle}' which must complete first`)
        break // cite only the first resolved dependency
      }
    }
  }

  // ── Priority ordering ──────────────────────────────────────────────────────
  if (task.priority === 'critical') {
    reasons.push('Prioritised because this task is marked critical')
  } else if (task.priority === 'high') {
    reasons.push('Prioritised because this task is marked high')
  }

  return { reasons }
}
