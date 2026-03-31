import type { ScheduleInput, ScheduleOutput, ExplainOutput } from '@ontask/core'

/**
 * explain — returns human-readable reasons for scheduling decisions.
 *
 * Stub returning empty reasons array.
 * Full implementation: Story 3.6.
 */
export function explain(
  _input: ScheduleInput,
  _output: ScheduleOutput,
): ExplainOutput {
  return { reasons: [] }
}
