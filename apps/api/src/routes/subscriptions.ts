import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'
import { verifyWebhookSignature } from '../services/stripe.js'
import { sendPush } from '../services/push.js'

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

// ── GET /v1/subscriptions/paywall-config ─────────────────────────────────────

const TierSchema = z.object({
  tier: z.enum(['individual', 'couple', 'family_and_friends']),
  displayName: z.string(),
  priceDisplay: z.string(),       // e.g. "~$10 / month" — localised display string
  stripePriceId: z.string().nullable(), // null until Story 9.3 wires real Price IDs
  available: z.boolean(),         // false = "coming soon" (couple, family for now)
})

const PaywallConfigResponseSchema = z.object({
  data: z.object({
    tiers: z.array(TierSchema),
  }),
})

const getPaywallConfigRoute = createRoute({
  method: 'get',
  path: '/v1/subscriptions/paywall-config',
  tags: ['Subscriptions'],
  summary: 'Get paywall tier configuration',
  description:
    'Returns tier display configuration for the paywall screen. ' +
    'stripePriceId is null until Story 9.3 wires real Stripe Price IDs. ' +
    'available=false means the tier is shown as "coming soon". ' +
    'FR88, FR83: used to populate PaywallScreen tier cards.',
  responses: {
    200: {
      content: { 'application/json': { schema: PaywallConfigResponseSchema } },
      description: 'Paywall tier configuration',
    },
  },
})

app.openapi(getPaywallConfigRoute, async (_c) => {
  // TODO(impl): In future, fetch dynamic pricing from Stripe or config store.
  // For now: static stub — exact prices TBD at launch per product brief (~$10/mo Individual).
  return _c.json(
    ok({
      tiers: [
        {
          tier: 'individual' as const,
          displayName: 'Individual',
          priceDisplay: '~$10 / month',
          stripePriceId: null,
          available: true,
        },
        {
          tier: 'couple' as const,
          displayName: 'Couple',
          priceDisplay: 'Coming soon',
          stripePriceId: null,
          available: false,
        },
        {
          tier: 'family_and_friends' as const,
          displayName: 'Family & Friends',
          priceDisplay: 'Coming soon',
          stripePriceId: null,
          available: false,
        },
      ],
    }),
    200,
  )
})

// ── POST /v1/subscriptions/activate ──────────────────────────────────────────

const ActivateSubscriptionRequestSchema = z.object({
  sessionId: z.string(), // Stripe Checkout session_id from Universal Link callback
})

const ActivateSubscriptionResponseSchema = z.object({
  data: z.object({
    status: z.enum(['trialing', 'active', 'cancelled', 'expired', 'grace_period']),
    stripeSubscriptionId: z.string().nullable(),
    currentPeriodEnd: z.string().datetime().nullable(),
  }),
})

const activateSubscriptionRoute = createRoute({
  method: 'post',
  path: '/v1/subscriptions/activate',
  tags: ['Subscriptions'],
  summary: 'Activate subscription from Stripe Checkout session',
  description:
    'Called when the app receives the Universal Link callback from Stripe Checkout. ' +
    'Validates the session_id against Stripe and activates the subscription server-side. ' +
    'FR83: returns updated subscription status so client can update immediately. ' +
    'Story 9.3 stub — TODO(impl): validate session with Stripe API, update DB.',
  request: {
    body: {
      content: { 'application/json': { schema: ActivateSubscriptionRequestSchema } },
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ActivateSubscriptionResponseSchema } },
      description: 'Subscription activated',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid session_id',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Unauthenticated',
    },
  },
})

app.openapi(activateSubscriptionRoute, async (_c) => {
  // TODO(impl): const db = createDb(c.env.DATABASE_URL)
  // TODO(impl): const jwtUserId = c.get('jwtPayload').sub
  // TODO(impl): validate _c.req.valid('json').sessionId against Stripe
  // TODO(impl): update subscription record in DB — set status='active', store stripeSubscriptionId, currentPeriodEnd
  // TODO(impl): emit 'subscription_activated' analytics event (NFR-B1)
  // Stub: return active status for testing the client flow.
  const stubCurrentPeriodEnd = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
  return _c.json(
    ok({
      status: 'active' as const,
      stripeSubscriptionId: 'stub_sub_id',
      currentPeriodEnd: stubCurrentPeriodEnd,
    }),
    200,
  )
})

// ── POST /v1/subscriptions/restore ───────────────────────────────────────────

const restoreSubscriptionRoute = createRoute({
  method: 'post',
  path: '/v1/subscriptions/restore',
  tags: ['Subscriptions'],
  summary: 'Restore a previously purchased subscription',
  description:
    'Attempts to restore a subscription by looking up existing Stripe subscriptions for the user. ' +
    'Story 9.3 stub — TODO(impl): query Stripe for existing subscriptions by customer ID.',
  responses: {
    200: {
      content: { 'application/json': { schema: ActivateSubscriptionResponseSchema } },
      description: 'Subscription restored or already active',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'No subscription found to restore',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Unauthenticated',
    },
  },
})

