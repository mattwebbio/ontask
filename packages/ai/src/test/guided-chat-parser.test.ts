import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { conductGuidedChatTurn } from '../guided-chat-parser.js'
import type { GuidedChatInput } from '../guided-chat-parser.js'
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

function makeInput(overrides: Partial<GuidedChatInput> = {}): GuidedChatInput {
  return {
    messages: [],
    userId: 'user-1',
    availableLists: [],
    now,
    ...overrides,
  }
}

function mockLlmResponse(partial: {
  reply?: string
  isComplete?: boolean
  extractedTask?: {
    title?: string | null
    dueDate?: string | null
    scheduledTime?: string | null
    estimatedDurationMinutes?: number | null
    energyRequirement?: 'high_focus' | 'low_energy' | 'flexible' | null
    listId?: string | null
  } | null
}) {
  mockGenerateObject.mockResolvedValueOnce({
    object: {
      reply: partial.reply ?? 'What would you like to name this task?',
      isComplete: partial.isComplete ?? false,
      extractedTask: partial.extractedTask ?? null,
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } as any)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('conductGuidedChatTurn', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
  })

  it('first turn (empty messages) — LLM returns opening question, isComplete: false', async () => {
    mockLlmResponse({
      reply: "Hi! What task would you like to create? Let's start with the name.",
      isComplete: false,
    })

    const result = await conductGuidedChatTurn(makeInput({ messages: [] }))

    expect(result.reply).toBe("Hi! What task would you like to create? Let's start with the name.")
    expect(result.isComplete).toBe(false)
    expect(result.extractedTask).toBeUndefined()
  })

  it('mid-conversation — LLM returns follow-up question, isComplete: false, no extractedTask', async () => {
    mockLlmResponse({
      reply: 'When does this task need to be done by?',
      isComplete: false,
    })

    const result = await conductGuidedChatTurn(
      makeInput({
        messages: [
          { role: 'user', content: 'I need to call the dentist' },
          { role: 'assistant', content: 'Great! When does this task need to be done?' },
          { role: 'user', content: 'Sometime this week' },
        ],
      }),
    )

    expect(result.reply).toBe('When does this task need to be done by?')
    expect(result.isComplete).toBe(false)
    expect(result.extractedTask).toBeUndefined()
  })

  it('final turn — LLM returns confirmation message, isComplete: true, extractedTask populated', async () => {
    mockLlmResponse({
      reply: 'Got it! I have everything I need to create your task.',
      isComplete: true,
      extractedTask: {
        title: 'Call the dentist',
        dueDate: '2026-04-03T00:00:00.000Z',
        scheduledTime: null,
        estimatedDurationMinutes: 30,
        energyRequirement: 'low_energy',
        listId: null,
      },
    })

    const result = await conductGuidedChatTurn(
      makeInput({
        messages: [
          { role: 'user', content: 'Call the dentist Thursday for 30 minutes' },
          { role: 'assistant', content: 'What energy level is this task?' },
          { role: 'user', content: 'Low energy' },
        ],
      }),
    )

    expect(result.isComplete).toBe(true)
    expect(result.reply).toContain('everything I need')
    expect(result.extractedTask).toBeDefined()
    expect(result.extractedTask?.title).toBe('Call the dentist')
    expect(result.extractedTask?.dueDate).toBe('2026-04-03T00:00:00.000Z')
    expect(result.extractedTask?.estimatedDurationMinutes).toBe(30)
    expect(result.extractedTask?.energyRequirement).toBe('low_energy')
  })

  it('LLM exceeds 2500ms timeout → throws error with code TIMEOUT', async () => {
    // Never resolves — simulates LLM timeout
    mockGenerateObject.mockImplementationOnce(
      () => new Promise((_resolve) => { /* intentionally never resolves */ }),
    )

    vi.useFakeTimers()

    const resultPromise = conductGuidedChatTurn(makeInput())
    vi.advanceTimersByTime(3000)

    await expect(resultPromise).rejects.toThrow('Chat assistant timed out — please try again')

    vi.useRealTimers()
  })

  it('TIMEOUT error has code TIMEOUT', async () => {
    mockGenerateObject.mockImplementationOnce(
      () => new Promise((_resolve) => { /* intentionally never resolves */ }),
    )

    vi.useFakeTimers()

    const resultPromise = conductGuidedChatTurn(makeInput())
    vi.advanceTimersByTime(3000)

    await expect(resultPromise).rejects.toMatchObject({ code: 'TIMEOUT' })

    vi.useRealTimers()
  })

  it('available lists passed through — prompt contains list titles', async () => {
    mockLlmResponse({ reply: 'What should we call this task?', isComplete: false })

    const lists = [
      { id: 'list-1', title: 'Work' },
      { id: 'list-2', title: 'Personal' },
    ]

    await conductGuidedChatTurn(makeInput({ availableLists: lists }))

    expect(mockGenerateObject).toHaveBeenCalledOnce()
    const callArgs = mockGenerateObject.mock.calls[0]![0] as { prompt: string }
    expect(callArgs.prompt).toContain('Work')
    expect(callArgs.prompt).toContain('Personal')
  })

  it('available lists matched — returns listId from LLM response in extractedTask', async () => {
    mockLlmResponse({
      reply: 'Task created!',
      isComplete: true,
      extractedTask: {
        title: 'Work task',
        listId: 'list-1',
        dueDate: null,
        scheduledTime: null,
        estimatedDurationMinutes: null,
        energyRequirement: null,
      },
    })

    const lists = [{ id: 'list-1', title: 'Work' }]
    const result = await conductGuidedChatTurn(makeInput({ availableLists: lists }))

    expect(result.isComplete).toBe(true)
    expect(result.extractedTask?.listId).toBe('list-1')
  })

  it('calls generateObject with prompt containing the conversation history', async () => {
    mockLlmResponse({ reply: 'When is this due?', isComplete: false })

    const messages = [
      { role: 'user' as const, content: 'I need to buy groceries' },
    ]

    await conductGuidedChatTurn(makeInput({ messages }))

    expect(mockGenerateObject).toHaveBeenCalledOnce()
    const callArgs = mockGenerateObject.mock.calls[0]![0] as { prompt: string }
    expect(callArgs.prompt).toContain('buy groceries')
    expect(callArgs.prompt).toContain(now.toISOString())
  })

  it('passes env to createAIProvider', async () => {
    const { createAIProvider } = await import('../provider.js')
    const mockCreateProvider = vi.mocked(createAIProvider)

    mockLlmResponse({ reply: 'What task?', isComplete: false })

    const fakeEnv: AIProviderEnv = {}
    await conductGuidedChatTurn(makeInput(), fakeEnv)

    expect(mockCreateProvider).toHaveBeenCalledWith(fakeEnv)
  })

  it('isComplete false — extractedTask is undefined regardless of LLM providing it', async () => {
    mockLlmResponse({
      reply: 'Just one more question…',
      isComplete: false,
      extractedTask: {
        title: 'Partial task',
        dueDate: null,
        scheduledTime: null,
        estimatedDurationMinutes: null,
        energyRequirement: null,
        listId: null,
      },
    })

    const result = await conductGuidedChatTurn(makeInput())

    // When isComplete is false, extractedTask should not be included
    expect(result.isComplete).toBe(false)
    expect(result.extractedTask).toBeUndefined()
  })

  it('extractedTask fields default to null when LLM omits optional fields', async () => {
    mockLlmResponse({
      reply: 'All done!',
      isComplete: true,
      extractedTask: {
        title: 'Simple task',
        // All optional fields omitted
      },
    })

    const result = await conductGuidedChatTurn(makeInput())

    expect(result.isComplete).toBe(true)
    expect(result.extractedTask?.title).toBe('Simple task')
    expect(result.extractedTask?.dueDate).toBeNull()
    expect(result.extractedTask?.scheduledTime).toBeNull()
    expect(result.extractedTask?.estimatedDurationMinutes).toBeNull()
    expect(result.extractedTask?.energyRequirement).toBeNull()
    expect(result.extractedTask?.listId).toBeNull()
  })

  it('extractedTask title is null when LLM explicitly returns null title', async () => {
    mockLlmResponse({
      reply: 'All done!',
      isComplete: true,
      extractedTask: {
        title: null,
        dueDate: '2026-04-05T00:00:00.000Z',
        scheduledTime: null,
        estimatedDurationMinutes: null,
        energyRequirement: null,
        listId: null,
      },
    })

    const result = await conductGuidedChatTurn(makeInput())

    expect(result.isComplete).toBe(true)
    expect(result.extractedTask?.title).toBeNull()
    expect(result.extractedTask?.dueDate).toBe('2026-04-05T00:00:00.000Z')
  })

  it('isComplete true with extractedTask null — extractedTask is undefined', async () => {
    mockLlmResponse({
      reply: 'All done!',
      isComplete: true,
      extractedTask: null,
    })

    const result = await conductGuidedChatTurn(makeInput())

    expect(result.isComplete).toBe(true)
    expect(result.extractedTask).toBeUndefined()
  })
})
