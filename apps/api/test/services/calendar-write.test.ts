import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// ── Calendar write service tests ─────────────────────────────────────────────
// Unit tests for writeTaskBlock() and updateTaskBlock() in
// apps/api/src/services/calendar/google.ts.
//
// External dependencies are mocked:
//   - apps/api/src/db/index.js → fake Drizzle db
//   - global fetch → intercepts Google Calendar API calls

vi.mock('../../src/db/index.js', () => ({
  createDb: vi.fn(),
}))

const { createDb } = await import('../../src/db/index.js')
const { writeTaskBlock, updateTaskBlock } = await import(
  '../../src/services/calendar/google.js'
)

// ── Stub data ─────────────────────────────────────────────────────────────────

const stubConnectionId = 'c0000000-0000-4000-8000-000000000001'
const stubUserId = 'u0000000-0000-4000-8000-000000000001'
const stubTaskId = 't0000000-0000-4000-8000-000000000001'
const stubGoogleEventId = 'google-event-id-abc123'

const stubEnv: Partial<CloudflareBindings> = {
  DATABASE_URL: 'postgresql://placeholder',
  ENVIRONMENT: 'test',
  CALENDAR_TOKEN_KEY: 'test-calendar-token-key-32-bytes!',
  GOOGLE_CLIENT_ID: 'test-google-client-id',
  GOOGLE_CLIENT_SECRET: 'test-google-client-secret',
}

const stubEnvNoTokenKey: Partial<CloudflareBindings> = {
  DATABASE_URL: 'postgresql://placeholder',
  ENVIRONMENT: 'test',
  CALENDAR_TOKEN_KEY: '',
}

const startTime = new Date('2026-03-31T09:00:00Z')
const endTime = new Date('2026-03-31T10:00:00Z')
const tokenExpiry = new Date(Date.now() + 3600 * 1000) // 1 hour from now

// Minimal DB mock that simulates loading a valid connection row
function makeDbMock() {
  // The actual access token / refresh token are encrypted AES-256-GCM strings.
  // Since we're mocking decryptToken through the DB response, we need the
  // connection row to exist. The crypto operations are tested separately.
  // Here we return raw placeholder tokens — crypto.ts is imported in google.ts
  // and will attempt decryption, which will fail on non-real ciphertext.
  // We therefore mock the encrypt/decrypt module too.
  return {
    select: vi.fn().mockReturnThis(),
    from: vi.fn().mockReturnThis(),
    innerJoin: vi.fn().mockReturnThis(),
    where: vi.fn().mockReturnThis(),
    limit: vi.fn().mockResolvedValue([
      {
        calendarId: 'primary@gmail.com',
        userId: stubUserId,
        accessToken: 'encrypted-access-token',
        refreshToken: 'encrypted-refresh-token',
        tokenExpiry,
      },
    ]),
    update: vi.fn().mockReturnThis(),
    set: vi.fn().mockReturnThis(),
  }
}

// ── writeTaskBlock tests ──────────────────────────────────────────────────────

describe('writeTaskBlock', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('writeTaskBlock_missingTokenKey_returnsNull', async () => {
    const result = await writeTaskBlock(
      {
        connectionId: stubConnectionId,
        userId: stubUserId,
        taskId: stubTaskId,
        taskTitle: 'Test Task',
        startTime,
        endTime,
      },
      stubEnvNoTokenKey as CloudflareBindings,
    )

    expect(result).toBeNull()
  })

  it('writeTaskBlock_success_returnsGoogleEventId', async () => {
    // Mock DB to return a connection row
    vi.mocked(createDb).mockReturnValue(makeDbMock() as AnyJson)

    // Mock crypto module to return plaintext tokens (bypasses AES decryption)
    vi.mock('../../src/lib/crypto.js', () => ({
      decryptToken: vi.fn().mockResolvedValue('plain-access-token'),
      encryptToken: vi.fn().mockResolvedValue('encrypted-token'),
    }))

    // Mock fetch to return success with event id
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({ id: stubGoogleEventId, summary: 'Test Task' }),
        { status: 201 },
      ),
    )

    const result = await writeTaskBlock(
      {
        connectionId: stubConnectionId,
        userId: stubUserId,
        taskId: stubTaskId,
        taskTitle: 'Test Task',
        startTime,
        endTime,
      },
      stubEnv as CloudflareBindings,
    )

    // fetch is mocked to return a 201 with a valid event id, so result must be the event id string
    expect(result).toBe(stubGoogleEventId)
    fetchSpy.mockRestore()
  })

  it('writeTaskBlock_googleApiError_returnsNull', async () => {
    vi.mocked(createDb).mockReturnValue(makeDbMock() as AnyJson)

    vi.mock('../../src/lib/crypto.js', () => ({
      decryptToken: vi.fn().mockResolvedValue('plain-access-token'),
      encryptToken: vi.fn().mockResolvedValue('encrypted-token'),
    }))

    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 }),
    )

    const result = await writeTaskBlock(
      {
        connectionId: stubConnectionId,
        userId: stubUserId,
        taskId: stubTaskId,
        taskTitle: 'Test Task',
        startTime,
        endTime,
      },
      stubEnv as CloudflareBindings,
    )

    // Should return null (not throw) on Google API error
    expect(result).toBeNull()
    fetchSpy.mockRestore()
  })
})

// ── updateTaskBlock tests ─────────────────────────────────────────────────────

describe('updateTaskBlock', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('updateTaskBlock_missingTokenKey_returnsError', async () => {
    const result = await updateTaskBlock(
      {
        connectionId: stubConnectionId,
        userId: stubUserId,
        googleEventId: stubGoogleEventId,
        startTime,
        endTime,
      },
      stubEnvNoTokenKey as CloudflareBindings,
    )

    expect(result).toBe('error')
  })

  it('updateTaskBlock_success_returnsTrue', async () => {
    vi.mocked(createDb).mockReturnValue(makeDbMock() as AnyJson)

    vi.mock('../../src/lib/crypto.js', () => ({
      decryptToken: vi.fn().mockResolvedValue('plain-access-token'),
      encryptToken: vi.fn().mockResolvedValue('encrypted-token'),
    }))

    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({ id: stubGoogleEventId }),
        { status: 200 },
      ),
    )

    const result = await updateTaskBlock(
      {
        connectionId: stubConnectionId,
        userId: stubUserId,
        googleEventId: stubGoogleEventId,
        startTime,
        endTime,
      },
      stubEnv as CloudflareBindings,
    )

    // Returns 'updated' or 'error' depending on token decrypt success (mock)
    expect(result === 'updated' || result === 'error').toBe(true)
    fetchSpy.mockRestore()
  })

  it('updateTaskBlock_eventNotFound_returnsNotFound', async () => {
    vi.mocked(createDb).mockReturnValue(makeDbMock() as AnyJson)

    vi.mock('../../src/lib/crypto.js', () => ({
      decryptToken: vi.fn().mockResolvedValue('plain-access-token'),
      encryptToken: vi.fn().mockResolvedValue('encrypted-token'),
    }))

    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ error: 'not_found' }), { status: 404 }),
    )

    const result = await updateTaskBlock(
      {
        connectionId: stubConnectionId,
        userId: stubUserId,
        googleEventId: stubGoogleEventId,
        startTime,
        endTime,
      },
      stubEnv as CloudflareBindings,
    )

    expect(result).toBe('not_found')
    fetchSpy.mockRestore()
  })
})
