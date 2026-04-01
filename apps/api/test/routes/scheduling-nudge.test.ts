import { describe, expect, it, vi, beforeEach } from 'vitest'
import app from '../../src/index.js'

// ── Mock @ontask/ai — never call real LLM in API route tests ─────────────────
vi.mock('@ontask/ai', () => ({
  parseSchedulingNudge: vi.fn(),
}))

import { parseSchedulingNudge } from '@ontask/ai'

const mockParseNudge = vi.mocked(parseSchedulingNudge)

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

const validTaskId = 'a0000000-0000-4000-8000-000000000001'
const unknownTaskId = 'f0000000-0000-4000-8000-000000000099'

// ── Helper ────────────────────────────────────────────────────────────────────

function mockHighConfidenceNudge(date = new Date('2026-04-02T09:00:00.000Z')) {
  mockParseNudge.mockResolvedValueOnce({
    suggestedDate: date,
    confidence: 'high',
    interpretation: 'Tomorrow morning at 9 AM',
  })
}

function mockLowConfidenceNudge() {
  mockParseNudge.mockResolvedValueOnce({
    suggestedDate: new Date('2026-04-02T09:00:00.000Z'),
    confidence: 'low',
    interpretation: 'Could not resolve clearly',
  })
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('POST /v1/tasks/:id/schedule/nudge', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 400 for invalid (non-UUID) task id', async () => {
    const res = await app.request('/v1/tasks/not-a-uuid/schedule/nudge', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'move to tomorrow morning' }),
    })
    expect(res.status).toBe(400)
  })

  it('returns 422 when confidence is low', async () => {
    mockLowConfidenceNudge()

    const res = await app.request(`/v1/tasks/${validTaskId}/schedule/nudge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'maybe sometime idk' }),
    })

    expect(res.status).toBe(422)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('UNPROCESSABLE')
  })

  it('returns 422 when the LLM throws a TIMEOUT error', async () => {
    const timeoutErr = new Error('Scheduling assistant timed out — try a simpler phrase')
    ;(timeoutErr as NodeJS.ErrnoException).code = 'TIMEOUT'
    mockParseNudge.mockRejectedValueOnce(timeoutErr)

    const res = await app.request(`/v1/tasks/${validTaskId}/schedule/nudge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'move to tomorrow morning' }),
    })

    expect(res.status).toBe(422)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('UNPROCESSABLE')
    expect(body.error.message).toContain('timed out')
  })

  it('returns 422 when the AI throws a non-timeout error', async () => {
    mockParseNudge.mockRejectedValueOnce(new Error('Some unexpected error'))

    const res = await app.request(`/v1/tasks/${validTaskId}/schedule/nudge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'move to tomorrow' }),
    })

    expect(res.status).toBe(422)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('UNPROCESSABLE')
    expect(body.error.message).toBe('Could not interpret scheduling request')
  })

  it('returns 404 when task is not in schedule output after nudge', async () => {
    mockHighConfidenceNudge()

    // unknownTaskId won't appear in stub schedule (tasks: [])
    const res = await app.request(`/v1/tasks/${unknownTaskId}/schedule/nudge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'move to tomorrow morning' }),
    })

    expect(res.status).toBe(404)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('NOT_FOUND')
  })

  it('uses stub-user-id when x-user-id header is absent', async () => {
    mockHighConfidenceNudge()

    const res = await app.request(`/v1/tasks/${unknownTaskId}/schedule/nudge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ utterance: 'move to tomorrow' }),
    })

    // Should still process (not 401) — auth is stubbed
    expect([404, 422]).toContain(res.status)
  })

  it('returns 400 when utterance is missing from request body', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/schedule/nudge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({}),
    })
    expect(res.status).toBe(400)
  })
})

describe('POST /v1/tasks/:id/schedule/nudge/confirm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 400 for invalid (non-UUID) task id', async () => {
    const res = await app.request('/v1/tasks/not-a-uuid/schedule/nudge/confirm', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ proposedStartTime: '2026-04-02T09:00:00.000Z' }),
    })
    expect(res.status).toBe(400)
  })

  it('returns 404 when confirmed task is not in schedule output', async () => {
    const res = await app.request(`/v1/tasks/${unknownTaskId}/schedule/nudge/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ proposedStartTime: '2026-04-02T09:00:00.000Z' }),
    })

    expect(res.status).toBe(404)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('NOT_FOUND')
  })

  it('uses stub-user-id when x-user-id header is absent', async () => {
    const res = await app.request(`/v1/tasks/${unknownTaskId}/schedule/nudge/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ proposedStartTime: '2026-04-02T09:00:00.000Z' }),
    })

    // Should still process (not 401) — auth is stubbed
    expect(res.status).toBe(404) // task not in stub schedule
  })

  it('returns 400 when proposedStartTime is missing', async () => {
    const res = await app.request(`/v1/tasks/${validTaskId}/schedule/nudge/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({}),
    })
    expect(res.status).toBe(400)
  })
})
