import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { eq, and } from 'drizzle-orm'
import { ok, err } from '../lib/response.js'
import { getDb } from '../db/index.js'
import { verificationDisputesTable, proofSubmissions, tasksTable } from '@ontask/core'

// ── Operator dispute resolution router ───────────────────────────────────────
// Admin endpoints for operator review and resolution of AI verification disputes.
// (Epic 7, Story 7.9, FR41, NFR-R3)
//
// GET  /admin/v1/disputes        — list pending disputes (AC: 1)
// GET  /admin/v1/disputes/:id    — dispute detail with proof/AI context (AC: 2)
// POST /admin/v1/disputes/:id/resolve — approve or reject (AC: 3)

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
  operatorNote: z.string().min(1, 'Decision note is required'),  // required by AC3
})
const ResolveDisputeResponseSchema = z.object({
  data: z.object({
    id: z.string(),
    status: z.enum(['approved', 'rejected']),
    resolvedAt: z.string(),
  }),
})

// ── SLA helper ────────────────────────────────────────────────────────────────

function computeSla(filedAt: Date): { hoursElapsed: number; slaStatus: 'ok' | 'amber' | 'red' } {
  const hoursElapsed = (Date.now() - filedAt.getTime()) / 3600000
  let slaStatus: 'ok' | 'amber' | 'red'
  if (hoursElapsed < 18) {
    slaStatus = 'ok'
  } else if (hoursElapsed < 22) {
    slaStatus = 'amber'
  } else {
    slaStatus = 'red'
  }
  return { hoursElapsed, slaStatus }
}

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
    'Includes SLA countdown metadata (NFR-R3: 24-hour SLA).',
  responses: {
    200: {
      content: { 'application/json': { schema: DisputeListResponseSchema } },
      description: 'List of pending disputes',
    },
  },
})

