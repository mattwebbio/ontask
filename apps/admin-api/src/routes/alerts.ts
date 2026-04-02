import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { eq } from 'drizzle-orm'
import { ok, err } from '../lib/response.js'
import { getDb } from '../db/index.js'
import { chargeEventsTable, disputeReviewsTable } from '@ontask/core'

// ── Operator alerts and monitoring router ────────────────────────────────────
// Admin endpoints for in-dashboard alert polling and business event metrics.
// (Epic 11, Story 11.5, FR54, NFR-B1)
//
// GET  /admin/v1/alerts                        — fetch unacknowledged alerts (AC: 1)
// POST /admin/v1/alerts/:alertId/acknowledge   — acknowledge a single alert (AC: 1)
// GET  /admin/v1/monitoring/metrics            — business event time-series (AC: 2)

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// AlertItem — a single operator alert
const AlertItemSchema = z.object({
  id: z.string(),              // UUID — unique alert id
  type: z.enum([
    'payment_failure',         // any charge_events row with status = 'failed'
    'new_dispute',             // any dispute_reviews row with status = 'pending' filed in last poll window
    'dispute_sla_warning',     // dispute with hoursElapsed >= 18 (amber) and status = 'pending'
  ]),
  severity: z.enum(['info', 'warning', 'critical']),
  title: z.string(),           // short human-readable title
  detail: z.string().nullable().optional(),
  referenceId: z.string(),     // e.g. chargeId or disputeId for deep-link navigation
  referenceType: z.enum(['charge', 'dispute']),
  createdAt: z.string(),       // ISO timestamp
  acknowledged: z.boolean(),
})

const AlertsResponseSchema = z.object({
  data: z.object({
    alerts: z.array(AlertItemSchema),
    unacknowledgedCount: z.number(),
  }),
})

const AcknowledgeResponseSchema = z.object({
  data: z.object({
    alertId: z.string(),
    acknowledgedAt: z.string(),
  }),
})

// MetricSeries — one day's count for a business metric
const MetricSeriesSchema = z.object({
  date: z.string(),    // 'YYYY-MM-DD'
  count: z.number(),
})

const MetricsResponseSchema = z.object({
  data: z.object({
    trialStarts: z.array(MetricSeriesSchema),
    trialToSubscriptionConversions: z.array(MetricSeriesSchema),
    subscriptionActivations: z.array(MetricSeriesSchema),
    subscriptionCancellations: z.array(MetricSeriesSchema),
    totalChargesFired: z.array(MetricSeriesSchema),
    totalDisbursedToCharity: z.array(MetricSeriesSchema),  // sum of charityAmountCents by day
    dateRange: z.object({ from: z.string(), to: z.string() }),
  }),
})

// ── GET /admin/v1/alerts ──────────────────────────────────────────────────────
// Fetches unacknowledged alerts for payment failures and disputes.
// Sorted: critical first, then warning, then info; within each group by createdAt desc.
// TODO(impl): Persistent acknowledgement requires an operator_alert_acks table (deferred).

const getAlertsRoute = createRoute({
  method: 'get',
  path: '/admin/v1/alerts',
  tags: ['Alerts'],
  summary: 'Fetch unacknowledged operator alerts',
  description:
    'Returns alerts for payment failures, new disputes, and dispute SLA warnings. ' +
    'All alerts returned as unacknowledged for v1 (persistent acks deferred). ' +
    '(AC: 1, FR54)',
  responses: {
    200: {
      content: { 'application/json': { schema: AlertsResponseSchema } },
      description: 'List of unacknowledged alerts with count',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Operator email not found in context',
    },
  },
})

const severityOrder = { critical: 0, warning: 1, info: 2 }

