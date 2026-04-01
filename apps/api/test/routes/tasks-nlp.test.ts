import { describe, expect, it, vi, beforeEach } from 'vitest'
import app from '../../src/index.js'

// ── Mock @ontask/ai — never call real LLM in API route tests ─────────────────
vi.mock('@ontask/ai', () => ({
  parseTaskUtterance: vi.fn(),
  parseSchedulingNudge: vi.fn(), // keep existing mock to avoid import errors
}))

import { parseTaskUtterance } from '@ontask/ai'

const mockParseTaskUtterance = vi.mocked(parseTaskUtterance)

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// ── Helpers ───────────────────────────────────────────────────────────────────

function mockHighConfidenceResult() {
  mockParseTaskUtterance.mockResolvedValueOnce({
    title: 'Call the dentist',
    confidence: 'high',
    dueDate: '2026-04-03T00:00:00.000Z',
    scheduledTime: '2026-04-03T14:00:00.000Z',
    estimatedDurationMinutes: null,
    energyRequirement: null,
    listId: null,
    fieldConfidences: {
      title: 'high',
      dueDate: 'high',
      scheduledTime: 'high',
    },
  })
}

function mockLowConfidenceResult() {
  mockParseTaskUtterance.mockResolvedValueOnce({
    title: '',
    confidence: 'low',
    dueDate: null,
    scheduledTime: null,
    estimatedDurationMinutes: null,
    energyRequirement: null,
    listId: null,
    fieldConfidences: {},
  })
}

function mockTimeoutError() {
  const err = new Error('Task assistant timed out — try a simpler phrase') as NodeJS.ErrnoException
  err.code = 'TIMEOUT'
  mockParseTaskUtterance.mockRejectedValueOnce(err)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('POST /v1/tasks/parse', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('valid utterance returns 200 with parsed fields', async () => {
    mockHighConfidenceResult()

    const res = await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'call the dentist Thursday at 2pm' }),
    })

    expect(res.status).toBe(200)
    const json = await res.json() as AnyJson
    expect(json.data.title).toBe('Call the dentist')
    expect(json.data.confidence).toBe('high')
    expect(json.data.dueDate).toBe('2026-04-03T00:00:00.000Z')
    expect(json.data.scheduledTime).toBe('2026-04-03T14:00:00.000Z')
    expect(json.data.fieldConfidences.title).toBe('high')
  })

  it('low confidence returns 422 UNPROCESSABLE', async () => {
    mockLowConfidenceResult()

    const res = await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'asdf qwerty zzz' }),
    })

    expect(res.status).toBe(422)
    const json = await res.json() as AnyJson
    expect(json.error.code).toBe('UNPROCESSABLE')
    expect(json.error.message).toContain('Could not understand')
  })

  it('LLM timeout returns 422 UNPROCESSABLE with timeout message', async () => {
    mockTimeoutError()

    const res = await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'call the dentist' }),
    })

    expect(res.status).toBe(422)
    const json = await res.json() as AnyJson
    expect(json.error.code).toBe('UNPROCESSABLE')
    expect(json.error.message).toContain('timed out')
  })

  it('missing utterance returns 400', async () => {
    const res = await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBe(400)
  })

  it('empty utterance returns 400', async () => {
    const res = await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: '' }),
    })

    expect(res.status).toBe(400)
  })

  it('passes x-user-id header to parseTaskUtterance', async () => {
    mockHighConfidenceResult()

    await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'specific-user-id' },
      body: JSON.stringify({ utterance: 'buy milk' }),
    })

    expect(mockParseTaskUtterance).toHaveBeenCalledOnce()
    const callArgs = mockParseTaskUtterance.mock.calls[0]![0] as { userId: string }
    expect(callArgs.userId).toBe('specific-user-id')
  })

  it('calls parseTaskUtterance with the utterance from the body', async () => {
    mockHighConfidenceResult()

    await app.request('/v1/tasks/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ utterance: 'remind me to call dentist' }),
    })

    expect(mockParseTaskUtterance).toHaveBeenCalledOnce()
    const callArgs = mockParseTaskUtterance.mock.calls[0]![0] as { utterance: string }
    expect(callArgs.utterance).toBe('remind me to call dentist')
  })
})
