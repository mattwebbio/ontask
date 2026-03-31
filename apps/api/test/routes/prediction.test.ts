import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const validTaskId = 'a0000000-0000-4000-8000-000000000001'
const validListId = 'b0000000-0000-4000-8000-000000000001'
const validSectionId = 'c0000000-0000-4000-8000-000000000001'

const predictionStatuses = ['on_track', 'at_risk', 'behind', 'unknown'] as const

describe('Prediction routes', () => {
  // ── Task prediction ────────────────────────────────────────────────────────

  it('GET /v1/tasks/{id}/prediction — returns 200 with prediction envelope', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/prediction`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('taskId')
    expect(body.data).toHaveProperty('predictedDate')
    expect(body.data).toHaveProperty('status')
    expect(body.data).toHaveProperty('tasksRemaining')
    expect(body.data).toHaveProperty('estimatedMinutesRemaining')
    expect(body.data).toHaveProperty('availableWindowsCount')
    expect(body.data).toHaveProperty('reasoning')
  })

  it('GET /v1/tasks/{id}/prediction — status is one of on_track/at_risk/behind/unknown', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/prediction`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(predictionStatuses).toContain(body.data.status)
  })

  it('GET /v1/tasks/{id}/prediction — predictedDate is valid datetime or null', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/prediction`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    const { predictedDate } = body.data
    if (predictedDate !== null) {
      expect(new Date(predictedDate).toString()).not.toBe('Invalid Date')
    }
  })

  it('GET /v1/tasks/{id}/prediction — reasoning string is non-empty', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/prediction`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(typeof body.data.reasoning).toBe('string')
    expect(body.data.reasoning.length).toBeGreaterThan(0)
  })

  // ── List prediction ────────────────────────────────────────────────────────

  it('GET /v1/lists/{id}/prediction — returns 200 with list prediction', async () => {
    const res = await app.request(`/v1/lists/${validListId}/prediction`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('listId')
    expect(body.data).toHaveProperty('predictedDate')
    expect(body.data).toHaveProperty('status')
    expect(predictionStatuses).toContain(body.data.status)
    expect(body.data).toHaveProperty('reasoning')
    expect(body.data.reasoning.length).toBeGreaterThan(0)
  })

  // ── Section prediction ────────────────────────────────────────────────────

  it('GET /v1/sections/{id}/prediction — returns 200 with section prediction', async () => {
    const res = await app.request(`/v1/sections/${validSectionId}/prediction`, { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('sectionId')
    expect(body.data).toHaveProperty('predictedDate')
    expect(body.data).toHaveProperty('status')
    expect(predictionStatuses).toContain(body.data.status)
    expect(body.data).toHaveProperty('reasoning')
    expect(body.data.reasoning.length).toBeGreaterThan(0)
  })
})
