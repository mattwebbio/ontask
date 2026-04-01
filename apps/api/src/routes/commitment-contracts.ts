import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Commitment contracts router ───────────────────────────────────────────────
// Payment method setup endpoints for commitment stakes (Epic 6, FR23, FR64).
// All Stripe API calls are stubs with TODO(impl) markers — stub story (6.1).
// Real Stripe integration deferred until Story 13.1 (AASA + payment pages) is deployed.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const paymentMethodSchema = z.object({
  last4: z.string().nullable(),
  brand: z.string().nullable(),
})

const paymentStatusSchema = z.object({
  hasPaymentMethod: z.boolean(),
  paymentMethod: paymentMethodSchema.nullable(),
  hasActiveStakes: z.boolean(),
})

const setupSessionResponseSchema = z.object({
  setupUrl: z.string(),
  sessionToken: z.string(),
})

const confirmRequestSchema = z.object({
  sessionToken: z.string(),
})

const removeResponseSchema = z.object({
  removed: z.boolean(),
})

const PaymentStatusResponseSchema = z.object({ data: paymentStatusSchema })
const SetupSessionResponseSchema = z.object({ data: setupSessionResponseSchema })
const RemoveResponseSchema = z.object({ data: removeResponseSchema })

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── GET /v1/payment-method ────────────────────────────────────────────────────
// Returns the current user's stored payment method status.

const getPaymentMethodRoute = createRoute({
  method: 'get',
  path: '/v1/payment-method',
  tags: ['PaymentMethod'],
  summary: 'Get current payment method status',
  description:
    'Returns the stored payment method for the authenticated user. ' +
    'Shows last 4 digits and card brand for display in Settings → Payments (FR64). ' +
    'Stub implementation (Story 6.1).',
  responses: {
    200: {
      content: { 'application/json': { schema: PaymentStatusResponseSchema } },
      description: 'Payment method status',
    },
  },
})

app.openapi(getPaymentMethodRoute, async (c) => {
  // TODO(impl): query commitment_contracts for userId = JWT sub; return real values
  return c.json(
    ok({
      hasPaymentMethod: false,
      paymentMethod: null,
      hasActiveStakes: false,
    }),
    200,
  )
})

// ── POST /v1/payment-method/setup-session ─────────────────────────────────────
// Generates a short-lived session token and returns the payment setup URL.

const createSetupSessionRoute = createRoute({
  method: 'post',
  path: '/v1/payment-method/setup-session',
  tags: ['PaymentMethod'],
  summary: 'Create a payment method setup session',
  description:
    'Generates a short-lived session token and returns the Stripe-hosted setup URL ' +
    '(ontaskhq.com/setup?sessionToken=xxx). The app opens this URL via url_launcher. ' +
    'After SetupIntent completes, the Universal Link callback returns the token. ' +
    'Stub implementation (Story 6.1).',
  request: {
    body: { content: { 'application/json': { schema: z.object({}) } }, required: false },
  },
  responses: {
    201: {
      content: { 'application/json': { schema: SetupSessionResponseSchema } },
      description: 'Setup session created',
    },
  },
})

app.openapi(createSetupSessionRoute, async (c) => {
  // TODO(impl): generate cryptographically random token, store in commitment_contracts.setupSessionToken
  //             with 5-minute expiry, build real URL
  return c.json(
    ok({
      setupUrl: 'https://ontaskhq.com/setup?sessionToken=stub-token',
      sessionToken: 'stub-token',
    }),
    201,
  )
})

// ── POST /v1/payment-method/confirm ───────────────────────────────────────────
// Exchanges the session token after the Universal Link callback returns.

const confirmSetupRoute = createRoute({
  method: 'post',
  path: '/v1/payment-method/confirm',
  tags: ['PaymentMethod'],
  summary: 'Confirm payment method setup via session token',
  description:
    'Validates the session token returned via Universal Link callback ' +
    '(https://ontaskhq.com/payment-setup-complete?sessionToken=xxx). ' +
    'Returns updated payment method status with stored last4 and brand. ' +
    'Stub implementation (Story 6.1).',
  request: {
    body: { content: { 'application/json': { schema: confirmRequestSchema } }, required: true },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: PaymentStatusResponseSchema } },
      description: 'Payment method confirmed',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Session token not found or expired',
    },
  },
})

app.openapi(confirmSetupRoute, async (c) => {
  // TODO(impl): validate sessionToken against commitment_contracts.setupSessionToken + setupSessionExpiresAt;
  //             call Stripe API to retrieve PaymentMethod from SetupIntent;
  //             store stripePaymentMethodId, paymentMethodLast4, paymentMethodBrand
  const body = c.req.valid('json')
  console.log(`[stub] Confirming payment setup session token: ${body.sessionToken}`)
  return c.json(
    ok({
      hasPaymentMethod: true,
      paymentMethod: { last4: '4242', brand: 'visa' },
      hasActiveStakes: false,
    }),
    200,
  )
})

// ── DELETE /v1/payment-method ─────────────────────────────────────────────────
// Removes the stored payment method for the current user.

const deletePaymentMethodRoute = createRoute({
  method: 'delete',
  path: '/v1/payment-method',
  tags: ['PaymentMethod'],
  summary: 'Remove stored payment method',
  description:
    'Removes the stored payment method. Returns 422 if the user has active staked tasks ' +
    '(hasActiveStakes = true). Stub implementation (Story 6.1).',
  request: {
    body: { content: { 'application/json': { schema: z.object({}) } }, required: false },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: RemoveResponseSchema } },
      description: 'Payment method removed',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Active commitment stakes prevent removal',
    },
  },
})

app.openapi(deletePaymentMethodRoute, async (c) => {
  // TODO(impl): check hasActiveStakes for userId; if true return 422;
  //             else null out stripePaymentMethodId, paymentMethodLast4, paymentMethodBrand
  //             in commitment_contracts; detach from Stripe API
  return c.json(ok({ removed: true }), 200)
})

export { app as commitmentContractsRouter }
