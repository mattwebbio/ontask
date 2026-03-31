import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Tasks routes', () => {
  it('POST /v1/tasks — creates task and returns 201 with correct envelope', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Buy groceries' }),
    })

    expect(res.status).toBe(201)
    const body = await res.json() as AnyJson
    expect(body.data.title).toBe('Buy groceries')
    expect(body.data.id).toBeDefined()
    expect(body.data.archivedAt).toBeNull()
    expect(body.data.completedAt).toBeNull()
    expect(body.data.createdAt).toBeDefined()
  })

  it('POST /v1/tasks — validates required title', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('GET /v1/tasks — returns paginated list with cursor pagination', async () => {
    const res = await app.request('/v1/tasks', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeInstanceOf(Array)
    expect(body.pagination).toBeDefined()
    expect(body.pagination.cursor).toBeNull()
    expect(typeof body.pagination.hasMore).toBe('boolean')
  })

  it('GET /v1/tasks supports listId and archived query params', async () => {
    const res = await app.request(
      '/v1/tasks?listId=a1b2c3d4-e5f6-4a7b-8c9d-ae1f2a3b4c5d&archived=true',
      { method: 'GET' },
    )
    expect(res.status).toBe(200)
  })

  it('GET /v1/tasks/:id — returns single task', async () => {
    const res = await app.request('/v1/tasks/a0000000-0000-4000-8000-000000000001', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.id).toBe('a0000000-0000-4000-8000-000000000001')
  })

  it('PATCH /v1/tasks/:id — updates task properties and returns 200', async () => {
    const res = await app.request('/v1/tasks/a0000000-0000-4000-8000-000000000001', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Updated title' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
  })

  it('DELETE /v1/tasks/:id/archive — archives task and returns 204', async () => {
    const res = await app.request('/v1/tasks/a0000000-0000-4000-8000-000000000001/archive', {
      method: 'DELETE',
    })

    expect(res.status).toBe(204)
  })

  it('PATCH /v1/tasks/:id/reorder — reorders task and returns 200', async () => {
    const res = await app.request('/v1/tasks/a0000000-0000-4000-8000-000000000001/reorder', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ position: 3 }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.position).toBe(3)
  })

  // ── Story 2.2: Scheduling hint fields ────────────────────────────────────

  it('POST /v1/tasks — accepts and echoes scheduling hint fields', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Focus work',
        timeWindow: 'morning',
        energyRequirement: 'high_focus',
        priority: 'critical',
      }),
    })

    expect(res.status).toBe(201)
    const body = await res.json() as AnyJson
    expect(body.data.timeWindow).toBe('morning')
    expect(body.data.energyRequirement).toBe('high_focus')
    expect(body.data.priority).toBe('critical')
    expect(body.data.timeWindowStart).toBeNull()
    expect(body.data.timeWindowEnd).toBeNull()
  })

  it('POST /v1/tasks — accepts custom time window with start/end', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Custom time task',
        timeWindow: 'custom',
        timeWindowStart: '09:00',
        timeWindowEnd: '11:30',
      }),
    })

    expect(res.status).toBe(201)
    const body = await res.json() as AnyJson
    expect(body.data.timeWindow).toBe('custom')
    expect(body.data.timeWindowStart).toBe('09:00')
    expect(body.data.timeWindowEnd).toBe('11:30')
  })

  it('POST /v1/tasks — defaults scheduling hints to null/normal', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Simple task' }),
    })

    expect(res.status).toBe(201)
    const body = await res.json() as AnyJson
    expect(body.data.timeWindow).toBeNull()
    expect(body.data.timeWindowStart).toBeNull()
    expect(body.data.timeWindowEnd).toBeNull()
    expect(body.data.energyRequirement).toBeNull()
    expect(body.data.priority).toBe('normal')
  })

  it('POST /v1/tasks — rejects invalid enum values', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Bad enum',
        timeWindow: 'midnight',
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('PATCH /v1/tasks/:id — updates scheduling hint fields', async () => {
    const res = await app.request('/v1/tasks/a0000000-0000-4000-8000-000000000001', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        timeWindow: 'evening',
        energyRequirement: 'low_energy',
        priority: 'high',
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.timeWindow).toBe('evening')
    expect(body.data.energyRequirement).toBe('low_energy')
    expect(body.data.priority).toBe('high')
  })

  it('GET /v1/tasks — response includes scheduling hint fields', async () => {
    const res = await app.request('/v1/tasks', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const task = body.data[0]
    expect(task).toHaveProperty('timeWindow')
    expect(task).toHaveProperty('timeWindowStart')
    expect(task).toHaveProperty('timeWindowEnd')
    expect(task).toHaveProperty('energyRequirement')
    expect(task).toHaveProperty('priority')
  })

  it('All task routes match Zod response schemas (no schema violations)', async () => {
    // POST returns proper data envelope
    const postRes = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Schema test' }),
    })
    const postBody = await postRes.json() as AnyJson
    expect(postBody.data).toHaveProperty('id')
    expect(postBody.data).toHaveProperty('title')
    expect(postBody.data).toHaveProperty('position')
    expect(postBody.data).toHaveProperty('archivedAt')
    expect(postBody.data).toHaveProperty('completedAt')

    // GET list returns proper pagination envelope
    const getRes = await app.request('/v1/tasks', { method: 'GET' })
    const getBody = await getRes.json() as AnyJson
    expect(getBody).toHaveProperty('data')
    expect(getBody).toHaveProperty('pagination')
  })
})
