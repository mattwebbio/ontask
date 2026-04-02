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
