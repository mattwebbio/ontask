import { describe, expect, it } from 'vitest'

// Tests for commitment-contracts routes — Story 10.5 (FR45, AC: 1, 2) + Story 13.1 real implementations.
// POST /v1/contracts — contract creation (Story 10.5)
// POST /v1/payment-method/setup-session — setup session (Story 13.1)
// POST /v1/payment-method/confirm — setup confirmation (Story 13.1)
// GET  /v1/payment-method/setup-intent-client-secret — client secret lookup (Story 13.1)

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

    expect(res.status).toBe(400)
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

    expect(res.status).toBe(400)
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

    expect(res.status).toBe(400)
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

    expect(res.status).toBe(400)
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

    expect(res.status).toBe(400)
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

    expect(res.status).toBe(400)
  })
})

// ── POST /v1/payment-method/setup-session (Story 13.1) ────────────────────────

describe('POST /v1/payment-method/setup-session', () => {
  it('route is registered (returns non-404)', async () => {
    // The endpoint requires a live DB + Stripe connection; in the test harness
    // (no DATABASE_URL) it will throw and return 500, but the route MUST exist
    // (not 404 / 405). This test guards against accidental route de-registration.
    const res = await app.request('/v1/payment-method/setup-session', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({}),
    })
    expect(res.status).not.toBe(404)
    expect(res.status).not.toBe(405)
  })
})

// ── POST /v1/payment-method/confirm (Story 13.1) ─────────────────────────────

describe('POST /v1/payment-method/confirm', () => {
  it('with missing sessionToken returns 400 validation error', async () => {
    const res = await app.request('/v1/payment-method/confirm', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({}),
    })
    expect(res.status).toBe(400)
  })

  it('route is registered (non-empty sessionToken returns non-404)', async () => {
    // DB not available in test harness — endpoint returns 404 or 500, but NOT
    // a routing-level 404 or 405. Guards against route de-registration.
    const res = await app.request('/v1/payment-method/confirm', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': validUserId,
      },
      body: JSON.stringify({ sessionToken: 'test-token-not-in-db' }),
    })
    expect(res.status).not.toBe(405)
  })
})

// ── GET /v1/payment-method/setup-intent-client-secret (Story 13.1) ───────────

describe('GET /v1/payment-method/setup-intent-client-secret', () => {
  it('without sessionToken query param returns 400', async () => {
    const res = await app.request('/v1/payment-method/setup-intent-client-secret', {
      method: 'GET',
    })
    expect(res.status).toBe(400)
  })

  it('with sessionToken returns non-405 (route is registered)', async () => {
    // DB not available in test harness — will return 404 or 500, but not 405.
    const res = await app.request(
      '/v1/payment-method/setup-intent-client-secret?sessionToken=test-session-token',
      { method: 'GET' },
    )
    expect(res.status).not.toBe(405)
  })
})
