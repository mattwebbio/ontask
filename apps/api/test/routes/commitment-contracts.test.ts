import { describe, expect, it } from 'vitest'

// Tests for POST /v1/contracts — Story 10.5 (FR45, AC: 1, 2)
// Extends existing coverage with contract creation endpoint tests.

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const validUuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
const validUserId = '00000000-0000-4000-a000-000000000001'

const validBody = {
  taskId: validUuid,
  stakeAmountCents: 2500,
  charityId: 'american-red-cross',
  deadline: '2026-05-01T00:00:00.000Z',
}

describe('POST /v1/contracts', () => {
  it('with valid body returns 422 NO_PAYMENT_METHOD with setupUrl (stub always has no payment method)', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify(validBody),
    })

    expect(res.status).toBe(422)
    const body = await res.json() as AnyJson
    expect(body.error).toBeDefined()
    expect(body.error.code).toBe('NO_PAYMENT_METHOD')
    expect(body.error.setupUrl).toBe('https://ontaskhq.com/setup')
    expect(body.error.message).toBeTruthy()
  })

  it('with missing taskId returns 422 validation error', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({
        stakeAmountCents: 2500,
        charityId: 'american-red-cross',
        deadline: '2026-05-01T00:00:00.000Z',
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
    expect(res.status).toBeLessThan(500)
  })

  it('with non-UUID taskId returns 422 validation error', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({
        ...validBody,
        taskId: 'not-a-uuid',
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
    expect(res.status).toBeLessThan(500)
  })

  it('with negative stakeAmountCents returns 422 validation error', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({
        ...validBody,
        stakeAmountCents: -100,
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
    expect(res.status).toBeLessThan(500)
  })

  it('with zero stakeAmountCents returns 422 validation error', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({
        ...validBody,
        stakeAmountCents: 0,
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
    expect(res.status).toBeLessThan(500)
  })

  it('with missing charityId returns 422 validation error', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({
        taskId: validUuid,
        stakeAmountCents: 2500,
        deadline: '2026-05-01T00:00:00.000Z',
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
    expect(res.status).toBeLessThan(500)
  })

  it('with missing deadline returns 422 validation error', async () => {
    const res = await app.request('/v1/contracts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({
        taskId: validUuid,
        stakeAmountCents: 2500,
        charityId: 'american-red-cross',
      }),
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
    expect(res.status).toBeLessThan(500)
  })
})
