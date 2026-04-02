import { describe, expect, it, vi } from 'vitest'
import { createTask } from '../../src/tools/create-task.js'
import { listTasks } from '../../src/tools/list-tasks.js'
import { updateTask } from '../../src/tools/update-task.js'
import { scheduleTask } from '../../src/tools/schedule-task.js'
import { completeTask } from '../../src/tools/complete-task.js'

// ── MCP Tools Test Suite (Story 10.3) ─────────────────────────────────────────
//
// Tests cover: tool invocation with Service Binding mock, MCP structured result
// format, error handling, and NLP path for create_task.
//
// Mock pattern: apiBinding.fetch is a vi.fn() that returns a fetch-compatible
// Response-like object. Tools are pure functions that accept apiBinding as a
// parameter — no Cloudflare runtime needed.

const stubTask = {
  id: 'a0000000-0000-4000-8000-000000000001',
  userId: '00000000-0000-4000-a000-000000000001',
  title: 'Test Task',
  notes: null,
  dueDate: null,
  listId: null,
  completedAt: null,
  createdAt: '2026-04-01T12:00:00.000Z',
  updatedAt: '2026-04-01T12:00:00.000Z',
  priority: 'normal',
  position: 0,
}

function makeMockApiBinding(overrides: {
  ok?: boolean
  status?: number
  json?: () => Promise<unknown>
  text?: () => Promise<string>
} = {}) {
  const response = {
    ok: overrides.ok ?? true,
    status: overrides.status ?? 200,
    json: overrides.json ?? (async () => ({ data: stubTask })),
    text: overrides.text ?? (async () => ''),
  }
  return {
    fetch: vi.fn().mockResolvedValue(response),
  }
}

describe('create_task', () => {
  it('with structured title returns MCP content format', async () => {
    const mockApi = makeMockApiBinding()
    const result = await createTask({ title: 'Buy groceries' }, mockApi)

    expect(result.isError).toBeUndefined()
    expect(result.content).toHaveLength(1)
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data).toMatchObject({ id: stubTask.id, title: 'Test Task' })
    // Should call POST /v1/tasks
    expect(mockApi.fetch).toHaveBeenCalledWith(
      expect.stringContaining('/v1/tasks'),
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('with natural language input field triggers NLP path (calls parse endpoint)', async () => {
    const parsedResult = { title: 'Call the dentist', dueDate: '2026-04-10T09:00:00.000Z' }
    // First call: parse; second call: create
    const mockApi = {
      fetch: vi
        .fn()
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: async () => ({ data: parsedResult }),
          text: async () => '',
        })
        .mockResolvedValueOnce({
          ok: true,
          status: 201,
          json: async () => ({ data: { ...stubTask, title: 'Call the dentist' } }),
          text: async () => '',
        }),
    }

    const result = await createTask({ input: 'call the dentist Thursday at 2pm' }, mockApi)

    expect(result.isError).toBeUndefined()
    expect(result.content[0].type).toBe('text')

    // Should have called parse endpoint first
    expect(mockApi.fetch).toHaveBeenCalledTimes(2)
    const firstCall = mockApi.fetch.mock.calls[0]
    expect(firstCall[0]).toContain('/v1/tasks/parse')
    const firstBody = JSON.parse(firstCall[1].body as string)
    expect(firstBody.utterance).toBe('call the dentist Thursday at 2pm')

    // Second call should be to create task
    const secondCall = mockApi.fetch.mock.calls[1]
    expect(secondCall[0]).toContain('/v1/tasks')
    expect(secondCall[1].method).toBe('POST')
  })

  it('with neither input nor title returns error MCP result', async () => {
    const mockApi = makeMockApiBinding()
    const result = await createTask({}, mockApi)

    expect(result.isError).toBe(true)
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('MISSING_REQUIRED_FIELD')
    // Should NOT call the API
    expect(mockApi.fetch).not.toHaveBeenCalled()
  })
})

