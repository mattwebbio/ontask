import { Hono } from 'hono'
import { eq, and, isNull } from 'drizzle-orm'
import { createDb } from '../db/index.js'
import { mcpOauthTokensTable } from '@ontask/core'

// ── MCP Token management routes (FR93, Story 10.4) ───────────────────────────
// Endpoints for issuing, listing, and revoking per-client MCP OAuth tokens.
// Exposed under /v1/mcp-tokens.
//
// Auth: x-user-id stub header (consistent with all other API routes).
// Real JWT auth is a separate story.
//
// Token security:
//   - Raw tokens are NEVER stored — only SHA-256 hash is persisted.
//   - Raw token is returned ONCE at issuance and never again.
//   - SHA-256 uses Web Crypto API (no npm crypto packages).

const app = new Hono<{ Bindings: CloudflareBindings }>()

// Valid MCP scope strings (canonical list — enforced at issuance)
const VALID_SCOPES = ['tasks:read', 'tasks:write', 'contracts:read', 'contracts:write'] as const
type McpScope = (typeof VALID_SCOPES)[number]

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

/**
 * Generates a cryptographically secure random token string.
 * Uses Web Crypto API — no npm packages needed.
 */
function generateSecureToken(): string {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

// ── POST /v1/mcp-tokens ───────────────────────────────────────────────────────
// Issue a new MCP OAuth token for the authenticated user.
//
// Request body: { clientName: string, scopes: string[] }
// Response: { data: { id, clientName, scopes, token, createdAt } }
//   Note: `token` is the raw bearer token — shown ONCE and never again.

app.post('/v1/mcp-tokens', async (c) => {
  const userId = c.req.header('x-user-id')
  if (!userId) {
    return c.json(
      { error: { code: 'UNAUTHORIZED', message: 'x-user-id header is required' } },
      401,
    )
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let body: any
  try {
    body = await c.req.json()
  } catch {
    return c.json(
      { error: { code: 'INVALID_JSON', message: 'Request body must be valid JSON' } },
      400,
    )
  }

  const { clientName, scopes } = body as { clientName?: unknown; scopes?: unknown }

  // Validate clientName
  if (!clientName || typeof clientName !== 'string' || clientName.trim() === '') {
    return c.json(
      { error: { code: 'VALIDATION_ERROR', message: 'clientName is required' } },
      400,
    )
  }
  if (clientName.length > 100) {
    return c.json(
      { error: { code: 'VALIDATION_ERROR', message: 'clientName must be 100 characters or fewer' } },
      400,
    )
  }

  // Validate scopes
  if (!Array.isArray(scopes) || scopes.length === 0) {
    return c.json(
      { error: { code: 'VALIDATION_ERROR', message: 'scopes must be a non-empty array' } },
      400,
    )
  }

  const invalidScopes = scopes.filter(
    (s) => !VALID_SCOPES.includes(s as McpScope),
  )
  if (invalidScopes.length > 0) {
    return c.json(
      {
        error: {
          code: 'VALIDATION_ERROR',
          message: `Invalid scopes: ${invalidScopes.join(', ')}. Valid scopes: ${VALID_SCOPES.join(', ')}`,
        },
      },
      400,
    )
  }

  const rawToken = generateSecureToken()
  const tokenHash = await sha256Hex(rawToken)

  const db = createDb(c.env.DATABASE_URL ?? '')

  const inserted = await db
    .insert(mcpOauthTokensTable)
    .values({
      userId,
      clientName: clientName.trim(),
      tokenHash,
      scopes: scopes as string[],
    })
    .returning({
      id: mcpOauthTokensTable.id,
      clientName: mcpOauthTokensTable.clientName,
      scopes: mcpOauthTokensTable.scopes,
      createdAt: mcpOauthTokensTable.createdAt,
    })

  const record = inserted[0]

  return c.json(
    {
      data: {
        id: record.id,
        clientName: record.clientName,
        scopes: record.scopes,
        token: rawToken,
        createdAt: record.createdAt,
      },
    },
    201,
  )
})

// ── GET /v1/mcp-tokens ────────────────────────────────────────────────────────
// List all active (non-revoked) tokens for the authenticated user.
//
// Response: { data: [{ id, clientName, scopes, lastUsedAt, createdAt }] }
// Note: tokenHash is NEVER returned.

app.get('/v1/mcp-tokens', async (c) => {
  const userId = c.req.header('x-user-id')
  if (!userId) {
    return c.json(
      { error: { code: 'UNAUTHORIZED', message: 'x-user-id header is required' } },
      401,
    )
  }

  const db = createDb(c.env.DATABASE_URL ?? '')

  const tokens = await db
    .select({
      id: mcpOauthTokensTable.id,
      clientName: mcpOauthTokensTable.clientName,
      scopes: mcpOauthTokensTable.scopes,
      lastUsedAt: mcpOauthTokensTable.lastUsedAt,
      createdAt: mcpOauthTokensTable.createdAt,
    })
    .from(mcpOauthTokensTable)
    .where(
      and(
        eq(mcpOauthTokensTable.userId, userId),
        isNull(mcpOauthTokensTable.revokedAt),
      ),
    )

  return c.json({ data: tokens })
})

// ── DELETE /v1/mcp-tokens/:id ─────────────────────────────────────────────────
// Revoke a specific token. Sets revokedAt = now().
// Verifies ownership — returns 404 if token not found or not owned by user.
//
// Response: 204 No Content on success.

app.delete('/v1/mcp-tokens/:id', async (c) => {
  const userId = c.req.header('x-user-id')
  if (!userId) {
    return c.json(
      { error: { code: 'UNAUTHORIZED', message: 'x-user-id header is required' } },
      401,
    )
  }

  const tokenId = c.req.param('id')
  const db = createDb(c.env.DATABASE_URL ?? '')

  // Verify ownership before revoking
  const existing = await db
    .select({ id: mcpOauthTokensTable.id })
    .from(mcpOauthTokensTable)
    .where(
      and(
        eq(mcpOauthTokensTable.id, tokenId),
        eq(mcpOauthTokensTable.userId, userId),
      ),
    )
    .limit(1)

  if (existing.length === 0) {
    return c.json(
      { error: { code: 'NOT_FOUND', message: 'Token not found' } },
      404,
    )
  }

  await db
    .update(mcpOauthTokensTable)
    .set({ revokedAt: new Date() })
    .where(and(eq(mcpOauthTokensTable.id, tokenId), eq(mcpOauthTokensTable.userId, userId)))

  return new Response(null, { status: 204 })
})

export { app as mcpTokensRouter }
