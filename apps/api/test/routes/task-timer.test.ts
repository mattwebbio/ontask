import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const testTaskId = 'a0000000-0000-4000-8000-000000000001'

describe('Task timer routes', () => {
  it('POST /v1/tasks/{id}/start — returns 200 with startedAt set', async () => {
    const res = await app.request(`/v1/tasks/${testTaskId}/start`, { method: 'POST' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.id).toBe(testTaskId)
    expect(body.data.startedAt).not.toBeNull()
    // startedAt should be an ISO datetime string
    expect(new Date(body.data.startedAt).toISOString()).toBe(body.data.startedAt)
  })

  it('POST /v1/tasks/{id}/pause — returns 200 with startedAt null and elapsedSeconds > 0', async () => {
    const res = await app.request(`/v1/tasks/${testTaskId}/pause`, { method: 'POST' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.id).toBe(testTaskId)
    expect(body.data.startedAt).toBeNull()
    expect(body.data.elapsedSeconds).toBeGreaterThan(0)
  })

  it('POST /v1/tasks/{id}/stop — returns 200 with startedAt null and elapsedSeconds > 0', async () => {
    const res = await app.request(`/v1/tasks/${testTaskId}/stop`, { method: 'POST' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.id).toBe(testTaskId)
    expect(body.data.startedAt).toBeNull()
    expect(body.data.elapsedSeconds).toBeGreaterThan(0)
  })

  it('GET /v1/tasks/current — includes startedAt and elapsedSeconds fields', async () => {
    const res = await app.request('/v1/tasks/current', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data).toHaveProperty('startedAt')
    expect(body.data).toHaveProperty('elapsedSeconds')
  })
})
