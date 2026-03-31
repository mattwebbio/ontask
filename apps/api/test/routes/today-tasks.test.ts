import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Today tasks routes', () => {
  // ── GET /v1/tasks/today ───────────────────────────────────────────────────

  it('GET /v1/tasks/today — returns tasks array with pagination envelope', async () => {
    const res = await app.request('/v1/tasks/today', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeInstanceOf(Array)
    expect(body.data.length).toBeGreaterThan(0)
    expect(body.pagination).toBeDefined()
    expect(body.pagination.cursor).toBeNull()
    expect(typeof body.pagination.hasMore).toBe('boolean')
  })

  it('GET /v1/tasks/today?date=2026-03-30 — accepts date filter and returns tasks for that date', async () => {
    const res = await app.request('/v1/tasks/today?date=2026-03-30', {
      method: 'GET',
    })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeInstanceOf(Array)
    expect(body.data.length).toBeGreaterThan(0)
    // Verify tasks have dueDate matching the requested date
    const task = body.data[0]
    expect(task.dueDate).toContain('2026-03-30')
  })

  it('GET /v1/tasks/today — returned tasks have expected schema fields', async () => {
    const res = await app.request('/v1/tasks/today', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const task = body.data[0]
    expect(task).toHaveProperty('id')
    expect(task).toHaveProperty('title')
    expect(task).toHaveProperty('dueDate')
    expect(task).toHaveProperty('completedAt')
    expect(task).toHaveProperty('createdAt')
  })

  // ── GET /v1/tasks/schedule-health ──────────────────────────────────────────

  it('GET /v1/tasks/schedule-health — returns 7-day health array', async () => {
    const res = await app.request(
      '/v1/tasks/schedule-health?weekStartDate=2026-03-30',
      { method: 'GET' },
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.days).toBeInstanceOf(Array)
    expect(body.data.days.length).toBe(7)
  })

  it('GET /v1/tasks/schedule-health — each day has correct schema', async () => {
    const res = await app.request(
      '/v1/tasks/schedule-health?weekStartDate=2026-03-30',
      { method: 'GET' },
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const day = body.data.days[0]
    expect(day).toHaveProperty('date')
    expect(day).toHaveProperty('status')
    expect(day).toHaveProperty('taskCount')
    expect(day).toHaveProperty('capacityPercent')
    expect(day).toHaveProperty('atRiskTaskIds')
    expect(day.status).toBe('healthy')
    expect(day.taskCount).toBe(0)
    expect(day.capacityPercent).toBe(0)
    expect(day.atRiskTaskIds).toEqual([])
  })

  it('GET /v1/tasks/schedule-health — days are sequential from weekStartDate', async () => {
    const res = await app.request(
      '/v1/tasks/schedule-health?weekStartDate=2026-03-30',
      { method: 'GET' },
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const dates = body.data.days.map((d: AnyJson) => d.date) as string[]
    expect(dates[0]).toBe('2026-03-30')
    expect(dates[1]).toBe('2026-03-31')
    expect(dates[2]).toBe('2026-04-01')
    expect(dates[6]).toBe('2026-04-05')
  })

  it('GET /v1/tasks/schedule-health — requires weekStartDate param', async () => {
    const res = await app.request('/v1/tasks/schedule-health', {
      method: 'GET',
    })

    // Should fail validation since weekStartDate is required
    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  // ── Route ordering: /v1/tasks/today and /v1/tasks/schedule-health are NOT swallowed by :id ──

  it('GET /v1/tasks/today — route is not swallowed by :id param', async () => {
    const res = await app.request('/v1/tasks/today', { method: 'GET' })
    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    // If swallowed by :id, it would try to parse "today" as UUID and fail
    expect(body.data).toBeInstanceOf(Array)
  })

  it('GET /v1/tasks/schedule-health — route is not swallowed by :id param', async () => {
    const res = await app.request(
      '/v1/tasks/schedule-health?weekStartDate=2026-03-30',
      { method: 'GET' },
    )
    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.days).toBeDefined()
  })
})
