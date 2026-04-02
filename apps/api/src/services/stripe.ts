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
 * Verify a Stripe webhook signature using HMAC-SHA256 with the Web Crypto API.
 * Must be called with the RAW (unparsed) request body — JSON parsing invalidates
 * the signature because byte-for-byte fidelity is required (ARCH-24, AC: 3).
 *
 * Stripe signature header format: `t=<timestamp>,v1=<hmac_hex>[,v1=<hmac_hex>...]`
 * Signed payload: `<timestamp>.<rawBody>`
 * Tolerance: 300 seconds (5 minutes) — rejects replayed events.
 *
 * Returns false (does not throw) on invalid signature — caller returns HTTP 400.
 * Never logs the secret or signature value.
 */
export async function verifyWebhookSignature(
  payload: string,
  signature: string,
  env: CloudflareBindings
): Promise<boolean> {
  const secret = env.STRIPE_WEBHOOK_SECRET
  if (!secret || !signature) return false

  // Parse Stripe signature header: t=timestamp,v1=signature[,v1=signature2...]
  const parts: Record<string, string[]> = {}
  for (const part of signature.split(',')) {
    const eq = part.indexOf('=')
    if (eq === -1) continue
    const key = part.slice(0, eq)
    const value = part.slice(eq + 1)
    if (!parts[key]) parts[key] = []
    parts[key].push(value)
  }

  const timestamp = parts['t']?.[0]
  const v1Sigs = parts['v1'] ?? []

  if (!timestamp || v1Sigs.length === 0) return false

  // Reject events older than 300 seconds (replay attack prevention).
  const timestampSeconds = parseInt(timestamp, 10)
  if (isNaN(timestampSeconds)) return false
  const nowSeconds = Math.floor(Date.now() / 1000)
  if (Math.abs(nowSeconds - timestampSeconds) > 300) return false

  // Compute HMAC-SHA256 of `<timestamp>.<payload>` using the webhook secret.
  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )
  const signedPayload = `${timestamp}.${payload}`
  const sigBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(signedPayload))
  const computedHex = Array.from(new Uint8Array(sigBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')

  // Timing-safe comparison against each v1 signature in the header.
  // (Web Crypto does not expose a built-in timing-safe string compare,
  // so we compare buffers byte-by-byte to avoid short-circuit leaks.)
  for (const v1Hex of v1Sigs) {
    if (v1Hex.length !== computedHex.length) continue
    // Convert both to Uint8Arrays for byte-by-byte comparison.
    const aBytes = hexToBytes(computedHex)
    const bBytes = hexToBytes(v1Hex)
    if (aBytes.length !== bBytes.length) continue
    try {
      // Use crypto.subtle.verify as a timing-safe comparator.
      const importedKey = await crypto.subtle.importKey(
        'raw',
        encoder.encode(secret),
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['verify']
      )
      const sigBytes = hexToBytes(v1Hex)
      const valid = await crypto.subtle.verify(
        'HMAC',
        importedKey,
        sigBytes,
        encoder.encode(signedPayload)
      )
      if (valid) return true
    } catch {
      continue
    }
  }

  return false
}

/** Converts a hex string to a Uint8Array. */
function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2)
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16)
  }
  return bytes
}