describe('list_tasks', () => {
  it('returns tasks array in MCP content format', async () => {
    const mockApi = makeMockApiBinding({
      json: async () => ({
        data: [stubTask],
        pagination: { cursor: null, hasMore: false },
      }),
    })

    const result = await listTasks({}, mockApi)

    expect(result.isError).toBeUndefined()
    expect(result.content).toHaveLength(1)
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data.tasks).toBeInstanceOf(Array)
    expect(data.tasks[0]).toMatchObject({ id: stubTask.id })
    expect(data.pagination).toMatchObject({ cursor: null, hasMore: false })
  })

  it('passes listId as query param when provided', async () => {
    const mockApi = makeMockApiBinding({
      json: async () => ({ data: [], pagination: { cursor: null, hasMore: false } }),
    })
    const listId = 'b0000000-0000-4000-8000-000000000001'

    await listTasks({ listId }, mockApi)

    const callUrl = mockApi.fetch.mock.calls[0][0] as string
    expect(callUrl).toContain(`listId=${listId}`)
  })
})

describe('update_task', () => {
  it('calls PATCH with correct body and returns MCP content format', async () => {
    const updatedTask = { ...stubTask, title: 'Updated Task Title' }
    const mockApi = makeMockApiBinding({
      json: async () => ({ data: updatedTask }),
    })

    const result = await updateTask(
      { id: stubTask.id, title: 'Updated Task Title', priority: 'high' },
      mockApi,
    )

    expect(result.isError).toBeUndefined()
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data.title).toBe('Updated Task Title')

    // Verify PATCH was called with correct body
    expect(mockApi.fetch).toHaveBeenCalledWith(
      expect.stringContaining(`/v1/tasks/${stubTask.id}`),
      expect.objectContaining({
        method: 'PATCH',
        body: expect.stringContaining('"title":"Updated Task Title"'),
      }),
    )
  })

  it('returns error result when id is missing', async () => {
    const mockApi = makeMockApiBinding()
    // @ts-expect-error — intentionally missing id to test validation
    const result = await updateTask({ title: 'Test' }, mockApi)

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('MISSING_REQUIRED_FIELD')
    expect(mockApi.fetch).not.toHaveBeenCalled()
  })
})

describe('schedule_task', () => {
  it('returns scheduled block in MCP content format', async () => {
    const scheduledBlock = {
      taskId: stubTask.id,
      startTime: '2026-04-02T09:00:00.000Z',
      endTime: '2026-04-02T09:30:00.000Z',
      isLocked: false,
      isAtRisk: false,
    }
    const mockApi = makeMockApiBinding({
      json: async () => ({ data: scheduledBlock }),
    })

    const result = await scheduleTask({ id: stubTask.id }, mockApi)

    expect(result.isError).toBeUndefined()
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data).toMatchObject({
      taskId: stubTask.id,
      startTime: '2026-04-02T09:00:00.000Z',
    })

    // Verify POST was called to the schedule endpoint
    expect(mockApi.fetch).toHaveBeenCalledWith(
      expect.stringContaining(`/v1/tasks/${stubTask.id}/schedule`),
      expect.objectContaining({ method: 'POST' }),
    )
  })
})

describe('complete_task', () => {
  it('marks task complete via correct API call', async () => {
    const completedTask = { ...stubTask, completedAt: '2026-04-01T12:30:00.000Z' }
    const mockApi = makeMockApiBinding({
      json: async () => ({ data: { completedTask, nextInstance: null } }),
    })

    const result = await completeTask({ id: stubTask.id }, mockApi)

    expect(result.isError).toBeUndefined()
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data.completedTask.completedAt).toBeTruthy()
    expect(data.nextInstance).toBeNull()

    // Verify POST to dedicated complete endpoint
    expect(mockApi.fetch).toHaveBeenCalledWith(
      expect.stringContaining(`/v1/tasks/${stubTask.id}/complete`),
      expect.objectContaining({ method: 'POST' }),
    )
  })
})

describe('Service Binding unavailable', () => {
  it('create_task returns graceful MCP error result (not a thrown exception)', async () => {
    const unavailableApi = {
      fetch: vi.fn().mockRejectedValue(new Error('Service binding unavailable')),
    }

    const result = await createTask({ title: 'Test Task' }, unavailableApi)

    // Must NOT throw — must return a structured error result
    expect(result.isError).toBe(true)
    expect(result.content).toHaveLength(1)
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data.error).toBeDefined()
    expect(data.error.code).toBe('UPSTREAM_ERROR')
  })

  it('list_tasks returns graceful MCP error result (not a thrown exception)', async () => {
    const unavailableApi = {
      fetch: vi.fn().mockRejectedValue(new Error('Service binding unavailable')),
    }

    const result = await listTasks({}, unavailableApi)

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('UPSTREAM_ERROR')
  })
})
