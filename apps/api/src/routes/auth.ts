import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// TLS 1.3 minimum is enforced at the Cloudflare edge layer — no app-level TLS
// configuration is required or possible in Workers. All inbound connections to
// Cloudflare are subject to the Cloudflare TLS policy, which enforces TLS 1.3
// as the minimum for all modern clients (NFR-S1).

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ─────────────────────────────────────────────────────

const AuthTokensSchema = z.object({
  data: z.object({
    accessToken: z.string().openapi({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' }),
    refreshToken: z.string().openapi({ example: 'rt_abc123...' }),
    userId: z.string().openapi({ example: 'usr_01HZQXYZ' }),
  }),
})

const RefreshTokensSchema = z.object({
  data: z.object({
    accessToken: z.string().openapi({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' }),
    refreshToken: z.string().openapi({ example: 'rt_new456...' }),
  }),
})

const AuthErrorSchema = z.object({
  error: z.object({
    code: z.string().openapi({ example: 'INVALID_CREDENTIALS' }),
    message: z.string().openapi({ example: "That email or password isn't quite right." }),
  }),
})

// ── POST /v1/auth/apple ────────────────────────────────────────────────────

const AppleSignInBodySchema = z.object({
  identityToken: z.string().openapi({ example: 'eyJraWQiOiJBQkNERUZHSCIsImFsZyI6IlJTMjU2In0...' }),
  authorizationCode: z.string().openapi({ example: 'c7a8b9...' }),
})

const appleRoute = createRoute({
  method: 'post',
  path: '/v1/auth/apple',
  tags: ['Auth'],
  summary: 'Sign in with Apple',
  description:
    'Validates an Apple identity token and authorization code, creates or retrieves the user account, ' +
    'and returns a short-lived JWT access token (≤15 min expiry) plus a rotating refresh token. ' +
    'Refresh tokens are rotated on every use; the previous token is immediately invalidated (NFR-S5).',
  request: {
    body: {
      content: { 'application/json': { schema: AppleSignInBodySchema } },
      required: true,
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AuthTokensSchema } },
      description: 'Authentication successful — returns access and refresh tokens',
    },
    401: {
      content: { 'application/json': { schema: AuthErrorSchema } },
      description: 'Apple identity token verification failed',
    },
  },
})

app.openapi(appleRoute, async (c) => {
  // TODO(impl): Verify Apple identity token with Apple's public keys,
  // upsert user record via Drizzle (casing: 'camelCase'), issue JWT + refresh token.
  const _body = c.req.valid('json')
  return c.json(
    ok({
      accessToken: 'stub_access_token',
      refreshToken: 'stub_refresh_token',
      userId: 'stub_user_id',
    }),
    200,
  )
})

// ── POST /v1/auth/google ───────────────────────────────────────────────────

const GoogleSignInBodySchema = z.object({
  idToken: z.string().openapi({ example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ii4uLiJ9...' }),
})

const googleRoute = createRoute({
  method: 'post',
  path: '/v1/auth/google',
  tags: ['Auth'],
  summary: 'Sign in with Google',
  description:
    'Validates a Google ID token, creates or retrieves the user account, ' +
    'and returns a short-lived JWT access token (≤15 min expiry) plus a rotating refresh token. ' +
    'Refresh tokens are rotated on every use; the previous token is immediately invalidated (NFR-S5).',
  request: {
    body: {
      content: { 'application/json': { schema: GoogleSignInBodySchema } },
      required: true,
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AuthTokensSchema } },
      description: 'Authentication successful — returns access and refresh tokens',
    },
    401: {
      content: { 'application/json': { schema: AuthErrorSchema } },
      description: 'Google ID token verification failed',
    },
  },
})

app.openapi(googleRoute, async (c) => {
  // TODO(impl): Verify Google ID token with Google's tokeninfo endpoint or JWKS,
  // upsert user record via Drizzle (casing: 'camelCase'), issue JWT + refresh token.
  const _body = c.req.valid('json')
  return c.json(
    ok({
      accessToken: 'stub_access_token',
      refreshToken: 'stub_refresh_token',
      userId: 'stub_user_id',
    }),
    200,
  )
})

// ── POST /v1/auth/email ────────────────────────────────────────────────────

const EmailSignInBodySchema = z.object({
  email: z.string().email().openapi({ example: 'user@example.com' }),
  password: z.string().min(1).openapi({ example: 'hunter2' }),
})

const emailRoute = createRoute({
  method: 'post',
  path: '/v1/auth/email',
  tags: ['Auth'],
  summary: 'Sign in with email and password',
  description:
    'Authenticates a user with their email and password. ' +
    'Returns a short-lived JWT access token (≤15 min expiry) plus a rotating refresh token on success. ' +
    'Returns INVALID_CREDENTIALS on failure — never distinguishes between unknown email and wrong password.',
  request: {
    body: {
      content: { 'application/json': { schema: EmailSignInBodySchema } },
      required: true,
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AuthTokensSchema } },
      description: 'Authentication successful — returns access and refresh tokens',
    },
    401: {
      content: { 'application/json': { schema: AuthErrorSchema } },
      description: 'Invalid credentials — email or password incorrect',
    },
  },
})

app.openapi(emailRoute, async (c) => {
  // TODO(impl): Look up user by email, verify bcrypt hash, issue JWT + refresh token.
  // Return INVALID_CREDENTIALS for both unknown email and wrong password (prevent enumeration).
  const _body = c.req.valid('json')
  return c.json(
    err(
      'INVALID_CREDENTIALS',
      "That email or password isn't quite right. Try again or reset your password.",
    ),
    401,
  )
})

