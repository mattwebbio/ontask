import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Task search route', () => {
  it('GET /v1/tasks/search — returns 200 with list envelope', async () => {
    const res = await app.request('/v1/tasks/search', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toBeDefined()
    expect(Array.isArray(body.data)).toBe(true)
    expect(body.pagination).toBeDefined()
    expect(body.pagination).toHaveProperty('cursor')
    expect(body.pagination).toHaveProperty('hasMore')
  })

  it('GET /v1/tasks/search?q=groceries — filters by title substring', async () => {
    const res = await app.request('/v1/tasks/search?q=groceries', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.length).toBeGreaterThan(0)
    expect(body.data[0].title.toLowerCase()).toContain('groceries')
  })

  it('GET /v1/tasks/search?status=completed — filters by status', async () => {
    const res = await app.request('/v1/tasks/search?status=completed', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    for (const task of body.data) {
      expect(task.completedAt).not.toBeNull()
    }
  })

  it('GET /v1/tasks/search?listId=<uuid> — filters by list', async () => {
    const listId = 'a0000000-0000-4000-8000-000000000100'
    const res = await app.request(`/v1/tasks/search?listId=${listId}`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.length).toBeGreaterThan(0)
    for (const task of body.data) {
      expect(task.listId).toBe(listId)
    }
  })

  it('GET /v1/tasks/search?dueDateFrom=2026-04-01&dueDateTo=2026-04-07 — date range filter', async () => {
    const res = await app.request(
      '/v1/tasks/search?dueDateFrom=2026-04-01&dueDateTo=2026-04-07',
      { method: 'GET' },
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    for (const task of body.data) {
      const dueDate = new Date(task.dueDate)
      expect(dueDate.getTime()).toBeGreaterThanOrEqual(new Date('2026-04-01').getTime())
      expect(dueDate.getTime()).toBeLessThanOrEqual(new Date('2026-04-07T23:59:59.999Z').getTime())
    }
  })

  it('GET /v1/tasks/search — response includes listName field', async () => {
    const res = await app.request('/v1/tasks/search', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data.length).toBeGreaterThan(0)
    for (const task of body.data) {
      expect(task).toHaveProperty('listName')
    }
  })

  it('GET /v1/tasks/search?q=report&status=upcoming — AND logic with combined filters', async () => {
    const res = await app.request('/v1/tasks/search?q=report&status=upcoming', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    // "Finish quarterly report" is overdue (due 2026-03-28), so status=upcoming should exclude it
    // depending on current date — but the filter combines AND logic
    for (const task of body.data) {
      expect(task.title.toLowerCase()).toContain('report')
      expect(task.completedAt).toBeNull()
    }
  })
})
