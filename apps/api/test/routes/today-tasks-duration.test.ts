import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Today tasks duration fields (Story 2.8)', () => {
  it('GET /v1/tasks/today — response includes durationMinutes field', async () => {
    const res = await app.request('/v1/tasks/today', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.length).toBeGreaterThan(0)
    const task = body.data[0]
    expect(task).toHaveProperty('durationMinutes')
    expect(typeof task.durationMinutes).toBe('number')
  })

  it('GET /v1/tasks/today — response includes scheduledStartTime field', async () => {
    const res = await app.request('/v1/tasks/today', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const task = body.data[0]
    expect(task).toHaveProperty('scheduledStartTime')
    expect(typeof task.scheduledStartTime).toBe('string')
  })

  it('GET /v1/tasks/today — durationMinutes defaults to 30', async () => {
    const res = await app.request('/v1/tasks/today', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const task = body.data[0]
    expect(task.durationMinutes).toBe(30)
  })
})