// ── POST /v1/auth/refresh ──────────────────────────────────────────────────

const RefreshBodySchema = z.object({
  refreshToken: z.string().openapi({ example: 'rt_abc123...' }),
})

const refreshRoute = createRoute({
  method: 'post',
  path: '/v1/auth/refresh',
  tags: ['Auth'],
  summary: 'Rotate refresh token',
  description:
    'Exchanges a valid refresh token for a new access token and a new refresh token. ' +
    'The old refresh token is immediately invalidated (NFR-S5 — refresh token rotation). ' +
    'Using an already-invalidated refresh token returns INVALID_REFRESH_TOKEN.',
  request: {
    body: {
      content: { 'application/json': { schema: RefreshBodySchema } },
      required: true,
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: RefreshTokensSchema } },
      description: 'New access token and rotated refresh token',
    },
    401: {
      content: { 'application/json': { schema: AuthErrorSchema } },
      description: 'Refresh token is invalid, expired, or already rotated',
    },
  },
})

app.openapi(refreshRoute, async (c) => {
  // TODO(impl): Validate refresh token against DB, invalidate old token,
  // issue new JWT + new refresh token, persist new token.
  const _body = c.req.valid('json')
  return c.json(
    err('INVALID_REFRESH_TOKEN', 'The refresh token is invalid or has already been used.'),
    401,
  )
})

// ── GET /v1/auth/sessions ──────────────────────────────────────────────────

const SessionSchema = z.object({
  sessionId: z.string().openapi({ example: 'sess_01HZABC123' }),
  deviceName: z.string().openapi({ example: 'iPhone 16 Pro' }),
  location: z.string().openapi({ example: 'London, UK' }),
  lastActiveAt: z.string().openapi({ example: '2026-03-30T10:00:00.000Z' }),
  isCurrentDevice: z.boolean().openapi({ example: true }),
})

const SessionListSchema = z.object({
  data: z.array(SessionSchema),
})

const UserErrorSchema = z.object({
  error: z.object({
    code: z.string().openapi({ example: 'FORBIDDEN' }),
    message: z.string().openapi({ example: 'You cannot revoke your current session.' }),
  }),
})

const getSessionsRoute = createRoute({
  method: 'get',
  path: '/v1/auth/sessions',
  tags: ['Auth'],
  summary: 'List active sessions',
  description:
    'Returns all active sessions (refresh token slots) for the authenticated user. ' +
    'Each session includes the device name (from User-Agent), approximate location, ' +
    'last-active timestamp, and whether it is the current session. ' +
    'Covers FR91 (session management).',
  responses: {
    200: {
      content: { 'application/json': { schema: SessionListSchema } },
      description: 'List of active sessions for the authenticated user',
    },
    401: {
      content: { 'application/json': { schema: AuthErrorSchema } },
      description: 'Unauthenticated — valid access token required',
    },
  },
})

app.openapi(getSessionsRoute, async (c) => {
  // TODO(impl): Query refresh_tokens table via Drizzle, join with users,
  // determine isCurrentDevice by comparing session ID in JWT claim.
  // Stub response — returns fixture data for development.
  return c.json(
    ok([
      {
        sessionId: 'sess_01_current',
        deviceName: 'iPhone 16 Pro',
        location: 'Unknown location',
        lastActiveAt: new Date().toISOString(),
        isCurrentDevice: true,
      },
      {
        sessionId: 'sess_02_other',
        deviceName: 'iPad Pro',
        location: 'Unknown location',
        lastActiveAt: new Date(Date.now() - 86_400_000).toISOString(),
        isCurrentDevice: false,
      },
    ]),
    200,
  )
})

// ── DELETE /v1/auth/sessions/:sessionId ───────────────────────────────────

const DeleteSessionParamsSchema = z.object({
  sessionId: z.string().openapi({ example: 'sess_01HZABC123' }),
})

const deleteSessionRoute = createRoute({
  method: 'delete',
  path: '/v1/auth/sessions/{sessionId}',
  tags: ['Auth'],
  summary: 'Revoke a session',
  description:
    'Invalidates (deletes) the refresh token for the given session. ' +
    'The signed-out device will receive a 401 on its next API call and be forced ' +
    'to re-authenticate. Returns 403 if attempting to revoke the current session ' +
    '(prevents self-lockout). Covers FR91, NFR-S5.',
  request: {
    params: DeleteSessionParamsSchema,
  },
  responses: {
    204: {
      description: 'Session successfully revoked — no content returned',
    },
    401: {
      content: { 'application/json': { schema: AuthErrorSchema } },
      description: 'Unauthenticated — valid access token required',
    },
    403: {
      content: { 'application/json': { schema: UserErrorSchema } },
      description: 'Cannot revoke current session (self-lockout prevention)',
    },
    404: {
      content: { 'application/json': { schema: UserErrorSchema } },
      description: 'Session not found for this user',
    },
  },
})

app.openapi(deleteSessionRoute, async (c) => {
  // TODO(impl): Look up session by sessionId in refresh_tokens table via Drizzle.
  // Compare sessionId against the session ID encoded in the JWT claim (current session).
  // If match → return 403 FORBIDDEN (self-lockout prevention).
  // If not found → return 404 NOT_FOUND.
  // If found and not current → delete row from refresh_tokens table → return 204.
  const { sessionId } = c.req.valid('param')

  // Stub: return 204 for all valid-looking revocations.
  // In production, check sessionId against JWT and DB.
  void sessionId // suppress unused-variable lint in stub
  return new Response(null, { status: 204 })
})

export { app as authRouter }
