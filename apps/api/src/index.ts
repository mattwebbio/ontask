import { OpenAPIHono } from '@hono/zod-openapi'
import { applyScopedCors } from './middleware/cors.js'
import { healthRouter } from './routes/health.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Scoped CORS (admin SPA + payment setup only — NOT global) ──────────────
applyScopedCors(app)

// ── Routes ─────────────────────────────────────────────────────────────────
app.route('/', healthRouter)

// ── OpenAPI documentation ──────────────────────────────────────────────────
app.doc('/v1/doc', {
  openapi: '3.0.0',
  info: {
    title: 'OnTask API',
    version: '1.0.0',
    description: 'OnTask REST API — task management platform',
  },
})

export default app