app.openapi(getAlertsRoute, async (c) => {
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    if (!operatorEmail) return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)

    const db = getDb(databaseUrl)

    // 1. Query charge_events WHERE status = 'failed' — map to payment_failure alerts
    const failedCharges = await db
      .select({
        id: chargeEventsTable.id,
        createdAt: chargeEventsTable.createdAt,
      })
      .from(chargeEventsTable)
      .where(eq(chargeEventsTable.status, 'failed'))

    // 2. Query dispute_reviews WHERE status = 'pending'
    const pendingDisputes = await db
      .select({
        id: disputeReviewsTable.id,
        filedAt: disputeReviewsTable.filedAt,
        createdAt: disputeReviewsTable.createdAt,
      })
      .from(disputeReviewsTable)
      .where(eq(disputeReviewsTable.status, 'pending'))

    type AlertItem = {
      id: string
      type: 'payment_failure' | 'new_dispute' | 'dispute_sla_warning'
      severity: 'info' | 'warning' | 'critical'
      title: string
      detail: string | null
      referenceId: string
      referenceType: 'charge' | 'dispute'
      createdAt: string
      acknowledged: boolean
    }

    const alerts: AlertItem[] = []

    // Map failed charges to payment_failure alerts
    for (const charge of failedCharges) {
      alerts.push({
        id: crypto.randomUUID(),
        type: 'payment_failure',
        severity: 'critical',
        title: `Payment failed for charge ${charge.id}`,
        detail: `Charge ID: ${charge.id}`,
        referenceId: charge.id,
        referenceType: 'charge',
        createdAt: charge.createdAt.toISOString(),
        acknowledged: false,
      })
    }

    // Map pending disputes to new_dispute or dispute_sla_warning alerts
    for (const dispute of pendingDisputes) {
      const hoursElapsed = (Date.now() - new Date(dispute.filedAt).getTime()) / 3_600_000

      if (hoursElapsed >= 18) {
        // SLA warning — amber (>= 18h) or critical (>= 22h)
        const severity: 'warning' | 'critical' = hoursElapsed >= 22 ? 'critical' : 'warning'
        alerts.push({
          id: crypto.randomUUID(),
          type: 'dispute_sla_warning',
          severity,
          title: `Dispute SLA warning for dispute ${dispute.id}`,
          detail: `Approaching 24h SLA (${Math.floor(hoursElapsed)}h elapsed)`,
          referenceId: dispute.id,
          referenceType: 'dispute',
          createdAt: dispute.createdAt.toISOString(),
          acknowledged: false,
        })
      } else {
        // Filed in last 24h and not yet at SLA warning threshold
        alerts.push({
          id: crypto.randomUUID(),
          type: 'new_dispute',
          severity: 'info',
          title: `New dispute filed`,
          detail: null,
          referenceId: dispute.id,
          referenceType: 'dispute',
          createdAt: dispute.createdAt.toISOString(),
          acknowledged: false,
        })
      }
    }

    // Sort: critical first, then warning, then info; within each group by createdAt desc
    alerts.sort((a, b) => {
      const severityDiff = severityOrder[a.severity] - severityOrder[b.severity]
      if (severityDiff !== 0) return severityDiff
      return b.createdAt.localeCompare(a.createdAt)
    })

    // TODO(impl): Persistent acknowledgement state requires an operator_alert_acks table.
    //    For v1, all alerts are returned as unacknowledged (acknowledged: false).
    return c.json(ok({ alerts, unacknowledgedCount: alerts.length }))
  }

  // TODO(impl): Remove stub fixture when DATABASE_URL is always available in prod/staging.
  // Stub fixture — returns 3 hardcoded alerts for UI development.
  const stubAlerts = [
    {
      id: crypto.randomUUID(),
      type: 'payment_failure' as const,
      severity: 'critical' as const,
      title: 'Payment failed',
      detail: 'TODO(impl): real charge detail',
      referenceId: '00000000-0000-4000-a000-000000000001',
      referenceType: 'charge' as const,
      createdAt: new Date().toISOString(),
      acknowledged: false,
    },
    {
      id: crypto.randomUUID(),
      type: 'dispute_sla_warning' as const,
      severity: 'warning' as const,
      title: 'Dispute SLA warning',
      detail: 'Approaching 24h SLA',
      referenceId: '00000000-0000-4000-a000-000000000002',
      referenceType: 'dispute' as const,
      createdAt: new Date().toISOString(),
      acknowledged: false,
    },
    {
      id: crypto.randomUUID(),
      type: 'new_dispute' as const,
      severity: 'info' as const,
      title: 'New dispute filed',
      detail: null,
      referenceId: '00000000-0000-4000-a000-000000000003',
      referenceType: 'dispute' as const,
      createdAt: new Date().toISOString(),
      acknowledged: false,
    },
  ]
  return c.json(ok({ alerts: stubAlerts, unacknowledgedCount: stubAlerts.length }))
})

// ── POST /admin/v1/alerts/:alertId/acknowledge ────────────────────────────────
// Acknowledge a single alert by ID.
// TODO(impl): Requires operator_alert_acks table (deferred to follow-up story).

