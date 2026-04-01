// ── Charge trigger queue consumer ─────────────────────────────────────────────
// Processes CHARGE_TRIGGER queue messages: validates clock skew, enforces
// idempotency, calls Stripe for the off-session charge, splits 50/50, and
// enqueues the Every.org disbursement. (FR24, AC: 1, 2, 3, 4, ARCH-24, NFR-R1, NFR-R2)

import { eq } from 'drizzle-orm'
import { createDb } from '../db/index.js'
import { chargeEventsTable } from '@ontask/core'
import { createOffSessionCharge } from '../services/stripe.js'
import { trackBusinessEvent } from '../services/analytics.js'

// ── Types ──────────────────────────────────────────────────────────────────────

type ChargeTriggerPayload = {
  taskId: string
  userId: string
  stakeAmountCents: number
  stripeCustomerId: string
  stripePaymentMethodId: string
  charityId: string
  charityName: string
  deadlineTimestamp: string // ISO 8601 UTC — subject to clock skew check
}

type QueueMessage<T> = {
  type: string           // 'CHARGE_TRIGGER'
  idempotencyKey: string // format: `charge-{taskId}-{userId}`
  payload: T
  createdAt: string      // ISO 8601 UTC
  retryCount: number     // incremented on retry
}

// ── Clock skew utility ─────────────────────────────────────────────────────────

const CLOCK_SKEW_LIMIT_MS = 30 * 24 * 60 * 60 * 1000 // 30 days

/**
 * Returns true if the given ISO 8601 timestamp is within the 30-day clock skew limit.
 * Exactly 30 days old → accepted (inclusive boundary per ARCH-29).
 * 30 days + 1 ms → rejected.
 *
 * Exported as a pure utility for unit testing in isolation (AC: 4).
 */
export function isWithinClockSkewLimit(timestamp: string): boolean {
  const deadline = new Date(timestamp)
  const ageMs = Date.now() - deadline.getTime()
  return ageMs <= CLOCK_SKEW_LIMIT_MS
}

// ── 50/50 split calculation ────────────────────────────────────────────────────

/**
 * Split a stake amount into charity and platform shares.
 * Math.floor ensures we never over-disburse; platform absorbs the odd cent.
 * This is PCI-compliant and audit-safe (per Dev Notes critical note).
 */
export function splitStakeAmount(stakeAmountCents: number): {
  charityAmountCents: number
  platformAmountCents: number
} {
  const charityAmountCents = Math.floor(stakeAmountCents / 2)
  const platformAmountCents = stakeAmountCents - charityAmountCents
  return { charityAmountCents, platformAmountCents }
}

// ── Consumer ───────────────────────────────────────────────────────────────────

/**
 * Cloudflare Queue consumer for the `charge-trigger-queue`.
 * Each message represents one overdue staked task that needs charging.
 *
 * Processing pipeline:
 * 1. Clock skew check (ARCH-29): reject timestamps > 30 days old
 * 2. Idempotency check: skip tasks already charged or disbursed (NFR-R2)
 * 3. Upsert charge_events with status='pending'
 * 4. Call Stripe createOffSessionCharge (FR24)
 * 5. Update charge_events with status='charged'
 * 6. Enqueue EVERY_ORG_DISBURSEMENT message (FR25) — async, 1-hour SLA
 * 7. Track analytics event (NFR-B1)
 */
