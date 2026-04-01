import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Proof submission router ───────────────────────────────────────────────────
// Stub endpoint for AI-verified photo proof submission (Epic 7, Story 7.2).
// FR31: camera capture only — no gallery import.
// FR32: AI verification stub — always returns verified: true by default.
//       Add ?demo=fail to exercise the rejection path.
//
// TODO(impl): upload to Backblaze B2 (NFR-S4); call packages/ai proof-verification.ts;
//             enqueue job via proof-verification-consumer.ts

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const proofResponseDataSchema = z.object({
  verified: z.boolean(),
  reason: z.string().nullable(),
  taskId: z.string(),
})

const ProofResponseSchema = z.object({ data: proofResponseDataSchema })

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/tasks/{taskId}/proof ─────────────────────────────────────────────
// Accepts multipart/form-data with a `media` file field.
// Returns AI verification result for the uploaded media.

const submitProofRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{taskId}/proof',
  tags: ['Proof'],
  summary: 'Submit photo proof for AI verification',
  description:
    'Accepts multipart/form-data with a `media` file field containing the captured photo. ' +
    'Returns a stub verification result. ' +
    'Add ?demo=fail to exercise the rejection path. ' +
    'Stub implementation (Story 7.2) — real AI pipeline deferred.',
  request: {
    params: z.object({
      taskId: z.string().min(1),
    }),
    query: z.object({
      demo: z.string().optional(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ProofResponseSchema } },
      description: 'Verification result',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Bad request — missing taskId or media file',
    },
  },
})

app.openapi(submitProofRoute, async (c) => {
  const { taskId } = c.req.valid('param')
  const { demo } = c.req.valid('query')

  if (!taskId) {
    return c.json(err('BAD_REQUEST', 'taskId is required'), 400)
  }

  // TODO(impl): parse multipart/form-data and extract `media` file field
  // TODO(impl): upload file to Backblaze B2 (NFR-S4) and store mediaUrl
  // TODO(impl): call packages/ai/src/proof-verification.ts with task context
  // TODO(impl): enqueue async job via proof-verification-consumer.ts
  // TODO(impl): store result in proof_submissions table

  // Demo failure path for testing rejection flow.
  if (demo === 'fail') {
    return c.json(
      ok({
        verified: false,
        reason: 'The photo does not clearly show the completed task. Please retake with the task visible.',
        taskId,
      }),
      200,
    )
  }

  // Default stub: approved.
  return c.json(
    ok({
      verified: true,
      reason: null,
      taskId,
    }),
    200,
  )
})

export { app as proofRouter }
