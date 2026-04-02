import { describe, expect, it, vi } from 'vitest'

// Story 10.1: REST API — Tasks & Lists (FR44, FR80, NFR-I6, ARCH-14)

vi.mock('../../src/services/scheduling.js', () => ({
  runScheduleForUser: vi.fn().mockResolvedValue({}),
}))

const app = (await import('../../src/index.js')).default

describe('Story 10.1 — DELETE /v1/lists/:id', () => {
  it('returns 204 for hard-delete of a list', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001', {
      method: 'DELETE',
    })
    expect(res.status).toBe(204)
  })

  it('hard-delete returns no body', async () => {
    const res = await app.request('/v1/lists/b0000000-0000-4000-8000-000000000001', {
      method: 'DELETE',
    })
    const body = await res.text()
    expect(body).toBe('')
  })
})

describe('Story 10.1 — GET /v1/openapi.json', () => {
  it('serves OpenAPI spec at /v1/openapi.json', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    expect(res.status).toBe(200)
  })

  it('/v1/openapi.json response is valid JSON with openapi field', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    const body = await res.json() as Record<string, unknown>
    expect(body).toHaveProperty('openapi')
    expect(body.openapi).toBe('3.0.0')
  })

  it('/v1/openapi.json info.title matches expected value', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    const body = await res.json() as { info: { title: string } }
    expect(body.info.title).toBe('OnTask API')
  })
})

describe('Story 10.1 — X-RateLimit-* headers (FR80, NFR-I6)', () => {
  it('GET /v1/tasks includes X-RateLimit-Limit header', async () => {
    const res = await app.request('/v1/tasks', { method: 'GET' })
    expect(res.headers.get('X-RateLimit-Limit')).toBeTruthy()
  })

  it('GET /v1/lists includes X-RateLimit-Remaining header', async () => {
    const res = await app.request('/v1/lists', { method: 'GET' })
    expect(res.headers.get('X-RateLimit-Remaining')).toBeTruthy()
  })

  it('POST /v1/tasks includes X-RateLimit-Reset header', async () => {
    const res = await app.request('/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Rate limit header test task' }),
    })
    expect(res.headers.get('X-RateLimit-Reset')).toBeTruthy()
  })

  it('rate limit header values are numeric strings', async () => {
    const res = await app.request('/v1/tasks', { method: 'GET' })
    const limit = res.headers.get('X-RateLimit-Limit')
    const remaining = res.headers.get('X-RateLimit-Remaining')
    const reset = res.headers.get('X-RateLimit-Reset')
    expect(Number(limit)).toBeGreaterThan(0)
    expect(Number(remaining)).toBeGreaterThanOrEqual(0)
    expect(Number(reset)).toBeGreaterThan(0)
  })
})
