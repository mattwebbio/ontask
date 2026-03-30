/**
 * Server-side PostHog event emitter for business events (NFR-B1, ARCH-30).
 *
 * Required business events — all triggered by backend business logic:
 *   - trial_started        — emitted when a user's free trial begins
 *   - trial_expired        — emitted when a user's trial period ends without conversion
 *   - subscription_activated — emitted when a user activates a paid subscription
 *   - subscription_cancelled — emitted when a user cancels their subscription
 *   - task_completed       — emitted when a task is marked complete (server-side confirmation)
 *   - stake_set            — emitted when a commitment stake is set on a task
 *   - charge_fired         — emitted when a commitment charge is processed
 *
 * PII prohibition: Event properties must NEVER include:
 *   - User name or email address
 *   - Stripe payment method or card details
 *   - Any other personally identifiable information
 *
 * Allowed properties: anonymous user ID (UUID), event-specific metadata
 * (e.g. stake_amount_cents, task_id), app version, environment.
 */

/**
 * Emit a business event to PostHog from the API worker.
 *
 * @param event - Event name (e.g. 'trial_started'). See JSDoc above for all
 *   required events.
 * @param properties - PII-free event properties. Must not include name, email,
 *   Stripe payment method, or card details.
 * @param env - Cloudflare worker bindings (for POSTHOG_API_KEY access).
 */
export async function trackBusinessEvent(
  event: string,
  properties: Record<string, unknown>,
  env: CloudflareBindings
): Promise<void> {
  // TODO(impl): POST to PostHog /capture endpoint with env.POSTHOG_API_KEY
  // Example envelope:
  //   POST https://eu.posthog.com/capture/
  //   { api_key: env.POSTHOG_API_KEY, event, properties: { distinct_id, ...properties } }
  //
  // Ensure:
  //   - Only called when env.POSTHOG_API_KEY is non-empty
  //   - Wrapped in try/catch so analytics failure never crashes the worker
  //   - PII-free: no name, email, or payment details in properties
  void event;
  void properties;
  void env;
}
