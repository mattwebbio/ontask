import { Hono } from 'hono'
import { eq } from 'drizzle-orm'
import { createDb } from '../db/index.js'
import { mcpOauthTokensTable } from '@ontask/core'

// ── Internal routes ───────────────────────────────────────────────────────────
// Private endpoints accessible only via Cloudflare Service Binding.
// NOT exposed in the public /v1/ API or OpenAPI schema.
// NO rate limiting (internal traffic only).
//
// Routes:
//   GET /internal/mcp-tokens/validate — validate MCP OAuth bearer token

const app = new Hono<{ Bindings: CloudflareBindings }>()

/**
 * Hashes a raw string with SHA-256 and returns the hex digest.
 * Uses the Web Crypto API available natively in Cloudflare Workers runtime.
 * DO NOT import any npm crypto packages.
 */
async function sha256Hex(raw: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(raw)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

// ── GET /internal/mcp-tokens/validate ────────────────────────────────────────
// Validates a raw MCP bearer token against the mcp_oauth_tokens table.
//
// Query params:
//   token — raw bearer token string (required)
//
// Behaviour:
//   - Hash the raw token with SHA-256 → look up by tokenHash
//   - If not found → 401 UNAUTHORIZED
//   - If revokedAt is set → 401 TOKEN_REVOKED
//   - If valid → update lastUsedAt = now(), return 200 { data: { userId, scopes } }

app.get('/internal/mcp-tokens/validate', async (c) => {
  const rawToken = c.req.query('token')

  if (!rawToken) {
    return c.json(
      { error: { code: 'UNAUTHORIZED', message: 'Token query parameter is required' } },
      401,
    )
  }

  const db = createDb(c.env.DATABASE_URL ?? '')
  const tokenHash = await sha256Hex(rawToken)

  const rows = await db
    .select()
    .from(mcpOauthTokensTable)
    .where(eq(mcpOauthTokensTable.tokenHash, tokenHash))
    .limit(1)

  const token = rows[0]

  if (!token) {
    return c.json(
      { error: { code: 'UNAUTHORIZED', message: 'Token not found' } },
      401,
    )
  }

  if (token.revokedAt !== null) {
    return c.json(
      { error: { code: 'TOKEN_REVOKED', message: 'Token has been revoked' } },
      401,
    )
  }

  // Update lastUsedAt as a side effect — fire and forget is acceptable here
  // since this is a tracking update and failure does not affect auth correctness.
  await db
    .update(mcpOauthTokensTable)
    .set({ lastUsedAt: new Date() })
    .where(eq(mcpOauthTokensTable.id, token.id))

  return c.json({
    data: {
      userId: token.userId,
      scopes: token.scopes,
    },
  })
})

export { app as internalRouter }
