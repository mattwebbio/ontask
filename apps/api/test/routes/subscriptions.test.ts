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
