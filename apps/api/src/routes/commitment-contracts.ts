import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'
import { verifyWebhookSignature } from '../services/stripe.js'

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
  stakeModificationDeadline: z.string().datetime().nullable(), // ISO 8601 UTC; null when no stake
  canModify: z.boolean(),   // true when stake exists AND now < stakeModificationDeadline
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
  // TODO(impl): query tasks table for stakeAmountCents, stakeModificationDeadline where id = taskId AND userId = JWT sub; compute canModify = stakeAmountCents != null && new Date() < new Date(stakeModificationDeadline)
  return c.json(ok({
    taskId,
    stakeAmountCents: null,
    stakeModificationDeadline: null,
    canModify: false,
  }), 200)
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
  // TODO(impl): after upserting stakeAmountCents, set tasks.stakeModificationDeadline = task.dueDate - 24h
  // Compute modification deadline: dueDate - 24h (caller must provide dueDate or API computes from task)
  return c.json(ok({
    taskId: body.taskId,
    stakeAmountCents: body.stakeAmountCents,
    stakeModificationDeadline: null,  // TODO(impl): set to task.dueDate - 24h; persist to tasks table
    canModify: true,
  }), 200)
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

// ── POST /v1/tasks/:taskId/stake/cancel ───────────────────────────────────────
// Cancels the stake on a task if the modification window is open (FR63, Story 6.6).
// Separate from DELETE /v1/tasks/:taskId/stake (Story 6.2) — this endpoint enforces
// the modification window; DELETE is unrestricted (used by internal/admin flows).

const cancelStakeRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/:taskId/stake/cancel',
  tags: ['Stake'],
  summary: 'Cancel the stake on a task',
  description:
    'Cancels the stake on the given task if the modification window is open. ' +
    'Returns 422 STAKE_LOCKED if the modification window has closed. ' +
    'Returns 422 NO_ACTIVE_STAKE if no stake is set.',
  request: {
    params: z.object({ taskId: z.string().uuid() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: z.object({ data: z.object({ cancelled: z.boolean() }) }) } },
      description: 'Stake cancelled successfully',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Stake locked or no active stake',
    },
  },
})

