import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Operator authentication router ───────────────────────────────────────────
// POST /admin/v1/auth/login — issue a signed JWT on valid credentials
//
// Stub implementation — no real DB or credential verification.
// Auth is format-validated only for Story 11.1.
// Real implementation deferred to when operator_accounts table is available.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const LoginRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  totpCode: z.string().length(6).regex(/^\d{6}$/),
})

const LoginResponseSchema = z.object({
  data: z.object({
    token: z.string(),
    operatorEmail: z.string(),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── JWT helpers (Web Crypto, HS256) ───────────────────────────────────────────

function base64url(data: Uint8Array): string {
  let str = ''
  for (const byte of data) {
    str += String.fromCharCode(byte)
  }
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function encodeJson(obj: unknown): string {
  return base64url(new TextEncoder().encode(JSON.stringify(obj)))
}

async function signJwt(payload: Record<string, unknown>, secret: string): Promise<string> {
  const header = encodeJson({ alg: 'HS256', typ: 'JWT' })
  const body = encodeJson(payload)
  const signingInput = `${header}.${body}`

  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'HMAC',
    keyMaterial,
    new TextEncoder().encode(signingInput),
  )

  return `${signingInput}.${base64url(new Uint8Array(signature))}`
}

// ── POST /admin/v1/auth/login ─────────────────────────────────────────────────
// Issues a signed JWT for any format-valid credentials.
// Real credential verification deferred to operator_accounts table setup.

const loginRoute = createRoute({
  method: 'post',
  path: '/admin/v1/auth/login',
  tags: ['Auth'],
  summary: 'Operator login — issue JWT',
  description:
    'Accepts email, password, and TOTP code. Validates format only (stub). ' +
    'Returns a signed HS256 JWT on success. ' +
    'Real credential and TOTP verification deferred to Story 11.x.',
  request: {
    body: { content: { 'application/json': { schema: LoginRequestSchema } } },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: LoginResponseSchema } },
      description: 'Login successful — JWT issued',
    },
    401: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invalid credentials or TOTP code',
    },
  },
})

app.openapi(loginRoute, async (c) => {
  const { email, password: _password, totpCode: _totpCode } = c.req.valid('json')

  // TODO(impl): replace stub with real credential check:
  //   1. Look up operator record by email in operators table (DB query)
  //   2. Verify password against stored argon2 hash (use argon2.verify())
  //   3. Verify TOTP code against stored TOTP secret (use otpauth or RFC 6238)
  //   4. Rate-limit login attempts by IP (Story 11.x)
  // TODO(impl): On credential mismatch, return 401 err('INVALID_CREDENTIALS', ...)
  // TODO(impl): TOTP stub accepts any 6-digit code — replace with real RFC 6238 verification

  const now = Math.floor(Date.now() / 1000)
  const jwtSecret = c.env?.ADMIN_JWT_SECRET ?? 'dev-secret-do-not-use-in-production'

  const token = await signJwt(
    {
      sub: email,
      role: 'operator',
      iat: now,
      exp: now + 8 * 60 * 60, // 8 hours
    },
    jwtSecret,
  )

  return c.json(ok({ token, operatorEmail: email }))
})

export { app as authRouter }
