import { cors } from 'hono/cors'

// ── Admin CORS middleware ─────────────────────────────────────────────────────
// Scoped to /admin/v1/* routes only — NOT global.
// Applied via app.use('/admin/v1/*', adminCors) in index.ts.
// [Source: architecture.md lines 333–338]

export const adminCors = cors({
  origin: ['https://admin.ontaskhq.com', 'https://admin.staging.ontaskhq.com'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
})
