import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Operator dispute resolution router ───────────────────────────────────────
// Admin endpoints for operator review and resolution of AI verification disputes.
// (Epic 7, Story 7.9, FR41, NFR-R3)
//
// GET  /admin/v1/disputes        — list pending disputes (AC: 1)
// GET  /admin/v1/disputes/:id    — dispute detail with proof/AI context (AC: 1)
// POST /admin/v1/disputes/:id/resolve — approve or reject (AC: 2, 3)
//
// Stub implementation — real DB queries and Stripe integration deferred to Story 11.2.
// Auth middleware (Story 11.1) and CORS (Story 11.1) not yet applied.
//
// TODO(impl): import verificationDisputesTable from '@ontask/core' for real DB writes
// TODO(impl): import tasksTable from '@ontask/core' for proof_dispute_pending update

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// DisputeItem — summary row for dispute list/queue
const DisputeItemSchema = z.object({
  id: z.string(),
  taskId: z.string(),
  userId: z.string(),
  proofSubmissionId: z.string().nullable(),
  status: z.enum(['pending', 'approved', 'rejected']),
  filedAt: z.string(),
  hoursElapsed: z.number(),             // for SLA colour logic in admin SPA
  slaStatus: z.enum(['ok', 'amber', 'red']),  // ok <18h, amber 18-22h, red ≥22h
})
const DisputeListResponseSchema = z.object({ data: z.array(DisputeItemSchema) })

// DisputeDetail — full record with task/proof/AI context for operator review
const DisputeDetailSchema = z.object({
  id: z.string(),
  taskId: z.string(),
  taskTitle: z.string(),
  userId: z.string(),
  proofSubmissionId: z.string().nullable(),
  proofMediaUrl: z.string().nullable(),
  aiVerificationResult: z.object({
    verified: z.boolean(),
    reason: z.string().nullable(),
  }).nullable(),
  status: z.enum(['pending', 'approved', 'rejected']),
  operatorNote: z.string().nullable(),
  filedAt: z.string(),
  resolvedAt: z.string().nullable(),
  resolvedByUserId: z.string().nullable(),
  hoursElapsed: z.number(),
  slaStatus: z.enum(['ok', 'amber', 'red']),
})
const DisputeDetailResponseSchema = z.object({ data: DisputeDetailSchema })

// ResolveDispute — operator decision request/response
const ResolveDisputeRequestSchema = z.object({
  decision: z.enum(['approved', 'rejected']),
  operatorNote: z.string().min(1, 'Decision note is required'),  // required by AC2
})
const ResolveDisputeResponseSchema = z.object({
  data: z.object({
    id: z.string(),
    status: z.enum(['approved', 'rejected']),
    resolvedAt: z.string(),
  }),
})

// ── GET /admin/v1/disputes ────────────────────────────────────────────────────
// List pending disputes ordered by filedAt asc (oldest first) for operator queue.
// SLA countdown metadata included (NFR-R3: 24-hour SLA).

const getDisputesRoute = createRoute({
  method: 'get',
  path: '/admin/v1/disputes',
  tags: ['Disputes'],
  summary: 'List pending disputes for operator review',
  description:
    'Returns all verification_disputes with status=pending, ordered by filedAt asc (oldest first). ' +
    'Includes SLA countdown metadata (NFR-R3: 24-hour SLA). ' +
    'Stub implementation (Story 7.9) — real DB query deferred.',
  responses: {
    200: {
      content: { 'application/json': { schema: DisputeListResponseSchema } },
      description: 'List of pending disputes',
    },
  },
})

app.openapi(getDisputesRoute, async (c) => {
  // TODO(impl): db = getDb(c.env.DATABASE_URL)
  // TODO(impl): query verification_disputes WHERE status = 'pending' ORDER BY filed_at ASC
  // TODO(impl): join tasks for task title + proof media URL
  // TODO(impl): join users for user context
  // TODO(impl): compute hoursElapsed = (now - filed_at) / 3600000
  // TODO(impl): compute slaStatus: ok <18h, amber 18-22h, red ≥22h
  const now = new Date()
  const filedAt = new Date(now.getTime() - 19 * 60 * 60 * 1000).toISOString() // 19h ago = amber
  return c.json(ok([{
    id: '00000000-0000-4000-a000-000000000079',
    taskId: '00000000-0000-4000-a000-000000000001',
    userId: '00000000-0000-4000-a000-000000000002',
    proofSubmissionId: null,
    status: 'pending' as const,
    filedAt,
    hoursElapsed: 19,
    slaStatus: 'amber' as const,
  }]))
})

// ── GET /admin/v1/disputes/:id ────────────────────────────────────────────────
// Full dispute detail for operator review — includes task title, proof media,
// AI verification result and reasoning, SLA status.

const getDisputeRoute = createRoute({
  method: 'get',
  path: '/admin/v1/disputes/{id}',
  tags: ['Disputes'],
  summary: 'Get dispute detail for operator review',
  description:
    'Returns full dispute record including task title, proof media URL, AI verification result with reasoning. ' +
    'Includes SLA countdown metadata. ' +
    'Returns 404 if dispute not found. ' +
    'Stub implementation (Story 7.9) — real DB query deferred.',
  request: {
    params: z.object({ id: z.string().min(1) }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: DisputeDetailResponseSchema } },
      description: 'Dispute detail',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Dispute not found',
    },
  },
})

