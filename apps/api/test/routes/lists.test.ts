import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

describe('Lists routes', () => {
  it('POST /v1/lists — creates list and returns 201 with correct envelope', async () => {
    const res = await app.request('/v1/lists', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Work tasks' }),
    })

    expect(res.status).toBe(201)
    const body = await res.json()
    expect(body.data.title).toBe('Work tasks')
    expect(body.data.id).toBeDefined()
    expect(body.data.archivedAt).toBeNull()
    expect(body.data.defaultDueDate).toBeNull()
  })

  it('POST /v1/lists — validates required title', async () => {
    const res = await app.request('/v1/lists', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('GET /v1/lists — returns paginated list with cursor pagination', async () => {
    const res = await app.request('/v1/lists', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.data).toBeInstanceOf(Array)
    expect(body.pagination).toBeDefined()
    expect(body.pagination.cursor).toBeNull()
    expect(typeof body.pagination.hasMore).toBe('boolean')
  })

  it('GET /v1/lists/:id — returns single list with sections array', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.data.id).toBe('b0000000-0000-4000-8000-000000000001')
    expect(body.data.sections).toBeInstanceOf(Array)
  })

  it('PATCH /v1/lists/:id — updates list properties and returns 200', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Updated list' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.data).toBeDefined()
  })

  it('DELETE /v1/lists/:id/archive — archives list and returns 204', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001/archive', {
      method: 'DELETE',
    })

    expect(res.status).toBe(204)
  })
})
