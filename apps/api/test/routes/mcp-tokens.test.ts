import { describe, expect, it, vi, beforeEach } from 'vitest'

// ── MCP Token API route tests (Story 10.4) ────────────────────────────────────
//
// Tests for:
//   POST /v1/mcp-tokens        — token issuance
//   GET  /v1/mcp-tokens        — token listing (no tokenHash in response)
//   DELETE /v1/mcp-tokens/:id  — token revocation
//   GET /internal/mcp-tokens/validate — token validation (used by MCP Worker)
//
// Mock pattern: vi.mock createDb → returns fake Drizzle db object.
// crypto.subtle.digest and crypto.getRandomValues are available in vitest/node.
//
// Note: The crypto.subtle and crypto.getRandomValues APIs used in production
// are the Web Crypto API available in both Cloudflare Workers and Node.js 19+.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// Mock the DB module before any imports
vi.mock('../../src/db/index.js', () => ({
  createDb: vi.fn(),
}))

// Mock scheduling (imported transitively by index.ts)
vi.mock('../../src/services/scheduling.js', () => ({
  runScheduleForUser: vi.fn().mockResolvedValue({}),
}))

const { createDb } = await import('../../src/db/index.js')
const app = (await import('../../src/index.js')).default

const stubUserId = 'u0000000-0000-4000-8000-000000000001'
const stubTokenId = 't0000000-0000-4000-8000-000000000001'

const stubEnv: Partial<CloudflareBindings> = {
  DATABASE_URL: 'postgresql://placeholder',
  ENVIRONMENT: 'test',
}

// ── Helper to compute SHA-256 hex (same as production code) ──────────────────
async function sha256Hex(raw: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(raw)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

describe('POST /v1/mcp-tokens', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('creates token, returns raw token once, stores only hash', async () => {
    const now = new Date('2026-04-01T12:00:00.000Z')
    const stubRecord = {
      id: stubTokenId,
      clientName: 'My AI Assistant',
      scopes: ['tasks:read', 'tasks:write'],
      createdAt: now,
    }

    const mockDb = {
      insert: vi.fn().mockReturnThis(),
      values: vi.fn().mockReturnThis(),
      returning: vi.fn().mockResolvedValue([stubRecord]),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/mcp-tokens',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify({ clientName: 'My AI Assistant', scopes: ['tasks:read', 'tasks:write'] }),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(201)
    const body = await res.json() as AnyJson
    expect(body.data.id).toBe(stubTokenId)
    expect(body.data.clientName).toBe('My AI Assistant')
    expect(body.data.scopes).toEqual(['tasks:read', 'tasks:write'])
    expect(body.data.token).toBeDefined()
    expect(typeof body.data.token).toBe('string')
    expect(body.data.token.length).toBeGreaterThan(0)
    // tokenHash must NOT be in the response
    expect('tokenHash' in body.data).toBe(false)

    // Verify the token hash stored is different from raw token
    const insertCall = mockDb.values.mock.calls[0][0] as AnyJson
    expect(insertCall.tokenHash).toBeDefined()
    expect(insertCall.tokenHash).not.toBe(body.data.token)
    // Verify it is a SHA-256 hex (64 chars)
    expect(insertCall.tokenHash).toMatch(/^[0-9a-f]{64}$/)

    // Verify stored hash matches raw token
    const expectedHash = await sha256Hex(body.data.token)
    expect(insertCall.tokenHash).toBe(expectedHash)
  })

  it('returns 400 when clientName is missing', async () => {
    const res = await app.request(
      '/v1/mcp-tokens',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify({ scopes: ['tasks:read'] }),
      },
      stubEnv as CloudflareBindings,
    )
    expect(res.status).toBe(400)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('VALIDATION_ERROR')
  })

  it('returns 400 for invalid scope string', async () => {
    const res = await app.request(
      '/v1/mcp-tokens',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': stubUserId },
        body: JSON.stringify({ clientName: 'Test', scopes: ['invalid:scope'] }),
      },
      stubEnv as CloudflareBindings,
    )
    expect(res.status).toBe(400)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('VALIDATION_ERROR')
  })

  it('returns 401 when x-user-id header is missing', async () => {
    const res = await app.request(
      '/v1/mcp-tokens',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ clientName: 'Test', scopes: ['tasks:read'] }),
      },
      stubEnv as CloudflareBindings,
    )
    expect(res.status).toBe(401)
  })
})

describe('GET /v1/mcp-tokens', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('lists active tokens, never includes tokenHash field', async () => {
    const stubTokens = [
      {
        id: stubTokenId,
        clientName: 'My AI Assistant',
        scopes: ['tasks:read'],
        lastUsedAt: null,
        createdAt: new Date('2026-04-01T10:00:00.000Z'),
      },
    ]

    const mockDb = {
      select: vi.fn().mockReturnThis(),
      from: vi.fn().mockReturnThis(),
      where: vi.fn().mockResolvedValue(stubTokens),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/v1/mcp-tokens',
      {
        method: 'GET',
        headers: { 'x-user-id': stubUserId },
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data).toBeInstanceOf(Array)
    expect(body.data).toHaveLength(1)
    expect(body.data[0].id).toBe(stubTokenId)
    expect(body.data[0].clientName).toBe('My AI Assistant')
    // tokenHash must NEVER appear in list response
    expect('tokenHash' in body.data[0]).toBe(false)
  })

  it('returns 401 when x-user-id header is missing', async () => {
    const res = await app.request(
      '/v1/mcp-tokens',
      { method: 'GET' },
      stubEnv as CloudflareBindings,
    )
    expect(res.status).toBe(401)
  })
})

