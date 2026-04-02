// ── update_task MCP tool (FR45, Story 10.3) ───────────────────────────────────
//
// Tool name: update_task
// Description: Update an existing task's properties (title, due date, duration, priority, etc.).
// Input: { id, title?, notes?, dueDate?, listId?, priority? }
// Output: MCP content format — { content: [{ type: 'text', text: JSON.stringify(task) }] }
//
// Proxies to PATCH /v1/tasks/:id on the API Worker via Service Binding.
// CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
//
// userId is provided by the OAuth middleware (FR93, Story 10.4) — not caller-supplied.

import type { McpResult } from './create-task.js'

export interface UpdateTaskInput {
  /** UUID of the task to update */
  id: string
  /** New task title */
  title?: string
  /** Updated notes */
  notes?: string | null
  /** ISO 8601 UTC date string */
  dueDate?: string | null
  /** UUID of the target list */
  listId?: string | null
  /** Task priority level */
  priority?: 'normal' | 'high' | 'critical'
}

/**
 * Updates a task via the API Service Binding (PATCH /v1/tasks/:id).
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 */
export async function updateTask(
  input: UpdateTaskInput,
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
    // Build PATCH body with only provided fields
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const body: Record<string, any> = {}
    if (input.title !== undefined) body.title = input.title
    if (input.notes !== undefined) body.notes = input.notes
    if (input.dueDate !== undefined) body.dueDate = input.dueDate
    if (input.listId !== undefined) body.listId = input.listId
    if (input.priority !== undefined) body.priority = input.priority

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const response: any = await apiBinding.fetch(
      `https://ontask-api-internal/v1/tasks/${input.id}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
        body: JSON.stringify(body),
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
                message: `update_task: API returned ${response.status} — ${errorBody}`,
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
