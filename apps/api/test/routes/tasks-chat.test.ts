import { describe, expect, it, vi, beforeEach } from 'vitest'
import app from '../../src/index.js'

// ── Mock @ontask/ai — never call real LLM in API route tests ─────────────────
vi.mock('@ontask/ai', () => ({
  parseTaskUtterance: vi.fn(),
  parseSchedulingNudge: vi.fn(),
  conductGuidedChatTurn: vi.fn(),
}))

import { conductGuidedChatTurn } from '@ontask/ai'

const mockConductGuidedChatTurn = vi.mocked(conductGuidedChatTurn)

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// ── Helpers ───────────────────────────────────────────────────────────────────

function mockMidConversationResult() {
  mockConductGuidedChatTurn.mockResolvedValueOnce({
    reply: 'When does this task need to be done by?',
    isComplete: false,
    extractedTask: undefined,
  })
}

function mockFinalTurnResult() {
  mockConductGuidedChatTurn.mockResolvedValueOnce({
    reply: 'Got it! Ready to create your task.',
    isComplete: true,
    extractedTask: {
      title: 'Call the dentist',
      dueDate: '2026-04-03T00:00:00.000Z',
      scheduledTime: null,
      estimatedDurationMinutes: null,
      energyRequirement: null,
      listId: null,
    },
  })
}

function mockTimeoutError() {
  const error = new Error('Chat assistant timed out — please try again') as NodeJS.ErrnoException
  error.code = 'TIMEOUT'
  mockConductGuidedChatTurn.mockRejectedValueOnce(error)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('POST /v1/tasks/chat', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('valid messages array returns 200 with reply, isComplete: false', async () => {
    mockMidConversationResult()

    const res = await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({
        messages: [{ role: 'user', content: 'I need to call the dentist' }],
      }),
    })

    expect(res.status).toBe(200)
    const json = await res.json() as AnyJson
    expect(json.data.reply).toBe('When does this task need to be done by?')
    expect(json.data.isComplete).toBe(false)
  })

  it('final turn returns 200 with isComplete: true and extractedTask', async () => {
    mockFinalTurnResult()

    const res = await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({
        messages: [
          { role: 'user', content: 'Call the dentist Thursday' },
          { role: 'assistant', content: 'What energy level?' },
          { role: 'user', content: 'Low energy' },
        ],
      }),
    })

    expect(res.status).toBe(200)
    const json = await res.json() as AnyJson
    expect(json.data.isComplete).toBe(true)
    expect(json.data.extractedTask).toBeDefined()
    expect(json.data.extractedTask.title).toBe('Call the dentist')
    expect(json.data.extractedTask.dueDate).toBe('2026-04-03T00:00:00.000Z')
  })

  it('LLM timeout returns 422 UNPROCESSABLE with timeout message', async () => {
    mockTimeoutError()

    const res = await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({
        messages: [{ role: 'user', content: 'I need to do something' }],
      }),
    })

    expect(res.status).toBe(422)
    const json = await res.json() as AnyJson
    expect(json.error.code).toBe('UNPROCESSABLE')
    expect(json.error.message).toContain('timed out')
  })

  it('empty messages array returns 400', async () => {
    const res = await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({ messages: [] }),
    })

    expect(res.status).toBe(400)
  })

  it('missing messages field returns 400', async () => {
    const res = await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({}),
    })

    expect(res.status).toBe(400)
  })

  it('message with empty content returns 400', async () => {
    const res = await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({
        messages: [{ role: 'user', content: '' }],
      }),
    })

    expect(res.status).toBe(400)
  })

  it('passes x-user-id header to conductGuidedChatTurn', async () => {
    mockMidConversationResult()

    await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'specific-user-id' },
      body: JSON.stringify({
        messages: [{ role: 'user', content: 'I need to create a task' }],
      }),
    })

    expect(mockConductGuidedChatTurn).toHaveBeenCalledOnce()
    const callArgs = mockConductGuidedChatTurn.mock.calls[0]![0] as { userId: string }
    expect(callArgs.userId).toBe('specific-user-id')
  })

  it('passes availableLists from request body to conductGuidedChatTurn', async () => {
    mockMidConversationResult()

    const availableLists = [{ id: 'list-1', title: 'Work' }]

    await app.request('/v1/tasks/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-user-id': 'test-user' },
      body: JSON.stringify({
        messages: [{ role: 'user', content: 'Work task' }],
        availableLists,
      }),
    })

    expect(mockConductGuidedChatTurn).toHaveBeenCalledOnce()
    const callArgs = mockConductGuidedChatTurn.mock.calls[0]![0] as { availableLists: typeof availableLists }
    expect(callArgs.availableLists).toEqual(availableLists)
  })
})
