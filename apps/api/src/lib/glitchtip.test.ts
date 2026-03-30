import { describe, expect, it, vi } from 'vitest'

import { AppError } from './errors.js'
import { reportToGlitchTip } from './glitchtip.js'

// ---------------------------------------------------------------------------
// Minimal CloudflareBindings stub for tests.
// ---------------------------------------------------------------------------
function makeEnv(overrides: Partial<CloudflareBindings> = {}): CloudflareBindings {
  return {
    DATABASE_URL: 'postgresql://test',
    ENVIRONMENT: 'test',
    GLITCHTIP_DSN: '',
    POSTHOG_API_KEY: '',
    ...overrides,
  } as unknown as CloudflareBindings
}

const defaultContext = {
  workerName: 'ontask-api',
  environment: 'test',
  path: '/v1/test',
  method: 'GET',
}

describe('reportToGlitchTip', () => {
  it('does NOT throw when GLITCHTIP_DSN is empty', async () => {
    const env = makeEnv({ GLITCHTIP_DSN: '' })
    await expect(reportToGlitchTip(new Error('test error'), defaultContext, env)).resolves.not.toThrow()
  })

  it('does NOT throw when GLITCHTIP_DSN is undefined', async () => {
    const env = makeEnv({ GLITCHTIP_DSN: undefined })
    await expect(reportToGlitchTip(new Error('test error'), defaultContext, env)).resolves.not.toThrow()
  })

  it('does NOT throw when the error is a plain string', async () => {
    const env = makeEnv({ GLITCHTIP_DSN: '' })
    await expect(reportToGlitchTip('something went wrong', defaultContext, env)).resolves.not.toThrow()
  })

  it('does NOT throw when the error is null', async () => {
    const env = makeEnv({ GLITCHTIP_DSN: '' })
    await expect(reportToGlitchTip(null, defaultContext, env)).resolves.not.toThrow()
  })

  it('does NOT throw even if fetch would fail (resilience)', async () => {
    // Stub global fetch to throw to simulate network failure.
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network error')))

    // With a DSN set, the stub would attempt to call fetch.
    // Even if fetch fails, reportToGlitchTip must not propagate the error.
    const env = makeEnv({ GLITCHTIP_DSN: 'https://key@glitchtip.example.com/1' })
    await expect(reportToGlitchTip(new Error('crash'), defaultContext, env)).resolves.not.toThrow()

    vi.restoreAllMocks()
  })

  it('returns void (undefined) on success', async () => {
    const env = makeEnv({ GLITCHTIP_DSN: '' })
    const result = await reportToGlitchTip(new Error('test'), defaultContext, env)
    expect(result).toBeUndefined()
  })
})

describe('AppError instances — NOT forwarded to GlitchTip', () => {
  // This test validates the architectural rule: AppError subclasses are known
  // business errors and must not be reported as crashes (AC #2).
  // The onError handler in index.ts enforces this by only calling
  // reportToGlitchTip in the `else` branch (non-AppError path).

  it('AppError is instanceof AppError (used to gate reporting in index.ts)', () => {
    class TestBusinessError extends AppError {
      constructor() {
        super('TEST_ERROR', 422, 'Test business error')
      }
    }

    const err = new TestBusinessError()
    expect(err instanceof AppError).toBe(true)
  })

  it('unexpected Error is NOT instanceof AppError', () => {
    const err = new Error('Unexpected crash')
    expect(err instanceof AppError).toBe(false)
  })
})
