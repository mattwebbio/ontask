import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok } from '../lib/response.js'

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
  },
})

app.openapi(patchUserMeRoute, async (c) => {
  // TODO(impl): Upsert user fields via Drizzle (casing: 'camelCase').
  // Identify user from the validated JWT bearer token.
  // Example: await db.update(users).set({ onboardingCompleted: body.onboardingCompleted }).where(eq(users.id, userId))
  const _body = c.req.valid('json')
  return c.json(
    ok({
      userId: 'stub_user_id',
      onboardingCompleted: true,
    }),
    200,
  )
})

export { app as usersRouter }
