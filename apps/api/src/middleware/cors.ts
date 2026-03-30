import { cors } from 'hono/cors'
import type { OpenAPIHono } from '@hono/zod-openapi'

/**
 * Scoped CORS middleware.
 *
 * IMPORTANT: CORS is NOT applied globally.
 *
 * `/v1/*` routes have NO CORS middleware — the Flutter mobile client is a native
 * HTTP client and does not require CORS headers.
 *
 * CORS is applied ONLY to:
 *   - `/admin/v1/*` — browser-based admin SPA at admin.ontaskhq.com
 *   - Payment setup endpoints — web-based payment flow
 *
 * Do NOT change this to global CORS — it expands attack surface unnecessarily.
 */

/** CORS options for the admin SPA origin. */
const adminCorsOptions = {
  origin: 'https://admin.ontaskhq.com',
  allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  maxAge: 600,
  credentials: true,
}

/** CORS options for web-based payment setup flow. */
const paymentCorsOptions = {
  origin: ['https://ontaskhq.com', 'https://www.ontaskhq.com'],
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  maxAge: 600,
  credentials: true,
}

/**
 * Registers scoped CORS middleware on the given OpenAPIHono app instance.
 *
 * ORDERING REQUIREMENT: This function MUST be called BEFORE any routes are mounted.
 * Hono processes middleware in registration order. If routes are mounted first,
 * OPTIONS preflight requests will be matched by the route handler (returning 404/405)
 * before CORS middleware has a chance to run. The result is that browsers will
 * silently block all cross-origin requests — no console error, just a failed fetch.
 *
 * Correct order in index.ts:
 *   1. applyScopedCors(app)   ← middleware first
 *   2. app.route(...)         ← then routes
 */
export function applyScopedCors<T extends OpenAPIHono<{ Bindings: CloudflareBindings }>>(
  app: T
): void {
  // Admin SPA routes — browser client needs CORS
  app.use('/admin/v1/*', cors(adminCorsOptions))

  // Payment setup endpoint — web-based payment flow needs CORS
  app.use('/v1/payment-setup/*', cors(paymentCorsOptions))
}