app.openapi(getDisputesRoute, async (c) => {
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    const db = getDb(databaseUrl)
    const rows = await db
      .select()
      .from(verificationDisputesTable)
      .where(eq(verificationDisputesTable.status, 'pending'))
      .orderBy(verificationDisputesTable.filedAt)

    const items = rows.map((row) => {
      const { hoursElapsed, slaStatus } = computeSla(row.filedAt)
      return {
        id: row.id,
        taskId: row.taskId,
        userId: row.userId,
        proofSubmissionId: row.proofSubmissionId ?? null,
        status: row.status as 'pending',
        filedAt: row.filedAt.toISOString(),
        hoursElapsed,
        slaStatus,
      }
    })

    return c.json(ok(items))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — returns a single amber-state dispute for UI development.
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
    'Returns 404 if dispute not found.',
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
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    const db = getDb(databaseUrl)

    const disputeRows = await db
      .select()
      .from(verificationDisputesTable)
      .where(eq(verificationDisputesTable.id, id))
      .limit(1)

    if (disputeRows.length === 0) {
      return c.json(err('DISPUTE_NOT_FOUND', 'Dispute not found'), 404)
    }

    const dispute = disputeRows[0]
    const { hoursElapsed, slaStatus } = computeSla(dispute.filedAt)

    // Fetch task title
    let taskTitle = dispute.taskId
    const taskRows = await db
      .select({ title: tasksTable.title })
      .from(tasksTable)
      .where(eq(tasksTable.id, dispute.taskId))
      .limit(1)
    if (taskRows.length > 0) {
      taskTitle = taskRows[0].title
    }

    // Fetch proof submission data
    let proofMediaUrl: string | null = null
    let aiVerificationResult: { verified: boolean; reason: string | null } | null = null
    if (dispute.proofSubmissionId) {
      const proofRows = await db
        .select({
          mediaUrl: proofSubmissions.mediaUrl,
          verified: proofSubmissions.verified,
          verificationReason: proofSubmissions.verificationReason,
        })
        .from(proofSubmissions)
        .where(eq(proofSubmissions.id, dispute.proofSubmissionId))
        .limit(1)
      if (proofRows.length > 0) {
        const proof = proofRows[0]
        proofMediaUrl = proof.mediaUrl ?? null
        if (proof.verified !== null && proof.verified !== undefined) {
          aiVerificationResult = {
            verified: proof.verified,
            reason: proof.verificationReason ?? null,
          }
        }
      }
    }

    return c.json(ok({
      id: dispute.id,
      taskId: dispute.taskId,
      taskTitle,
      userId: dispute.userId,
      proofSubmissionId: dispute.proofSubmissionId ?? null,
      proofMediaUrl,
      aiVerificationResult,
      status: dispute.status as 'pending' | 'approved' | 'rejected',
      operatorNote: dispute.operatorNote ?? null,
      filedAt: dispute.filedAt.toISOString(),
      resolvedAt: dispute.resolvedAt ? dispute.resolvedAt.toISOString() : null,
      resolvedByUserId: dispute.resolvedByUserId ?? null,
      hoursElapsed,
      slaStatus,
    }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — returns fixed dispute data for UI development / test environment.
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
// operatorNote is required in both cases (AC3).
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
    'Sends push notification to user (Story 8.3).',
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
  const { decision, operatorNote } = c.req.valid('json')
  const resolvedAt = new Date()
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    const db = getDb(databaseUrl)

    // Fetch dispute — verify it exists and is still pending
    const disputeRows = await db
      .select()
      .from(verificationDisputesTable)
      .where(eq(verificationDisputesTable.id, id))
      .limit(1)

    if (disputeRows.length === 0) {
      return c.json(err('DISPUTE_NOT_FOUND', 'Dispute not found'), 404)
    }

    const dispute = disputeRows[0]
    if (dispute.status !== 'pending') {
      return c.json(err('DISPUTE_ALREADY_RESOLVED', 'Dispute already resolved'), 409)
    }

    // Resolve the dispute — use operatorEmail from auth middleware as resolvedByUserId placeholder
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    await db
      .update(verificationDisputesTable)
      .set({
        status: decision,
        operatorNote,
        resolvedAt,
        // TODO(impl): resolve resolvedByUserId from operatorEmail via users table lookup
        // For now store operatorEmail string in resolvedByUserId field as placeholder
        resolvedByUserId: operatorEmail ?? null,
      })
      .where(and(
        eq(verificationDisputesTable.id, id),
        eq(verificationDisputesTable.status, 'pending'),
      ))

    // Clear dispute pending flag on task
    await db
      .update(tasksTable)
      .set({ proofDisputePending: false })
      .where(eq(tasksTable.id, dispute.taskId))

    // TODO(impl): if decision='approved': cancel Stripe PaymentIntent, set tasks.completedAt=now()
    // TODO(impl): if decision='rejected': confirm Stripe PaymentIntent charge

    // TODO(impl): After updating status (Story 8.3):
    //   1. Look up dispute taskId, userId, stakeAmountCents, charityName, charityAmountCents
    //   2. Query device_tokens in main DB for userId
    //   3. Query notificationPreferencesTable WHERE userId = userId
    //   4. For each token: enforce preferences + call sendPush({
    //        payload: {
    //          title: task.title,
    //          body: buildDisputeResolvedBody(task.title, approved, amountCents, charityName, charityAmountCents),
    //          data: { taskId, type: approved ? 'dispute_approved' : 'dispute_rejected' },
    //        }
    //      }, env)
    //
    // NOTE: admin-api is SEPARATE from apps/api. Import sendPush from
    //   apps/admin-api/src/services/push.ts (mirror, not imported from apps/api/src/).
    //   Import buildDisputeResolvedBody from apps/admin-api/src/lib/notification-helpers.ts.
    //   approved body:  "[Task title] — dispute approved. Your $[amount] stake has been cancelled."
    //   rejected body:  "[Task title] — dispute reviewed. $[amount] charged. [Charity] receives $[charity amount]. Thanks for trying."

    return c.json(ok({ id, status: decision, resolvedAt: resolvedAt.toISOString() }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — Zod validation already enforces operatorNote non-empty (min 1).
  // The stub does not enforce 404/409 — those are handled by real DB path above.
  return c.json(ok({ id, status: decision, resolvedAt: resolvedAt.toISOString() }))
})

export { app as disputesRouter }
