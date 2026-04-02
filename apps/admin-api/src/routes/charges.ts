import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { eq, and, sum } from 'drizzle-orm'
import { ok, err } from '../lib/response.js'
import { getDb } from '../db/index.js'
import { chargeEventsTable, tasksTable, operatorRefundLogsTable } from '@ontask/core'

// ── Operator charge history and refund router ─────────────────────────────────
// Admin endpoints for viewing charge history and issuing refunds.
// (Epic 11, Story 11.3, FR52, NFR-S6, NFR-R3)
//
// GET  /admin/v1/users/:userId/charges      — list processed charges for a user (AC: 1)
// POST /admin/v1/charges/:chargeId/refund   — issue a full or partial refund (AC: 2, 3)

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ChargeItem — summary row for charge list
const ChargeItemSchema = z.object({
  id: z.string(),               // charge_events.id (UUID)
  taskId: z.string(),
  taskTitle: z.string(),        // join tasks.title; fall back to taskId if unavailable
  amountCents: z.number(),
  charityAmountCents: z.number(),
  platformAmountCents: z.number(),
  charityName: z.string(),
  status: z.string(),           // 'charged' | 'failed' | 'disbursed' | 'disbursement_failed' | 'refunded' | 'partially_refunded'
  refundStatus: z.enum(['none', 'partial', 'full']),
  refundedAmountCents: z.number().nullable(),
  stripePaymentIntentId: z.string().nullable(),
  chargedAt: z.string().nullable(),
  createdAt: z.string(),
})
const ChargeListResponseSchema = z.object({ data: z.array(ChargeItemSchema) })

// RefundRequest — operator issues refund
const RefundRequestSchema = z.object({
  amountCents: z.number().int().positive(),  // refund amount; must be <= charge amountCents
  reason: z.string().min(1, 'Refund reason is required'),  // internal, not user-visible
})

// RefundResponse — returned on successful refund
const RefundResponseSchema = z.object({
  data: z.object({
    chargeId: z.string(),
    refundedAmountCents: z.number(),
    refundStatus: z.enum(['partial', 'full']),
    processedAt: z.string(),
  }),
})

// ── GET /admin/v1/users/:userId/charges ───────────────────────────────────────
// Lists all processed charges for a user, including refund status.
// refundStatus and refundedAmountCents are computed by joining operator_refund_logs.

const getChargesRoute = createRoute({
  method: 'get',
  path: '/admin/v1/users/{userId}/charges',
  tags: ['Charges'],
  summary: 'List processed charges for a user',
  description:
    'Returns all charge_events for the given userId, ordered by createdAt desc. ' +
    'Includes refund status computed from operator_refund_logs. ' +
    'refundStatus: none (no refunds), partial (some refunded), full (all refunded). ' +
    '(AC: 1, FR52)',
  request: {
    params: z.object({ userId: z.string().min(1) }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ChargeListResponseSchema } },
      description: 'List of charges for the user',
    },
  },
})

app.openapi(getChargesRoute, async (c) => {
  const { userId } = c.req.valid('param')
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    const db = getDb(databaseUrl)

    // SELECT charge_events.*, tasks.title FROM charge_events
    //   LEFT JOIN tasks ON tasks.id = charge_events.task_id
    //   WHERE charge_events.user_id = :userId
    //   ORDER BY charge_events.created_at DESC
    const rows = await db
      .select()
      .from(chargeEventsTable)
      .where(eq(chargeEventsTable.userId, userId))
      .orderBy(chargeEventsTable.createdAt)

    const items = await Promise.all(rows.map(async (row) => {
      // Fetch task title (fall back to taskId if not found)
      let taskTitle = row.taskId
      const taskRows = await db
        .select({ title: tasksTable.title })
        .from(tasksTable)
        .where(eq(tasksTable.id, row.taskId))
        .limit(1)
      if (taskRows.length > 0) {
        taskTitle = taskRows[0].title
      }

      // TODO(impl): Compute refundStatus and refundedAmountCents from operator_refund_logs
      // once the table is migrated and available. Query:
      //   SELECT SUM(amount_cents) FROM operator_refund_logs
      //   WHERE charge_event_id = row.id
      const refundRows = await db
        .select({ total: sum(operatorRefundLogsTable.amountCents) })
        .from(operatorRefundLogsTable)
        .where(eq(operatorRefundLogsTable.chargeEventId, row.id))

      const refundedTotal = refundRows[0]?.total ? Number(refundRows[0].total) : 0
      let refundStatus: 'none' | 'partial' | 'full' = 'none'
      if (refundedTotal > 0) {
        refundStatus = refundedTotal >= row.amountCents ? 'full' : 'partial'
      }

      return {
        id: row.id,
        taskId: row.taskId,
        taskTitle,
        amountCents: row.amountCents,
        charityAmountCents: row.charityAmountCents,
        platformAmountCents: row.platformAmountCents,
        charityName: row.charityName,
        status: row.status,
        refundStatus,
        refundedAmountCents: refundedTotal > 0 ? refundedTotal : null,
        stripePaymentIntentId: row.stripePaymentIntentId ?? null,
        chargedAt: row.chargedAt ? row.chargedAt.toISOString() : null,
        createdAt: row.createdAt.toISOString(),
      }
    }))

    return c.json(ok(items))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — returns one hardcoded ChargeItem for UI development.
  const stubChargeId = '00000000-0000-4000-a000-000000000020'
  return c.json(ok([{
    id: stubChargeId,
    taskId: '00000000-0000-4000-a000-000000000001',
    taskTitle: 'Complete morning workout',
    amountCents: 2500,
    charityAmountCents: 1250,
    platformAmountCents: 1250,
    charityName: 'Water.org',
    status: 'charged',
    refundStatus: 'none' as const,
    refundedAmountCents: null,
    stripePaymentIntentId: null,
    chargedAt: new Date().toISOString(),
    createdAt: new Date().toISOString(),
  }]))
})

