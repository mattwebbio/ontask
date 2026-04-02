// ── MCP OAuth Middleware (FR93, Story 10.4) ────────────────────────────────────
//
// Bearer token authentication for the MCP Worker.
// Validates tokens by delegating to the API Worker via Service Binding —
// the MCP Worker has no direct database access.
//
// Protected routes: /tools/* (all tool invocations)
// Unprotected routes: GET /tools (manifest discovery), GET / (health check)
//
// On valid token: attaches { userId, scopes } to Hono context via c.set('mcpAuth', ...)
// On missing/invalid/revoked token: returns 401 with standard error envelope

import type { Hono } from 'hono'

export interface McpAuthPayload {
  userId: string
  scopes: string[]
}

// Augment Hono context variables so handlers can access mcpAuth with type safety
declare module 'hono' {
  interface ContextVariableMap {
    mcpAuth: McpAuthPayload
  }
}

/**
 * Applies OAuth Bearer token middleware to all /tools/* routes.
 *
 * Token validation is delegated to the API Worker via Service Binding
 * (GET /internal/mcp-tokens/validate?token=<raw>). The API Worker
 * hashes the token, checks the DB, updates lastUsedAt, and returns
 * { userId, scopes } on success.
 *
 * CRITICAL: Never call api.ontaskhq.com directly — always use env.API.fetch().
 */
export function applyOauthMiddleware(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  app: Hono<{ Bindings: { API?: { fetch: (...args: any[]) => Promise<any> } } }>,
): void {
  app.use('/tools/*', async (c, next) => {
    // GET /tools (manifest discovery) is unauthenticated — only sub-paths are protected.
    // Hono's /tools/* wildcard matches /tools as well as /tools/<anything>, so we
    // explicitly pass through the manifest discovery endpoint here.
    const path = new URL(c.req.url).pathname
    if (c.req.method === 'GET' && (path === '/tools' || path === '/tools/')) {
      return next()
    }

    const authHeader = c.req.header('Authorization')

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return c.json(
        { error: { code: 'UNAUTHORIZED', message: 'Authorization Bearer token is required' } },
        401,
      )
    }

    const rawToken = authHeader.slice('Bearer '.length).trim()

    if (!rawToken) {
      return c.json(
        { error: { code: 'UNAUTHORIZED', message: 'Authorization Bearer token is required' } },
        401,
      )
    }

    const apiBinding = c.env.API
    if (!apiBinding) {
      return c.json(
        { error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } },
        503,
      )
    }

    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const validationResponse: any = await apiBinding.fetch(
        `https://ontask-api-internal/internal/mcp-tokens/validate?token=${encodeURIComponent(rawToken)}`,
        {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' },
        },
      )

      if (!validationResponse.ok) {
        const body = (await validationResponse.json()) as {
          error?: { code?: string; message?: string }
        }
        const code = body?.error?.code ?? 'UNAUTHORIZED'
        const message = body?.error?.message ?? 'Invalid or revoked token'
        return c.json({ error: { code, message } }, 401)
      }

      const payload = (await validationResponse.json()) as {
        data: { userId: string; scopes: string[] }
      }

      c.set('mcpAuth', {
        userId: payload.data.userId,
        scopes: payload.data.scopes,
      })

      await next()
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e)
      return c.json(
        { error: { code: 'UPSTREAM_ERROR', message: `Token validation failed: ${message}` } },
        502,
      )
    }
  })
}

/**
 * Checks that the required scope is present in the token's granted scopes.
 * Call this within tool route handlers to enforce per-tool scope requirements.
 */
export function requireScope(scopes: string[], requiredScope: string): boolean {
  return scopes.includes(requiredScope)
}
