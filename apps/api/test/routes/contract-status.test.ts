import { describe, expect, it } from 'vitest'

// Tests for GET /v1/contracts/:id/status — Story 6.9 (FR71, AC: 2)

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const validUuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'

describe('GET /v1/contracts/:id/status', () => {
  it('returns 200 with status/stakeAmountCents/chargeTimestamp', async () => {
    const res = await app.request(`/v1/contracts/${validUuid}/status`, {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.id).toBe(validUuid)
    expect(['active', 'charged', 'cancelled', 'disputed']).toContain(body.data.status)
    expect(body.data.stakeAmountCents).toBeDefined()
    expect('chargeTimestamp' in body.data).toBe(true)
  })

  it('returns 400 on non-UUID id', async () => {
    const res = await app.request('/v1/contracts/not-a-uuid/status', {
      method: 'GET',
    })

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('chargeTimestamp is null when status is active', async () => {
    const res = await app.request(`/v1/contracts/${validUuid}/status`, {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    if (body.data.status === 'active') {
      expect(body.data.chargeTimestamp).toBeNull()
    }
  })
})
