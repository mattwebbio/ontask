import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

describe('Sections routes', () => {
  it('POST /v1/sections — creates section and returns 201 with correct envelope', async () => {
    const res = await app.request('/v1/sections', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Sprint backlog',
        listId: 'b0000000-0000-4000-8000-000000000001',
      }),
    })

    expect(res.status).toBe(201)
    const body = await res.json()
    expect(body.data.title).toBe('Sprint backlog')
    expect(body.data.listId).toBe('b0000000-0000-4000-8000-000000000001')
    expect(body.data.parentSectionId).toBeNull()
  })

  it('POST /v1/sections — validates required title and listId', async () => {
    const res = await app.request('/v1/sections', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('GET /v1/sections — returns sections for a given listId', async () => {
    const res = await app.request('/v1/sections?listId=b0000000-0000-4000-8000-000000000001', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.data).toBeInstanceOf(Array)
    expect(body.pagination).toBeDefined()
  })

  it('PATCH /v1/sections/:id — updates section and returns 200', async () => {
    const res = await app.request('/v1/sections/c0000000-0000-4000-8000-000000000001', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Updated section' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.data).toBeDefined()
  })

  it('DELETE /v1/sections/:id — deletes section and returns 204', async () => {
    const res = await app.request('/v1/sections/c0000000-0000-4000-8000-000000000001', {
      method: 'DELETE',
    })

    expect(res.status).toBe(204)
  })
})
