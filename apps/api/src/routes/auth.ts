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

export { app as authRouter }
