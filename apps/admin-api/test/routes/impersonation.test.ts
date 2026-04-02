import { describe, expect, it } from 'vitest'

// Tests for admin impersonation endpoints — Story 11.4
// AC: 1, 2, 3 — FR53, NFR-S6
// Auth bypass: ADMIN_JWT_SECRET is undefined in Vitest → adminAuthMiddleware skips auth.
// No Authorization header needed.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const app = (await import('../../src/index.js')).default

const STUB_USER_ID = '00000000-0000-4000-a000-000000000010'
const STUB_SESSION_ID = '00000000-0000-4000-a000-000000000030'

describe('POST /admin/v1/users/:userId/impersonate', () => {
  it('returns 200 with sessionId, userId, operatorEmail, expiresAt on valid request', async () => {
    const res = await app.request(`/admin/v1/users/${STUB_USER_ID}/impersonate`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.sessionId).toBeDefined()
    expect(typeof body.data.sessionId).toBe('string')
    expect(body.data.userId).toBe(STUB_USER_ID)
    expect(body.data.expiresAt).toBeDefined()
    expect(body.data.startedAt).toBeDefined()
    expect(body.data.userEmail).toBeDefined()
  })

  it('expiresAt is approximately 30 minutes in the future', async () => {
    const before = Date.now()
    const res = await app.request(`/admin/v1/users/${STUB_USER_ID}/impersonate`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const expiresAt = new Date(body.data.expiresAt).getTime()
    const expectedExpiry = before + 30 * 60 * 1000

    // expiresAt should be within 5 seconds of now + 30 min
    expect(expiresAt).toBeGreaterThanOrEqual(expectedExpiry - 5000)
    expect(expiresAt).toBeLessThanOrEqual(expectedExpiry + 5000)
  })

  it('returns a unique sessionId on each call', async () => {
    const res1 = await app.request(`/admin/v1/users/${STUB_USER_ID}/impersonate`, {
      method: 'POST',
    })
    const res2 = await app.request(`/admin/v1/users/${STUB_USER_ID}/impersonate`, {
      method: 'POST',
    })

    expect(res1.status).toBe(200)
    expect(res2.status).toBe(200)
    const body1 = await res1.json() as AnyJson
    const body2 = await res2.json() as AnyJson
    expect(body1.data.sessionId).not.toBe(body2.data.sessionId)
  })
})

describe('POST /admin/v1/impersonation/:sessionId/end', () => {
  it('returns 200 with sessionId, endedAt, reason=operator_ended', async () => {
    const res = await app.request(`/admin/v1/impersonation/${STUB_SESSION_ID}/end`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.sessionId).toBe(STUB_SESSION_ID)
    expect(body.data.endedAt).toBeDefined()
    expect(new Date(body.data.endedAt).toISOString()).toBeTypeOf('string')
    expect(body.data.reason).toBe('operator_ended')
  })
})

describe('POST /admin/v1/impersonation/:sessionId/log-action', () => {
  it('returns 200 with logId, sessionId, loggedAt on valid actionDetail', async () => {
    const res = await app.request(`/admin/v1/impersonation/${STUB_SESSION_ID}/log-action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: STUB_USER_ID, actionDetail: 'Operator viewed task list' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.logId).toBeDefined()
    expect(typeof body.data.logId).toBe('string')
    expect(body.data.sessionId).toBe(STUB_SESSION_ID)
    expect(body.data.loggedAt).toBeDefined()
    expect(new Date(body.data.loggedAt).toISOString()).toBeTypeOf('string')
  })

  it('returns 400 when actionDetail is empty string', async () => {
    const res = await app.request(`/admin/v1/impersonation/${STUB_SESSION_ID}/log-action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: STUB_USER_ID, actionDetail: '' }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when actionDetail is absent', async () => {
    const res = await app.request(`/admin/v1/impersonation/${STUB_SESSION_ID}/log-action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: STUB_USER_ID }),
    })

    expect(res.status).toBe(400)
  })
})
