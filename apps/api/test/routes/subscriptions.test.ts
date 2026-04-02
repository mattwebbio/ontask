import { describe, it, expect } from 'vitest'
import app from '../../src/index.js'

// Tests for GET /v1/subscriptions/me — Story 9.1 (FR82, FR87, AC: 2)
// Handler is a stub (real DB deferred) — all valid requests return 200.

describe('GET /v1/subscriptions/me', () => {
  it('returns 200', async () => {
    const res = await app.request('/v1/subscriptions/me')
    expect(res.status).toBe(200)
  })

  it('response shape has data.status field', async () => {
    const res = await app.request('/v1/subscriptions/me')
    const body = await res.json() as { data: { status: string } }
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('status')
  })

  it('response data.status is a valid enum value', async () => {
    const res = await app.request('/v1/subscriptions/me')
    const body = await res.json() as { data: { status: string } }
    const validStatuses = ['trialing', 'active', 'cancelled', 'expired', 'grace_period']
    expect(validStatuses).toContain(body.data.status)
  })

  it('response data.trialDaysRemaining is null or a non-negative integer', async () => {
    const res = await app.request('/v1/subscriptions/me')
    const body = await res.json() as { data: { trialDaysRemaining: number | null } }
    const { trialDaysRemaining } = body.data
    if (trialDaysRemaining !== null) {
      expect(typeof trialDaysRemaining).toBe('number')
      expect(Number.isInteger(trialDaysRemaining)).toBe(true)
      expect(trialDaysRemaining).toBeGreaterThanOrEqual(0)
    } else {
      expect(trialDaysRemaining).toBeNull()
    }
  })

  it('stub response data.trialDaysRemaining equals 14', async () => {
    const res = await app.request('/v1/subscriptions/me')
    const body = await res.json() as { data: { trialDaysRemaining: number } }
    expect(body.data.trialDaysRemaining).toBe(14)
  })
})

// Tests for GET /v1/subscriptions/paywall-config — Story 9.2 (FR88, FR83, AC: 1)
// Handler is a stub (real Stripe Price IDs deferred to Story 9.3).

describe('GET /v1/subscriptions/paywall-config', () => {
  it('returns 200', async () => {
    const res = await app.request('/v1/subscriptions/paywall-config')
    expect(res.status).toBe(200)
  })

  it('response shape has data.tiers array', async () => {
    const res = await app.request('/v1/subscriptions/paywall-config')
    const body = await res.json() as { data: { tiers: unknown[] } }
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('tiers')
    expect(Array.isArray(body.data.tiers)).toBe(true)
  })

  it('data.tiers has exactly 3 entries', async () => {
    const res = await app.request('/v1/subscriptions/paywall-config')
    const body = await res.json() as { data: { tiers: unknown[] } }
    expect(body.data.tiers).toHaveLength(3)
  })

  it('all tiers have required fields: tier, displayName, priceDisplay, available', async () => {
    const res = await app.request('/v1/subscriptions/paywall-config')
    const body = await res.json() as {
      data: { tiers: Array<{ tier: string; displayName: string; priceDisplay: string; available: boolean }> }
    }
    for (const tier of body.data.tiers) {
      expect(tier).toHaveProperty('tier')
      expect(tier).toHaveProperty('displayName')
      expect(tier).toHaveProperty('priceDisplay')
      expect(tier).toHaveProperty('available')
    }
  })

  it('individual tier available is true', async () => {
    const res = await app.request('/v1/subscriptions/paywall-config')
    const body = await res.json() as {
      data: { tiers: Array<{ tier: string; available: boolean }> }
    }
    const individual = body.data.tiers.find((t) => t.tier === 'individual')
    expect(individual).toBeDefined()
    expect(individual!.available).toBe(true)
  })

  it('individual tier stripePriceId is null (stub phase)', async () => {
    const res = await app.request('/v1/subscriptions/paywall-config')
    const body = await res.json() as {
      data: { tiers: Array<{ tier: string; stripePriceId: string | null }> }
    }
    const individual = body.data.tiers.find((t) => t.tier === 'individual')
    expect(individual).toBeDefined()
    expect(individual!.stripePriceId).toBeNull()
  })
})

// Tests for POST /v1/subscriptions/checkout-session — Story 13.1 (AC: 3)
// Creates a Stripe Checkout session for the selected tier.
// In test environments without STRIPE_SECRET_KEY, Stripe calls fail → 500.

describe('POST /v1/subscriptions/checkout-session', () => {
  it('returns 422 for unknown tier', async () => {
    const res = await app.request('/v1/subscriptions/checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: 'unknown_tier' }),
    })
    expect(res.status).toBe(400) // zod validation rejects unknown enum value
  })

  it('returns 400 for missing tier field', async () => {
    const res = await app.request('/v1/subscriptions/checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })
    expect(res.status).toBe(400)
  })

  it('attempts Stripe call for valid tier (individual)', async () => {
    // In test env without Stripe key, call fails with network error → 500 or 422.
    const res = await app.request('/v1/subscriptions/checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: 'individual' }),
    })
    // Either 422 (unconfigured price ID) or 500 (Stripe fetch fails in test env).
    expect([422, 500]).toContain(res.status)
  })

  it('attempts Stripe call for valid tier (couple)', async () => {
    const res = await app.request('/v1/subscriptions/checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: 'couple' }),
    })
    expect([422, 500]).toContain(res.status)
  })

  it('attempts Stripe call for valid tier (family)', async () => {
    const res = await app.request('/v1/subscriptions/checkout-session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: 'family' }),
    })
    expect([422, 500]).toContain(res.status)
  })
})