app.openapi(getDisputeRoute, async (c) => {
  const { id } = c.req.valid('param')
  // TODO(impl): db = getDb(c.env.DATABASE_URL)
  // TODO(impl): SELECT from verification_disputes JOIN tasks JOIN proof_submissions WHERE id = ?
  // TODO(impl): return 404 err('DISPUTE_NOT_FOUND', 'Dispute not found') when id unknown
  if (id !== '00000000-0000-4000-a000-000000000079') {
    return c.json(err('DISPUTE_NOT_FOUND', 'Dispute not found'), 404)
  }
  const now = new Date()
  const filedAt = new Date(now.getTime() - 19 * 60 * 60 * 1000).toISOString()
  return c.json(ok({
    id: '00000000-0000-4000-a000-000000000079',
    taskId: '00000000-0000-4000-a000-000000000001',
    taskTitle: 'Complete morning workout',
    userId: '00000000-0000-4000-a000-000000000002',
    proofSubmissionId: null,
    proofMediaUrl: null,
    aiVerificationResult: {
      verified: false,
      reason: 'The submitted photo does not clearly show completion of the task.',
    },
    status: 'pending' as const,
    operatorNote: null,
    filedAt,
    resolvedAt: null,
    resolvedByUserId: null,
    hoursElapsed: 19,
    slaStatus: 'amber' as const,
  }))
})

// ── POST /admin/v1/disputes/:id/resolve ──────────────────────────────────────
// Operator records decision: approve (cancel charge) or reject (process charge).
// operatorNote is required in both cases (AC2).
// Sets verification_disputes.status, operator_note, resolved_at, resolved_by_user_id.
// Sets tasks.proof_dispute_pending = false.
// Sends push notification to user (Story 8.3).

const resolveDisputeRoute = createRoute({
  method: 'post',
  path: '/admin/v1/disputes/{id}/resolve',
  tags: ['Disputes'],
  summary: 'Approve or reject a pending dispute',
  description:
    'Records operator decision on a verification dispute (FR41). ' +
    'approved: stake charge cancelled, task marked verified complete. ' +
    'rejected: stake charge processed (Stripe), AI decision confirmed. ' +
    'operatorNote is required in both cases. ' +
    'Sets verification_disputes.status, operator_note, resolved_at, resolved_by_user_id. ' +
    'Sets tasks.proof_dispute_pending = false. ' +
    'Sends push notification to user (Story 8.3). ' +
    'Stub implementation (Story 7.9) — real DB writes and Stripe deferred.',
  request: {
    params: z.object({ id: z.string().min(1) }),
    body: { content: { 'application/json': { schema: ResolveDisputeRequestSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ResolveDisputeResponseSchema } },
      description: 'Dispute resolved',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Missing or invalid decision note',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Dispute not found',
    },
    409: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Dispute already resolved',
    },
  },
})

app.openapi(resolveDisputeRoute, async (c) => {
  const { id } = c.req.valid('param')
  const { decision, operatorNote: _operatorNote } = c.req.valid('json')
  const resolvedAt = new Date().toISOString()
  // TODO(impl): db = getDb(c.env.DATABASE_URL)
  // TODO(impl): const operatorId = getOperatorIdFromJwt(c) // Story 11.1 auth middleware
  // TODO(impl): const dispute = await db.select().from(verificationDisputesTable)
  //   .where(eq(verificationDisputesTable.id, id)).limit(1)
  // TODO(impl): if (!dispute) return c.json(err('DISPUTE_NOT_FOUND', 'Dispute not found'), 404)
  // TODO(impl): if (dispute.status !== 'pending') return c.json(err('DISPUTE_ALREADY_RESOLVED', 'Dispute already resolved'), 409)
  // TODO(impl): await db.update(verificationDisputesTable)
  //   .set({ status: decision, operatorNote: _operatorNote, resolvedAt: new Date(), resolvedByUserId: operatorId })
  //   .where(and(eq(verificationDisputesTable.id, id), eq(verificationDisputesTable.status, 'pending')))
  // TODO(impl): await db.update(tasksTable)
  //   .set({ proofDisputePending: false })
  //   .where(eq(tasksTable.id, dispute.taskId))
  // TODO(impl): if decision='approved': cancel Stripe PaymentIntent, set tasks.completed_at=now()
  // TODO(impl): if decision='rejected': confirm Stripe PaymentIntent charge
  // TODO(impl): After updating verification_disputes.status = 'approved'|'rejected' (Story 8.3):
  //   1. Look up the original dispute to get taskId, userId, stakeAmountCents, charityName, charityAmountCents
  //   2. Query device_tokens in main DB for userId
  //   3. Query notificationPreferencesTable WHERE userId = userId
  //   4. For each token: enforce preferences (shouldSendNotification) + call sendPush({
  //        payload: {
  //          title: task.title,
  //          body: buildDisputeResolvedBody(task.title, approved, amountCents, charityName, charityAmountCents),
  //          data: { taskId, type: approved ? 'dispute_approved' : 'dispute_rejected' },
  //        }
  //      }, env)
  //
  // NOTE: admin-api is a SEPARATE Cloudflare Worker (apps/admin-api/). It has its own
  //   wrangler config and does NOT import from apps/api/src/. Import sendPush from
  //   apps/admin-api/src/services/push.ts (mirror of apps/api/src/services/push.ts).
  //   Import buildDisputeResolvedBody from apps/admin-api/src/lib/notification-helpers.ts
  //   (duplicate the pure helper — cannot import from apps/api/src/).
  //   approved body:  "[Task title] — dispute approved. Your $[amount] stake has been cancelled."
  //   rejected body:  "[Task title] — dispute reviewed. $[amount] charged. [Charity] receives $[charity amount]. Thanks for trying."
  return c.json(ok({ id, status: decision, resolvedAt }))
})

export { app as disputesRouter }
