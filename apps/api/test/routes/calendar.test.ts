import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// ── Calendar routes tests ─────────────────────────────────────────────────────
// Tests for POST /v1/calendar/connect and GET /v1/calendar/connections.
//
// The calendar routes call external dependencies (DB, Google APIs), so we mock:
//   - apps/api/src/db/index.js → returns a fake Drizzle db object
//   - global fetch → intercepts Google API calls

// Mock the DB module
vi.mock('../../src/db/index.js', () => ({
  createDb: vi.fn(),
}))

// Import after mock setup
const { createDb } = await import('../../src/db/index.js')
const app = (await import('../../src/index.js')).default

// ── Stub data ─────────────────────────────────────────────────────────────────

const stubConnectionId = 'c0000000-0000-4000-8000-000000000001'
const stubUserId = 'u0000000-0000-4000-8000-000000000001'

// Minimal fake CloudflareBindings env for tests that access c.env.
// Passed as the third argument to app.request() so Hono populates c.env.
const stubEnv: Partial<CloudflareBindings> = {
  DATABASE_URL: 'postgresql://placeholder',
  ENVIRONMENT: 'test',
  CALENDAR_TOKEN_KEY: 'test-calendar-token-key-32-bytes!',
  GOOGLE_CLIENT_ID: 'test-google-client-id',
  GOOGLE_CLIENT_SECRET: 'test-google-client-secret',
}

const stubConnection = {
  id: stubConnectionId,
  provider: 'google',
  calendarId: 'primary@gmail.com',
  displayName: 'My Google Calendar',
  isRead: true,
  isWrite: false,
}

// ── GET /v1/calendar/connections ──────────────────────────────────────────────

describe('GET /v1/calendar/connections', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('returns 200 with data array on success', async () => {
    const mockDb = {
      select: vi.fn().mockReturnThis(),
      from: vi.fn().mockReturnThis(),
      where: vi.fn().mockResolvedValue([stubConnection]),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/calendar/connections',
      { method: 'GET', headers: { 'x-user-id': stubUserId } },
      stubEnv,
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(Array.isArray(body.data)).toBe(true)
  })

  it('returns 200 with empty array when no connections', async () => {
    const mockDb = {
      select: vi.fn().mockReturnThis(),
      from: vi.fn().mockReturnThis(),
      where: vi.fn().mockResolvedValue([]),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/calendar/connections',
      { method: 'GET', headers: { 'x-user-id': stubUserId } },
      stubEnv,
    )

    expect(res.status).toBe(200)
    const body = (await res.json()) as AnyJson
    expect(body.data).toHaveLength(0)
  })

  it('returns connection without tokens (AC 7)', async () => {
    const mockDb = {
      select: vi.fn().mockReturnThis(),
      from: vi.fn().mockReturnThis(),
      where: vi.fn().mockResolvedValue([stubConnection]),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/calendar/connections',
      { method: 'GET', headers: { 'x-user-id': stubUserId } },
      stubEnv,
    )

    const body = (await res.json()) as AnyJson
    const conn = body.data[0]

    // Must have expected fields
    expect(conn).toHaveProperty('id')
    expect(conn).toHaveProperty('provider')
    expect(conn).toHaveProperty('calendarId')
    expect(conn).toHaveProperty('displayName')
    expect(conn).toHaveProperty('isRead')
    expect(conn).toHaveProperty('isWrite')

    // Must NOT expose tokens
    expect(conn).not.toHaveProperty('accessToken')
    expect(conn).not.toHaveProperty('refreshToken')
    expect(conn).not.toHaveProperty('tokenExpiry')
  })

  it('returned connection has correct provider field', async () => {
    const mockDb = {
      select: vi.fn().mockReturnThis(),
      from: vi.fn().mockReturnThis(),
      where: vi.fn().mockResolvedValue([stubConnection]),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/calendar/connections',
      { method: 'GET', headers: { 'x-user-id': stubUserId } },
      stubEnv,
    )

    const body = (await res.json()) as AnyJson
    expect(body.data[0].provider).toBe('google')
  })
})

// ── POST /v1/calendar/connect ─────────────────────────────────────────────────

describe('POST /v1/calendar/connect', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  const validBody = {
    provider: 'google',
    authorizationCode: 'auth-code-abc123',
    redirectUri: 'https://app.ontaskhq.com/oauth/google/callback',
  }

  it('returns 400 when provider is invalid', async () => {
    const res = await app.request(
      '/v1/calendar/connect',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify({ ...validBody, provider: 'unknown' }),
      },
      stubEnv,
    )

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('returns 400 when authorizationCode is missing', async () => {
    const res = await app.request(
      '/v1/calendar/connect',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify({ provider: 'google', redirectUri: 'https://example.com/callback' }),
      },
      stubEnv,
    )

    expect(res.status).toBeGreaterThanOrEqual(400)
  })

  it('returns 400 when Google OAuth token exchange fails', async () => {
    // Mock fetch to return a non-200 from Google token endpoint
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ error: 'invalid_grant' }), { status: 400 }),
    )

    const res = await app.request(
      '/v1/calendar/connect',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify(validBody),
      },
      stubEnv,
    )

    expect(res.status).toBe(400)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('OAUTH_EXCHANGE_FAILED')
  })

  it('returns 201 with connectionId on success', async () => {
    // Mock Google token exchange, userinfo, and calendar primary fetch
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(
        // Token exchange
        new Response(
          JSON.stringify({
            access_token: 'access-token-abc',
            refresh_token: 'refresh-token-xyz',
            expires_in: 3600,
          }),
          { status: 200 },
        ),
      )
      .mockResolvedValueOnce(
        // Userinfo
        new Response(JSON.stringify({ email: 'user@gmail.com' }), { status: 200 }),
      )
      .mockResolvedValueOnce(
        // Calendar primary fetch
        new Response(JSON.stringify({ id: 'primary', summary: 'My Calendar' }), { status: 200 }),
      )

    const mockDb = {
      transaction: vi.fn().mockResolvedValue(stubConnectionId),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/calendar/connect',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify(validBody),
      },
      stubEnv,
    )

    expect(res.status).toBe(201)
    const body = (await res.json()) as AnyJson
    expect(body).toHaveProperty('data')
    expect(body.data).toHaveProperty('connectionId')
    expect(body.data).toHaveProperty('calendarId')
    expect(body.data).toHaveProperty('displayName')

    fetchMock.mockRestore()
  })

  it('returns 400 when Google calendar info fetch fails', async () => {
    vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(
        // Token exchange succeeds
        new Response(
          JSON.stringify({
            access_token: 'access-token-abc',
            refresh_token: 'refresh-token-xyz',
            expires_in: 3600,
          }),
          { status: 200 },
        ),
      )
      .mockResolvedValueOnce(
        // Userinfo
        new Response(JSON.stringify({ email: 'user@gmail.com' }), { status: 200 }),
      )
      .mockResolvedValueOnce(
        // Calendar fetch fails
        new Response(JSON.stringify({ error: 'forbidden' }), { status: 403 }),
      )

    const res = await app.request(
      '/v1/calendar/connect',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify(validBody),
      },
      stubEnv,
    )

    expect(res.status).toBe(400)
    const body = (await res.json()) as AnyJson
    expect(body.error.code).toBe('CALENDAR_FETCH_FAILED')
  })
})
