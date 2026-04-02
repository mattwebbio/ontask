// ── create_task MCP tool (FR45, Story 10.3) ───────────────────────────────────
//
// Tool name: create_task
// Description: Create a new task. Accepts structured properties or a natural
//              language description that is parsed by an LLM before creating.
// Input: { input?, title?, listId?, dueDate?, durationMinutes?, priority?, notes? }
// Output: MCP content format — { content: [{ type: 'text', text: JSON.stringify(task) }] }
//
// Uses Cloudflare Service Binding (env.API) — NEVER makes HTTP calls to the public API URL.
// NLP path: if `input` is provided, calls POST /v1/tasks/parse via Service Binding,
//           then creates the task with parsed fields.
//
// userId is provided by the OAuth middleware (FR93, Story 10.4) — not caller-supplied.

export interface CreateTaskInput {
  /** Natural language description (triggers NLP parse via POST /v1/tasks/parse) */
  input?: string
  /** Structured: task title (required if input not provided) */
  title?: string
  /** UUID — target list */
  listId?: string
  /** ISO 8601 UTC date string */
  dueDate?: string
  /** Estimated duration in minutes */
  durationMinutes?: number
  /** Task priority level */
  priority?: 'normal' | 'high' | 'critical'
  /** Optional notes */
  notes?: string
}

export interface McpContent {
  type: 'text'
  text: string
}

export interface McpResult {
  content: McpContent[]
  isError?: boolean
}

/**
 * Creates a task via the API Service Binding (POST /v1/tasks).
 *
 * If `input` (natural language) is provided, first calls POST /v1/tasks/parse to
 * extract structured fields, then creates the task with the parsed result.
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 * CRITICAL: Never imports packages/ai — NLP parsing goes through the API Worker.
 */
export async function createTask(
  input: CreateTaskInput,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<McpResult> {

  // Validate: either input (NLP) or title (structured) must be provided
  if (!input.input && !input.title) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: {
              code: 'MISSING_REQUIRED_FIELD',
              message: 'Either input (natural language) or title (structured) must be provided',
            },
          }),
        },
      ],
      isError: true,
    }
  }

  try {
    let taskTitle = input.title
    let taskDueDate = input.dueDate
    let taskListId = input.listId
    let taskNotes = input.notes

    // NLP path: if natural language input provided, parse it first
    if (input.input) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const parseResponse: any = await apiBinding.fetch(
        'https://ontask-api-internal/v1/tasks/parse',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': userId,
          },
          body: JSON.stringify({ utterance: input.input }),
        },
      )

      if (parseResponse.ok) {
        const parseJson = (await parseResponse.json()) as {
          data: {
            title: string
            dueDate?: string | null
            scheduledTime?: string | null
            listId?: string | null
          }
        }
        // Use parsed fields, allowing structured overrides to take precedence
        taskTitle = taskTitle ?? parseJson.data.title
        taskDueDate = taskDueDate ?? parseJson.data.dueDate ?? undefined
        taskListId = taskListId ?? parseJson.data.listId ?? undefined
      } else {
        // NLP parse failed — fall back to using the raw input as the title
        taskTitle = taskTitle ?? input.input
      }
    }

    // Create the task via POST /v1/tasks
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const createResponse: any = await apiBinding.fetch(
      'https://ontask-api-internal/v1/tasks',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
        body: JSON.stringify({
          title: taskTitle,
          notes: taskNotes ?? undefined,
          dueDate: taskDueDate ?? undefined,
          listId: taskListId ?? undefined,
          priority: input.priority ?? undefined,
        }),
      },
    )

    if (!createResponse.ok) {
      const errorBody: string = await createResponse.text()
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: {
                code: 'UPSTREAM_ERROR',
                message: `create_task: API returned ${createResponse.status} — ${errorBody}`,
              },
            }),
          },
        ],
        isError: true,
      }
    }

    const json = (await createResponse.json()) as { data: unknown }
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
