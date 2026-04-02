import type { OpenAPIHono } from '@hono/zod-openapi'

// ── Rate limit header middleware (FR80, NFR-I6) ────────────────────────────
// Injects X-RateLimit-* headers on every response for Story 10.1.
// Actual enforcement (429 responses, per-user counters) comes in Story 10.2.
//
// Stub values: 1000 req/hr limit, resets at top of next hour.

export function applyRateLimitHeaders(app: OpenAPIHono<{ Bindings: CloudflareBindings }>): void {
  app.use('*', async (c, next) => {
    await next()
    // Stub: fixed values until real counters land in Story 10.2
    const resetUnixSec = Math.ceil(Date.now() / 3_600_000) * 3_600 // top of next hour (Unix seconds)
    c.res.headers.set('X-RateLimit-Limit', '1000')
    c.res.headers.set('X-RateLimit-Remaining', '1000') // stub: no real counter yet (Story 10.2)
    c.res.headers.set('X-RateLimit-Reset', String(resetUnixSec))
  })
}