const acknowledgeAlertRoute = createRoute({
  method: 'post',
  path: '/admin/v1/alerts/{alertId}/acknowledge',
  tags: ['Alerts'],
  summary: 'Acknowledge a single alert',
  description:
    'Marks the alert as acknowledged for the current operator. ' +
    'TODO(impl): Persistent acks require operator_alert_acks table. ' +
    '(AC: 1, FR54)',
  request: {
    params: z.object({ alertId: z.string().min(1) }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AcknowledgeResponseSchema } },
      description: 'Alert acknowledged successfully',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Operator email not found in context',
    },
  },
})

app.openapi(acknowledgeAlertRoute, async (c) => {
  const { alertId } = c.req.valid('param')
  const databaseUrl = c.env?.DATABASE_URL
  const acknowledgedAt = new Date().toISOString()

  if (databaseUrl) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    if (!operatorEmail) return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)

    // TODO(impl): Insert into operator_alert_acks (alertId, operatorEmail, acknowledgedAt)
    //    This table is not defined in this story — create it in a follow-up.
  }

  // Stub fixture — returns acknowledgement response (persistent ack table deferred).
  // TODO(impl): Replace stub with real DB insert when operator_alert_acks table is available.
  return c.json(ok({ alertId, acknowledgedAt }))
})

// ── GET /admin/v1/monitoring/metrics ──────────────────────────────────────────
// Query PostHog for business event time-series data queryable by date range.
// Data: trial starts, trial-to-subscription conversions, subscription activations,
//       subscription cancellations, total charges fired, total disbursed to charity.
// TODO(impl): Wire up real PostHog Query API + DB query for charity disbursement.

const getMetricsRoute = createRoute({
  method: 'get',
  path: '/admin/v1/monitoring/metrics',
  tags: ['Monitoring'],
  summary: 'Query business event time-series metrics',
  description:
    'Returns daily bucketed counts for key business events. ' +
    'Sourced from PostHog events (Story 1.12, ARCH-30, NFR-B1). ' +
    'totalDisbursedToCharity sourced from DB (chargeEventsTable.charityAmountCents). ' +
    'TODO(impl): Wire up real PostHog Query API. ' +
    '(AC: 2, NFR-B1)',
  request: {
    query: z.object({
      from: z.string().min(1, 'from date is required'),
      to: z.string().min(1, 'to date is required'),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: MetricsResponseSchema } },
      description: 'Business event time-series metrics',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Missing or invalid from/to query params',
    },
    500: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Operator email not found in context',
    },
  },
})

app.openapi(getMetricsRoute, async (c) => {
  const { from, to } = c.req.valid('query')
  const databaseUrl = c.env?.DATABASE_URL

  if (databaseUrl) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const operatorEmail = (c as any).get('operatorEmail') as string | undefined
    if (!operatorEmail) return c.json(err('OPERATOR_EMAIL_MISSING', 'Operator email not found'), 500)
  }

  // TODO(impl): Call PostHog Query API (https://posthog.com/docs/api/query) to aggregate events:
  //   - 'trial_started' → trialStarts
  //   - 'subscription_activated' → subscriptionActivations + trialToSubscriptionConversions
  //     (trialToSubscriptionConversions = subscriptions where preceding 'trial_started' event exists)
  //   - 'subscription_cancelled' → subscriptionCancellations
  //   - 'charge_fired' → totalChargesFired
  //   PostHog events are emitted by the Flutter SDK (ARCH-30, NFR-B1, Story 1.12)
  // PostHog key access: c.env?.POSTHOG_API_KEY
  // For totalDisbursedToCharity: query charge_events table (DATABASE_URL) grouping charityAmountCents by day.
  //
  // Stub mode: POSTHOG_API_KEY absent → return zero-count series for the requested date range.

  // Stub fixture — empty series for all metrics when POSTHOG_API_KEY or DATABASE_URL unavailable
  const emptyMetrics = {
    trialStarts: [],
    trialToSubscriptionConversions: [],
    subscriptionActivations: [],
    subscriptionCancellations: [],
    totalChargesFired: [],
    totalDisbursedToCharity: [],
    dateRange: { from: from ?? '', to: to ?? '' },
  }
  return c.json(ok(emptyMetrics))
})

export { app as alertsRouter }
