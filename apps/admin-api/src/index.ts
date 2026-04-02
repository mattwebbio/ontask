import { OpenAPIHono } from '@hono/zod-openapi'
import { adminCors } from './middleware/cors.js'
import { adminAuthMiddleware } from './middleware/admin-auth.js'
import { authRouter } from './routes/auth.js'
import { disputesRouter } from './routes/disputes.js'
import { chargesRouter } from './routes/charges.js'

// ── Admin API — Operator Hono Worker ─────────────────────────────────────────
// Routes: api.ontaskhq.com/admin/v1/*
// Separate Cloudflare Worker from apps/api (user-facing).
// Auth middleware and CORS added in Story 11.1.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings; Variables: { operatorEmail: string } }>()

// CORS — scoped to /admin/v1/* only (never global)
app.use('/admin/v1/*', adminCors)

// Auth route — unauthenticated (login endpoint)
app.route('/', authRouter)

// All other admin routes require authentication
app.use('/admin/v1/disputes/*', adminAuthMiddleware)
app.use('/admin/v1/disputes', adminAuthMiddleware)
app.use('/admin/v1/users/*', adminAuthMiddleware)
app.use('/admin/v1/charges/*', adminAuthMiddleware)

app.route('/', disputesRouter)
app.route('/', chargesRouter)

export default app
