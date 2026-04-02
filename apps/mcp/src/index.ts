import { Hono } from 'hono'
import { getCommitmentStatus } from './tools/get-commitment-status.js'
import { createTask } from './tools/create-task.js'
import { listTasks } from './tools/list-tasks.js'
import { updateTask } from './tools/update-task.js'
import { scheduleTask } from './tools/schedule-task.js'
import { completeTask } from './tools/complete-task.js'
import { applyOauthMiddleware, requireScope } from './middleware/oauth.js'

// ── OnTask MCP Server ─────────────────────────────────────────────────────────
// Cloudflare Worker hosting the On Task MCP server.
// All tools proxy to the API Worker via the env.API Service Binding.
//
// CRITICAL: Never make HTTP calls to api.ontaskhq.com — always use env.API.
//
// Tool manifest (FR45):
//   create_task, list_tasks, update_task, schedule_task, complete_task
//
// Transport: HTTP routing pattern with MCP-structured results.
//   Each tool is exposed as a POST /tools/<tool-name> endpoint.
//   The MCP tool manifest is available at GET /tools (discovery endpoint).
//
// Auth: OAuth Bearer token middleware (FR93, Story 10.4) protects /tools/* routes.
//   Token validation delegates to the API Worker via Service Binding.
//
// TODO(impl): Replace HTTP routing with MCP SDK SSE transport (Story 10.3 follow-up)
//             when bundle size constraints are resolved for Cloudflare Workers.
//
// See architecture.md line 799–827 for MCP Worker structure.

interface Env {
  // Cloudflare Service Binding to the ontask-api Worker.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  API?: { fetch: (...args: any[]) => Promise<any> }
}

const app = new Hono<{ Bindings: Env }>()

// ── OAuth middleware (FR93) ────────────────────────────────────────────────────
// IMPORTANT: Must be applied BEFORE tool routes are registered.
// Protects all /tools/* routes. GET /tools and GET / remain unauthenticated.
applyOauthMiddleware(app)

// ── MCP tool manifest ─────────────────────────────────────────────────────────
// GET /tools — returns the full tool manifest for AI client discovery (AC: 2).

const toolManifest = {
  tools: [
    {
      name: 'create_task',
      description:
        'Create a new task. Accepts structured properties or a natural language description that is parsed by an LLM before creating.',
      inputSchema: {
        type: 'object',
        properties: {
          input: {
            type: 'string',
            description: 'Natural language description of the task (triggers NLP parse via API)',
          },
          title: {
            type: 'string',
            description: 'Structured: task title (required if input not provided)',
          },
          listId: {
            type: 'string',
            description: 'UUID — target list',
          },
          dueDate: {
            type: 'string',
            description: 'ISO 8601 UTC date string',
          },
          durationMinutes: {
            type: 'number',
            description: 'Estimated duration in minutes',
          },
          priority: {
            type: 'string',
            enum: ['normal', 'high', 'critical'],
            description: 'Task priority level',
          },
          notes: {
            type: 'string',
            description: 'Optional task notes',
          },
        },
      },
    },
    {
      name: 'list_tasks',
      description:
        'List tasks for the current user. Supports filtering by list ID, completion status, and scheduling status.',
      inputSchema: {
        type: 'object',
        properties: {
          listId: {
            type: 'string',
            description: 'Filter by list UUID',
          },
          completed: {
            type: 'boolean',
            description: 'Filter by completion status',
          },
          cursor: {
            type: 'string',
            description: 'Cursor for pagination (ARCH-14: cursor-based pagination)',
          },
        },
      },
    },
    {
      name: 'update_task',
      description: "Update an existing task's properties (title, due date, duration, priority, etc.).",
      inputSchema: {
        type: 'object',
        required: ['id'],
        properties: {
          id: {
            type: 'string',
            description: 'UUID of the task to update',
          },
          title: {
            type: 'string',
            description: 'New task title',
          },
          notes: {
            type: 'string',
            description: 'Updated notes',
          },
          dueDate: {
            type: 'string',
            description: 'ISO 8601 UTC date string',
          },
          listId: {
            type: 'string',
            description: 'UUID of the target list',
          },
          priority: {
            type: 'string',
            enum: ['normal', 'high', 'critical'],
            description: 'Task priority level',
          },
        },
      },
    },
    {
      name: 'schedule_task',
      description: 'Trigger the scheduling engine for a task and return the resulting scheduled time block.',
      inputSchema: {
        type: 'object',
        required: ['id'],
        properties: {
          id: {
            type: 'string',
            description: 'UUID of the task to schedule',
          },
        },
      },
    },
    {
      name: 'complete_task',
      description: 'Mark a task as complete.',
      inputSchema: {
        type: 'object',
        required: ['id'],
        properties: {
          id: {
            type: 'string',
            description: 'UUID of the task to complete',
          },
        },
      },
    },
  ],
}

