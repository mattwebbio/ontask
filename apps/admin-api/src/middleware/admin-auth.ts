import type { Context, Next } from 'hono'
import { err } from '../lib/response.js'

// ── Admin auth middleware ─────────────────────────────────────────────────────
// Verifies HS256 JWT in Authorization: Bearer <token> header.
// Sets c.var.operatorEmail on success.
// Applied to all /admin/v1/* routes except the login endpoint.
//
// Stub behaviour: if ADMIN_JWT_SECRET is undefined (test environment),
// authentication is skipped to avoid test complexity at stub stage.
// TODO(impl): Remove no-secret skip once ADMIN_JWT_SECRET is always provisioned.

export type AdminAuthContext = { operatorEmail: string }

function base64urlDecode(str: string): Uint8Array {
  // Restore standard base64 padding
  const padded = str.replace(/-/g, '+').replace(/_/g, '/').padEnd(
    str.length + (4 - (str.length % 4)) % 4,
    '=',
  )
  const binary = atob(padded)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes
}

export async function adminAuthMiddleware(
  c: Context<{ Bindings: CloudflareBindings; Variables: { operatorEmail: string } }>,
  next: Next,
): Promise<Response | void> {
  const secret = c.env?.ADMIN_JWT_SECRET

  // TODO(impl): Remove this bypass once ADMIN_JWT_SECRET is always set.
  // Stub: skip auth when secret is not configured (e.g., local dev / tests).
  if (!secret) {
    await next()
    return
  }

  const authHeader = c.req.header('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json(err('UNAUTHORIZED', 'Authorization required'), 401)
  }

  const token = authHeader.slice(7)
  const parts = token.split('.')
  if (parts.length !== 3) {
    return c.json(err('UNAUTHORIZED', 'Invalid or expired token'), 401)
  }

  const [headerB64, payloadB64, signatureB64] = parts
  const signingInput = `${headerB64}.${payloadB64}`

  try {
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify'],
    )

    const signatureBytes = base64urlDecode(signatureB64)
    const valid = await crypto.subtle.verify(
      'HMAC',
      keyMaterial,
      signatureBytes,
      new TextEncoder().encode(signingInput),
    )

    if (!valid) {
      return c.json(err('UNAUTHORIZED', 'Invalid or expired token'), 401)
    }

    // Decode payload
    const payloadJson = new TextDecoder().decode(base64urlDecode(payloadB64))
    const payload = JSON.parse(payloadJson) as { sub?: string; exp?: number }

    // Check expiry
    const now = Math.floor(Date.now() / 1000)
    if (payload.exp !== undefined && payload.exp < now) {
      return c.json(err('UNAUTHORIZED', 'Invalid or expired token'), 401)
    }

    if (!payload.sub) {
      return c.json(err('UNAUTHORIZED', 'Invalid or expired token'), 401)
    }

    c.set('operatorEmail', payload.sub)
    await next()
  } catch {
    return c.json(err('UNAUTHORIZED', 'Invalid or expired token'), 401)
  }
}
