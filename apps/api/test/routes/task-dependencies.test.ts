import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

describe('Task Dependencies routes', () => {
  it('POST /v1/task-dependencies — creates dependency and returns 201', async () => {
    const res = await app.request('/v1/task-dependencies', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dependentTaskId: 'a0000000-0000-4000-8000-000000000002',
        dependsOnTaskId: 'a0000000-0000-4000-8000-000000000001',
      }),
    })

    expect(res.status).toBe(201)
    const body = await res.json() as AnyJson
    expect(body.data.dependentTaskId).toBe('a0000000-0000-4000-8000-000000000002')
    expect(body.data.dependsOnTaskId).toBe('a0000000-0000-4000-8000-000000000001')
    expect(body.data.id).toBeDefined()
    expect(body.data.createdAt).toBeDefined()
  })

  it('POST /v1/task-dependencies — returns 422 when dependentTaskId === dependsOnTaskId', async () => {
    const res = await app.request('/v1/task-dependencies', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dependentTaskId: 'a0000000-0000-4000-8000-000000000001',
        dependsOnTaskId: 'a0000000-0000-4000-8000-000000000001',
      }),
    })

    expect(res.status).toBe(422)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('SELF_DEPENDENCY')
  })

  it('GET /v1/task-dependencies?taskId= — returns dependencies for task', async () => {
    const res = await app.request(
      '/v1/task-dependencies?taskId=a0000000-0000-4000-8000-000000000001',
      { method: 'GET' },
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.dependsOn).toBeInstanceOf(Array)
    expect(body.data.blocks).toBeInstanceOf(Array)
  })

  it('DELETE /v1/task-dependencies/:id — returns 204', async () => {
    const res = await app.request(
      '/v1/task-dependencies/b0000000-0000-4000-8000-000000000001',
      { method: 'DELETE' },
    )

    expect(res.status).toBe(204)
  })
})
