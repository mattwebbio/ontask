// ── Every.org queue consumer ──────────────────────────────────────────────────
// Processes EVERY_ORG_DISBURSEMENT queue messages: disburses the charity's 50%
// share via Every.org Partner Funds API. Retries indefinitely on failure
// per NFR-R4 ("funds are never lost in transit"). (FR25, AC: 2, Story 6.5)

import { eq } from 'drizzle-orm'
import { createDb } from '../db/index.js'
import { chargeEventsTable } from '@ontask/core'
import { disburseDonation } from '../services/every-org.js'

// ── Types ──────────────────────────────────────────────────────────────────────

type EveryOrgDisbursementPayload = {
  chargeEventId: string
  nonprofitId: string
  amountCents: number
  idempotencyKey: string // format: `disburse-{chargeEventId}`
}

type QueueMessage<T> = {
  type: string
  idempotencyKey: string
  payload: T
  createdAt: string
  retryCount: number
}

// ── Consumer ───────────────────────────────────────────────────────────────────

/**
 * Cloudflare Queue consumer for the `every-org-queue`.
 * Each message represents a charity disbursement for a successfully charged task.
 *
 * Processing pipeline:
 * 1. Idempotency check: if charge_events.status is already 'disbursed', ack and skip
 * 2. Call disburseDonation() from every-org service
 * 3. On success: update charge_events → status='disbursed', disbursedAt=now()
 * 4. On failure: update charge_events → status='disbursement_failed', disbursementError
 *    then THROW to trigger Cloudflare Queues retry (max_retries: 10 per NFR-R4)
 */
export async function everyOrgConsumer(
  batch: MessageBatch<unknown>,
  env: CloudflareBindings,
  _ctx: ExecutionContext
): Promise<void> {
  const db = createDb(env.DATABASE_URL ?? '')

  for (const message of batch.messages) {
    const msg = message.body as QueueMessage<EveryOrgDisbursementPayload>
    const { payload } = msg

    // ── Step 1: Idempotency check ────────────────────────────────────────────
    const chargeRows = await db
      .select()
      .from(chargeEventsTable)
      .where(eq(chargeEventsTable.id, payload.chargeEventId))
      .limit(1)

    if (chargeRows.length === 0) {
      // Charge event not found — ack to avoid retry loop on a missing record
      console.error(
        `EVERY_ORG_MISSING_CHARGE_EVENT: chargeEventId=${payload.chargeEventId}`
      )
      message.ack()
      continue
    }

    const chargeRow = chargeRows[0]

    if (chargeRow.status === 'disbursed') {
      // Already disbursed — ack without re-disbursing
      message.ack()
      continue
    }

    // ── Step 2: Call Every.org disbursement ──────────────────────────────────
    const result = await disburseDonation(
      {
        nonprofitId: payload.nonprofitId,
        amountCents: payload.amountCents,
        chargeEventId: payload.chargeEventId,
        idempotencyKey: payload.idempotencyKey,
      },
      env
    )

    if (result.success) {
      // ── Step 3: Update charge_events → status='disbursed' ─────────────────
      await db
        .update(chargeEventsTable)
        .set({
          status: 'disbursed',
          disbursedAt: new Date(),
          disbursementError: null,
          updatedAt: new Date(),
        })
        .where(eq(chargeEventsTable.id, payload.chargeEventId))

      message.ack()
    } else {
      // ── Step 4: Update status='disbursement_failed', then throw for retry ─
      const errorMessage = result.error ?? 'Unknown Every.org disbursement error'
      console.error(
        `EVERY_ORG_DISBURSEMENT_FAILED: chargeEventId=${payload.chargeEventId} error=${errorMessage}`
      )

      await db
        .update(chargeEventsTable)
        .set({
          status: 'disbursement_failed',
          disbursementError: errorMessage,
          updatedAt: new Date(),
        })
        .where(eq(chargeEventsTable.id, payload.chargeEventId))

      // Throw to trigger Cloudflare Queues retry (NFR-R4: never lose funds in transit)
      throw new Error(
        `Every.org disbursement failed for chargeEventId=${payload.chargeEventId}: ${errorMessage}`
      )
    }
  }
}
