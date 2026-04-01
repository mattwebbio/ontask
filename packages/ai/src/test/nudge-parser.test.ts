import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { parseSchedulingNudge } from '../nudge-parser.js'
import type { NudgeInput } from '../nudge-parser.js'

// ── Mock the Vercel AI SDK — never call the real LLM in unit tests ────────────
vi.mock('ai', () => ({
  generateObject: vi.fn(),
}))

// ── Mock the provider — returns a mock model factory ─────────────────────────
vi.mock('../provider.js', () => ({
  createAIProvider: vi.fn(() => {
    // Returns a function that returns a model stub
    return (_modelName: string) => ({ id: 'mock-model' })
  }),
}))

import { generateObject } from 'ai'

const mockGenerateObject = vi.mocked(generateObject)

// ── Helpers ───────────────────────────────────────────────────────────────────

const windowStart = new Date('2026-04-01T08:00:00.000Z')
const windowEnd = new Date('2026-04-15T22:00:00.000Z')

function makeInput(overrides: Partial<NudgeInput> = {}): NudgeInput {
  return {
    utterance: 'move to tomorrow morning',
    taskId: 'task-1',
    taskTitle: 'Gym session',
    windowStart,
    windowEnd,
    ...overrides,
  }
}

function mockLlmResponse(suggestedDate: string, confidence: 'high' | 'low', interpretation: string) {
  mockGenerateObject.mockResolvedValueOnce({
    object: { suggestedDate, confidence, interpretation },
  } as ReturnType<typeof generateObject> extends Promise<infer T> ? T : never)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('parseSchedulingNudge', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('returns high-confidence result when LLM resolves an unambiguous utterance', async () => {
    mockLlmResponse('2026-04-02T09:00:00.000Z', 'high', 'Tomorrow morning at 9 AM')

    const result = await parseSchedulingNudge(makeInput())

    expect(result.suggestedDate).toEqual(new Date('2026-04-02T09:00:00.000Z'))
    expect(result.confidence).toBe('high')
    expect(result.interpretation).toBe('Tomorrow morning at 9 AM')
  })

  it('returns low confidence when LLM returns low confidence for ambiguous utterance', async () => {
    mockLlmResponse('2026-04-02T09:00:00.000Z', 'low', 'Could not resolve clearly')

    const result = await parseSchedulingNudge(
      makeInput({ utterance: 'sometime next week maybe' }),
    )

    expect(result.confidence).toBe('low')
  })

  it('overrides confidence to low when resolved date falls before windowStart', async () => {
    // Resolved date is before the window
    mockLlmResponse('2026-03-31T09:00:00.000Z', 'high', 'Yesterday at 9 AM')

    const result = await parseSchedulingNudge(makeInput())

    expect(result.confidence).toBe('low')
    expect(result.suggestedDate).toEqual(new Date('2026-03-31T09:00:00.000Z'))
  })

  it('overrides confidence to low when resolved date falls after windowEnd', async () => {
    // Resolved date is beyond the 14-day window
    mockLlmResponse('2026-05-01T09:00:00.000Z', 'high', 'May 1st at 9 AM')

    const result = await parseSchedulingNudge(makeInput())

    expect(result.confidence).toBe('low')
  })

  it('accepts an optional currentScheduledTime in the input', async () => {
    mockLlmResponse('2026-04-02T14:00:00.000Z', 'high', 'Tomorrow afternoon at 2 PM')

    const result = await parseSchedulingNudge(
      makeInput({ currentScheduledTime: new Date('2026-04-01T10:00:00.000Z') }),
    )

    expect(result.confidence).toBe('high')
    expect(result.interpretation).toBe('Tomorrow afternoon at 2 PM')
  })

  it('passes env to createAIProvider', async () => {
    const { createAIProvider } = await import('../provider.js')
    const mockCreateProvider = vi.mocked(createAIProvider)

    mockLlmResponse('2026-04-02T09:00:00.000Z', 'high', 'Tomorrow morning')

    const fakeEnv = { AI: {} } as unknown as CloudflareBindings
    await parseSchedulingNudge(makeInput(), fakeEnv)

    expect(mockCreateProvider).toHaveBeenCalledWith(fakeEnv)
  })

  it('calls generateObject with a prompt containing the utterance', async () => {
    mockLlmResponse('2026-04-02T09:00:00.000Z', 'high', 'Tomorrow morning at 9 AM')

    await parseSchedulingNudge(makeInput({ utterance: 'move gym to Friday' }))

    expect(mockGenerateObject).toHaveBeenCalledOnce()
    const callArgs = mockGenerateObject.mock.calls[0]![0] as { prompt: string }
    expect(callArgs.prompt).toContain('move gym to Friday')
    expect(callArgs.prompt).toContain('Gym session')
  })

  it('throws a TIMEOUT error when the LLM exceeds 2500ms', async () => {
    // Never resolves — simulates LLM timeout
    mockGenerateObject.mockImplementationOnce(
      () => new Promise((_resolve) => { /* intentionally never resolves */ }),
    )

    // Override timer to fire immediately for test speed
    vi.useFakeTimers()

    const resultPromise = parseSchedulingNudge(makeInput())
    vi.advanceTimersByTime(3000)

    await expect(resultPromise).rejects.toThrow(
      'Scheduling assistant timed out — try a simpler phrase',
    )

    vi.useRealTimers()
  })

  it('keeps high confidence when resolved date is exactly at windowStart', async () => {
    mockLlmResponse(windowStart.toISOString(), 'high', 'Right now')

    const result = await parseSchedulingNudge(makeInput())

    expect(result.confidence).toBe('high')
  })

  it('keeps high confidence when resolved date is exactly at windowEnd', async () => {
    mockLlmResponse(windowEnd.toISOString(), 'high', 'End of window')

    const result = await parseSchedulingNudge(makeInput())

    expect(result.confidence).toBe('high')
  })

  it('returns the interpretation string from the LLM response', async () => {
    const interpretation = 'Friday at 2 PM'
    mockLlmResponse('2026-04-03T14:00:00.000Z', 'high', interpretation)

    const result = await parseSchedulingNudge(makeInput({ utterance: 'move to Friday afternoon' }))

    expect(result.interpretation).toBe(interpretation)
  })
})
