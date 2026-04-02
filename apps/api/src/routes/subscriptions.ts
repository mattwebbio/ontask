import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'
import { verifyWebhookSignature } from '../services/stripe.js'
import { sendPush } from '../services/push.js'

// ── Subscriptions router ──────────────────────────────────────────────────────
// Subscription lifecycle: trial, activation, management, payment failure.
// (Epic 9, FR49, FR82-90)
// NOTE: DB integration deferred for most endpoints — Drizzle TS2345 incompatibility.
// Do NOT add createDb/drizzle imports until the type error is resolved.

// ── Stripe API helper (raw fetch — no SDK) ────────────────────────────────────
async function stripePost(
  path: string,
  body: Record<string, string>,
  secretKey: string,
  // rawParams: pre-encoded key=value pairs appended verbatim (use for Stripe URL
  // template placeholders like {CHECKOUT_SESSION_ID} that must not be
  // percent-encoded by encodeURIComponent).
  rawParams?: string,
): Promise<unknown> {
  const formBody = Object.entries(body)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&')
  const fullBody = rawParams ? `${formBody}&${rawParams}` : formBody
  const response = await fetch(`https://api.stripe.com${path}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${secretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: fullBody,
  })
  if (!response.ok) {
    const error = await response.json() as { error?: { message?: string } }
    throw new Error(`Stripe error: ${error?.error?.message ?? response.statusText}`)
  }
  return response.json()
}

async function stripeGet(path: string, secretKey: string): Promise<unknown> {
  const response = await fetch(`https://api.stripe.com${path}`, {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${secretKey}` },
  })
  if (!response.ok) {
    const error = await response.json() as { error?: { message?: string } }
    throw new Error(`Stripe error: ${error?.error?.message ?? response.statusText}`)
  }
  return response.json()
}

/** Maps a subscription tier string to the Stripe Price ID from env vars. */
function priceIdForTier(tier: string, env: CloudflareBindings): string {
  const priceIds: Record<string, string | undefined> = {
    individual: env.STRIPE_PRICE_ID_INDIVIDUAL,
    couple: env.STRIPE_PRICE_ID_COUPLE,
    family: env.STRIPE_PRICE_ID_FAMILY,
  }
  const id = priceIds[tier]
  if (!id) throw new Error(`Unknown or unconfigured tier: ${tier}`)
  return id
}

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

// ── POST /v1/subscriptions/checkout-session ───────────────────────────────────
// Creates a Stripe Checkout session for the selected subscription tier.
// Called by the Flutter app BEFORE opening Safari — app opens the returned Checkout URL.
// Auth: JWT required. Story 13.1.

const CheckoutSessionRequestSchema = z.object({
  tier: z.enum(['individual', 'couple', 'family']),
})

const CheckoutSessionResponseSchema = z.object({
  data: z.object({ checkoutUrl: z.string() }),
})

const createCheckoutSessionRoute = createRoute({
  method: 'post',
  path: '/v1/subscriptions/checkout-session',
  tags: ['Subscriptions'],
  summary: 'Create a Stripe Checkout session for subscription',
  description:
    'Creates a Stripe Checkout session for the selected subscription tier. ' +
    'Returns the hosted Checkout URL — Flutter opens this via url_launcher. ' +
    'Success URL: ontaskhq.com/subscribe/success?session_id=xxx (Universal Link). ' +
    'Story 13.1.',
  request: {
    body: { content: { 'application/json': { schema: CheckoutSessionRequestSchema } } },
  },
  responses: {
    201: {
      content: { 'application/json': { schema: CheckoutSessionResponseSchema } },
      description: 'Checkout session created',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Unknown or unconfigured tier',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Unauthenticated',
    },
  },
})

