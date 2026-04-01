// ── Stripe service ─────────────────────────────────────────────────────────────
// Off-session charge creation and webhook signature verification for commitment
// contract charges (FR24, ARCH-24, Story 6.5).

/**
 * Create an off-session PaymentIntent to charge the user's stored payment method.
 * The user is not present — `off_session: true` instructs Stripe to attempt
 * the charge without requiring user authentication (SCA-exempt for merchant-initiated
 * transactions where the user explicitly consented via SetupIntent).
 *
 * Uses Stripe idempotency key to ensure exactly-once semantics on retries (NFR-R1).
 */
export async function createOffSessionCharge(
  params: {
    stripeCustomerId: string
    stripePaymentMethodId: string
    amountCents: number
    idempotencyKey: string
    taskId: string
    userId: string
  },
  env: CloudflareBindings
): Promise<{ paymentIntentId: string }> {
  // TODO(impl): POST https://api.stripe.com/v1/payment_intents with Bearer {env.STRIPE_SECRET_KEY}
  // Body (application/x-www-form-urlencoded):
  //   amount={params.amountCents}
  //   currency=usd
  //   customer={params.stripeCustomerId}
  //   payment_method={params.stripePaymentMethodId}
  //   confirm=true
  //   off_session=true
  //   metadata[task_id]={params.taskId}
  //   metadata[user_id]={params.userId}
  // Header: Idempotency-Key: {params.idempotencyKey}
  //
  // On success: return { paymentIntentId: pi.id }
  // On transient error (network, 5xx): throw — Cloudflare Queues will retry
  // On permanent error (card declined, invalid payment method): throw a typed error
  //   so the consumer can distinguish transient vs permanent failures
  void env
  throw new Error(
    `createOffSessionCharge not yet implemented — taskId=${params.taskId} userId=${params.userId}`
  )
}

/**
 * Verify a Stripe webhook signature using timing-safe HMAC comparison.
 * Must be called with the RAW (unparsed) request body — JSON parsing invalidates
 * the signature because byte-for-byte fidelity is required (ARCH-24, AC: 3).
 *
 * Returns false (does not throw) on invalid signature — caller returns HTTP 400.
 */
export function verifyWebhookSignature(
  payload: string,
  signature: string,
  env: CloudflareBindings
): boolean {
  // TODO(impl): use Stripe webhook signature verification with env.STRIPE_WEBHOOK_SECRET
  // Algorithm:
  //   1. Parse `signature` header: format "t=<timestamp>,v1=<hmac_hex>[,v1=<hmac_hex>...]"
  //   2. Construct signed_payload = "<timestamp>.<rawBody>"
  //   3. Compute HMAC-SHA256 of signed_payload using env.STRIPE_WEBHOOK_SECRET
  //   4. Compare computed hex against each v1= value using timing-safe comparison
  //   5. If any matches AND |timestamp - now| < 300 seconds: return true
  //   6. Otherwise: return false
  //
  // Never log env.STRIPE_WEBHOOK_SECRET or the full signature value.
  void payload
  void signature
  void env
  return false
}
