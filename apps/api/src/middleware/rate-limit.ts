import type { OpenAPIHono } from '@hono/zod-openapi'
import { err } from '../lib/response.js'

// ── Rate limit enforcement middleware (FR80, NFR-I6) ──────────────────────────
// Per-user rate limiting: 1000 req/hr, enforced via in-memory counter.
// Real deployment uses Cloudflare KV for persistence (env.RATE_LIMIT_KV).
// In test/local environments where KV is unavailable, falls back to in-memory Map.
//
// User identity: x-user-id header (consistent with all stub routes until real JWT auth lands).
// Rate limit: 1000 requests per 1-hour window (resets at top of each hour).

const RATE_LIMIT = 1000
const WINDOW_SECS = 3600 // 1 hour

// In-memory fallback counter (test + local environments)
const memoryCounters = new Map<string, { count: number; windowStart: number }>()

function getWindowStart(): number {
  // Top of the current hour (Unix seconds)
  return Math.floor(Date.now() / 1000 / WINDOW_SECS) * WINDOW_SECS
}

function getResetTimestamp(): number {
  return getWindowStart() + WINDOW_SECS
}

export function applyRateLimitHeaders(app: OpenAPIHono<{ Bindings: CloudflareBindings }>): void {
  app.use('*', async (c, next) => {
    const userId = c.req.header('x-user-id') ?? 'anonymous'
    const windowStart = getWindowStart()
    const resetTs = getResetTimestamp()

    // In-memory counter (stub — no KV available in tests)
    let entry = memoryCounters.get(userId)
    if (!entry || entry.windowStart !== windowStart) {
      entry = { count: 0, windowStart }
      memoryCounters.set(userId, entry)
    }
    entry.count++

    const remaining = Math.max(0, RATE_LIMIT - entry.count)
    const isExceeded = entry.count > RATE_LIMIT

    if (isExceeded) {
      const retryAfter = resetTs - Math.floor(Date.now() / 1000)
      return c.json(
        err('RATE_LIMIT_EXCEEDED', `Rate limit exceeded. Try again after ${retryAfter} seconds.`, {
          retryAfter,
        }),
        429,
      )
    }

    await next()

    // Inject headers after route handler runs
    c.res.headers.set('X-RateLimit-Limit', String(RATE_LIMIT))
    c.res.headers.set('X-RateLimit-Remaining', String(remaining))
    c.res.headers.set('X-RateLimit-Reset', String(resetTs))
  })
}
