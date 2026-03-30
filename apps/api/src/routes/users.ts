import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Users router ───────────────────────────────────────────────────────────────
// Covers: FR60, FR61, FR64, FR65, FR81, FR85, FR87
// See architecture.md line ~730 for full route coverage plan.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ─────────────────────────────────────────────────────────

const PatchUserMeBodySchema = z.object({
  onboardingCompleted: z.boolean().optional().openapi({
    example: true,
    description: 'Mark the user onboarding flow as completed.',
  }),
})

const UserMeResponseSchema = z.object({
  data: z.object({
    userId: z.string().openapi({ example: 'stub_user_id' }),
    onboardingCompleted: z.boolean().openapi({ example: true }),
  }),
})

const UserErrorSchema = z.object({
  error: z.object({
    code: z.string().openapi({ example: 'INVALID_REQUEST' }),
    message: z.string().openapi({ example: 'Request body is invalid.' }),
  }),
})

// ── PATCH /v1/users/me ─────────────────────────────────────────────────────────

const patchUserMeRoute = createRoute({
  method: 'patch',
  path: '/v1/users/me',
  tags: ['Users'],
  summary: 'Update current user fields',
  description:
    'Updates mutable fields on the current user record (identified by bearer token). ' +
    'Supports: onboardingCompleted. ' +
    'Server-side onboarding persistence is belt-and-suspenders for multi-device scenarios — ' +
    'the local SharedPreferences flag is the source of truth for single-device re-launch prevention.',
  request: {
    body: {
      content: { 'application/json': { schema: PatchUserMeBodySchema } },
      required: true,
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: UserMeResponseSchema } },
      description: 'User record updated successfully',
    },
    422: {
      content: { 'application/json': { schema: UserErrorSchema } },
      description: 'Request body failed validation',
    },
  },
})

app.openapi(patchUserMeRoute, async (c) => {
  // TODO(impl): Upsert user fields via Drizzle (casing: 'camelCase').
  // Identify user from the validated JWT bearer token.
  // Example: await db.update(users).set({ onboardingCompleted: body.onboardingCompleted }).where(eq(users.id, userId))
  const _body = c.req.valid('json')
  // WARNING(stub): Response is hardcoded — onboardingCompleted is always true
  // regardless of the request body value. When real Drizzle impl lands, derive
  // the response fields from the actual upserted user record, not the request body.
  return c.json(
    ok({
      userId: 'stub_user_id',
      onboardingCompleted: true,
    }),
    200,
  )
})

// ── POST /v1/users/me/export ───────────────────────────────────────────────────

const ExportResponseSchema = z.object({
  data: z.object({
    downloadUrl: z.string().openapi({
      example: 'https://stub.ontaskhq.com/exports/stub.zip',
      description: 'Signed URL for the generated ZIP archive (CSV + Markdown).',
    }),
    expiresAt: z.string().openapi({
      example: '2026-03-30T11:00:00.000Z',
      description: 'ISO 8601 timestamp when the download URL expires.',
    }),
  }),
})

const postExportRoute = createRoute({
  method: 'post',
  path: '/v1/users/me/export',
  tags: ['Users'],
  summary: 'Request a data export archive',
  description:
    'Generates a ZIP archive containing all of the authenticated user\'s tasks and lists ' +
    'in both CSV and Markdown formats (FR81). ' +
    'Returns a signed download URL valid for one hour. ' +
    'For typical account sizes the archive should be available within 60 seconds (AC #1).',
  responses: {
    200: {
      content: { 'application/json': { schema: ExportResponseSchema } },
      description: 'Export URL generated successfully',
    },
    401: {
      content: { 'application/json': { schema: UserErrorSchema } },
      description: 'Unauthenticated — valid access token required',
    },
  },
})

app.openapi(postExportRoute, async (c) => {
  // TODO(impl): generate ZIP from user tasks+lists via Drizzle,
  // upload to R2, return signed URL with 1-hour expiry.
  // Use auth middleware to identify user from JWT bearer token.
  const stubExpiresAt = new Date(Date.now() + 3_600_000).toISOString() // +1h
  return c.json(
    ok({
      downloadUrl: 'https://stub.ontaskhq.com/exports/stub.zip',
      expiresAt: stubExpiresAt,
    }),
    200,
  )
})

// ── DELETE /v1/users/me ────────────────────────────────────────────────────────

const deleteUserMeRoute = createRoute({
  method: 'delete',
  path: '/v1/users/me',
  tags: ['Users'],
  summary: 'Delete the current user account',
  description:
    'Initiates account deletion for the authenticated user (FR60). ' +
    'Per NFR-R7 the user record is NOT immediately deleted — the server sets deletedAt ' +
    'and schedules a permanent purge after 30 days. ' +
    'All active refresh tokens are revoked immediately. ' +
    'Returns 204 No Content on success.',
  responses: {
    204: {
      description: 'Account deletion queued — no content returned',
    },
    401: {
      content: { 'application/json': { schema: UserErrorSchema } },
      description: 'Unauthenticated — valid access token required',
    },
  },
})

app.openapi(deleteUserMeRoute, async (c) => {
  // TODO(impl): Set users.deletedAt = new Date(); revoke all refresh_tokens for this user;
  // Do NOT immediately delete user rows — NFR-R7 requires 30-day retention.
  // Schedule permanent purge via Cloudflare Queue or cron trigger after 30 days.
  return new Response(null, { status: 204 })
})

export { app as usersRouter }
