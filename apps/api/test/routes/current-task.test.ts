import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Current task route', () => {
  it('GET /v1/tasks/current — returns single task with enriched fields', async () => {
    const res = await app.request('/v1/tasks/current', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data).not.toBeNull()
    expect(body.data.id).toBeDefined()
    expect(body.data.title).toBeDefined()
  })

  it('GET /v1/tasks/current — enriched fields are present', async () => {
    const res = await app.request('/v1/tasks/current', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toHaveProperty('listName')
    expect(body.data).toHaveProperty('assignorName')
    expect(body.data).toHaveProperty('stakeAmountCents')
    expect(body.data).toHaveProperty('proofMode')
  })

  it('GET /v1/tasks/current — stub returns expected default values', async () => {
    const res = await app.request('/v1/tasks/current', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.listName).toBe('Personal')
    expect(body.data.assignorName).toBeNull()
    expect(body.data.stakeAmountCents).toBeNull()
    expect(body.data.proofMode).toBe('standard')
  })

  it('GET /v1/tasks/current — response is NOT an array (single task envelope)', async () => {
    const res = await app.request('/v1/tasks/current', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    // data is an object, not an array
    expect(Array.isArray(body.data)).toBe(false)
    // No pagination envelope
    expect(body.pagination).toBeUndefined()
  })

  it('GET /v1/tasks/current — route is not swallowed by :id param', async () => {
    const res = await app.request('/v1/tasks/current', { method: 'GET' })
    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    // If swallowed by :id, it would try to parse "current" as UUID and fail
    expect(body.data.listName).toBeDefined()
  })
})
