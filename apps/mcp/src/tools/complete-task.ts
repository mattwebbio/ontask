// ── complete_task MCP tool (FR45, Story 10.3) ─────────────────────────────────
//
// Tool name: complete_task
// Description: Mark a task as complete.
// Input: { id, userId? }
// Output: MCP content format — { content: [{ type: 'text', text: JSON.stringify(result) }] }
//
// Proxies to POST /v1/tasks/:id/complete on the API Worker via Service Binding.
// The API endpoint sets completedAt = now() and handles recurring task generation.
// CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
//
// Note: The API has a dedicated POST /v1/tasks/:id/complete endpoint (not PATCH /v1/tasks/:id).
//       This endpoint returns { completedTask, nextInstance } for recurring tasks.
//
// TODO(impl): wire OAuth per-client scoping (FR93) — deferred to Story 10.4.

import type { McpResult } from './create-task.js'

export interface CompleteTaskInput {
  /** UUID of the task to complete */
  id: string
  /** User ID stub — OAuth per-client scoping deferred to Story 10.4 */
  userId?: string
}

/**
 * Marks a task complete via the API Service Binding (POST /v1/tasks/:id/complete).
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 * Uses the dedicated completion endpoint (not PATCH) as confirmed by reading tasks.ts.
 */
export async function completeTask(
  input: CompleteTaskInput,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
): Promise<McpResult> {
  const userId = input.userId ?? 'stub-user-id'

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
    // Use the dedicated POST /v1/tasks/:id/complete endpoint (confirmed from reading tasks.ts).
    // This endpoint sets completedAt = now() and returns { completedTask, nextInstance }
    // for recurring tasks.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const response: any = await apiBinding.fetch(
      `https://ontask-api-internal/v1/tasks/${input.id}/complete`,
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
                message: `complete_task: API returned ${response.status} — ${errorBody}`,
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
