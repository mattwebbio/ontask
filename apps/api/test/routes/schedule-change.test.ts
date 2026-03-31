import { describe, expect, it } from 'vitest'
import app from '../../src/index.js'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const changeTypes = ['moved', 'removed'] as const
const severities = ['none', 'at_risk', 'critical'] as const

describe('Schedule Change routes', () => {
  // ── GET /v1/tasks/schedule-changes ────────────────────────────────────────

  it('GET /v1/tasks/schedule-changes — returns 200 with changes envelope', async () => {
    const res = await app.request('/v1/tasks/schedule-changes', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('hasMeaningfulChanges')
    expect(body.data).toHaveProperty('changeCount')
    expect(body.data).toHaveProperty('changes')
  })

  it('GET /v1/tasks/schedule-changes — hasMeaningfulChanges is boolean', async () => {
    const res = await app.request('/v1/tasks/schedule-changes', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(typeof body.data.hasMeaningfulChanges).toBe('boolean')
  })

  it('GET /v1/tasks/schedule-changes — changes array items have taskId, taskTitle, changeType', async () => {
    const res = await app.request('/v1/tasks/schedule-changes', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(Array.isArray(body.data.changes)).toBe(true)
    for (const item of body.data.changes) {
      expect(item).toHaveProperty('taskId')
      expect(item).toHaveProperty('taskTitle')
      expect(item).toHaveProperty('changeType')
    }
  })

  it('GET /v1/tasks/schedule-changes — changeType is one of moved/removed', async () => {
    const res = await app.request('/v1/tasks/schedule-changes', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    for (const item of body.data.changes) {
      expect(changeTypes).toContain(item.changeType)
    }
  })

  // ── GET /v1/tasks/overbooking-status ──────────────────────────────────────

  it('GET /v1/tasks/overbooking-status — returns 200 with overbooking envelope', async () => {
    const res = await app.request('/v1/tasks/overbooking-status', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('isOverbooked')
    expect(body.data).toHaveProperty('severity')
    expect(body.data).toHaveProperty('capacityPercent')
    expect(body.data).toHaveProperty('overbookedTasks')
  })

  it('GET /v1/tasks/overbooking-status — severity is one of none/at_risk/critical', async () => {
    const res = await app.request('/v1/tasks/overbooking-status', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(severities).toContain(body.data.severity)
  })

  it('GET /v1/tasks/overbooking-status — overbookedTasks array items have taskId, hasStake', async () => {
    const res = await app.request('/v1/tasks/overbooking-status', { method: 'GET' })

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(Array.isArray(body.data.overbookedTasks)).toBe(true)
    for (const item of body.data.overbookedTasks) {
      expect(item).toHaveProperty('taskId')
      expect(item).toHaveProperty('hasStake')
    }
  })
})