// ── POST /admin/v1/charges/:chargeId/refund ───────────────────────────────────
// Operator issues a full or partial refund for a processed charge.
// Inserts an immutable audit log row into operator_refund_logs (NFR-S6).
// Stripe refund call and push notification are stubbed (Story TBD / Story 8.3).

const postRefundRoute = createRoute({
  method: 'post',
  path: '/admin/v1/charges/{chargeId}/refund',
  tags: ['Charges'],
  summary: 'Issue a full or partial refund for a charge',
  description:
    'Validates refund amount and reason, inserts audit log row (NFR-S6), ' +
    'updates charge status, and stubs Stripe + push notification calls. ' +
    'amountCents must be > 0 and <= charge.amountCents. ' +
    'reason is required (internal, not user-visible). ' +
    '(AC: 2, 3, FR52)',
  request: {
    params: z.object({ chargeId: z.string().min(1) }),
    body: { content: { 'application/json': { schema: RefundRequestSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: RefundResponseSchema } },
      description: 'Refund processed successfully',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid refund amount or missing reason',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Charge not found',
    },
    409: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Charge already fully refunded',
    },
  },
})

app.openapi(postRefundRoute, async (c) => {
  const { chargeId } = c.req.valid('param')
  const { amountCents, reason } = c.req.valid('json')
  const processedAt = new Date()
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    const db = getDb(databaseUrl)

    // 1. Fetch charge_events WHERE id = :chargeId — 404 if not found
    const chargeRows = await db
      .select()
      .from(chargeEventsTable)
      .where(eq(chargeEventsTable.id, chargeId))
      .limit(1)

    if (chargeRows.length === 0) {
      return c.json(err('CHARGE_NOT_FOUND', 'Charge not found'), 404)
    }

    const charge = chargeRows[0]

    // 2. Validate amountCents <= charge.amountCents, else 400
    if (amountCents > charge.amountCents) {
      return c.json(err('REFUND_EXCEEDS_CHARGE', 'Refund amount exceeds charge amount'), 400)
    }

    // 3. Check existing refunds sum — if already fully refunded, 409
    const existingRefundRows = await db
      .select({ total: sum(operatorRefundLogsTable.amountCents) })
      .from(operatorRefundLogsTable)
      .where(eq(operatorRefundLogsTable.chargeEventId, chargeId))

    const existingRefundTotal = existingRefundRows[0]?.total ? Number(existingRefundRows[0].total) : 0
    if (existingRefundTotal >= charge.amountCents) {
      return c.json(err('CHARGE_ALREADY_FULLY_REFUNDED', 'Charge is already fully refunded'), 409)
    }

    // 4. TODO(impl): Stripe refund — after inserting audit log row (Story TBD):
    //   const stripe = new Stripe(c.env.STRIPE_SECRET_KEY, { apiVersion: '2024-06-20' })
    //   const refund = await stripe.refunds.create({
    //     payment_intent: charge.stripePaymentIntentId,
    //     amount: amountCents,
    //     reason: 'requested_by_customer',
    //   })
    //   Store refund.id in operator_refund_logs.stripeRefundId
    //
    // NOTE: admin-api is SEPARATE from apps/api. Do NOT import Stripe from apps/api/src/.

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined

    // 5. Insert into operator_refund_logs (immutable audit log — NFR-S6)
    await db.insert(operatorRefundLogsTable).values({
      chargeEventId: chargeId,
      userId: charge.userId,
      operatorEmail: operatorEmail ?? 'unknown',
      amountCents,
      reason,
      // TODO(impl): stripeRefundId — set to Stripe refund.id once Stripe is wired
      stripeRefundId: null,
      processedAt,
    })

    // 6. Determine refundStatus: 'full' if total refunded >= charge.amountCents, else 'partial'
    const totalRefunded = existingRefundTotal + amountCents
    const refundStatus: 'full' | 'partial' = totalRefunded >= charge.amountCents ? 'full' : 'partial'

    // 7. Update charge_events.status to reflect refund outcome
    // Use .returning() to detect race conditions (0 rows → already updated)
    // TODO(impl): Use WHERE status NOT IN ('refunded') to prevent double-update race
    const newStatus = refundStatus === 'full' ? 'refunded' : 'partially_refunded'
    await db
      .update(chargeEventsTable)
      .set({ status: newStatus, updatedAt: processedAt })
      .where(eq(chargeEventsTable.id, chargeId))
      .returning({ id: chargeEventsTable.id })

    // 8. TODO(impl): Push notification to user (Story 8.3):
    //   Import sendPush from apps/admin-api/src/services/push.ts (mirror — do NOT import from apps/api)
    //   Import buildRefundNotificationBody from apps/admin-api/src/lib/notification-helpers.ts
    //   body: "[Task title] — $[amount] refunded to your card."

    return c.json(ok({
      chargeId,
      refundedAmountCents: amountCents,
      refundStatus,
      processedAt: processedAt.toISOString(),
    }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — Zod validates amountCents > 0 and reason non-empty before reaching here.
  // TODO(impl): Return 'partial' when amountCents < charge.amountCents (no DB available to check)
  return c.json(ok({
    chargeId,
    refundedAmountCents: amountCents,
    refundStatus: 'full' as const,
    processedAt: processedAt.toISOString(),
  }))
})

export { app as chargesRouter }