export async function chargeTriggerConsumer(
  batch: MessageBatch<unknown>,
  env: CloudflareBindings,
  _ctx: ExecutionContext
): Promise<void> {
  const db = createDb(env.DATABASE_URL ?? '')

  for (const message of batch.messages) {
    const msg = message.body as QueueMessage<ChargeTriggerPayload>
    const { payload, idempotencyKey } = msg

    // ── Step 1: Clock skew check (ARCH-29, AC: 4) ───────────────────────────
    if (!isWithinClockSkewLimit(payload.deadlineTimestamp)) {
      console.error(
        `CLOCK_SKEW_REJECT: taskId=${payload.taskId} deadlineTimestamp=${payload.deadlineTimestamp}`
      )
      // Business rejection — ack the message (do not retry)
      message.ack()
      continue
    }

    // ── Step 2: Idempotency check (NFR-R2) ──────────────────────────────────
    const existing = await db
      .select()
      .from(chargeEventsTable)
      .where(eq(chargeEventsTable.idempotencyKey, idempotencyKey))
      .limit(1)

    if (existing.length > 0) {
      const existingStatus = existing[0].status
      if (existingStatus === 'charged' || existingStatus === 'disbursed' || existingStatus === 'disbursement_failed') {
        // Already processed (or charge succeeded but disbursement failed — handled by every-org-consumer retry).
        // Ack without re-charging to prevent duplicate Stripe charges and duplicate disbursement messages.
        message.ack()
        continue
      }
    }

    // ── Step 3: 50/50 split calculation ─────────────────────────────────────
    const { charityAmountCents, platformAmountCents } = splitStakeAmount(
      payload.stakeAmountCents
    )

    // ── Step 4: Upsert charge_events row with status='pending' ──────────────
    await db
      .insert(chargeEventsTable)
      .values({
        userId: payload.userId,
        taskId: payload.taskId,
        idempotencyKey,
        amountCents: payload.stakeAmountCents,
        charityAmountCents,
        platformAmountCents,
        charityId: payload.charityId,
        charityName: payload.charityName,
        status: 'pending',
      })
      .onConflictDoUpdate({
        target: chargeEventsTable.idempotencyKey,
        set: {
          status: 'pending',
          updatedAt: new Date(),
        },
      })

    // ── Step 5: Stripe off-session charge ───────────────────────────────────
    try {
      const { paymentIntentId } = await createOffSessionCharge(
        {
          stripeCustomerId: payload.stripeCustomerId,
          stripePaymentMethodId: payload.stripePaymentMethodId,
          amountCents: payload.stakeAmountCents,
          idempotencyKey,
          taskId: payload.taskId,
          userId: payload.userId,
        },
        env
      )

      // ── Step 6: Update charge_events — status='charged' ─────────────────
      await db
        .update(chargeEventsTable)
        .set({
          status: 'charged',
          stripePaymentIntentId: paymentIntentId,
          chargedAt: new Date(),
          updatedAt: new Date(),
        })
        .where(eq(chargeEventsTable.idempotencyKey, idempotencyKey))

      // ── Step 7: Enqueue Every.org disbursement (AC: 2) ──────────────────
      // Look up the charge_events row id for the disbursement idempotency key
      const chargeRow = await db
        .select({ id: chargeEventsTable.id })
        .from(chargeEventsTable)
        .where(eq(chargeEventsTable.idempotencyKey, idempotencyKey))
        .limit(1)

      if (chargeRow.length > 0) {
        const chargeEventId = chargeRow[0].id
        const disbursementIdempotencyKey = `disburse-${chargeEventId}`

        await env.EVERY_ORG_QUEUE.send({
          type: 'EVERY_ORG_DISBURSEMENT',
          idempotencyKey: disbursementIdempotencyKey,
          payload: {
            chargeEventId,
            nonprofitId: payload.charityId,
            amountCents: charityAmountCents,
            idempotencyKey: disbursementIdempotencyKey,
          },
          createdAt: new Date().toISOString(),
          retryCount: 0,
        })
      }

      // ── Step 8: Analytics (NFR-B1) ───────────────────────────────────────
      await trackBusinessEvent(
        'charge_fired',
        {
          taskId: payload.taskId,
          userId: payload.userId,
          amountCents: payload.stakeAmountCents,
          charityAmountCents,
        },
        env
      )

      message.ack()
    } catch (error) {
      // Determine if this is a permanent or transient failure
      const isTransient = isPermanentStripeError(error)
        ? false
        : true

      if (isTransient) {
        // Throw — Cloudflare Queues retries automatically with backoff (max_retries: 3)
        console.error(
          `CHARGE_TRANSIENT_ERROR: taskId=${payload.taskId} retryCount=${msg.retryCount}`,
          error
        )
        throw error
      } else {
        // Permanent failure — update DB, ack (do not retry)
        const errorMessage = error instanceof Error ? error.message : String(error)
        console.error(
          `CHARGE_PERMANENT_FAILURE: taskId=${payload.taskId} error=${errorMessage}`
        )
        await db
          .update(chargeEventsTable)
          .set({
            status: 'failed',
            stripeError: errorMessage,
            updatedAt: new Date(),
          })
          .where(eq(chargeEventsTable.idempotencyKey, idempotencyKey))
        message.ack()
      }
    }
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────

/**
 * Returns true if the Stripe error is permanent (card declined, invalid method)
 * and should NOT be retried. Returns false for transient errors (network, 5xx,
 * rate limit) which should be retried via Cloudflare Queues.
 */
function isPermanentStripeError(error: unknown): boolean {
  if (!(error instanceof Error)) return false
  const msg = error.message.toLowerCase()
  // Permanent decline codes (card declined, insufficient funds, invalid method)
  const permanentIndicators = [
    'card_declined',
    'insufficient_funds',
    'invalid_card_number',
    'invalid_payment_method',
    'payment_method_not_found',
    'customer_not_found',
    'expired_card',
    'do_not_honor',
    'fraudulent',
    'lost_card',
    'stolen_card',
    'pickup_card',
  ]
  return permanentIndicators.some(indicator => msg.includes(indicator))
}
