import { OpenAPIHono } from '@hono/zod-openapi'
import { disputesRouter } from './routes/disputes.js'

// ── Admin API — Operator Hono Worker ─────────────────────────────────────────
// Routes: api.ontaskhq.com/admin/v1/*
// Separate Cloudflare Worker from apps/api (user-facing).
// Auth middleware (Story 11.1) and CORS (Story 11.1) added in future stories.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

app.route('/', disputesRouter)

export default app
