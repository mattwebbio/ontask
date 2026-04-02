import { describe, expect, it } from 'vitest'

// Tests for admin dispute review and resolution endpoints — Story 7.9
// AC: 1, 2, 3 — FR41, NFR-R3

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('GET /admin/v1/disputes', () => {
  it('returns 200 with array containing status: pending items', async () => {
    const res = await app.request('/admin/v1/disputes')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(Array.isArray(body.data)).toBe(true)
    expect(body.data.length).toBeGreaterThan(0)
    expect(body.data[0].status).toBe('pending')
  })

  it('includes slaStatus field on each dispute item', async () => {
    const res = await app.request('/admin/v1/disputes')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const item = body.data[0]
    expect(['ok', 'amber', 'red']).toContain(item.slaStatus)
    expect(typeof item.hoursElapsed).toBe('number')
  })
})

describe('GET /admin/v1/disputes/:id', () => {
  it('returns 200 with dispute detail including slaStatus field', async () => {
    const id = '00000000-0000-4000-a000-000000000079'
    const res = await app.request(`/admin/v1/disputes/${id}`)

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.id).toBe(id)
    expect(['ok', 'amber', 'red']).toContain(body.data.slaStatus)
    expect(body.data.taskTitle).toBeDefined()
    expect(body.data.aiVerificationResult).toBeDefined()
  })

  it('returns 404 for unknown dispute id', async () => {
    const res = await app.request('/admin/v1/disputes/00000000-0000-4000-a000-000000000000')

    expect(res.status).toBe(404)
    const body = await res.json() as AnyJson
    expect(body.error).toBeDefined()
    expect(body.error.code).toBe('DISPUTE_NOT_FOUND')
  })
})

describe('POST /admin/v1/disputes/:id/resolve', () => {
  const id = '00000000-0000-4000-a000-000000000079'

  it('returns 200 with status: approved when decision is approved with operatorNote', async () => {
    const res = await app.request(`/admin/v1/disputes/${id}/resolve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ decision: 'approved', operatorNote: 'Photo clearly shows task completion.' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.id).toBe(id)
    expect(body.data.status).toBe('approved')
    expect(body.data.resolvedAt).toBeDefined()
  })

  it('returns 200 with status: rejected when decision is rejected with operatorNote', async () => {
    const res = await app.request(`/admin/v1/disputes/${id}/resolve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ decision: 'rejected', operatorNote: 'Proof does not match task requirements.' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.status).toBe('rejected')
    expect(body.data.resolvedAt).toBeDefined()
  })

  it('returns 400 when operatorNote is missing (empty string)', async () => {
    const res = await app.request(`/admin/v1/disputes/${id}/resolve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ decision: 'approved', operatorNote: '' }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when operatorNote is absent', async () => {
    const res = await app.request(`/admin/v1/disputes/${id}/resolve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ decision: 'approved' }),
    })

    expect(res.status).toBe(400)
  })
})
