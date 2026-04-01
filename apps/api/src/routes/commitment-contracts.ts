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
  void body.sessionToken // consumed by TODO(impl) validation above
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

// ── Stake schemas ─────────────────────────────────────────────────────────────

const stakeSchema = z.object({
  taskId: z.string().uuid(),
  stakeAmountCents: z.number().int().min(500), // minimum $5 = 500 cents
})

const stakeResponseSchema = z.object({
  taskId: z.string().uuid(),
  stakeAmountCents: z.number().int().nullable(),
})

const StakeResponseSchema = z.object({ data: stakeResponseSchema })
const StakeRemoveResponseSchema = z.object({ data: z.object({ removed: z.boolean() }) })

// ── GET /v1/tasks/:taskId/stake ───────────────────────────────────────────────
// Returns the current stake amount for a task.

const getTaskStakeRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/:taskId/stake',
  tags: ['Stake'],
  summary: 'Get current stake for a task',
  description:
    'Returns the stake amount (in cents) for the given task. ' +
    'Stub implementation (Story 6.2).',
  request: {
    params: z.object({ taskId: z.string().uuid() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: StakeResponseSchema } },
      description: 'Current task stake',
    },
  },
})

app.openapi(getTaskStakeRoute, async (c) => {
  const { taskId } = c.req.valid('param')
  // TODO(impl): query tasks table for stakeAmountCents where id = taskId AND userId = JWT sub
  return c.json(ok({ taskId, stakeAmountCents: null }), 200)
})

// ── PUT /v1/tasks/:taskId/stake ───────────────────────────────────────────────
// Sets or updates the stake on a task.

const putTaskStakeRoute = createRoute({
  method: 'put',
  path: '/v1/tasks/:taskId/stake',
  tags: ['Stake'],
  summary: 'Set or update stake on a task',
  description:
    'Sets the stake amount (in cents) for the given task. ' +
    'Returns 422 NO_PAYMENT_METHOD if no stored payment method. ' +
    'Stub implementation (Story 6.2).',
  request: {
    params: z.object({ taskId: z.string().uuid() }),
    body: { content: { 'application/json': { schema: stakeSchema } }, required: true },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: StakeResponseSchema } },
      description: 'Stake set successfully',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'No payment method stored',
    },
  },
})

app.openapi(putTaskStakeRoute, async (c) => {
  const body = c.req.valid('json')
  // TODO(impl): check commitment_contracts.stripePaymentMethodId for userId; if null return 422 NO_PAYMENT_METHOD;
  //             else upsert tasks.stakeAmountCents; set commitment_contracts.hasActiveStakes = true
  return c.json(ok({ taskId: body.taskId, stakeAmountCents: body.stakeAmountCents }), 200)
})

// ── DELETE /v1/tasks/:taskId/stake ────────────────────────────────────────────
// Removes the stake from a task.

const deleteTaskStakeRoute = createRoute({
  method: 'delete',
  path: '/v1/tasks/:taskId/stake',
  tags: ['Stake'],
  summary: 'Remove stake from a task',
  description:
    'Removes the stake from the given task. ' +
    'Stub implementation (Story 6.2).',
  request: {
    params: z.object({ taskId: z.string().uuid() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: StakeRemoveResponseSchema } },
      description: 'Stake removed',
    },
  },
})

app.openapi(deleteTaskStakeRoute, async (c) => {
  // TODO(impl): set tasks.stakeAmountCents = null; recheck commitment_contracts.hasActiveStakes across all tasks for userId
  return c.json(ok({ removed: true }), 200)
})

// ── Charity schemas ────────────────────────────────────────────────────────────

const nonprofitSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string().nullable(),
  logoUrl: z.string().nullable(),
  categories: z.array(z.string()),
})

const nonprofitListSchema = z.object({
  nonprofits: z.array(nonprofitSchema),
  total: z.number().int(),
})

const charitySelectionRequestSchema = z.object({
  charityId: z.string(),
  charityName: z.string(),
})

const charitySelectionResponseSchema = z.object({
  charityId: z.string().nullable(),
  charityName: z.string().nullable(),
})

