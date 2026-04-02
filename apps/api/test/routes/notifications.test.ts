import { describe, expect, it } from 'vitest'

// Tests for notification endpoints — Story 8.1 (FR42-43, AC: 1, 2, 3)
// Tests validate the HTTP contract only — APNs delivery is stubbed and cannot
// be tested locally (wrangler dev does not support HTTP/2 outbound).

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('POST /v1/notifications/device-token', () => {
  it('returns 200 with registered: true for ios development token', async () => {
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
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.registered).toBe(true)
  })

  it('returns 200 with registered: true for macos production token', async () => {
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
    const body = await res.json() as AnyJson
    expect(body.data.registered).toBe(true)
  })

  it('returns 400 when token is missing', async () => {
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

  it('returns 400 when platform is invalid', async () => {
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

  it('returns 400 when environment is invalid', async () => {
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
  it('returns 200 with empty data array (stub)', async () => {
    const res = await app.request('/v1/notifications/preferences', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(Array.isArray(body.data)).toBe(true)
    expect(body.data).toHaveLength(0)
  })
})

describe('PUT /v1/notifications/preferences', () => {
  it('returns 200 with the submitted preference for global scope', async () => {
    const pref = {
      scope: 'global',
      deviceId: null,
      taskId: null,
      enabled: false,
    }

    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(pref),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.scope).toBe('global')
    expect(body.data.enabled).toBe(false)
    expect(body.data.deviceId).toBeNull()
    expect(body.data.taskId).toBeNull()
  })

  it('returns 200 with device-scoped preference', async () => {
    const pref = {
      scope: 'device',
      deviceId: 'abc123devicetoken',
      taskId: null,
      enabled: true,
    }

    const res = await app.request('/v1/notifications/preferences', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(pref),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.scope).toBe('device')
    expect(body.data.deviceId).toBe('abc123devicetoken')
    expect(body.data.enabled).toBe(true)
  })

  it('returns 400 when scope is invalid', async () => {
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
})
