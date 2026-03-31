import type { ScheduleInput, ScheduleOutput } from '@ontask/core'

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
 * Full scheduling algorithm is implemented in Story 3.2.
 * This stub satisfies the type contract and all determinism invariants.
 */
export function schedule(input: ScheduleInput): ScheduleOutput {
  // Minimal implementation: place no blocks, report all tasks as unscheduled.
  // Story 3.2 replaces this body with the real algorithm.
  return {
    scheduledBlocks: [],
    unscheduledTaskIds: input.tasks.map((task) => task.id),
    // generatedAt must be set by the caller; we use windowStart as the
    // pure-function-safe stand-in so the engine never calls new Date().
    generatedAt: input.windowStart,
  }
}
