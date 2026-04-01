// ── Charge scheduler ─────────────────────────────────────────────────────────
// Scheduled cron handler: runs every 5 minutes to find overdue staked tasks
// and enqueue CHARGE_TRIGGER messages. (FR24, AC: 1, Story 6.5)
//
// Runs as `scheduled` export in the Cloudflare Worker — NOT as an HTTP route.

/**
 * Query for overdue staked tasks and enqueue CHARGE_TRIGGER messages
 * for each task that hasn't already been charged.
 *
 * Query logic (to be implemented):
 *   SELECT t.id, t.user_id, t.stake_amount_cents, t.due_date,
 *          cc.stripe_customer_id, cc.stripe_payment_method_id,
 *          cc.charity_id, cc.charity_name
 *   FROM tasks t
 *   JOIN commitment_contracts cc ON cc.user_id = t.user_id
 *   LEFT JOIN charge_events ce ON ce.task_id = t.id
 *     AND ce.status IN ('pending', 'charged', 'disbursed')
 *   WHERE t.stake_amount_cents IS NOT NULL
 *     AND t.due_date < NOW()
 *     AND t.completed_at IS NULL
 *     AND ce.id IS NULL  -- no existing charge event
 *     AND cc.stripe_customer_id IS NOT NULL
 *     AND cc.stripe_payment_method_id IS NOT NULL
 *     AND cc.charity_id IS NOT NULL
 */
export async function triggerOverdueCharges(env: CloudflareBindings): Promise<void> {
  // TODO(impl): implement DB query and queue dispatch
  // 1. createDb(env.DATABASE_URL) to get a Drizzle ORM instance
  // 2. Run the JOIN query above to find overdue tasks without existing charge events
  // 3. For each matching task, enqueue to env.CHARGE_TRIGGER_QUEUE:
  //    {
  //      type: 'CHARGE_TRIGGER',
  //      idempotencyKey: `charge-${task.id}-${task.userId}`,
  //      payload: {
  //        taskId: task.id,
  //        userId: task.userId,
  //        stakeAmountCents: task.stakeAmountCents,
  //        stripeCustomerId: contract.stripeCustomerId,
  //        stripePaymentMethodId: contract.stripePaymentMethodId,
  //        charityId: contract.charityId,
  //        charityName: contract.charityName,
  //        deadlineTimestamp: task.dueDate.toISOString(),
  //      },
  //      createdAt: new Date().toISOString(),
  //      retryCount: 0,
  //    }
  // 4. Log count of enqueued messages for observability
  void env
}
