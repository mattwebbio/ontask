// ── schedule_task MCP tool (FR45, Story 10.3) ─────────────────────────────────
//
// Tool name: schedule_task
// Description: Trigger the scheduling engine for a task and return the resulting scheduled time block.
// Input: { id }
// Output: MCP content format — { content: [{ type: 'text', text: JSON.stringify(scheduledBlock) }] }
//
// Proxies to POST /v1/tasks/:id/schedule on the API Worker via Service Binding.
// The API endpoint calls runScheduleForUser() and returns the scheduled block for the task.
// CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
// CRITICAL: Never calls the scheduling engine directly — always goes through the API Worker.
//
// userId is provided by the OAuth middleware (FR93, Story 10.4) — not caller-supplied.

import type { McpResult } from './create-task.js'

export interface ScheduleTaskInput {
  /** UUID of the task to schedule */
  id: string
}

/**
 * Triggers the scheduling engine for a task via the API Service Binding
 * (POST /v1/tasks/:id/schedule).
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 * CRITICAL: Does NOT call the scheduling engine directly — proxies through the API Worker.
 */
export async function scheduleTask(
  input: ScheduleTaskInput,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<McpResult> {

  if (!input.id) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: { code: 'MISSING_REQUIRED_FIELD', message: 'Task id is required' },
          }),
        },
      ],
      isError: true,
    }
  }

  try {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const response: any = await apiBinding.fetch(
      `https://ontask-api-internal/v1/tasks/${input.id}/schedule`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
      },
    )

    if (!response.ok) {
      const errorBody: string = await response.text()
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: {
                code: 'UPSTREAM_ERROR',
                message: `schedule_task: API returned ${response.status} — ${errorBody}`,
              },
            }),
          },
        ],
        isError: true,
      }
    }

    const json = (await response.json()) as { data: unknown }
    return {
      content: [{ type: 'text', text: JSON.stringify(json.data) }],
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({ error: { code: 'UPSTREAM_ERROR', message } }),
        },
      ],
      isError: true,
    }
  }
}