const NonprofitListResponseSchema = z.object({ data: nonprofitListSchema })
const CharitySelectionResponseSchema = z.object({ data: charitySelectionResponseSchema })

// ── GET /v1/charities/default ─────────────────────────────────────────────────
// Returns the user's current default charity selection.
// CRITICAL: Must be registered BEFORE GET /v1/charities/:charityId (specific before parameterized).

const getDefaultCharityRoute = createRoute({
  method: 'get',
  path: '/v1/charities/default',
  tags: ['Charity'],
  summary: "Get the user's default charity",
  description:
    "Returns the user's currently selected default charity for commitment stakes. " +
    'Stub implementation (Story 6.3).',
  responses: {
    200: {
      content: { 'application/json': { schema: CharitySelectionResponseSchema } },
      description: 'Default charity selection',
    },
  },
})

app.openapi(getDefaultCharityRoute, async (c) => {
  // TODO(impl): query commitment_contracts for userId = JWT sub; return charityId + charityName
  return c.json(ok({ charityId: null, charityName: null }), 200)
})

// ── PUT /v1/charities/default ─────────────────────────────────────────────────
// Sets the user's default charity for future stakes.

const putDefaultCharityRoute = createRoute({
  method: 'put',
  path: '/v1/charities/default',
  tags: ['Charity'],
  summary: "Set the user's default charity",
  description:
    "Persists the user's selected charity as their default for commitment stakes. " +
    'Stub implementation (Story 6.3).',
  request: {
    body: { content: { 'application/json': { schema: charitySelectionRequestSchema } }, required: true },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: CharitySelectionResponseSchema } },
      description: 'Default charity updated',
    },
  },
})

app.openapi(putDefaultCharityRoute, async (c) => {
  const body = c.req.valid('json')
  // TODO(impl): upsert commitment_contracts.charityId and commitment_contracts.charityName for userId = JWT sub
  return c.json(ok({ charityId: body.charityId, charityName: body.charityName }), 200)
})

// ── GET /v1/charities ─────────────────────────────────────────────────────────
// Search or browse nonprofits from Every.org.

const getCharitiesRoute = createRoute({
  method: 'get',
  path: '/v1/charities',
  tags: ['Charity'],
  summary: 'Search or browse nonprofits',
  description:
    'Returns a list of nonprofits from the Every.org catalog. Supports filtering by search query and category. ' +
    'Stub implementation (Story 6.3).',
  request: {
    query: z.object({
      search: z.string().optional(),
      category: z.string().optional(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: NonprofitListResponseSchema } },
      description: 'Nonprofit list',
    },
  },
})

// Stub nonprofit catalog — returns valid-looking data so Flutter UI renders correctly.
// TODO(impl): proxy to Every.org search API — GET https://api.every.org/v0.2/search/{query}?apiKey=ENV
//             fallback to browse endpoint for empty query; filter by category if provided
//             NEVER log apiKey
const _stubNonprofits = [
  { id: 'american-red-cross', name: 'American Red Cross', description: 'Emergency response and disaster relief.', logoUrl: null, categories: ['Health'] },
  { id: 'doctors-without-borders', name: 'Doctors Without Borders', description: 'Medical aid in crisis zones.', logoUrl: null, categories: ['Health'] },
  { id: 'world-wildlife-fund', name: 'World Wildlife Fund', description: 'Conservation of nature and wildlife.', logoUrl: null, categories: ['Environment'] },
  { id: 'unicef', name: 'UNICEF', description: "Children's rights and emergency relief worldwide.", logoUrl: null, categories: ['Human Rights'] },
  { id: 'electronic-frontier-foundation', name: 'Electronic Frontier Foundation', description: 'Digital rights and civil liberties.', logoUrl: null, categories: ['Human Rights'] },
]

app.openapi(getCharitiesRoute, async (c) => {
  return c.json(ok({ nonprofits: _stubNonprofits, total: _stubNonprofits.length }), 200)
})

export { app as commitmentContractsRouter }
