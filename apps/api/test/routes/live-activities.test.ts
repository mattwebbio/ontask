import { describe, expect, it } from 'vitest'

// Tests for Live Activities token endpoint — Story 12.1 (AC: 2, ARCH-28)
//
// Handler is a stub (real DB upsert deferred) — all valid requests return 200.
// Validation errors return 400 (Zod schema enforcement by OpenAPIHono middleware).
// No DATABASE_URL in test environment — stub returns registered:true regardless.

const app = (await import('../../src/index.js')).default

describe('POST /v1/live-activities/token', () => {
  it('returns 200 with registered:true for task_timer with taskId', async () => {
    const res = await app.request('/v1/live-activities/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: '550e8400-e29b-41d4-a716-446655440000',
        activityType: 'task_timer',
        pushToken: 'activitykit-push-token-abc123def456',
        expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { registered: boolean } }
    expect(body.data.registered).toBe(true)
  })

  it('returns 200 with registered:true for commitment_countdown with taskId', async () => {
    const res = await app.request('/v1/live-activities/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: '550e8400-e29b-41d4-a716-446655440001',
        activityType: 'commitment_countdown',
        pushToken: 'activitykit-push-token-xyz789',
        expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { registered: boolean } }
    expect(body.data.registered).toBe(true)
  })

  it('returns 200 with registered:true for watch_mode with null taskId', async () => {
    const res = await app.request('/v1/live-activities/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: null,
        activityType: 'watch_mode',
        pushToken: 'activitykit-push-token-watchmode123',
        expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { registered: boolean } }
    expect(body.data.registered).toBe(true)
  })

  it('returns 400 when activityType is invalid', async () => {
    const res = await app.request('/v1/live-activities/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: '550e8400-e29b-41d4-a716-446655440000',
        activityType: 'invalid_type',
        pushToken: 'activitykit-push-token-abc123',
        expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when pushToken is missing', async () => {
    const res = await app.request('/v1/live-activities/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: '550e8400-e29b-41d4-a716-446655440000',
        activityType: 'task_timer',
        expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when expiresAt is missing or not ISO datetime', async () => {
    const res = await app.request('/v1/live-activities/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        taskId: '550e8400-e29b-41d4-a716-446655440000',
        activityType: 'task_timer',
        pushToken: 'activitykit-push-token-abc123',
        expiresAt: 'not-a-valid-datetime',
      }),
    })

    expect(res.status).toBe(400)
  })
})
