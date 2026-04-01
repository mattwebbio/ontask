import { describe, it, expect, vi } from 'vitest'

// ── Mock @ai-sdk/openai to avoid real HTTP calls ───────────────────────────────
vi.mock('@ai-sdk/openai', () => ({
  createOpenAI: vi.fn((options: Record<string, unknown>) => {
    // Return a mock model factory that captures the options
    const factory = (modelId: string) => ({ id: modelId, options })
    factory._options = options
    return factory
  }),
}))

import { createAIProvider } from '../provider.js'
import { createOpenAI } from '@ai-sdk/openai'

const mockCreateOpenAI = vi.mocked(createOpenAI)

describe('createAIProvider', () => {
  it('returns a model factory (callable function)', () => {
    const provider = createAIProvider()
    expect(typeof provider).toBe('function')
  })

  it('calls createOpenAI without baseURL when no AI_GATEWAY_URL is in env', () => {
    createAIProvider()
    expect(mockCreateOpenAI).toHaveBeenCalledWith(
      expect.not.objectContaining({ baseURL: expect.anything() }),
    )
  })

  it('calls createOpenAI without baseURL when env has no AI_GATEWAY_URL', () => {
    const env = {} as unknown as CloudflareBindings
    createAIProvider(env)
    expect(mockCreateOpenAI).toHaveBeenCalledWith(
      expect.not.objectContaining({ baseURL: expect.anything() }),
    )
  })

  it('calls createOpenAI with baseURL when AI_GATEWAY_URL is in env', () => {
    const env = {
      AI_GATEWAY_URL: 'https://gateway.ai.cloudflare.com/v1/acct/gw/openai',
    } as unknown as CloudflareBindings
    createAIProvider(env)
    expect(mockCreateOpenAI).toHaveBeenCalledWith(
      expect.objectContaining({
        baseURL: 'https://gateway.ai.cloudflare.com/v1/acct/gw/openai',
      }),
    )
  })

  it('calls createOpenAI without baseURL when AI_GATEWAY_URL is an empty string', () => {
    const env = { AI_GATEWAY_URL: '' } as unknown as CloudflareBindings
    createAIProvider(env)
    expect(mockCreateOpenAI).toHaveBeenCalledWith(
      expect.not.objectContaining({ baseURL: expect.anything() }),
    )
  })
})
