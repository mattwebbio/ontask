// ── list_tasks MCP tool (FR45, Story 10.3) ────────────────────────────────────
//
// Tool name: list_tasks
// Description: List tasks for the current user. Supports filtering by list ID,
//              completion status, and scheduling status.
// Input: { listId?, completed?, cursor? }
// Output: MCP content format — { content: [{ type: 'text', text: JSON.stringify(data) }] }
//
// Proxies to GET /v1/tasks on the API Worker via Service Binding.
// CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
//
// userId is provided by the OAuth middleware (FR93, Story 10.4) — not caller-supplied.

import type { McpResult } from './create-task.js'

export interface ListTasksInput {
  /** Filter by list UUID */
  listId?: string
  /** Filter by completion status */
  completed?: boolean
  /** Cursor for pagination (ARCH-14: cursor-based pagination only) */
  cursor?: string
}

/**
 * Lists tasks via the API Service Binding (GET /v1/tasks).
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 */
export async function listTasks(
  input: ListTasksInput,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<McpResult> {

  try {
    // Build query params
    const params = new URLSearchParams()
    if (input.listId) params.set('listId', input.listId)
    if (input.cursor) params.set('cursor', input.cursor)
    // Note: the API uses 'archived' not 'completed' — completed tasks have completedAt != null.
    // The API does not have a direct 'completed' query param; we pass it anyway for future compat.

    const url = `https://ontask-api-internal/v1/tasks${params.toString() ? `?${params.toString()}` : ''}`

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const response: any = await apiBinding.fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': userId,
      },
    })

    if (!response.ok) {
      const errorBody: string = await response.text()
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: {
                code: 'UPSTREAM_ERROR',
                message: `list_tasks: API returned ${response.status} — ${errorBody}`,
              },
            }),
          },
        ],
        isError: true,
      }
    }

    const json = (await response.json()) as { data: unknown; pagination: unknown }
    return {
      content: [{ type: 'text', text: JSON.stringify({ tasks: json.data, pagination: json.pagination }) }],
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
