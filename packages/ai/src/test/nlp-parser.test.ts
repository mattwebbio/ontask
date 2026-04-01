import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { parseTaskUtterance } from '../nlp-parser.js'
import type { TaskParseInput } from '../nlp-parser.js'
import type { AIProviderEnv } from '../provider.js'

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

const now = new Date('2026-04-01T08:00:00.000Z')

function makeInput(overrides: Partial<TaskParseInput> = {}): TaskParseInput {
  return {
    utterance: 'call the dentist Thursday at 2pm',
    userId: 'user-1',
    availableLists: [],
    now,
    ...overrides,
  }
}

function mockLlmResponse(partial: {
  title?: string
  confidence?: 'high' | 'low'
  dueDate?: string | null
  scheduledTime?: string | null
  estimatedDurationMinutes?: number | null
  energyRequirement?: 'high_focus' | 'low_energy' | 'flexible' | null
  listId?: string | null
  fieldConfidences?: Record<string, 'high' | 'low'>
}) {
  mockGenerateObject.mockResolvedValueOnce({
    object: {
      title: partial.title ?? 'Call the dentist',
      confidence: partial.confidence ?? 'high',
      dueDate: partial.dueDate ?? null,
      scheduledTime: partial.scheduledTime ?? null,
      estimatedDurationMinutes: partial.estimatedDurationMinutes ?? null,
      energyRequirement: partial.energyRequirement ?? null,
      listId: partial.listId ?? null,
      fieldConfidences: partial.fieldConfidences ?? {},
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } as any)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('parseTaskUtterance', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('high-confidence parse — resolves title, dueDate, scheduledTime', async () => {
    mockLlmResponse({
      title: 'Call the dentist',
      confidence: 'high',
      dueDate: '2026-04-03T00:00:00.000Z',
      scheduledTime: '2026-04-03T14:00:00.000Z',
      fieldConfidences: {
        title: 'high',
        dueDate: 'high',
        scheduledTime: 'high',
      },
    })

    const result = await parseTaskUtterance(makeInput())

    expect(result.title).toBe('Call the dentist')
    expect(result.confidence).toBe('high')
    expect(result.dueDate).toBe('2026-04-03T00:00:00.000Z')
    expect(result.scheduledTime).toBe('2026-04-03T14:00:00.000Z')
    expect(result.fieldConfidences.title).toBe('high')
    expect(result.fieldConfidences.dueDate).toBe('high')
  })

  it('partial parse — "buy milk" resolves title only; dueDate/duration undefined', async () => {
    mockLlmResponse({
      title: 'Buy milk',
      confidence: 'high',
      dueDate: null,
      scheduledTime: null,
      estimatedDurationMinutes: null,
      fieldConfidences: { title: 'high' },
    })

    const result = await parseTaskUtterance(makeInput({ utterance: 'buy milk' }))

    expect(result.title).toBe('Buy milk')
    expect(result.confidence).toBe('high')
    expect(result.dueDate).toBeNull()
    expect(result.scheduledTime).toBeNull()
    expect(result.estimatedDurationMinutes).toBeNull()
  })

  it('low-confidence response from LLM — returns confidence: low', async () => {
    mockLlmResponse({
      title: '',
      confidence: 'low',
      fieldConfidences: {},
    })

    const result = await parseTaskUtterance(makeInput({ utterance: 'asdf qwerty zzz' }))

    expect(result.confidence).toBe('low')
  })

  it('LLM exceeds 2500ms timeout — throws error with code TIMEOUT', async () => {
    // Never resolves — simulates LLM timeout
    mockGenerateObject.mockImplementationOnce(
      () => new Promise((_resolve) => { /* intentionally never resolves */ }),
    )

    vi.useFakeTimers()

    const resultPromise = parseTaskUtterance(makeInput())
    vi.advanceTimersByTime(3000)

    await expect(resultPromise).rejects.toThrow(
      'Task assistant timed out — try a simpler phrase',
    )

    vi.useRealTimers()
  })

  it('TIMEOUT error has code TIMEOUT', async () => {
    mockGenerateObject.mockImplementationOnce(
      () => new Promise((_resolve) => { /* intentionally never resolves */ }),
    )

    vi.useFakeTimers()

    const resultPromise = parseTaskUtterance(makeInput())
    vi.advanceTimersByTime(3000)

    await expect(resultPromise).rejects.toMatchObject({ code: 'TIMEOUT' })

    vi.useRealTimers()
  })

  it('available lists passed through — LLM prompt contains list titles', async () => {
    mockLlmResponse({ title: 'Work task', confidence: 'high' })

    const lists = [
      { id: 'list-1', title: 'Work' },
      { id: 'list-2', title: 'Personal' },
    ]

    await parseTaskUtterance(makeInput({ availableLists: lists }))

    expect(mockGenerateObject).toHaveBeenCalledOnce()
    const callArgs = mockGenerateObject.mock.calls[0]![0] as { prompt: string }
    expect(callArgs.prompt).toContain('Work')
    expect(callArgs.prompt).toContain('Personal')
  })

  it('available lists matched — returns listId from LLM response', async () => {
    mockLlmResponse({
      title: 'Work task',
      confidence: 'high',
      listId: 'list-1',
      fieldConfidences: { title: 'high', listId: 'high' },
    })

    const lists = [{ id: 'list-1', title: 'Work' }]
    const result = await parseTaskUtterance(makeInput({ availableLists: lists }))

    expect(result.listId).toBe('list-1')
    expect(result.fieldConfidences.listId).toBe('high')
  })

  it('empty lists array — parser handles gracefully, no listId returned', async () => {
    mockLlmResponse({
      title: 'Some task',
      confidence: 'high',
      listId: null,
    })

    const result = await parseTaskUtterance(makeInput({ availableLists: [] }))

    expect(result.listId).toBeNull()
  })

  it('calls generateObject with prompt containing the utterance and now time', async () => {
    mockLlmResponse({ title: 'Buy groceries', confidence: 'high' })

    await parseTaskUtterance(makeInput({ utterance: 'buy groceries tomorrow' }))

    expect(mockGenerateObject).toHaveBeenCalledOnce()
    const callArgs = mockGenerateObject.mock.calls[0]![0] as { prompt: string }
    expect(callArgs.prompt).toContain('buy groceries tomorrow')
    expect(callArgs.prompt).toContain(now.toISOString())
  })

  it('passes env to createAIProvider', async () => {
    const { createAIProvider } = await import('../provider.js')
    const mockCreateProvider = vi.mocked(createAIProvider)

    mockLlmResponse({ title: 'Test task', confidence: 'high' })

    const fakeEnv: AIProviderEnv = {}
    await parseTaskUtterance(makeInput(), fakeEnv)

    expect(mockCreateProvider).toHaveBeenCalledWith(fakeEnv)
  })

  it('returns energyRequirement when LLM provides it', async () => {
    mockLlmResponse({
      title: 'Deep work session',
      confidence: 'high',
      energyRequirement: 'high_focus',
      fieldConfidences: { title: 'high', energyRequirement: 'high' },
    })

    const result = await parseTaskUtterance(makeInput({ utterance: 'deep work session tomorrow' }))

    expect(result.energyRequirement).toBe('high_focus')
  })

  it('returns estimatedDurationMinutes when LLM provides it', async () => {
    mockLlmResponse({
      title: 'Quick call',
      confidence: 'high',
      estimatedDurationMinutes: 30,
      fieldConfidences: { title: 'high', estimatedDurationMinutes: 'high' },
    })

    const result = await parseTaskUtterance(makeInput({ utterance: 'quick 30-minute call' }))

    expect(result.estimatedDurationMinutes).toBe(30)
  })
})
