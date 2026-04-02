import { describe, expect, it } from 'vitest'

// Tests for notification endpoints — Story 8.1 (FR42-43, AC: 1, 2, 3) + Story 8.2 (scheduler)
//
// Handlers remain stubs (real DB deferred) — all valid requests return 200.
// Validation errors return 400 (Zod schema enforcement by OpenAPIHono middleware).

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('POST /v1/notifications/device-token', () => {
  it('returns 200 with registered:true for ios development token', async () => {
    const res = await app.request('/v1/notifications/device-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: 'abc123def456abc123def456abc123def456abc123def456abc123def456abc12',
        platform: 'ios',
        environment: 'development',
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { registered: boolean } }
    expect(body.data.registered).toBe(true)
  })

  it('returns 200 with registered:true for macos production token', async () => {
    const res = await app.request('/v1/notifications/device-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: 'xyz789abc123xyz789abc123xyz789abc123xyz789abc123xyz789abc123xyz78',
        platform: 'macos',
        environment: 'production',
      }),
    })

    expect(res.status).toBe(200)
  })

  it('returns 400 when token is missing (validation — no DB call needed)', async () => {
    const res = await app.request('/v1/notifications/device-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        platform: 'ios',
        environment: 'development',
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when platform is invalid (validation — no DB call needed)', async () => {
    const res = await app.request('/v1/notifications/device-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: 'abc123',
        platform: 'android',
        environment: 'development',
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when environment is invalid (validation — no DB call needed)', async () => {
    const res = await app.request('/v1/notifications/device-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: 'abc123',
        platform: 'ios',
        environment: 'staging',
      }),
    })

    expect(res.status).toBe(400)
  })
})

describe('GET /v1/notifications/preferences', () => {
  it('returns 200 with empty data array', async () => {
    const res = await app.request('/v1/notifications/preferences', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: unknown[] }
    expect(Array.isArray(body.data)).toBe(true)
  })
})

describe('PUT /v1/notifications/preferences', () => {
  it('returns 200 for global scope preference', async () => {
    const pref = { scope: 'global', deviceId: null, taskId: null, enabled: false }

    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(pref),
    })

    expect(res.status).toBe(200)
  })

  it('returns 200 for device-scoped preference', async () => {
    const pref = { scope: 'device', deviceId: 'abc123devicetoken', taskId: null, enabled: true }

    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(pref),
    })

    expect(res.status).toBe(200)
  })

  it('returns 400 when scope is invalid (validation — no DB call needed)', async () => {
    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        scope: 'invalid-scope',
        deviceId: null,
        taskId: null,
        enabled: true,
      }),
    })

    expect(res.status).toBe(400)
  })

  // ── Story 8.2 additional tests — real handler wiring verification ─────────────

  it('returns 400 for task-scoped preference with invalid taskId type (validation)', async () => {
    // Ensures Zod validation runs before DB is attempted
    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        scope: 'task',
        deviceId: null,
        taskId: null,
        // missing 'enabled' field
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when body is missing for PUT preferences', async () => {
    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 for device-token registration with empty token string', async () => {
    // Ensures min(1) validation fires on token field
    const res = await app.request('/v1/notifications/device-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: '',
        platform: 'ios',
        environment: 'development',
      }),
    })

    expect(res.status).toBe(400)
  })
})

// ── Story 8.5 — Notification history routes ───────────────────────────────────

describe('GET /v1/notifications', () => {
  it('returns 200 with data.notifications array and data.unreadCount', async () => {
    const res = await app.request('/v1/notifications', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { notifications: unknown[]; unreadCount: number } }
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('notifications')
    expect(body.data).toHaveProperty('unreadCount')
  })

  it('returns notifications as an array (empty from stub)', async () => {
    const res = await app.request('/v1/notifications', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { notifications: unknown[] } }
    expect(Array.isArray(body.data.notifications)).toBe(true)
  })

  it('returns unreadCount as a non-negative integer', async () => {
    const res = await app.request('/v1/notifications', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { unreadCount: number } }
    expect(typeof body.data.unreadCount).toBe('number')
    expect(body.data.unreadCount).toBeGreaterThanOrEqual(0)
    expect(Number.isInteger(body.data.unreadCount)).toBe(true)
  })
})

describe('PATCH /v1/notifications/read-all', () => {
  it('returns 200 with data.markedRead shape', async () => {
    const res = await app.request('/v1/notifications/read-all', {
      method: 'PATCH',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { markedRead: number } }
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('markedRead')
  })

  it('returns markedRead as a non-negative integer', async () => {
    const res = await app.request('/v1/notifications/read-all', {
      method: 'PATCH',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { data: { markedRead: number } }
    expect(typeof body.data.markedRead).toBe('number')
    expect(body.data.markedRead).toBeGreaterThanOrEqual(0)
    expect(Number.isInteger(body.data.markedRead)).toBe(true)
  })
})