app.openapi(restoreSubscriptionRoute, async (_c) => {
  // TODO(impl): query Stripe for subscriptions by customer ID
  // Stub: return active for testing restore flow
  const stubCurrentPeriodEnd = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
  return _c.json(
    ok({
      status: 'active' as const,
      stripeSubscriptionId: 'stub_sub_id',
      currentPeriodEnd: stubCurrentPeriodEnd,
    }),
    200,
  )
})

// ── POST /v1/subscriptions/cancel ─────────────────────────────────────────────

const cancelSubscriptionRoute = createRoute({
  method: 'post',
  path: '/v1/subscriptions/cancel',
  tags: ['Subscriptions'],
  summary: 'Cancel subscription at end of current billing period',
  description:
    'Cancels the subscription — access continues until currentPeriodEnd (FR49, FR89). ' +
    'Active commitment contracts are unaffected by cancellation. ' +
    'Story 9.4 stub — TODO(impl): call Stripe cancel_at_period_end, update DB status to cancelled.',
  responses: {
    200: {
      content: { 'application/json': { schema: ActivateSubscriptionResponseSchema } },
      description: 'Subscription cancelled (access continues until period end)',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Unauthenticated',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'No active subscription found',
    },
  },
})

app.openapi(cancelSubscriptionRoute, async (_c) => {
  // TODO(impl): const db = createDb(c.env.DATABASE_URL)
  // TODO(impl): const jwtUserId = c.get('jwtPayload').sub
  // TODO(impl): call Stripe API — stripe.subscriptions.update(subId, { cancel_at_period_end: true })
  // TODO(impl): update subscription record in DB — set status='cancelled', preserve currentPeriodEnd
  // TODO(impl): emit 'subscription_cancelled' analytics event (NFR-B1)
  // Stub: return cancelled status with a future access-until date for testing the client flow.
  const stubCurrentPeriodEnd = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
  return _c.json(
    ok({
      status: 'cancelled' as const,
      stripeSubscriptionId: 'stub_sub_id',
      currentPeriodEnd: stubCurrentPeriodEnd,
    }),
    200,
  )
})

// ── POST /v1/subscriptions/webhook/stripe ────────────────────────────────────

const StripeWebhookRequestSchema = z.object({
  type: z.string(),    // e.g. 'invoice.payment_failed', 'invoice.payment_succeeded'
  data: z.object({
    object: z.record(z.string(), z.unknown()),
  }),
})

const StripeWebhookResponseSchema = z.object({
  data: z.object({
    received: z.boolean(),
  }),
})

const stripeWebhookRoute = createRoute({
  method: 'post',
  path: '/v1/subscriptions/webhook/stripe',
  tags: ['Subscriptions'],
  summary: 'Stripe webhook receiver for subscription events',
  description:
    'Receives Stripe webhook events for subscription lifecycle management. ' +
    'Handles invoice.payment_failed (begin grace period, send push notification, FR90). ' +
    'Handles invoice.payment_succeeded (end grace period, restore active status). ' +
    'Story 9.5 stub — TODO(impl): verify Stripe webhook signature, process event type, ' +
    'update DB subscription status, send APNs push via services/push.ts.',
  request: {
    body: {
      content: { 'application/json': { schema: StripeWebhookRequestSchema } },
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: StripeWebhookResponseSchema } },
      description: 'Webhook received',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid webhook payload or signature',
    },
  },
})

app.openapi(stripeWebhookRoute, async (_c) => {
  // TODO(impl): const rawBody = await _c.req.text() — MUST be raw, unparsed body
  // TODO(impl): const sig = _c.req.header('stripe-signature') ?? ''
  // TODO(impl): const valid = verifyWebhookSignature(rawBody, sig, _c.env)
  // TODO(impl): if (!valid) return _c.json(err('INVALID_SIGNATURE', '...'), 400)
  // TODO(impl): const event = _c.req.valid('json')
  // TODO(impl): if (event.type === 'invoice.payment_failed') {
  //   TODO(impl): update subscription status to 'grace_period' in DB
  //   TODO(impl): set grace period expiry = now + 7 days
  //   TODO(impl): call sendPush() from services/push.ts with FR90 message:
  //     title: "Payment failed", body: "Your payment didn't go through — update your payment method to keep access"
  // TODO(impl): } else if (event.type === 'invoice.payment_succeeded') {
  //   TODO(impl): update subscription status back to 'active'
  //   TODO(impl): clear grace period state
  // TODO(impl): }
  // TODO(impl): emit 'payment_failed' analytics event (NFR-B1)
  // Stub: acknowledge receipt unconditionally.
  return _c.json(ok({ received: true }), 200)
})

export const subscriptionsRouter = app
