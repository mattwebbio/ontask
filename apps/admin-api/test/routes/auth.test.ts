import { describe, expect, it } from 'vitest'

// Tests for operator authentication endpoint — Story 11.1
// AC: 2 — FR51, NFR-S6
// POST /admin/v1/auth/login — validate format, issue JWT (stub: accept all format-valid creds)

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('POST /admin/v1/auth/login', () => {
  it('returns 200 with token and operatorEmail when credentials are valid format', async () => {
    const res = await app.request('/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'operator@ontaskhq.com',
        password: 'supersecret',
        totpCode: '123456',
      }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(typeof body.data.token).toBe('string')
    expect(body.data.token.length).toBeGreaterThan(0)
    expect(body.data.operatorEmail).toBe('operator@ontaskhq.com')
  })

  it('returns 400 when totpCode is missing', async () => {
    const res = await app.request('/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'operator@ontaskhq.com',
        password: 'supersecret',
        // totpCode omitted
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when totpCode is wrong length (not 6 digits)', async () => {
    const res = await app.request('/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'operator@ontaskhq.com',
        password: 'supersecret',
        totpCode: '123', // 3 digits — too short
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when email format is invalid', async () => {
    const res = await app.request('/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'not-an-email',
        password: 'supersecret',
        totpCode: '123456',
      }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when password is empty string', async () => {
    const res = await app.request('/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'operator@ontaskhq.com',
        password: '',
        totpCode: '123456',
      }),
    })

    expect(res.status).toBe(400)
  })
})
