import { describe, expect, it } from 'vitest'

// Tests for GET /v1/billing-history — Story 6.9 (FR65, AC: 1)

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('GET /v1/billing-history', () => {
  it('returns 200 with entries array', async () => {
    const res = await app.request('/v1/billing-history', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(Array.isArray(body.data.entries)).toBe(true)
  })

  it('entries array contains at least one cancelled entry with amountCents=null', async () => {
    const res = await app.request('/v1/billing-history', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const entries: AnyJson[] = body.data.entries
    const cancelledEntry = entries.find(
      (e: AnyJson) => e.disbursementStatus === 'cancelled',
    )
    expect(cancelledEntry).toBeDefined()
    expect(cancelledEntry?.amountCents).toBeNull()
  })

  it('disbursementStatus values are one of: pending/completed/failed/cancelled', async () => {
    const res = await app.request('/v1/billing-history', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const validStatuses = ['pending', 'completed', 'failed', 'cancelled']
    const entries: AnyJson[] = body.data.entries
    for (const entry of entries) {
      expect(validStatuses).toContain(entry.disbursementStatus)
    }
  })
})
