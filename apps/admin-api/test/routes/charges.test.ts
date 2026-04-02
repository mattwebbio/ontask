import { describe, expect, it } from 'vitest'

// Tests for admin charge history and refund endpoints — Story 11.3
// AC: 1, 2, 3 — FR52, NFR-S6
// Auth bypass: ADMIN_JWT_SECRET is undefined in Vitest → adminAuthMiddleware skips auth.
// No Authorization header needed.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const app = (await import('../../src/index.js')).default

// Stub fixture IDs used across all tests
const STUB_USER_ID = '00000000-0000-4000-a000-000000000010'
const STUB_CHARGE_ID = '00000000-0000-4000-a000-000000000020'

describe('GET /admin/v1/users/:userId/charges', () => {
  it('returns 200 with array of charge items', async () => {
    const res = await app.request(`/admin/v1/users/${STUB_USER_ID}/charges`)

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(Array.isArray(body.data)).toBe(true)
    expect(body.data.length).toBeGreaterThan(0)
  })

  it('each charge item includes refundStatus field', async () => {
    const res = await app.request(`/admin/v1/users/${STUB_USER_ID}/charges`)

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const item = body.data[0]
    expect(['none', 'partial', 'full']).toContain(item.refundStatus)
    expect(item.amountCents).toBeTypeOf('number')
    expect(item.taskTitle).toBeTypeOf('string')
    expect(item.charityName).toBeTypeOf('string')
  })

  it('returns 200 with stub fixture for any userId (stub does not filter by userId)', async () => {
    // Stub fixture returns the same hardcoded charge regardless of userId.
    // TODO(impl): With real DB, an unknown userId should return an empty array.
    const res = await app.request('/admin/v1/users/00000000-0000-0000-0000-000000000000/charges')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(Array.isArray(body.data)).toBe(true)
  })
})

describe('POST /admin/v1/charges/:chargeId/refund', () => {
  it('returns 200 with refundedAmountCents and refundStatus on valid request', async () => {
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amountCents: 1000, reason: 'Customer request — billing error.' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.chargeId).toBe(STUB_CHARGE_ID)
    expect(body.data.refundedAmountCents).toBe(1000)
    expect(['partial', 'full']).toContain(body.data.refundStatus)
    expect(body.data.processedAt).toBeDefined()
  })

  it('returns 400 when reason is empty string', async () => {
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amountCents: 500, reason: '' }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when reason is absent', async () => {
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amountCents: 500 }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when amountCents is 0', async () => {
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amountCents: 0, reason: 'Test reason' }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when amountCents is negative', async () => {
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amountCents: -100, reason: 'Test reason' }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 400 when amountCents is missing', async () => {
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason: 'Test reason' }),
    })

    expect(res.status).toBe(400)
  })

  it('returns 200 with processedAt timestamp on valid request', async () => {
    const before = new Date().toISOString()
    const res = await app.request(`/admin/v1/charges/${STUB_CHARGE_ID}/refund`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amountCents: 2500, reason: 'Full refund — exceptional circumstance.' }),
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.processedAt).toBeDefined()
    // processedAt should be a valid ISO timestamp at or after test start
    expect(new Date(body.data.processedAt).toISOString()).toBeTypeOf('string')
    expect(body.data.processedAt >= before).toBe(true)
  })
})