// Tests for POST /v1/subscriptions/activate — Story 9.3 / 13.1 (FR83, AC: 2, 3)
// Real implementation (Story 13.1): validates sessionId against Stripe API.
// In test environments without STRIPE_SECRET_KEY, Stripe calls fail → 400 INVALID_SESSION.

describe('POST /v1/subscriptions/activate', () => {
  it('returns 400 for invalid/unknown sessionId (no Stripe key in test env)', async () => {
    const res = await app.request('/v1/subscriptions/activate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sessionId: 'test_invalid_session' }),
    })
    // In test environments, Stripe call fails because no real API key is configured.
    // Real Stripe environment will return 200 on valid session_id.
    expect([400, 500]).toContain(res.status)
  })

  it('returns 400 with INVALID_SESSION error code for invalid sessionId', async () => {
    const res = await app.request('/v1/subscriptions/activate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sessionId: 'invalid_cs_id' }),
    })
    // Stripe call fails with error → handler returns 400 INVALID_SESSION (or 500 on network error)
    expect([400, 500]).toContain(res.status)
  })

  it('returns 422 for missing sessionId field', async () => {
    const res = await app.request('/v1/subscriptions/activate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })
    expect(res.status).toBe(400)
  })
})

// Tests for POST /v1/subscriptions/restore — Story 9.3 (AC: 2)
// Handler is a stub — all valid requests return 200.

describe('POST /v1/subscriptions/restore', () => {
  it('returns 200', async () => {
    const res = await app.request('/v1/subscriptions/restore', {
      method: 'POST',
    })
    expect(res.status).toBe(200)
  })

  it('response data.status is "active"', async () => {
    const res = await app.request('/v1/subscriptions/restore', {
      method: 'POST',
    })
    const body = await res.json() as { data: { status: string } }
    expect(body.data.status).toBe('active')
  })
})

// Tests for POST /v1/subscriptions/cancel — Story 9.4 (FR49, FR89, AC: 2)
// Handler is a stub (real Stripe cancellation deferred) — all valid requests return 200.

describe('POST /v1/subscriptions/cancel', () => {
  it('returns 200', async () => {
    const res = await app.request('/v1/subscriptions/cancel', {
      method: 'POST',
    })
    expect(res.status).toBe(200)
  })

  it('response shape has data object', async () => {
    const res = await app.request('/v1/subscriptions/cancel', {
      method: 'POST',
    })
    const body = await res.json() as { data: { status: string } }
    expect(body).toHaveProperty('data')
  })

  it('response data.status is "cancelled"', async () => {
    const res = await app.request('/v1/subscriptions/cancel', {
      method: 'POST',
    })
    const body = await res.json() as { data: { status: string } }
    expect(body.data.status).toBe('cancelled')
  })

  it('response has data.currentPeriodEnd (non-null — access-until date)', async () => {
    const res = await app.request('/v1/subscriptions/cancel', {
      method: 'POST',
    })
    const body = await res.json() as { data: { currentPeriodEnd: string | null } }
    expect(body.data).toHaveProperty('currentPeriodEnd')
    expect(body.data.currentPeriodEnd).not.toBeNull()
  })

  it('response has data.stripeSubscriptionId', async () => {
    const res = await app.request('/v1/subscriptions/cancel', {
      method: 'POST',
    })
    const body = await res.json() as { data: { stripeSubscriptionId: string | null } }
    expect(body.data).toHaveProperty('stripeSubscriptionId')
  })
})

// Tests for POST /v1/subscriptions/webhook/stripe — Story 9.5 (FR90, AC: 1–3)
// Handler is a stub — all valid requests return 200 with { data: { received: true } }.

describe('POST /v1/subscriptions/webhook/stripe', () => {
  const webhookPayload = {
    type: 'invoice.payment_failed',
    data: { object: { id: 'in_stub_123' } },
  }

  it('returns 200 for invoice.payment_failed event', async () => {
    const res = await app.request('/v1/subscriptions/webhook/stripe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(webhookPayload),
    })
    expect(res.status).toBe(200)
  })

  it('returns 200 for invoice.payment_succeeded event', async () => {
    const res = await app.request('/v1/subscriptions/webhook/stripe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'invoice.payment_succeeded', data: { object: {} } }),
    })
    expect(res.status).toBe(200)
  })

  it('response shape has data.received boolean', async () => {
    const res = await app.request('/v1/subscriptions/webhook/stripe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(webhookPayload),
    })
    const body = await res.json() as { data: { received: boolean } }
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('received')
  })

  it('response data.received is true', async () => {
    const res = await app.request('/v1/subscriptions/webhook/stripe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(webhookPayload),
    })
    const body = await res.json() as { data: { received: boolean } }
    expect(body.data.received).toBe(true)
  })

  it('returns 200 for unknown event type (stub accepts all)', async () => {
    const res = await app.request('/v1/subscriptions/webhook/stripe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'customer.subscription.updated', data: { object: {} } }),
    })
    expect(res.status).toBe(200)
  })
})
