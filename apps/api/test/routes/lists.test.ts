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
    const body = await res.json() as Record<string, any>
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
    const body = await res.json() as Record<string, any>
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
    const body = await res.json() as Record<string, any>
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
    const body = await res.json() as Record<string, any>
    expect(body.data).toBeDefined()
  })

  it('DELETE /v1/lists/:id/archive — archives list and returns 204', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001/archive', {
      method: 'DELETE',
    })

    expect(res.status).toBe(204)
  })
})

// Tests for POST /v1/invitations/:token/accept — Story 9.6 (FR86, AC: 1)
// Validates new isNewUser field in accept response schema.

describe('POST /v1/invitations/:token/accept (Story 9.6 — isNewUser field)', () => {
  it('returns 200 for valid token', async () => {
    const res = await app.request('/v1/invitations/test-token/accept', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    })
    expect(res.status).toBe(200)
  })

  it('response shape includes isNewUser boolean', async () => {
    const res = await app.request('/v1/invitations/test-token/accept', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    })
    const body = await res.json() as { data: { isNewUser: boolean } }
    expect(body.data).toHaveProperty('isNewUser')
    expect(typeof body.data.isNewUser).toBe('boolean')
  })

  it('stub returns isNewUser: false', async () => {
    const res = await app.request('/v1/invitations/test-token/accept', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    })
    const body = await res.json() as { data: { isNewUser: boolean } }
    expect(body.data.isNewUser).toBe(false)
  })

  it('response shape includes all required fields', async () => {
    const res = await app.request('/v1/invitations/test-token/accept', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    })
    const body = await res.json() as { data: Record<string, unknown> }
    expect(body.data).toHaveProperty('listId')
    expect(body.data).toHaveProperty('listTitle')
    expect(body.data).toHaveProperty('invitedByName')
    expect(body.data).toHaveProperty('membershipId')
    expect(body.data).toHaveProperty('isNewUser')
  })
})
