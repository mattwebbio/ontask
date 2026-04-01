// ── Every.org service ─────────────────────────────────────────────────────────
// Partner Funds API disbursement for commitment charge charity split (FR25, Story 6.5).
// Never throws — returns structured success/failure so the queue consumer can
// decide whether to retry (NFR-R4: funds are never lost in transit).

/**
 * Disburse the charity's 50% share of a commitment charge to the specified
 * Every.org nonprofit.
 *
 * Uses an idempotency key (`disburse-{chargeEventId}`) to prevent double-disbursement
 * on queue retries. Every.org disbursement failures queue indefinitely (max_retries: 10)
 * per NFR-R4 — the consumer throws on failure to trigger Cloudflare Queues retry.
 */
export async function disburseDonation(
  params: {
    nonprofitId: string    // Every.org nonprofit ID (charityId from commitment_contracts)
    amountCents: number    // charity's 50% share
    chargeEventId: string  // for idempotency tracking
    idempotencyKey: string // format: `disburse-{chargeEventId}`
  },
  env: CloudflareBindings
): Promise<{ success: boolean; error?: string }> {
  // TODO(impl): POST to Every.org Partner Funds API with env.EVERY_ORG_API_KEY
  // Endpoint: https://partners.every.org/v0.2/donate
  // Body (JSON):
  //   {
  //     nonprofitId: params.nonprofitId,
  //     amount: (params.amountCents / 100).toFixed(2),  // dollars
  //     currency: "USD",
  //     partnerDonationId: params.idempotencyKey,        // Every.org idempotency field
  //     description: `OnTask commitment charge disbursement for chargeEventId=${params.chargeEventId}`
  //   }
  // Header: Authorization: Bearer {env.EVERY_ORG_API_KEY}
  //
  // On success (2xx): return { success: true }
  // On network/API error: return { success: false, error: errorMessage }
  //   — caller decides whether to throw for retry or ack
  //
  // NEVER log env.EVERY_ORG_API_KEY.
  void env
  return {
    success: false,
    error: `disburseDonation not yet implemented — chargeEventId=${params.chargeEventId} nonprofitId=${params.nonprofitId}`,
  }
}
