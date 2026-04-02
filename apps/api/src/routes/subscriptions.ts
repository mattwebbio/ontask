import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok } from '../lib/response.js'

// ── Subscriptions router ──────────────────────────────────────────────────────
// Subscription lifecycle: trial, activation, management, payment failure.
// (Epic 9, FR49, FR82-90)
// DB integration deferred — TODO(impl) stubs only (Drizzle TS2345 incompatibility).

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schemas ───────────────────────────────────────────────────────────────────

const SubscriptionStatusSchema = z.object({
  status: z.enum(['trialing', 'active', 'cancelled', 'expired', 'grace_period']),
  trialStartedAt: z.string().datetime().nullable(),
  trialEndsAt: z.string().datetime().nullable(),
  trialDaysRemaining: z.number().int().min(0).nullable(),  // null when not trialing
  dataRetentionDeadline: z.string().datetime().nullable(), // populated after trial expires (FR85)
  stripeSubscriptionId: z.string().nullable(),
  currentPeriodEnd: z.string().datetime().nullable(),
})

const SubscriptionStatusResponseSchema = z.object({
  data: SubscriptionStatusSchema,
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── GET /v1/subscriptions/me ──────────────────────────────────────────────────

const getSubscriptionMeRoute = createRoute({
  method: 'get',
  path: '/v1/subscriptions/me',
  tags: ['Subscriptions'],
  summary: 'Get current user subscription status',
  description:
    'Returns the current subscription status for the authenticated user. ' +
    'During free trial: status=trialing, trialDaysRemaining is the days left (rounded down). ' +
    'trialDaysRemaining=0 means the trial expires today. ' +
    'After trial expiry without subscription: status=expired, dataRetentionDeadline is set (FR85). ' +
    'FR87: used to populate Settings → Subscription screen and trial countdown banner.',
  responses: {
    200: {
      content: { 'application/json': { schema: SubscriptionStatusResponseSchema } },
      description: 'Subscription status',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Unauthenticated',
    },
  },
})

app.openapi(getSubscriptionMeRoute, async (_c) => {
  // TODO(impl): const db = createDb(c.env.DATABASE_URL)
  // TODO(impl): const jwtUserId = c.get('jwtPayload').sub
  // TODO(impl): Query subscriptions WHERE userId = jwtUserId
  // TODO(impl): Calculate trialDaysRemaining = Math.max(0, Math.floor((trialEndsAt - NOW()) / 86400000))
  //   Set trialDaysRemaining = null when status !== 'trialing'
  const stubTrialEndsAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString()
  const stubTrialStartedAt = new Date().toISOString()
  return _c.json(
    ok({
      status: 'trialing' as const,
      trialStartedAt: stubTrialStartedAt,
      trialEndsAt: stubTrialEndsAt,
      trialDaysRemaining: 14,
      dataRetentionDeadline: null,
      stripeSubscriptionId: null,
      currentPeriodEnd: null,
    }),
    200,
  )
})

export const subscriptionsRouter = app
