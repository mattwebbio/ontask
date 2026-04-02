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


export function applyRateLimitHeaders(app: OpenAPIHono<{ Bindings: CloudflareBindings }>): void {
  app.use('*', async (c, next) => {
    // P1: Capture a single timestamp at the top of the middleware so that both
    // window-boundary calculations and retryAfter use the same instant.
    const nowSecs = Math.floor(Date.now() / 1000)
    const userId = c.req.header('x-user-id') ?? 'anonymous'
    const windowStart = Math.floor(nowSecs / WINDOW_SECS) * WINDOW_SECS
    const resetTs = windowStart + WINDOW_SECS

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
      // P2: Clamp retryAfter to at least 1 so it is never zero or negative.
      const retryAfter = Math.max(1, resetTs - nowSecs)
      return c.json(
        err('RATE_LIMIT_EXCEEDED', `Rate limit exceeded. Try again after ${retryAfter} seconds.`, {
          retryAfter,
        }),
        429,
        // P3: Emit Retry-After header for standards compliance (RFC 6585 §4).
        { 'Retry-After': String(retryAfter) },
      )
    }

    await next()

    // Inject headers after route handler runs
    c.res.headers.set('X-RateLimit-Limit', String(RATE_LIMIT))
    c.res.headers.set('X-RateLimit-Remaining', String(remaining))
    c.res.headers.set('X-RateLimit-Reset', String(resetTs))
  })
}