app.openapi(cancelStakeRoute, async (c) => {
  const { taskId } = c.req.valid('param')
  // TODO(impl): check tasks.stakeAmountCents != null for taskId+userId; if null return 422 NO_ACTIVE_STAKE
  // TODO(impl): check tasks.stakeModificationDeadline; if now >= stakeModificationDeadline return 422 STAKE_LOCKED
  // TODO(impl): set tasks.stakeAmountCents = null AND tasks.stakeModificationDeadline = null
  // TODO(impl): recheck commitment_contracts.hasActiveStakes across all tasks for userId
  // TODO(impl): if a charge_events row exists with status='pending' for this task, cancel/ignore it (check for active charges before clearing)
  void taskId
  return c.json(ok({ cancelled: true }), 200)
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

// ── Impact schemas (FR27, Story 6.4) ─────────────────────────────────────────

const milestoneSchema = z.object({
  id: z.string(),              // e.g. 'first-donation', 'first-kept', 'hundred-donated'
  title: z.string(),           // milestone label — affirming framing
  body: z.string(),            // New York voice copy — "evidence of who you've become"
  earnedAt: z.string(),        // ISO 8601 UTC string
  shareText: z.string(),       // pre-composed share copy for native share sheet
})

const impactSummarySchema = z.object({
  totalDonatedCents: z.number().int(),
  commitmentsKept: z.number().int(),
  commitmentsMissed: z.number().int(),
  charityBreakdown: z.array(z.object({
    charityName: z.string(),
    donatedCents: z.number().int(),
  })),
  milestones: z.array(milestoneSchema),
})

const impactResponseSchema = z.object({ data: impactSummarySchema })

// ── GET /v1/impact ────────────────────────────────────────────────────────────
// Returns the authenticated user's impact summary and earned milestones.

const getImpactRoute = createRoute({
  method: 'get',
  path: '/v1/impact',
  tags: ['Impact'],
  summary: 'Get user impact summary',
  description:
    "Returns the authenticated user's impact summary: total amount donated, " +
    'commitments kept/missed, charity breakdown, and earned milestones. ' +
    'Milestones use "evidence of who you\'ve become" framing (FR27, UX-DR19). ' +
    'Stub implementation (Story 6.4).',
  responses: {
    200: {
      content: { 'application/json': { schema: impactResponseSchema } },
      description: 'Impact summary with milestones',
    },
  },
})

// Stub impact data — returns valid-looking data so Flutter UI renders correctly.
// TODO(impl): query commitment_contracts and task_stakes for userId = JWT sub;
//             aggregate totalDonatedCents, commitmentsKept, commitmentsMissed;
//             query charity breakdown; resolve earned milestones
const _stubImpactData = {
  totalDonatedCents: 2500, // $25.00
  commitmentsKept: 3,
  commitmentsMissed: 1,
  charityBreakdown: [
    { charityName: 'American Red Cross', donatedCents: 2500 },
  ],
  milestones: [
    {
      id: 'first-kept',
      title: 'First commitment kept.',
      body: 'You showed up when it mattered.',
      earnedAt: '2026-01-15T00:00:00.000Z',
      shareText: 'I kept my first commitment with On Task. Your past self makes plans. Your future self keeps them.',
    },
    {
      id: 'first-donation',
      title: 'First donation made.',
      body: 'Even a missed commitment moved something good into the world.',
      earnedAt: '2026-02-01T00:00:00.000Z',
      shareText: 'I donated $25 to the American Red Cross through On Task accountability.',
    },
    {
      id: 'hundred-donated',
      title: '$100 donated.',
      body: "Look how far you've come.",
      earnedAt: '2026-03-01T00:00:00.000Z',
      shareText: "I've donated over $100 to charity through On Task. Accountability that does good.",
    },
  ],
}

app.openapi(getImpactRoute, (c) => {
  return c.json(ok(_stubImpactData), 200)
})

// ── POST /v1/webhooks/stripe ──────────────────────────────────────────────────
// Receives raw Stripe webhook events. No auth middleware — Stripe's webhook
// secret (STRIPE_WEBHOOK_SECRET) is the authentication mechanism (ARCH-24, AC: 3).
//
// IMPORTANT: Raw body must be read BEFORE any JSON parsing for signature
// verification. Do NOT use createRoute body schema parsing here.
//
// Must respond within 30 seconds of receipt (NFR-I4).
// Duplicate webhook delivery does NOT result in duplicate charges (NFR-R2) —
// idempotency is enforced in the charge-trigger consumer.

app.post('/v1/webhooks/stripe', async (c) => {
  // Step 1: Read raw body (must be before any JSON parsing for signature verification)
  const rawBody = await c.req.text()

  // Step 2: Get Stripe signature header
  const sig = c.req.header('Stripe-Signature') ?? ''

  // Step 3: Verify webhook signature
  const valid = verifyWebhookSignature(rawBody, sig, c.env)
  if (!valid) {
    return c.json({ error: 'Invalid signature' }, 400)
  }

  // Step 4: Parse event
  let event: { type: string; data: unknown }
  try {
    event = JSON.parse(rawBody) as { type: string; data: unknown }
  } catch {
    return c.json({ error: 'Invalid JSON payload' }, 400)
  }

  // Step 5: Handle event types
  // TODO(impl): distinguish webhook event types; handle payment_intent.succeeded,
  //             payment_intent.payment_failed; enqueue status update messages
  //
  // Current handling: acknowledge all events immediately to meet <30s SLA (NFR-I4).
  // The primary charge trigger is enqueued by the scheduled cron (charge-scheduler.ts)
  // when deadline passes. The Stripe webhook is the confirmation signal that
  // updates charge_events.status — not the primary trigger.
  //
  // On payment_intent.succeeded: enqueue an UPDATE_CHARGE_STATUS message or update
  //   charge_events inline if latency budget allows (must be < 30s total).
  // On payment_intent.payment_failed: update charge_events.status = 'failed',
  //   store stripeError from the event's last_payment_error.message.
  void event

  // Step 6: Return 200 immediately after acknowledging — must be within 30s (NFR-I4)
  return c.json({ received: true }, 200)
})

export { app as commitmentContractsRouter }
