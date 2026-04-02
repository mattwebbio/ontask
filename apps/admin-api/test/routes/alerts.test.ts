import { describe, expect, it } from 'vitest'

// Tests for operator alerts and monitoring endpoints — Story 11.5
// AC: 1, 2 — FR54, NFR-B1
// Auth bypass: ADMIN_JWT_SECRET is undefined in Vitest → adminAuthMiddleware skips auth.
// No Authorization header needed.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const app = (await import('../../src/index.js')).default

describe('GET /admin/v1/alerts', () => {
  it('returns 200 with alerts array and unacknowledgedCount', async () => {
    const res = await app.request('/admin/v1/alerts')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(Array.isArray(body.data.alerts)).toBe(true)
    expect(typeof body.data.unacknowledgedCount).toBe('number')
  })

  it('returns array with at least one alert in stub mode', async () => {
    const res = await app.request('/admin/v1/alerts')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.alerts.length).toBeGreaterThan(0)
  })

  it('unacknowledgedCount equals number of returned alerts in stub mode', async () => {
    const res = await app.request('/admin/v1/alerts')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.unacknowledgedCount).toBe(body.data.alerts.length)
  })

  it('each alert has required fields: id, type, severity, title, referenceId, referenceType, createdAt, acknowledged', async () => {
    const res = await app.request('/admin/v1/alerts')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    const alert = body.data.alerts[0]
    expect(typeof alert.id).toBe('string')
    expect(typeof alert.type).toBe('string')
    expect(typeof alert.severity).toBe('string')
    expect(typeof alert.title).toBe('string')
    expect(typeof alert.referenceId).toBe('string')
    expect(typeof alert.referenceType).toBe('string')
    expect(typeof alert.createdAt).toBe('string')
    expect(typeof alert.acknowledged).toBe('boolean')
  })

  it('severity values are one of: info, warning, critical', async () => {
    const res = await app.request('/admin/v1/alerts')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    for (const alert of body.data.alerts) {
      expect(['info', 'warning', 'critical']).toContain(alert.severity)
    }
  })
})

describe('POST /admin/v1/alerts/:alertId/acknowledge', () => {
  it('returns 200 with alertId and acknowledgedAt', async () => {
    const alertId = '00000000-0000-4000-a000-000000000099'
    const res = await app.request(`/admin/v1/alerts/${alertId}/acknowledge`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(body.data.alertId).toBe(alertId)
    expect(typeof body.data.acknowledgedAt).toBe('string')
  })

  it('acknowledgedAt is a valid ISO timestamp', async () => {
    const alertId = '00000000-0000-4000-a000-000000000088'
    const before = new Date().toISOString()
    const res = await app.request(`/admin/v1/alerts/${alertId}/acknowledge`, {
      method: 'POST',
    })

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    // Verify it parses as a valid date
    const parsed = new Date(body.data.acknowledgedAt)
    expect(isNaN(parsed.getTime())).toBe(false)
    expect(body.data.acknowledgedAt >= before).toBe(true)
  })
})

describe('GET /admin/v1/monitoring/metrics', () => {
  it('returns 200 with all metric categories present', async () => {
    const res = await app.request('/admin/v1/monitoring/metrics?from=2026-01-01&to=2026-04-01')

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeDefined()
    expect(Array.isArray(body.data.trialStarts)).toBe(true)
    expect(Array.isArray(body.data.trialToSubscriptionConversions)).toBe(true)
    expect(Array.isArray(body.data.subscriptionActivations)).toBe(true)
    expect(Array.isArray(body.data.subscriptionCancellations)).toBe(true)
    expect(Array.isArray(body.data.totalChargesFired)).toBe(true)
    expect(Array.isArray(body.data.totalDisbursedToCharity)).toBe(true)
    expect(body.data.dateRange).toBeDefined()
    expect(body.data.dateRange.from).toBe('2026-01-01')
    expect(body.data.dateRange.to).toBe('2026-04-01')
  })

  it('returns 400 when from query param is missing', async () => {
    const res = await app.request('/admin/v1/monitoring/metrics?to=2026-04-01')

    expect(res.status).toBe(400)
  })

  it('returns 400 when to query param is missing', async () => {
    const res = await app.request('/admin/v1/monitoring/metrics?from=2026-01-01')

    expect(res.status).toBe(400)
  })
})
