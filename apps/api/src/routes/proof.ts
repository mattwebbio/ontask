import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Proof submission router ───────────────────────────────────────────────────
// Stub endpoint for AI-verified photo, screenshot/document, or Watch Mode proof submission
// (Epic 7, Stories 7.2–7.4, FR31, FR33-34, FR36, FR66-67).
// FR31: camera capture only — no gallery import (photo path).
// FR33-34: Watch Mode passive camera monitoring (watchMode path).
// FR36: screenshot/document path — PNG, JPG, or PDF up to 25 MB.
// FR32: AI verification stub — always returns verified: true by default.
//       Add ?demo=fail to exercise the rejection path.
// FR66-67: Watch Mode session summary — durationSeconds + activityPercentage in body.
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
  summary: 'Submit photo, screenshot/document, or Watch Mode session proof for AI verification',
  description:
    'Accepts multipart/form-data with a `media` file field (photo/screenshot path) or ' +
    'JSON body with durationSeconds/activityPercentage (watchMode path). ' +
    'FR31: photo path — camera capture only; FR36: screenshot/document path — PNG, JPG, PDF up to 25 MB; ' +
    'FR33-34/FR66-67: Watch Mode session path — passive camera monitoring, session summary submitted as JSON. ' +
    'Returns a stub verification result. ' +
    'Add ?demo=fail to exercise the rejection path. ' +
    'Use ?proofType=screenshot or ?proofType=watchMode to indicate submission type (stub ignores body format but documents intent). ' +
    'Stub implementation (Stories 7.2–7.4) — real AI pipeline deferred.',
  request: {
    params: z.object({
      taskId: z.string().min(1),
    }),
    query: z.object({
      demo: z.string().optional(),
      proofType: z.enum(['photo', 'screenshot', 'watchMode']).optional(),
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

  // TODO(impl): parse multipart/form-data and extract `media` file field (photo/screenshot paths)
  // TODO(impl): upload file to Backblaze B2 (NFR-S4) and store mediaUrl
  // TODO(impl): call packages/ai/src/proof-verification.ts with task context
  // TODO(impl): enqueue async job via proof-verification-consumer.ts
  // TODO(impl): store result in proof_submissions table
  // TODO(impl): Story 7.4 — store watch_mode_sessions table entry; validate activityPercentage; trigger AI frame scoring via packages/ai/src/watch-mode.ts

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
