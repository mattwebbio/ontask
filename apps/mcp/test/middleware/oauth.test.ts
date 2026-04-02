import { describe, expect, it, vi } from 'vitest'
import { Hono } from 'hono'
import { applyOauthMiddleware, requireScope } from '../../src/middleware/oauth.js'

// ── MCP OAuth Middleware Tests (Story 10.4) ────────────────────────────────────
//
// Tests cover:
//   - Missing Authorization header → 401
//   - Invalid token (API returns 401) → 401 UNAUTHORIZED
//   - Revoked token (API returns TOKEN_REVOKED) → 401 TOKEN_REVOKED
//   - Valid token → context populated with userId and scopes, next() called
//   - Scope enforcement → 403 when required scope not in token scopes
//
// Mock pattern: env.API.fetch is a vi.fn() returning Response-like objects.
// Middleware is tested via a minimal Hono app with a test route.

function makeApp(apiFetchImpl: ReturnType<typeof vi.fn>) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const app = new Hono<{ Bindings: { API?: { fetch: (...args: any[]) => Promise<any> } } }>()
  applyOauthMiddleware(app)

  // Test route that echoes the mcpAuth context
  app.post('/tools/test', (c) => {
    const auth = c.get('mcpAuth')
    return c.json({ ok: true, auth })
  })

  return {
    request: (path: string, init?: RequestInit) => {
      return app.request(path, init, {
        API: { fetch: apiFetchImpl },
      })
    },
  }
}

function makeApiResponse(opts: {
  ok: boolean
  status: number
  body: unknown
}) {
  return vi.fn().mockResolvedValue({
    ok: opts.ok,
    status: opts.status,
    json: async () => opts.body,
    text: async () => JSON.stringify(opts.body),
  })
}

