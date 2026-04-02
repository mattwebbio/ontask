import { Hono } from 'hono'
import { and, eq, isNull } from 'drizzle-orm'
import { createDb } from '../db/index.js'
import { liveActivityTokensTable, mcpOauthTokensTable } from '@ontask/core'
import { sendLiveActivityUpdate, type LiveActivityContentState } from '../services/live-activity.js'

// ── Internal routes ───────────────────────────────────────────────────────────
// Private endpoints accessible only via Cloudflare Service Binding.
// NOT exposed in the public /v1/ API or OpenAPI schema.
// NO rate limiting (internal traffic only).
//
// Routes:
//   GET  /internal/mcp-tokens/validate       — validate MCP OAuth bearer token
//   POST /internal/live-activities/update    — send ActivityKit server push update

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

// ── POST /internal/live-activities/update ────────────────────────────────────
// Triggers an ActivityKit server push for a live activity token.
// Used by cron functions, charge consumer, and proof route to update the
// Dynamic Island in real time.
//
// Request body:
//   userId       — UUID of the user who owns the activity
//   taskId       — UUID or null (null = watch_mode without an associated task)
//   activityType — 'task_timer' | 'commitment_countdown' | 'watch_mode'
//   event        — 'update' | 'end'
//   contentState — ActivityKit ContentState fields (no elapsedSeconds — client-driven)
//   dismissalDate — optional Unix timestamp (seconds) — deadline for countdown activities
//
// Behaviour:
//   - Look up live_activity_tokens WHERE userId + taskId + activityType
//   - If no row → 200 { sent: false, reason: 'no_token' }   (activity ended client-side — not an error)
//   - If expiresAt is in the past → 200 { sent: false, reason: 'token_expired' } + delete row
//   - Call sendLiveActivityUpdate via APNs
//   - If APNs 410 → delete row, return 200 { sent: false, reason: 'token_expired' }
//   - Success → 200 { sent: true }

app.post('/internal/live-activities/update', async (c) => {
  let body: {
    userId: string
    taskId: string | null
    activityType: string
    event: 'update' | 'end'
    contentState: LiveActivityContentState
    dismissalDate?: number
  }

  try {
    body = await c.req.json()
  } catch {
    return c.json({ error: { code: 'BAD_REQUEST', message: 'Invalid JSON body' } }, 400)
  }

  // Validate required fields
  if (
    typeof body.userId !== 'string' ||
    !body.userId ||
    !('taskId' in body) ||
    typeof body.activityType !== 'string' ||
    !body.activityType ||
    (body.event !== 'update' && body.event !== 'end') ||
    typeof body.contentState !== 'object' ||
    body.contentState === null ||
    typeof body.contentState.taskTitle !== 'string' ||
    !body.contentState.taskTitle ||
    typeof body.contentState.activityStatus !== 'string'
  ) {
    return c.json({ error: { code: 'BAD_REQUEST', message: 'Missing or invalid required fields' } }, 400)
  }

  const db = createDb(c.env.DATABASE_URL ?? '')

  // Look up the token — taskId may be null (watch_mode without associated task)
  const whereClause = body.taskId === null
    ? and(
        eq(liveActivityTokensTable.userId, body.userId),
        isNull(liveActivityTokensTable.taskId),
        eq(liveActivityTokensTable.activityType, body.activityType),
      )
    : and(
        eq(liveActivityTokensTable.userId, body.userId),
        eq(liveActivityTokensTable.taskId, body.taskId),
        eq(liveActivityTokensTable.activityType, body.activityType),
      )

  const rows = await db
    .select()
    .from(liveActivityTokensTable)
    .where(whereClause)
    .limit(1)

  if (rows.length === 0) {
    // Activity may have already ended client-side — not an error
    return c.json({ data: { sent: false, reason: 'no_token' } })
  }

  const token = rows[0]

  // Check if token has already expired locally before calling APNs
  if (token.expiresAt < new Date()) {
    await db
      .delete(liveActivityTokensTable)
      .where(eq(liveActivityTokensTable.id, token.id))
    return c.json({ data: { sent: false, reason: 'token_expired' } })
  }

  // Send the ActivityKit push via APNs
  const result = await sendLiveActivityUpdate(
    {
      pushToken: token.pushToken,
      expiresAt: token.expiresAt,
      event: body.event,
      contentState: body.contentState,
      dismissalDate: body.dismissalDate,
    },
    c.env
  )

  // If APNs returned 410 (Unregistered), delete the stale token row
  if (result.tokenExpired) {
    await db
      .delete(liveActivityTokensTable)
      .where(eq(liveActivityTokensTable.id, token.id))
    return c.json({ data: { sent: false, reason: 'token_expired' } })
  }

  return c.json({ data: { sent: true } })
})

export { app as internalRouter }
