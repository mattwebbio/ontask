import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

describe('Templates routes', () => {
  it('POST /v1/templates — creates template and returns 201 with title and sourceType', async () => {
    const res = await app.request('/v1/templates', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Sprint planning template',
        sourceType: 'list',
        sourceId: 'b0000000-0000-4000-8000-000000000001',
      }),
    })

    expect(res.status).toBe(201)
    const body = (await res.json()) as Record<string, any>
    expect(body.data.title).toBe('Sprint planning template')
    expect(body.data.sourceType).toBe('list')
    expect(body.data.id).toBeDefined()
    expect(body.data.templateData).toBeDefined()
    expect(body.data.createdAt).toBeDefined()
  })

  it('GET /v1/templates — returns template summaries with pagination', async () => {
    const res = await app.request('/v1/templates', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as Record<string, any>
    expect(body.data).toBeInstanceOf(Array)
    expect(body.data.length).toBeGreaterThan(0)
    expect(body.data[0].title).toBeDefined()
    expect(body.data[0].sourceType).toBeDefined()
    expect(body.data[0].createdAt).toBeDefined()
    // Summary should not include templateData
    expect(body.data[0].templateData).toBeUndefined()
    expect(body.pagination).toBeDefined()
    expect(body.pagination.cursor).toBeNull()
    expect(typeof body.pagination.hasMore).toBe('boolean')
  })

  it('GET /v1/templates/:id — returns full template with templateData', async () => {
    const res = await app.request(
      '/v1/templates/c0000000-0000-4000-8000-000000000001',
      { method: 'GET' },
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as Record<string, any>
    expect(body.data.id).toBe('c0000000-0000-4000-8000-000000000001')
    expect(body.data.templateData).toBeDefined()
    expect(typeof body.data.templateData).toBe('string')

    // Verify templateData is valid JSON
    const templateData = JSON.parse(body.data.templateData)
    expect(templateData.sections).toBeDefined()
    expect(templateData.rootTasks).toBeDefined()
  })

  it('POST /v1/templates/:id/apply — returns created structure with completedAt null and offset due dates', async () => {
    const res = await app.request(
      '/v1/templates/c0000000-0000-4000-8000-000000000001/apply',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ dueDateOffsetDays: 7 }),
      },
    )

    expect(res.status).toBe(201)
    const body = (await res.json()) as Record<string, any>
    expect(body.data.sections).toBeInstanceOf(Array)
    expect(body.data.tasks).toBeInstanceOf(Array)
    expect(body.data.list).toBeDefined()

    // All tasks should have completedAt = null
    for (const task of body.data.tasks) {
      expect(task.completedAt).toBeNull()
    }

    // Tasks with due dates should have offset dates
    const tasksWithDates = body.data.tasks.filter(
      (t: any) => t.dueDate !== null,
    )
    expect(tasksWithDates.length).toBeGreaterThan(0)
  })

  it('DELETE /v1/templates/:id — returns 204', async () => {
    const res = await app.request(
      '/v1/templates/c0000000-0000-4000-8000-000000000001',
      { method: 'DELETE' },
    )

    expect(res.status).toBe(204)
  })
})
