import { describe, expect, it } from 'vitest'

// Tests for POST /v1/tasks/{taskId}/proof — Story 7.2 (FR31-32, AC: 1, 3, 4)

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('POST /v1/tasks/{taskId}/proof', () => {
  it('returns 200 with verified: true by default (stub)', async () => {
    const taskId = '550e8400-e29b-41d4-a716-446655440000'
    const res = await app.request(`/v1/tasks/${taskId}/proof`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.verified).toBe(true)
    expect(body.data.reason).toBeNull()
    expect(body.data.taskId).toBe(taskId)
  })

  it('returns verified: false with reason when ?demo=fail is set', async () => {
    const taskId = '550e8400-e29b-41d4-a716-446655440000'
    const res = await app.request(`/v1/tasks/${taskId}/proof?demo=fail`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.verified).toBe(false)
    expect(typeof body.data.reason).toBe('string')
    expect(body.data.reason.length).toBeGreaterThan(0)
    expect(body.data.taskId).toBe(taskId)
  })

  it('reflects the correct taskId in response', async () => {
    const taskId = 'abc12345-0000-0000-0000-000000000001'
    const res = await app.request(`/v1/tasks/${taskId}/proof`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.taskId).toBe(taskId)
  })
})