describe('DELETE /v1/mcp-tokens/:id', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('sets revokedAt on token and returns 204', async () => {
    const mockDb = {
      select: vi.fn().mockReturnThis(),
      from: vi.fn().mockReturnThis(),
      where: vi.fn().mockReturnThis(),
      limit: vi.fn().mockResolvedValue([{ id: stubTokenId }]),
      update: vi.fn().mockReturnThis(),
      set: vi.fn().mockReturnThis(),
    }
    // Make the second .where() call (for UPDATE) also chainable
    // We need to handle both SELECT and UPDATE chains
    let callCount = 0
    const whereImpl = vi.fn().mockImplementation(function(this: AnyJson) {
      callCount++
      if (callCount === 1) {
        // SELECT chain — returns object with limit()
        return { limit: vi.fn().mockResolvedValue([{ id: stubTokenId }]) }
      }
      // UPDATE chain — resolves with nothing
      return Promise.resolve()
    })

    const mockDb2 = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([{ id: stubTokenId }]),
          }),
        }),
      }),
      update: vi.fn().mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue([]),
        }),
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb2 as AnyJson)

    const res = await app.request(
      `/v1/mcp-tokens/${stubTokenId}`,
      {
        method: 'DELETE',
        headers: { 'x-user-id': stubUserId },
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(204)
    expect(mockDb2.update).toHaveBeenCalled()
    const setCall = mockDb2.update.mock.results[0].value.set.mock.calls[0][0] as AnyJson
    expect(setCall.revokedAt).toBeDefined()
    expect(setCall.revokedAt).toBeInstanceOf(Date)
  })

  it('returns 404 when token does not belong to user', async () => {
    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),  // empty = not found
          }),
        }),
      }),
      update: vi.fn().mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue([]),
        }),
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      `/v1/mcp-tokens/${stubTokenId}`,
      {
        method: 'DELETE',
        headers: { 'x-user-id': stubUserId },
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(404)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('NOT_FOUND')
    // update should NOT have been called
    expect(mockDb.update).not.toHaveBeenCalled()
  })
})

describe('GET /internal/mcp-tokens/validate', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 200 with userId and scopes for valid token', async () => {
    const rawToken = 'valid-test-token-abc123'
    const tokenHash = await sha256Hex(rawToken)
    const now = new Date()

    const stubToken = {
      id: stubTokenId,
      userId: stubUserId,
      clientName: 'Test Client',
      tokenHash,
      scopes: ['tasks:read', 'tasks:write'],
      revokedAt: null,
      lastUsedAt: null,
      createdAt: now,
    }

    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([stubToken]),
          }),
        }),
      }),
      update: vi.fn().mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue([]),
        }),
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      `/internal/mcp-tokens/validate?token=${encodeURIComponent(rawToken)}`,
      { method: 'GET' },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.userId).toBe(stubUserId)
    expect(body.data.scopes).toEqual(['tasks:read', 'tasks:write'])
    // Verify lastUsedAt was updated
    expect(mockDb.update).toHaveBeenCalled()
  })

  it('returns 401 TOKEN_REVOKED for revoked token', async () => {
    const rawToken = 'revoked-token-xyz'
    const tokenHash = await sha256Hex(rawToken)

    const stubRevokedToken = {
      id: stubTokenId,
      userId: stubUserId,
      tokenHash,
      scopes: ['tasks:read'],
      revokedAt: new Date('2026-03-30T10:00:00.000Z'),  // non-null = revoked
      lastUsedAt: null,
      createdAt: new Date(),
    }

    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([stubRevokedToken]),
          }),
        }),
      }),
      update: vi.fn(),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      `/internal/mcp-tokens/validate?token=${encodeURIComponent(rawToken)}`,
      { method: 'GET' },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(401)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('TOKEN_REVOKED')
    // update should NOT be called for revoked tokens
    expect(mockDb.update).not.toHaveBeenCalled()
  })

  it('returns 401 UNAUTHORIZED for unknown token', async () => {
    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),  // empty = not found
          }),
        }),
      }),
      update: vi.fn(),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      `/internal/mcp-tokens/validate?token=unknown-token`,
      { method: 'GET' },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(401)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('UNAUTHORIZED')
    expect(mockDb.update).not.toHaveBeenCalled()
  })

  it('returns 401 when token query param is missing', async () => {
    const mockDb = { select: vi.fn(), update: vi.fn() }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/internal/mcp-tokens/validate',
      { method: 'GET' },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(401)
    expect(mockDb.select).not.toHaveBeenCalled()
  })
})