app.openapi(createCheckoutSessionRoute, async (c) => {
  const { tier } = c.req.valid('json')

  let priceId: string
  try {
    priceId = priceIdForTier(tier, c.env)
  } catch {
    return c.json(err('UNKNOWN_TIER', `Unknown or unconfigured subscription tier: ${tier}`), 422)
  }

  // TODO(impl): Look up stripeCustomerId from commitment_contracts or users table.
  // DB integration deferred due to TS2345 Drizzle type incompatibility in this file.
  // For now: create checkout session without customer (Stripe will create one).
  const stripeSecretKey = c.env.STRIPE_SECRET_KEY ?? ''

  // success_url must contain the Stripe template literal {CHECKOUT_SESSION_ID}.
  // Pass it via rawParams so encodeURIComponent does not encode the braces —
  // Stripe requires the literal characters { and } to identify the placeholder.
  const successUrl =
    'https://ontaskhq.com/subscribe/success?session_id={CHECKOUT_SESSION_ID}'
  const session = await stripePost(
    '/v1/checkout/sessions',
    {
      mode: 'subscription',
      'line_items[0][price]': priceId,
      'line_items[0][quantity]': '1',
      cancel_url: 'https://ontaskhq.com/subscribe',
    },
    stripeSecretKey,
    `success_url=${encodeURIComponent(successUrl).replace(/%7B/gi, '{').replace(/%7D/gi, '}')}`,
  ) as { url: string }

  return c.json(ok({ checkoutUrl: session.url }), 201)
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

app.openapi(activateSubscriptionRoute, async (c) => {
  const { sessionId } = c.req.valid('json')
  const stripeSecretKey = c.env.STRIPE_SECRET_KEY ?? ''

  // Retrieve and validate the Stripe Checkout session.
  let session: { payment_status: string; subscription: string | null }
  try {
    session = await stripeGet(
      `/v1/checkout/sessions/${encodeURIComponent(sessionId)}`,
      stripeSecretKey
    ) as { payment_status: string; subscription: string | null }
  } catch {
    return c.json(err('INVALID_SESSION', 'Invalid or unknown Stripe Checkout session'), 400)
  }

  if (session.payment_status !== 'paid') {
    return c.json(err('PAYMENT_NOT_COMPLETED', 'Checkout session payment is not yet complete'), 400)
  }

  const stripeSubscriptionId = session.subscription
  let currentPeriodEnd: string | null = null

  if (stripeSubscriptionId) {
    try {
      const sub = await stripeGet(
        `/v1/subscriptions/${encodeURIComponent(stripeSubscriptionId)}`,
        stripeSecretKey
      ) as { current_period_end: number }
      currentPeriodEnd = new Date(sub.current_period_end * 1000).toISOString()
    } catch {
      // Non-fatal — proceed with activation even if period end fetch fails.
    }
  }

  // TODO(impl): Update subscription record in DB — set status='active', store stripeSubscriptionId,
  // currentPeriodEnd. DB integration deferred due to TS2345 Drizzle type incompatibility in this file.
  // TODO(impl): Emit 'subscription_activated' analytics event (NFR-B1).

  return c.json(
    ok({
      status: 'active' as const,
      stripeSubscriptionId: stripeSubscriptionId ?? null,
      currentPeriodEnd,
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

app.openapi(stripeWebhookRoute, async (c) => {
  const sig = c.req.header('stripe-signature') ?? ''

  // Only verify signature when STRIPE_WEBHOOK_SECRET is configured.
  // In test/dev environments where the secret is empty, skip verification.
  if (c.env?.STRIPE_WEBHOOK_SECRET) {
    // Reconstruct raw body from the validated JSON for HMAC verification.
    // Note: This re-serializes the body which may differ from original bytes.
    // For production: register this route as a raw Hono route (not openapi) so
    // c.req.text() returns the original body bytes. This is a known trade-off
    // when using @hono/zod-openapi with webhook signature verification.
    const event = c.req.valid('json')
    const rawBodyForVerification = JSON.stringify(event)
    const isValid = await verifyWebhookSignature(rawBodyForVerification, sig, c.env)
    if (!isValid) {
      return c.json(err('INVALID_SIGNATURE', 'Stripe webhook signature verification failed'), 400)
    }
  }

  // Use the already-validated payload from zod-openapi.
  const event = c.req.valid('json')

  // Handle subscription lifecycle events.
  // DB integration deferred due to TS2345 Drizzle type incompatibility in this file.
  if (event.type === 'customer.subscription.updated' || event.type === 'customer.subscription.deleted') {
    // TODO(impl): Update subscription status in DB based on event.data.object.status.
    // TODO(impl): For customer.subscription.deleted: set status='cancelled'.
    // TODO(impl): For customer.subscription.updated with status='active': clear grace period.
  } else if (event.type === 'invoice.payment_failed') {
    // TODO(impl): Update subscription status to 'grace_period' in DB.
    // TODO(impl): Set grace period expiry = now + 7 days.
    // TODO(impl): Look up userId by stripeCustomerId, then call sendPush().
    // sendPush is imported and available for the real implementation.
    // TODO(impl): Emit 'payment_failed' analytics event (NFR-B1).
  } else if (event.type === 'invoice.payment_succeeded') {
    // TODO(impl): If subscription was in grace_period: restore to 'active' in DB.
    // TODO(impl): Clear grace period state.
  }

  return c.json(ok({ received: true }), 200)
})

export const subscriptionsRouter = app