app.get('/', (c) => {
  return c.text('OnTask MCP Server')
})

// ── Tool discovery endpoint ───────────────────────────────────────────────────
// GET /tools — returns MCP tool manifest for AI client discovery (AC: 2)

app.get('/tools', (c) => {
  return c.json(toolManifest)
})

// ── Tool: get_commitment_status ───────────────────────────────────────────────
// GET /tools/get-commitment-status?id=<uuid>
//
// Reads the status of a commitment contract by its ID.
// Returns status (active/charged/cancelled/disputed), stake amount, and
// charge timestamp if charged. Scoped to authenticated user's contracts only.
// Required scope: contracts:read

app.get('/tools/get-commitment-status', async (c) => {
  const id = c.req.query('id')
  if (!id) {
    return c.json({ error: { code: 'MISSING_ID', message: 'id query parameter is required' } }, 400)
  }

  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }, 503)
  }

  const { userId, scopes } = c.get('mcpAuth')

  if (!requireScope(scopes, 'contracts:read')) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'contracts:read scope required' } }) }], isError: true },
      403,
    )
  }

  try {
    const result = await getCommitmentStatus({ id }, apiBinding, userId)
    return c.json({ data: result }, 200)
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return c.json({ error: { code: 'UPSTREAM_ERROR', message } }, 502)
  }
})

// ── Tool: create_task ─────────────────────────────────────────────────────────
// POST /tools/create-task
// Body: { input?, title?, listId?, dueDate?, durationMinutes?, priority?, notes? }
// Required scope: tasks:write

app.post('/tools/create-task', async (c) => {
  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }) }], isError: true },
      503,
    )
  }

  const { userId, scopes } = c.get('mcpAuth')

  if (!requireScope(scopes, 'tasks:write')) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:write scope required' } }) }], isError: true },
      403,
    )
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let body: any
  try {
    body = await c.req.json()
  } catch {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' } }) }], isError: true },
      400,
    )
  }

  const result = await createTask(body, apiBinding, userId)
  return c.json(result)
})

// ── Tool: list_tasks ──────────────────────────────────────────────────────────
// POST /tools/list-tasks
// Body: { listId?, completed?, cursor? }
// Required scope: tasks:read

app.post('/tools/list-tasks', async (c) => {
  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }) }], isError: true },
      503,
    )
  }

  const { userId, scopes } = c.get('mcpAuth')

  if (!requireScope(scopes, 'tasks:read')) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:read scope required' } }) }], isError: true },
      403,
    )
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let body: any = {}
  try {
    body = await c.req.json()
  } catch {
    // Body is optional for list_tasks — continue with empty object
  }

  const result = await listTasks(body, apiBinding, userId)
  return c.json(result)
})

// ── Tool: update_task ─────────────────────────────────────────────────────────
// POST /tools/update-task
// Body: { id, title?, notes?, dueDate?, listId?, priority? }
// Required scope: tasks:write

app.post('/tools/update-task', async (c) => {
  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }) }], isError: true },
      503,
    )
  }

  const { userId, scopes } = c.get('mcpAuth')

  if (!requireScope(scopes, 'tasks:write')) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:write scope required' } }) }], isError: true },
      403,
    )
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let body: any
  try {
    body = await c.req.json()
  } catch {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' } }) }], isError: true },
      400,
    )
  }

  const result = await updateTask(body, apiBinding, userId)
  return c.json(result)
})

// ── Tool: schedule_task ───────────────────────────────────────────────────────
// POST /tools/schedule-task
// Body: { id }
// Required scope: tasks:write

app.post('/tools/schedule-task', async (c) => {
  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }) }], isError: true },
      503,
    )
  }

  const { userId, scopes } = c.get('mcpAuth')

  if (!requireScope(scopes, 'tasks:write')) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:write scope required' } }) }], isError: true },
      403,
    )
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let body: any
  try {
    body = await c.req.json()
  } catch {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' } }) }], isError: true },
      400,
    )
  }

  const result = await scheduleTask(body, apiBinding, userId)
  return c.json(result)
})

// ── Tool: complete_task ───────────────────────────────────────────────────────
// POST /tools/complete-task
// Body: { id }
// Required scope: tasks:write

app.post('/tools/complete-task', async (c) => {
  const apiBinding = c.env.API
  if (!apiBinding) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }) }], isError: true },
      503,
    )
  }

  const { userId, scopes } = c.get('mcpAuth')

  if (!requireScope(scopes, 'tasks:write')) {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:write scope required' } }) }], isError: true },
      403,
    )
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let body: any
  try {
    body = await c.req.json()
  } catch {
    return c.json(
      { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' } }) }], isError: true },
      400,
    )
  }

  const result = await completeTask(body, apiBinding, userId)
  return c.json(result)
})

export default app
