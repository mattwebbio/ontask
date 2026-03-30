/**
 * GlitchTip error reporting stub for the API worker (AC #2, ARCH-31).
 *
 * GlitchTip implements the Sentry ingestion protocol, so this stub constructs
 * a minimal Sentry envelope payload and POSTs it to the GlitchTip DSN endpoint.
 *
 * Full Sentry envelope format reference:
 *   https://develop.sentry.dev/sdk/envelopes/
 *
 * Usage:
 *   Only call for non-AppError exceptions (unexpected errors).
 *   AppError subclasses (known business errors) must NOT be forwarded.
 */

/**
 * Report an unexpected error to GlitchTip.
 *
 * @param error - The error to report. Must NOT be an AppError instance — those
 *   are known business errors and should not be reported as crashes.
 * @param context - Worker context for enriching the error report.
 * @param env - Cloudflare worker bindings (for GLITCHTIP_DSN access).
 */
export async function reportToGlitchTip(
  error: unknown,
  context: {
    workerName: string
    environment: string
    path: string
    method: string
  },
  env: CloudflareBindings
): Promise<void> {
  // Silently skip if DSN is not configured (local dev, test environments).
  if (!env.GLITCHTIP_DSN) return

  try {
    // TODO(impl): implement full Sentry envelope format per
    //   https://develop.sentry.dev/sdk/envelopes/
    //
    // Minimal envelope structure:
    //   Header: { "dsn": "<dsn>", "sdk": { "name": "ontask-api", "version": "1.0.0" } }
    //   Item header: { "type": "event" }
    //   Item payload: { "event_id": "<uuid>", "timestamp": "<iso8601>",
    //                   "level": "error", "message": "<error message>",
    //                   "tags": { "worker": workerName, "path": path },
    //                   "environment": environment }
    //
    // The envelope is sent as a newline-delimited JSON stream to:
    //   POST <glitchtip-host>/api/<project-id>/envelope/
    //
    // For now, construct a placeholder to confirm the stub structure compiles:
    const message = error instanceof Error ? error.message : String(error)
    void message
    void context
  } catch {
    // Reporting failure must NEVER crash the worker — swallow silently.
  }
}
