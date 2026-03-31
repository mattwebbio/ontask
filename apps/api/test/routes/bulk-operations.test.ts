import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Bulk Operations routes', () => {
  it('POST /v1/tasks/bulk/reschedule — returns succeeded IDs with updated dueDate', async () => {
    const res = await app.request('/v1/tasks/bulk/reschedule', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskIds: [
          'a0000000-0000-4000-8000-000000000001',
          'a0000000-0000-4000-8000-000000000002',
        ],
        dueDate: '2026-04-15T09:00:00.000Z',
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.succeeded).toEqual([
      'a0000000-0000-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000002',
    ])
    expect(body.data.failed).toEqual([])
  })

  it('POST /v1/tasks/bulk/complete — returns succeeded IDs', async () => {
    const res = await app.request('/v1/tasks/bulk/complete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskIds: [
          'a0000000-0000-4000-8000-000000000001',
          'a0000000-0000-4000-8000-000000000002',
        ],
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.succeeded).toEqual([
      'a0000000-0000-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000002',
    ])
    expect(body.data.failed).toEqual([])
  })

  it('POST /v1/tasks/bulk/delete — returns succeeded IDs', async () => {
    const res = await app.request('/v1/tasks/bulk/delete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskIds: [
          'a0000000-0000-4000-8000-000000000001',
          'a0000000-0000-4000-8000-000000000002',
        ],
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.succeeded).toEqual([
      'a0000000-0000-4000-8000-000000000001',
      'a0000000-0000-4000-8000-000000000002',
    ])
    expect(body.data.failed).toEqual([])
  })
})
