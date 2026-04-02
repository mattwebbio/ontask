// ── Live Activity APNs push service ──────────────────────────────────────────
// Sends ActivityKit server-push updates via APNs.
// Uses @fivesheepco/cloudflare-apns2 v13.0.0 — Workers-native APNs client.
// Uses fetch() + crypto.subtle for ES256 JWT signing; no Node.js net/tls required.
//
// CRITICAL: Test against staging only — wrangler dev does not support HTTP/2
// outbound (open workerd bug). Use: wrangler deploy --env staging (ARCH-28)
//
// APNs headers differ from regular push (push.ts uses 'alert' + 'com.ontaskhq.ontask'):
//   apns-push-type : liveactivity
//   apns-topic     : com.ontaskhq.ontask.push-type.liveactivity
//
// Required Workers Secrets (wrangler secret put — never committed):
//   APNS_KEY      — contents of the .p8 key file (ES256 private key)
//   APNS_KEY_ID   — 10-character Key ID from Apple Developer portal
//   APNS_TEAM_ID  — 10-character Team ID from Apple Developer portal

import { ApnsClient, ApnsError, Notification, PushType } from '@fivesheepco/cloudflare-apns2'

const LIVE_ACTIVITY_TOPIC = 'com.ontaskhq.ontask.push-type.liveactivity'

// ── Types ─────────────────────────────────────────────────────────────────────

export interface LiveActivityContentState {
  taskTitle: string
  elapsedSeconds?: number       // Timer mode only — do NOT send in server pushes (client-driven)
  deadlineTimestamp?: number    // Unix timestamp (seconds) — not milliseconds
  stakeAmount?: number          // Dollars, not cents (convert: stakeAmountCents / 100)
  activityStatus: 'active' | 'completed' | 'failed' | 'watchMode'
}

export interface SendLiveActivityUpdateOptions {
  pushToken: string             // ActivityKit push token from live_activity_tokens.pushToken
  expiresAt: Date               // from live_activity_tokens.expiresAt
  event: 'update' | 'end'
  contentState: LiveActivityContentState
  dismissalDate?: number        // Unix timestamp (seconds) — for commitment_countdown: deadline
}

// ── sendLiveActivityUpdate ────────────────────────────────────────────────────
// Sends an ActivityKit server push via APNs.
//
// Returns { success: true, tokenExpired: false } on success.
// Returns { success: false, tokenExpired: true } on APNs HTTP 410 (stale token).
// Returns { success: false, tokenExpired: false } on other APNs errors.
//
// IMPORTANT: The caller is responsible for deleting the live_activity_tokens row
// on tokenExpired: true. This function is side-effect-free for testability.

export async function sendLiveActivityUpdate(
  options: SendLiveActivityUpdateOptions,
  env: CloudflareBindings
): Promise<{ success: boolean; tokenExpired: boolean }> {
  const apns = new ApnsClient({
    team: env.APNS_TEAM_ID,
    keyId: env.APNS_KEY_ID,
    signingKey: env.APNS_KEY,
    defaultTopic: LIVE_ACTIVITY_TOPIC,
    // Use production unless ENVIRONMENT is explicitly 'development'
    host: env.ENVIRONMENT === 'development' ? 'api.sandbox.push.apple.com' : 'api.push.apple.com',
  })

  const now = Math.floor(Date.now() / 1000)
  const expiration = Math.floor(options.expiresAt.getTime() / 1000)

  // Build ActivityKit APS payload
  // NOTE: elapsedSeconds is intentionally omitted from server pushes —
  // elapsed timer is driven client-side by Swift Timer.periodic.
  // Server pushes must NOT override it.
  const contentState: Record<string, unknown> = {
    taskTitle: options.contentState.taskTitle,
    activityStatus: options.contentState.activityStatus,
  }
  if (options.contentState.deadlineTimestamp !== undefined) {
    contentState.deadlineTimestamp = options.contentState.deadlineTimestamp
  }
  if (options.contentState.stakeAmount !== undefined) {
    contentState.stakeAmount = options.contentState.stakeAmount
  }

  const apsPayload: Record<string, unknown> = {
    timestamp: now,
    event: options.event,
    'content-state': contentState,
  }

  if (options.dismissalDate !== undefined) {
    apsPayload['dismissal-date'] = options.dismissalDate
  }

  const notification = new Notification(options.pushToken, {
    type: PushType.liveactivity,
    topic: LIVE_ACTIVITY_TOPIC,
    expiration,
    aps: apsPayload,
  })

  try {
    await apns.send(notification)
    return { success: true, tokenExpired: false }
  } catch (error: unknown) {
    // APNs HTTP 410: Unregistered token — caller must delete the row from live_activity_tokens
    if (error instanceof ApnsError && error.statusCode === 410) {
      return { success: false, tokenExpired: true }
    }
    // Other APNs errors (network, 5xx, etc.) — log and return failure
    console.error('Live Activity APNs push failed:', error)
    return { success: false, tokenExpired: false }
  }
}
