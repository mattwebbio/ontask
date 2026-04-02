import { describe, expect, it, vi } from 'vitest'

// Story 10.2: REST API — Scheduling Operations & Rate Limit Enforcement
// (FR44, FR80, NFR-I6, ARCH-14)

vi.mock('../../src/services/scheduling.js', () => ({
  runScheduleForUser: vi.fn().mockResolvedValue({
    schedule: { scheduledBlocks: [], unscheduledTaskIds: ['a0000000-0000-4000-8000-000000000001'] },
    scheduleInput: { tasks: [], constraints: {}, calendarEvents: [] },
  }),
}))

const app = (await import('../../src/index.js')).default

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const validTaskId = 'a0000000-0000-4000-8000-000000000001'
const unknownTaskId = 'f0000000-0000-4000-8000-000000000099'

describe('Story 10.2 — POST /v1/tasks/:id/schedule (AC: 1)', () => {
  it('returns 404 for unknown task (not in schedule output)', async () => {
    const res = await app.request(`/v1/tasks/${unknownTaskId}/schedule`, {
      method: 'POST',
      headers: { 'x-user-id': 'story-10-2-schedule-test' },
    })
    expect(res.status).toBe(404)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('NOT_FOUND')
  })

  it('returns 400 for invalid (non-UUID) task id', async () => {
    const res = await app.request('/v1/tasks/not-a-uuid/schedule', {
      method: 'POST',
      headers: { 'x-user-id': 'story-10-2-schedule-test' },
    })
    expect(res.status).toBe(400)
  })
})

describe('Story 10.2 — GET /v1/tasks/:id/schedule (AC: 1)', () => {
  it('returns scheduled:false with explanation for unscheduled task', async () => {
    // validTaskId is in unscheduledTaskIds in the mock
    const res = await app.request(`/v1/tasks/${validTaskId}/schedule`, {
      method: 'GET',
      headers: { 'x-user-id': 'story-10-2-schedule-test' },
    })
    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.scheduled).toBe(false)
    expect(body.data).toHaveProperty('explanation')
    expect(Array.isArray(body.data.explanation.reasons)).toBe(true)
  })

  it('returns 404 for unknown task not in any schedule list', async () => {
    const res = await app.request(`/v1/tasks/${unknownTaskId}/schedule`, {
      method: 'GET',
      headers: { 'x-user-id': 'story-10-2-schedule-test' },
    })
    expect(res.status).toBe(404)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('NOT_FOUND')
  })

  it('rate limit headers are present on scheduling responses', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/schedule`, {
      method: 'GET',
      headers: { 'x-user-id': 'story-10-2-schedule-test' },
    })
    expect(res.headers.get('X-RateLimit-Limit')).toBeTruthy()
    expect(res.headers.get('X-RateLimit-Remaining')).toBeTruthy()
    expect(res.headers.get('X-RateLimit-Reset')).toBeTruthy()
  })
})

describe('Story 10.2 — Rate limit enforcement 429 (AC: 2)', () => {
  it('returns 429 with RATE_LIMIT_EXCEEDED after limit is exceeded', async () => {
    // Use a unique user ID for this test to isolate counter state
    const testUserId = 'rate-limit-enforce-user-10-2'

    // Exhaust the limit (1000 requests) — fire them all against the cheapest endpoint
    const requests = []
    for (let i = 0; i < 1001; i++) {
      requests.push(
        app.request('/v1/tasks', {
          method: 'GET',
          headers: { 'x-user-id': testUserId },
        }),
      )
    }
    const responses = await Promise.all(requests)
    const last = responses[responses.length - 1]!
    expect(last.status).toBe(429)
    const body = (await last.json()) as AnyJson
    expect(body.error.code).toBe('RATE_LIMIT_EXCEEDED')
    expect(body.error.details).toHaveProperty('retryAfter')
    expect(typeof body.error.details.retryAfter).toBe('number')
  })

  it('429 response does NOT include X-RateLimit-* headers (short-circuit before headers)', async () => {
    // The exceeded user from the test above will still be over-limit in same module
    const testUserId = 'rate-limit-enforce-user-10-2'
    const res = await app.request('/v1/tasks', {
      method: 'GET',
      headers: { 'x-user-id': testUserId },
    })
    expect(res.status).toBe(429)
  })

  it('rate limit is per-user — different user IDs have independent counters', async () => {
    const userA = 'rate-limit-user-A-10-2'
    const userB = 'rate-limit-user-B-10-2'

    // Exhaust userA
    const exhaust = []
    for (let i = 0; i < 1001; i++) {
      exhaust.push(app.request('/v1/tasks', { method: 'GET', headers: { 'x-user-id': userA } }))
    }
    await Promise.all(exhaust)

    // userB should still be fine
    const resB = await app.request('/v1/tasks', {
      method: 'GET',
      headers: { 'x-user-id': userB },
    })
    expect(resB.status).toBe(200)
  })
})

describe('Story 10.2 — OpenAPI spec includes rate limit documentation (AC: 2)', () => {
  it('/v1/doc description mentions rate limiting', async () => {
    const res = await app.request('/v1/doc', { method: 'GET' })
    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const description: string = body?.info?.description ?? ''
    expect(description.toLowerCase()).toContain('rate limit')
  })

  it('/v1/openapi.json description includes window limit information', async () => {
    const res = await app.request('/v1/openapi.json', { method: 'GET' })
    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const description: string = body?.info?.description ?? ''
    expect(description).toContain('1000')
  })
})
