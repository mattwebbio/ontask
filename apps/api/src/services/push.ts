// ── APNs push notification service ───────────────────────────────────────────
// Uses @fivesheepco/cloudflare-apns2 v13.0.0 — Workers-native APNs client.
// Uses fetch() + crypto.subtle for ES256 JWT signing; no Node.js net/tls required.
// CRITICAL: wrangler dev does NOT support HTTP/2 outbound (open workerd bug).
// APNs calls MUST be tested against staging only: `wrangler deploy --env staging`
// APNs topic for regular push: com.ontaskhq.ontask
// APNs topic for Live Activity: com.ontaskhq.ontask.push-type.liveactivity
//
// Required Workers Secrets (wrangler secret put — never committed):
//   APNS_KEY      — contents of the .p8 key file (ES256 private key)
//   APNS_KEY_ID   — 10-character Key ID from Apple Developer portal
//   APNS_TEAM_ID  — 10-character Team ID from Apple Developer portal

export interface PushPayload {
  title: string
  body: string
  badge?: number
  sound?: string
  data?: Record<string, unknown>
}

export interface SendPushOptions {
  deviceToken: string
  environment: 'development' | 'production'
  payload: PushPayload
}

export async function sendPush(
  options: SendPushOptions,
  env: CloudflareBindings
): Promise<void> {
  // TODO(impl): import and instantiate @fivesheepco/cloudflare-apns2 client
  // TODO(impl): const apns = new ApnsClient({
  //   teamId: env.APNS_TEAM_ID,
  //   keyId: env.APNS_KEY_ID,
  //   signingKey: env.APNS_KEY,
  //   defaultTopic: 'com.ontaskhq.ontask',
  //   environment: options.environment,
  // })
  // TODO(impl): await apns.sendNotification(options.deviceToken, {
  //   aps: {
  //     alert: { title: options.payload.title, body: options.payload.body },
  //     badge: options.payload.badge,
  //     sound: options.payload.sound ?? 'default',
  //   },
  //   ...options.payload.data,
  // })
  // TODO(impl): on UNREGISTERED error from APNs, DELETE FROM device_tokens WHERE token = ?
  void options
  void env
}
