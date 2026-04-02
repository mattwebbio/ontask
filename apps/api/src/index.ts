import { OpenAPIHono } from '@hono/zod-openapi'
import { applyScopedCors } from './middleware/cors.js'
import { applyRateLimitHeaders } from './middleware/rate-limit.js'
import { healthRouter } from './routes/health.js'
import { authRouter } from './routes/auth.js'
import { usersRouter } from './routes/users.js'
import { tasksRouter } from './routes/tasks.js'
import { listsRouter } from './routes/lists.js'
import { sectionsRouter } from './routes/sections.js'
import { templatesRouter } from './routes/templates.js'
import { taskDependenciesRouter } from './routes/task-dependencies.js'
import { bulkOperationsRouter } from './routes/bulk-operations.js'
import { schedulingRouter } from './routes/scheduling.js'
import { calendarRouter } from './routes/calendar.js'
import { sharingRouter } from './routes/sharing.js'
import { commitmentContractsRouter } from './routes/commitment-contracts.js'
import { proofRouter } from './routes/proof.js'
import { notificationsRouter } from './routes/notifications.js'
import { subscriptionsRouter } from './routes/subscriptions.js'
import { chargeTriggerConsumer } from './queues/charge-trigger-consumer.js'
import { everyOrgConsumer } from './queues/every-org-consumer.js'
import { triggerOverdueCharges } from './lib/charge-scheduler.js'
import { triggerReminderNotifications, triggerDeadlineNotifications, triggerStakeWarningNotifications } from './lib/notification-scheduler.js'
import { AppError } from './lib/errors.js'
import { reportToGlitchTip } from './lib/glitchtip.js'
import { err } from './lib/response.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Global error handler ───────────────────────────────────────────────────
// Must be registered before routes so Hono wires it up correctly.
// Catches AppError subclasses and maps them to the standard error envelope.
// All other errors become 500 INTERNAL_SERVER_ERROR.
// Non-AppError (unexpected) errors are reported to GlitchTip (AC #2, ARCH-31).
app.onError((error, c) => {
  if (error instanceof AppError) {
    return c.json(err(error.code, error.message, error.details), error.httpStatus as 400)
  }
  // Report unexpected errors to GlitchTip — AppError subclasses are NOT forwarded.
  // c.env may be undefined in test environments (no env passed to app.request).
  void reportToGlitchTip(
    error,
    {
      workerName: 'ontask-api',
      environment: c.env?.ENVIRONMENT ?? 'production',
      path: new URL(c.req.url).pathname,
      method: c.req.method,
    },
    c.env
  )
  return c.json(err('INTERNAL_SERVER_ERROR', 'An unexpected error occurred'), 500)
})

// ── Scoped CORS (admin SPA + payment setup only — NOT global) ──────────────
// IMPORTANT: applyScopedCors() MUST be called before routes are mounted.
// Hono matches middleware in registration order — if routes are mounted first,
// OPTIONS preflight requests will be handled by the route (returning 404/405)
// before CORS middleware runs, and browsers will silently block cross-origin
// requests with no useful error message.
applyScopedCors(app)

// ── Rate limit headers (Story 10.1 — FR80, NFR-I6) ────────────────────────
applyRateLimitHeaders(app)

// ── Routes ─────────────────────────────────────────────────────────────────
app.route('/', healthRouter)
app.route('/', authRouter)
app.route('/', usersRouter)
// IMPORTANT: bulkOperationsRouter MUST be registered BEFORE tasksRouter.
// Hono matches routes in registration order — /v1/tasks/bulk/complete would
// otherwise match /v1/tasks/{id}/complete with id='bulk'.
app.route('/', bulkOperationsRouter)
app.route('/', tasksRouter)
app.route('/', listsRouter)
app.route('/', sectionsRouter)
app.route('/', templatesRouter)
app.route('/', taskDependenciesRouter)
app.route('/', schedulingRouter)
app.route('/', calendarRouter)
app.route('/', sharingRouter)
app.route('/', commitmentContractsRouter)
app.route('/', proofRouter)
app.route('/', notificationsRouter)
app.route('/', subscriptionsRouter)

// ── OpenAPI documentation ──────────────────────────────────────────────────
app.doc('/v1/doc', {
  openapi: '3.0.0',
  info: {
    title: 'OnTask API',
    version: '1.0.0',
    description: 'OnTask REST API — task management platform',
  },
})

// Alias: OpenAPI spec at /v1/openapi.json (Story 10.1 — FR44)
// The canonical doc endpoint /v1/doc remains unchanged.
app.doc('/v1/openapi.json', {
  openapi: '3.0.0',
  info: {
    title: 'OnTask API',
    version: '1.0.0',
    description: 'OnTask REST API — task management platform',
  },
})

// ── Default export (HTTP fetch handler + test compatibility) ─────────────────
// Keeps `export default app` so existing tests (which import the default and
// call `.request()`) continue to work unchanged. Cloudflare Workers also
// supports picking up the `queue` and `scheduled` named exports below
// alongside the default `fetch` export. This is a non-breaking change.
export default app

// ── Queue consumer export (Story 6.5) ────────────────────────────────────────
// Cloudflare Workers named queue export. Routes batch messages to the correct
// consumer based on queue name (charge-trigger-queue or every-org-queue).
export async function queue(
  batch: MessageBatch<unknown>,
  env: CloudflareBindings,
  ctx: ExecutionContext
): Promise<void> {
  if (batch.queue === 'charge-trigger-queue') {
    await chargeTriggerConsumer(batch, env, ctx)
  } else if (batch.queue === 'every-org-queue') {
    await everyOrgConsumer(batch, env, ctx)
  } else {
    console.warn(`Unknown queue: ${batch.queue}`)
  }
}

// ── Scheduled handler export (Story 6.5) ─────────────────────────────────────
// Cloudflare Workers named scheduled export. Runs every 5 minutes
// (cron: */5 * * * *) to find overdue staked tasks and enqueue CHARGE_TRIGGER
// messages.
export async function scheduled(
  _event: ScheduledEvent,
  env: CloudflareBindings,
  ctx: ExecutionContext
): Promise<void> {
  ctx.waitUntil(triggerOverdueCharges(env))
  ctx.waitUntil(triggerReminderNotifications(env))
  ctx.waitUntil(triggerDeadlineNotifications(env))
  ctx.waitUntil(triggerStakeWarningNotifications(env))
}