describe('OAuth middleware', () => {
  it('returns 401 when Authorization header is missing', async () => {
    const apiFetch = makeApiResponse({ ok: true, status: 200, body: {} })
    const app = makeApp(apiFetch)

    const res = await app.request('/tools/test', { method: 'POST' })

    expect(res.status).toBe(401)
    const body = await res.json() as { error: { code: string } }
    expect(body.error.code).toBe('UNAUTHORIZED')
    expect(apiFetch).not.toHaveBeenCalled()
  })

  it('returns 401 when Authorization header is not Bearer scheme', async () => {
    const apiFetch = makeApiResponse({ ok: true, status: 200, body: {} })
    const app = makeApp(apiFetch)

    const res = await app.request('/tools/test', {
      method: 'POST',
      headers: { Authorization: 'Basic abc123' },
    })

    expect(res.status).toBe(401)
    const body = await res.json() as { error: { code: string } }
    expect(body.error.code).toBe('UNAUTHORIZED')
    expect(apiFetch).not.toHaveBeenCalled()
  })

  it('returns 401 UNAUTHORIZED when API returns 401 for unknown token', async () => {
    const apiFetch = makeApiResponse({
      ok: false,
      status: 401,
      body: { error: { code: 'UNAUTHORIZED', message: 'Token not found' } },
    })
    const app = makeApp(apiFetch)

    const res = await app.request('/tools/test', {
      method: 'POST',
      headers: { Authorization: 'Bearer unknown-token-xyz' },
    })

    expect(res.status).toBe(401)
    const body = await res.json() as { error: { code: string } }
    expect(body.error.code).toBe('UNAUTHORIZED')
    expect(apiFetch).toHaveBeenCalledOnce()
  })

  it('returns 401 TOKEN_REVOKED when API returns TOKEN_REVOKED', async () => {
    const apiFetch = makeApiResponse({
      ok: false,
      status: 401,
      body: { error: { code: 'TOKEN_REVOKED', message: 'Token has been revoked' } },
    })
    const app = makeApp(apiFetch)

    const res = await app.request('/tools/test', {
      method: 'POST',
      headers: { Authorization: 'Bearer revoked-token-abc' },
    })

    expect(res.status).toBe(401)
    const body = await res.json() as { error: { code: string; message: string } }
    expect(body.error.code).toBe('TOKEN_REVOKED')
    expect(apiFetch).toHaveBeenCalledOnce()
  })

  it('passes userId and scopes to context on valid token', async () => {
    const apiFetch = makeApiResponse({
      ok: true,
      status: 200,
      body: {
        data: {
          userId: 'user-uuid-123',
          scopes: ['tasks:read', 'tasks:write'],
        },
      },
    })
    const app = makeApp(apiFetch)

    const res = await app.request('/tools/test', {
      method: 'POST',
      headers: { Authorization: 'Bearer valid-token-here' },
    })

    expect(res.status).toBe(200)
    const body = await res.json() as { ok: boolean; auth: { userId: string; scopes: string[] } }
    expect(body.ok).toBe(true)
    expect(body.auth.userId).toBe('user-uuid-123')
    expect(body.auth.scopes).toEqual(['tasks:read', 'tasks:write'])
    expect(apiFetch).toHaveBeenCalledOnce()
  })

  it('calls API validation endpoint with raw token in query param', async () => {
    const apiFetch = makeApiResponse({
      ok: true,
      status: 200,
      body: { data: { userId: 'u1', scopes: ['tasks:read'] } },
    })
    const app = makeApp(apiFetch)
    const rawToken = 'my-test-raw-token'

    await app.request('/tools/test', {
      method: 'POST',
      headers: { Authorization: `Bearer ${rawToken}` },
    })

    expect(apiFetch).toHaveBeenCalledOnce()
    const callUrl = apiFetch.mock.calls[0][0] as string
    expect(callUrl).toContain('/internal/mcp-tokens/validate')
    expect(callUrl).toContain(encodeURIComponent(rawToken))
  })

  it('does NOT apply to GET / (health check remains unauthenticated)', async () => {
    const apiFetch = makeApiResponse({ ok: true, status: 200, body: {} })
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const healthApp = new Hono<{ Bindings: { API?: { fetch: (...args: any[]) => Promise<any> } } }>()
    applyOauthMiddleware(healthApp)
    healthApp.get('/', (c) => c.text('OnTask MCP Server'))

    const res = await healthApp.request('/', { method: 'GET' }, { API: { fetch: apiFetch } })

    expect(res.status).toBe(200)
    expect(apiFetch).not.toHaveBeenCalled()
  })

  it('returns 403 when valid token lacks required scope', async () => {
    const apiFetch = makeApiResponse({
      ok: true,
      status: 200,
      body: { data: { userId: 'user-uuid-123', scopes: ['tasks:read'] } },
    })
    // Build an app with a route that requires tasks:write
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const scopeApp = new Hono<{ Bindings: { API?: { fetch: (...args: any[]) => Promise<any> } } }>()
    applyOauthMiddleware(scopeApp)
    scopeApp.post('/tools/write-only', (c) => {
      const { scopes } = c.get('mcpAuth')
      if (!requireScope(scopes, 'tasks:write')) {
        return c.json(
          { content: [{ type: 'text', text: JSON.stringify({ error: { code: 'FORBIDDEN', message: 'tasks:write scope required' } }) }], isError: true },
          403,
        )
      }
      return c.json({ ok: true })
    })

    const res = await scopeApp.request(
      '/tools/write-only',
      { method: 'POST', headers: { Authorization: 'Bearer read-only-token' } },
      { API: { fetch: apiFetch } },
    )

    expect(res.status).toBe(403)
    const body = await res.json() as { content: Array<{ type: string; text: string }>; isError: boolean }
    expect(body.isError).toBe(true)
    const parsed = JSON.parse(body.content[0].text) as { error: { code: string } }
    expect(parsed.error.code).toBe('FORBIDDEN')
    // Token was valid — API was called to validate it
    expect(apiFetch).toHaveBeenCalledOnce()
  })

  it('does NOT apply to GET /tools (manifest discovery remains unauthenticated)', async () => {
    const apiFetch = makeApiResponse({ ok: true, status: 200, body: {} })
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const manifestApp = new Hono<{ Bindings: { API?: { fetch: (...args: any[]) => Promise<any> } } }>()
    applyOauthMiddleware(manifestApp)
    manifestApp.get('/tools', (c) => c.json({ tools: [] }))

    const res = await manifestApp.request('/tools', { method: 'GET' }, { API: { fetch: apiFetch } })

    expect(res.status).toBe(200)
    expect(apiFetch).not.toHaveBeenCalled()
  })
})

describe('requireScope', () => {
  it('returns true when required scope is present', () => {
    expect(requireScope(['tasks:read', 'tasks:write'], 'tasks:read')).toBe(true)
    expect(requireScope(['tasks:read', 'tasks:write'], 'tasks:write')).toBe(true)
  })

  it('returns false when required scope is not present', () => {
    expect(requireScope(['tasks:read'], 'tasks:write')).toBe(false)
    expect(requireScope(['tasks:read'], 'contracts:read')).toBe(false)
    expect(requireScope(['tasks:read', 'tasks:write'], 'contracts:write')).toBe(false)
  })

  it('returns false for empty scopes array', () => {
    expect(requireScope([], 'tasks:read')).toBe(false)
  })
})
